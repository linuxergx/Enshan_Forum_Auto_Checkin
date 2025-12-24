#!/bin/bash

# ==========================================
# 恩山论坛自动签到脚本
# ==========================================

CONFIG_FILE="config.json"

# --- 1. 配置加载逻辑 ---
ENSHAN_COOKIE=${ENSHAN_COOKIE:-$(jq -r '.ENSHAN[0].cookie // empty' "$CONFIG_FILE" 2>/dev/null)}
BARK_URL=${BARK_URL:-$(jq -r '.BARK_URL // empty' "$CONFIG_FILE" 2>/dev/null)}
TELEGRAM_TOKEN=${TELEGRAM_TOKEN:-$(jq -r '.TELEGRAM_TOKEN // empty' "$CONFIG_FILE" 2>/dev/null)}
TELEGRAM_USERID=${TELEGRAM_USERID:-$(jq -r '.TELEGRAM_USERID // empty' "$CONFIG_FILE" 2>/dev/null)}

# --- 2. 环境及变量检查 ---
check_env() {
    if ! command -v jq >/dev/null 2>&1 || ! command -v curl >/dev/null 2>&1; then
        echo "❌ 错误: 系统缺少 jq 或 curl。"
        exit 1
    fi

    echo "--- 变量状态诊断 ---"
    if [ -n "$ENSHAN_COOKIE" ]; then
        echo "✅ ENSHAN_COOKIE 已加载 (长度: ${#ENSHAN_COOKIE})"
        echo "DEBUG: 片段 [ ${ENSHAN_COOKIE:0:15}...${ENSHAN_COOKIE: -15} ]"
    else
        echo "❌ 错误: 未获取到 ENSHAN_COOKIE！请检查 GitHub Secrets 或 config.json"
        exit 1
    fi
    echo "✅ 环境检查通过。"
}

# --- 3. 随机 UA 获取 ---
get_random_ua() {
    local ua=""
    if [ -f "$CONFIG_FILE" ]; then
        ua=$(jq -r '.USER_AGENTS[] // empty' "$CONFIG_FILE" 2>/dev/null | awk 'BEGIN{srand();}{a[NR]=$0}END{if(NR>0) print a[int(rand()*NR)+1]}')
    fi
    [ -z "$ua" ] && ua="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    echo "$ua"
}

# --- 4. 签到核心函数 ---
sign_enshan() {
    local current_ua=$(get_random_ua)
    
    # 自动探测 curl 是否支持 --compressed (Action支持, OpenWrt可能不支持)
    local compress_opt=""
    curl --help all | grep -q "\--compressed" && compress_opt="--compressed"

    # 增加 -w 参数来打印 HTTP 状态码，增加 -v 打印详细过程
    echo "DEBUG: 正在发起网络请求..."
    local response=$(curl -s -v -L $compress_opt --request GET 'https://www.right.com.cn/forum/home.php?mod=spacecp&ac=credit&showcredit=1' \
        -H "User-Agent: $current_ua" \
        -H "Cookie: $ENSHAN_COOKIE" \
        -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' \
        -H 'Referer: https://www.right.com.cn/forum/forum.php?mod=guide&view=my' \
        -w "\nHTTP_CODE: %{http_code}\n")

    # 打印状态码看看
    echo "DEBUG: 最终 HTTP 状态码: $(echo "$response" | grep 'HTTP_CODE' | awk '{print $2}')"

    # 提取关键信息
    local coin=$(echo "$response" | grep -oE '恩山币: </em>[^<]+' | grep -oE '[0-9]+' | head -n 1)
    local point=$(echo "$response" | grep -oE '积分: </em>[^<]+' | grep -oE '[0-9]+' | head -n 1)

    if [ -z "$coin" ] || [ -z "$point" ]; then
        # 深度诊断逻辑
        local title=$(echo "$response" | grep -oP '(?<=<title>).*?(?=</title>)' | head -n 1)
        echo "⚠️ 解析失败。页面标题: [ $title ]"
        
        if echo "$response" | grep -qiE "waf|captcha|verify|forbidden"; then
            echo "❌ 触发了 WAF 防火墙拦截 (Action IP 可能被封)"
        elif echo "$title" | grep -q "提示信息"; then
            echo "❌ 登录失效 (Cookie 可能已过期)"
        else
            echo "❌ 未知响应 (可能是网络问题或页面结构变化)"
        fi
        return 1
    fi

    echo "💰 签到成功 -> 恩山币: $coin, 积分: $point"
    return 0
}

# --- 5. 通知推送 ---
push_notification() {
    local msg="$1"
    [ -z "$msg" ] && return

    # Bark
    if [ -n "$BARK_URL" ]; then
        local encoded_msg=$(echo "$msg" | jq -s -R -r @uri)
        curl -s "${BARK_URL}${encoded_msg}" > /dev/null
    fi

    # Telegram
    if [ -n "$TELEGRAM_TOKEN" ] && [ -n "$TELEGRAM_USERID" ]; then
        curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
            -d chat_id="${TELEGRAM_USERID}" \
            -d parse_mode="HTML" \
            -d text="<b>恩山自动签到</b>%0A${msg}" > /dev/null
    fi
}

# --- 6. 主逻辑 ---
main() {
    check_env
    
    local final_result=""
    for i in 1 2; do
        echo "🔄 第 $i 次尝试..."
        if res_data=$(sign_enshan); then
            final_result="✅ $res_data"
            break
        else
            final_result="❌ $res_data"
            [ $i -eq 1 ] && sleep $(( RANDOM % 10 + 5 ))
        fi
    done

    echo "$final_result"
    push_notification "$final_result"
}

main
