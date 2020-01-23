---
title: Why array.indexOf(undefined) doesn't work if array is sparse
date: 2017-06-15 11:50:00
tags: [JavaScript]
---

```js
var firstMissingPositive = function (nums) {
  let arr = [true];
  nums.forEach((val) => {
  if (val > 0) {
    arr[val] = true;
  }
  });
  return [arr, arr.indexOf(undefined)];
};
```

Why this doesn't work?! 

```
firstMissingPositive([2]) // [[true, undefined, true], -1]
```

Why `-1` !?

but if just run `[true, undefined, true].indexOf(undefined)` in chrome dev tools it returns `1`.


# 原因

主要是 chrome 的打印问题， **sparse (稀疏)** 的 array 在没有定义的项目上，chrome 会打印出来 `undefined` 。但是这个其实是真的没有定义过的，对于 `indexOf` 来说，不像 `console.log` 会将没有定义的元素补全为 `undefined` ，`indexOf` 是看不到这个元素的。

# 解决办法

```js
arr.findIndex(val => !val); // ~= arr.indexOf(undefined)
```

`findIndex()` 是真的会去从 0 开始遍历的。就像 `for` 循环一样。

# 参考

- [Why array.indexOf(undefined) doesn't work if array is sparse - Stack Overflow](https://stackoverflow.com/questions/35949699/why-array-indexofundefined-doesnt-work-if-array-is-sparse)

> The reason this actually works unlike indexOf is that a[i] will evaluate to undefined if:
> 1. The element exists and it has the value undefined, or
> 2. The element doesn't exist at all. indexOf however will skip these "gaps" in the array.
