---
title: Chrome Console 过滤器黑名单
date: 2017-06-09 11:24:36
tags: [Chrome, Web]
---

别人的库频繁报错怎么办，让人心情很不好。外部引入的库比如 .js lib 或者 node_modules 里面的库，无法修改的时候。

是 node_modules 内部的库报错，过滤器很强大，看起来好像是白名单，其实加一个 `!` 就可以实现黑名单。像这样：

```
!./node_modules/mlz_student/build/js/index.js
```

就可以屏蔽掉所有含有这个关键词的 log 了！



比如，

![chrome_dev_tools_console_filter_blacklist_mass.png](/images/chrome_dev_tools_console_filter_blacklist/chrome_dev_tools_console_filter_blacklist_mass.png)



![chrome_dev_tools_console_filter_blacklist_clean.png](/images/chrome_dev_tools_console_filter_blacklist/chrome_dev_tools_console_filter_blacklist_clean.png)