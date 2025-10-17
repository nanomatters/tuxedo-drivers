#!/bin/bash
# Quick build script for tuxedo-drivers Arch package
# Run this from the repository root

set -e

PACKAGE_NAME="tuxedo-drivers"
PACKAGE_VERSION=$(grep -Pom1 '.* \(\K.*(?=\) .*; urgency=.*)' debian/changelog)

echo "Building ${PACKAGE_NAME} version ${PACKAGE_VERSION} for Arch Linux"
echo "=================================================================="

# Step 1: Create source tarball
echo "[1/4] Creating source tarball..."
cd "$(dirname "$0")/.."
mkdir -p archpkg

tar --create --file "archpkg/${PACKAGE_NAME}-${PACKAGE_VERSION}.tar.xz" \
    --transform="s/debian\/copyright/${PACKAGE_NAME}-${PACKAGE_VERSION}\/LICENSE/" \
    --transform="s/usr/${PACKAGE_NAME}-${PACKAGE_VERSION}\/usr/" \
    --transform="s/src/${PACKAGE_NAME}-${PACKAGE_VERSION}\/src/" \
    --exclude=*.cmd \
    --exclude=*.ko \
    --exclude=*.mod \
    --exclude=*.mod.c \
    --exclude=*.o \
    --exclude=*.o.d \
    --exclude=modules.order \
    debian/copyright src usr

echo "✓ Tarball created: archpkg/${PACKAGE_NAME}-${PACKAGE_VERSION}.tar.xz"

# Step 2: Update .SRCINFO if makepkg is available
if command -v makepkg >/dev/null 2>&1; then
    echo "[2/4] Updating .SRCINFO..."
    cd archpkg
    makepkg --printsrcinfo > .SRCINFO
    cd ..
    echo "✓ .SRCINFO updated"
else
    echo "[2/4] Skipping .SRCINFO update (makepkg not available)"
fi

# Step 3: Verify PKGBUILD syntax
echo "[3/4] Verifying PKGBUILD..."
cd archpkg
bash -n PKGBUILD && echo "✓ PKGBUILD syntax is valid" || {
    echo "✗ PKGBUILD has syntax errors!"
    exit 1
}
cd ..

# Step 4: Build package if requested
if [ "$1" = "--build" ] || [ "$1" = "-b" ]; then
    if command -v makepkg >/dev/null 2>&1; then
        echo "[4/4] Building package..."
        cd archpkg
        makepkg -f
        echo ""
        echo "=================================================================="
        echo "✓ Package built successfully!"
        echo ""
        echo "To install:"
        echo "  sudo pacman -U archpkg/${PACKAGE_NAME}-dkms-*.pkg.tar.zst"
        echo ""
        echo "To test installation:"
        echo "  1. Install package"
        echo "  2. Check DKMS status: dkms status"
        echo "  3. Check modules: lsmod | grep tuxedo"
        echo "  4. Check logs: journalctl -b | grep tuxedo"
    else
        echo "[4/4] Skipping build (makepkg not available)"
        echo ""
        echo "Preparation complete! Files ready in archpkg/"
        echo ""
        echo "To build on an Arch system:"
        echo "  cd archpkg && makepkg -si"
    fi
else
    echo "[4/4] Skipping build (use --build to build package)"
    echo ""
    echo "=================================================================="
    echo "✓ Package preparation complete!"
    echo ""
    echo "Files created in archpkg/:"
    echo "  - ${PACKAGE_NAME}-${PACKAGE_VERSION}.tar.xz"
    echo "  - PKGBUILD"
    echo "  - tuxedo-drivers-generic.install"
    echo "  - .SRCINFO"
    echo "  - README.md"
    echo "  - IMPROVEMENTS.md"
    echo ""
    echo "To build package:"
    echo "  $0 --build"
    echo ""
    echo "Or manually:"
    echo "  cd archpkg && makepkg -si"
fi
