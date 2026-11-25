# TWRP device tree — Samsung Galaxy A14 5G (SM-A146P / `a146p`)

> **وضعیت فعلی:** درخت پایه ساخته شده است. هنوز بیلد نشده و روی دستگاه تست نشده است.
> رمزگشایی `/data` و پچهای TWRP هنوز پورت نشدهاند (بخش ۷ را ببینید).

---

## ۱) مشخصات دستگاه

| مورد | مقدار |
|---|---|
| مدل | Samsung Galaxy A14 5G |
| مدل تجاری | `SM-A146P` |
| نام محصول سامسونگ | `a14xmxx` / `a14xm` |
| نام درخت TWRP | `a146p` |
| چیپست | MediaTek **MT6833** (Dimensity 700) |
| معماری | arm64-v8a + armeabi-v7a |
| اندروید | ۱۵ (One UI 7)، SDK 35 |
| بیلد استوک | `A146PXXULEZJ3` / `AP3A.240905.015.A2` |
| سطح امنیتی | `2026-09-05` |
| fingerprint | `samsung/a14xmxx/a14xm:15/AP3A.240905.015.A2/A146PXXULEZJ3:user/release-keys` |
| تراکم صفحه | 450 dpi |
| اندازه پارتیشن recovery | ۴۱۹۴۳۰۴۰ بایت |
| اندازه پارتیشن boot | ۳۳۵۵۴۴۳۲ بایت |

---

## ۲) منبع فایلها

تمام فایلهای `prebuilt/` مستقیماً از `recovery.img` استوک همین دستگاه استخراج
شدهاند (نه از اینترنت و نه از دستگاه مشابه دیگری).

| فایل | اندازه (بایت) | MD5 |
|---|---:|---|
| `prebuilt/kernel` | ۱۴٬۰۹۲٬۷۹۹ | `40d6b66f8aaeae274197748032b2a141` |
| `prebuilt/dtb.img` | ۲۰۱٬۷۷۵ | `c242c18278a5de98c972069e902935e6` |
| `prebuilt/dtbo.img` | ۵۱٬۶۱۸ | `58b05a34865d2db035da366d00010147` |
| `prebuilt/modules/` | ۲۴ MB | ۱۸۵ فایل `.ko` + ۴ فایل متادیتا |

ورژن کرنل: `6.6.127-android15-8-abA146PXXULEZJ3-4k`

### هش ایمیجهای استوک تحویلدادهشده

ایمیجها و ramdisk استخراجشده **خارج از درخت** در `/root/a146p_stock_images/` نگهداری
میشوند و وارد مخزن نمیشوند.

| ایمیج | MD5 |
|---|---|
| `recovery.img` | `ecceb5b20f0ea2935a43d0f5c6f1988f` |
| `boot.img` | `4db0c14f81f11b70196cc45a24e34a0a` |
| `init_boot.img` | `04ccd40c0580c61f026a7ed033536462` |
| `vendor_boot.img` | `9ea62afbe2deb9e4c048a6a462e125fb` |
| `dtbo.img` | `fe8f1179a650358bcf525423b4369042` |
| `vbmeta.img` | `abc7a3ecb0a4cb47e3f5266be0128a79` |

> ایمیجها نباید در مخزن کامیت شوند (`.gitignore` آنها را مستثنی میکند).

---

## ۳) هدر بوت

مقادیر زیر از هدر `recovery.img` استوک خوانده شدهاند و در `BoardConfig.mk`
تنظیم شدهاند:

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

cmdline عمداً دقیقاً همان چیزی است که استوک دارد. `androidboot.selinux=permissive`
اضافه نشده است؛ TWRP خودش SELinux را در init permissive میکند.

---

## ۴) ساختار درخت

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
│   └── modules/          ← 185 ماژول + modules.alias/dep/softdep/load.recovery
├── recovery/root/
│   ├── init.recovery.mt6833.rc
│   ├── init.recovery.samsung.rc
│   ├── sbin/twrp-diag.sh          ← لاگ تشخیصی بوت (فقط /tmp و /cache)
│   └── system/
│       ├── bin/usb_restrict.sh
│       └── etc/twrp.flags
└── tools/
    ├── extract_from_recovery.py
    ├── stock_init.recovery.mt6833.rc
    ├── stock_init.recovery.samsung.rc
    └── stock_recovery.fstab
