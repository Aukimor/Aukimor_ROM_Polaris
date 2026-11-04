# 三方官改 jar 层分析（2026-11-04）

## 差异范围
framework 目录 ~100 个 jar，三方字节不同的只有 4 个：
```
framework.jar          B 9.7M / U 25.1M / M 15.1M   （厨房重编译，类数完全相同）
services.jar           B 5.2M / U 6.5M / M 11.3M
miuisystemsdk@boot.jar B 479K / U 480K / M 1046K
cloud-common-runtime / miuisdk@boot / wifi-service  （仅重建痕迹）
```
其余所有 jar（telephony-common、ext、 ims-common…）字节完全一致 → **官改只动 framework + services**。

## 反编译验证（baksmali 全量 + 归一化 diff）
工作目录：服务器 /opt/work/baksmali/{B,U,M}

- **framework.jar**：三方类数完全相同（5399/7446/5600/87x）→ 只是重编译产物差异，无人加新类
- **services.jar**：总类数相同（7384 / M=7373），其中 574 个类在 B 里位于 classes2.dex、U/M 挪到 classes.dex（厨房流程指纹）

### 真实改动（归一化后 md5 仍不同的类）
| 相对 BlueHill | 数量 | 可读性 |
|---|---|---|
| 乌堆 U | 4711 类 | 全量重编译，diff 被噪音淹没（但实证 PMS/UserManagerService/DeviceIdleController 有改） |
| 猫咪 M | **仅 63 类** | 干净可读 |

### 猫咪的 63 个改动类（按功能分组）
- **pm/**：PackageManagerService、PackageManagerServiceInjector、PackageManagerServiceUtils、CarrierAppServiceManager、MiuiRamdiskService
- **am/**：ActivityManagerShellCommand、ProcessManagerService、ProcessPolicy、KidSpaceSwitchingDialog、MiuiUserSwitchingDialog
- **input/**：InputManagerService 及 7 个内部类
- **audio/**：AudioService、FocusRequester
- **net/**：MiuiNetworkPolicyManagerService、MiuiNetworkPolicyTrafficLimit（限速）
- **display/**：DisplayPowerController、MiuiBrightnessChangeTracker（亮度统计）
- **policy/**：MiuiGlobalActions（电源菜单）、PhoneWindowManager
- **wm/**：Task、AppWindowToken、WindowManagerService 等 6 个
- **com/miui/server/**：SecurityManagerService、EdgeSuppressionManager、MiuiInitServer

### 核心补丁实证：降级安装
PackageManagerService 里 MIUI 的降级检查（读 `persist.yr_oncore` prop、
`" is older than current"` 比较 versionCode）：
```
              yr_oncore 命中   "is older than current"
BlueHill            1              2        ← 保留降级限制
乌堆                0              0        ← 删除（允许降级安装）
猫咪                0              0        ← 删除
```
→ **删降级限制是乌堆/猫咪的共同标准动作**，BlueHill 没做。

### 签名校验
`checkSignature/compareSignature` 方法引用数三方完全一致（11 处）→
**services 侧签名校验链没人改**。结合 framework.jar 类数也没变，
官改的"去卡米"补丁大概率以**替换方法体**形式存在（引用数不变），
具体位置还没定位（可能需要 framework.jar 逐方法 diff）。

## 结论
1. 官改 jar 层改动极小：**不加类**，只改现有方法 + 删检查（降级/卡米类）
2. 厨房重编译是主要噪音源（乌堆重编译 4711/7384 类）
3. 想做自己的官改：照着猫咪的 63 类清单改即可，Hais SmallPatchFile 足以表达
