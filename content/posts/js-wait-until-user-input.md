---
title: 实现等待用户输入完毕继续执行
date: 2017-05-25 11:18:01
tags: [JavaScript]
---

# 问题 

有一个主函数同步调用一个异步函数，这个异步函数要等待用户输入后返回给主函数用户输入的结果。在用户输入前，要怎么阻塞线程，待用户输入完毕继续执行？

# 用 while 阻塞线程？

**No**

线程会永远阻塞在 `while` 上，外部调用都不会产生作用。因为外部那个函数都执行不到，此时整个程序都完全死去了。因为同步函数到死都不会交出 CPU 控制权。

就像这样：

```js
var test = {
  status: false,
  main: function() {
    let res = this.func();
    console.log(res);
  },
  func: function() {
    while (!this.status);
    return 100;
  },
  confirm: function() {
    this.status = true;
  }
}

setTimeout(test.confirm.bind(test), 1000); // never confirm
test.func();
```

# 用 setTimeout 替代 while 轮询?



**No**

```js
func: function() {
  if (!this.status) {
    setTimeout(() => {
      this.func();
    }, 500);
  } else {
    return 100;
  }
  // return undefined;
},
```

因为 `async_func` 依然是一个被同步调用的函数，所以在一开始 `this.status` 为 `false` 的时候，它执行了 `setTimeout` 后依然继续执行了 `return` 。不可能用 `if` 阻塞函数返回啊。不能因为你把 `return` 包裹起来这个函数就不返回了。只是没有显式执行，隐式执行了 `return undefined`

# 异步主函数 + Promise + while？

**No**

```js
var test = {
  status: false,
  main: function() {
    let promise = this.async_func();
    promise.then( (data) => {
       console.log(data)
    });
  },
  async_func: function() {
    return new Promise((res) => {
		while(!this.status);
      res(100);
    });
  },
  confirm: function() {
    console.log('confirmed~');
    this.status = true;
  }
}
setTimeout(test.confirm.bind(test), 1000);
test.main(); // 100 immediately
```

这也印证了 Promise 并没有创建一个新的任务管理机制。并没有因为用 Promise 就自动在多个子线程间来回切换。

# 异步主函数 + Promise + setTimeout

**Yes**

```js
async_func: function() {
  let helper = (res) => {
    if (!this.status) {
      setTimeout(() => {
        helper(res);
      }, 500);
      return;
    }
    res(100);
  }
  return new Promise((res) => {
    setTimeout(() => {
      helper(res);
    }, 500);
  })
},
```

可以简化为：
```js
async_func: function() {
  let helper = (res) => {
    if (!this.status) {
      setTimeout(() => {
        helper(res);
      }, 1);
      return;
    }
    res(100);
  }
  return new Promise(helper);
},
```


# Promise + Setter

**Yes**

```js
var test = {
  status: false,
  on_status_change: () => {}, // placeholder
  setStatus: function(new_status) {
    this.status = new_status;
    this.on_status_change(new_status);
  },
  main: function() {
    let promise = this.async_func();
    promise.then((data) => {
       console.log(data)
    });
  },
  async_func: function() {
    let helper = (res) => {
      this.on_status_change = () => {
        res(100);
      }
    }
    return new Promise(helper);
  },
  confirm: function() {
    console.log('confirmed~');
    this.setStatus(true);
  }
}
setTimeout(test.confirm.bind(test), 1000);
test.main(); // 100 immediately
```
