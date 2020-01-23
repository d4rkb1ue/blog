---
title: 廖雪峰 JavaScript 教程-浏览器对象, DOM, 操作表单
date: 2016-02-10 21:13:59
tags: [JavaScript, CSS, Web]
---
# 浏览器对象
## 1. window
`window`对象首先是全局作用域。
`window`对象有 `innerWidth` 和 `innerHeight` 可以获取浏览器窗口的内部宽度和高度。内部宽高是指除去菜单栏、工具栏、边框等占位元素后，用于显示网页的净宽高。



## 2. navigator
`navigator`对象表示浏览器的信息

- navigator.appName：浏览器名称；
- navigator.appVersion：浏览器版本；
- navigator.language：浏览器设置的语言；
- navigator.platform：操作系统类型；
- navigator.userAgent：浏览器设定的User-Agent字符串。

{0} 3. screen

- screen.width：屏幕宽度，以像素为单位；
- screen.height：屏幕高度，以像素为单位；
- screen.colorDepth：返回颜色位数，如8、16、24。

## 4. location
`location`对象表示当前页面的URL信息

- location.href : http://www.example.com:8080/path/index.html?a=1&b=2#TOP

- location.protocol; // 'http'
- location.host; // 'www.example.com'
- location.port; // '8080'
- location.pathname; // '/path/index.html'
- location.search; // '?a=1&b=2'
- location.hash; // 'TOP'

也可以通过操作`location`对象进行跳转或刷新

- location.reload(); // 刷新
- location.assign('/discuss'); // 设置一个新的URL地址

## 5. document
document对象表示当前页面。由于HTML在浏览器中以DOM形式表示为树形结构，document对象就是整个DOM树的根节点。

- document.title : HTML文档中的`<title>xxx</title>`



用document对象提供的`getElementById()`和`getElementsByTagName()`可以按ID获得一个DOM节点和按Tag名称获得一组DOM节点：
```js
var menu = document.getElementById('drink-menu');
var drinks = document.getElementsByTagName('dt');
```

###  操作浏览器对象Title
```js
var i =0;

var intervalID = window.setInterval(function(){
	document.title = document.title+"+";
	i++;
	if(i>10){
		clearInterval(intervalID);
	}
}, 500);
alert("aa");
```

#  DOM

##  查找

**注意 `getElementsByClassName`只能用于`document` 根元素。
普通的`HTMLDivElement`是只有`getByClassName`和`getByTagName`的。**

###  CSS
```js
document.styleSheets
```

可以找到所有的css文件。

## 修改

### innerHTML
修改innerHTML属性，完全操控一个节点的任何属性。设置默认不会被编码。存在危险性。

### innerText或textContent
可以自动对字符串进行HTML编码，保证无法设置任何HTML标签.
```js
t.innerText = '<dd>';
```

输出
```html
<div id="test-div">&lt;dd&gt;</div>
```

>两者的区别在于读取属性时，innerText不返回隐藏元素的文本，而textContent返回所有文本。另外注意IE<9不支持textContent。

但是我没有发现有什么区别。

### 设置CSS

```js
// 获取<p id="p-id">...</p>
var p = document.getElementById('p-id');
// 设置CSS:
p.style.color = '#ff0000';
p.style.fontSize = '20px';
p.style.paddingTop = '2em';
```

## 插入DOM
因为innerHTML会直接替换掉原来的所有子节点。
### appendChild
把一个子节点添加到父节点的最后一个子节点。
为HTML元素进行排序：
```html
<ol id="test-list">
    <li class="lang">Scheme</li>
    <li class="lang">JavaScript</li>
    <li class="lang">Python</li>
    <li class="lang">Ruby</li>
    <li class="lang">Haskell</li>
</ol>
```

我的答案：
```js
var a = [];
var e = document.getElementById('test-list').children;

for(i=0;i<e.length;i++){
    a.push(e[i]);
}


a.sort( function (ele,ele2) {
    if(ele.innerText > ele2.innerText){
        return 1;
    }else{
        return -1;
    }
});

e = document.getElementById('test-list');
e.innerHTML = "";

a.forEach(function(aa){
    e.appendChild(aa);
})
```

