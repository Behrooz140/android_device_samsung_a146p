#!/usr/bin/env python3
"""Verify a freshly built a146p recovery.img against this device tree.

Checks the boot header, the prebuilt kernel/DTB/DTBO, ramdisk compression,
every file under recovery/root/, every module under prebuilt/modules/, the
fstab mount points, init services and the absence of unsafe CPIO entries.

Usage:
    tools/verify_recovery.py /path/to/recovery.img

Exit status is 0 only when every check passes.
"""

import argparse
import hashlib
import os
import stat
import sys

from extract_from_recovery import (
    BOOT_MAGIC, TRAILER, align, decompress, parse_boot, safe_name,
)

TREE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

STOCK_CMDLINE = "bootopt=64S3,32N2,64N2 loop.max_part=7"
STOCK_BOARD = "SRPVH12A021"
STOCK_ADDRESSES = {
    "kernel_addr": 0x40080000,
    "ramdisk_addr": 0x51100000,
    "tags_addr": 0x47C80000,
}
STOCK_MD5 = {
    "prebuilt/kernel": "40d6b66f8aaeae274197748032b2a141",
    "prebuilt/dtb.img": "c242c18278a5de98c972069e902935e6",
    "prebuilt/dtbo.img": "58b05a34865d2db035da366d00010147",
}
STOCK_OS_VERSION = 0x1E0001A9  # 15.0.0 / 2026-09
FSTAB_POINTS = (
    "/system", "/vendor", "/product", "/system_ext", "/system_dlkm",
    "/vendor_dlkm", "/odm_dlkm", "/data", "/cache", "/efs", "/sec_efs",
    "/persist", "/nvdata",
)

results = []


def check(label, ok, detail=""):
    results.append((ok, label, detail))
    print("%s %s%s" % ("PASS" if ok else "FAIL", label,
                       ("  -> " + detail) if detail else ""))


def md5(data):
    return hashlib.md5(data).hexdigest()


def iter_newc(data):
    """Yield (name, mode, content) from an ASCII NEWC archive, safely."""
    off = 0
    while off + 110 <= len(data):
        if data[off:off + 6] not in (b"070701", b"070702"):
            raise ValueError("bad CPIO magic at 0x%x (got %r)" %
                             (off, data[off:off + 6]))
        fields = [int(data[off + 6 + i * 8:off + 14 + i * 8], 16)
                  for i in range(13)]
        mode, filesize, namesize = fields[1], fields[6], fields[11]
        name_start = off + 110
        body = align(name_start + namesize, 4)
        end = body + filesize
        if end > len(data):
            raise ValueError("truncated CPIO entry")
        raw = data[name_start:name_start + namesize]
        name = safe_name(raw)
        if raw.rstrip(b"\0") != TRAILER:
            yield name, mode, data[body:end]
        off = align(end, 4)


