# EnShan 论坛自动签到 Shell 脚本 (路由器/本地版)

## 📌 介绍

这是一个专为 **路由器**（如 OpenWrt, Padavan, 等）及 **NAS/虚拟机** 环境设计的恩山无线论坛自动签到脚本。

⚠️ **重要警告**： 经过实测，恩山论坛使用了高强度的 WAF 防火墙（经常会触发 521 拦截），**GitHub Actions 等云端环境 IP 已被彻底封锁**。目前该脚本 **仅推荐在家庭宽带环境（本地设备）运行**，以利用家宽 IP 的高信誉度绕过拦截。

## 🕊功能

- 自动签到恩山无线论坛。
- 提取并显示“恩山币”和“积分”。
- 可通过 Bark或TG 推送通知签到结果。

## ✨ 特点

- **环境自适应**：支持 BusyBox/精简版 Linux 环境，完美兼容 `curl` 和 `jq`。
- **随机化抗风控**：在`config.json`中内置 User-Agent 随机切换逻辑，模拟真实设备访问。
- **多平台通知**：支持 Bark 和 Telegram Bot 签到结果推送。

## 🛠️ 环境要求

- **核心依赖**：`curl` 和 `jq`（必须）。
- **网络条件**：家庭宽带环境（家宽 IP 权重高，签到成功率接近 100%）。
- **存储空间**：极小，专为资源受限设备优化。

## 📥 安装与配置

### 1. 安装依赖

在 OpenWrt 或其他支持 `opkg` 的系统下执行：

```
opkg update
opkg install curl jq
```



### 2. 准备配置文件 `config.json`

在脚本同级目录下创建 `config.json`：

```
{
  "BARK_URL": "",
  "TELEGRAM_TOKEN":  "",
  "TELEGRAM_USERID": "",
  "ENSHAN": [
    {
    "cookie": ""
    }
  ],
  "USER_AGENTS": [
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0",
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) Safari/605.1.15"
      ]
}
```

### 3. 如何抓取 Cookie

1. 使用电脑浏览器（推荐 Chrome）登录恩山论坛。
2. 按 `F12` 进入开发者工具 -> **Network (网络)**。
3. 刷新页面，点击任意请求，在 **Request Headers** 中复制 `cookie:` 后的全部字符串。

## 🚀 使用方法

1. **赋予执行权限**：

   ```
   chmod +x enshan.sh
   ```

2. **手动运行测试**：

   ```
   ./enshan.sh
   ```

3. **设置定时任务 (Crontab)**： 建议避开整点运行（例如设置为 08:35）：

   ```
   35 8 * * * /path/to/enshan.sh >> /tmp/enshan.log 2>&1
   ```

## ⚠️ 注意事项

- **WAF 拦截 (HTTP 521)**：如果脚本提示 521 错误，说明该环境 IP 被封锁，请尝试更换运行设备或重启路由器获取新 IP。
- **Cookie 时效**：若提示解析失败且标题为“提示信息”，请重新抓取 Cookie 并更新 `config.json`。
- **安全提醒**：请勿将包含敏感 Cookie 的 `config.json` 上传至任何公开仓库。

## 🤝 贡献

如有改进建议或代码优化，欢迎提交 Issue。



