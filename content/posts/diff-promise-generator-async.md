---
title: 区别 diff - Promise Generator Async
date: 2017-05-24 17:52:22
tags: [JavaScript]
---

## 绝佳例子

```js
var fs = require('fs');
// callback 写法
fs.readFile('/etc/fstab', function (err, f1) {
  if (err) throw err;
	console.log(f1.toString());
	fs.readFile('/etc/shells', function (err, f2) {
		if (err) throw err;
		console.log(f2.toString());
	}
});
// 出现了两层嵌套。如果有更多文件的话，将会有更多嵌套

var readFile = function (fileName){
  return new Promise(function (resolve, reject){
    fs.readFile(fileName, function(error, data){
      if (error) reject(error);
      resolve(data);
    });
  });
};
// Promise 写法
readFile(fileA)
.then(function(data){
  console.log(data.toString());
})
.then(function(){
  return readFile(fileB);
})
.then(function(data){
  console.log(data.toString());
})
.catch(function(err) {
  console.log(err);
});

// generator 写法
var gen = function* (){
  var f1 = yield readFile('/etc/fstab');
  console.log(f1.toString());
  var f2 = yield readFile('/etc/shells');
  console.log(f2.toString());
};

// async 写法
var asyncReadFile = async function (){
  var f1 = await readFile('/etc/fstab');
  console.log(f1.toString());
  var f2 = await readFile('/etc/shells');
  console.log(f2.toString());
};
```



```js
var f1 = await readFile('/etc/fstab');
// ===
readFile('/etc/fstab')
.then((data) => {
  var f1 = data;
})
```

参考 [阮一峰 - Generator](http://www.ruanyifeng.com/blog/2015/04/generator.html) 和 [阮一峰 - Async](http://www.ruanyifeng.com/blog/2015/05/async.html) 


## Promise

Promise 是 `callback` 的语法糖。流式写法的 `callback` 。最基本的功能，用另一种方式写 `callback` 。再加上了 `.then` 提供的异步操作队列。但是本质上依然是 `callback` 而已。只是写法上的不同，并没有新的线程管理，任务管理机制的引入。

> Promise 是一个对象，从它可以获取异步操作的消息。Promise 提供统一的 API，各种异步操作都可以用同样的方法进行处理。

- [ECMAScript 6入门 - Promise](http://es6.ruanyifeng.com/?search=promise&x=0&y=0#docs/promise)

- [JavaScript Promises: an Introduction - Google Developers](https://developers.google.com/web/fundamentals/getting-started/primers/promises) （这个网页有中文，到最下可更改)

## Async

而 Async 又是 Promise 的语法糖。将 Promise 中的 `.then` 函数删掉， 直接将 `.then` 函数要执行的直接写就可以。 `await` 之后就是 `.then()` 里的内容。但是看起来和同步函数完全一样。而且支持把错误处理用原生 `try{} catch{}` 方式去处理。如此重新把在 Promise 中被代替的 catch 错误处理方式用起来。但是其实也可以支持 Promise 的 `.catch` ，效果一样：

> ```js
async function myFunction() {
  try {
    await somethingThatReturnsAPromise();
  } catch (err) {
    console.log(err);
  }
}

// 另一种写法
async function myFunction() {
  await somethingThatReturnsAPromise().catch(function (err){
    console.log(err);
  });
}
```

- [Async functions - making promises friendly - Google Developers](https://developers.google.com/web/fundamentals/getting-started/primers/async-functions)

- [阮一峰 - Async](http://www.ruanyifeng.com/blog/2015/05/async.html) 称 async 是 generator 的语法糖。 但是本来都是语法糖，所以谁继承谁也都无所谓啦。

## Generator

是另一个 Promise 的语法糖。 yield 类似 `await` 的意义。但是提供了 next() 作为控制异步流程的方法。 更像一个子线程一样的行为。**但是其实只是看起来像**一个子线程。本质还是用 `callback` 进行切换。**并没有某种任务管理器**来自动根据需求切换线程。

- [阮一峰 - Generator](http://www.ruanyifeng.com/blog/2015/04/generator.html) 