def decode_os_version(raw):
    # Android boot header: ((major << 14 | minor << 7 | patch) << 11)
    #                      | ((year - 2000) << 4) | month
    major = (raw >> 25) & 0x7F
    minor = (raw >> 18) & 0x7F
    patch = (raw >> 11) & 0x7F
    year = 2000 + ((raw >> 4) & 0xFF)
    month = raw & 0x0F
    return "%d.%d.%d / %04d-%02d" % (major, minor, patch, year, month)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("image")
    args = ap.parse_args()
    path = os.path.abspath(args.image)
    if not os.path.isfile(path):
        sys.exit("error: %s not found" % path)

    with open(path, "rb") as f:
        image = f.read()
    check("image fits 41,943,040-byte recovery partition",
          len(image) <= 41943040, "%d bytes" % len(image))
    check("boot magic", image[:8] == BOOT_MAGIC)

    info = parse_boot(image)
    check("header version 2", info["header_version"] == 2,
          str(info["header_version"]))
    check("page size 4096", info["page_size"] == 4096, str(info["page_size"]))
    check("cmdline byte-for-byte stock", info["cmdline"] == STOCK_CMDLINE,
          repr(info["cmdline"]))
    check("no selinux=permissive in cmdline",
          "selinux=permissive" not in info["cmdline"])
    check("board name", info["name"] == STOCK_BOARD, repr(info["name"]))
    for key, expected in STOCK_ADDRESSES.items():
        check("%s = 0x%x" % (key, expected), info[key] == expected,
              "0x%x" % info[key])
    check("os_version = 15.0.0 / 2026-09",
          info["os_version"] == STOCK_OS_VERSION,
          "%s (raw 0x%08x)" % (decode_os_version(info["os_version"]),
                               info["os_version"]))

    check("ramdisk uses gzip", info["ramdisk"][:2] == b"\x1f\x8b",
          "first bytes %r" % info["ramdisk"][:2])

    for rel, expected in STOCK_MD5.items():
        key = os.path.basename(rel).replace(".img", "")
        actual = md5(info[key])
        check("%s unchanged" % rel, actual == expected, actual)
    check("recovery_dtbo matches stock", md5(info["dtbo"]) ==
          STOCK_MD5["prebuilt/dtbo.img"], md5(info["dtbo"]))

    try:
        cpio = decompress(info["ramdisk"])
    except Exception as e:
        sys.exit("error: cannot decompress ramdisk: %s" % e)

    entries = {}
    try:
        for name, mode, content in iter_newc(cpio):
            entries[name] = (mode, content)
    except ValueError as e:
        sys.exit("error: %s" % e)
    print("INFO ramdisk entries: %d" % len(entries))

    # 1. Every file we keep under recovery/root/ must be in the ramdisk
    #    byte-for-byte with the same permission bits.
    root_src = os.path.join(TREE, "recovery", "root")
    overlay = []
    for dirpath, _, filenames in os.walk(root_src):
        for fn in filenames:
            full = os.path.join(dirpath, fn)
            rel = os.path.relpath(full, root_src).replace(os.sep, "/")
            overlay.append((rel, full))
    for rel, full in sorted(overlay):
        if rel not in entries:
            check("overlay %s present" % rel, False, "missing")
            continue
        want = open(full, "rb").read()
        mode, got = entries[rel]
        want_mode = stat.S_IMODE(os.stat(full).st_mode)
        check("overlay %s present" % rel, got == want,
              "bytes match" if got == want else "content differs")
        check("overlay %s mode %04o" % (rel, want_mode),
              stat.S_IMODE(mode) == want_mode, "%04o" % stat.S_IMODE(mode))

    # 2. All prebuilt modules must be present and identical.
    mods_src = os.path.join(TREE, "prebuilt", "modules")
    modules = [fn for fn in os.listdir(mods_src)
               if os.path.isfile(os.path.join(mods_src, fn))]
    missing = [fn for fn in modules if "lib/modules/" + fn not in entries]
    changed = []
    for fn in modules:
        rel = "lib/modules/" + fn
        if rel in entries:
            if entries[rel][1] != open(os.path.join(mods_src, fn), "rb").read():
                changed.append(fn)
    check("all %d prebuilt module files in ramdisk" % len(modules),
          not missing, "missing: %s" % ", ".join(missing[:8]) if missing else "")
    check("all prebuilt module files byte-identical", not changed,
          "changed: %s" % ", ".join(changed[:8]) if changed else "")
    load_entry = entries.get("lib/modules/modules.load.recovery", (0, b""))
    load_names = set(load_entry[1].decode("utf-8", "replace").split())
    ko_names = {fn for fn in modules if fn.endswith(".ko")}
    unlisted = sorted(ko_names - load_names)
    stale = sorted(load_names - ko_names)
    check("modules.load.recovery lists exactly the stock modules",
          not unlisted and not stale,
          "unlisted: %s; stale: %s" % (", ".join(unlisted[:8]),
                                        ", ".join(stale[:8]))
          if (unlisted or stale) else "")

    for special in ("regulator-vibrator.ko", "clk-mt6833.ko"):
        check("module %s present" % special,
              "lib/modules/" + special in entries)
    panel = [fn for fn in modules if fn.startswith("panel-wt-")]
    check("panel modules present (%d)" % len(panel), len(panel) >= 5)

    # 3. Fstab: identify the actual file and check every mount point.
    fstab_names = [n for n in entries if os.path.basename(n) in
                   ("fstab", "recovery.fstab", "fstab.a146p")]
    check("fstab file found", bool(fstab_names), ", ".join(fstab_names))
    if fstab_names:
        fstab = entries[fstab_names[0]][1].decode("utf-8", "replace")
        missing_points = [p for p in FSTAB_POINTS if p not in fstab]
        check("fstab has all %d expected mount points" % len(FSTAB_POINTS),
              not missing_points,
              "missing: %s" % ", ".join(missing_points) if missing_points else "")
        for sensitive in ("/efs", "/persist", "/nvdata"):
            lines = [ln for ln in fstab.splitlines()
                     if ln.split() and ln.split()[0] == sensitive]
            bad = [ln for ln in lines if "wipeingui" in ln or "flags=rw" in ln]
            check("%s has no wipe/rw flags" % sensitive, not bad,
                  "; ".join(bad) if bad else "")

    # 4. Init wiring and basic TWRP binaries.
    initrc = entries.get("init.recovery.mt6833.rc", (0, b""))[1].decode(
        "utf-8", "replace")
    check("init rc defines twrpdiag service", "service twrpdiag" in initrc)
    check("init rc defines usb-restrict service",
          "service usb-restrict" in initrc)
    check("init rc imports Samsung rc",
          "import /init.recovery.samsung.rc" in initrc)
    check("init rc configfs USB rules", "sys.usb.configfs" in initrc)

    required = (
        "init", "default.prop", "system/etc/twrp.flags",
        "system/etc/recovery.fstab", "init.recovery.samsung.rc",
        "sbin/twrp-diag.sh", "system/bin/usb_restrict.sh",
    )
    missing_entries = [name for name in required if name not in entries]
    check("all %d required recovery entries present" % len(required),
          not missing_entries,
          "missing: %s" % ", ".join(missing_entries) if missing_entries else "")

    required_tools = (
        "twrp", "recovery", "fastbootd", "toolbox", "toybox", "unzip",
        "mke2fs", "e2fsck", "resize2fs", "make_f2fs", "fsck.f2fs",
        "sload_f2fs",
    )
    basenames = {os.path.basename(name) for name in entries}
    missing_tools = [name for name in required_tools if name not in basenames]
    check("all %d required recovery tools present" % len(required_tools),
          not missing_tools,
          "missing: %s" % ", ".join(missing_tools) if missing_tools else "")
    check("twrpdiag is executable",
          bool(entries.get("sbin/twrp-diag.sh", (0, b""))[0] & 0o111))

    # 5. Verify the build's own complete ramdisk manifest, when present. This
    #    catches any file that was silently dropped or modified by packaging.
    manifest = entries.get("ramdisk-files.sha256sum", (0, b""))[1]
    if manifest:
        bad_hashes = []
        checked = 0
        for line in manifest.decode("utf-8", "replace").splitlines():
            parts = line.split(None, 1)
            if len(parts) != 2:
                bad_hashes.append("malformed: " + line)
                continue
            want_hash, name = parts
            name = name.strip()
            if name.startswith("./"):
                name = name[2:]
            if name in ("ramdisk-files.sha256sum", "prop.default") or \
                    name.startswith("lib/modules/"):
                continue
            if name not in entries:
                bad_hashes.append("missing " + name)
                continue
            checked += 1
            if hashlib.sha256(entries[name][1]).hexdigest() != want_hash:
                bad_hashes.append("hash " + name)
        check("ramdisk manifest hashes (%d files)" % checked,
              not bad_hashes,
              "; ".join(bad_hashes[:8]) if bad_hashes else "")

    # 6. No leftover stock flashable images inside the ramdisk.
    stray = [n for n in entries if n.endswith(".img") and
             n.startswith(("boot", "recovery", "vendor_boot", "vbmeta"))]
    check("no stock images packed into ramdisk", not stray, ", ".join(stray))

    ok = all(r[0] for r in results)
    bad = [r[1] for r in results if not r[0]]
    print("\n%s — %d passed, %d failed" %
          ("VERIFIED" if ok else "NOT VERIFIED",
           len(results) - len(bad), len(bad)))
    if bad:
        print("Failed checks:")
        for name in bad:
            print("  - " + name)
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
