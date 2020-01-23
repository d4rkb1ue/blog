---
title: Node.js Modules 入门
date: 2017-03-01 20:46:05
tags: [Node.js]
---

# 示例

## exports Functions

创造一个模块，circle.js
```js
const PI = Math.PI;
exports.area = (r) => PI * r * r;
```


引用这个模块，main.js
```js
const circle = require('./circle.js');
console.log(`Area of a circle of radius 4 is ${circle.area(4)}`);
```

Usage
```
$ node main.js
> Area of a circle of radius 4 is 50.26548245743669
```



circle.js 暴露了 `area()` 这个方法。于是引用起来就是直接`.这个方法`

## exports Object

除了定义要暴露的 `exports` 的方法，还可以选择自定义一个完整的 Object 作为整个`exports`接口来暴露，square.js
```js
module.exports = (width) => {
    return {
        area: () => width * width
    };
};
```

引用它，main.js
```js
const square = require('./square.js');
var mySquare = square(2); // get a closure
console.log(`The area of my square is ${mySquare.area()}`);
```

## diff

这两个的区别，

>1. module.exports 初始值为一个空对象 {}

>2. exports 是指向的 module.exports 的引用

>3. require() 返回的是 module.exports 而不是 exports

# 注意事项

require 的过程是同步的，所以这样是错误的:

```js
setTimeout(() => {
  module.exports = { a: 'hello' };
}, 0);
```

警惕循环引用，
```
# a.js
require('./b.js');

# b.js
require('./a.js');
```

这种循环引用的结果是其中一个require到的对象是空，`{}`。因为第一个被重复引用的对象还没有初始化完成。

# Ref

- https://nodejs.org/api/modules.html
- https://github.com/nswbmw/N-blog/blob/master/book/2.1%20require.md
- https://github.com/nswbmw/N-blog/blob/master/book/2.2%20exports%20和%20module.exports.md


