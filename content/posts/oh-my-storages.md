---
title: "我的存储们"
date: 2021-02-01T06:34:03Z
tags: []
---

## 加密 - 使用 LUKS

![storage-stack.png](/images/storage-stack.png)

显示了分级的加密方式. LUKS 是位于 block system 层的加密. 位于 filesystem (比如 EXT4) 之**下**. 即加密之后的空间可以再被格式化为目标 filesystem. 

```diff
    |  |  |  [ EXT4 ]  |  |  |
    |  |  |            |  |  |
+   |  |  +--  LUKS  --+  |  |
    |  |                  |  |
    |  +---  Partition ---+  |
    |                        |
    +-----   Dev Disk   -----+
```

> Just make a partition to your liking, and put LUKS on top of it and a filesystem into the LUKS container

其实也可以省略掉 Partition 这层, 直接将整个 Disk 作为一个块设备加密. ([cryptsetup/FAQ](https://gitlab.com/cryptsetup/cryptsetup/-/wikis/FrequentlyAskedQuestions))
>  For Fully encrypted raw block device, put LUKS on the raw device (e.g. `/dev/sda`)

经过 LUKS 加密的磁盘层级是这样, 

```sh
$ lsblk
# encrypted
sda           8:0    0   1.9T  0 disk
└─sda1        8:1    0   1.9T  0 part

# unencrypted
sda           8:0    0   1.9T  0 disk
└─sda1        8:1    0   1.9T  0 part
  └─m2t     253:0    0   1.9T  0 crypt /media/m2t
```

### 创建加密分区

使用 Ubuntu 20 的话, 直接 Disk GUI 工具操作创建分区设定大小并且勾选 LUKS 加密即可. 

或者手动操作, 

```sh
# 分区
$ ?
# 创建加密块
# luks1 to force use LUKS version 1
$ cryptsetup luksFormat -M luks1 /dev/sda1
# 解密
$ cryptsetup open /dev/sda sda1
# 格式化
$ mkfs -t ext4 /dev/mapper/sda1
```

创建结束后可以查看, 

```sh
$ sudo apt install cryptsetup
$ sudo cryptsetup luksDump /dev/sda1
LUKS header information for /dev/sda1

Version:        1
Cipher name:    aes
Cipher mode:    xts-plain64
Hash spec:      sha256
Payload offset: 4096
MK bits:        512
MK digest:      fc 26 e2 a5 85 cd c9 49 4a ce da 84 fc 43 ab 14 8c 4a ca 7f
MK salt:        ff ec a7 cf 98 5e c6 aa 27 51 0e 98 6c a6 f7 7d
                8b 1b fe 76 1b 80 14 04 91 2a c8 59 27 0c 84 aa
MK iterations:  87614
UUID:           bfe1bc96-fee1-4b1e-8f89-6ac2cb09a97f

Key Slot 0: ENABLED
        Iterations:             1418912
        Salt:                   9b c2 d0 59 7a b8 9d e7 bd 7b d1 3a a6 41 8f fd
                                ab 8e d4 32 27 87 5d 2f ee e2 f0 24 ad 6a 51 8f
        Key material offset:    8
        AF stripes:             4000
Key Slot 1: DISABLED
Key Slot 2: DISABLED
Key Slot 3: DISABLED
Key Slot 4: DISABLED
Key Slot 5: DISABLED
Key Slot 6: DISABLED
Key Slot 7: DISABLED
```

每个 Key Slot 即是一个新的密钥. 对一个加密分区可以设置独立(或)密钥, 每个都可以开锁. 

使用 `cryptsetup` 的命令来增删改密码, 
```
cryptsetup  luksAddKey
            luksChangeKey
            luksRemoveKey
```

解密和挂载, 

```sh
# 在未解密的情况下
$ sudo mount /dev/sda1 /media/m2t
mount: /media/m2t: unknown filesystem type 'crypto_LUKS'.

# 解密
$ sudo cryptsetup open /dev/sda1 m2t    # map to /dev/mapper/m2t

# 挂载
$ sudo mount /dev/mapper/m2t /media/m2t # mount to /media/m2t

# 看看
$ df -h
/dev/mapper/m2t  1.9T   77M  1.8T   1% /media/m2t
```


手动关闭, 

```sh
$ umount /media/m2t
$ cryptsetup close sda1
```

其实很少需要, 因为一旦关机(gracefully 或者拔电源)依旧是加密状态, 数据不会因此就暴露了. 原理是

> For the purposes of disk encryption, each blockdevice (or individual file in the case of stacked filesystem encryption) is divided into sectors of equal length, for example 512 bytes (4,096 bits). The encryption/decryption then happens on a per-sector basis, so the n'th sector of the blockdevice/file on disk will store the encrypted version of the n'th sector of the original data.
> Whenever the operating system or an application requests a certain fragment of data from the blockdevice/file, the whole sector (or sectors) that contains **the data will be read from disk, decrypted *on-the-fly*, and temporarily stored in memory**:
> ```
>            ╔═══════╗
>   sector 1 ║"???.."║
>            ╠═══════╣         ╭┈┈┈┈┈╮
>   sector 2 ║"???.."║         ┊ key ┊
>            ╠═══════╣         ╰┈┈┬┈┈╯
>            :       :            │
>            ╠═══════╣            ▼             ┣┉┉┉┉┉┉┉┫
>   sector n ║"???.."║━━━━━━━(decryption)━━━━━━▶┋"abc.."┋ sector n
>            ╠═══════╣                          ┣┉┉┉┉┉┉┉┫
>            :       :
>            ╚═══════╝
>   
>            encrypted                          unencrypted
>       blockdevice or                          data in RAM
>         file on disk
> ```
> Similarly, on each write operation, all sectors that are affected must be re-encrypted completely (while the rest of the sectors remain untouched).
> 
> ([archlinux/Data-at-rest_encryption](https://wiki.archlinux.org/index.php/Data-at-rest_encryption))


## TODO 云备份

在 Ubuntu 下如果希望忽略 `lost+found` 文件夹, 

```sh
$ rsync -a --info=progress2 --exclude "lost+found" /media/sum4t/doc /media/m2t
```

## SMB

启动 SMB Docker container, 

```sh
# 使用 env 是为了方便改成 --env-file
# SHARE 的参数格式 name;path;browsable;readonly;guest;users;admins;writelist;comment
# dperson/samba 支持多个 USER/SHARE 变量, 直接以 USER1, USER2, ... 为名传入
# 比如 -e SHARE2='share2;/mount/m2t2;yes;no;no;user1;user1;user1'

$ docker run --restart=always -d \
  -e USER='user1;badpass' \
  -e SHARE='share1;/mount/m2t;yes;no;no;user1;user1;user1' \
  -p 139:139 -p 445:445 \
  -v /media/m2t:/mount/m2t \
  -v /media/tm:/mount/tm \
  dperson/samba
```

访问, 
(替换 `deskmini.local` 为你的 server 名字, 本地 LAN 上可以尝试用 hostname.local 看看有没有自动的 DDNS 设定, 不然就直接上 IP)

- `smb://deskmini.local/share1` 来访问 `share1` 用户名 `user1` 密码 `badpass`

## Time Machine

Time Machine 也可以用 Docker container 来建立. 

因为 macOS 无法使用自定义的 SMB 端口, 只能是默认的 `445`, 所以我们需要为我们的新 Time Machine container 开一个新的 IP. 

在此我们使用 MACVLAN 来复用我的小 Deskmini 上的唯一的物理 Ethernet 端口, 来模拟多个 MAC 地址/NIC 因此可以获取多个 IP 来供新的 container 使用. 

首先来创建 MACVLAN, 先确认我本地的 IP 段, 网关, 网卡名, 

```sh
$ ip r | grep ^default
default via 192.168.164.1 dev enp0s31f6 proto dhcp metric 100

$ ip a | grep 192.168.
    inet 192.168.164.214/24 brd 192.168.164.255 scope global dynamic noprefixroute enp0s31f6

# so I should use CIDR 192.168.164.0/24, gateway 192.168.164.1, device enp0s31f6

$ docker network create -d macvlan --subnet=192.168.164.0/24 --gateway=192.168.164.1 -o parent=enp0s31f6 macvlan1
```

Then start the container,
```sh
$ docker run --restart=always -d \
    --name tm \
    --hostname timemachine \
    --network macvlan1 \
    --ip 192.168.164.2 \
    -p 137:137/udp \
    -p 138:138/udp \
    -p 139:139 \
    -p 445:445 \
    -e TM_USERNAME="username-sameto-sharename" \
    -e PASSWORD="badpass2" \
    -e SET_PERMISSIONS="false" \
    -e SHARE_NAME="TimeMachine" \
    -v /media/tm:/opt/username-sameto-sharename \
    -v timemachine-var-lib-samba:/var/lib/samba \
    -v timemachine-var-cache-samba:/var/cache/samba \
    -v timemachine-run-samba:/run/samba \
    mbentley/timemachine:smb
```

在 macOS 上设定 Time Machine 前, 我们最好先把我们指定的 IP `192.168.164.2` 在路由器上设定为静态 IP. 这样就不会被路由器的 DHCP 意外的分配给其他设备. 

最后, 在 macOS 上的 "Time Machine" 应该可以直接看到名为 `TimeMachine` 的磁盘, 记得打开 "Encrypt backups".


## Refs.

1. [保护数据, 用 LUKS 给磁盘全盘加密](https://nova.moe/encrypt-disk-with-luks/)
2. [cloudflare/Speeding up Linux disk encryption](https://blog.cloudflare.com/speeding-up-linux-disk-encryption/)
3. [archlinux/dm-crypt/Encrypting an entire system]( https://wiki.archlinux.org/index.php/Dm-crypt/Encrypting_an_entire_system)
4. [archlinux/Data-at-rest_encryption](https://wiki.archlinux.org/index.php/Data-at-rest_encryption)
5. [cryptsetup/FAQ](https://gitlab.com/cryptsetup/cryptsetup/-/wikis/FrequentlyAskedQuestions)
6. [github/dperson/samba](https://github.com/dperson/samba)
7. [github/mbentley/docker-timemachine](https://github.com/mbentley/docker-timemachine)


## 我的空间记录

| Model                    |  Size |    Crypt | Usage                                |
| :----------------------- | ----: | -------: | :----------------------------------- |
| WD SN550 NVME SSD        |    1T | 内容加密 | 系统 和 Time machine (本体加密)      |
| Samsung 860 EVO SATA SSD |    4T |     LUKS | 主数据盘                             |
| Micron 1100 SATA SSD     |    2T |     LUKS | 主数据盘热备份                       |
| Toshiba Portable HDD     |    2T |       无 | 主数据盘冷备份之一                   |
| Samsung SATA HDD         |    2T |       无 | -                                    |
| Samsung T3 Portable SSD  | 250GB |       无 | 临时用 Time Machine 中转站           |
| HGST SATA HDD            |   1TB |       无 | -                                    |
| Google Drive (UC Irvine)   |     ∞ |       无 | 主数据盘冷备份之二                   |
| iCloud Drive             | 200GB |       无 | iPhone&iPad 备份 + 照片 + 桌面文件夹 |
