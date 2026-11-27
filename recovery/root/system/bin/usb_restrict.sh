#!/system/bin/sh
# Hand USB role selection back to the Type-C/PD stack (auto mode).
#
# Some Samsung bootloaders pass usb_notify_layer.usb_restrict=1 on the kernel
# command line. Samsung's usb_notify then reserves the vbus event and blocks
# role changes, so earlier builds forced musb into device mode (cmode=3) to
# keep adb/MTP alive. That also prevented OTG host mode without a manual
# /system/bin/usb_role.sh host call.
#
# musb_dr's "cmode" (0 none, 1 normal/auto, 2 host, 3 device) bypasses
# usb_notify. Setting cmode=1 lets the Type-C/PD stack choose the role:
# a PC on CC gives device (adb/MTP), an OTG adapter gives host with VBUS.
# This is a hardware test build; if auto mode breaks adb, run
#   /system/bin/usb_role.sh device
# from TWRP Terminal (touch works) to restore device mode for this boot.
RESTRICT=/sys/module/usb_notify_layer/parameters/usb_restrict
CMODE=/sys/class/udc/musb-hdrc/device/cmode

[ "$(cat "$RESTRICT" 2>/dev/null)" = "1" ] || exit 0
[ -w "$CMODE" ] || exit 0
echo 1 > "$CMODE"
exit 0
