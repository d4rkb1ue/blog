---
title: nswbmw/N-blog 学习-3-设计路由, MongoDB 的链接, 会话 Session, Cookie, Connect-flash, Supervisor, 界面实现
date: 2016-03-30 02:35:51
tags: [Nblog, Node.js]
---

# 路由

>###博客的功能分析
>搭建一个简单的具有多人注册、登录、发表文章、登出功能的博客。

>###设计目标
>未登录：主页左侧导航显示 home、login、register，右侧显示已发表的文章、发表日期及作者。
>
>登陆后：主页左侧导航显示 home、post、logout，右侧显示已发表的文章、发表日期及作者。
>用户登录、注册、发表成功以及登出后都返回到主页。

>###路由规划
>已经把设计的构想图贴出来了，接下来的任务就是完成路由规划了。

> / ：首页
> 
> /login ：用户登录
> 
> /reg ：用户注册
> 
> /post ：发表文章
> 
> /logout ：登出

>我们要求 /login 和 /reg 只能是未登录的用户访问，而 /post 和 /logout 只能是已登录的用户访问。左侧导航列表则针对已登录和未登录的用户显示不同的内容。

## 创建路由JS

### index.js（和原教程不一样哟）
```js
var express = require('express');
var router = express.Router();
    
/* GET home page. */
router.get('/', function (req, res) {
        res.render('index', { title: '主页' });
        });
router.get('/reg', function (req, res) {
        res.render('reg', { title: '注册' });
        });
router.post('/reg', function (req, res) {
        });
router.get('/login', function (req, res) {
        res.render('login', { title: '登录' });
        });
router.post('/login', function (req, res) {
        });
router.get('/post', function (req, res) {
        res.render('post', { title: '发表' });
        });
router.post('/post', function (req, res) {
        });
router.get('/logout', function (req, res) {
        });

module.exports = router;
```

*tips:使用`gg=G`命令在vim里自动缩进，爽爆！还有`:%s/app/router/c`进行全局字符串"app"到"router"的替换。*

# 数据库：MongoDB

## Install MongoDB on Ubuntu

### 1. Import the public key used by the package management system

>The Ubuntu package management tools (i.e. dpkg and apt) ensure package consistency and authenticity by requiring that distributors sign packages with GPG keys. Issue the following command to import the MongoDB public GPG Key.

    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927

### 2. Create a list file for MongoDB
>Create the /etc/apt/sources.list.d/mongodb-org-3.2.list list file using the command  @Ubuntu 14.04

    echo "deb http://repo.mongodb.org/apt/ubuntu trusty/mongodb-org/3.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.2.list

作用：把"..."字符串附加到后面这个文件的尾巴上。

### 3. Reload local package database

    sudo apt-get update

### 4. Install the MongoDB packages

    sudo apt-get install -y mongodb-org

### 5. Start MongoDB

    sudo service mongod start

### 6. Verify that MongoDB has started successfully

Checking the contents of the log file at /var/log/mongodb/mongod.log for a line reading `[initandlisten] waiting for connections on port <port>`

*where <port> is the port configured in /etc/mongod.conf, 27017 by default.*

### 7. Stop MongoDB

    sudo service mongod stop

### 配置信息&文件存放

- 配置信息存放在 /etc/mongod.conf，the init script /etc/init.d/mongod. 但是并没有自动生成init文件。:?

- store its data files in the /var/lib/mongodb and its log files in /var/log/mongodb, and run using the mongodb user account.


>These packages configure MongoDB using the /etc/mongodb.conf file in conjunction with the control script. You will find the control script is at /etc/init.d/mongodb.


## [快速入门 @mongoing.com](http://docs.mongoing.com/manual/tutorial/getting-started.html)

## 食用MongoDB

### 指定文件目录
默认数据库存放在 /var/lib/mongodb 中。首先`sudo service mongod stop`关闭monodb，再执行

    mongod --dbpath ~/db-blog/

设置 blog 文件夹作为工程的存储目录并启动数据库。

输出`[initandlisten] MongoDB starting : pid=6846 port=27017 dbpath=db-blog 64-bit host=ubuntu`证明正常运行。

*tips. 如果不先关闭db再启动，会启动不了*

*tips2. 这样启动起来之后，这个shell就被前台了，使用`Ctrl+C`终止service*

### node.js链接db

#### 安装包

并保存依赖：

    npm install mongodb --save

*version:mongodb@2.1.13*

#### settings.js
创建 settings.js 文件，用于保存该博客工程的配置信息.

```js
module.exports = { 
  cookieSecret: 'myblog', 
  db: 'blog', 
  host: 'localhost',
  port: 27017
}; 
```

其中 db 是数据库的名称，host 是数据库的地址，port是数据库的端口号，cookieSecret 用于 Cookie 加密与数据库无关.

#### models/db.js
创建models/db.js

```js
var settings = require('../settings'),
        Db = require('mongodb').Db,
        Connection = require('mongodb').Connection,
        Server = require('mongodb').Server;
    module.exports = new Db(settings.db, new Server(settings.host, settings.port),
 {safe: true});
```

