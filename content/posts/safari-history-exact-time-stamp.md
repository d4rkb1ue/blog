---
title: Safari on Mac check history EXACT time stamp
date: 2016-07-23 02:45:58
tags: [macOS, Tools]
---

# One Line

```
ls -ogtrT ~/Library/Caches/Metadata/Safari/History/
```


# Explanation

```
-o: do not list group information
-g: but do not list owner
-t: sort by time(Last first)
-r: reverse(so -tr is Last last)
-T: time style = "MM DD hh:mm:ss YYYY"
```

*从今天开始试试英文Blog :P*