---
title: Node.js 生产环境部署的几种方式
date: 2017-02-25 22:43:10
tags: [Node.js]
---

- pm2
- nginx + pm2
- yyx990803/pod (@尤雨溪)



---


# 最简单：使用 pm2

```
$ npm install -g pm2
$ pm2 start app.js -i 0 --name “app-name"
```


# 配合 nginx

## Q：为什么要配上 nginx 食用？

一个域名的直接访问是解析ip的80端口（浏览器会默认隐藏80端口），然而每一个node的进程又只能占用一个端口，那么当一个服务器（是指承载这些网站的机器，可能是windows、linux或者mac）上搭建的网站超过一个时，端口不够用。

一般情况下是使用node监听某些端口，然后按域名（看自己需求）进行转换，比如：

```
a.com => 9000
b.com => 9001
c.com => 9002
…
```

如此，可以使用一台服务器的一个接口配置多个站点。


## 配置步骤

一个站点一个 .conf 文件，通过 include 来加载，比如：

nginx.conf 文件是这样的：

```
http {
    # 其他的配置
    # 加载所有conf目录下的配置文件  
    include conf/*.conf;
}
```


conf 目录下的每一个 .conf 文件都是一个站点，比如 a.com 的代理到 9000 端口的配置大概是：

```
# conf/a.com.conf
server {
    server_name a.com;
    listen 80;

    location / {
        # proxy_http_version 1.1;
        proxy_set_header Connection "";
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $http_host;
        proxy_set_header X-NginX-Proxy true;
        proxy_pass http://127.0.0.1:9000$request_uri;
        proxy_redirect off;
    }
}
```


也可以选择使用nginx托管静态资源，

```
# 网站静态资源
/wwwroot/a.com/static/

# node程序
/wwwroot/a.com/lib/
```


使用 node+nginx 方式后，一般 node 服务的端口可以直接禁用掉外网访问，不然可能有人通过 `ip:port`直接访问你的 node 服务。上例就是关闭 9000 端口的外网访问。


# 整合

- [yyx990803/pod @尤雨溪](https://github.com/yyx990803/pod)

> 我个人写的部署工具，以前基于forever，现在基于pm2。在进程管理的基础上增加直接git push发布更新的功能。在我自己的vps上搭配nginx用着很省心。由于是个人项目，用于生产环境请务必小心，有问题欢迎github上开issue


---

# Ref

- [使用node和nginx部署网站服务](https://xuexb.com/html/nodejs-nginx-webserver.html)