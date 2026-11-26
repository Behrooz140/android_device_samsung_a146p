# TWRP device tree — Samsung Galaxy A14 5G (SM-A146P / `a146p`)

TWRP device tree for Samsung Galaxy A14 5G (`SM-A146P`, codename `a146p`, MediaTek MT6833 / Dimensity 700).

> **Status:** Booted and verified on real hardware. Build-9 logs confirm fastbootd, reboot scripts, and logical partitions; the touch fix is carried over from build-8. Build-10 adds an on-demand USB-OTG host switch. `/data` decryption is not implemented.

## Latest release

- **Build 9:** https://github.com/Behrooz140/android_device_samsung_a146p/releases/tag/build-9
- **CI run:** https://github.com/Behrooz140/android_device_samsung_a146p/actions/runs/45610667417
- **recovery.img SHA256:** `85b693f45c914680c642f3818c36f605a69f66633c591e429977b454f17cd6fa`

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

Everything in `prebuilt/` was extracted directly from the stock `recovery.img` for this device. Stock images and extracted ramdisk are kept outside the tree in `/root/a146p_stock_images/` on the build machine and are not committed.

| File | Size (bytes) | MD5 |
|---|---:|---|
| `prebuilt/kernel` | 14,092,799 | `40d6b66f8aaeae274197748032b2a141` |
| `prebuilt/dtb.img` | 201,775 | `c242c18278a5de98c972069e902935e6` |
| `prebuilt/dtbo.img` | 51,618 | `58b05a34865d2db035da366d00010147` |
| `prebuilt/modules/` | 24 MB | 185 `.ko` files + 4 metadata files |

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
| Touch | FT8722 `focaltech_tp.ko` + firmware added; awaiting hardware retest |
| Logical partitions / GSI | Confirmed in build-9 hardware logs: dynamic partitions are prepared from `super` |
| Reboot / fastbootd | Confirmed in build-9 hardware logs: BCB/misc writes succeed and TWRP enters fastbootd |
| ADB sideload | USB-state timeout guard added; detection/cancel behavior still needs hardware retest |
| `fastbootd` | Enabled; startup with `--fastboot` confirmed on hardware |
| MTP / ADB | Configfs rules present; adb daemon confirmed running |
| USB-OTG host | Disabled by default because `usb_restrict=1` forces device mode; build-10 adds `/system/bin/usb_role.sh host` |
| `/data` decryption | Not implemented |
| Backup of logical partitions | Intentionally disabled |

## Build-9 fixes (hardware-confirmed where noted)

- **Touch:** Includes build-8 FT8722 touch fix (driver + firmware).
- **Logical partitions / GSI:** Fixed wipe/flash handling for dynamic/super partitions, enabling proper image flashing to logical partitions (e.g., GSI to `system`). Build-9 logs show all dynamic partitions prepared from `super`.
- **Reboot / Fastbootd:** Fixed reboot handling (BCB/misc fallback). Build-9 logs show the reboot scripts writing the BCB correctly and TWRP entering fastbootd with `--fastboot`.
- **ADB sideload:** Added a USB-state timeout guard to prevent sideload from getting stuck indefinitely; detection still needs hardware retest.
- **Wipe behavior:** Dalvik/cache wipe no longer fails completely when `/data` cannot be mounted; empty/RO logical partition mount errors are handled more cleanly.

## USB-OTG host mode

The bootloader passes `usb_notify_layer.usb_restrict=1`, so `usb_restrict.sh`
forces `cmode=3` (peripheral) at boot to keep adb/MTP working. That also keeps
OTG VBUS off, so USB drives, mice, and keyboards will not power up.

Build-10 adds `/system/bin/usb_role.sh` to override the role for the current
boot:

```sh
adb shell /system/bin/usb_role.sh host    # cmode 2: OTG devices get 5 V, adb drops
adb shell /system/bin/usb_role.sh auto    # cmode 1: Type-C/PD stack chooses
adb shell /system/bin/usb_role.sh device  # cmode 3: restore adb/MTP
adb shell /system/bin/usb_role.sh         # print current cmode
```

The same commands work from TWRP's Terminal. Run `host` **before** attaching the
OTG device; a reboot always returns to device mode. This is a session switch,
not a persisted setting.

## Diagnostics

`twrpdiag` writes to `/cache/twrp-diag` and `/tmp/twrp-diag`. It does not mount `/metadata` read-write, dump raw partition headers, or copy TEE logs.

```sh
adb pull /cache/twrp-diag/diag.txt
adb pull /tmp/recovery.log
```

Review logs before sharing; `dmesg` may contain device identifiers.

## Remaining work

1. Hardware retest build-10: USB-OTG host switch, sideload/cancel, auto-reboot, logical wipe, GSI flash to `system`. Build-9 already confirmed fastbootd and reboot scripts.
2. Confirm exact `super` partition size with `fastboot getvar all` or `lsblk -b`.
3. Port A146P-specific `/data` decryption only when matching A146P TEE/KeyMint/gatekeeper blobs are available.
4. Confirm presence of `carrier`, `hidden`, `keydata`, `keyrefuge` on target variant before relying on them.

## Sensitive partitions

`efs`, `persist`, and `nvdata` contain IMEI/radio/sensor data. Keep them read-only/backup-only; never enable wipe for them.
