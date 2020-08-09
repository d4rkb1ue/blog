---
title: VSCode 调试例子
date: 2016-06-07 22:34:15
tags: [JavaScript, Tools]
---

```js
/*
保存本js为文件。按 F5 可以启动执行。选择 Node.js 的执行环境。
在生成的 launch.json 中修改 

"program": "${workspaceRoot}/js.js",

这样以来，就可以在调试中启动js.js了。

选择最下面的debug界面，可以动态追踪变量。
*/

var rt = test();

function mySort(dom, func) {
    var num = dom.length;
    var i, j = 0;
    var tmp;
    var ret;
    for (i = 0; i + 1 < num; i++) {
        for (j = i + 1; j < num; j++) {
            if ( ret = func(dom[i], dom[j]) < 0) {
                tmp = dom[i].innerText;
                dom[i].innerText = dom[j].innerText;
                dom[j].innerText = tmp;
            }
        }
    }
    return dom;
};


function test() {

    var ret = mySort(["Scheme","JavaScript","Python","Ruby","Haskell"], function (a, b) {
        return a > b? 1 : -1;
    })

    // var ret =  mySort([3, 2, 4], function (a, b) {
    //     return a - b;
    // });
    console.log(ret);
}

/*
mySort.call(e,commm); 是不对的！
call 的第一个参数是this！应该这样：
mySort.call(null,e,commm)
*/


function mySort(dom, func) {
    var num = dom.length;
    var i, j = 0;
    var tmp;
    var ret;
    for (i = 0; i + 1 < num; i++) {
        for (j = i + 1; j < num; j++) {
            if ( ret = func(dom[i], dom[j]) < 0) {
                tmp = dom[i].innerText;
                dom[i].innerText = dom[j].innerText;
                dom[j].innerText = tmp;
            }
        }
    }
    return dom;
};

mySort(e,function(a,b){
return a.innerText < b.innerText ? 1:-1;
})
```
