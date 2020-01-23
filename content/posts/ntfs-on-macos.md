---
title: NTFS on macOS
date: 2017-01-18 15:56:25
tags: [macOS, Tools]
---

最近在重造文件备份系统的时候，因为 Synology 默认支持 NTFS，而 macOS 也可以开启对 NTFS 的支持，计划建立这样的结构：

- 2T+1T Raid 0@Synology NAS : 日常大型文件存放
* TimeMachine@ macbook, nas：系统级备份
* Resilio Sync@ macbook, nas, iPhone ：日常工作文件夹同步
* 2T 外置硬盘 (NTFS)：连接 NAS 做计划备份（Synology 支持 NTFS）；在 mac 上开启对NTFS的支持；使用虚拟机使用 everything 检索文件
* 2T 外置硬盘 2 (NTFS)：长期冷备份

下面解决怎么让 mac 直接读写 NTFS。



*@macOS Sierra, 10.12.2*

有这么几个办法：

* Tuxera NTFS for Mac, 收费
* Paragon NTFS for Mac, 收费
* NTFS-3G, free
* 开启 macOS 内置支持, free
* windows 虚拟机

虚拟机已经有了，但是不太方便。试试开启内置支持，尽量不安新软件。

1. 给分区起个名字。这个名字将会再后面用到，默认格式化是没有名字的。mac 下连给 ntfs 改名都不可以！*还得开 windows 命名，摔！*右键分区，输入名字，apply。尽量不要带空格。

    ![/images/ntfs_on_macos/disk_format_name_it.png](/images/ntfs_on_macos/disk_format_name_it.png)

2. 进入 terminal, 执行
```
sudo nano /etc/fstab
```
写入,
```
LABEL=NAME none ntfs rw,auto,nobrowse
```

`NAME` 是分区名字，我这里是 “toshiba2t”。像这样`LABEL=toshiba2t none ntfs rw,auto,nobrowse`。如果名字有空格，使用`\040`代替空格，作为转意符。

> If you have multiple NTFS drives you want to write to, add a different line for each.

3. 断开再重连。
4. 进入分区。Finder，执行前往-前往文件夹，或者快捷键，`command+shift+g`输入`/Volumes`即可看到所有的分区。可以看到这个分区并且读写。
5. 使分区显示到桌面上。执行
```
sudo ln -s /Volumes/toshiba2t ~/Desktop/toshiba2t
```
当然，`toshiba2t`要改为你的分区名字。
6. 断开在重连。依然可以访问。如果要取消，删除那行`LABEL`即可。


---

# Reference

* [DiskStation Manager - Knowledge Base | Synology Inc.](https://www.synology.com/en-us/knowledgebase/DSM/help/DSM/AdminCenter/system_externaldevice_devicelist)
* [使用diskpart命令修复U盘分区 - 不明飞行物 - 51CTO技术博客](http://alien.blog.51cto.com/951694/599203/)
* [What is the difference between volume and partition? - Quora](https://www.quora.com/What-is-the-difference-between-volume-and-partition)
* [hard disk - Differences between volume, partition and drive - Unix & Linux Stack Exchange](http://unix.stackexchange.com/questions/87300/differences-between-volume-partition-and-drive)
* [How to Write to NTFS Drives on a Mac](http://www.howtogeek.com/236055/how-to-write-to-ntfs-drives-on-a-mac/)
* [打开Mac OSX原生的NTFS功能](http://www.tianwaihome.com/2014/07/mac-osx-ntfs.html)