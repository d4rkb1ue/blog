---
title: nswbmw/N-blog 学习-5-登出 logout, session 和 flash 的再次研究, cookie.id 和 cookieSecret 的研究 
date: 2016-04-02 22:43:57
tags: [Nblog, Node.js]
---



# 登出响应 logout 的实现

## index.js

`app.post('/login')` :

```js
app.post('/login', function (req, res) {
  //生成密码的 md5 值
  var md5 = crypto.createHash('md5'),
      password = md5.update(req.body.password).digest('hex');
  //检查用户是否存在
  User.get(req.body.name, function (err, user) {
    if (!user) {
      req.flash('error', '用户不存在!'); 
      //@d4rkb1ue 在这里return res.() 其实并不是在return response.
      //res.redirect 肯定返回了一个无所谓的值。其实就是
      //res.redirect();return null;
      return res.redirect('/login');//用户不存在则跳转到登录页
    }
    //检查密码是否一致
    if (user.password != password) {
      req.flash('error', '密码错误!'); 
      return res.redirect('/login');//密码错误则跳转到登录页
    }
    //用户名密码都匹配后，将用户信息存入 session
    req.session.user = user;
    req.flash('success', '登陆成功!');
    res.redirect('/');//登陆成功后跳转到主页
  });
});
```



### 对这段代码的研究



```js
req.session.user = user;
req.flash('success','welcome!'+user.name);
res.redirect('/');
```

首先req.session/flash的操作都是本地的。即去修改本地数据库里面session信息。
之后在res.redirect是在给予用户反馈。但是当然的，这次发送其实是告诉用户去 `GET /`而不是直接送给用户`/`的内容（可以在包拦截中看到实际上是给了一个302,临时转址）。然后之后用户`/`的请求，自带了cookie.id，因此服务器返回的是符合这个id的内容，包括去属于这个id的session里拿到flash，给用户。之后删除flash。

`app.get('/login')` :

```js
app.get('/login', function (req, res) {
    res.render('login', {
        title: '登录',
        user: req.session.user,
        success: req.flash('success').toString(),
        error: req.flash('error').toString()});
});
```

不加这段，在不登陆状态访问 `/reg` 就会报错找不到 `user`。

`app.get('/logout')`:

```js
app.get('/logout', function (req, res) {
  req.session.user = null;
  req.flash('success', '登出成功!');
  res.redirect('/');//登出成功后跳转到主页
});
```

在 `req.session.user` 中把 `user` 信息赋值为空。就等于这个用户的cookie.id来数据库中找的时候，发现没有user。于是就返回未登录状态的界面。

**Tips:用`db.sessions.remove({})`可以删除所有的session。**






# 第一次研究登陆的过程，我觉得漏洞很多
1. 首先，密码原文是明文传输的。只是在server端不保存原文而已。
2. server判定用户是通过cookie id，那么如果有人伪造id呢？
3. md5保存密码没有问题，一定程度上减少了被拖库的威胁。但是session数据库被拖库了以后，对方不就知道这个用户的cookie id了吗，继而就可以仿造cookie了。

## 对 cookie.id & cookieSecret  猜测

```js
app.use(session({
secret: settings.cookieSecret
key: settings.db,//cookie name
...
})}));
```

在session中，我们添加了一个 cookieSecret 我猜测这个东西对我们的 cookie 做了加密。

### 查看Client:Cookie
看下cookie（从chrome的开发者工具的 Resources->Cookies 可以看到 Cookies):
```
Name: blog
Value: s%3ATKcqS6XfuhObSk2vFY1UuNI_ehtpn8MM.b8NAkCxLu85FB2OiusE8FftGMKS2VEOJppODD2eD5%2FU
Domain: node
Path: /
Exp. time: 2016-05-01T09:23:32.673Z
Size: 86
HTTP: ✓ true
```

我在同一个浏览器中重新注册了一个账号'r'，看看新的Cookie：
```
blog    
s%3ATKcqS6XfuhObSk2vFY1UuNI_ehtpn8MM.b8NAkCxLu85FB2OiusE8FftGMKS2VEOJppODD2eD5%2FU
node
/   
2016-05-02T11:23:50.520Z    
86  
✓       
```

也就是说，value没变！只是Expire Time变了。

### 查看Server:Cookie
再来看看数据库的存储：
```
> db.sessions.find()
{ "_id" : "TKcqS6XfuhObSk2vFY1UuNI_ehtpn8MM", "session" : "{\"cookie\":{\"originalMaxAge\":2591999997,\"expires\":\"2016-04-30T21:36:25.235Z\",\"httpOnly\":true,\"path\":\"/\"},\"flash\":{},\"user\":{\"name\":\"r\",\"password\":\"c4ca4238a0b923820dcc509a6f75849b\",\"email\":\"1@1\"}}", "expires" : ISODate("2016-04-30T21:36:25.235Z") }
```

可以看到 user:name:r 就是刚刚申请的那个。值得注意的是，expire time 没变！看来client 和 server各自维护自己的expire时间。

