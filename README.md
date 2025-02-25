### 说明
* 脚本取自github项目 sitoi/dailycheckin,源仓库使用MIT License，本人只需要恩山论坛签到功能，故将其他内容进行精简。本项目无UI界面，直接执行即可。
* 本地环境使用python3.12，低版本运行时可能在main.py调用时间函数时出错，自行百度即可将时间函数修改为适配您本地的版本
### 目录结构

```bash
│  config.json        #存放推送消息的配置文件 配置文件使用方式--->https://sitoi.github.io/dailycheckin/settings/config/
│  main.py        # 执行脚本入口
│  __init__.py        # 初始化
│  __version__.py       # 版本信息
│
├─.idea
│  │  .gitignore
│  │  .name
│  │  dailycheckin.iml
│  │  misc.xml
│  │  modules.xml
│  │  workspace.xml
│  │
│  └─inspectionProfiles
│          profiles_settings.xml
│
├─enshan        # 恩山论坛签到主代码
│      main.py
│
└─utils       # 各类消息推送脚本的执行逻辑 
        message.py
        __init__.py
        
```
