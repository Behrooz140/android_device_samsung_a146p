# TWRP device tree — Samsung Galaxy A14 5G (SM-A146P / `a146p`)

TWRP device tree for Samsung Galaxy A14 5G (`SM-A146P`, codename `a146p`, MediaTek MT6833 / Dimensity 700).

> **Status:** Booted and verified on real hardware. Hardware diagnostics confirm the FT8722 touch driver, fastbootd, reboot scripts, and logical partitions. Build-12 fixed build identity, vibrator and diagnostics. Build-13 puts USB in auto role mode (`cmode=1`) and registers USB disks in TWRP's Mount menu through a sysfs-based `/usb_otg` entry, so OTG no longer needs a manual switch. `/data` decryption is not implemented.

## Latest release

- **Build 10:** https://github.com/Behrooz140/android_device_samsung_a146p/releases/tag/build-10
- **CI run:** https://github.com/Behrooz140/android_device_samsung_a146p/actions/runs/45763558190
- **Build commit:** `e6fc6a71b2ac288dbdbec9aebd18ba19fabe9b7c`
- **recovery.img SHA256:** `6251700c57de9e24b1d0e721aef011d4b3869f7fc8466f36db8a4c92bfd7ea2c`
- **Odin tar SHA256:** `7a42a9877b40600b7d4a853c5cbb17fcf0e4d0b68641f64d1549f3d131e29ec0`
- Previous stable: [build-9](https://github.com/Behrooz140/android_device_samsung_a146p/releases/tag/build-9)

## Device specifications

| Item | Value |
|---|---|
| Model | Samsung Galaxy A14 5G |
| Model number | `SM-A146P` |
| Samsung product name | `a14xmxx` / `a14xm` |
| TWRP device name | `a146p` |
| Chipset | MediaTek MT6833 (Dimensity 700) |
| Architecture | arm64-v8a + armeabi-v7a |
| Android | 15 (One UI 7), SDK 35 |
| Stock build | `A146PXXULEZJ3` / `AP3A.240905.015.A2` |
| Security patch | `2026-09-05` |
| Screen density | 450 dpi |
| Recovery partition | 41,943,040 bytes |
| Boot partition | 33,554,432 bytes |

## Prebuilts source

The kernel, DTB, DTBO, and 185 stock modules in `prebuilt/` were extracted directly from this device's stock `recovery.img` (build `A146PXXULEZJ3`). Two additional modules, `focaltech_tp.ko` and `sec_cmd.ko`, provide FT8722 touch support and are compiled against the same stock kernel version. Stock images and extracted ramdisks are kept outside the tree and are not committed.

| File | Size (bytes) | MD5 |
|---|---:|---|
| `prebuilt/kernel` | 14,092,799 | `40d6b66f8aaeae274197748032b2a141` |
| `prebuilt/dtb.img` | 201,775 | `c242c18278a5de98c972069e902935e6` |
| `prebuilt/dtbo.img` | 51,618 | `58b05a34865d2db035da366d00010147` |
| `prebuilt/modules/` | 24 MB | 187 `.ko` files (185 stock + 2 touch) + 4 metadata files |

Kernel: `6.6.127-android15-8-abA146PXXULEZJ3-4k`

## Boot header

Values read from stock `recovery.img` and set in `BoardConfig.mk`:

```text
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

The cmdline is byte-for-byte identical to stock. `androidboot.selinux=permissive` is not added.

## Build

### GitHub Actions

Run the workflow from the Actions tab or push a `v*` tag. Outputs include `recovery.img`, `twrp_a146p.tar.md5`, checksums, and `pinned-manifest.xml`.

The workflow pins Actions to commit SHAs, verifies the `repo` launcher SHA256, does not use `--no-repo-verify`, and separates build/release permissions.

### Local

```sh
repo init -u https://github.com/minimal-manifest-twrp/platform_manifest_twrp_aosp.git -b twrp-12.1
repo sync -c -j$(nproc)
mkdir -p device/samsung
# place this tree at device/samsung/a146p
. build/envsetup.sh
lunch twrp_a146p-eng
mka recoveryimage -j$(nproc)
```

## Flashing

1. Bootloader must be unlocked.
2. Flash a patched/disabled-verification vbmeta if required by your device state:
   ```sh
   fastboot --disable-verity --disable-verification flash vbmeta vbmeta.img
   ```
3. Flash recovery:
   ```sh
   fastboot flash recovery recovery.img
   fastboot reboot recovery
   ```
   Or flash `twrp_a146p.tar.md5` in Odin **AP** slot.

Never flash `preloader`, `lk`, `tee1`, or `tzar`.

## Current status

| Feature | Status |
|---|---|
| Boot, display, storage | Booted on real hardware; storage/logical partitions verified |
| Touch | Confirmed on hardware: `fts_ts` input device with real DOWN/UP events; FT8722 driver and firmware added |
| Logical partitions / GSI | Confirmed in build-9 hardware logs: dynamic partitions are prepared from `super` |
| Reboot / fastbootd | Confirmed in build-9 hardware logs: BCB/misc writes succeed and TWRP enters fastbootd |
| ADB sideload | USB-state timeout guard added; detection/cancel behavior still needs hardware retest |
| `fastbootd` | Enabled; startup with `--fastboot` confirmed on hardware |
| MTP / ADB | Configfs rules present; adb daemon confirmed running |
| USB-OTG host | Build-13 sets `cmode=1` (auto) so the Type-C/PD stack picks device vs host; attached USB disks appear as `USB-OTG` in Mount; `usb_role.sh device|host` remains as a manual fallback |
| Vibrator | Patched to use `/sys/class/leds/vibrator` (the legacy `timed_output` path does not exist) |
| `/data` decryption | Not implemented |
| Backup of logical partitions | Intentionally disabled |

## Build-9 fixes (hardware-confirmed where noted)

- **Touch:** Includes build-8 FT8722 touch fix (driver + firmware).
- **Logical partitions / GSI:** Fixed wipe/flash handling for dynamic/super partitions, enabling proper image flashing to logical partitions (e.g., GSI to `system`). Build-9 logs show all dynamic partitions prepared from `super`.
- **Reboot / Fastbootd:** Fixed reboot handling (BCB/misc fallback). Build-9 logs show the reboot scripts writing the BCB correctly and TWRP entering fastbootd with `--fastboot`.
- **ADB sideload:** Added a USB-state timeout guard to prevent sideload from getting stuck indefinitely; detection still needs hardware retest.
- **Wipe behavior:** Dalvik/cache wipe no longer fails completely when `/data` cannot be mounted; empty/RO logical partition mount errors are handled more cleanly.

## Build-10 changes

- Added `/system/bin/usb_role.sh` for on-demand OTG host/device/auto role switching.
- `twrp-diag.sh` now records how to switch the USB role.
- `tools/verify_recovery.py` now checks that the role script is packaged.
- Local verification: **60 passed, 0 failed**.

## Build-13 changes

- `usb_restrict.sh` now sets `cmode=1` (auto) instead of forcing `cmode=3` (device).
- `twrp.flags` adds a sysfs-based `USB-OTG` storage entry for `musb-hdrc`, with `auto` filesystem detection and wipe/backup disabled.
- `twrp-diag.sh` records all `sdX` devices, their sysfs paths, partitions, USB bus devices and the `usb-storage` driver so a missing OTG mount can be diagnosed.
- `tools/verify_recovery.py` checks the auto role, the safe OTG entry and the new diagnostics.

## USB-OTG host mode and Mount

The bootloader passes `usb_notify_layer.usb_restrict=1`, and Samsung's
`usb_notify_layer.ko` enforces it. Build-13 no longer forces `cmode=3`
(peripheral) at boot; `usb_restrict.sh` sets `cmode=1` (auto) so the Type-C/PD
stack can choose device vs host from the cable/attachment.

Attached USB storage is discovered through the `musb-hdrc` sysfs entry in
`system/etc/twrp.flags`. TWRP adds a `USB-OTG` entry to **Mount** only when a
disk is actually present:

- partitioned USB disk: `/usb_otg-1`, `/usb_otg-2`, ... (one per partition);
- superfloppy (filesystem directly on the disk): the disk itself;
- filesystem is detected with `auto` (vfat/exFAT/NTFS/f2fs/ext4);
- wiping and backup are disabled for this removable entry.

`sda`, `sdb` and `sdc` are internal UFS LUNs; they are deliberately excluded.
USB disks normally appear as a later `sdX` device (`sdd`, `sde`, ...).

`/system/bin/usb_role.sh` remains as a per-boot fallback:

```sh
adb shell /system/bin/usb_role.sh host    # cmode 2: OTG devices get 5 V, adb drops
adb shell /system/bin/usb_role.sh auto    # cmode 1: Type-C/PD stack chooses
adb shell /system/bin/usb_role.sh device  # cmode 3: restore adb/MTP
adb shell /system/bin/usb_role.sh         # print current cmode
```

The same commands work from TWRP's Terminal. Run `host` **before** attaching
the OTG device if auto mode does not switch. A reboot returns to the auto
default; this is a session switch, not a persisted setting.

## Diagnostics

`twrpdiag` writes to `/cache/twrp-diag` and `/tmp/twrp-diag`. It does not mount `/metadata` read-write, dump raw partition headers, or copy TEE logs. Hardware diagnostics also confirmed the FT8722 touch events, the USB-restrict boot state, and the expected FBE mount failure for `/data`. The legacy `timed_output` vibrator path was missing, so patch `0019` makes TWRP use this device's LED-class vibrator instead.

```sh
adb pull /cache/twrp-diag/diag.txt
adb pull /tmp/recovery.log
```

Review logs before sharing; `dmesg` may contain device identifiers.

## Remaining work

1. Hardware retest build-13: auto USB role (PC → adb/MTP, OTG → host), then sideload/cancel, auto-reboot, logical wipe, GSI flash to `system`. Build-12 diagnostics confirmed touch, modules and prop overrides.
2. Confirm exact `super` partition size with `fastboot getvar all` or `lsblk -b`.
3. Port A146P-specific `/data` decryption only when matching A146P TEE/KeyMint/gatekeeper blobs are available.
4. `keydata` and `keyrefuge` exist on this variant but are FBE-protected and cannot be mounted in TWRP yet; verify `carrier` and `hidden` separately (they were outside the sampled `by-name` list).

## Sensitive partitions

`efs`, `persist`, and `nvdata` contain IMEI/radio/sensor data. Keep them read-only/backup-only; never enable wipe for them.
