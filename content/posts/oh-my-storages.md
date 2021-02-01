---
title: "我的存储们"
date: 2021-02-01T06:34:03Z
tags: []
---

## 空间

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

## 加密 - 使用 LUKS

![storage-stack.png](/images/storage-stack.png)

显示了分级的加密方式。LUKS 是位于 block system 层的加密。位于 filesystem (比如 EXT4) 之**下**。即加密之后的空间可以再被格式化为目标 filesystem。

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

其实也可以省略掉 Partition 这层，直接将整个 Disk 作为一个块设备加密。([cryptsetup/FAQ](https://gitlab.com/cryptsetup/cryptsetup/-/wikis/FrequentlyAskedQuestions))
>  For Fully encrypted raw block device, put LUKS on the raw device (e.g. `/dev/sda`)

经过 LUKS 加密的磁盘层级是这样，

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

使用 Ubuntu 20 的话，直接 Disk GUI 工具操作创建分区设定大小并且勾选 LUKS 加密即可。

或者手动操作，

```sh
# 分区
$ ?
# 创建加密块
$ cryptsetup luksFormat /dev/sda1
# 解密
$ cryptsetup open /dev/sda sda1
# 格式化
$ mkfs -t ext4 /dev/mapper/sda1
```

创建结束后可以查看，

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

每个 Key Slot 即是一个新的密钥。对一个加密分区可以设置独立(或)密钥，每个都可以开锁。

使用 `cryptsetup` 的命令来增删改密码，
```
cryptsetup  luksAddKey
            luksChangeKey
            luksRemoveKey
```

解密和挂载，

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


手动关闭，

```sh
$ umount /media/m2t
$ cryptsetup close sda1
```

其实很少需要，因为一旦关机(gracefully 或者拔电源)依旧是加密状态，数据不会因此就暴露了。原理是

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

## TODO Time Machine + SMB + FTP 存取

## Refs.

1. [保护数据，用 LUKS 给磁盘全盘加密](https://nova.moe/encrypt-disk-with-luks/)
2. [cloudflare/Speeding up Linux disk encryption](https://blog.cloudflare.com/speeding-up-linux-disk-encryption/)
3. [archlinux/dm-crypt/Encrypting an entire system]( https://wiki.archlinux.org/index.php/Dm-crypt/Encrypting_an_entire_system)
4. [archlinux/Data-at-rest_encryption](https://wiki.archlinux.org/index.php/Data-at-rest_encryption)
5. [cryptsetup/FAQ](https://gitlab.com/cryptsetup/cryptsetup/-/wikis/FrequentlyAskedQuestions)