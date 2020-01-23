---
title: 修复 Hexo 博客 Next 主题无法载入
date: 2016-11-12 23:51:18
tags: [Tools, Hexo, Blog]
---

# Error

刚刚遇到的问题，如往常一样执行

```
hexo clean
hexo d -g
```

重新部署的时候莫名出现`vendors`下的css, js资源无法载入问题。
而在`public`文件夹下其实`vendors`文件夹及其文件是正常存在的，权限也正常。

- *这个问题很费解，原因没找到*



# Solution

修改`blog/themes/hexo-theme-next/_config.yml`文件中：
```
...
vendors:
  # Internal path prefix. Please do not edit it.
  # _internal: vendors 将此行注释，并改为下面的样子
  _internal: lib
...
```

- 解释

    将静态文件地址从`public/vendors`改到`public/lib`。


