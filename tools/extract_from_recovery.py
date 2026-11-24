#!/usr/bin/env python3
"""Extract the stock prebuilts from a Samsung a146p recovery.img.

Everything comes from the image itself; nothing is downloaded and no file
outside the device tree is written.  The ramdisk CPIO parser rejects absolute,
parent-traversing and symlink entries so a malformed image cannot escape the
temporary extraction directory.

Usage:
    tools/extract_from_recovery.py /path/to/recovery.img

Outputs (relative to the device tree):
    prebuilt/kernel          stock Image.gz
    prebuilt/dtb.img         stock DTB
    prebuilt/dtbo.img        stock recovery_dtbo section
    prebuilt/modules/        lib/modules from the ramdisk
    tools/stock_*            stock init rc files and recovery.fstab
"""

import argparse
import bz2
import gzip
import hashlib
import lzma
import os
import shutil
import stat
import struct
import sys
import tempfile

BOOT_MAGIC = b"ANDROID!"
NEWC_MAGIC = 0x71AFFBAF
TRAILER = b"TRAILER!!!"


def align(n, page):
    return (n + page - 1) // page * page


def md5(data):
    return hashlib.md5(data).hexdigest()


def parse_boot(data):
    if data[:8] != BOOT_MAGIC:
        sys.exit("error: not an Android boot image")
    (ks, ka, rs, ra, ss, sa, ta, ps, hv, osv) = struct.unpack_from("<10I", data, 8)
    if ps not in (2048, 4096, 8192, 16384):
        sys.exit("error: unexpected page size %d" % ps)
    name = data[48:64].split(b"\0", 1)[0].decode("utf-8", "replace")
    cmdline = data[64:576].split(b"\0", 1)[0].decode("utf-8", "replace")

    if hv >= 2:
        rdtbo_size = struct.unpack_from("<I", data, 1632)[0]
        rdtbo_off = struct.unpack_from("<Q", data, 1636)[0]
        hsz, dtb_size = struct.unpack_from("<II", data, 1644)
        dtb_addr = struct.unpack_from("<Q", data, 1652)[0]
    else:
        rdtbo_size = rdtbo_off = hsz = dtb_size = dtb_addr = 0
        hsz = 1632

    o = align(hsz, ps)
    kernel = data[o:o + ks]
    o += align(ks, ps)
    ramdisk = data[o:o + rs]
    o += align(rs, ps)
    o += align(ss, ps)

    if rdtbo_size and 0 < rdtbo_off <= len(data) - rdtbo_size:
        dtbo = data[rdtbo_off:rdtbo_off + rdtbo_size]
        dtb_start = align(rdtbo_off + rdtbo_size, ps)
    else:
        dtbo = data[o:o + rdtbo_size]
        dtb_start = o + align(rdtbo_size, ps)
    dtb = data[dtb_start:dtb_start + dtb_size]

    print("==> header v%d, page %d, board %r" % (hv, ps, name))
    print("    cmdline: %s" % cmdline)
    print("    kernel   %9d bytes  md5 %s" % (len(kernel), md5(kernel)))
    print("    ramdisk  %9d bytes  md5 %s  @0x%x" % (len(ramdisk), md5(ramdisk), ra))
    print("    dtb      %9d bytes  md5 %s  @0x%x" % (len(dtb), md5(dtb), dtb_addr))
    print("    dtbo     %9d bytes  md5 %s" % (len(dtbo), md5(dtbo)))
    return {
        "name": name,
        "cmdline": cmdline,
        "kernel": kernel,
        "ramdisk": ramdisk,
        "dtb": dtb,
        "dtbo": dtbo,
        "header_size": hsz,
        "kernel_addr": ka,
        "ramdisk_addr": ra,
        "tags_addr": ta,
        "os_version": osv,
        "header_version": hv,
        "page_size": ps,
    }


def decompress(blob):
    if blob[:2] == b"\x1f\x8b":
        return gzip.decompress(blob)
    if blob[:6] == b"\xfd7zXZ\x00":
        return lzma.decompress(blob)
    if blob[:3] == b"BZh":
        return bz2.decompress(blob)
    if blob[:4] in (b"\x04\x22\x4d\x18", b"\x02\x21\x4c\x18"):
        try:
            import lz4.frame
        except ImportError:
            sys.exit("error: LZ4 ramdisk needs the 'lz4' python module")
        return lz4.frame.decompress(blob)
    return blob  # already uncompressed CPIO