`new Db(settings.db, new Server(settings.host, settings.port), {safe: true}); `设置数据库名、数据库地址和数据库端口创建了一个数据库连接实例，并通过 module.exports 导出该实例。这样，我们就可以通过 require 这个文件来对数据库进行读写了。

#### 添加到app.js

app.js加入：

    var settings = require('./settings');


# 会话支持

>- 会话是一种持久的网络协议，用于完成服务器和客户端之间的一些交互行为。会话是一个比连接粒度更大的概念， 一次会话可能包含多次连接，每次连接都被认为是会话的一次操作。

>- 为了在无状态的 HTTP 协议之上实现会话，Cookie 诞生了。Cookie 是一些存储在客户端的信息，每次连接的时候由浏览器向服务器递交，服务器也向浏览器发起存储 Cookie 的请求，依靠这样的手段服务器可以识别客户端。浏览器首次向服务器发起请求时，服务器生成一个唯一标识符并发送给客户端浏览器，浏览器将这个唯一标识符存储在 Cookie 中，以后每次再发起请求，客户端浏览器都会向服务器传送这个唯一标识符，服务器通过这个唯一标识符来识别用户。 

## 安装组件
    npm install express-session connect-mongo --save

## 添加到app.js

```js
var session = require('express-session');
var MongoStore = require('connect-mongo')(session);

app.use(session({
  secret: settings.cookieSecret,
  key: settings.db,//cookie name
  cookie: {maxAge: 1000 * 60 * 60 * 24 * 30},//30 days
  store: new MongoStore({
  url: 'mongodb://localhost/blog'
})
}));
```

将会话信息存储到mongoldb中。secret 用来防止篡改 cookie，key 的值为 cookie 的名字，通过设置 cookie 的 maxAge 值设定 cookie 的生存期，这里我们设置 cookie 的生存期为 30 天，设置它的 store 参数为 MongoStore 实例，把会话信息存储到数据库中，以避免丢失。


# 页面实现

## views/index.ejs

```
<%- include header %>
这是主页
<%- include footer %>
```

## views/header.ejs

```html
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8" />
<title><%= title %></title>
<link rel="stylesheet" href="/stylesheets/style.css">
</head>
<body>

<header>
<h1><%= title %></h1>
</header>

<nav>
<span><a title="主页" href="/">home</a></span> 
<span><a title="登录" href="/login">login</a></span>
<span><a title="注册" href="/reg">register</a></span>
</nav>

<article>
```

TODO: `<a title="主页"`  title 是干啥用的。。？

## views/footer.ejs

```html
</article>
</body>
</html>
```


## public/stylesheets/style.css

```css
*{padding:0;margin:0;}


body {
    width:600px;
    margin:2em auto;
    padding:0 2em;

  font: 14px "Lucida Grande", Helvetica, Arial, sans-serif;
}

p {
    line-height:24px;
    margin:1em 0;
}

header{
    padding:.5em 0;
    border-bottom:1px solid #cccccc;
}

nav{
    float:left;
    font-size:1.1em;
    text-transform:uppercase;
    margin-left:-12em;
    width:9em;
    text-align:right;
}
nav a{
    display:block;
    text-decoration:none;
    padding:.7em 1em;
    color:#000000;
}
nav a:hover{
    background-color:#ff0000;
    color:#f9f9f9;
    -webkit-transition:color .2s linear;
}

article{
    font-size:16px;
    padding-top:.5em;
}

article a{
    color:#dd0000;
    text-decoration:none;
}
article a:hover{
    color:#333333;
    text-decoration:underline;
}
.info{font-size:14px;}

a {
  color: #00B7FF;
}
```

## views/login.ejs

```html
<%- include header %>
<form method="post">
    user name: <input type="text" name="name" /><br />
    password:  <input type="password" name="password" /><br />
           <input type="submit" value="login!"/>
</form>
<%- include footer %>
```


## views/reg.ejs
```html
<%- include header %>
<form method="post">
    user name: <input type="text" name="name" /><br />
    password: <input type="password" name="password" /><br />
    confirm pw:<input type="password" name="password-repeat"/> <br />
    email: <input type="email" name="email" /><br />
        <input type="submit" value="register!"/>
</form>
<%- include footer %>
```

*修改views文件，生效无需重启*

# Supervisor

    npm install -g supervisor

代码变更的时候，无需手动停止并重启应用，使用 supervisor 模块可以解决这个问题。
每当我们保存修改的文件时，supervisor 都会自动帮我们重启应用。使用 supervisor 命令启动 app.js：

    supervisor app.js

~~无需`supervisior bin/www`~~

**此处有大坑！因为以app.js作为起点就没人给他传port3000之类的参数了。所以网站之后是打不开的！**

# Connect-flash

flash 是一个在 session 中用于存储信息的特定区域。信息写入 flash ，下一次显示完毕后即被清除。典型的应用是结合重定向的功能，确保信息是提供给下一个被渲染的页面。

## 安装

    npm install connect-flash --save

添加到 app.js

    var flash = require('connect-flash');

在 `app.set('view engine', 'ejs');` 后添加：

    app.use(flash());

---
@d4rkb1ue 2016.4.1 07:00
