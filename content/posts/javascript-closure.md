---
title: Javascript 闭包(Closure)学习笔记
date: 2017-02-28 21:27:51
tags: [JavaScript]
---

闭包是一个函数，可以访问它被创建时所处的上下文环境。

我对它一开始的理解是，保存了一份上下文的拷贝，然而这个理解是错的。实际是所需的上下文没有被释放。



# 闭包的例子

如果用闭包做一个计数器，
```js
function newCounter(start){
    // context
    var n = start || 0; // if start is undefined
    return {
        // Plan A: here will be anthor 'n' to store the 'n' from the context
        inc: function(){
            return ++n;  
        }
    }
}
// usage
var counter = newCounter();
counter.inc(); // 1
counter.inc(); // 2
```

对于这个含有函数(`inc()`)的匿名对象，它是如何访问到`n`，有两个解释：

- 闭包会复制上下文，如注释里所说
- 闭包需要的上下文会持续存在

# 错误的理解：闭包会复制上下文

闭包是自带状态的函数，**看起来**它的实现是这样的，
```js
function closure{
    var arguments = [...];
    function real_funcion(arguments){
        /* code here*/   
    }
}
```

如此来保存上下文。因为函数本身就是一个 Object，所以其实闭包**看起来**就是一个带有一个可执行函数和数据的 Object。

**看起来**，闭包将创造这个对象外面的上下文保存在内部，对外不可见。在计数器的例子中，返回的 Object 中的函数创建一个新的 `n` 对外隐藏，拷贝前面执行完毕的 `n`，形成一个闭包。

但是，这个现象很奇怪：

```js
function returner(){
    var i = 0;
    var closure = function(){
        return i;
    }
    i++;
    return closure;
}
// usage
var c = returner();
c(); // 1
```

另一个例子，

```js
function evens(){
    var arr = [];
    for (var i = 0; i<3; i++){
        arr.push(function(){
            return i * 2;
            });
    }
    return arr;
}
// usage
var e = evens();
// lazy method, calculate when use
e[0](); // 6
e[1](); // 6
e[2](); // 6
```

这个问题的一个解释是：

**看起来**，闭包复制上下文并不在声明它的时候，而在上下文函数结束后。

而正确的解释是，**闭包需要的外部变量会持续保留**

# 正确的理解：闭包需要的外部变量会持续保留

要验证它，我们给 counter 添加一个 `now()` 函数（也是个闭包），
```js
function newCounter(start){
    // context
    var n = start || 0; // if start is undefined
    return {
        // here will be anthor 'n' to store the 'n' from the context
        inc: function(){
            return ++n;  
        },
        now: function(){
            return n;
        }
    }
}
// usage
var counter = newCounter();
counter.inc(); // 1
counter.inc(); // 2
counter.now(); // 2
```

可以看到，`now()` 使用的`n`是和`inc()`所共用的，这两个函数并没有单独各自复制一个`n`。

## evens()

要修复 `evens()` 函数的问题，
```js
function evens(){
    var arr = [];
    for (var i = 0; i<3; i++){
        arr.push((function(n){
            return function(){
                return n * 2;
            }
        })(i));
    }
    return arr;
}
// usage
var e = evens();
e[0](); // 0
e[1](); // 2
e[2](); // 4
```

我们为 `()=> return n * 2` 这个函数包裹上一个上下文，即 `(function(n){...})(n)` 这是一个立即执行的匿名函数，唯一的目的是创建一个新的函数作用域。

# 上下文和作用域

函数A的上下文的定义：

> 定义函数A的外部函数的参数和变量，除了 `this`, `arguments`

上面定义的 counter 所引用的 `n` 访问的就是创建这个闭包的那个父函数中的 `n`。

## 创建新的作用域为什么有效？

因为不同作用域内的变量生命周期不同。

作用域举例，
```js
var foo = function(){
    var a = 3, b = 5;
    var bar = function(){
        var b = 7, c = 11;
        // 定义相同的 b，引用时会首先访问 this.b，找不到去找是 super.b
        // 此时此地，a = 3, b = 7, c = 11
        a += b + c;
        // 此时此地，a = 21, b = 7, c = 11
    }
    // 此时此地，a = 3, b = 5, c = undefined
    bar();
    // 此时此地，a = 21, b = 5, c = undefined
}
```

可以看到，内部定义的`b`的生命周期和外部的不同。这个例子中，`bar()`内的变量的生存周期比外部的短，在执行完毕后就释放了。

对于闭包来说，这个函数的生存周期比包含它的外部函数的生存周期更长。而本应释放的外部变量，因为内部函数仍然存在引用，故予以保留，不予释放。

[`evens()`](#evens) 这个例子中，我们让内部函数访问的 `n` 是在每次循环中新产生的 `n` 。因此得到的三个闭包所处的上下文是不同的。

# 总结

**看起来**，闭包中的 `n` 就如同新建一个 private 变量。

但是其实只是上下文的变量没有释放而已。
