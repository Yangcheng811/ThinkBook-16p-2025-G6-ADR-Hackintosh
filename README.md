# Lenovo ThinkBook 16p 2025 (G6 ADR) Hackintosh EFI — AMD Radeon 610M iGPU (`RembrandtGfx`, `v0.2.0-alpha`)

<p align="center">
  <b>English</b> | <a href="README.zh-CN.md">简体中文</a>
</p>

> **Branch Notice (`igpu-610m-rembrandtgfx` — Dual-GPU Coexistence `v0.2.0-alpha`)**
> - This branch provides the **experimental AMD Radeon 610M (`1002:164e`) iGPU + RTX 5060 Dual-GPU OpenCore 1.0.9 EFI** powered by our custom-ported **`RembrandtGfx.kext`** ([source repository](https://github.com/Yangcheng811/raphael-610m-gfx), ported from [caoshiyuan0211-blip/winmax2-2022-6800u-hackintosh](https://github.com/caoshiyuan0211-blip/winmax2-2022-6800u-hackintosh) to **Raphael / `gfx1036`**, spoofing `0x73ff` RX 6600 on **macOS 26.7.4 (`25G422`)**) alongside **NullMoth 3.1** for the NVIDIA RTX 5060 Laptop GPU.
> - Looking for the **stable daily-driver dGPU-only (RTX 5060) EFI**? Switch to the [`main`](https://github.com/Yangcheng811/ThinkBook-16p-2025-G6-ADR-Hackintosh/tree/main) branch ([`v1.1.1`](https://github.com/Yangcheng811/ThinkBook-16p-2025-G6-ADR-Hackintosh/releases/tag/v1.1.1)).
> - **SMBIOS Sanitized**: `PlatformInfo > Generic` contains placeholder values — **generate your own `MacPro7,1` SMBIOS before booting**.

---

## Screenshots (macOS 26.7.4 Tahoe — Hybrid / Dual-GPU Mode)

| About This Mac (`AMD Radeon RX 6600`) | System Information (610M `0x73ff` Metal + RTX 5060) |
| :---: | :---: |
| ![About This Mac - RX 6600](assets/igpu-about-this-mac.jpg) | ![System Information - Dual GPU](assets/igpu-system-info.jpg) |

---

## What's New in `v0.2.0-alpha`

### 1. Raphael 610M Stability Fixes (`RembrandtGfx` `3d8fa05`)
- **`collect_stb` Watchdog Deadlock Fixed**: Hooked `AMDRadeonX6000_AMDNavi23Hardware::collect_stb(AmdStbInfo*)` to return `false` on Raphael, eliminating the infinite STB register polling loop (`0xecc182`/`0xecc183`) that previously froze `WindowServer` for 40 s.
- **GC 10.3.6 Golden Registers & MMIO Safety**: Added GC 10.3.6 golden registers (`SQG_CONFIG`, `SX_DEBUG_1`; opt-out `-rmbnogoldenguard`) and guarded `0xFFFFFFFF` GC/MMIO reads.
- **Reduced Background Overhead**: Disabled 5 s periodic VRAM page-table scans by default (opt-in `-rmbptperiodic`), cleaned up SMU `DisallowGfxOff(0x17)` handling, and updated DCN/DMUB/SMCA diagnostics.
- **Recommended `boot-args` Stabilizers**: Added `-rmbnolinkwatch -rmbnopresdiag -rmbnodmubpoll -rmbsubmitscan` and `nvfbhotplugpoll=3`.

### 2. Dual-GPU Coexistence with NullMoth 3.1 RTX 5060
- **AMD 610M Marked `isLowPower = true`**: Patches `AMDRadeonX6000_AMDGraphicsAccelerator::populateAccelConfig` (`0x30804200 -> 0x30804600`, disable with `-rmbnoigpulowpower`) so macOS and Metal apps properly distinguish the low-power 610M iGPU from the high-power RTX 5060 dGPU.
- **RTX 5060 Marked `isRemovable = true`**: Patches `NVAccel::populateAccelConfig` (`0x30844300 -> 0x30846300`, disable with `-rmbnonvremovable`), enabling Finder's **"Prefer External GPU"** checkbox on any app's *Get Info* panel to offload Metal workloads (e.g., Chrome, Steam, games, video apps) to the 8 GB RTX 5060.
- **NullMoth 3.1 `nvcopy` BAR1 WC Acceleration**: Adapted the `NVDisplayPipe::performTransaction` 8-bit BGRA copy loop to a Write-Combining BAR1 `movnti` stub (`sysctl debug.rmb_nvcopy = 4`, disable with `-rmbnonvcopy`).
- **Automatic NullMoth Hotplug Arming**: Watches `NVRMNVDAFramebuffer` publication and automatically arms `debug.nvaccelfb`, `debug.nvrmfb_agdc_k5`, `debug.nvrmfb_agdc`, and `debug.nvaccel_iop` after boot (`-rmbnonvhotplug` disables).

---

## What Works

- **AMD Radeon 610M (`1002:164e`, Rev `0xd8`, Raphael `gfx1036`, 2 CU) Metal Acceleration**:
  - Boots into macOS 26.7.4 (`25G422`) desktop at native `2560 × 1600` (30-bit ARGB2101010) with Metal hardware acceleration (`102-RAPHAEL-008`, `2 GB` UMA VRAM recommended in BIOS).
- **DarkWake / Clamshell ~21 s Black Screen Fixed**:
  - `clamshell-sleep` block in `sleep.cpp` eliminates DarkWake / `setOutputPowerState(1)` black screens at boot.
- **NVIDIA RTX 5060 Laptop GPU (`10de:2d59`, `17aa:8036`) Co-Enabled**:
  - Both GPUs enumerate in Metal (`610M: lowPower=true`, `RTX 5060: lowPower=false, removable=true`); supports NVDEC video decode, per-app "Prefer External GPU", or global default Metal offloading to RTX 5060 via `defaults write -g GPUSelectionPolicy preferRemovable && defaults write com.apple.Metal deviceNameMatch "NVIDIA"`.
- **120 Hz Internal eDP & MT7925 Native Wi-Fi / iPhone Personal Hotspot**:
  - Copy `Scripts/DisplayVendorID-e77/DisplayProductID-1659` into `/Library/Displays/Contents/Resources/Overrides/DisplayVendorID-e77/` to unlock `2560 × 1600 @ 120 Hz` (DSC 12 bpp) on the 610M iGPU;
  - Synced `WTLWireless.kext` **v0.15.5** with the Tahoe `25G422` + `0x37/0x31/0x167` fix ([PR #15](https://github.com/watchthelight-labs/WTLWireless/pull/15)) for reliable iPhone Personal Hotspot and WPA2 connections.

---

## Known Issues & Recommendations

1. **610M UMA VRAM Exhaustion Under Heavy Desktop/Browser Load (`AMD ERROR! Failed to allocate`)**:
   - Even with 2 GB UMA VRAM allocated in BIOS, running `WindowServer` + Chrome (Skia/Dawn Metal) + Dynamic Wallpaper all on the 610M can exhaust VRAM and trigger a GFX hang / GPU Reset loop.
   - **Workaround**: In Finder, right-click **Google Chrome** (and other GPU-heavy apps) → **Get Info** → check **"Prefer External GPU"** so they render on the 8 GB RTX 5060 instead of the 2 GB 610M.
2. **Minimum Brightness Black Screen**: Setting internal panel brightness to minimum under iGPU still turns the backlight completely off.
3. **Sleep / Wake**: Still experimental; current `config.plist` passes `-rmbnousb4sleep -rmbnohalt -rmbnomode2 -rmbnosleep -rmbnodispsleep` to bypass S3/display sleep paths.

---

## Current Test EFI Configuration Summary

- **`boot-args`**:
  ```text
  -v debug=0x100 keepsyms=1 nvfb=1 nvaccel=1 nvfbheads=4 nvfbhotplugpoll=3 -nvkmsnosmooth amfi_get_out_of_my_way=0x1 amfi=0x80 ipc_control_port_options=0 gfxrst=4 -vi2c-force-polling mtkfe=native mtknativeif=1 revpatch=sbvmm nmxaudio=2 ps2kbdonly=1 ps2rst=0 -lilubetaall -rmbnousb4sleep -rmbnohalt -rmbnomode2 -rmbnosleep -rmbnodispsleep -rmbnolinkwatch -rmbnopresdiag -rmbnodmubpoll -rmbsubmitscan
  ```
- **`Booter > Quirks > ResizeAppleGpuBars`**: `10`
- **Recommended Deployment**: Test this branch on an **external USB drive (`OC_USB`)** first — keep your internal SSD's stable `main` (RTX 5060 dGPU-only) EFI untouched.
- **Source Code**: [`Yangcheng811/raphael-610m-gfx`](https://github.com/Yangcheng811/raphael-610m-gfx) (`RembrandtGfx` source).

---

## Credits

- Upstream iGPU bring-up architecture: [caoshiyuan0211-blip / winmax2-2022-6800u-hackintosh](https://github.com/caoshiyuan0211-blip/winmax2-2022-6800u-hackintosh) (`RembrandtGfx`)
- Full platform credits & component licenses: see `LICENSES/` and [`main` README](https://github.com/Yangcheng811/ThinkBook-16p-2025-G6-ADR-Hackintosh/blob/main/README.md).
