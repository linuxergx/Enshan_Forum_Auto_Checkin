#!/bin/bash

# ==========================================
# 恩山论坛自动签到脚本
# ==========================================

CONFIG_FILE="config.json"

# --- 1. 配置加载逻辑 (优先级：环境变量 > JSON文件) ---
# 在 GitHub Actions 和本地 OpenWrt 都能跑通
ENSHAN_COOKIE=${ENSHAN_COOKIE:-$(jq -r '.ENSHAN[0].cookie // empty' "$CONFIG_FILE" 2>/dev/null)}
BARK_URL=${BARK_URL:-$(jq -r '.BARK_URL // empty' "$CONFIG_FILE" 2>/dev/null)}
TELEGRAM_TOKEN=${TELEGRAM_TOKEN:-$(jq -r '.TELEGRAM_TOKEN // empty' "$CONFIG_FILE" 2>/dev/null)}
TELEGRAM_USERID=${TELEGRAM_USERID:-$(jq -r '.TELEGRAM_USERID // empty' "$CONFIG_FILE" 2>/dev/null)}

# --- 2. 环境检查 ---
check_env() {
    if ! command -v jq >/dev/null 2>&1 || ! command -v curl >/dev/null 2>&1; then
        echo "❌ 错误: 系统缺少 jq 或 curl，请先安装依赖。"
        exit 1
    fi

# 核心诊断打印 (脱敏处理，只看头尾)
if [ -n "$ENSHAN_COOKIE" ]; then
    COOKIE_LEN=${#ENSHAN_COOKIE}
    echo "DEBUG: Cookie 获取成功! 长度: $COOKIE_LEN"
    echo "DEBUG: Cookie 片段: ${ENSHAN_COOKIE:0:20}...${ENSHAN_COOKIE: -20}"
else
    echo "❌ 错误: 所有途径均未获取到 Cookie！"
fi

    if [ -z "$ENSHAN_COOKIE" ]; then
        echo "❌ 错误: 未获取到 ENSHAN_COOKIE，请检查环境变量或 config.json。"
        exit 1
    fi
    echo "✅ 环境及配置检查通过。"
}

# --- 3. 随机 UA 获取 ---
get_random_ua() {
    local ua=""
    if [ -f "$CONFIG_FILE" ]; then
        # OpenWrt 兼容写法：用 awk 随机取一行替代 shuf
        ua=$(jq -r '.USER_AGENTS[] // empty' "$CONFIG_FILE" 2>/dev/null | awk 'BEGIN{srand();}{a[NR]=$0}END{if(NR>0) print a[int(rand()*NR)+1]}')
    fi
    [ -z "$ua" ] && ua="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    echo "$ua"
}
# --- 4. 签到核心函数 ---
sign_enshan() {
    local current_ua=$(get_random_ua)
    echo "🚀 正在签到... 使用UA片段: ${current_ua:0:40}..."

    # 删掉了 --compressed，确保老版本 curl 也能跑
    local response=$(curl -s -L --request GET 'https://www.right.com.cn/forum/home.php?mod=spacecp&ac=credit&showcredit=1' \
        -H "User-Agent: $current_ua" \
        -H "Cookie: $ENSHAN_COOKIE" \
        -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' \
        -H 'Referer: https://www.right.com.cn/forum/forum.php?mod=guide&view=my')

    # 正则提取恩山币和积分
    local coin=$(echo "$response" | grep -oE '恩山币: </em>[^<]+' | grep -oE '[0-9]+' | head -n 1)
    local point=$(echo "$response" | grep -oE '积分: </em>[^<]+' | grep -oE '[0-9]+' | head -n 1)

    if [ -z "$coin" ] || [ -z "$point" ]; then
        # 简单诊断：是否被防火墙拦截
        if echo "$response" | grep -q "waf"; then
            echo "⚠️ 触发了 WAF 防火墙拦截，请检查 IP 质量或更新 Cookie。"
        else
            echo "⚠️ 无法解析页面数据，可能是 Cookie 过期。"
        fi
        return 1
    fi

    echo "恩山币: $coin, 积分: $point"
    return 0
}

# --- 5. 通知推送 ---
push_notification() {
    local msg="$1"
    
    # Bark 推送
    if [ -n "$BARK_URL" ]; then
        echo "📢 发送 Bark 通知..."
        local encoded_msg=$(echo "$msg" | jq -s -R -r @uri)
        curl -s "${BARK_URL}${encoded_msg}" > /dev/null
    fi

    # Telegram 推送
    if [ -n "$TELEGRAM_TOKEN" ] && [ -n "$TELEGRAM_USERID" ]; then
        echo "📢 发送 Telegram 通知..."
        curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
            -d chat_id="${TELEGRAM_USERID}" \
            -d parse_mode="HTML" \
            -d text="<b>恩山自动签到</b>%0A${msg}" > /dev/null
    fi
}

# --- 6. 主逻辑 ---
main() {
    check_env
    
    local success=false
    local final_result=""

    for i in 1 2; do
        echo "🔄 第 $i 次尝试..."
        res_data=$(sign_enshan)
        if [ $? -eq 0 ]; then
            final_result="✅ 签到成功！$res_data"
            success=true
            break
        else
            final_result="❌ 签到失败：$res_data"
            [ $i -eq 1 ] && sleep $(( RANDOM % 5 + 3 ))
        fi
    done

    echo "$final_result"
    push_notification "$final_result"
}

main

