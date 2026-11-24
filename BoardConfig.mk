#
# Device tree for Samsung Galaxy A14 5G (SM-A146P / a146p)
# MediaTek MT6833 (Dimensity 700) - Android 15 (One UI 7)
#
# Every blob in prebuilt/ was extracted from the phone's own stock
# recovery.img: A146PXXULEZJ3 / AP3A.240905.015.A2 / 2026-09-05.
#
# SPDX-License-Identifier: Apache-2.0
#

DEVICE_PATH := device/samsung/a146p

# ----------------------------------------------------------------------------
# Build / minimal manifest
# ----------------------------------------------------------------------------
ALLOW_MISSING_DEPENDENCIES := true

# Kernel modules are ELF relocatable objects copied into the recovery ramdisk
# at /lib/modules. The build system rejects ELF files in PRODUCT_COPY_FILES
# whose destination contains "lib", so disable that check explicitly.
BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES := true

# ----------------------------------------------------------------------------
# Architecture
# ----------------------------------------------------------------------------
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := generic
TARGET_CPU_VARIANT_RUNTIME := cortex-a76

TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv7-a-neon
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := generic
TARGET_2ND_CPU_VARIANT_RUNTIME := cortex-a55

# ----------------------------------------------------------------------------
# Bootloader / platform
# ----------------------------------------------------------------------------
TARGET_BOOTLOADER_BOARD_NAME := a146p
TARGET_BOARD_PLATFORM := mt6833
TARGET_NO_BOOTLOADER := true

# ----------------------------------------------------------------------------
# Display
# ----------------------------------------------------------------------------
TARGET_SCREEN_DENSITY := 450
TARGET_USES_VULKAN := true

# ----------------------------------------------------------------------------
# Kernel (prebuilt from stock recovery.img)
#
# Stock boot header (verified from recovery.img):
#   header version : 2
#   page size      : 4096
#   kernel  addr   : 0x40080000
#   ramdisk addr   : 0x51100000
#   tags    addr   : 0x47C80000
#   dtb     addr   : 0x47C80000
#   board name     : SRPVH12A021
#   os version     : 15.0.0 / 2026-09
#   cmdline        : bootopt=64S3,32N2,64N2 loop.max_part=7
#   ramdisk format : gzip (stock kernel also supports LZ4)
#
# The cmdline is deliberately kept byte-for-byte identical to stock; do NOT
# append androidboot.selinux=permissive here. TWRP switches SELinux to
# permissive itself in its own init, without changing the boot header.
# ----------------------------------------------------------------------------
BOARD_BOOTIMG_HEADER_VERSION := 2
BOARD_KERNEL_BASE := 0x40078000
BOARD_KERNEL_CMDLINE := bootopt=64S3,32N2,64N2 loop.max_part=7
BOARD_KERNEL_PAGESIZE := 4096
BOARD_RAMDISK_OFFSET := 0x11088000
BOARD_KERNEL_TAGS_OFFSET := 0x07c08000
BOARD_KERNEL_IMAGE_NAME := Image.gz

BOARD_MKBOOTIMG_ARGS += --header_version $(BOARD_BOOTIMG_HEADER_VERSION)
BOARD_MKBOOTIMG_ARGS += --ramdisk_offset $(BOARD_RAMDISK_OFFSET)
BOARD_MKBOOTIMG_ARGS += --tags_offset $(BOARD_KERNEL_TAGS_OFFSET)
BOARD_MKBOOTIMG_ARGS += --dtb_offset 0x07c08000
BOARD_MKBOOTIMG_ARGS += --board SRPVH12A021
BOARD_MKBOOTIMG_ARGS += --os_version 15.0.0 --os_patch_level 2026-09

TARGET_FORCE_PREBUILT_KERNEL := true
TARGET_PREBUILT_KERNEL := $(DEVICE_PATH)/prebuilt/kernel
TARGET_PREBUILT_DTB := $(DEVICE_PATH)/prebuilt/dtb.img
BOARD_MKBOOTIMG_ARGS += --dtb $(TARGET_PREBUILT_DTB)

BOARD_PREBUILT_DTBOIMAGE := $(DEVICE_PATH)/prebuilt/dtbo.img
BOARD_INCLUDE_RECOVERY_DTBO := true

# ----------------------------------------------------------------------------
# Partitions
# ----------------------------------------------------------------------------
BOARD_FLASH_BLOCK_SIZE := 262144 # 4096 * 64
BOARD_BOOTIMAGE_PARTITION_SIZE := 33554432
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 41943040

BOARD_HAS_LARGE_FILESYSTEM := true
BOARD_SYSTEMIMAGE_PARTITION_TYPE := ext4
BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := ext4
TARGET_COPY_OUT_VENDOR := vendor

