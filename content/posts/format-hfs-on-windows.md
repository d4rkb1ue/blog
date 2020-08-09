---
title: 格式化 HFS+ on Windows
date: 2017-01-18 15:37:37
tags: [macOS, Tools]
---

在 Windows 10 上格式化原有 HFS+ 格式的外置硬盘时，发现有一个 200MB 的分区无法删除，可以使用 Diskpart 来解决。



- Microsoft DiskPart on Windows

![/images/format_hfs_on_windows/diskpart_error.jpg](/images/format_hfs_on_windows/diskpart_error.jpg)

进入 CMD，执行 `diskpart` 进入程序。`list disk` 可以看到所有的磁盘，`select disk x` 选择指定磁盘。

选择好了再 `list disk` 一下，确认该硬盘被 `* … *` 围住

![/images/format_hfs_on_windows/diskpart_select.jpg](/images/format_hfs_on_windows/diskpart_select.jpg)

执行
```
clean
```

即可删除所有分区。

这么删除之后，会发现在计算机管理-磁盘工具中，无法直接建立新分区。应该是没有分区表。

![/images/format_hfs_on_windows/disk_format_error.png](/images/format_hfs_on_windows/disk_format_error.png)

怎么建立，可以`help`一下。执行`help`可以看到命令列表。具体到某一个命令可以执行，比如`creat`命令，执行 `help create`，下面还可以再继续 `help create partition` 等等。create 可以创建 volumn(卷) 或者 partition(分区)，不过这俩又啥区别呢。

**Diff Partitions & Volumes**:

> A partition is a just a space crafted out of a disk.
> For example- you could set aside a space of 100 GB for a partition from a hard disk of 1 TB.
> 
> A volume is a partition that has been formatted into a filesystem.
> A partition is of little use unless formatted. And when we format a partition into NTFS, FAT32, ext4 etc, it becomes a volume and is usable.
[What is the difference between volume and partition? - Quora](https://www.quora.com/What-is-the-difference-between-volume-and-partition)

也就是说，partition 是没格式化的 volumn。

于是可以创建一个分区，再格式化，这比较符合我的习惯。
```
create partition parimary
```

创建一个全部大小的主分区。于是我们得到了一个 raw 格式的磁盘。
*如果没看到，弹出再插上即可。*

这个时候，其实就建立了 MBR 分区表了，接下来的工作就可以再磁盘管理，图形化界面解决了。

![/images/format_hfs_on_windows/disk_format_mbr.png](/images/format_hfs_on_windows/disk_format_mbr.png)

我改成了一个 1 GB 的 exFat + 1.81 TB 的 NTFS。exFat是备用的，比如放个 NTFS 的驱动 @linux，@mac。

---
# Reference
- [刪除硬碟裡頑強的 EFI 分割區，還你完整空間](http://www.techbang.com/posts/6982-a-to-delete-a-stubborn-stick-ji-efi-partition-yang-liwei)