---
title: 整理曲库整理到一处
date: 2019-01-10 23:37:52
tags: ['Tools']
---

研究整理把所有喜欢的歌曲整理到一个 csv 中，

# Netease Music
> 使用 Chrome+油猴脚本 [网易云音乐怎么导出歌单？ - 知乎](https://www.zhihu.com/question/31816805/answer/347366850)


- [导出网易云音乐歌单](https://greasyfork.org/zh-CN/scripts/39807-%E5%AF%BC%E5%87%BA%E7%BD%91%E6%98%93%E4%BA%91%E9%9F%B3%E4%B9%90%E6%AD%8C%E5%8D%95)

每次需要等待几秒按钮才会刷新出来。**切换到新的歌单需要刷新。**

# Douban FM

```js
let titles = [];
document.querySelectorAll('#app > div > div.explore > div.mine-page > div.section-content > div > div.container > ul > li > div.top > div.titles > h3').forEach(a => titles.push(a.innerText));

// 只选择第一个歌手，方便对齐
let artists = [];
document.querySelectorAll('#app > div > div.explore > div.mine-page > div.section-content > div > div.container > ul > li > div.top > div.titles > p > span > a:first-child').forEach(a => artists.push(a.innerText))
```

Chrome console 里自带了一个全局函数`copy`，可以直接保存任何变量到剪切板例如，
```js
copy(titles);
```

用 Sublime 批处理 JSON 得到纯文本，同理 `copy(artists)`.

# Spotify
先将 fav songs 保存为一个 playlist（stared 不能被直接读取）, 然后使用

- [GitHub - watsonbox/exportify: Export Spotify playlists using the Web API](https://github.com/watsonbox/exportify)

## Apple Music iTunes

打开 iTunes CMD+A 全选所有歌曲。打开 Numbers，新建一个表格，复制。