---
title: Unix 正确编译运行多文件 Java
date: 2016-09-19 18:38:14
tags: [Linux, Java]
---

*0基础 Java 命令行编译~*



# 目录结构

1. 建立 package 文件夹，如 `~/project/myPackage`
2. 在 `~/project/myPackage` 下存放多个 java 文件
3. 每个 java 文件除注释外首行应为本 package 名 `package myPackage;`

# 编译

1. 在 `~/project` 目录下执行 `javac myPackage/*.java` 编译全部 java 文件

# 运行

1. 在 `~/project` 目录下执行 `java myPackage.MainClass` 或 `java myPackage/MainClass` 均可
