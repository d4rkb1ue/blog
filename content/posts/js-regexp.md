---
title: 正则表达式入门
date: 2017-03-11 23:44:20
tags: [JavaScript, RegEx]
---

# RegExp 语法
## 字符

- `\d`: one number
- `\w`: one number, letter
- `.`: any single character
- `\s`: one space(' '), tab('\t')


特殊字符需要转义，

- `-`: `\-`
- `_`: `\_`
- `$`: `\$`

例如，
```js
00\d // 004
\d\d\d // 223
\w\w // f2
js.// js!
```


## 限制
`+`: one or more
`*`: none or more
`?`: none or one
`{n}`: exactly n chars
`{n, m}`: n <= number of chars <= m
`[0-9]`: range
`A|B`: or
`^`: 表示行的开头
`$`: 表示行的结束 

## 分组
`()`， `^(\d{3})-(\d{3,8})$` 定义了两个组。`$1` 匹配第一个分组 

## 贪婪匹配
> 正则匹配默认是贪婪匹配，也就是匹配尽可能多的字符

```js
var re = /^(\d+)(0*)$/;
re.exec('102300'); // ['102300', '102300', '']
```

加个 `?` 就可以让 `\d+` 采用非贪婪匹配，
```js
var re = /^(\d+?)(0*)$/;
re.exec('102300'); // ['102300', '1023', '00']
```


# In Javascript

使用 `/RegExp/` 定义，或者创建 RegExp 对象，
```js
var re1 = /ABC\-001/; // /ABC\-001/
/* 因为字符串的转义问题，字符串的两个\\实际上是一个\ */
var re2 = new RegExp('ABC\\-001'); // /ABC\-001/
```

## 使用方式

`RegExp.test()` 检验，

```js
var re = /^\d{3}\-\d{3,8}$/;
re.test('010-12345'); // true
re.test('010-1234x'); // false
```

`RegExp.exe()` 检验并提取分组，

```js
var re = /^(\d{3})-(\d{3,8})$/;
re.exec('010-12345'); // ['010-12345', '010', '12345']
re.exec('010 12345'); // null
```


`String.split()` 切分字符串,
```js
/* 不用 regexp 的后果 */
'a b   c'.split(' '); // ['a', 'b', '', '', 'c']
'a,b;; c  d'.split(/[\s\,\;]+/); // ['a', 'b', 'c', 'd']
```

`/test/g` 全局搜索，
```js
var s = 'JavaScript, VBScript, JScript and ECMAScript';
var re=/[a-zA-Z]+Script/g;
/* === re = new RegExp('[a-zA-Z]+Script', 'g'*/

// 使用全局匹配:
re.exec(s); // ['JavaScript']
re.lastIndex; // 10

re.exec(s); // ['VBScript']
re.lastIndex; // 20

re.exec(s); // ['JScript']
re.lastIndex; // 29

re.exec(s); // ['ECMAScript']
re.lastIndex; // 44

re.exec(s); // null，直到结束仍没有匹配到
```

全局匹配类似搜索，因此不能使用 `/^...$/`，那样只会最多匹配一次。

`/g` 是一种特殊标志，还有 `i` 标志，表示忽略大小写；`m` 标志，表示执行多行匹配。


# 例子
必须以数字开头
```js
^\d
```

整行匹配 'js'
```js
^js$
```

匹配一个数字、字母或者下划线
```js
[0-9a-zA-Z\_]
```

可以匹配至少由一个数字、字母或者下划线组成的字符串，比如'a100'，'0_Z'，'js2015'等等
```js
[0-9a-zA-Z\_]+
```

JavaScript允许的变量名
```js
[a-zA-Z\_\$][0-9a-zA-Z\_\$]*
```

变量的长度是1-20个字符
```js
[a-zA-Z\_\$][0-9a-zA-Z\_\$]{0, 19}
```

可以匹配A或B，所以可以匹配'JavaScript'、'Javascript'、'javaScript'或者'javascript'
```js
(J|j)ava(S|s)cript
```

匹配 email 地址
```js
/^[a-z0-9\_\.]+@[a-z0-9\-]+\.[a-z]+$/i
```

将数字转为中文大写
```js
/**
 * 将数字转为中文大写
 * @param  {Number} n 原始数字
 * @return {String}   大写
 */
function daxie(n){
    if (!/^(0|([1-9][0-9]*))$/.test(n)){
        return undefined;
    }
    var unit = "千百十万千百十亿千百十万千百十个";
    if (n.toString().length > unit.length){
        return undefined;
    }
    // 得到单位的长度
    var unit = unit.substring(unit.length - n.toString().length);
    var nString = "";
    for (var i = 0; i < n.toString().length; i++){
        nString += "零一二三四五六七八九".charAt(n.toString()[i]) + unit.charAt(i);
    }
    // 去除多余的'零'
    nString = nString.replace(/零[千|百|十]/g, '零').replace(/零+/g, '零').replace(/零([万|亿|个])/g, '$1');
    // 去除末尾的'个'
    nString = nString.substring(0, nString.length - 1);
    return nString;
}
```



---
# Ref

- [RegExp - Javascript 教程 - 廖雪峰](http://www.liaoxuefeng.com/wiki/001434446689867b27157e896e74d51a89c25cc8b43bdb3000/001434499503920bb7b42ff6627420da2ceae4babf6c4f2000)