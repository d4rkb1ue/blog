---
title: nswbmw/N-blog 学习-4-routes 的重构, 响应 HTTP 请求, sesson 和 flash 的研究, 界面匹配显示
date: 2016-04-01 02:41:16
tags: [Nblog, Node.js]
---


# 重构
被`supervisor app.js`坑惨了！这样程序入口就变成了 app.js ，于是没有 bin/www 给它传 `port:3000`这样的参数。于是拒绝访问。因为3000端口压根没开嘛。
找了半天问题，fuckyousonofbitch!
还是老老实实的按照教程的办法重置了 app.js 和 route/index.js 

## 坑们
1. `node app.js`是不会自动重启的哟！
2. 不要开着全局Shadowsocks访问node:3000!



# 注册响应

## models/user.js
`vi models/user.js`:

```js
var mongodb = require('./db');

function User(user) {
  this.name = user.name;
  this.password = user.password;
  this.email = user.email;
};

module.exports = User;

//存储用户信息
//@d4rkb1ue 使用User.prototype.save定义函数，那么在产生user实例的时候，就会存在user.save这个函数！
User.prototype.save = function(callback) {
  //要存入数据库的用户文档
  var user = {
      name: this.name,
      password: this.password,
      email: this.email
  };
  //打开数据库
  //@d4rkb1ue mongodb.open(callback) 这个函数是mongo提供的函数，我猜大约是在执行完毕数据库开启之后执行传入的回调函数，也就是下面这个匿名函数，如果出现错误，就直接callback(err),没有错误的话，就callback(null,db)这样。于是下面这个代码就能发现是否出错了。db应该是数据库连接实例吧。
  mongodb.open(function (err, db) {
    if (err) {
      return callback(err);//错误，返回 err 信息
    }
    //读取 users 集合
    // db.collection 依然是mongodb提供的，也是类似的结构
    db.collection('users', function (err, collection) {
      if (err) {
        mongodb.close();
        return callback(err);//错误，返回 err 信息
      }
      //将用户数据插入 users 集合
      collection.insert(user, {
        safe: true
      }, function (err, user) {
        mongodb.close();
        if (err) {
          return callback(err);//错误，返回 err 信息
        }
        // callback 是调用 user.save时传入的函数，应该也模仿mongodb这样的调用结构
        callback(null, user[0]);//成功！err 为 null，并返回存储后的用户文档
      });
    });
  });
};

//读取用户信息
User.get = function(name, callback) {
  //打开数据库
  mongodb.open(function (err, db) {
    if (err) {
      return callback(err);//错误，返回 err 信息
    }
    //读取 users 集合
    db.collection('users', function (err, collection) {
      if (err) {
        mongodb.close();
        return callback(err);//错误，返回 err 信息
      }
      //查找用户名（name键）值为 name 一个文档
      collection.findOne({
        name: name
      }, function (err, user) {
        mongodb.close();
        if (err) {
          return callback(err);//失败！返回 err 信息
        }
        callback(null, user);//成功！返回查询的用户信息
      });
    });
  });
};
```

## routes/index.js
在最前面添加如下代码：

```js
var crypto = require('crypto'),
    User = require('../models/user.js');
```

>crypto 是 Node.js 的一个核心模块，我们用它生成散列值来加密密码。

`app.post('/reg')`改动为：

```js
app.post('/reg', function (req, res) {
  var name = req.body.name,
      password = req.body.password,
      password_re = req.body['password-repeat'];
  //检验用户两次输入的密码是否一致
  if (password_re != password) {
    req.flash('error', '两次输入的密码不一致!'); 
    return res.redirect('/reg');//返回注册页
  }
  //生成密码的 md5 值
  var md5 = crypto.createHash('md5'),
      password = md5.update(req.body.password).digest('hex');
  var newUser = new User({
      name: name,
      password: password,
      email: req.body.email
  });
  //检查用户名是否已经存在 
  User.get(newUser.name, function (err, user) {
    if (err) {
      req.flash('error', err);
      return res.redirect('/');
    }
    if (user) {
      req.flash('error', '用户已存在!');
      return res.redirect('/reg');//返回注册页
    }
    //如果不存在则新增用户
    newUser.save(function (err, user) {
      if (err) {
        req.flash('error', err);
        return res.redirect('/reg');//注册失败返回主册页
      }
      req.session.user = newUser;//用户信息存入 session
      req.flash('success', '注册成功!');
      res.redirect('/');//注册成功后返回主页
    });
  });
});
```

- `req.body`中的信息来自 reg.ejs:

```html
<form method="post">
        user name: <input type="text" name="name" /><br />
        password: <input type="password" name="password" /><br />
        confirm pw:<input type="password" name="password-repeat"/> <br />
        email: <input type="email" name="email" /><br />
                <input type="submit" value="register!"/>
</form>
```

- `res.redirect` :重定向

## 测试注册

1. 注册完毕会跳转回 /