注意`_id`正是Client:Cookie存储的`s%3ATKcqS6XfuhObSk2vFY1UuNI_ehtpn8MM.`只是多了个`s%3A`前缀罢了。那么我说的这种cookie欺骗是有可能的。

### 新注册一个Cookie
再看一个cookie, 使用chrome隐身模式，注册一个 'niming' 的user：
得到Cookie:
```
blog    s%3ADLGJsEugpRcnMGtH37frp_uQQ2B-RXUp.iL5i3ATdzjoABjwAHZF554jkpfFtY%2B%2FICrOFzADEH2A    node    /   2016-05-02T11:43:58.855Z    88  ✓       
 
```

`>db.sessions.find()`:

```
{ "_id" : "DLGJsEugpRcnMGtH37frp_uQQ2B-RXUp", "session" : "{\"cookie\":{\"originalMaxAge\":2592000000,\"expires\":\"2016-04-30T21:56:26.531Z\",\"httpOnly\":true,\"path\":\"/\"},\"flash\":{},\"user\":{\"name\":\"niming\",\"password\":\"c4ca4238a0b923820dcc509a6f75849b\",\"email\":\"1@1\"}}", "expires" : ISODate("2016-04-30T21:56:26.531Z") }
```

//TODO: expire time 到底怎么回事。。不是很关键。日后再说。
问题是，依然一样。前缀也依然是`s%3A`，后面一样。
### 更改 `cookieSecret = myblog?`

我更改下 `cookieSecret = myblog?` 看看是不是影响前缀。
1. 首先修改cookieSecret后，用户端的原cookie失效了。并且申领了一个新的cookie:
        
        s%3A82YXnbBiTqEbnFWVtkyaQPcZ0yxAD1Oz.97K96xtAF186ejUJMWCMcGg7Hq9J5w017YiqCzR8RTg

    
2. 注册一个新用户 "new". Client.Cookie.Value 并没有发生改变。
3. 看看 Server.db.Session.Cookie:
    
        { "_id" : "82YXnbBiTqEbnFWVtkyaQPcZ0yxAD1Oz", "session" : "{\"cookie\":{\"originalMaxAge\":2592000000,\"expires\":\"2016-04-30T22:07:14.027Z\",\"httpOnly\":true,\"path\":\"/\"},\"flash\":{},\"user\":{\"name\":\"new\",\"password\":\"c4ca4238a0b923820dcc509a6f75849b\",\"email\":\"1@1\"}}", "expires" : ISODate("2016-04-30T22:07:14.027Z") }

    
4. 可以看到前缀没有变化。但是是不是Client.Cookie.Value的后半部分`.97K96xtAF186ejUJMWCMcGg7Hq9J5w017YiqCzR8RTg`有用呢？是不是Client在Request的时候传入了后者。而后者是由Server之前对前半部分用 种子为 cookieSecret 进行加密的结果，传给Client作为凭证。
5. 尝试注释掉 `secret: settings.cookieSecret` 这一行。结果是报错，`Error: secret option required for sessions`。把setting.js里的secret设为空。也报一样的错误。

6. 后者就是Server给的！可以去chrome的network点击'node'（也就是索取的host)页面,就可以看到response,request,和里面的cookie了！可以看到的确server提供了value的后半段，而且每次发送的时候也发送全部的。

### 使用Chrome Extension Tamper Chrome

#### 安装Tamper Chrome 

两部分，分为 Application 和 Extension:

[Application](https://chrome.google.com/webstore/detail/tamper-chrome-extension/hifhgpdkfodlpnlmlnmhchnkepplebkb)

[Extension](https://chrome.google.com/webstore/detail/tamper-chrome-application/odldmflbckacdofpepkdkmkccgdfaemb)

都要安装。Extension负责拦截，App负责显示。

#### 启动

在地址栏输入 `chrome://apps` 进入应用启动界面。开启Tamper App.
在开发者工具 `Element Console ...` 这一行点击最后面的 `>>` 开启Tamper Ext.之后可以选择拦截什么东西。第一个应该是总开关。后面是拦截的所有选项。
开启 `block / reroute requests` 和 `request headers` 可选 ignore 一些 request。不必去拦截这些。

#### 修改 request.cookie

当注册成功返回主页的时候，register 选项不可见。证明已经是已登陆状态。
再次刷新依然是已登陆状态的。 

再次刷新的时候，拦截，并且修改cookie的后半段。就是`.`之后的部分。哈哈！的确是**退出登陆状态**了。而且server的返回也再分派给client一个新的cookie。

### 结论
如果把cookie.value分为 `x.y` 的话。这2部分都是由server生成的。`x`存储在数据库中。`y`存储在用户cookie中。在用户发送request的时候，同时发送`x.y`。由server判断 `加密(x,cookieSecret) === y`，如果不等于，就认为用户有误。不予登录。

因此，如果要达成欺骗，就需要同时获取到 `x.y`，单单更改`x`是不行的。












