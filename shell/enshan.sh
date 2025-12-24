#!/bin/sh

# 配置文件路径
CONFIG_FILE="config.json"
ENSHAN_COOKIE=${ENSHAN_COOKIE:-$(jq -r '.ENSHAN[0].cookie' "$CONFIG_FILE" 2>/dev/null)}
BARK_URL=${BARK_URL:-$(jq -r '.BARK_URL' "$CONFIG_FILE" 2>/dev/null)}
TELEGRAM_TOKEN=${TELEGRAM_TOKEN:-$(jq -r '.TELEGRAM_TOKEN' "$CONFIG_FILE" 2>/dev/null)}
TELEGRAM_USERID=${TELEGRAM_USERID:-$(jq -r '.TELEGRAM_USERID' "$CONFIG_FILE" 2>/dev/null)}
# 检查配置文件是否存在
if [ ! -f "$CONFIG_FILE" ]; then
    echo "检查配置文件是否存在..."
    echo "配置文件 $CONFIG_FILE 不存在！尝试从环境变量读取.."
fi


echo "配置文件存在，继续执行..."

# 检查 jq 是否安装
if ! command -v jq >/dev/null 2>&1; then
    echo "检查 jq 是否安装..."
    echo "jq 未安装，请先安装 jq！"
    exit 1
fi

echo "jq 已安装，继续执行..."

# 检查 curl 是否安装
if ! command -v curl >/dev/null 2>&1; then
    echo "检查 curl 是否安装..."
    echo "curl 未安装，请先安装 curl！"
    exit 1
fi

echo "curl 已安装，继续执行..."

# 从配置文件中读取 EnShan Cookie 和 Bark URL
ENSHAN_COOKIE=$(jq -r '.ENSHAN[0].cookie' "$CONFIG_FILE")
BARK_URL=$(jq -r '.BARK_URL' "$CONFIG_FILE")

# 检查 EnShan Cookie 是否存在
if [ -z "$ENSHAN_COOKIE" ]; then
    echo "读取 EnShan Cookie..."
    echo "未找到 EnShan Cookie，请检查 config.json 文件！"
    exit 1
fi

echo "EnShan Cookie 读取成功，继续执行..."

# 检查 Bark URL 是否存在
if [ -z "$BARK_URL" ]; then
    echo "读取 Bark URL..."
    echo "未找到 Bark URL，请检查 config.json 文件！"
    exit 1
fi

echo "Bark URL 读取成功，继续执行..."

# 签到函数
sign_enshan() {
    echo "开始签到..."
    local response=$(curl 'https://www.right.com.cn/forum/home.php?mod=spacecp&ac=credit&showcredit=1' \
      --compressed \
      -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:136.0) Gecko/20100101 Firefox/136.0' \
      -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' \
      -H 'Accept-Language: zh-CN,zh;q=0.8,zh-TW;q=0.7,zh-HK;q=0.5,en-US;q=0.3,en;q=0.2' \
      -H 'Accept-Encoding: gzip, deflate, br, zstd' \
      -H 'Referer: https://www.right.com.cn/forum/forum.php?mod=viewthread&tid=220716&page=2' \
      -H 'DNT: 1' \
      -H 'Connection: keep-alive' \
      -H "Cookie: $ENSHAN_COOKIE" \
      -H 'Upgrade-Insecure-Requests: 1' \
      -H 'Sec-Fetch-Dest: document' \
      -H 'Sec-Fetch-Mode: navigate' \
      -H 'Sec-Fetch-Site: same-origin' \
      -H 'Sec-Fetch-User: ?1' \
      -H 'Priority: u=0, i')

    # 使用 grep 提取恩山币和积分
    local coin=$(echo "$response" | grep -oE '恩山币: </em>[^<]+' | grep -oE '[0-9]+')
    local point=$(echo "$response" | grep -oE '积分: </em>[^<]+' | grep -oE '[0-9]+')

    if [ -z "$coin" ] || [ -z "$point" ]; then
        echo "提取恩山币或积分失败，可能是正则表达式不匹配！"
        return 1
    fi

    echo "签到成功，恩山币: $coin，积分: $point"
    return 0
}

# Bark 推送函数
push_bark() {
    local message="$1"
    echo "推送通知到 Bark..."
    local encoded_message=$(echo "$message" | jq -s -R -r @uri)  # 使用 jq 对消息内容进行 URL 编码
    curl -s "$BARK_URL$encoded_message" &> /dev/null
    if [ $? -eq 0 ]; then
        echo "通知已发送到 Bark！"
    else
        echo "通知发送失败，请检查 Bark URL 和网络连接！"
    fi
}
# TG 推送函数
push_tg() {
    local message="$1"
    echo "推送通知到 Telegram..."
    # 这里的变量名要和 .yml 里的 env 对应
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
         -d chat_id="${TELEGRAM_USERID}" \
         -d parse_mode=HTML \
         -d text="$message"
}
# 主逻辑
main() {
    sign_result=$(sign_enshan)
    sign_status=$?

    if [ $sign_status -eq 0 ]; then
        echo "$sign_result"
        push_bark "$sign_result"
        push_tg "$sign_result"
    else
        echo "$sign_result"
        push_bark "$sign_result"
        push_tg "$sign_result"
    fi
}

# 执行主逻辑
main
