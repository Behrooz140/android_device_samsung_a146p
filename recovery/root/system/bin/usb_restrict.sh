#!/system/bin/sh
# Make adb/MTP work when the bootloader restricts USB.
#
# Some Samsung bootloaders pass usb_notify_layer.usb_restrict=1 on the kernel
# command line. Samsung's usb_notify then disables all USB operations and
# reserves the vbus event, so mtk_set_peripheral() is never reached and musb
# stays at USB_ROLE_NONE. The parameter is read-only and libmodprobe appends
# command-line options last, so it cannot be overridden from the ramdisk.
#
# musb_dr's "cmode" (0 none, 1 normal, 2 host, 3 device) bypasses usb_notify
# and switches the role directly. Force device mode only when the restriction
# is actually set, so units without it keep normal host/OTG switching.
RESTRICT=/sys/module/usb_notify_layer/parameters/usb_restrict
CMODE=/sys/class/udc/musb-hdrc/device/cmode

[ "$(cat "$RESTRICT" 2>/dev/null)" = "1" ] || exit 0
[ -w "$CMODE" ] || exit 0
echo 3 > "$CMODE"
exit 0