# Dynamic partitions (super).
# NOTE: the exact super size must be confirmed with `lsblk -b` or
# `fastboot getvar all` on the device; 9126805504 is the value used by the
# sibling A14 tree and is only a safe placeholder for building this image.
BOARD_SUPER_PARTITION_SIZE := 9126805504
BOARD_SUPER_PARTITION_GROUPS := samsung_dynamic_partitions
BOARD_SAMSUNG_DYNAMIC_PARTITIONS_PARTITION_LIST := \
    system \
    system_ext \
    product \
    vendor \
    odm \
    system_dlkm \
    vendor_dlkm \
    odm_dlkm
BOARD_SAMSUNG_DYNAMIC_PARTITIONS_SIZE := 9122611200

# ----------------------------------------------------------------------------
# Recovery
# ----------------------------------------------------------------------------
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/recovery.fstab
# recovery/root is copied into the ramdisk (init rc files, scripts, flags).
TARGET_RECOVERY_DEVICE_DIRS += $(DEVICE_PATH)
TARGET_RECOVERY_PIXEL_FORMAT := BGRA_8888
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true
TARGET_USES_MKE2FS := true

BOARD_USES_METADATA_PARTITION := true
BOARD_ROOT_EXTRA_FOLDERS += metadata

# ----------------------------------------------------------------------------
# Verified boot
# ----------------------------------------------------------------------------
# Stock firmware is AVB-signed with the Samsung key. An image built with the
# AOSP test key will not verify against it: unlock the bootloader and flash a
# patched vbmeta.img (or use fastboot --disable-verification) before flashing.
BOARD_AVB_ENABLE := true
BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --flags 3
BOARD_AVB_RECOVERY_KEY_PATH := external/avb/test/data/testkey_rsa4096.pem
BOARD_AVB_RECOVERY_ALGORITHM := SHA256_RSA4096
BOARD_AVB_RECOVERY_ROLLBACK_INDEX := 1
BOARD_AVB_RECOVERY_ROLLBACK_INDEX_LOCATION := 1

# Keep the build from being blocked by an older installed security patch.
PLATFORM_SECURITY_PATCH := 2099-12-31
VENDOR_SECURITY_PATCH := 2099-12-31
PLATFORM_VERSION := 16.1.0

# ----------------------------------------------------------------------------
# TWRP
# ----------------------------------------------------------------------------
TW_THEME := portrait_hdpi
# Move the status-bar clock into the left gap next to the waterdrop notch.
TW_CUSTOM_CLOCK_POS := 280
TW_EXTRA_LANGUAGES := true
TW_DEVICE_VERSION := a146p
TW_SCREEN_BLANK_ON_BOOT := true
TW_NO_SCREEN_BLANK := true
TW_INPUT_BLACKLIST := "hbtp_vm"
TW_USE_TOOLBOX := true

# Display / backlight (mediatek,lcd-backlight, max 0xff)
TW_BRIGHTNESS_PATH := "/sys/class/leds/lcd-backlight/brightness"
TW_MAX_BRIGHTNESS := 255
TW_DEFAULT_BRIGHTNESS := 160

# Samsung specifics
TW_NO_REBOOT_BOOTLOADER := true
TW_HAS_DOWNLOAD_MODE := true

# Tools / features
TW_INCLUDE_FASTBOOTD := true
TW_INCLUDE_REPACKTOOLS := true
TW_INCLUDE_LIBRESETPROP := true
TW_INCLUDE_RESETPROP := true
TW_INCLUDE_NTFS_3G := true
TW_INCLUDE_LPTOOLS := true
TW_EXCLUDE_TWRPAPP := true
# The 6.6 kernel rejects TWRP's APEX loop loader ("Value too large for
# defined data type"); nothing here needs APEX libraries.
TW_EXCLUDE_APEX := true
RECOVERY_SDCARD_ON_DATA := true

# Read the real build identity from the installed system at boot. The values
# compiled into twrp_a146p.mk are only a fallback when /system cannot be read.
TW_OVERRIDE_SYSTEM_PROPS := \
    "ro.build.fingerprint=ro.system.build.fingerprint;\
    ro.build.description;\
    ro.build.version.incremental;\
    ro.build.version.release;\
    ro.build.version.security_patch"

# ----------------------------------------------------------------------------
# Crypto (FBE + metadata encryption)
# ----------------------------------------------------------------------------
# Keep FBE support so TWRP recognizes /data as encrypted and shows the
# password prompt. TWRP's own metadata-decrypt path is disabled because it
# waits for keystore2, which is not available in recovery on this device.
# /data decryption itself is not implemented yet (see README.md).
TW_INCLUDE_CRYPTO := true
TW_INCLUDE_CRYPTO_FBE := true
TW_INCLUDE_FBE_METADATA_DECRYPT := false
