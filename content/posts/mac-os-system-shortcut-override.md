---
title: Mac OS (OS X) 系统级快捷键重载
date: 2016-10-20 23:14:22
tags: [macOS, Tools]
---


# meta

Mac 系统默认的所有程序退出快捷键是 `Command + Q` 有的时候按快了而没注意焦点位置，容易误操作。以下用 Sublime 为例将默认的退出快捷键由 `Command + Q` 改为 `Control + Command + Q`。



# 环境

Mac OS Sierra 10.12

# 步骤

1. System Preference(系统设置) -> Keyboard(键盘) -> Shortcut(快捷键)，在左侧列表的最后一项，应用快捷键。

2. 点击 `+` 添加新快捷键。

3. 在程序列表中选择 Sublime Text.app， 菜单标题照抄原快捷键说明：`Quit Sublime Text`  *(注意大小写，空格，都不能差)*

    ![system-shortcut-override-sublime-1](/images/system-shortcut-override-sublime-1.png)

4. 键盘快捷键录入新快捷键。

5. 结果如图。

    ![system-shortcut-override-sublime-2](/images/system-shortcut-override-sublime-2.png)

# 结果

在 Sublime 中使用 `Command + Q` 没有任何效果。新快捷键 `Control + Command + Q` 生效。完全覆盖。

# Trouble shooting

1. 快捷键说明注意大小写，空格，都不能差。

2. 注意避开已被软件指定的快捷键。比如 `Option + Command + Q` 默认在 Sublime 中就被占用了。


 
