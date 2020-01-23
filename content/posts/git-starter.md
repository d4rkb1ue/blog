---
title: Git 初步入门
date: 2016-03-09 22:55:17
tags: [Tools, Git]
---
# 创建版本库

## 把这个目录变成Git可以管理的仓库：
```
git init
```



*也不一定必须在空目录下创建Git仓库，选择一个已经有东西的目录也是可以的。*

## 把文件添加到仓库：
```
git add readme.txt
```

## （设置用户信息：）
```
git config --global user.email "7874364@gmail.com"
git config --global user.name "ray0"
```

*只要设置一次，好像只有在从来没用过git的情况下才会出现*


## 提交文件到仓库
```
git commit
```

为什么Git添加文件需要add，commit一共两步呢？因为commit可以一次提交很多文件，所以你可以多次add不同的文件，比如：
```
ray0@ubuntu:~/learngit$ touch b.txt
ray0@ubuntu:~/learngit$ touch c.c
ray0@ubuntu:~/learngit$ git add b.txt 
ray0@ubuntu:~/learngit$ git add c.c 
ray0@ubuntu:~/learngit$ git commit -m "add b/c"
[master 5ccb1c8] add b/c
 2 files changed, 0 insertions(+), 0 deletions(-)
 create mode 100644 b.txt
 create mode 100644 c.c
```

# 发生变化
## 状态

查看目前状态：
```
git status
```

**出现修改之后，需要重新`add`才能`commit`**

## 查看区别

```
git diff
```

# 回退
## 日志
每次commit的说明：
```
git log
```

或者 `git log --pretty=oneline` 显示在单行

## HEAD & 版本号
表示当前版本。
上一个版本: `HEAD^`
上上一个版本: `HEAD^^`
往上100个版本: `HEAD~100`
`5b892195a65c3e4886f27c170b55b354e041928a` 版本前的指纹就是版本号。在作为参数使用的时候，**无需写全。**

## reset
回退到上一个版本：
```
git reset --hard HEAD^
```

此时，`git log` `git diff` 就像刚刚提交了这个 commit 的状态一样。完全没有未来版本的痕迹。毁尸灭迹的非常严重。

回退到某一个版本：
```
git reset --hard 5b892195a65c3e4886f27c170b55b354e041928a
```

参数是长长的sha码。就是指定要的那个版本的指纹。使用这个命令，当然也可以不写全版本号，至少四位。
**这个指纹可以是未来的版本号哦！hard reset之后可以rest到在log里看不到但是存在过的未来的那个版本**

## 操作日志
```
git reflog
```

这个指令可以查看全部对库发生改变的指令。被 hard reset 替换的版本也会被记录下。

## CheckOut :)
```
git checkout -- readme.txt
```

把readme.txt文件在工作区的修改全部撤销。首先看，如果有`add`的版本就回退到那个版本，否则退到`commit`的版本。

## 撤销`add`
```
git reset HEAD file
```

再次撤销工作区修改的话：
```
git checkout -- readme.txt
```

现在依次撤销了 `add` 和 本地修改。

# 删除
```
git rm test.txt
```

同时在本地和`add`库中删除了该文件。如果需要撤销，`git reset HEAD c.c`，`git checkout -- c.c`依次撤销`add`库的修改，和 本地修改。

# 使用Github

## 首次使用
需要建立ssh-keygen
```
ssh-keygen -t rsa -C "youremail@example.com"
```

GitHub，打开“Account settings”，“SSH Keys”,“Add SSH Key”，填上任意Title，在Key文本框里粘贴`~/.ssh/id_rsa.pub`的内容

## 新建远程库
~~GitHub，“Create a new repo”。按照github的指示操作。~~

不要使用默认的HTTPS的同步方式，这个方式不支持两步验证，应使用 SSH式的，可以改为：
```
git remote set-url origin git@github.com:username/repo.git
```


## 推送到远程
```
git push origin master
```

推送的时候，完全将远程和本地的库一致。无需每次`commit`后都`push`。只要`push`一次，全部的版本都会存在。

## 部署到服务器
在远程服务器执行
```
git clone https://github.com/d4rkb1ue/joker.git
```

会在本地建立一个joker文件夹并下载全部。如果本身就有一个joker, 那就先删除了他呗。

**注意，`git clone git@github.com:d4rkb1ue/joker.git`要求下载这个git的客户端也需要把ssh_pub记录到github上。所以安心用https吧。

```
npm install 
```

因为npm_modules我没有上传。直接在本地下载好啦。反正所有的dependance都是自带版本号的：
```
"dependencies": {
    "body-parser": "~1.13.2",
    "cookie-parser": "~1.3.5",
    "debug": "~2.2.0",
    "ejs": "~2.3.3",
    "express": "~4.13.1",
    "morgan": "~1.6.1",
    "serve-favicon": "~2.3.0"
  }

```

---
# 参考

1. [廖雪峰-Git](http://www.liaoxuefeng.com/wiki/0013739516305929606dd18361248578c67b8067c8c017b000)
