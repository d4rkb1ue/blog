---
title: "问题记录 - Node.js Error callback-already-called"
date: 2016-05-03 21:54:58
tags: ["Node.js"]
---

# 重现

```js
if (err || account.length === 0) {
    callback(err);
}
  
callback(null, account[0]);

```

>Error: Callback was already called.

# 原因 

>Add else statement to you code, because if you get error, your callback executes twice.

不能2次callback。虽然本意是第一个callback之后直接return。但是async还是会继续踏实的执行完本函数。

# 解决

```js
if (err || account.length === 0) {
  callback(err);
} else {
  callback(null, account[0]);
}
```

也可以这样：

```js
if (err || account.length === 0) {
  return callback(err);
}
  
callback(null, account[0]);

```