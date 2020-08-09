---
title: 同一行中固定宽度 div 和响应式宽度 div 的配合
date: 2016-05-04 21:43:45
tags: [Web, CSS]
---

# 目标

简单说就是在一行里面希望放置2个 `div`。

- 其中1个固定在一侧，并且具有固定的大小

- 另外那个占据这一行剩余的所有空间



# 思路1 inline-block

- 使用 auto 宽度，不可行

- 使用百分比，不可行

- 使用js检测宽度之后用 `$(window).width - fix_another_width - other_padding_or_margin` 动态生成宽度，可行，但是一点也不优雅。

# 思路2 不要使用`inline-block`，改为`float`

对于

```html
<div id="container">
    <div id="DivB">b</div>
    <div id="DivA">a</div>
</div>
```

使用CSS：

```css
#container {
    /* 这行是stackoverflow给出的答案 */
    /* 溢出操作，我觉得没什么必要，一旦溢出也不符合要求，隐藏掉无异于掩耳盗铃 */
    overflow: hidden;
}
#DivA {
    overflow: hidden;
}
#DivB {
    float: right;
    width: 100px;
}
```

# 参考

[Dynamic width with inline-block @StackOverflow](http://stackoverflow.com/questions/6931581/dynamic-width-with-inline-block)
