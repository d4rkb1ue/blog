---
title: nswbmw/N-blog 学习-7-使用 markdown, ejs 模版的 <%- / <%=, 清空数据库的正确姿势
date: 2016-04-04 15:05:46
tags: [Nblog, Node.js]
---

现在我们来给博客添加支持 markdown 发表文章的功能。
# 安装
```
npm install markdown --save
```


先看下未使用markdown时候，数据库保存的格式：

```
{ "_id" : ObjectId("5700ccade40784880eda687e"), "name" : "tamper", "time" : { "date" : ISODate("2016-04-03T07:56:29.017Z"), "year" : 2016, "month" : 4, "day" : 3, "hour" : 15, "minute" : 56 }, "title" : "第2章 使用 Markdown", "post" : "现在我们来给博客添加支持 markdown 发表文章的功能。\r\n假如你不还熟悉 markdown，请转到：http://wowubuntu.com/markdown/\r\n\r\n打开 package.json ，添加一行代码：\r\n\r\n\"markdown\": \"0.5.0\"\r\n使用 npm install 安装 markdown 模块。\r\n\r\n打开 post.js，在 mongodb = require('./db') 后添加一行代码：\r\n\r\nmarkdown = require('markdown').markdown;\r\n在 Post.get 函数里的 callback(null, docs); 前添加以下代码：" }
```

# views/index.ejs
现在突然明白为什么在views/index.ejs中使用 `<p><%- post.post %></p>` 而不是 `<%=` 了。就是为了markdown渲染出来的html代码正常执行。但是话说这样很危险啊。



>Tips about Cookies [http only]: Javascript 中的document.cookie语句不能获取到cookie

//TODO: 网站安全问题。比如对于所有搜索框和url请求的检查。

很讨巧的，其实渲染是发生在导出而不是存储的阶段：

# post.js

```js
var markdown = require('markdown').markdown;
...
db.collection('posts',function(err,collection){
    ...
    docs.forEach(function(doc){
            doc.post = markdown.toHTML(doc.post);
    });

    callback(null,docs);
});
```


# Post本章节
## 数据库显示
```
{ "_id" : ObjectId("5700d247e96e99c70e337605"), "name" : "tamper", "time" : { "date" : ISODate("2016-04-03T08:20:23.754Z"), "year" : 2016, "month" : 4, "day" : 3, "hour" : 16, "minute" : 20 }, "title" : "#第2章 使用 Markdown 2016/4/3", "post" : "#第2章 使用 Markdown 2016/4/3\r\n\r\n现在我们来给博客添加支持 markdown 发表文章的功能。\r\n\r\n```\r\nnpm install markdown --save\r\n```\r\n\r\n先看下未使用markdown时候，数据库保存的格式：\r\n\r\n```\r\n{ \"_id\" : ObjectId(\"5700ccade40784880eda687e\"), \"name\" : \"tamper\", \"time\" : { \"date\" : ISODate(\"2016-04-03T07:56:29.017Z\"), \"year\" : 2016, \"month\" : 4, \"day\" : 3, \"hour\" : 15, \"minute\" : 56 }, \"title\" : \"第2章 使用 Markdown\", \"post\" : \"现在我们来给博客添加支持 markdown 发表文章的功能。\\r\\n假如你不还熟悉 markdown，请转到：http://wowubuntu.com/markdown/\\r\\n\\r\\n打开 package.json ，添加一行代码：\\r\\n\\r\\n\\\"markdown\\\": \\\"0.5.0\\\"\\r\\n使用 npm install 安装 markdown 模块。\\r\\n\\r\\n打开 post.js，在 mongodb = require('./db') 后添加一行代码：\\r\\n\\r\\nmarkdown = require('markdown').markdown;\\r\\n在 Post.get 函数里的 callback(null, docs); 前添加以下代码：\" }\r\n```\r\n\r\n现在突然明白为什么在views/index.ejs中使用 `<p><%- post.post %></p>` 而不是 `<%=` 了。就是为了让html代码正常执行。但是话说这样很危险啊。\r\n\r\n>Tips about Cookies [http only]: Javascript 中的document.cookie语句不能获取到cookie\r\n\r\n//TODO: 网站安全问题。比如对于所有搜索框和url请求的检查。\r\n\r\n\r\n" }
```

值得注意的是，所有`\ " ' `其实都已经被转义了。也就是说不会出现输入框崩溃我的服务器的情况。

# 清空数据库

## 不要直接删除文件！
~~使用 `rm -rf db-blog/*` 清空数据库.~~
这样的话，回报：
```
2016-04-03T16:48:03.284+0800 E STORAGE  [initandlisten] WiredTiger (2) [1459673283:284405][1748:0x7fabf999bd00], file:WiredTiger.wt, connection: /home/ray0/db-blog//WiredTiger.wt: No such file or directory
2016-04-03T16:48:03.288+0800 I -        [initandlisten] Assertion: 28718:2: No such file or directory
2016-04-03T16:48:03.289+0800 I STORAGE  [initandlisten] exception in initAndListen: 28718 2: No such file or directory, terminating
2016-04-03T16:48:03.290+0800 I CONTROL  [initandlisten] dbexit:  rc: 100
```
错误。即使重启服务器，也解决不了。

我估计是和日志文件冲突。就是本来应该有文件的地方没有了，而且这个文件的删除还不经过数据库系统的操作。

## 删除了要怎么办

用`mongod --repair --dbpath /database/db --storageEngine wiredTiger`也是屁用没有。

反正数据也不要了。直接

```
mkdir db-blog2
sudo mongod --dbpath ~/db-blog2
```

做一个新的文件夹当数据库好了。记得先终止之前的服务。
改文件夹之后，db.name 没有改变，是因为定义name是在程序中的。

## 正确的删除姿势
```
mongo db 
>  db.dropDatabase();
```