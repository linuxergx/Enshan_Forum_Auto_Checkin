# EnShan 论坛签到 Shell 脚本

## 介绍
这是一个用于自动签到恩山无线论坛（EnShan Forum）的 Shell 脚本，专为资源受限的设备（如路由器）设计。它通过模拟 HTTP 请求完成签到，并将结果通过 Bark 推送通知。

## 功能
- 自动签到恩山无线论坛。
- 提取并显示“恩山币”和“积分”。
- 通过 Bark 推送通知签到结果。

## 环境要求
- **BusyBox**：支持 `grep`、`sed`、`curl` 和 `jq`。
- **网络连接**：能够访问恩山论坛和 Bark 服务。
- **Cookie**：有效的恩山论坛登录 Cookie。
- **Bark URL**：用于推送通知的 Bark 服务 URL。

## 安装
1. **安装必要的工具**：
   - 确保你的设备上安装了 `curl` 和 `jq`。如果未安装，可以通过以下命令安装（具体命令取决于你的系统）：
     ```bash
     opkg install curl jq  # OpenWRT 系统
     # 本人使用的路由器为二手拆emmc芯片，刷了Padavan固件的鲁班jdc-1,有opkg命令但切换root之后还是报权限问题
     ```

2. **准备配置文件**：
   - 创建 `config.json` 文件，并填写你的恩山论坛 Cookie 和 Bark URL：
     ```json
     {
         "ENSHAN": [
             {
                 "cookie": "your_enshan_cookie_here"
             }
         ],
         "BARK_URL": "https://api.day.app/your_bark_key/"
     }
     ```

3. **下载脚本**：
   - 将脚本文件 `sign_enshan.sh` 放在与 `config.json` 同一目录下。

## 使用方法
1. **赋予脚本执行权限**：
   ```bash
   chmod +x sign_enshan.sh
   ```

2. **运行脚本**：
   ```bash
   ./sign_enshan.sh
   ```

3. **定时任务（可选）**：
   - 如果你希望每天自动签到，可以将脚本添加到定时任务中。例如，在 `cron` 中添加以下任务：
     ```bash
     0 8 * * * /path/to/sign_enshan.sh
     ```
     这将在每天早上 8 点执行签到脚本。

## 注意事项
- **Cookie 有效期**：确保你的恩山论坛 Cookie 是有效的。如果 Cookie 失效，需要更新 `config.json` 文件。
- **网络连接**：确保你的设备可以访问恩山论坛和 Bark 服务。
- **资源限制**：本脚本专为资源受限的设备设计，尽量减少了对系统资源的占用。

## 贡献
如果你有任何改进建议或遇到问题，欢迎提交 Issue 或 Pull Request。