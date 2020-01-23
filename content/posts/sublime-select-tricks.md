---
title: Sublime Select Tricks
date: 2017-02-18 23:56:53
tags: [Tools]
---

# 问题

在选择的时候遇到了一些问题，如下面的代码
```java
if (max && p.compareTo(ret) > 0) ret = p;
```

我在选择变量`p`的时候，`shift`选中`p`然后`Command + D`，后果就是同时选中了`compareTo`中的`p`。

![sublime-select-tricks](/images/sublime-select-tricks/sublime-select-tricks.png)



## 解决方案1

选中`p`之后，`Command + D`选中`compareTo`中的`p`，此时`Command + K`，`Command + D`可以取消选择上个选中的`p`，即`compareTo`中的`p`，并选中下一个`p`。

不过这个方法很麻烦。其实 Sublime 是可以识别变量的。

## 解决方案2

不要选中`p`！
不要选中`p`！
不要选中`p`！

直接将光标放在`p`之前或之后，`Command + D`即可自动选择变量。


- 还有一个关于选择的快捷键，`Command + U` 可以撤销最后一个选择。

# 其他快捷键

- 选择全部 token `Ctrl + Command + G`

- HTML 中选中一对标签（需要 Emmet） `Command + Shift + K`

---

# Reference

- [sublimetext2 - Sublime Text: Select all instances of a variable and edit variable name - Stack Overflow](http://stackoverflow.com/questions/16844657/sublime-text-select-all-instances-of-a-variable-and-edit-variable-name)

- [http://www.sublimetext.com/docs/selection](http://www.sublimetext.com/docs/selection)

