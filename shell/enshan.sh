#!/bin/bash

# 配置文件路径
CONFIG_FILE="config.json"

# 1. 尝试从环境变量读取（GitHub Actions 会注入这些变量）
# 2. 如果环境变量为空，则尝试从 config.json 读取
[ -z "$ENSHAN_COOKIE" ] && ENSHAN_COOKIE=$(jq -r '.ENSHAN[0].cookie' "$CONFIG_FILE" 2>/dev/null)
[ -z "$BARK_URL" ] && BARK_URL=$(jq -r '.BARK_URL' "$CONFIG_FILE" 2>/dev/null)
[ -z "$TELEGRAM_TOKEN" ] && TELEGRAM_TOKEN=$(jq -r '.TELEGRAM_TOKEN' "$CONFIG_FILE" 2>/dev/null)
[ -z "$TELEGRAM_USERID" ] && TELEGRAM_USERID=$(jq -r '.TELEGRAM_USERID' "$CONFIG_FILE" 2>/dev/null)

# 检查环境准备情况
if [ ! -f "$CONFIG_FILE" ]; then
    echo "提示：未找到 $CONFIG_FILE，将尝试使用环境变量..."
fi

# 检查依赖项
if ! command -v jq >/dev/null 2>&1 || ! command -v curl >/dev/null 2>&1; then
    echo "错误：缺少 jq 或 curl，请先安装依赖！"
    exit 1
fi

echo "环境检查通过，继续执行..."

# 校验核心变量是否拿到（不要再用 jq 重新读取了！）
if [ -z "$ENSHAN_COOKIE" ]; then
    echo "读取 EnShan Cookie 失败，请检查环境变量或 config.json！"
    exit 1
fi

# 签到函数
sign_enshan() {
    echo "开始执行恩山签到..."
    local response=$(curl -s 'https://www.right.com.cn/forum/home.php?mod=spacecp&ac=credit&showcredit=1' \
      --compressed \
      -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:136.0) Gecko/20100101 Firefox/136.0' \
      -H "Cookie: $ENSHAN_COOKIE" \
      -H 'Referer: https://www.right.com.cn/forum/forum.php?mod=viewthread&tid=220716&page=2')

    # 提取恩山币和积分
    local coin=$(echo "$response" | grep -oE '恩山币: </em>[^<]+' | grep -oE '[0-9]+' | head -n 1)
    local point=$(echo "$response" | grep -oE '积分: </em>[^<]+' | grep -oE '[0-9]+' | head -n 1)

    if [ -z "$coin" ] || [ -z "$point" ]; then
        echo "❌ 签到结果提取失败，请检查 Cookie 是否有效"
        return 1
    fi

    echo "✅ 签到成功！恩山币: $coin，积分: $point"
    return 0
}

# Bark 推送
push_bark() {
    [ -z "$BARK_URL" ] && return
    local message="$1"
    local encoded_message=$(echo "$message" | jq -s -R -r @uri)
    curl -s "$BARK_URL$encoded_message" > /dev/null
}

# TG 推送
push_tg() {
    [ -z "$TELEGRAM_TOKEN" ] || [ -z "$TELEGRAM_USERID" ] && return
    local message="$1"
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
         -d chat_id="${TELEGRAM_USERID}" \
         -d parse_mode=HTML \
         -d text="<b>恩山论坛提醒</b>%0A$message" > /dev/null
}

# 主逻辑
main() {
    sign_result=$(sign_enshan)
    status=$?
    
    echo "$sign_result"
    push_bark "$sign_result"
    push_tg "$sign_result"
}

main
