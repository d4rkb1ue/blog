---
title: nswbmw/N-blog 学习-6-页面权限控制, 中间件, next() 和 routes 的研究, 发表文章 和 首页 的实现, prototype 的方法, 数据库异常
date: 2016-04-03 23:51:48
tags: [Nblog, Node.js]
---

# 页面权限控制

## 状态检查中间件
```js
function checkLogin(req, res, next) {
  if (!req.session.user) {
    req.flash('error', '未登录!'); 
    res.redirect('/login');
  }
  next();
}

function checkNotLogin(req, res, next) {
  if (req.session.user) {
    req.flash('error', '已登录!'); 
    res.redirect('back');//返回之前的页面
  }
  next();
}
```

通过 `next()` 转移控制权.


>next() with no arguments says "just kidding, I don't actual want to handle this". It goes back in and tries to find the next route that would match.

正常情况下routes是按照顺序依次找匹配的，找到一个匹配的就进去。如果有`send()`就返回，没有就什么都不返回；加入`next()`之后，在这个`app.VERB`里如果运行到`next()`那么就会返回到routes继续向下查找。

`res.redirect('back');` //返回之前的页面
这个'back'不错。很方便。

## 修改后的 index.js
```js
var crypto = require('crypto'),
    User = require('../models/user.js');

module.exports = function(app) {
  app.get('/', function (req, res) {
    res.render('index', {
      title: '主页',
      user: req.session.user,
      success: req.flash('success').toString(),
      error: req.flash('error').toString()
    });
  });

  app.get('/reg', checkNotLogin);
  app.get('/reg', function (req, res) {
    res.render('reg', {
      title: '注册',
      user: req.session.user,
      success: req.flash('success').toString(),
      error: req.flash('error').toString()
    });
  });

  app.post('/reg', checkNotLogin);
  app.post('/reg', function (req, res) {
    var name = req.body.name,
        password = req.body.password,
        password_re = req.body['password-repeat'];
    if (password_re != password) {
      req.flash('error', '两次输入的密码不一致!'); 
      return res.redirect('/reg');
    }
    var md5 = crypto.createHash('md5'),
        password = md5.update(req.body.password).digest('hex');
    var newUser = new User({
        name: name,
        password: password,
        email: req.body.email
    });
    User.get(newUser.name, function (err, user) {
      if (err) {
        req.flash('error', err);
        return res.redirect('/');
      }
      if (user) {
        req.flash('error', '用户已存在!');
        return res.redirect('/reg');
      }
      newUser.save(function (err, user) {
        if (err) {
          req.flash('error', err);
          return res.redirect('/reg');
        }
        req.session.user = user;
        req.flash('success', '注册成功!');
        res.redirect('/');
      });
    });
  });

  app.get('/login', checkNotLogin);
  app.get('/login', function (req, res) {
    res.render('login', {
      title: '登录',
      user: req.session.user,
      success: req.flash('success').toString(),
      error: req.flash('error').toString()
    }); 
  });

  app.post('/login', checkNotLogin);
  app.post('/login', function (req, res) {
    var md5 = crypto.createHash('md5'),
        password = md5.update(req.body.password).digest('hex');
    User.get(req.body.name, function (err, user) {
      if (!user) {
        req.flash('error', '用户不存在!'); 
        return res.redirect('/login');
      }
      if (user.password != password) {
        req.flash('error', '密码错误!'); 
        return res.redirect('/login');
      }
      req.session.user = user;
      req.flash('success', '登陆成功!');
      res.redirect('/');
    });
  });

  app.get('/post', checkLogin);
  app.get('/post', function (req, res) {
    res.render('post', {
      title: '发表',
      user: req.session.user,
      success: req.flash('success').toString(),
      error: req.flash('error').toString()
    });
  });

  app.post('/post', checkLogin);
  app.post('/post', function (req, res) {
  });

  app.get('/logout', checkLogin);
  app.get('/logout', function (req, res) {
    req.session.user = null;
    req.flash('success', '登出成功!');
    res.redirect('/');
  });

  function checkLogin(req, res, next) {
    if (!req.session.user) {
      req.flash('error', '未登录!'); 
      res.redirect('/login');
    }
    next();
  }

  function checkNotLogin(req, res, next) {
    if (req.session.user) {
      req.flash('error', '已登录!'); 
      res.redirect('back');
    }
    next();
  }
};
```

2个get/post的处理函数的逻辑：
```js
app.get('/logout', checkLogin);
app.get('/logout', function (req, res) {
    req.session.user = null;
    req.flash('success', '登出成功!');
    res.redirect('/');
});
```

首先，routes先放问到第一个函数。第一个如果调用了render()/send()之类，就没第二个什么事了。
如果第一个调用了next(),那么就会返回routes继续检查下一个匹配，也就是第二个函数。

另外，把这些逻辑摊开，不如直接在最开头拦截所有 `app.all("/*",check)` 统一处理。