def safe_name(raw):
    name = raw.split(b"\0", 1)[0].decode("utf-8", "surrogateescape")
    while name.startswith(("/", "./")):
        name = name.lstrip("/") if name.startswith("/") else name[2:]
    parts = []
    for part in name.split("/"):
        if part in ("", "."):
            continue
        if part == "..":
            sys.exit("error: unsafe CPIO entry %r" % name)
        parts.append(part)
    if not parts:
        sys.exit("error: empty CPIO entry %r" % name)
    return os.path.join(*parts)


def parse_newc(data, dest):
    off = 0
    count = 0
    while off + 110 <= len(data):
        if data[off:off + 6] not in (b"070701", b"070702"):
            sys.exit("error: bad CPIO magic at 0x%x (got %r)" % (off, data[off:off + 6]))
        fields = [int(data[off + 6 + i * 8:off + 14 + i * 8], 16) for i in range(13)]
        (ino, mode, uid, gid, nlink, mtime, filesize, devmajor, devminor,
         rdevmajor, rdevminor, namesize, check) = fields
        name_start = off + 110
        body = align(name_start + namesize, 4)
        end = body + filesize
        if end > len(data):
            sys.exit("error: truncated CPIO entry")
        raw = data[name_start:name_start + namesize]
        name = safe_name(raw)
        if raw.rstrip(b"\0") == TRAILER:
            break
        target = os.path.join(dest, name)
        os.makedirs(os.path.dirname(target), exist_ok=True)
        fmt = stat.S_IFMT(mode)
        if fmt == stat.S_IFDIR:
            os.makedirs(target, exist_ok=True)
        elif fmt == stat.S_IFREG:
            with open(target, "wb") as f:
                f.write(data[body:end])
            os.chmod(target, mode & 0o7777)
        elif fmt == stat.S_IFLNK:
            link = data[body:end].split(b"\0", 1)[0].decode("utf-8", "surrogateescape")
            if os.path.isabs(link) or ".." in link.split("/"):
                print("    skipping unsafe symlink %s -> %s" % (name, link))
            else:
                os.symlink(link, target)
        else:
            print("    skipping special CPIO entry %s" % name)
        count += 1
        off = align(end, 4)
    print("    unpacked %d CPIO entries" % count)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("image")
    args = ap.parse_args()
    img = os.path.abspath(args.image)
    if not os.path.isfile(img):
        sys.exit("error: %s not found" % img)

    tree = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    prebuilt = os.path.join(tree, "prebuilt")
    tools = os.path.join(tree, "tools")
    os.makedirs(os.path.join(prebuilt, "modules"), exist_ok=True)

    with open(img, "rb") as f:
        info = parse_boot(f.read())

    # Keep the large temporary ramdisk OUTSIDE the device tree.
    workdir = os.path.join(os.path.dirname(tree), "a146p_stock_images")
    os.makedirs(workdir, exist_ok=True)
    work = tempfile.mkdtemp(prefix="extract-", dir=workdir)
    try:
        ramdisk = decompress(info["ramdisk"])
        root = os.path.join(work, "ramdisk")
        os.makedirs(root)
        parse_newc(ramdisk, root)

        for src, dst in (
            ("kernel", os.path.join(prebuilt, "kernel")),
            ("dtb", os.path.join(prebuilt, "dtb.img")),
            ("dtbo", os.path.join(prebuilt, "dtbo.img")),
        ):
            with open(dst, "wb") as f:
                f.write(info[src])
            print("    wrote %s" % os.path.relpath(dst, tree))

        modules_src = os.path.join(root, "lib", "modules")
        modules_dst = os.path.join(prebuilt, "modules")
        if os.path.isdir(modules_src):
            for entry in os.listdir(modules_src):
                src = os.path.join(modules_src, entry)
                if os.path.isfile(src):
                    shutil.copy2(src, os.path.join(modules_dst, entry))
            print("    wrote %d module files" % len(os.listdir(modules_dst)))

        for entry in sorted(os.listdir(root)):
            if entry.startswith("init.recovery.") and entry.endswith(".rc"):
                shutil.copy2(os.path.join(root, entry), os.path.join(tools, "stock_" + entry))
                print("    wrote tools/stock_%s" % entry)
        fstab = os.path.join(root, "system", "etc", "recovery.fstab")
        if os.path.isfile(fstab):
            shutil.copy2(fstab, os.path.join(tools, "stock_recovery.fstab"))
            print("    wrote tools/stock_recovery.fstab")
    finally:
        shutil.rmtree(work)

    print("==> done.  Update BoardConfig.mk from the values above.")


if __name__ == "__main__":
    main()
