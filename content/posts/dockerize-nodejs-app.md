---
title: Dockerize Node.js APP
date: 2017-02-20 18:33:21
tags: [Nblog, Node.js, Docker]
---

# 案例
以运行 [d4rkb1ue/joker](https://github.com/d4rkb1ue/joker)  为例



# 步骤
将 [d4rkb1ue/joker](https://github.com/d4rkb1ue/joker) 下载到本地，并作为工作路径
```
$ git clone https://github.com/d4rkb1ue/joker.git
$ cd joker
```

## 数据库

基于Dockerfile 建立 mongodb 的 image `d4rkb1ue/mongodb`, Dockerfile 位于 `/joker/dockerfile/mongodbDockerfile` 并命名为 mongodb
```
$ docker build -t "mongodb" - < dockerfile/mongodbDockerfile    
```


建立 mongodb 的 container，命名为`jokerdb`，并映射本地`~/Development/joker/sample_database/` 到 container 中的 `/data/db`目录。本地目录为`joker`所在目录。（必须要绝对路径）
```
$ docker run -p 27017:27017 --name jokerdb -v ~/Development/joker/sample_database/:/data/db -d mongodb
```


修改 `~/Development/joker/settings.js`，替换 `192.168.50.6` 为本地地址。可以通过 `ifconfig` 命令查看。
```
# 本行中的地址修改为本地地址，不可用 localhost
mongodbUrl: 'mongodb://192.168.50.6/joker',
# 这里也是
host: '192.168.50.6',
```


## 启动 Node 测试环境

启动 container `node:6.9.5`（`node:boron`），同时映射3000端口到本地，命名为joker，映射本地文件夹`~/Development/joker/`到 Docker 中的 `/dev/joker`。并进入此 container。*如果不存在 node 的 image ，会自动下载*
```
$ docker run -it -p 3000:3000 --name joker -v ~/Development/joker/:/dev/joker node:boron bash
```


在 container 内中执行
```
root@[Docker ID]:/# cd /dev/joker
root@[Docker ID]:/# npm install
root@[Docker ID]:/# node app.js 
```

OK! 
现在可以直接在本地访问 `localhost:3000`

## 生产环境部署

```
$ vi app.js
# app.js
(-) port 3000
(+) port 80
#

$ docker run -it -p 80:80 --name joker -v ~/Development/joker/:/dev/joker node:boron bash

root@[Docker ID]:/# cd /dev/joker
root@[Docker ID]:/# npm install
root@[Docker ID]:/# npm install -g pm2
root@[Docker ID]:/# pm2 start app.js -i 0 --name "joker"
```

输入 `Ctrl+p` + `Ctrl+q` detach docker

## 参考: Correct way to detach from a container without stopping it

Q: After attach to a container, exit and CTR+C both stop the container. Why?

A: because your main process is a bash. And command exit will kill the main process and exit.


To detach the tty without exiting the shell, use the escape sequence `Ctrl+p` + `Ctrl+q`

[Ref](https://docs.docker.com/engine/reference/commandline/attach/
)


---
# 备用命令
1.  build the dockerfile to image: `docker build -t `mongodb .`(the latest `.` can **NOT** be ignored)

2. show logs: `docker logs mdb1`

3. 进入正在运行的 container: `docker attach [container name]` ，或`docker exec -it [container name] bash`

4. 访问宿主机服务: `curl http://10.0.0.2:3000`。不要 `localhost:3000`。例如 container1 的 mongodb 服务映射到宿主的 `localhost:27071`，可以通过在本地访问`localhost:27071`，但是在另一个 container2 里面，需要访问`10.0.0.2:27071`(对于 contianer2 ，localhost 是容器a自己)

5. `docker start [container]` :可以开启已存在的container，但是没办法再附加选项，比如 `-v`(volume), `-p` (port)

6. 解决办法是 `docker stop [container 1]` 停止，`docker commit [base on a container] [a new image]`基于这个container提交产生一个新的image，`docker run -p 3000:3000 -td [the new image]`  重新开启一个新的container，这时就可以把原来的关掉了

