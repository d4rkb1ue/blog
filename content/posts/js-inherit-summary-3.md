---
title: JavaScript 继承机制-3-拷贝继承和数据类型
date: 2016-06-16 16:47:52
tags: [JavaScript]
---

# 假设
现在有一个对象，叫做"中国人"。
```js
var Chinese = {
    nation:'中国'
};
```

还有一个对象，叫做"医生"。
```js
var Doctor ={
    career:'医生'
}
```

请问怎样才能让"医生"去继承"中国人"，也就是说，我怎样才能生成一个"中国医生"的对象？



# object(o) 方法: 生成“类”o的实例
```js
function object(o) {
    function F() {};
    F.prototype = o;
    return new F();
}
```

`new F()`实际调用的是`o.constructor`但是免去了传参。其实就是把一切初始化参数都设定为`undefined`. 即：
```js
function O(a){this.a=a};
function F() {};
F.prototype = O;

F.prototype.constructor === O.constructor; //true
```

## 使用
```js
var Doctor = object(Chinese);
Doctor.career = '医生';
alert(Doctor.nation); //中国
```

这时，子对象已经继承了父对象的属性了。

# 浅拷贝: extendCopy(p)
把父对象的属性，全部拷贝给子对象，也能实现继承。
```js
function extendCopy(p) {
    var c = {};
    for (var i in p) { 
        c[i] = p[i];
    }
    c.uber = p; //uber means super. 即父类
    return c; 　　
}
```

## 使用
```js
var Doctor = extendCopy(Chinese);
Doctor.career = '医生';

alert(Doctor.nation); // 中国
```

## 问题
如果父对象的属性等于**Array数组**或另一个**Object对象**，那么实际上，子对象获得的只是一个内存地址，而不是真正拷贝，因此存在父对象被篡改的可能:对子类的操作，反而会影响父类。这不和逻辑。

*所以，extendCopy()只是拷贝基本类型的数据，我们把这种拷贝叫做"浅拷贝"。*

# 深拷贝
递归调用"浅拷贝"就行了。
```js
function deepCopy(p, c) {
    var c = c || {};
    for (var i in p) {
        //Array也是'object'哈。而且'i'永远不能是'null', 因此会递归拷贝所有指针
        if (typeof p[i] === 'object') {
            c[i] = (p[i].constructor === Array) ? [] : {};
            deepCopy(p[i], c[i]);
        } else {
            //基本数据类型
            c[i] = p[i];
        }
    } 　　　　
    return c;
}
```

*Array的拷贝说明：*
```js
for(var v in a){console.dir(v+": "+a[v])};
//0: 1
//1: 2
//2: 4
```

## 使用
```js
var Doctor = deepCopy(Chinese);

Chinese.birthPlaces = ['北京','上海','香港'];
Doctor.birthPlaces.push('厦门');

alert(Doctor.birthPlaces); //北京, 上海, 香港, 厦门
alert(Chinese.birthPlaces); //北京, 上海, 香港
```

这时，父对象就不会受到影响了。

*目前，jQuery库使用的就是这种继承方法。*

---
# 关于JS的指针
## [ ] = new Array()
```js
var a = [123,45];
var b = a;

a.pop(); //45
b; //[123]
```

## { }
```js
var a = {n:1};
var b = a; //Object {n: 123}

a.s = 1;
a; //Object {n: 1, ss: 2}
b; //Object {n: 1, ss: 2}
```

## 总结
JS中，对于Array和对象（方法也是对象）的`=`重载是复制指针。

# JS的数据类型：使用constructor得到的
`typeof`定义的类型`function`和`undefined`都是不一样的。详见API。

```js
//不要使用==比较，始终坚持使用===比较。

123..constructor === Number; //true
//注意123.constructor是会报错的。123.. => 123.0. 不会误判为错误的数字定义方式。
Infinity.constructor === Number; //true 无穷
NaN.constructor === Number; //true 不是个数字,可由"0/0"获得



'123'.constructor === String; //true
true.constructor === Boolean; //true

[1,2].constructor === Array; //true

({}).constructor === Object; //true
//{}.constructor === Object; //Unexpected token . :所有'}'都预示着后面没东西了。不会再看了。有东西就出错。这是由于js的免';'机制导致的

null.constructor; //Cannot read property 'constructor' of null
null === null; //true

//undefined仅仅在判断函数参数是否传递的情况下有用
undefined.constructor; //Cannot read property 'constructor' of undefined
undefined === undefined; //true

```

## API
### constructor
```js
  new Array(),
  [],
  new Boolean(),
  true,             // remains unchanged
  new Date(),
  new Error(),
  new Function(),
  function () {},
  Math,
  new Number(),
  1,                // remains unchanged
  new Object(),
  {},
  new RegExp(),
  /(?:)/,
  new String(),
```

### typeof
```js
Undefined           "undefined"
Null                "object"
Boolean             "boolean"
Number              "number"
String              "string"
Symbol              "symbol"
Function object     "function"
Any other object    "object"

Host object (provided by the JS environment)    Implementation-dependent
```

## 特殊的Number
```js
NaN === NaN; //false 不等于任何,包括自己
isNaN(NaN); // true

Infinity === Infinity; //true

1 / 3 === (1 - 2 / 3); // false
Math.abs(1 / 3 - (1 - 2 / 3)) < 0.0000001; // true
```

 参考

[阮一峰：Javascript面向对象编程（三）：非构造函数的继承](http://www.ruanyifeng.com/blog/2010/05/object-oriented_javascript_inheritance_continued.html)
