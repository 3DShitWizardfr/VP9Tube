#!/bin/bash
set -e

LIBVPX_VERSION="v1.14.1"
MIN_IOS_VERSION="14.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
OUTPUT_DIR="$PROJECT_DIR/libvpx-ios"

echo "=== VP9Tube: Building libvpx for iOS ARM64 ==="
echo ""

# Clone libvpx if not present
if [ ! -d "$PROJECT_DIR/libvpx" ]; then
    echo "[1/4] Cloning libvpx $LIBVPX_VERSION..."
    git clone https://chromium.googlesource.com/webm/libvpx -b "$LIBVPX_VERSION" --depth 1 "$PROJECT_DIR/libvpx"
else
    echo "[1/4] libvpx source already present, skipping clone"
fi

cd "$PROJECT_DIR/libvpx"

# Setup iOS toolchain
echo "[2/4] Configuring iOS ARM64 toolchain..."
export IOS_SDK=$(xcrun --sdk iphoneos --show-sdk-path)
export CC="$(xcrun --sdk iphoneos -f clang)"
export CXX="$(xcrun --sdk iphoneos -f clang++)"
export AR="$(xcrun --sdk iphoneos -f ar)"
export AS="$(xcrun --sdk iphoneos -f as)"
export STRIP="$(xcrun --sdk iphoneos -f strip)"
export RANLIB="$(xcrun --sdk iphoneos -f ranlib)"
export CFLAGS="-arch arm64 -isysroot $IOS_SDK -mios-version-min=$MIN_IOS_VERSION -fembed-bitcode -O3"
export CXXFLAGS="$CFLAGS"
export LDFLAGS="-arch arm64 -isysroot $IOS_SDK -mios-version-min=$MIN_IOS_VERSION"

# Clean previous build
BUILD_DIR="build-ios-arm64"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Configure
echo "[3/4] Configuring libvpx (VP9 decode-only, static, ARM64)..."
../configure \
    --target=arm64-darwin-gcc \
    --sdk-path="$IOS_SDK" \
    --enable-static \
    --disable-shared \
    --disable-examples \
    --disable-tools \
    --disable-docs \
    --disable-unit-tests \
    --enable-vp9-decoder \
    --disable-vp9-encoder \
    --disable-vp8-decoder \
    --disable-vp8-encoder \
    --disable-encoders \
    --enable-pic \
    --enable-multithread \
    --enable-runtime-cpu-detect \
    --enable-neon \
    --prefix="$OUTPUT_DIR"

# Build
echo "[4/4] Building..."
make -j$(sysctl -n hw.ncpu)
make install

echo ""
echo "================================================"
echo " VP9Tube: libvpx build complete!"
echo " Static library: $OUTPUT_DIR/lib/libvpx.a"
echo " Headers:        $OUTPUT_DIR/include/"
echo "================================================"
