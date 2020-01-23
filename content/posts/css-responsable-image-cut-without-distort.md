---
title: 使用CSS实现响应式图片不变形裁剪
date: 2016-05-05 21:13:43
tags: [CSS, Web]
---

## 思路1. 使用overflow裁剪

大致的思想就是对图片固定高或宽，然后另一个选项为auto.
记得单独设置
```css
max-width: none; 
```

保证图片不会被裁剪/变形.
如果需要让图片居中，就设置
```css 
margin-left: -50%
```



可以让图像向右移动50%即一半啦

### 完整实例
```css
height:350px;
overflow: hidden;

max-width: none; 
margin-left: -50%;
```

### 存在的问题
在slider里，在图片滚动的时候会显示出溢出的部分

## 思路2. 使用 CSS3 特性 `object-fit`

这个特性碉堡了。
和上面的实例具有相同效果的：

```css
height:350px;
object-fit: cover;
```

设置好宽和高，图片自己就会进行裁剪和居中。

### 支持性问题

- [浏览器支持](http://caniuse.com/#feat=object-fit)
- 使用[Polyfill](https://github.com/anselmh/object-fit)来扩展支持的范围

### 参考

- [object-fit API @w3c](http://www.w3.org/TR/css3-images/#the-object-fit)
- [用一行 CSS 居中并裁剪图片 @伯乐在线](http://web.jobbole.com/82617/)

- 更多：[判断浏览器是否支持指定CSS属性和指定值](http://www.alloyteam.com/2011/10/判断浏览器是否支持指定css属性和指定值/)