执行后已被正确排序
```html
Haskell
JavaScript
Python
Ruby
Scheme
```

值得注意的是，`HTMLCollection` 是无法被直接排序的，详情见 
array-prototype-sort-call-cannot-apply-on-dom.md


## 删除DOM
```js
// 拿到待删除节点:
var self = document.getElementById('to-be-removed');
// 拿到父节点:
var parent = self.parentElement;
// 删除:
var removed = parent.removeChild(self);
removed === self; // true
```


# 操作表单

## MD5加密密码的最佳实现
```html
<!-- onsubmit 响应<form>本身的onsubmit事件，在提交form时return true来告诉浏览器继续提交，如果return false，浏览器将不会继续提交form -->
<form id="login-form" method="post" onsubmit="return checkForm()">
    <input type="text" id="username" name="username">
    <input type="password" id="input-password">
    <!-- 
    这样做不改变用户的输入，不会出现口令框的显示会突然从几个*变成32个*（因为MD5有32个字符）。
    的情况
    -->
    <input type="hidden" id="md5-password" name="password">
    <button type="submit">Submit</button>
</form>

<script>
function checkForm() {
    var input_pwd = document.getElementById('input-password');
    var md5_pwd = document.getElementById('md5-password');
    // 把用户输入的明文变为MD5:
    md5_pwd.value = toMD5(input_pwd.value);
    // 继续下一步:
    return true;
}
</script>
```

以下这种实现不被推荐。扰乱了浏览器对form的正常提交。
```html
<form id="test-form">
    <input type="text" name="test">
    <button type="button" onclick="doSubmitForm()">Submit</button>
</form>

<script>
function doSubmitForm() {
    var form = document.getElementById('test-form');
    // 可以在此修改form的input...
    // 提交form:
    form.submit();
}
</script>
```

## 对提交表单的格式验证
```js
var user = document.getElementById('username'),
    pass = document.getElementById('password'),
    pass1= document.getElementById('password-2'),
    userc=/\w{3,10}/, //3-10位数字或字母
    passc=/.{6,20}/; //任意字符长度为6-20位

  if(!userc.test(user.value)){
    alert("账户必须为3-10位数字或字母");
    return false;
  }else if(!passc.test(pass.value)){
    alert("密码长度必须为6-20位");
    return false;
  }else if(pass.value != pass1.value){
    alert('两次密码必须相同');
    return false;
  }
  return true;
}
```

*tips:`<button type="reset">重置</button>`可以重设表单数据*


# File API
```html
<h3>图片预览</h3>
<div id="image-preview" style="border: 1px solid #ccc; width: 980px;margin:auto; height: 200px; background-size: contain; background-repeat: no-repeat; background-position: center center;">

</div>
<div id="info">

</div>
<div>
    <input type="file" id="file" name="file" value="" />
</div>
```

```js
    var fileInput = document.getElementById('file'),
        info = document.getElementById('info'),
        preview = document.getElementById('image-preview');
    // 监听 type="file" 的change事件
    fileInput.addEventListener('change', function () {
        // 清除背景图片
        preview.style.backgroundImage = '';
        // 检查文件是否选择
        if(!fileInput.value) {
            info.innerHTML = '<span style="color:red;">没有选择图片</span>';
            return false;
        }

        // 获取file引用
        var file = fileInput.files[0];
        console.log(file);
        info.innerHTML = 
                        '文件: ' + file.name + '<br>'
                    +   '大小: ' + file.size + '<br>'
                    +   '修改: ' + file.lastModifiedDate;

        // 判断图片格式
        if(file.type!=='image/jpeg' && file.type !== 'image/png' && file.type !== 'image/gif') {
            var p = document.createElement('p');
            p.innerHTML = '<span style="color:red;">不是有效的图片文件！</span>';
            info.appendChild(p);
            return false;
        }

        // 展示图片
        var reader = new FileReader();
        reader.onload = function (e) {
            var data = e.target.result;// data:image/jpeg;base64,
            preview.style.backgroundImage = 'url("'+data+'")';
        }

        // 以DataURL的形式读取文件
        reader.readAsDataURL(file);
    });
```
