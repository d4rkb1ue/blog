---
title: nswbmw/N-blog 学习-8-文件上传 Multer, 静态文件访问权限, 感触和总结
date: 2016-04-07 00:13:40
tags: [Nblog, Node.js]
---
做起文件上传，就突然想起来访问权限问题。之前在apache服务器里，/var/www里面的文件是通过linux的权限管理来决定是否可以访问。那么express是怎么样的呢？

# 现在的访问权限

好像通过`app.use(express.static(path.join(__dirname, 'public')));`定义之后，直接访问 `/some-url` 就是在访问 `public/`文件夹下的文件。

# 使用Multer

## 安装：
```
$ npm install --save multer
```



## header.ejs
在 `<span><a title="发表" href="/post">post</a></span>` 前添加一行代码：
```
<span><a title="上传" href="/upload">upload</a></span>
```

## index.js
在 app.get('/logout') 函数后添加如下代码：
```js
app.get('/upload', checkLogin);
app.get('/upload', function (req, res) {
  res.render('upload', {
    title: '文件上传',
    user: req.session.user,
    success: req.flash('success').toString(),
    error: req.flash('error').toString()
});
});
```

## views/upload.ejs

```
<%- include header %>
<form method='post' action='/upload' enctype='multipart/form-data' >
  <input type="file" name='file'/><br>
  <input type="file" name='file'/><br>
  <input type="file" name='file'/><br>
  <input type="file" name='file'/><br>
  <input type="file" name='file'/><br>
  <input type="submit" />
</form>
<%- include footer %>
```

现在我们就可以访问文件上传页面了。
有一点和教程不同，我这5个name都是相同的，这样以备后面的设定。

## routes/index.js

教程里把multer的设定放在了app.js。不过他使用的版本比较老旧，对于新版本的multer，那个代码已经失效了。我把所有的逻辑都转移到了routes里。
```js
var multer = require('multer');

var storage = multer.diskStorage({
  destination: function (req, file, cb) {
      cb(null, './public/uploads')
  },
  filename: function (req, file, cb) {
      cb(null, file.originalname)
  }
})

var upload = multer({ storage: storage });

...

app.get('/upload',checkLogin);
app.get('/upload',function(req,res){
    res.render('upload',
    {title: '文件上传',
    user: req.session.user,
    success: req.flash('success').toString(),
    error: req.flash('error').toString()
});
});


app.post('/upload', checkLogin);
app.post('/upload',upload.fields([{name:'file',maxCound:5}]), function (req, res) {
    req.flash('success', '文件上传成功!');
    res.redirect('/upload');
});

```


`upload.fields([{name:'file',maxCound:5}])`:  req.files 里面的所有filedname都叫`file`，直接统一解决。
`file.originalname`: 保存的名字就是原来的文件名字。这个选项是必选的，否则上传的文件名都是随机乱码。

[Muler API](https://github.com/expressjs/multer)

---
# 感触

使用express.node.js的一个爽快之处就是整个框架的结构非常简洁，我可以从http请求处理到程序逻辑，几乎没有黑盒。
都很平面化，而且全部的插件都是通过 中间件 的形式出现。调用的逻辑也很统一: `app.use`

一切都尽在掌控的感觉。不用什么都去google一下，什么都在代码里。

太喜欢这种一切都按照逻辑来的感觉。
和人交往就不同，仿佛每个人都是一个随机数发生器。
想到一个梗，`#define true (rand()>10)` 差不多是这样。


