# TWRP device tree — Samsung Galaxy A14 5G (SM-A146P / `a146p`)

> **Status:** base tree only. The first CI build is in progress and the tree has
> not been tested on the device yet. `/data` decryption and TWRP source patches
> have not been ported (see [Current status](#8-current-status)).

A Persian translation is available in [README.fa.md](README.fa.md).

---

## 1) Device specifications

| Item | Value |
|---|---|
| Model | Samsung Galaxy A14 5G |
| Model number | `SM-A146P` |
| Samsung product name | `a14xmxx` / `a14xm` |
| TWRP device name | `a146p` |
| Chipset | MediaTek **MT6833** (Dimensity 700) |
| Architecture | arm64-v8a + armeabi-v7a |
| Android | 15 (One UI 7), SDK 35 |
| Stock build | `A146PXXULEZJ3` / `AP3A.240905.015.A2` |
| Security patch | `2026-09-05` |
| Fingerprint | `samsung/a14xmxx/a14xm:15/AP3A.240905.015.A2/A146PXXULEZJ3:user/release-keys` |
| Screen density | 450 dpi |
| Recovery partition | 41,943,040 bytes |
| Boot partition | 33,554,432 bytes |

---

## 2) Source of the prebuilts

Everything in `prebuilt/` was extracted directly from this phone's own stock
`recovery.img` — nothing was downloaded and no similar device was used as a
source.

| File | Size (bytes) | MD5 |
|---|---:|---|
| `prebuilt/kernel` | 14,092,799 | `40d6b66f8aaeae274197748032b2a141` |
| `prebuilt/dtb.img` | 201,775 | `c242c18278a5de98c972069e902935e6` |
| `prebuilt/dtbo.img` | 51,618 | `58b05a34865d2db035da366d00010147` |
| `prebuilt/modules/` | 24 MB | 185 `.ko` files + 4 metadata files |

Kernel version: `6.6.127-android15-8-abA146PXXULEZJ3-4k`

### Hashes of the supplied stock images

The stock images and the extracted ramdisk are kept **outside the device tree**
in `/root/a146p_stock_images/` on the build machine. They are never committed.

| Image | MD5 |
|---|---|
| `recovery.img` | `ecceb5b20f0ea2935a43d0f5c6f1988f` |
| `boot.img` | `4db0c14f81f11b70196cc45a24e34a0a` |
| `init_boot.img` | `04ccd40c0580c61f026a7ed033536462` |
| `vendor_boot.img` | `9ea62afbe2deb9e4c048a6a462e125fb` |
| `dtbo.img` | `fe8f1179a650358bcf525423b4369042` |
| `vbmeta.img` | `abc7a3ecb0a4cb47e3f5266be0128a79` |

Stock images must not be committed (`.gitignore` excludes them; the two
`prebuilt/*.img` blobs are explicitly re-included).

---

## 3) Boot header

These values were read from the stock `recovery.img` header and are set in
`BoardConfig.mk`:

```
header version : 2
page size      : 4096
kernel  addr   : 0x40080000
ramdisk addr   : 0x51100000
tags    addr   : 0x47C80000
dtb     addr   : 0x47C80000
board name     : SRPVH12A021
os version     : 15.0.0 / 2026-09
cmdline        : bootopt=64S3,32N2,64N2 loop.max_part=7
ramdisk format : gzip
```

The cmdline is deliberately byte-for-byte identical to stock.
`androidboot.selinux=permissive` is **not** appended: TWRP switches SELinux to
permissive in its own init, without modifying the boot header.

---

## 4) Tree structure

```
device/samsung/a146p/
├── .github/workflows/build-twrp.yml
├── .gitignore
├── Android.bp / Android.mk / AndroidProducts.mk
├── BoardConfig.mk
├── device.mk
├── twrp_a146p.mk
├── vendorsetup.sh
├── recovery.fstab
├── prebuilt/
│   ├── kernel
│   ├── dtb.img
│   ├── dtbo.img
│   └── modules/          ← 185 modules + modules.alias/dep/softdep/load.recovery
├── recovery/root/
│   ├── init.recovery.mt6833.rc
│   ├── init.recovery.samsung.rc
│   ├── sbin/twrp-diag.sh          ← boot diagnostics (/tmp and /cache only)
│   └── system/
│       ├── bin/usb_restrict.sh
│       └── etc/twrp.flags
└── tools/
    ├── extract_from_recovery.py
    ├── stock_init.recovery.mt6833.rc
    ├── stock_init.recovery.samsung.rc
    └── stock_recovery.fstab
```

To re-extract the prebuilts:

```sh
python3 tools/extract_from_recovery.py /path/to/recovery.img
```

The extractor rejects unsafe CPIO entries (absolute paths, `..` and symlinks
pointing outside the ramdisk) and places its temporary unpack directory next
to the images, outside the tree.

---

## 5) Building

### GitHub Actions

Open the **Actions** tab and run the workflow (`Run workflow`), or push a `v*`
tag. Outputs:

- `recovery.img`
- `twrp_a146p.tar.md5` (Odin package, AP slot)
- `pinned-manifest.xml` (exact source revisions used by that build)
- `MD5SUMS.txt` / `SHA256SUMS.txt`

The workflow pins Actions to commit SHAs, verifies the `repo` launcher against
a fixed SHA256, does not use `--no-repo-verify`, and splits build (read-only)
and release (write) permissions. Patches are **not** applied automatically
until they have been rebased and tested against the exact source revision.

### Local

```sh
repo init -u https://github.com/minimal-manifest-twrp/platform_manifest_twrp_aosp.git -b twrp-12.1
repo sync -c -j$(nproc)
mkdir -p device/samsung
ln -s "$(pwd)" device/samsung/a146p      # from this device tree's directory
. build/envsetup.sh
lunch twrp_a146p-eng
mka recoveryimage -j$(nproc)
```

---

## 6) Flashing

1. The bootloader must be unlocked.
2. Stock vbmeta is signed with the Samsung key; an image built with TWRP's test
   key will not verify against it. Patch/disable verification first:

   ```sh
   fastboot flash vbmeta vbmeta.img      # patched vbmeta
   ```

   or, for a one-off boot:

   ```sh
   fastboot --disable-verity --disable-verification flash vbmeta vbmeta.img
   ```

3. Flash recovery:

   ```sh
   fastboot flash recovery recovery.img
   fastboot reboot recovery
   ```

   Alternatively flash `twrp_a146p.tar.md5` in Odin's **AP** slot.

Never flash `preloader`, `lk`, `tee1` or `tzar` — doing so can hard-brick the
device.

---

## 7) Verified boot / identity notes

`BoardConfig.mk` uses `BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --flags 3` and the
AOSP test key, and sets future security patch values plus `PLATFORM_VERSION :=
16.1.0` so the build is not blocked by an older installed patch level. These
are build-time values only; they do not change Android's real version reported
by the running system (which is read at boot via `TW_OVERRIDE_SYSTEM_PROPS`).

---

## 8) Current status

| Feature | Status |
|---|---|
| Boot, display, touch, storage | Expected to work (stock modules); not tested yet |
| Logical (`super`) partitions | Read-only mount and `flashimg` configured in fstab |
| `fastbootd` | Enabled |
| MTP / ADB | configfs rules added in init rc |
| Vibrator | Turned off in init so the motor cannot stay on |
| `/data` decryption | ❌ Not implemented |
| Backup of logical partitions | ❌ Intentionally disabled |
| Boot diagnostics | ✅ `sbin/twrp-diag.sh` |

### Getting logs when the device will not boot

The `twrpdiag` service runs about 20 seconds after boot and writes only to
`/cache/twrp-diag` (plus a volatile copy in `/tmp/twrp-diag`). Unlike the older
`a14m` script, it never mounts `/metadata` read-write, never dumps raw partition
headers or `.twrps`, never copies TEE logs and never touches the vibrator.

```sh
adb pull /cache/twrp-diag/diag.txt
adb pull /tmp/recovery.log
```

If TWRP does not start at all, `diag.txt` pulled after rebooting into the system
also includes `/proc/last_kmsg` (the previous boot's kernel log). Review the log
before sharing it: `dmesg` may contain device identifiers.

### Remaining work

1. Finish the first build and test boot on the device.
2. Rebase and test the generic TWRP patches (especially logical partitions and
   wipe handling) against the exact source revision used by CI.
3. Port the decryption stack (TEEGRIS + KeyMint + gatekeeper) from the `a14m`
   tree, if the corresponding A146P binaries become available.
4. Confirm the exact `super` partition size with `lsblk -b` or
   `fastboot getvar all` on the device; the current value is a placeholder.
5. Verify whether `carrier`, `hidden`, `keydata` and `keyrefuge` exist on this
   variant before relying on their fstab entries.

---

## 9) Sensitive partitions

`efs`, `persist` and `nvdata` contain IMEI, radio calibration and sensor data.
They are defined in `recovery.fstab` read-only, for backup only; wipe must never
be enabled for them.
