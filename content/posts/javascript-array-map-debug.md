---
title: 理解 Array.prototype.map()
date: 2017-04-03 20:25:00
tags: [JavaScript]
---

# 调用不是 .call()

错误示范：
```js
var b = [[1, 2], [3, 2]];
b.map(Array.prototype.sort);
// Uncaught TypeError: Array.prototype.sort called on null or undefined
b.map(a => typeof a);
// (2) ["object", "object"]
b.map(Object.prototype.toString);
// (2) ["[object Undefined]", "[object Undefined]"]
Object.prototype.toString.apply(undefined);
// "[object Undefined]"
b.map(a=>a);
// (2) [Array(2), Array(2)]
[1, 2].map(Object.prototype.toString);
// (2) ["[object Undefined]", "[object Undefined]"]
```

而 `Array.prototype.map` 或 `every` 并不是去绑定`this`。



`Array.prototype.map` 的一个例子：

```js
['a','b'].map(function a(item, index, array) {
    // 为每个值执行 function
    });
```

是这样执行的：
```js
a('a', 0, [1, 2]);
a('b', 1, [1, 2]);
```

而不是:
```js
'a'.call(0, [1, 2]);
'b'.call(1, [1, 2]);
```

因此，`[[1,2], [3,2]].map(Array.prototype.sort)` 实际上是这样运行的 

```js
Array.prototype.sort.call(this, [1, 2]);
Array.prototype.sort.call(this, [3, 2]);
```


而 this: 
```js
[1].map(()=>console.log(this)) // Window
```

也就是说，其实 `this` 被绑定了 Window，我执行的是 
```js
Window.sort([1, 2]);
Window.sort([3, 2]);
```

同样，

```js
b.map(Object.prototype.toString);
// === 
Window.toString(1);
Window.toString(2);
```


# 参数个数

```js
['1', '2', '3'].map(parseInt);
// While one could expect [1, 2, 3]
// The actual result is [1, NaN, NaN]
```

这个问题写在 API 里面，其原因是 `map` 在调用的时候传了 3 个参数，

> currentValue: The current element being processed in the array.
> index: The index of the current element being processed in the array.
> array: The array map was called upon.

就像 `callback('a', 0, [1,2])` 这样。而 `parseInt` 其实需要 2 个参数，`Number.parseInt(string,[ radix ])`。

这样一来，对于 `['1', '2', '3'].map(parseInt);` 事实上是这样的调用的：
```js
parseInt('1', 0, ['1', '2', '3']); // 1
parseInt('2', 1, ['1', '2', '3']); // NaN
parseInt('3', 2, ['1', '2', '3']); // NaN
```

第二个参数指定了几进制，1 进制是不存在的，2 进制中 `3` 也是个非法输入。不过 `parseInt('1', 0)` 0 进制是个什么鬼。。 `parseInt('142', 0); // 142` 可能 0 就被认作是 10 吧。避开这个坑的方法：

```js
function returnInt(element) {
  return parseInt(element, 10);
}

['1', '2', '3'].map(returnInt); // [1, 2, 3]
// Actual result is an array of numbers (as expected)

// A simpler way to achieve the above, while avoiding the "gotcha":
['1', '2', '3'].map(Number); // [1, 2, 3]
```

