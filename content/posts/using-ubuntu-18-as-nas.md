---
title: "折腾 Ubuntu 18.04 做 NAS"
date: 2018-07-22 21:11:31
tags: [Gadget, Linux]
---

一直在用 Deskmini 搭了黑群晖，但是其实用不到群晖的生态系统，索性自己安装个 Ubuntu 还方便自己自由维护使用。

- 远程界面
- 挂载 NTFS
- 备份
- 开启 SMB 服务
- 开启 Time Machine 服务：[Time Machine On Ubuntu 18 with samba](https://drkbl.com/ubuntu-18-samba-time-machine/)


# 远程界面

Ubuntu 没有网页端的 GUI，有时候还是想用界面来操作。不能总连着个显示器。所以用远程桌面替代，可以满足的选择有很多。

- 18.04 自带了 vino，如果是 minimal install 需要自行安装， `sudo apt-get install vino ssh`

重启后进入设置，开启 sharing -> desktop 开启密码。


## 客户端：VNC Viewer 

https://www.realvnc.com/

connect by,

`192.168.1.110:5900` 

(your ip `ip:5900`)



## Trouble Shooting


### encryption 登录失败

如果远程登录因为 encryption 的原因不成功，改一条设置即可，

```
gsettings set org.gnome.Vino require-encryption false
```

注意安全，如果不暴露到外网还好。

### 重启后无法登录

原因很简单，重启后未登录 Gnome 用户的情况下，服务进程还没启动，每次启动后在 Gnome 上登录一次就好了，但是还是很麻烦，每次重启要连一次键盘鼠标很淡疼啊，(ssh 登录没用)，解决办法：

https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-vnc-on-ubuntu-18-04

# Mount NTFS

In ubuntu 18, you can just using the stock app: "Disks"  to mount and manage disks.

## Mount in terminal

- Ref: [How to Mount NTFS partition in Ubuntu 16.04 - Ask Ubuntu](https://askubuntu.com/questions/978746/how-to-mount-ntfs-partition-in-ubuntu-16-04/978750)

For mount once,

```bash
# show all devices/partitions to find the target path
# remember use
sudo fdisk -l

# create mount destination
sudo mkdir /media/ntfs

# may like /dev/sdc1
sudo mount -t ntfs -o nls=utf8,umask=0222 /dev/sdc1 /media/ntfs

# unmount
sudo umount /media/ntfs
```


For auto mount,
https://askubuntu.com/questions/46588/how-to-automount-ntfs-partitions

## Mount ExFAT

https://www.howtogeek.com/235655/how-to-mount-and-use-an-exfat-drive-on-linux/

# 备份

```
rsync -av /src /des
```

# SMB

如果需要开启 Time Machine，不要直接这么安装，版本不够新，还得折腾。请看另一篇博客关于开启 Time Machine 的。

[Install and Configure Samba | Ubuntu tutorials](https://tutorials.ubuntu.com/tutorial/install-and-configure-samba#0)

```bash
sudo apt update
sudo apt install samba
sudo nano /etc/samba/smb.conf

#! /etc/samba/smb.conf
#! sambashare will be the name of share path
[sambashare] 
    path = /path/to/share/folder
    read only = no
    browsable = yes
# 	  valid users = user_only_can_access
sudo service smbd restart

# Username used must belong to a system account
sudo smbpasswd -a username
```

On Windows,
`\\ip-address\sambashare`

On Mac,
`smb://ip-address/` 

