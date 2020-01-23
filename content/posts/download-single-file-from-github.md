---
title: 下载 github 单个文件
date: 2017-01-02 23:08:37
tags: [Tools, Git]
---

以下载以下文件为例。

```sh
https://github.com/Supervisor/initscripts/blob/master/ubuntu
```
 
要下载这个文件，点击按钮 `Raw` ，得到下载地址。

```sh
https://raw.githubusercontent.com/Supervisor/initscripts/master/ubuntu
```

执行 

```sh
curl https://raw.githubusercontent.com/Supervisor/initscripts/master/ubuntu > a.txt
```

即这个文件下载到本地`a.txt`了。