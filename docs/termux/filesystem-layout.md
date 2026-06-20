> **Fonte**: https://github.com/termux/termux-packages/wiki/Termux-file-system-layout
> **Snapshot**: 19/06/2026
> **Formato**: Termux wiki - File system layout

# Termux Filesystem Layout

The following docs provide info on Android and Termux paths, and their differences.

---

## Android Paths

| Path | Description |
|---|---|
| `/` | The filesystem rootfs. Usually a ramdisk, but on modern Android OS it is a mounted system partition. |
| `/bin` | Symlink to `/system/bin`. Do not add to `$PATH`. |
| `/data` | The data partition of the internal sd card. |
| `/data/app` | App APKs and native libraries for 3rd party apps. |
| `/data/data` | Private app data directory for apps on primary user `0`. |
| `/dev` | Device files. |
| `/etc` | Symlink to `/system/etc`. |
| `/mnt` | Raw mount points of filesystems for internal and external sd cards. |
| `/proc` | Standard directory with runtime process and kernel information. |
| `/sbin` | Directory where special-purpose executables exist. Do not add to `$PATH`. |
| `/storage` | External storage mount points accessible to apps with storage permissions. |
| `/system` | The Android OS system root. |
| `/system/bin` | System executables. Avoid adding to `$PATH`. |
| `/system/lib` | System libraries. |
| `/system/xbin` | Optional set of system command line tools. Do not add to `$PATH`. |

---

## Termux Paths

| Path | Description |
|---|---|
| `/data/data/com.termux` | Termux Private App Data Directory |
| `/data/data/com.termux/termux` | Termux Project Directory (v0.119+) |
| `/data/data/com.termux/termux/core` | Termux Core Directory |
| `/data/data/com.termux/termux/apps` | Termux Apps Directory |
| `/data/data/com.termux/files` | Termux Rootfs Directory |
| `/data/data/com.termux/files/home` | Termux Home Directory (`$HOME`) |
| `/data/data/com.termux/files/usr` | Termux Prefix Directory (`$PREFIX`) |
| `/data/data/com.termux/cache` | Termux App Cache Directory |

### Termux Prefix Directory

The Termux prefix directory (`$PREFIX`) serves the same purpose as `/usr` on Linux distros.

| Path | Description |
|---|---|
| `$PREFIX/bin` | Executables. Combines `/bin`, `/sbin`, `/usr/bin`, `/usr/sbin`. |
| `$PREFIX/etc` | Configuration files. |
| `$PREFIX/include` | C/C++ headers. |
| `$PREFIX/lib` | Libraries. |
| `$PREFIX/libexec` | Executables which should not be run by user directly. |
| `$PREFIX/opt` | Installation root for sideloaded packages. |
| `$PREFIX/share` | Non-executable runtime data and documentation. |
| `$PREFIX/tmp` | Temporary files. Erased on each application restart. Combines `/tmp` and `/var/tmp`. Can be freely modified by user. |
| `$PREFIX/var` | Variable data, such as caches and databases. |
| `$PREFIX/var/run` | Lock files, PID files, sockets and other temporary files. Replaces `/run`. |

### Termux App Cache Directory

Cache files that are safe to be deleted by Android or Termux. Default path: `/data/data/com.termux/cache`.

---

## File Path Limits

| Constant | Value | Description |
|---|---|---|
| `TERMUX_APP__DATA_DIR___MAX_LEN` | 69 | Max length for app data directory |
| `TERMUX__ROOTFS_DIR___MAX_LEN` | 86 | Max length for rootfs directory |
| `TERMUX__PREFIX_DIR___MAX_LEN` | 90 | Max length for prefix directory |
| `TERMUX__PREFIX__TMP_DIR___MAX_LEN` | 94 | Max length for tmp directory |
| `TERMUX__UNIX_PATH_MAX` | 108 | Max length for Unix domain socket paths |

**Package name recommendation**: For packages, keep name `<= 21` characters (ideally `<= 10`).
