### 说明
* 脚本取自github项目 sitoi/dailycheckin,源仓库使用MIT License，本人只需要恩山论坛签到功能，故将其他内容进行精简。本项目无UI界面，直接执行即可。
* 本地环境使用python3.12，低版本运行时可能在main.py调用时间函数时出错，自行百度即可将时间函数修改为适配您本地的版本
### 目录结构

```bash
|
├── config.json    #推送消息的配置文件 配置文件使用方式--->https://sitoi.github.io/dailycheckin/settings/config/
├── enshan
│   └── main.py    # python3执行脚本入口
├── main.py
├── shell          # shell版本 适合内存与存储不足的小设备
│   ├── README.md 
│   └── enshan.sh  
└── utils        # 各类消息推送脚本的执行逻辑
    ├── __init__.py
    └── message.py
        
```
如果您的设备资源不足请使用 [shell核心脚本](./shell/README.md) 了解实现逻辑。
