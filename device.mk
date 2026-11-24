#
# Copyright (C) 2026 The Android Open Source Project
#
# SPDX-License-Identifier: Apache-2.0
#

LOCAL_PATH := device/samsung/a146p

# Dynamic partitions (super)
PRODUCT_USE_DYNAMIC_PARTITIONS := true

# Device-tree Soong namespace (root Android.bp). Add decrypt/ here once the
# KeyMint/gatekeeper stack is ported from the a14m tree.
PRODUCT_SOONG_NAMESPACES += device/samsung/a146p

# Explicit ramdisk files. The rest of recovery/root is picked up through
# TARGET_RECOVERY_DEVICE_DIRS in BoardConfig.mk.
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/recovery/root/init.recovery.mt6833.rc:recovery/root/init.recovery.mt6833.rc \
    $(LOCAL_PATH)/recovery/root/init.recovery.samsung.rc:recovery/root/init.recovery.samsung.rc \
    $(LOCAL_PATH)/recovery/root/system/etc/twrp.flags:recovery/root/system/etc/twrp.flags

# Prebuilt kernel modules from the stock recovery ramdisk. They must match
# prebuilt/kernel exactly, otherwise display, touch, storage and USB break.
# No spaces after the commas in $(call ...): make keeps them in the arguments
# and the helper's regex would reject the line.
PRODUCT_COPY_FILES += \
    $(call find-copy-subdir-files,*.ko,$(LOCAL_PATH)/prebuilt/modules,recovery/root/lib/modules) \
    $(LOCAL_PATH)/prebuilt/modules/modules.alias:recovery/root/lib/modules/modules.alias \
    $(LOCAL_PATH)/prebuilt/modules/modules.dep:recovery/root/lib/modules/modules.dep \
    $(LOCAL_PATH)/prebuilt/modules/modules.softdep:recovery/root/lib/modules/modules.softdep \
    $(LOCAL_PATH)/prebuilt/modules/modules.load.recovery:recovery/root/lib/modules/modules.load.recovery

# fastbootd (dynamic partitions)
PRODUCT_PACKAGES += \
    android.hardware.fastboot@1.0-impl-mock \
    fastbootd

# Useful recovery tools
PRODUCT_PACKAGES += \
    crash_dump
