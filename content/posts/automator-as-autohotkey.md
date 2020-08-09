---
title: 用 macOS 的 Automator 做 AutoHotKey
date: 2017-02-01 17:19:55
tags: [macOS, Tools]
---

使用 Automator 当作 Safari@macOS 的按键精灵，敲简单的。此方法不兼容 Chrome@macOS。

# 例子 - 在 Safari 上循环点击按钮
目标：每隔一段时间，自动点击 Safari 网页上的一个按钮。



打开 Automator，新建一个“服务”。

![automator_create.png](/images/automator/automator_create.png)

在左侧资源库中，选择“实用工具” —> “开启应用程序“。拖到右侧工作流程中。

![automator_open_app.png](/images/automator/automator_open_app.png)

开启“Safari.app”。（如有多个窗口，将会切换到最近窗口）

![automator_open_safari.png](/images/automator/automator_open_safari.png)

接下来，录制。点击红色按钮开始录制。

![automator_record_button.png](/images/automator/automator_record_button.png)

切换到 Safari，点击按钮。

![automator_safari_button.png](/images/automator/automator_safari_button.png)

在控制面板上点结束。

![automator_record_panel.png](/images/automator/automator_record_panel.png)

录制结果如下：

![automator_safari_record_result.png](/images/automator/automator_safari_record_result.png)

可以点击“运行”（Command+R）测试一下。（这里有2个条目，其实删除一个也完全OK。选择条目敲击“delete”即可。）

加入循环：左侧资源库 —> 实用工具 —> 循环，拖到右侧。放在“我做给您看”后面即可。

![automator_circle.png](/images/automator/automator_circle.png)

将“要求继续”改为“自动循环”。可自选按重复时间（分钟）计，还是按重复次数计。我这里选择按照重复次数。

![automator_circle_result.png](/images/automator/automator_circle_result.png)

运行，测试一下。

可以将本脚本保存起来。以备后用。

如果需要提前终止，将当前程序焦点切换到 Automator，快捷键 Command + .(句号) 即可停止。

完成文件：[safariAutoClick.workflow](/safariAutoClick.workflow)