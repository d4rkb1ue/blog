---
title: "在 Chrome Devtools 中调试本地代码"
date: 2017-03-21 19:05:19
tags: [JavaScript, Tools]
---

创建这样的文档结构

```sh
$ find . -print | sed -e 's;[^/]*/;|____;g;s;____|; |;g'
.
|____index.html
|____partition.js
```

partition.js 是要挑试的 js 代码，index.html 是用来辅助以运行在 Chrome 中。

index.html 引用 js 即可。

```html
<!doctype html>
<html>
    <head>
        <script src="partition.js"></script>
    </head>
    <body></body>
</html>
```

然后将 index.html 拖入 Chrome 中（以 Chrome 打开也一样）。
可以在 Source 选项卡中左侧打开文件树形图。可以修改直接在 Chrome 中保存！

然后进入 Console 面板 (macOS 下可用 `Command + [` 和 `Command + ]` 来作用切换面板) 愉快的运行吧。当然，这个（些） js 文件都已经在加载时被执行了一遍。



![/images/debug-javascript-chrome-devtools.png](/images/debug-javascript-chrome-devtools.png)


*macOS 的 `tree`:*
```
find . -print | sed -e 's;[^/]*/;|____;g;s;____|; |;g'
```

[by OSXDaily](http://osxdaily.com/2016/09/09/view-folder-tree-terminal-mac-os-tree-equivalent/)