# 发表文章
## views/post.ejs
```html
<%- include header %>
<form method="post">
  标题：<br />
  <input type="text" name="title" /><br />
  正文：<br />
  <textarea name="post" rows="20" cols="100"></textarea><br />
  <input type="submit" value="发表" />
</form>
<%- include footer %>
```

## models/post.js
```js
var mongodb = require('./db');

function Post(name, title, post) {
  this.name = name;
  this.title = title;
  this.post = post;
}

module.exports = Post;

//存储一篇文章及其相关信息
Post.prototype.save = function(callback) {
  var date = new Date();
  //存储各种时间格式，方便以后扩展
  var time = {
      date: date,
      year : date.getFullYear(),
      month : date.getFullYear() + "-" + (date.getMonth() + 1),
      day : date.getFullYear() + "-" + (date.getMonth() + 1) + "-" + date.getDate(),
      minute : date.getFullYear() + "-" + (date.getMonth() + 1) + "-" + date.getDate() + " " + 
      date.getHours() + ":" + (date.getMinutes() < 10 ? '0' + date.getMinutes() : date.getMinutes()) 
  }
  //要存入数据库的文档
  var post = {
      name: this.name,
      time: time,
      title: this.title,
      post: this.post
  };
  //打开数据库
  mongodb.open(function (err, db) {
    if (err) {
      return callback(err);
    }
    //读取 posts 集合
    db.collection('posts', function (err, collection) {
      if (err) {
        mongodb.close();
        return callback(err);
      }
      //将文档插入 posts 集合
      collection.insert(post, {
        safe: true
      }, function (err) {
        mongodb.close();
        if (err) {
          return callback(err);//失败！返回 err
        }
        callback(null);//返回 err 为 null
      });
    });
  });
};

//读取文章及其相关信息
Post.get = function(name, callback) {
  //打开数据库
  mongodb.open(function (err, db) {
    if (err) {
      return callback(err);
    }
    //读取 posts 集合
    db.collection('posts', function(err, collection) {
      if (err) {
        mongodb.close();
        return callback(err);
      }
      var query = {};
      if (name) {
        query.name = name;
      }
      //根据 query 对象查询文章
      collection.find(query).sort({
        time: -1
      }).toArray(function (err, docs) {
        mongodb.close();
        if (err) {
          return callback(err);//失败！返回 err
        }
        callback(null, docs);//成功！以数组形式返回查询的结果
      });
    });
  });
};
```

不是很能理解 `var time = {..}` 里面对于每个元素的写法。我觉得这个处理放在表现层比较妥当。

### `Post.prototype.save` & `Post.get`

由于在获取Post的时候，调用如下：
```
app.get('/', function (req, res) {
    Post.get(null,function(err,posts){
    ...
}
```

所调用的是原型本身。

而保存的时候：
```
 app.post('/post', function (req, res) {
    var currentUser = req.session.user,
            post = new Post(currentUser.name, req.body.title, req.body.post);
            post.save(function (err){

    ...
```

可以看到，保存时候调用的是子类方法。因此，需要注意 `Post.prototype.save` & `Post.get`

## 发表响应
### index.js

```js
var Post = require('../models/post.js');

...

app.post('/post', checkLogin);
app.post('/post', function (req, res) {
  var currentUser = req.session.user,
      post = new Post(currentUser.name, req.body.title, req.body.post);
  post.save(function (err) {
    if (err) {
      req.flash('error', err); 
      return res.redirect('/');
    }
    req.flash('success', '发布成功!');
    res.redirect('/');//发表成功跳转到主页
  });
});

```

## 首页显示
### views/index.ejs 
```html
<%- include header %>
<% posts.forEach(function (post, index) { %>
  <p><h2><a href="#"><%= post.title %></a></h2></p>
  <p class="info">
    作者：<a href="#"><%= post.name %></a> | 
    日期：<%= post.time.minute %>
  </p>
  <p><%- post.post %></p>
<% }) %>
<%- include footer %>
```

因此需要传入新的参数，`posts`：
### index.js

```js
app.get('/', function (req, res) {
  Post.get(null, function (err, posts) {
    if (err) {
      posts = [];
    } 
    res.render('index', {
      title: '主页',
      user: req.session.user,
      posts: posts,
      success: req.flash('success').toString(),
      error: req.flash('error').toString()
    });
  });
});
```

## 数据库信息
```
{ "_id" : ObjectId("56fe117f7733c2187a66d4f4"), "name" : "tamper", "time" : { "date" : ISODate("2016-04-01T06:13:19.013Z"), "year" : 2016, "month" : 4, "day" : 1, "hour" : 14, "minute" : 13 }, "title" : "hello world", "post" : "how!!" }
```

奇怪的是，无论cookie 还是 post的时间都很错乱。重启才正常。

*`date`命令可以在ubuntu里面查看时间。*

### 数据丢失
神奇的是，我直接`poweroff`再重启之后，数据就只剩下一条session，其他都没了！

运行了一下`sudo mongod --dbpath ~/db-blog/ --repair`就好啦！
注意重启数据库，也需要同时重启 app.js
