
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
chmod +x ./steamcommunity_302.caddy
chmod +x ./steamcommunity_302.cli

./steamcommunity_302.cli \
    -allowed-uid 1000 \
    -runtime-dir /run/s302/1000 \
    -start-service &

# 启动 ASF
exec /asf/ArchiSteamFarm-Service.sh --no-restart --system-required
