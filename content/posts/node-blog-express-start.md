---
title: nswbmw/N-blog学习笔记-1-Express, Routes 初步
date: 2016-03-28 17:30:44
tags: [Nblog, Node.js]
---

# Express 安装

1. `npm install -g express-generator` : `-g`:global
2. `app.use([path], function)` 

  例如一个简单的logger：
  ```js
  var express = require('express');
  var app = express();

  // 一个简单的 logger
  app.use(function(req, res, next){
    console.log('%s %s', req.method, req.url);
    next();
  });

  // 响应
  app.use(function(req, res, next){
    res.send('Hello World');
  });

  app.listen(3000);
  ```

  使用 `app.use()`定义的中间件的顺序非常重要，它们将会顺序执行，**use的先后顺序决定了中间件的优先级**。比如说通常 express.logger() 是最先使用的一个组件，纪录每一个请求。

3. [express api](http://expressjs.jser.us/api.html)
4. `next()` : 如果某一个`callback`执行了`next('route')`，它后面的`callback`就被忽略。这种情形会应用在当满足一个路由前缀，但是不需要处理这个路由，于是把它向后传递。
5. `routes/index.js` 控制了请求调用。
  ```js
  //ray0@ubuntu:~/nodeblog$ cat routes/index.js 
  var express = require('express');
  var router = express.Router();

  /* GET home page. */
  router.get('/', function(req, res, next) {
    res.render('index', { title: 'Express' });
  });
  ```
6. `bin/www` 文件是实际的执行文件，在里面会调用`../app.js`
    每次执行 `DEBUG=nodeblog:* npm start` 的时候，会提示 `> node ./bin/www` 这样。
7. 我用的这个版本的Express默认的前端渲染引擎是`jade`。结构很有趣：

        //ray0@ubuntu:~/nodeblog/views$ cat index.jade 
        extends layout

        block content
          h1= title
          p Welcome to #{title}

        //ray0@ubuntu:~/nodeblog/views$ cat layout.jade 
        doctype html
        html
          head
            title= title
            link(rel='stylesheet', href='/stylesheets/style.css')
          body
            block content
        
    关于里面这个`title= title`: 在渲染模板时我们在`routes/index.js`传入了一个变量 title 值为 express 字符串。尝试修改了2个jade里面的`title`（`title= titled`和`h1= titled`)再把传入参数在`routes/index.js`改为`titled: 'Express'`一切正常。说明的确`titled`全程在做参数。
    
    *Tips:更改view不需要重启*

# routes的探究

## app.js 
```js
//ray0@ubuntu:~/nodeblog$ cat app.js 
//...
var routes = require('./routes/index');
var users = require('./routes/users');
//...
app.use('/', routes);
app.use('/users', users);
//...
```

意义：是在 app.js 中实现了简单的路由分配。对于`/`的请求，去找routes(是指`'./routes/index'`).对于`'/users'`的请求，去找`users` `(= require('./routes/users');)`。
再去`index.js`（或者`users.js`）中找到对应的路由函数，最终实现路由功能。

## index.js

```js
//ray0@ubuntu:~/nodeblog$ cat routes/index.js 
...
/* GET home page. */
router.get('/', function(req, res, next) {
  res.render('index', { titled: 'Express' });
});
...
```

意义：当访问主页`/`时，调用`app.set('view engine', 'jade');`:`jade`的渲染引擎，来渲染 index.jade 模版文件（同时将 title 变量全部替换为字符串 Express），生成静态页面并显示在浏览器中。

## 顺便看下users.js

```js
ray0@ubuntu:~/nodeblog$ cat routes/users.js 
var express = require('express');
var router = express.Router();

/* GET users listing. */
router.get('/', function(req, res, next) {
  res.send('respond with a resource');
});

module.exports = router;
```

其实和index一样。调用方式为`http://node:3000/users`
这个逻辑定义在`app.js`中。进入`/users`之后去调用`users.js`,