```

برای استخراج مجدد prebuiltها:

```sh
python3 tools/extract_from_recovery.py /root/a146p_stock_images/recovery.img
```

اسکریپت ورودیهای CPIO ناامن (مسیر مطلق، `..` و symlink خارج از رamdisk) را رد
میکند و فقط داخل همین درخت مینویسد.

---

## ۵) بیلد

در GitHub Actions: تب Actions → Run workflow. خروجیها:

- `recovery.img`
- `twrp_a146p.tar.md5` (برای Odin، جایگاه AP)
- `pinned-manifest.xml` (کامیت دقیق منابع استفادهشده)
- `MD5SUMS.txt` / `SHA256SUMS.txt`

محلی:

```sh
repo init -u https://github.com/minimal-manifest-twrp/platform_manifest_twrp_aosp.git -b twrp-12.1
repo sync -c -j$(nproc)
mkdir -p device/samsung
ln -s /root/android_device_samsung_a146p device/samsung/a146p
. build/envsetup.sh
lunch twrp_a146p-eng
mka recoveryimage -j$(nproc)
```

> workflow اکشنها را با SHA ثابت پین میکند، هش `repo` را چک میکند و از
> `--no-repo-verify` استفاده نمیکند. پچها بهطور خودکار اعمال نمیشوند تا زمانی
> که روی نسخهٔ دقیق منابع rebase و تست شوند.

---

## ۶) فلش

1. بوتلودر باید آنلاک شده باشد.
2. vbmeta استوک امضاشده با کلید سامسونگ است؛ تصویر ساختهشده با کلید تست TWRP
   verify نمیشود. قبل از فلش vbmeta را patch/disable کنید:

   ```sh
   fastboot flash vbmeta vbmeta.img   # vbmeta اصلاحشده
   ```

   یا در هر فلش: `fastboot --disable-verity --disable-verification flash vbmeta vbmeta.img`

3. فلش ریکاوری:

   ```sh
   fastboot flash recovery recovery.img
   fastboot reboot recovery
   ```

   یا `twrp_a146p.tar.md5` را در جایگاه AP با Odin فلش کنید.

هیچگاه `preloader`، `lk`، `tee1` یا `tzar` را فلش نکنید.

---

## ۷) وضعیت قابلیتها

| قابلیت | وضعیت |
|---|---|
| بوت، نمایش، ذخیرهسازی | ✅ روی دستگاه واقعی بوت شد؛ ذخیرهسازی و پارتیشنهای منطقی بررسی شدند |
| تاچ | درایور `focaltech_tp.ko` بههمراه فریمور اضافه شد؛ منتظر تست مجدد روی دستگاه |
| پارتیشنهای منطقی `super` | mount فقطخواندنی و `flashimg` در fstab تنظیم شده |
| `fastbootd` | فعال |
| MTP / ADB | قواعد configfs در init rc اضافه شده |
| ویبره | در init خاموش میشود تا موتور روشن نماند |
| `/data` decryption | ❌ پیادهسازی نشده |
| بکاپ از پارتیشنهای منطقی | ❌ عمداً غیرفعال است |
| لاگ تشخیصی بوت | ✅ `sbin/twrp-diag.sh` |

اولین تست روی دستگاه واقعی TWRP بوت شد ولی تاچ کار نمیکرد. ramdisk استوک فقط
درایور سنسور grip (`hx9035.ko`) را دارد؛ کنترلر واقعی تاچ برای پنل انتخابشدهٔ
`ft8722` یک ماژول `vendor_dlkm` است. اکنون این ماژول بهصورت `focaltech_tp.ko`
همراه وابستگی `sec_cmd.ko` و فایلهای `focaltech_ft8722_fw_txd.bin` و
`focaltech_ft8722_txd.ini` اضافه شده و بعد از `tp_notifier.ko` از
`modules.load.recovery` بارگذاری میشود.

برای جا شدن در پارتیشن ۴۰ مگابایتی استوک، قابلیتهای اختیاری `NTFS-3G`،
`lptools`، `lpdump`، `nano`، ابزار مستقل `zip`، ابزارهای repack، زبانهای اضافه
و کل مجموعهٔ رمزنگاری/keystore2 غیرفعال شدهاند. اینها برای فلش، پاک کردن،
sideload، بکاپ و ریستور در A146P لازم نیستند و اگر بعداً نیاز اختیاری مشخصی
تأیید شود و ایمج باز هم جا شود، میشود آنها را فعال کرد. با غیرفعال بودن
رمزنگاری، `/data` تا زمان پورت شدن مجموعهٔ رمزگشایی مخصوص A146P در TWRP قابل
خواندن نخواهد بود.

### گرفتن لاگ وقتی بوت نشد

سرویس `twrpdiag` حدود ۲۰ ثانیه بعد از بوت اجرا میشود و خروجی را فقط در
`/cache/twrp-diag` میگذارد (و یک کپی موقت در `/tmp/twrp-diag`). برخلاف نسخهٔ
قدیمی `a14m`، این اسکریپت `/metadata` را rw نمیکند، هدر پارتیشنها و فایل
`.twrps` را نمیخواند، لاگ TEE را کپی نمیکند و ویبره را دستکاری نمیکند.

```sh
adb pull /cache/twrp-diag/diag.txt
adb pull /tmp/recovery.log
```

اگر TWRP اصلاً بالا نیامد، بعد از ریبوت به سیستم همان `diag.txt` شامل
`/proc/last_kmsg` (لاگ کرنل بوت قبل) هم هست. قبل از ارسال لاگ آن را بررسی کنید،
چون `dmesg` میتواند شناسهٔ دستگاه را نشان دهد.

### کارهای باقیمانده

1. بیلد اول و تست بوت روی دستگاه.
2. پچهای عمومی TWRP (مخصوصاً مربوط به logical partitions و wipe) را روی
   کامیت دقیق منابع rebase و تست کردن.
3. پورت stack رمزگشایی (TEEGRIS + KeyMint + gatekeeper) از درخت `a14m`، در
   صورتی که فایلهای مربوطه از دستگاه A146P در دسترس باشند.
4. تأیید اندازه دقیق `super` با `lsblk -b` یا `fastboot getvar all` روی دستگاه.
5. بررسی وجود پارتیشنهای `carrier`, `hidden`, `keydata`, `keyrefuge` در fstab.

---

## ۸) نکته دربارهٔ پارتیشنهای حساس

`efs`، `persist` و `nvdata` حاوی IMEI و کالیبراسیون رادیو هستند. در fstab فقط
برای بکاپ و بهصورت فقطخواندنی تعریف شدهاند و نباید گزینهٔ wipe برایشان فعال شود.
