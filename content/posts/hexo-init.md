---
title: Hexo 初始化笔记
date: 2016-04-22 06:32:48
tags: [Tools, Blog]
---


# TODO
 
- [NexT说明](http://theme-next.iissnan.com/theme-settings.html#reward)

- 添加About Me

- RSS订阅

- 头部添加tag和图片的尝试

- Sitemap站点地图



使用了[NexT](http://theme-next.iissnan.com/getting-started.html)主题。执行主题的安装说明。轻松的添加多说！



# 流程注意
1. push前先 `hexo g` 生成静态文件
2. 安装hexo-deployer-git, 部署方式见官方网站, `hexo d` 部署
3. 更换主题后需要先 `hexo clean` 清除静态文件，再`g`, `d`
4. `d`,`g`命令可以合为一行 `hexo d -g`


# 问题和解决

## 无法git CNAME文件

CNAME文件不会被上传。

### 解决

CNAME需放在source文件夹下。事实上，所有放在source/根目录的文件都会原样上传。

## 不支持 `#Title` (无空格)渲染

### 解决方式

对存在无空格使用#标记的md，用Sublime或VS Code执行全局替换：

Find:

`^(#+)`

Replace:

`$1 `

注意$1之后有空格.

### 说明
可以匹配所有#,##,###,… 并且在之后加上一个” “(空格)。

应对不支持”#Title”(无空格)渲染的~~垃圾~~引擎比如hexo用的。

`^(#+)` 用 `()` 括上的部分在Replace里面经`$`引用。第一个`()`就是`$1`

## 界面为德语
_config.yml: `language: zh-Hans` 而不是 `language: zh-CN` 
`CN` 会导致界面为德语。“Veröffentlicht“

尝试使用[hexo-renderer-markdown-it](https://github.com/celsomiranda/hexo-renderer-markdown-it)来代替原先的hexo-renderer-marked, 然而并不能解决问题

## 太长的Description
NexT默认每个文章都在主页里完整显示，如果需要自定义显示的内容。可在front-matter头中定义description。
```yaml
---
title: JavaScript Array.prototype.sort() 可以 call 哪些对象？
date: 2016-04-18 05:51:34
description: 对于从document中获取的nodeList,想要对它进行排序，实时显示出来。
---
```

偷懒的方式：
在文章合适的位置插入

```
<!-- more -->
```

即可！



**需要注意头部不支持markdown语法！**

---
# 参考
- [使用Github与Hexo搭建blog](http://mattshma.github.io/2015/05/15/github_hexo/)

- [使用GitHub和Hexo搭建免费静态Blog](http://wsgzao.github.io/post/hexo-guide/)

- [hexo搭建静态博客以及优化](http://code.wileam.com/build-a-hexo-blog-and-optimize/)

