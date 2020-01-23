---
title: 同步函数调用异步函数导致的 setState 问题
date: 2017-05-18 20:53:40
tags: [JavaScript, React]
---

# 问题描述

根据用户输入计算结果，实时将结果打印到界面上。原本的接口大约是这样：

```js
function output(text) {
    var mypre = document.getElementById("output");
    // append 而不是覆盖
    mypre.innerHTML = mypre.innerHTML + text;
}
// calculate yield 一个结果后会调用 output(res) 输出
calculate(paras, output);
```

将 `output()` 转为 React 的写法时，像这样：

```js
function output(text) {
  this.setState({mypre: this.state.mypre + text});
}
...
<div className='mypre'>
    {this.state.mypre}
</div>
```

于是问题来了。



# 以下都是不认真看教程的结果

[React - Docs](https://facebook.github.io/react/docs/state-and-lifecycle.html)

> # State Updates May Be Asynchronous
> React may batch multiple setState() calls into a single update for performance.
>
> Because this.props and this.state may be updated asynchronously, you should not rely on their values for calculating the next state.
>
> For example, this code may fail to update the counter:
>```js
// Wrong
this.setState({
  counter: this.state.counter + this.props.increment,
});
```
> 
> To fix it, use a second form of setState() that accepts a function rather than an object. That function will receive the previous state as the first argument, and the props at the time the update is applied as the second argument:
>
> ```js
// Correct
this.setState((prevState, props) => ({
  counter: prevState.counter + props.increment
}));
```


## 执行结果

在实际的调用中，正确结果是每次计算出来都要输出一个结果，应该输出多行。但是这么调用的结果是只有**最后一个结果**被成功输出。中间的结果都被吞掉了。

如果在 `setState` 中设置回调，set 后打印的话，

```js
function output(text) {
  console.log('start set state to\n', text);
  this.setState({
    mypre: this.state.mypre + text
    }, () => {
      console.log('finish set state');
    });
}
```

会发现所有的 `'finish set state'` 都会在最后被打印出来，在所有的 `'start set state to'` 之后。也就是说每次获取的原有 `this.state.mypre` 都是一样的，都是初始值。因此只有最后一个结果被附加到了结果中。

# 原因

因为 `calculate()` 是个同步函数，而 `setState()` 是异步的。同步函数在调用异步函数，但是同步函数却又时时获取异步函数的结果： `mypre: this.state.mypre + text` 。

因此，因为异步函数必然和同步函数执行速度不同，所以同步函数就会获取到旧的的参数，而不是实时的结果。于是导致了，

> 每次获取的原有 `this.state.mypre` 都是一样的

因为直到在最后一个获取 `state` 的时候，所有 `setState` 都没有完成。

# 解决方式

```js
function output(text) {
  // use this to force synchronous setState
  this.setState((prev_state) => {
    return {mypre: prev_state.mypre + text};
  })
}
```

如此 React 会自己管理 `setState` 的流程，并且保证下一个 set 之前一定能获取准确的 state。多看 API 解决一切。

> Both prevState and props received by the updater function are guaranteed to be up-to-date. The output of the updater is shallowly merged with prevState.
>
> ```
 this.setState((prevState, props) => {
    return {counter: prevState.counter + props.step};
 });
 ```

