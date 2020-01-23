---
title: Docker Quick Start
date: 2017-02-02 23:51:36
tags: [Docker, Node.js]
---

# Hello World

Follow [Install Docker and run hello-world - Docker](https://docs.docker.com/engine/getstarted/step_one/)

1. Install Docker on macOS
2. run `docker run hello-world` to test



# Basic Components

- image: read-only ISO
- container: instance to load a image and run it; can be create, start, stop, delete; separate from each others; has its own ‘root’ 
- repository: a docker hub like github

# Basic Commands

```
docker image ls
```
or `docker images`
show all the images

```
docker pull ubuntu:16.04
```
‘git clone’ a docker images `ubuntu` with TAG: `16.04`; from a specific repository server: `sudo docker pull dl.dockerpool.com:5000/ubuntu:12.04` 

```
docker run -it ubuntu:16.04 /bin/bash
```
= `docker run -it ubuntu:16.04 bash`: start this image to a container and `ssh` into it by start its ‘bash’; `-i`: --interactive, Keep STDIN open even if not attached; `-t`: --tty, Allocate a pseudo-TTY (more help can be `cat` by `docker run —help`); `exit` to exit; 

- 错误！ ~~`run` 之后并不能在 `docker container ls` 中看到，好像在运行后直接删除了~~ 并没有！当Docker容器中指定的应用终结时，容器也自动终止，而 `docker container ls` 只会显示正在运行的；使用 `docker container ls -a` 显示全部；使用 `docker run —rm [image:tag]` 来在运行后自动删除本container

- 错误！~~对 container 的修改在 `exit` 之后被遗弃~~ 并没有！如果执行 `run …` 每次会基于image新建一个container，新container自然不包括在老的container中作出的修改；即使在 `docker stop [a container]` 之后，使用 `docker diff [a container]` 依然可见对这个container做出的修改（当然，不使用 Dockerfile 定制的container是黑箱container，不应发布）

```
docker tag ubuntu:16.04 ubuntu:latest
```
为 ubuntu:16.04 添加一个tag。`latest` 是默认 tag，在不指定tag的时候会认为指的是 latest。因此之后可以直接运行 `docker run ubuntu`

```
docker run --name webserver -d -p 80:80 nginx
```
上述ubuntu的image都干干净净没有daemon进程，因此开启就即刻被关闭。运行一个ngnix来看一个持续运行的container。并且将其命名为 webserver。

```
docker container ls
```
=`docker ps`。查看当前运行的containers。

```
docker ps -a
```
将列出全部containers，包括停止的。

```
docker exec -it webserver bash
```
diff: `exec`进入一个正在运行的container; `run` 开启一个新container。
`top` 一下，可以看到正在运行的nginx。

```
docker diff webserver
```
对container作出改动后，可以查看这个container发生了什么变化。
 
```
docker rm 87dd 02e2 416 e09
```
批量删除container ID以 87dd，416 开头（多少位都可以，只要能区分就行）的这些container. `docker rmi` 用来删除image。


---
# Reference
- [Docker —— 从入门到实践](https://yeasy.gitbooks.io/docker_practice/content/introduction/) 
- [Install Docker and run hello-world](https://docs.docker.com/engine/getstarted/step_one/)
- [Docker Getting Start: Related Knowledge](http://tiewei.github.io/cloud/Docker-Getting-Start/)

## Docker 原理篇
* [DOCKER基础技术：LINUX NAMESPACE（上）CoolShell](http://coolshell.cn/articles/17010.html)
* [Docker基础技术：Linux Namespace（下）CoolShell](http://coolshell.cn/articles/17029.html)
* [DOCKER基础技术：AUFS CoolShell](http://coolshell.cn/articles/17061.html)
* [DOCKER基础技术：DEVICEMAPPER CoolShell](http://coolshell.cn/articles/17200.html)
* [DOCKER基础技术：LINUX CGROUP CoolShell](http://coolshell.cn/articles/17049.html)