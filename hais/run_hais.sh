#!/bin/bash
# Hais V6 一键做包（Droidspaces 服务器）
# 用法: bash /opt/scripts/run_hais.sh <ROM包名>.zip
# 包在 /storage/emulated/0/Openlist/mix2s系统/
JAR=/opt/hais_tool/Bin/Lib/MiDoMain.jar
ROMDIR=/storage/emulated/0/Openlist/mix2s系统
Z="$1"
SHA=0d9b6549ef2cb40b7dc8286b91632e72ced3117e4ea5be63836fc1d2e3d120d1
URL=https://github.com/Aukimor/Aukimor_ROM_Polaris/releases/download/hais-tool-1.14/MiDoMain.jar

# 1. jar 完整性：坏了就从 Release 恢复
ACT=$(sha256sum "$JAR" | cut -d" " -f1)
if [ "$ACT" != "$SHA" ]; then
  echo "== jar bad, restoring from release"
  rm -f "$JAR"
  for i in 1 2 3 4 5 6 7 8 9 10; do
    curl -L --retry 5 -o "$JAR" "$URL" && break
    sleep 3
  done
fi

# 2. 跑工具（直接 java，绕开 Linux.sh 的自更新块）
echo "=== START $Z"
java -Xmx3g -Dfile.encoding=utf-8 -jar "$JAR" "$ROMDIR/$Z"
echo "=== DONE $Z"
