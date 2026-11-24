#
# Copyright (C) 2026 The Android Open Source Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Inherit common TWRP configuration.
$(call inherit-product, vendor/twrp/config/common.mk)

# Inherit from the a146p device.
$(call inherit-product, device/samsung/a146p/device.mk)

PRODUCT_DEVICE := a146p
PRODUCT_NAME := twrp_a146p
PRODUCT_BRAND := samsung
PRODUCT_MODEL := SM-A146P
PRODUCT_MANUFACTURER := samsung

PRODUCT_GMS_CLIENTID_BASE := android-samsung

# Fallback build identity. TW_OVERRIDE_SYSTEM_PROPS in BoardConfig.mk replaces
# these with the values read from the installed system at boot, so the image
# stays correct after firmware updates.
PRODUCT_BUILD_PROP_OVERRIDES += \
    PRIVATE_BUILD_DESC="a14xmxx-user 15 AP3A.240905.015.A2 A146PXXULEZJ3 release-keys"

BUILD_FINGERPRINT := samsung/a14xmxx/a14xm:15/AP3A.240905.015.A2/A146PXXULEZJ3:user/release-keys
