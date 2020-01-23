---
title: nswbmw/N-blog 学习-2-模版引擎 ejs, 静态文件挂载
date: 2016-03-28 20:40:06
tags: [Nblog, Node.js]
---


# 模版引擎

*[N-blog](https://github.com/nswbmw/N-blog/)使用的模版引擎是ejs。我想想我还是改成这个吧。不然后面可能差距越来越大。*

*Sublime's tips: `CMD+p`:定位，输入`@`定位文件内标签 `CMD+R` ＝ `CMD+p`,`@`*

## index.ejs

```html
<!DOCTYPE html>
<html>
  <head>
    <title><%= title %></title>
    <link rel='stylesheet' href='/stylesheets/style.css' />
  </head>
  <body>
    <h1><%= title %></h1>
    <p>Welcome to <%= title %></p>
  </body>
</html>
```


## app.js
指定了所使用的render

```js
// view engine setup
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'ejs');
```

## index.js
调用render()来渲染模版，同时传参

>第一个是模板的名称，即 views 目录下的模板文件名，扩展名 .ejs 可选。第二个参数是传递给模板的数据对象，用于模板翻译。

>`res.render(view, [locals], callback)`渲染view, 同时向callback 传入渲染后的字符串。 callback如果不传的话，直接会把渲染后的字符串输出至请求方， 一般如果不需要再对渲染后的模板作操作，就不需要传callback。 当有错误发生时next(err)会被执行. 

```js
/* GET home page. */
router.get('/', function(req, res, next) {
  res.render('index', { title: 'Express' });
});
```

# ejs的标签

只有以下三种标签：

- <% code %>：JavaScript 代码。
- <%= code %>：显示**替换过 HTML 特殊字符的**内容。
- <%- code %>：显示**原始** HTML 内容。

## “替换过 HTML 特殊字符的”的含义

当变量 code 为普通字符串时，`<%=` 和 `<%-` 两者没有区别。当 code 比如为 `<h1>hello</h1>` 这种字符串时，`<%= code %>` 会原样输出 `<h1>hello</h1>`，也就说EJS会替换掉会被解释的标签如 `>` 为 `&gt;` ，而 <%- code %> 则会显示 H1 大的 hello 字符串。也就是说不会替换。

##  <% %> 内使用 JavaScript 示例

### The Data

```
supplies: ['mop', 'broom', 'duster']
```

### The Template

```html
<ul>
<% for(var i=0; i<supplies.length; i++) {%>
   <li><%= supplies[i] %></li>
<% } %>
</ul>
```

### The Result

```html
<ul>
  <li>mop</li>
  <li>broom</li>
  <li>duster</li>
</ul>
```


## include
include 的简单使用如下：

### index.ejs

```html
<%- include a %>
hello,world!
<%- include b %>
```

### a.ejs
```
this is a.ejs
```

### b.ejs
```
this is b.ejs
```

最终 index.ejs 会显示：
```
this is a.ejs
hello,world!
this is b.ejs
```

# 静态文件挂载

>app.use(express.static(path.join(__dirname, 'public'))) 设置了静态文件目录为 public 文件夹，所以 index.ejs 中的 href='/stylesheets/style.css' 就相当于 href='/public/stylesheets/style.css' 
>Express 相对于静态目录查找文件，因此静态目录的名称不是此 URL 的一部分。

在这里浏览器请求为 `Request URL:http://node:3000/stylesheets/style.css` 但是实际上请求了`/public/stylesheets/style.css`

## 疑问：那是不是所有的请求都会添加一个`public`？

为什么之前比如 node:3000/users/123 这时候不会请求到 node:3000/public/users/123 ？
按照字面理解，只有在获取静态文件的时候，才会调用这个函数吧。

1. 在 public 下 `touch 1.txt`。尝试 `GET /1.txt` 。嗯，返回file。
2. `mv 1.txt 1`。尝试`GET /1`。也能返回file。
3. 把名字改回去。还叫 1.txt
4. 在 index.js 中添加：
    
        router.get('/1.txt',function(req,res,next){
            res.send('function!');
        });

### Output

`GET /1.txt` 返回file。
但是如果删除了 1.txt ，再`GET /1.txt`，调用的就是function了。

### 结论

所有请求都会首先去看有没有相应的静态文件，设置了静态加载就会自动加上加载去查找。
没有静态文件，才会继续处理访问。

#### app.js

```js
...
app.use(express.static(path.join(__dirname, 'public')));
app.use('/', routes);
app.use('/users', users);
...
```

可以看到，对static的use是在routes之前的。

如果改为：

```js
app.use('/', routes);
app.use(express.static(path.join(__dirname, 'public')));
app.use('/users', users);
```

就会首先访问function啦！！

*vi's tips: vi 中的上下换行命令为`ddp`，其实是`dd`和`p`指令的组合。`dd`是剪切本行。`p`是在当前位置之后粘贴（在本行之后）。如果是`P`（大写）的话，是在当前位置之前*


## app.use其他参数的探索

### 使用 `__dirname + '/public'`的目的：

>向 express.static 函数提供的路径相对于您在其中启动 node 进程的目录。如果从另一个目录运行 Express 应用程序，那么对于提供资源的目录使用绝对路径会更安全。

### path.join的目的
>Node.js provides path.join() to always use the correct slash. For Windows does paths with backslashes where unix does paths with forward slashes.

### 创建虚拟路径前缀

路径并不实际存在于文件系统中。
app.use('/static', express.static('public'));

此时访问为：

```
http://localhost:3000/static/images/kitten.jpg
http://localhost:3000/static/css/style.css
```

**注意：此时访问的仍然是 /public 的文件，并没有去访问 /static/public**

---
@d4rkb1ue 2016/3/30 05:49


