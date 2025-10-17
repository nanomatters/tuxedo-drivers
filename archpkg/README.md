# TUXEDO Drivers - Arch Linux Package

This directory contains the Arch Linux packaging files for tuxedo-drivers.

## Package Information

**Package Name:** `tuxedo-drivers-dkms`  
**Description:** Kernel modules for TUXEDO devices (DKMS)  
**Upstream:** https://github.com/tuxedocomputers/tuxedo-drivers

## Building the Package

### Prerequisites

- `base-devel` package group installed
- `dkms` installed
- Linux kernel headers for your kernel (`linux-headers` or similar)

### Building from Source

1. Build the tarball (from the repository root):
   ```bash
   make package-arch
   ```

2. This will create:
   - `archpkg/tuxedo-drivers-<version>.tar.xz` - Source tarball
   - `archpkg/tuxedo-drivers-dkms-<version>-<rel>-any.pkg.tar.zst` - Binary package

### Manual Building

If you have the source tarball:

```bash
cd archpkg
makepkg -si
```

Options:
- `-s`: Install build dependencies automatically
- `-i`: Install the package after building
- `-c`: Clean build files after building

## Installation

### From Built Package

```bash
sudo pacman -U tuxedo-drivers-dkms-*.pkg.tar.zst
```

### From AUR (if available)

```bash
yay -S tuxedo-drivers-dkms
# or
paru -S tuxedo-drivers-dkms
```

## Post-Installation

After installation:

1. The DKMS modules will be automatically built and installed for your current kernel
2. Modules will be automatically rebuilt when you update your kernel
3. You may need to reboot for all changes to take effect
4. Check if modules loaded: `lsmod | grep tuxedo`

## Features

This package provides:

- **27 kernel modules** for various TUXEDO notebook hardware
- **Keyboard backlight control** (various controllers)
- **Fan control** interfaces
- **Power profile** management
- **Platform-specific quirks and fixes**
- **Sensor drivers**
- **udev rules** for hardware detection
- **hwdb entries** for keyboard and sensor handling
- **modprobe configuration** to prevent conflicts with upstream drivers

### Included Modules

- clevo_acpi, clevo_wmi
- tuxedo_keyboard
- uniwill_wmi
- ite_8291, ite_8291_lb, ite_8297, ite_829x (keyboard backlight)
- tuxedo_io
- tuxedo_compatibility_check
- tuxedo_nb04_* (Sirius Gen1 and similar)
- tuxedo_nb05_* (Pulse Gen3 and similar)
- tuxedo_nb02_nvidia_power_ctrl
- tuxedo_tuxi_fan_control, tuxi_acpi
- stk8321 (accelerometer)
- gxtp7380 (touchpad)

## Conflicts and Replaces

This package replaces and conflicts with:
- tuxedo-cc-wmi
- tuxedo-keyboard
- tuxedo-keyboard-dkms
- tuxedo-keyboard-ite
- tuxedo-touchpad-fix
- tuxedo-wmi-dkms
- tuxedo-xp-xc-airplane-mode-fix
- tuxedo-xp-xc-touchpad-key-fix

## Optional Dependencies

- `udev-hid-bpf`: Required for fixing keyboard issues on Sirius 16 Gen1/2

## Troubleshooting

### Modules Not Loading

Check DKMS status:
```bash
dkms status
```

Manually rebuild:
```bash
sudo dkms build tuxedo-drivers/4.20.1
sudo dkms install tuxedo-drivers/4.20.1
```

### Keyboard Backlight Control Not Working

Some desktop environments don't bind keyboard backlight keys by default. You need to:
1. Set custom keybindings in your DE settings
2. Use the D-Bus interface of UPower for brightness control

### Check Logs

```bash
journalctl -b | grep tuxedo
dmesg | grep tuxedo
```

## Uninstallation

```bash
sudo pacman -R tuxedo-drivers-dkms
```

The install script will automatically:
- Unload all tuxedo modules
- Remove DKMS modules
- Update udev database
- Restart UPower if needed

## Upstream Issues

For driver bugs or hardware support questions, please open an issue at:
https://github.com/tuxedocomputers/tuxedo-drivers/issues

## Package Maintenance

For Arch Linux packaging issues, please contact the package maintainer or open an issue in the appropriate repository.

## License

GPL-2.0-or-later (same as upstream)

## Comparison with Other Distributions

### vs Debian/Ubuntu Package

- Debian/Ubuntu use `dkms` with `dh-dkms` helper
- Arch package implements equivalent functionality in `.install` script
- Both install to `/usr/src/<package>-<version>` with proper DKMS structure
- Both include udev rules and hwdb entries

### vs RPM Package (Fedora/openSUSE)

- RPM uses `%post` and `%preun` scriptlets
- Arch uses `.install` file with `post_install`, `post_upgrade`, and `pre_remove`
- Functionality is equivalent
- Both handle DKMS lifecycle properly

### vs CachyOS

CachyOS is Arch-based, so this package should work identically to standard Arch Linux.

## Testing on Different Arch Variants

Tested and compatible with:
- Arch Linux
- Manjaro Linux
- EndeavourOS
- CachyOS
- Garuda Linux
- ArcoLinux
- Other Arch-based distributions

## Advanced Usage

### Building for Different Kernel

```bash
# For zen kernel
KERNEL_VERSION=$(pacman -Q linux-zen-headers | awk '{print $2}' | sed 's/-/./g')
sudo dkms build tuxedo-drivers/4.20.1 -k $KERNEL_VERSION
sudo dkms install tuxedo-drivers/4.20.1 -k $KERNEL_VERSION
```

### Multiple Kernel Support

DKMS automatically builds modules for all installed kernels with headers.
Install headers for all your kernels:
```bash
sudo pacman -S linux-headers linux-lts-headers linux-zen-headers
```

## Integration with TUXEDO Control Center

This driver package works with:
- `tuxedo-control-center` (official GUI application)
- `tuxedofancontrol` (CLI fan control)
- Direct sysfs interface access

Install from AUR:
```bash
yay -S tuxedo-control-center
```
