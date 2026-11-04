# 首次部署（Droidspaces / aarch64 Debian）

## 1. 工作区（绕开 FUSE noexec）
```bash
mknod /dev/loop-control c 10 237
truncate -s 24G /storage/emulated/0/haisdisk.img
DEV=$(losetup -f --show /storage/emulated/0/haisdisk.img 2>&1 | grep -o '/dev/loop[0-9]*')
# 提示 "device node lost" 时: mknod $DEV b 7 <minor>
losetup $DEV /storage/emulated/0/haisdisk.img
mkfs.ext4 -F -E lazy_itable_init=1,lazy_journal_init=1 $DEV
mkdir -p /opt/work && mount $DEV /opt/work
```

## 2. 工具与假服务器
```bash
mkdir -p /opt/hais_serve
tar xzf <haisfiles.tar.gz> -C /opt/hais_serve/          # Release 下载
cp config/aarch64/md5.json /opt/hais_serve/aarch64/     # 伪造清单
# 自签证书 + 导入 JVM
openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days 3650 -nodes \
  -subj "/CN=jihulab.com" -addext "subjectAltName=DNS:jihulab.com,DNS:www.jihulab.com"
keytool -importcert -noprompt -keystore /etc/ssl/certs/java/cacerts -storepass changeit \
  -alias haismitm -file cert.pem
echo "127.0.0.1 jihulab.com" >> /etc/hosts
nohup python3 /opt/hais_serve/haisserver2.py > /opt/hais_serve/server.out 2>&1 &
```

## 3. bionic 兼容（sdat2img/imgextractor 是 Termux ELF）
从 ROM 的 system.img（或解包后的树）抽：
```
/system/apex/com.android.runtime.release/bin/linker64      → /system/bin/linker64
/system/apex/com.android.runtime.release/lib64/bionic/*.so → /system/lib64/
PyInstaller 解出的 libz.so.1.3                              → /data/data/com.termux/files/usr/lib/
```
（imgextractor 的 ext4.py 一并放 /opt/hais，PYTHONPATH 引用）

## 4. 其它
```bash
apt-get install -y qemu-user openjdk-21-jre-headless python3-brotli e2fsprogs p7zip
# mke2fs.conf 去掉新特性（兼容工具自带 1.46.6）:
sed -i 's/orphan_file,//; s/metadata_csum_seed,//' /etc/mke2fs.conf
```
TWRP: `config/twrp/md5.json` + `polaris.img.7z` 放进 /opt/hais_serve/twrp/

## 5. 做包
```bash
bash /opt/scripts/run_hais.sh <包名>.zip
```
