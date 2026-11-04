# Aukimor_ROM_Polaris — Mix2S 官改做包链路

在 Droidspaces 服务器（aarch64 Debian）上用 **Hais V6** 自动做 MIUI 官改包的完整链路。

## 原理
Hais V6 是 Java 工具（`MiDoMain.jar`），但它的依赖二进制在 aarch64 Linux 上跑不起来，
且每次启动会自更新覆盖自己。本仓解决三件事：

1. **假 jihulab 服务器**（`hais/haisserver2.py` + hosts + 自签证书）—— 工具的
   md5.json 校验机制反过来用：我们控制 md5.json，想替换哪个二进制就替换哪个
2. **bionic 兼容层** —— sdat2img/imgextractor 是 Termux ELF，需要从 ROM 的 apex
   抽 linker64 + libc 装进容器（一次配好）
3. **qemu-arm 兜底** —— zipalign 是 32 位 ARM 静态 ELF，aarch64 段错误，
   服务端用 `exec qemu-arm` 壳替代

## 用法（服务器）
```bash
bash /opt/scripts/run_hais.sh <ROM包>.zip    # 包在 /storage/emulated/0/Openlist/mix2s系统
# → /opt/work/hais/Complete/Hais_<device><版本>(日期)_<md5>.zip
```

## 首次部署
见 `hais/SETUP.md`

## 目录
- `hais/` —— 服务器脚本与配置（假服务器、一键做包、brotli 解压、通用解包）
- `config/` —— 伪造的 md5.json（aarch64 / common / twrp）
- `docs/` —— 三方官改包对比分析、jar 分析
- Release `hais-tool-1.14` —— MiDoMain.jar / haisfiles.tar.gz / polaris.img.7z