2. 前往mongodb查看数据是否存在：

        ray0@ubuntu:~/blog/routes$ mongo
        MongoDB shell version: 3.2.4
        connecting to: test
        > use blog
        switched to db blog
        > db.users.find()
        { "_id" : ObjectId("56fc2394a20a60f4631a7d32"), "name" : "a", "password" : "0cc175b9c0f1b6a831c399e269772661", "email" : "a@a" }

3. 顺便看下 session 的在数据库里储存的结构：

        > show collections
        sessions
        users
        > db.sessions.find()
        { "_id" : "TKcqS6XfuhObSk2vFY1UuNI_ehtpn8MM", "session" : "{\"cookie\":{\"originalMaxAge\":2591999998,\"expires\":\"2016-04-29T19:26:00.311Z\",\"httpOnly\":true,\"path\":\"/\"},\"flash\":{},\"user\":{\"name\":\"a\",\"password\":\"0cc175b9c0f1b6a831c399e269772661\",\"email\":\"a@a\"}}", "expires" : ISODate("2016-04-29T19:26:00.311Z") }

### flash里面空空如也?

令我好奇的是，flash里面空空如也！
我怀疑是不是flash在一次刷新之后就消失了，重新执行一次注册试下。
的确可以正确显示在网页中，但是数据库里面始终没有。的确刷新页面之后，这个flash就空了。

更改下 index.js 让注册完毕之后不自动跳转到 '/':

```
...

res.send('OK');
//res.redirect('/');//注册成功后返回主页

...
```

再看下session：
```
{ "_id" : "Q1wK_BigddTo9H1U-LdugZT8o5bl7sRX", "session" : "{\"cookie\":{\"originalMaxAge\":2592000000,\"expires\":\"2016-04-29T20:19:51.588Z\",\"httpOnly\":true,\"path\":\"/\"},\"flash\":{\"success\":[\"注册成功!\"]},\"user\":{\"name\":\"33333\",\"password\":\"182be0c5cdcd5072bb1864cdee4d3d6e\",\"email\":\"33@33\"}}", "expires" : ISODate("2016-04-29T20:19:51.588Z") }
```

Yeah!!!的确出现了。再刷新到主页，主页显示“注册成功！”，再看下session：
```
"flash\":{}
```



## 注册状态显示

>实现当注册成功返回主页时，左侧导航显示 HOME 、POST 、LOGOUT ，右侧显示 注册成功！ 字样，即添加 flash 的页面通知功能。

### view/header.ejs

```html
...

<nav>
<span><a title="主页" href="/">home</a></span>
<% if (user) { %>
  <span><a title="发表" href="/post">post</a></span>
  <span><a title="登出" href="/logout">logout</a></span>
<% } else { %>
  <span><a title="登录" href="/login">login</a></span>
  <span><a title="注册" href="/reg">register</a></span>
<% } %>
</nav>

...
```

**注意！此时因为header.ejs是所有页面的模版，其他ejs都引用了这个ejs，因此需要对所有`GET`请求都附加上 `user` 的属性！下面的`success`/`error`也是同理**

教程中还要求了：

>在 <article> 后添加如下代码：

> <% if (success) { %>
>   <div><%= success %></div>
> <% } %>
> <% if (error) { %>
>   <div><%= error %> </div>
> <% } %>
> 

再试试做成弹窗呢：

```html
...

<% if (success || error){ %>
<script>
alert( " <%= success || error %>" );
//错误示范：alert( <%= success || error %>);
</script>
<% } %>

...
```

## routes/index.js

现在ejs需要的属性变多了，需要告诉index.js这些属性的来源：

```js
app.get('/', function (req, res) {
  res.render('index', {
    title: '主页',
    user: req.session.user,
    success: req.flash('success').toString(),
    error: req.flash('error').toString()
  });
});
```

由于 reg.ejs 里也同样调用了 header.ejs （包含对`user`的判定），因此事实上也需要对 `/reg` 进行传参：

```js
app.get('/reg', function (req, res) {
  res.render('reg', {
    title: '注册',
    user: req.session.user,
    success: req.flash('success').toString(),
    error: req.flash('error').toString()
  });
});
```

>`success: req.flash('success').toString()` 的意思是将成功的信息赋值给变量 `success`。

## 像 sesson, flash 这样的信息在Server端存储（可在db中找到），为什么要写成 `req.flash('success')` ?

之前在会话支持里，老师指出：
>服务器生成一个唯一标识符并发送给客户端浏览器，浏览器将这个唯一标识符存储在 Cookie 中，以后每次再发起请求，客户端浏览器都会向服务器传送这个唯一标识符，服务器通过这个唯一标识符来识别用户。

呢么应该是server根据requset传进来的标识符，去db里找相应的session，再把数据写入到这个session里。于是有了 `req.flash` .也就是这个flash 唯一和这个 **requset的发起方** 相关联。



