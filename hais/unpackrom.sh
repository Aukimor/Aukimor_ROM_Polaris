#!/bin/bash
set -x
ROMDIR="/storage/emulated/0/Openlist/mix2s系统"
ROM="$1"
NAME=$(basename "$ROM" .zip)
W=/opt/work/diff
ST="$W/$NAME/stage"
mkdir -p "$ST"
cd "$ST"

python3 - "$ROMDIR/$ROM" "$ST" <<'EOF'
import zipfile, sys, os
src, dst = sys.argv[1], sys.argv[2]
z = zipfile.ZipFile(src)
for n in z.namelist():
    b = os.path.basename(n)
    if b.endswith('.new.dat') or b.endswith('.new.dat.br') or b.endswith('.transfer.list'):
        if not os.path.exists(os.path.join(dst, b)):
            z.extract(member=n, path=dst)
            p = os.path.join(dst, n)
            if os.path.isfile(p) and os.path.dirname(p) != dst:
                os.replace(p, os.path.join(dst, b))
        print('have', b)
EOF

# brotli 解压
for br in $(find . -maxdepth 1 -name "*.new.dat.br" | sed 's|^\./||'); do
  OUT="${br%.br}"
  [ -f "$OUT" ] || { echo "== decompress $br"; python3 /opt/scripts/brdec.py "$br" "$OUT"; }
done

# 转 img + 解包
for dat in $(find . -maxdepth 1 -name "*.new.dat" | sed 's|^\./||; s|\.new\.dat$||'); do
  P="$W/$NAME/$dat"
  if [ -f "$dat.transfer.list" ] && [ ! -d "$P" ]; then
    echo "== convert $dat"
    python3 /opt/hais/sdat2img.py "$dat.transfer.list" "$dat.new.dat" "$P.img" > "$W/$NAME/$dat.sdat.log" 2>&1
    echo "sdat rc=$?"
    PYTHONPATH=/opt/hais python3 /opt/hais/imgextractor.py "$P.img" "$W/$NAME" > "$W/$NAME/$dat.ext.log" 2>&1
    echo "ext rc=$?"
    rm -f "$P.img"
  fi
done

echo "=== $NAME 结构:"
ls "$W/$NAME/"
du -sh "$W/$NAME"/* 2>/dev/null
echo "UNPACK_DONE $NAME"
