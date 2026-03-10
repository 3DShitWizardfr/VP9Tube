# Contributing to VP9Tube

Thank you for your interest in contributing! VP9Tube is an experimental project, and contributions are very welcome.

---

## Setting up the Development Environment

### Prerequisites

- **macOS** (required for iOS toolchain)
- **Xcode** with Command Line Tools installed (`xcode-select --install`)
- **[Theos](https://theos.dev/docs/installation)** — follow the official installation guide
- A **jailbroken iOS device** or a sideloading method (TrollStore recommended)
- **[YTUHD](https://github.com/PoomSmart/YTUHD)** installed on your test device for format/ABR hooks

### Setup

```bash
# Clone the repo
git clone https://github.com/3DShitWizardfr/VP9Tube.git
cd VP9Tube

# Build the libvpx static library for iOS ARM64
./scripts/build_libvpx_ios.sh

# Build the tweak
make package
```

---

## Areas Where Contributions Are Most Impactful

### 🔧 10-bit VP9 Support (Profile 2)

The decoder currently handles 8-bit I420 (`VPX_IMG_FMT_I420`) only. 10-bit VP9 streams use `VPX_IMG_FMT_I42016` and require a different pixel buffer format (`kCVPixelFormatType_420YpCbCr10BiPlanarVideoRange` / P010). Implementing this would unlock HDR-capable streams.

### ⚡ Performance Optimizations

Software decoding is CPU-intensive on older chips. Ideas:
- NEON-accelerated YUV conversion (replacing the scalar I420→NV12 loop)
- Adaptive thread count based on resolution
- Frame dropping strategies for constrained devices

### 🧪 Testing on Different Devices and YouTube Versions

Real-world testing across a variety of devices (A9, A10, A11, A12+) and YouTube versions helps identify compatibility issues. If you find a breakage, please open an issue with:
- Device model and iOS version
- YouTube version
- Console log output (filter for `[VP9Tube]`)
- Description of the failure

### 🎬 AV1 / Sideload Entitlement Research

Investigating whether `com.apple.coremedia.allow-alternate-video-decoder-selection` can be preserved or worked around in sideloaded contexts.

---

## Pull Request Process

1. **Fork** the repository and create a feature branch:
   ```bash
   git checkout -b feature/my-improvement
   ```

2. **Make your changes.** Keep commits focused and descriptive.

3. **Test your changes** on a real device with YouTube v20.47.3 or newer.

4. **Open a Pull Request** with:
   - A clear description of what the PR does and why
   - Device(s) and YouTube version(s) tested on
   - Console log snippets showing the decoder in action (if applicable)

---

## Code Style

- Objective-C++ for implementation files (`.mm`)
- Logos syntax (`.x`) for hooks — keep hooks minimal and defensive
- Log all significant events with the `[VP9Tube]` prefix for easy filtering
- Follow the existing code structure and formatting

---

## Reporting Issues

Please open a GitHub Issue with as much detail as possible. Include console logs filtered for `[VP9Tube]` and your device/YouTube version.
