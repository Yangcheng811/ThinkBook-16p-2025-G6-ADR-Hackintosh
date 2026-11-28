# Lenovo ThinkBook 16p 2025 (G6 ADR) Hackintosh EFI — AMD Radeon 610M 核显驱动分支 (`RembrandtGfx`, `v0.2.0-alpha`)

<p align="center">
  <a href="README.md">English</a> | <b>简体中文</b>
</p>

> **分支说明（`igpu-610m-rembrandtgfx` — 双显卡共存版 `v0.2.0-alpha`）**
> - 本分支发布 **ThinkBook 16p 2025 G6 ADR (Ryzen 9 8945HX)** 的 **AMD Radeon 610M (`1002:164e`) 核显 + RTX 5060 双显卡 OpenCore 1.0.9 引导 EFI**，基于自研移植的 **`RembrandtGfx.kext`**（[源码仓库](https://github.com/Yangcheng811/raphael-610m-gfx)，源自 [caoshiyuan0211-blip/winmax2-2022-6800u-hackintosh](https://github.com/caoshiyuan0211-blip/winmax2-2022-6800u-hackintosh) 移植适配 **Raphael / `gfx1036`**，在 **macOS 26.7.4 (`25G422`)** 下仿冒 `0x73ff` RX 6600 启用 Metal 加速），并与 **NullMoth 3.1**（RTX 5060 Laptop GPU）深度协同共存。
> - 如需日常稳定使用的 **独显直连（RTX 5060）** 正式版 EFI，请切换到 [`main`](https://github.com/Yangcheng811/ThinkBook-16p-2025-G6-ADR-Hackintosh/tree/main) 分支（[`v1.1.1`](https://github.com/Yangcheng811/ThinkBook-16p-2025-G6-ADR-Hackintosh/releases/tag/v1.1.1)）。
> - **隐私脱敏**：`EFI/OC/config.plist` 中 `PlatformInfo > Generic` 已还原为占位符，**使用前请自行生成 `MacPro7,1` 三码**。

---

## 实机截图（macOS 26.7.4 Tahoe — 混合 / 双显卡模式）

| 关于本机（`AMD Radeon RX 6600`） | 系统信息（610M `0x73ff` Metal + RTX 5060） |
| :---: | :---: |
| ![关于本机 - RX 6600](assets/igpu-about-this-mac.jpg) | ![系统信息 - 双显卡识别](assets/igpu-system-info.jpg) |

---

## `v0.2.0-alpha` 更新内容

### 1. Raphael 610M 核显稳定性修复（`RembrandtGfx` `3d8fa05`）
- **修复 `collect_stb` 持锁死循环导致的 40 秒灰屏/看门狗重启**：在 `probe.cpp` 中 hook `AMDRadeonX6000_AMDNavi23Hardware::collect_stb(AmdStbInfo*)` 直接返回 `false`，彻底消除读取 `0xecc182`/`0xecc183` 导致的 `WindowServer` 锁死。
- **补齐 GC 10.3.6 黄金寄存器与 MMIO 防护**：补充 `SQG_CONFIG`、`SX_DEBUG_1` 黄金寄存器初始化（可用 `-rmbnogoldenguard` 关闭），并对 `0xFFFFFFFF` 异常读数加保护。
- **降低后台轮询开销**：默认关闭每 5 秒一次的 VRAM 页表全量扫描（按需 `-rmbptperiodic` 开启），清理 SMU `DisallowGfxOff(0x17)` 逻辑并完善 DCN/DMUB/SMCA 诊断日志。
- **同步实测稳定启动参数**：新增 `-rmbnolinkwatch -rmbnopresdiag -rmbnodmubpoll -rmbsubmitscan` 与 `nvfbhotplugpoll=3`。

### 2. 与 NullMoth 3.1（RTX 5060）双显卡深度共存
- **AMD 610M 标记为低功耗核显（`isLowPower = true`）**：修补 `AMDRadeonX6000_AMDGraphicsAccelerator::populateAccelConfig`（`0x30804200 -> 0x30804600`，可用 `-rmbnoigpulowpower` 关闭），让系统与 Metal 应用正确区分 610M 核显与 RTX 5060 独显。
- **RTX 5060 标记为可移除/外置 GPU（`isRemovable = true`）**：修补 `NVAccel::populateAccelConfig`（`0x30844300 -> 0x30846300`，可用 `-rmbnonvremovable` 关闭），现在可在访达中右键任意应用 → **显示简介** → 勾选 **“首选外部 GPU”**，将 Chrome、Steam、游戏或视频软件定向交给 8 GB 显存的 RTX 5060 渲染。
- **适配 NullMoth 3.1 `nvcopy` BAR1 WC 写合并加速**：替换 `NVDisplayPipe::performTransaction` 的 8-bit BGRA 拷贝循环为 `movnti` 写合并加速（`sysctl debug.rmb_nvcopy = 4`，可用 `-rmbnonvcopy` 关闭）。
- **NullMoth 热插拔自动布防**：监听 `NVRMNVDAFramebuffer` 发布并在启动完成后自动配置 `debug.nvaccelfb`、`debug.nvrmfb_agdc_k5`、`debug.nvrmfb_agdc`、`debug.nvaccel_iop`（可用 `-rmbnonvhotplug` 关闭）。

---

## 已验证可用功能

- **AMD Radeon 610M（`1002:164e`, Rev `0xd8`, Raphael `gfx1036`, 2 CU）Metal 硬件加速**：
  - macOS 26.7.4 (`25G422`) 正常进桌面（`2560 × 1600`, 30 位色深 ARGB2101010），Metal 加速正常（`102-RAPHAEL-008`，建议 BIOS 将 UMA 显存调至 `2 GB` 及以上）。
- **DarkWake / 合盖 ~21 秒黑屏已修复**：
  - `sleep.cpp` 内置 `clamshell-sleep` 阻断，消除开机 DarkWake 黑屏。
- **NVIDIA RTX 5060 Laptop GPU（`10de:2d59`, `17aa:8036`）协同工作**：
  - 双卡同时被 Metal 正确枚举（`610M: lowPower=true`，`RTX 5060: lowPower=false, removable=true`）；支持 NVDEC 视频硬解、按应用勾选“首选外部 GPU”，或执行 `defaults write -g GPUSelectionPolicy preferRemovable && defaults write com.apple.Metal deviceNameMatch "NVIDIA"` 全局将用户态 Metal 应用默认分流到 RTX 5060。
- **内屏 120 Hz 高刷 + MT7925 原生 Wi-Fi / iPhone 个人热点正常**：
  - 将 `Scripts/DisplayVendorID-e77/DisplayProductID-1659` 复制到 `/Library/Displays/Contents/Resources/Overrides/DisplayVendorID-e77/` 即可在 610M 核显下开启 `2560 × 1600 @ 120 Hz`（DSC 12 bpp）；
  - 已同步升级 `WTLWireless.kext` 至 **v0.15.5** 并合入 Tahoe `25G422` + `0x37/0x31/0x167` 修复（[PR #15](https://github.com/watchthelight-labs/WTLWireless/pull/15)），iPhone 个人热点与常规 WPA2 Wi-Fi 均可正常连接。

---

## 已知问题与使用建议

1. **610M 2 GB 显存高压易耗尽（`AMD ERROR! Failed to allocate`）**：
   - 若把 `WindowServer`、Chrome（Skia/Dawn Metal）与动态壁纸全部堆在 2 GB 核显上，长时间运行可能耗尽显存并诱发 GFX 卡死 / 连续 GPU Reset。
   - **推荐缓解方式**：在“应用程序”里右键 **Google Chrome** 等重度图形应用 → **显示简介** → 勾选 **“首选外部 GPU”**，将渲染和显存占用分流到 8 GB 的 RTX 5060 上。
2. **内屏亮度最低全黑**：核显下将亮度调至最低仍会背光全黑。
3. **休眠尚未恢复验证**：当前配置通过 `-rmbnousb4sleep -rmbnohalt -rmbnomode2 -rmbnosleep -rmbnodispsleep` 规避休眠路径，完整 S3/合盖休眠仍属实验状态。

---

## 当前 EFI 配置摘要

- **`boot-args`**：
  ```text
  -v debug=0x100 keepsyms=1 nvfb=1 nvaccel=1 nvfbheads=4 nvfbhotplugpoll=3 -nvkmsnosmooth amfi_get_out_of_my_way=0x1 amfi=0x80 ipc_control_port_options=0 gfxrst=4 -vi2c-force-polling mtkfe=native mtknativeif=1 revpatch=sbvmm nmxaudio=2 ps2kbdonly=1 ps2rst=0 -lilubetaall -rmbnousb4sleep -rmbnohalt -rmbnomode2 -rmbnosleep -rmbnodispsleep -rmbnolinkwatch -rmbnopresdiag -rmbnodmubpoll -rmbsubmitscan
  ```
- **`Booter > Quirks > ResizeAppleGpuBars`**：`10`
- **使用建议**：建议先部署到**外接测试 U 盘（`OC_USB`）**试用，保留内置硬盘上稳定的 `main` 分支（RTX 5060 独显直连）EFI 不动。
- **驱动源码**：[`Yangcheng811/raphael-610m-gfx`](https://github.com/Yangcheng811/raphael-610m-gfx)（`RembrandtGfx` 源码仓库）。

---

## 致谢（Credits）

- 上游核显驱动架构：[caoshiyuan0211-blip / winmax2-2022-6800u-hackintosh](https://github.com/caoshiyuan0211-blip/winmax2-2022-6800u-hackintosh)（`RembrandtGfx`）
- 其余平台组件与开源许可：见 `LICENSES/` 目录及 [`main` 分支文档](https://github.com/Yangcheng811/ThinkBook-16p-2025-G6-ADR-Hackintosh/blob/main/README.zh-CN.md)。
