
#!/bin/bash

# 初始化 ASF 配置
if [ ! -f "/app/config/IPC.config" ]; then
    echo '{"Kestrel":{"Endpoints":{"HTTP":{"Url":"http://*:1242"}}}}' >> /app/config/IPC.config
fi

if [ ! -f "/app/config/ASF.json" ]; then
    echo '{"IPCPassword":"asf123456","UpdateChannel": 0,"UpdatePeriod": 0,"Headless": true}' >> /app/config/ASF.json
fi

# 首次启动时初始化 S302 配置
mkdir -p /var/lib/Steamcommunity_302

if [ ! -f "/var/lib/Steamcommunity_302/config.json" ]; then
    cp /app/config.json /var/lib/Steamcommunity_302/config.json
fi

# 保留原有 hosts 配置
echo '127.0.0.1 steamcommunity.com www.steamcommunity.com store.steampowered.com api.steampowered.com github.com' >> /etc/hosts

# 准备 S302 运行目录
mkdir -p /run/s302/1000
chown 1000:1000 /run/s302/1000
chmod 755 /run/s302/1000

# 启动 S302
./steamcommunity_302.cli \
    -allowed-uid 1000 \
    -runtime-dir /run/s302/1000 \
    -start-service &

# 等待 S302 生成根证书
ROOT_CERT="/var/lib/Steamcommunity_302/caddy-storage/pki/authorities/local/root.crt"

for i in {1..30}; do
    if [ -s "$ROOT_CERT" ]; then
        break
    fi
    sleep 1
done

# 检查根证书是否生成成功
if [ ! -s "$ROOT_CERT" ]; then
    echo "ERROR: S302 根证书生成失败，无法启动 ASF"
    exit 1
fi

# 安装 S302 根证书到系统信任库
install -m 0644 "$ROOT_CERT" \
    /usr/local/share/ca-certificates/steamcommunity-302.crt

update-ca-certificates

# 启动 ASF
exec /asf/ArchiSteamFarm-Service.sh --no-restart --system-required
