---
title: 私有翻墙服务搭建指南
date: 2017-01-04 16:38:37
tags: [Tools, Proxy]
---

# 简介

- 如何购买服务器？
- 如何配置服务器？
- 在 Mac, Windows, iOS, Android 设备上通过配置好的服务器翻墙
- 高级玩法



# 购买 VPS

- 费用：以下两家服务商提供的最低配价格都是$5/月*；如果使用快照服务，DigitalOcean 收取极少量费用，Vultr 免费。

## 服务商推荐

- [DigitalOcean $10 优惠](https://m.do.co/c/93c5105aab61): DigitalOcean 的新加坡, 旧金山, 纽约服务器都还可以。
- [Vultr 限时 $20 优惠](http://www.vultr.com/?ref=7076061-3B), [Vultr $10 优惠](http://www.vultr.com/?ref=7076060): Vultr 的日本东京服务器速度飞快！
- [阿里云国际](https://sp-buy-intl.aliyun.com/simple), 推荐香港。**CN2 线路, 当前最优选择**。

*注：通过以上链接注册，在你将获得优惠的同时，作者也将获得相应的推广回报。使用以下链接可以避免给作者回报 `http://digitalocean.com/`，`http://www.vultr.com/`* 

## 使用 DigitalOcean

- [测速地址](http://speedtest-sfo1.digitalocean.com)
- 懒人推荐：SGP1, SFO2, NYC1

### 流程

1. 点击 Create Droplets
1. Image 选择 Ubuntu 16.04.x x64
1. Size 选择最低的$5版本即可
1. Datacenter Region 选择刚刚选好的那个服务器
1. （*按需）SSH keys, `New SSH key`, 输入`.ssh/id_rsa.pub`中的内容，格式大约是：`ssh-rsa AAAA...Bjjdwd d4rkb1ue@drkbl.com`
1. Create!
1. 等待进度条走完，就可以看到 IP 地址了，如`138.197.84.40`

## 使用 Vultr

- [测速地址](https://www.vultr.com/faq/#downloadspeedtests)
- 懒人推荐：Tokyo

*流程类似。不赘述。*

## 使用阿里云

1. 使用 [此链接](https://sp-buy-intl.aliyun.com/simple) 创建一个 ECS 服务器
1. 进入 Consol 控制台 -> Elastic Compute Service, 可以看到刚刚创建的 instance 实例
1. 在侧边栏选择 Networks and Security -> SSH Key Pair
1. Create SSH Key Pair, 选择 Import SSH Key Pair, 输入本地电脑 `.ssh/id_rsa.pub` 中的内容，格式大约是: `ssh-rsa AAAA...Bjjdwd d4rkb1ue@drkbl.com`
1. OK 创建。将这个 key bind 绑定到刚刚创建的 instance
1. 在 instance 的 action 中选择 more -> Netword and security group -> Configure
1. Add Rules -> 增加一条 ingress, allow, customized TCP, port range=`8388/8388`(或者你的 SS 服务端口), Authorization Objects=`0.0.0.0/0`
1. 重启 instance
1. 可供访问的 IP 是 Internet IP

# 服务端安装

## 登入远程服务器

在 Mac 上操作, `138.197.84.40` 需要替换为你的 IP,

```
ssh root@138.197.84.40
```

出现诸如 `Do you want/Are you sure to xxx? [Y/n]` 输入 `Y` 或者yes，回车

<!-- ### PC -->

## 安装 Shadowsocks

1. 安装程序
    
    ```
    sudo apt-get update
    sudo apt-get install python-pip
    sudo pip install shadowsocks
    ```
    
2. 新建配置

    ```
    nano /etc/shadowsocks.json
    ```

3. 编辑配置文件

    将下面的代码复制粘贴。其中，`server_port`, `password`, `method` 可自定义。输入完毕按`Ctrl+x`，再按y保存。

    ```
    {
        "server":"0.0.0.0",
        "server_port":8388,
        "local_address": "127.0.0.1",
        "local_port":1080,
        "password":"yourpassword",
        "timeout":300,
        "method":"aes-256-cfb",
        "fast_open": false,
        "workers": 1
    }
    ```

4. 启动服务

    ```
    ssserver -c /etc/shadowsocks.json -d start
    ```

5. （*按需）关闭服务

    ```
    ssserver -c /etc/shadowsocks.json -d stop
    ```

# 在终端上通过配置好的服务器翻墙

## macOS

- [Shadowsocks-for-OSX](https://github.com/shadowsocks/shadowsocks-iOS/wiki/Shadowsocks-for-OSX-帮助) 需要手动切换 branch 到 `master` 才能看到 release 版本
- [Shadowsocks-for-OSX@sourceforce](https://sourceforge.net/projects/shadowsocksgui/)

## iPhone

- [Shadowrocket](https://itunes.apple.com/cn/app/shadowrocket/id932747118?mt=8) 
- [Surge](https://itunes.apple.com/us/app/surge-web-developer-tool-and-proxy-utility/id1040100637?mt=8)

## Surge 配置

打开 Surge App
选择 从 URL 下载配置，输入 

```
https://raw.githubusercontent.com/d4rkb1ue/SurgeConfig/master/Shadowsocks.conf
```

编辑 Shadowsocks.conf，将 `#Shadowsocks Server IP#`, `#Shadowsocks Server Port#`, `#password#` 替换为`你的 VPS IP`, `端口 port 上面示例是 8388`, `你的密码`（替换整体，包括`#`号）
开始此配置。

[https://github.com/d4rkb1ue/SurgeConfig](https://github.com/d4rkb1ue/SurgeConfig)


## 解决 Shadowsocks for osx 更新 gfwlist（自定义规则）发生错误

新建 update_gfwlist.sh，复制粘贴以下：

```
#!/bin/bash
# update_gfwlist.sh
# Author : VincentSit
# Copyright (c) http://xuexuefeng.com

GFWLIST="https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt"
PROXY="127.0.0.1:1080"
USER_RULE_NAME="user-rule.txt"

check_module_installed()
{
    pip list | grep gfwlist2pac &> /dev/null

    if [ $? -eq 1 ]; then
        echo "Installing gfwlist2pac."

        pip install gfwlist2pac
    fi
}

update_gfwlist()
{
    echo "Downloading gfwlist."

    curl -s "$GFWLIST" --fail --socks5-hostname "$PROXY" --output /tmp/gfwlist.txt

    if [[ $? -ne 0 ]]; then
        echo "abort due to error occurred."
    exit 1
    fi

    cd /Users/$(logname)/.ShadowsocksX || exit 1

    if [ -f "gfwlist.js" ]; then
        mv gfwlist.js ~/.Trash
    fi

    if [ ! -f $USER_RULE_NAME ]; then
        touch $USER_RULE_NAME
    fi

    /usr/local/bin/gfwlist2pac \
    --input /tmp/gfwlist.txt \
    --file gfwlist.js \
    --proxy "SOCKS5 $PROXY; SOCKS $PROXY; DIRECT" \
    --user-rule $USER_RULE_NAME \
    --precise

  rm -f /tmp/gfwlist.txt

  echo "Updated."
}

check_module_installed
update_gfwlist
```

保存。

修改权限：`chmod +x update_gfwlist.sh`

修改 “user-rule.txt” 之后，执行 `sudo ./update_gfwlist.sh`

（在 “user-rule.txt” 尾部添加1行`example.com`即可加入 `*.example.com/*` 的 Proxy 规则，如：
```
! Put user rules line by line in this file.
! See https://adblockplus.org/en/filter-cheatsheet
digitalocean.com
googletagmanager.com
```
)

<!-- 
## iOS 安装
### Surge/Shadowrocket
### VPN 描述文件

## Windows 安装

## Android 安装 -->

----------------------------------

# 高级技巧

## 使用`rsync`来同步文件

每次都`nano`一个新文件，但是在命令行做文本编辑很不舒服。对于不想学习vim的同学来说，在本地用sublime，vscode等一众舒适的文本编辑器编辑好了再同步到远程是一个不错的方式。以同步shadowsocks的conf配置文件举例，在本地`~/shadowsocks.json`编辑好文件后，输入

```
rsync --delete --rsh=ssh -av ~/shadowsocks.json root@138.197.84.40:/etc/shadowsocks.json
```

即可同步到远程`/etc/shadowsocks.json`处。

- `--delete`: 如果目的地有同名文件，则删除
- `-a`: achieve 模式
- `-v`: 反馈可见。上传成功与否会显示出结果
- `--rsh=ssh`: 登陆远程服务器模式，可以在后面加入密码，端口什么的

## 为服务器产生快照

### DigitalOcean

1. 进入 Image 
2. Take a Snapshot，选择做好的那个服务器，自定义名字
3. 点击 Take Snapshot
4. 调整 Snapshot 的位置：在做好的 Snapshot 上点击 More，选择 Add to region， 移动到你想要的地方
5. 使用做好的 Snapshot 新建服务器（服务器所在地要有这个 Snapshot，执行第4步来添加存储位置）：Create Droplots 时，在 Choose an image 中选择 Snapshot 选项卡，选择你想要的 Snapshots，而不是选择 Ubuntu

### Vultr

1. 选择做好的 Server
2. 点击 Snapshot
3. 输入 label，点击 Take a Snapshot
4. Vultr 制造新的 Snapshot 需要1个小时，这个体验真的不好


## 使用 systemctl 建立系统服务自动托管

好处:

- 重启后可以自启动
- 保存为 Snapshot 快照后可以快速建立，自动启动，免除一切服务端配置，便于迅速更换 IP

要建立 Linux 系统服务，在 SS 服务器新建文件

```
/etc/systemd/system/shadowsocks.service
``` 

复制粘贴以下内容

```sh
[Unit]
Description=Shadowsocks
After=network.target

[Service]
ExecStart=/usr/bin/python /usr/local/bin/ssserver -c /etc/shadowsocks.json start
ExecReload=/bin/kill -9 $MAINPID
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

注意在 command 行没有 `-d` ，因为`-d`是 shadowsocks 运行为 daemon，后台程序的参数。我们需要 supervisor 来监控 shadowsocks ，所以不要运行为后台程序。
完成保存退出。

如果 shadowsocks 已经在运行了，需要先执行

```sh
ssserver -c /etc/shadowsocks.json -d stop
```

开启服务。 

```sh
sudo systemctl reenable shadowsocks.service
sudo systemctl restart shadowsocks.service

# 查看服务状态
sudo systemctl status shadowsocks.service
# (如需)中止服务
sudo systemctl stop shadowsocks.service
```

*如果发生问题，尝试重启。*

# 加速

https://github.com/iMeiji/shadowsocks_install/wiki/开启TCP-BBR拥塞控制算法