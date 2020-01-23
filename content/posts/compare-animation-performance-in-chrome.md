---
title: Chrome Devtools 实时对比不同代码的渲染效率
date: 2017-04-24 15:36:00
tags: [Tools, Web, Chrome]
---

## 问题

公司项目有一个更新动画的函数需要每帧调用来更新动画，需要对比

- `setTimeout`
- `requestAnimationFrame`

哪一个在更新上效率更佳。



```js
if (this.internal_tick_control) {
    // window.requestAnimationFrame(this.update.bind(this));
    setTimeout(this.update.bind(this), 1000/60);
}
```

[requestAnimationFrame 会让动画函数执行会先于浏览器重绘动作执行](https://developer.mozilla.org/en-US/docs/Web/API/window/requestAnimationFrame)。其功能都是在绘制新一帧之前先对状态（动画内容）进行更新，然后调用重绘。`setTimeout` 是手动指定每隔多长时间进行更新，这有时会导致不精确的更新间隔；而 `requestAnimationFrame` 是浏览器自带优化，并且自带精确间隔调用的调用方式。理论上来说 `requestAnimationFrame` 应该会有更好的性能，我来证明一下。

## 工具

- 用了公司项目内置的 API 来保证每次测试的动画内容一致；

- 使用 Chrome Dev-tools - FPS Meter 来显示实时性能；

    ![fps_meter.png](/images/compare_animation_performance/fps_meter.png)

- 使用 CPU performance limiting setting.  (I use 20x slow down to maximize the difference) 限制 CPU 性能扩大对比差距；

    ![cpu_perfermence.png](/images/compare_animation_performance/cpu_perfermence.png)
    
- 同时运行多个不同代码的项目的方法 (A little trick to run these two different code simultaneously):

  1. `npm start` to run one type of codes, and load it in Chrome Tab 1
  2. change the line we need to compare
  3. `$ gulp; $ npm start` to run the another one and load it in Chrome Tab 2
  4. do NOT reload the Tab 1, thus it still run the old js file


- Chrome 还提供了录制功能来详细对比性能时间线：[Analyzing Runtime Performance](https://developers.google.com/web/tools/chrome-devtools/evaluate-performance/?hl=zh-cn)




## The result

![compare_result.png](/images/compare_animation_performance/compare_result.png)

左侧使用 `requestAnimationFrame` ，右侧使用 `setTimeout` 效果很明显。右上角，一个 30 FPS，一个 18 FPS。