#!/system/bin/sh
#
# Safe boot diagnostics for TWRP on a146p.
#
# Started as a oneshot service from init.recovery.mt6833.rc. It writes ONLY to
# /tmp and /cache. It never mounts /metadata read-write, never dumps raw
# partition headers, never reads .twrps or TEE/decrypt logs, and never changes
# the vibrator state. Nothing is copied to SD cards automatically: pull the
# folder yourself with `adb pull /cache/twrp-diag`.
#
# Output: /cache/twrp-diag/diag.txt (the interesting file)
#         /cache/twrp-diag/SAVED-TO.txt

LOG=/tmp/twrp-diag
mkdir -p "$LOG" 2>/dev/null

# Let the kernel finish probing deferred display/touch devices and let TWRP
# write its own log. 20s is enough for a boot diagnosis.
sleep 20

{
  echo "== date =="
  date
  echo
  echo "== /proc/cmdline =="
  cat /proc/cmdline 2>/dev/null
  echo
  echo "== /proc/version =="
  cat /proc/version 2>/dev/null
  echo
  echo "== loaded modules (display / touch / input / storage) =="
  # /proc/modules uses underscores in module names; the old hyphenated
  # patterns silently printed almost nothing.
  grep -E 'panel|lcm_|mediatek_drm|mtk_disp|mtk_panel|mtk_kpd|i2c_mt65xx|pinctrl_mt6833|ufs_mediatek|regulator_vibrator|tp_notifier|sec_ext|sec_debug|focaltech_tp|sec_cmd' /proc/modules 2>/dev/null
  echo "-- module count: $(grep -c '^' /proc/modules 2>/dev/null)"
  echo
  echo "== input devices =="
  cat /proc/bus/input/devices 2>/dev/null
  echo
  for e in /sys/class/input/event*; do
    [ -e "$e" ] || continue
    echo "$e = $(cat "$e/device/name" 2>/dev/null)"
  done
  echo
  echo "== i2c devices =="
  ls /sys/bus/i2c/devices 2>/dev/null
  echo
  echo "== block devices =="
  # sda/sdb are internal UFS boot LUNs and sdc is the internal UFS main LUN.
  # USB-OTG disks normally appear as a later sdX device (sdd, sde, ...).
  ls -l /dev/block/sd* /dev/block/mmcblk* 2>/dev/null | head -60
  echo "-- by-name sample"
  ls /dev/block/by-name 2>/dev/null | head -60
  echo
  echo "== USB storage devices (for TWRP Mount / USB-OTG) =="
  for b in /sys/block/sd*; do
    [ -e "$b" ] || continue
    echo "-- $b -> $(readlink -f "$b" 2>/dev/null)"
    echo "   size=$(cat "$b/size" 2>/dev/null)"
    echo "   partitions: $(ls "$b" 2>/dev/null | grep -E '^sd[a-z][0-9]+$' | tr '\n' ' ')"
  done
  echo "-- USB bus devices"
  ls /sys/bus/usb/devices 2>/dev/null | head -60
  echo "-- USB mass-storage driver"
  ls -l /sys/bus/usb/drivers/usb-storage 2>/dev/null | head -40
  echo
  echo "== mounts =="
  cat /proc/mounts 2>/dev/null
  echo
  echo "== USB role =="
  echo "-- cmode: $(cat /sys/class/udc/musb-hdrc/device/cmode 2>/dev/null)"
  echo "-- usb_restrict: $(cat /sys/module/usb_notify_layer/parameters/usb_restrict 2>/dev/null)"
  echo "-- OTG host switch: /system/bin/usb_role.sh host (device|auto)"
  for f in /sys/class/typec/*/data_role /sys/class/typec/*/power_role \
           /sys/class/extcon/*/state; do
    [ -r "$f" ] || continue
    echo "-- $f: $(cat "$f" 2>/dev/null | tr '\n' ' ')"
  done
  echo
  echo "== vibrator (read-only) =="
  echo "-- active trigger: $(tr ' ' '\n' < /sys/class/leds/vibrator/trigger 2>/dev/null | grep -E '^\[.*\]$' | tr -d '[]')"
  echo "-- brightness: $(cat /sys/class/leds/vibrator/brightness 2>/dev/null)"
  echo
  echo "== thermal zones =="
  for z in /sys/class/thermal/thermal_zone*; do
    [ -r "$z/temp" ] || continue
    echo "$z type=$(cat "$z/type" 2>/dev/null) temp=$(cat "$z/temp" 2>/dev/null)"
  done
  echo
  echo "== init service states =="
  getprop 2>/dev/null | grep -E '^\[init\.svc\.' | head -60
  echo
  echo "== relevant properties =="
  getprop 2>/dev/null | grep -iE 'ro\.hardware|sys\.usb|ro\.boot|servicemanager|twrp' | head -80
  echo
  echo "== filtered kernel log (boot / display / touch / storage) =="
  dmesg 2>/dev/null | grep -iE 'panic|oops|fatal|init:|recovery|panel|drm|himax|touch|input:|i2c|ufs|mmc|functionfs|musb|regulator' | tail -250
  echo
  echo "== kernel log tail =="
  dmesg 2>/dev/null | tail -150
  echo
  echo "== previous boot kernel log (if kept) =="
  cat /proc/last_kmsg 2>/dev/null | tail -150
  echo
  echo "== TWRP log highlights =="
  grep -aE 'E:|I:|Unable to mount|Failed|fstab|Start|decrypt|Error' /tmp/recovery.log 2>/dev/null | tail -200
} > "$LOG/diag.txt" 2>&1

cat > "$LOG/README.txt" <<'EOT'
TWRP boot diagnostics (a146p)
=============================

diag.txt   cmdline, modules, input devices, mounts, USB role, filtered
           dmesg, last_kmsg and TWRP log highlights.

This folder is only in /tmp and /cache. Nothing was written to /metadata or
copied to an SD card. Pull it with:

    adb pull /cache/twrp-diag

Review the log before sharing it: dmesg may contain device identifiers.
EOT

# Cache is the only persistent destination. Mount read-write only if TWRP
# has not already mounted it.
: > "$LOG/SAVED-TO.txt"
saved_dir=
if [ -d /cache ] && touch /cache/.twrp-diag-test 2>/dev/null; then
  rm -f /cache/.twrp-diag-test
  saved_dir=/cache/twrp-diag
  mkdir -p "$saved_dir" 2>/dev/null
  cp -f "$LOG"/* "$saved_dir/" 2>/dev/null
  echo "$saved_dir" >> "$LOG/SAVED-TO.txt"
  cp -f "$LOG/SAVED-TO.txt" "$saved_dir/SAVED-TO.txt" 2>/dev/null
fi
if [ -z "$saved_dir" ]; then
  mkdir -p /mnt/cache 2>/dev/null
  if mount -t ext4 -o rw /dev/block/by-name/cache /mnt/cache 2>/dev/null; then
    saved_dir=/mnt/cache/twrp-diag
    mkdir -p "$saved_dir" 2>/dev/null
    cp -f "$LOG"/* "$saved_dir/" 2>/dev/null
    echo "/cache/twrp-diag" >> "$LOG/SAVED-TO.txt"
    cp -f "$LOG/SAVED-TO.txt" "$saved_dir/SAVED-TO.txt" 2>/dev/null
    sync
    umount /mnt/cache 2>/dev/null
  fi
fi

echo "twrp-diag: saved to: $(tr '\n' ' ' < "$LOG/SAVED-TO.txt")" > /dev/kmsg 2>/dev/null
exit 0
