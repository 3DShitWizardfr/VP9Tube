<div align="center">

# 🎬 VP9Tube

**Bundled VP9 software decoder for YouTube on iOS — because YouTube took it away.**

[![iOS 14+](https://img.shields.io/badge/iOS-14%2B-blue?logo=apple&logoColor=white)](https://github.com/3DShitWizardfr/VP9Tube)
[![ARM64](https://img.shields.io/badge/arch-ARM64-lightgrey)](https://github.com/3DShitWizardfr/VP9Tube)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Status: WIP](https://img.shields.io/badge/status-Work%20in%20Progress-orange)](https://github.com/3DShitWizardfr/VP9Tube)

</div>

---

## 📖 What is this?

Starting from **YouTube v20.47.3**, the built-in software VP9 decoder (`libvpx`) was silently removed from the app binary. This broke **2K and 4K VP9 playback** on iOS devices that lack hardware VP9 decoding support (generally anything older than Apple A12 Bionic).

**VP9Tube** is a standalone iOS tweak that:

- Bundles its **own statically-compiled `libvpx`** (VP9 decode-only build for iOS ARM64)
- Hooks into YouTube's internal decoder pipeline to intercept VP9 decode requests
- Routes them to the bundled software decoder, fully restoring 2K/4K VP9 playback

> ⚠️ **This is a standalone tweak.** VP9Tube is **NOT** part of YTLite and has **no dependency** on it. It is designed to work **alongside** [YTUHD by PoomSmart](https://github.com/PoomSmart/YTUHD), which handles the format/ABR side of enabling high-resolution streams. VP9Tube handles the actual decoding.

---

## 🔧 How it works

1. **`libvpx` (VP9 decode-only)** is compiled as a static library for iOS ARM64 using the provided build script. Only the VP9 decoder is enabled — no encoders, no VP8 — keeping the binary size minimal.

2. **`VP9SoftwareDecoder`** is an Objective-C++ wrapper class that bridges libvpx's C API to the protocol interface YouTube's internal video pipeline expects. It manages codec lifecycle, thread count, and pixel buffer conversion (I420 → NV12 for CVPixelBuffer).

3. **Logos hooks on `MLVideoDecoderFactory` and `HAMDefaultVideoDecoderFactory`** intercept VP9 decode requests at YouTube's decoder factory layer. When a VP9-encoded stream is detected, the request is redirected to the bundled `VP9SoftwareDecoder` instead of the (now-missing) system decoder.

```
YouTube requests VP9 decoder
         │
         ▼
MLVideoDecoderFactory / HAMDefaultVideoDecoderFactory
         │  (hooked by VP9Tube)
         ▼
VP9SoftwareDecoder (libvpx C API bridge)
         │
         ▼
CVPixelBuffer (NV12) → YouTube's render pipeline
```

---

## 📋 Requirements

| Requirement | Notes |
|---|---|
| macOS with Xcode | Required to build libvpx and the tweak |
| [Theos](https://theos.dev) | iOS tweak build system |
| Jailbroken device or sideloading method | TrollStore recommended to preserve entitlements |
| [YTUHD](https://github.com/PoomSmart/YTUHD) | For format/ABR hooks that enable high-res VP9 stream selection |

---

## 📦 Building

### 1. Clone the repository

```bash
git clone https://github.com/3DShitWizardfr/VP9Tube.git
cd VP9Tube
```

### 2. Build libvpx for iOS ARM64

This step clones the libvpx source and compiles a decode-only static library for iOS ARM64. Requires Xcode command-line tools.

```bash
./scripts/build_libvpx_ios.sh
```

The compiled library and headers will be placed in `libvpx-ios/`.

### 3. Build the tweak

For jailbroken devices:
```bash
make package
```

For sideloaded IPAs:
```bash
make package SIDELOAD=1
```

The resulting `.deb` package will be in the `packages/` directory.

---

## 🚀 Usage

1. Install VP9Tube (`.deb`) on your jailbroken device (or integrate into a sideloaded IPA)
2. Install [YTUHD](https://github.com/PoomSmart/YTUHD) to enable VP9/high-resolution stream selection
3. Open YouTube → Settings → Video quality preferences → Enable VP9 / high-res options via YTUHD
4. Play a 2K or 4K video — it should now decode correctly via the bundled software decoder

> 💡 **Tip:** You can confirm the software decoder is active by checking the device console logs for `[VP9Tube]` messages.

---

## ⚡ Compatibility

| Scenario | Status |
|---|---|
| Devices **without** hardware VP9 (pre-A12 Bionic) | ✅ Primary target |
| Devices **with** hardware VP9 (A12+) | ✅ Works (hardware decoder still preferred by system) |
| YouTube **v20.47.3+** | ✅ Required (older versions have built-in VP9) |
| YouTube **< v20.47.3** | ⚠️ Not needed (built-in decoder still present) |
| **iOS 14+** | ✅ Supported |
| **Sideloaded** installs | ✅ Works (VP9Tube does not rely on AV1 entitlements) |

> ⚠️ **Performance note:** 4K VP9 software decoding is CPU-intensive. On older chips (A9/A10), expect higher CPU usage and potential frame drops at 4K. 2K (1440p) is generally smooth on A10 and newer.

---

## 🙏 Credits

- **[PoomSmart](https://github.com/PoomSmart)** — For [YTUHD](https://github.com/PoomSmart/YTUHD), years of reverse engineering YouTube's iOS internals, and laying the groundwork that makes projects like this possible
- **[WebM Project / Google](https://chromium.googlesource.com/webm/libvpx)** — For [libvpx](https://chromium.googlesource.com/webm/libvpx), the open-source VP8/VP9 codec library

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

libvpx is used under its own [BSD-style license](https://chromium.googlesource.com/webm/libvpx/+/refs/heads/main/LICENSE).

