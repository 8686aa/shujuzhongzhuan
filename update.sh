#!/usr/bin/env bash
# 一键拉取并更新 Socks5TzspBridge (Linux) —— 放到 shujuzhongzhuan 仓库根目录执行
# 用法: cd 到本仓库目录 && ./update.sh
set -e
cd "$(dirname "$0")"

echo "[1/3] git pull ..."
git pull --ff-only

if [ ! -f "Socks5TzspBridge-linux-x64.zip" ]; then
    echo "[error] 仓库中缺少 Socks5TzspBridge-linux-x64.zip" >&2
    exit 1
fi

echo "[2/3] 解压到 ./bridge ..."
unzip -o Socks5TzspBridge-linux-x64.zip -d bridge
chmod +x bridge/Socks5TzspBridge

echo "[3/3] 完成。运行桥: cd bridge && ./Socks5TzspBridge"
echo "      需要停止旧进程: pkill -f Socks5TzspBridge   (谨慎, 只杀你自己部署的)"