>挂载的路径不会在req里出现，对中间件 function不可见，这意味着你在function的回调参数req里找不到path。 这么设计的为了让间件可以在不需要更改代码就在任意"前缀"路径下执行

因此，它对于它的根目录的响应就是返回一个字符串。

## 另一种可行的办法和原理猜测

在[N-blog的教程](https://github.com/nswbmw/N-blog/wiki/第1章--一个简单的博客)里，他推荐

>修改 index.js 如下：

>       
>       module.exports = function(app) {
>          app.get('/', function (req, res) {
>              res.render('index', { title: 'Express' });
>          });
>       };
>      
>app.js 修改为：
>
>       (+)app.set('port', process.env.PORT || 3000);
>       (-)app.use('/', routes);
>       (-)app.use('/users', users);
>       (+)routes(app);
>       

他认为这样把路由控制器和实现路由功能的函数都放到 index.js 里，app.js 中只有一个总的路由接口。会更容易维护。

值得注意的是：
>这里我们在 routes/index.js 中通过 module.exports 导出了一个函数接口，在 app.js 中通过 require 加载了 index.js 然后通过 routes(app) 调用了 index.js 导出的函数。

那么也就是说，其实require之后得到的返回是一个Funtion。因此可以直接调用。`app.use()`也是一个类似`call()`的函数而已。

# 路由规则

`app.get()` 和 `app.post()`的第一个参数都为请求的路径，第二个参数为处理请求的回调函数，回调函数有两个参数分别是 req 和 res，代表请求信息和响应信息 。路径请求及对应的获取路径有以下几种形式：

## req.query : 处理 get 请求

```
// GET /search?q=tobi+ferret  
req.query.q  
// => "tobi ferret"  

// GET /shoes?order=desc&shoe[color]=blue&shoe[type]=converse  
req.query.order  
// => "desc"  

req.query.shoe.color  
// => "blue"  

req.query.shoe.type  
// => "converse"  
```

~~这么看来，第一个`search`或者`shoes`一点屁用都没有啊。~~
有用，这才是指定路由的字段。这个请求因此被 `get('/search')` 函数处理。 

## req.body : 处理 post 请求

```
// POST user[name]=tobi&user[email]=tobi@learnboost.com  
req.body.user.name  
// => "tobi"  

req.body.user.email  
// => "tobi@learnboost.com"  

// POST { "name": "tobi" }  
req.body.name  
// => "tobi"  
```

显然json是一个很好的post方式

## req.params : 处理 url参数 请求

```
// GET /user/tj  
req.params.name  
// => "tj"  

// GET /file/javascripts/jquery.js  
req.params[0]  
// => "javascripts/jquery.js" 
```

`req.params[1]` 会返回什么？undefined

## req.param(name) : 处理 全部 请求，但查找优先级由高到低为 req.params→req.body→req.query

```
// ?name=tobi  
req.param('name')  
// => "tobi"  

// POST name=tobi  
req.param('name')  
// => "tobi"  

// /user/tobi for /user/:name   
req.param('name')  
// => "tobi"  
```

`/user/:name` 指的是url请求。但是`:name`是怎么定义的？这里对于解析url毫无影响，纯粹是为后面对这个字段的调用命名。

# 添加规则

## express支持正则表达式

```js
app.get(/^\/commits\/(\w+)(?:\.\.(\w+))?$/, function(req, res){
  var from = req.params[0];
  var to = req.params[1] || 'HEAD';
  res.send('commit range ' + from + '..' + to);
});
```

关于`(?:xxxxx)`格式：虽然被`()`围起来是一个分组，但是这个分组的信息不会被记录为para。
上述`(?:\.\.(\w+))`的意义就是说这个分组里面需要匹配形如"..1234"这样的，但是不记录"..1234"，只去记录"1234".

另外，正则表达式使用`\....\`被扩起来之后就不要用`'...'`再扩一遍了。

这个函数的调用方式 `http://node:3000/commits/71dbb9c..4c084f9`

## 发现一个小问题，如果这里的`commits`是`users`,那 /routes/users.js 会怎么办？
尝试一下：
同时在每个函数里加上一个`debug()`查看调用顺序:

### index.js
```js
...
debug('in index.js HEAD');
router.get('/', function(req, res, next) {
  debug('in index.js /');
  res.render('index', { titled: 'Express' });
});

router.get(/^\/users\/(\w+)(?:\.\.(\w+))?$/, function(req, res){
  debug('in index.js get_RegExp');
  var from = req.params[0];
  var to = req.params[1] || 'HEAD';
  res.send('commit range ' + from + '..' + to );
});
...
```

### users.js
```js
...
debug('in users.js HEAD');
router.get('/', function(req, res, next) {
  debug('in users.js /');
  res.send('respond with a resource');
});
...
```

### Output
`http://node:3000/users/` : debug is not defined

### debug
这个Debug函数好像的确是没有定义。。但是我看在 /bin/www 里用的是`debug`啊。
再去翻下 /bin/www 发现定义
`var debug = require('debug')('nodeblog:server');`
加到2个routes.js里面。

### 再来一次: 注意每次修改文件都要重启

### Output

```
  nodeblog:server in index.js HEAD +0ms
  nodeblog:server in users.js HEAD +5ms
  nodeblog:server Listening on port 3000 +30ms

  nodeblog:server in index.js get_RegExp +7s
GET /users/123 304 9.495 ms - -

  nodeblog:server in users.js / +14s
GET /users/ 304 2.616 ms - -

  nodeblog:server in users.js / +22s
GET /users 304 0.791 ms - -
```

*注意，访问url后，先log出 `in users.js` 再 log出 `GET /users/ ` 
肯定先去找相应的router再调用function，最后返回html。*

也就是说，再访问`/users/`的时候，**只**用到了users.js。访问`/users/123`**只**用到了index.js。

@update 3/30 06:24 猜测：可能是在执行 index.js 的时候只是把 `get` `post` 等函数做一个hash图。之后需要路由的时候只去hash里面找，而不会执行这个完整的JS函数。

### 猜测
由于

```
app.use('/', routes);
app.use('/users', users);
```

>使用 app.use() “定义的”中间件的顺序非常重要，它们将会顺序执行，use的先后顺序决定了中间件的优先级。 

因此，express 先查看 index.js中定义的中间件是否有可用的回调函数。因为 `/users` 不符合 `'/'` 和 `/^\/users\/(\w+)(?:\.\.(\w+))?$/` 。所以自然就不去继续调用callback。之后去 users.js 中定义的函数中看，这时候带着一个文件路径前缀`"/static"`,并且成功找到了`'/'`。注意访问全程express并不会再跑一遍router.js，只是在最一开始运行的时候跑了2个js。  


### 脑洞：如果两个js都定义了对于同一个url的请求的解析呢？

在users.js中添加函数：

```
router.get('/123',function(req,res,next){
  debug('in users.js /123');
  res.send('in us 123');
});
```

#### Output

```
  nodeblog:server in index.js get_RegExp +4s
GET /users/123 200 2.981 ms - 22
```

看来也只去访问 index.js 。符合查看的顺序。

### 假设 index.js 里面如果这个函数不提供`res.send();`呢？

也不会继续交还给 users.js。而是啥都不返回。干等，也不返回空值。具体表现为访问超时。


---
*关于github markdown的吐槽：*
话说如果 \`\`\` 前面如果有Tab就会渲染不出来。但是如果没有Tab编号就乱了。官方的意思是
> To preserve your formatting within a list, make sure to indent non-fenced code blocks by eight spaces.  
    
也就是说还是要留8个空格。但是Omni的渲染器并不能正确渲染这个格式。

