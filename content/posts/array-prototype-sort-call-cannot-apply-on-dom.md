---
title: JavaScript Array.prototype.sort() 可以 call 哪些对象？
date: 2016-04-18 05:51:34
tags: [JavaScript, Web]
---


## 问题背景
对于从`document`中获取的`nodeList`:
```html
[<li>​JavaScript​</li>​, <li>​Swift​</li>​, 
<li>​HTML​</li>​, <li>​ANSI C​</li>​, <li>​CSS​</li>​, <li>​DirectX​</li>​]
```
想要对它进行排序，实时显示出来。

**要注意它不是一个 `Array` !**
```js
cs instanceof Array; //false
```

~~很费解啊。~~

于是我在代码里使用了for循环改为一个array。

更简便的方式是：@[stackoverflow](http://stackoverflow.com/questions/222841/most-efficient-way-to-convert-an-htmlcollection-to-an-array)
```js
var arr = Array.prototype.slice.call( htmlCollection );
// 或，更简单的方式：
var arr = [].slice.call(htmlCollection);
```

但是我发现一个问题，不做拷贝直接对原DOM的排序无效：

```js
[].sort.call([3,4,1]); //[1, 3, 4] 正常
[].forEach.call(document.getElementById('test-list').children,function(ee){console.log(ee);});
//正常输出所有的孩子

[].sort.call([3,4,1],function(a,b){console.log(a+","+b)}); 
//3,4; 4,1; [3, 4, 1]; 正常遍历执行。

var e = document.getElementById('test-list').children;

[].sort.call(e,function(a,b){console.log(a+","+b)});
// 但是这个就输出不了任何东西！
```

## 整理问题的格式发到[zhihu](https://www.zhihu.com/question/43452733)

我想使用 Array.prototype.sort() 对DOM的Element进行排序。

HTML如下
```html
<ol id="test-list">
    <li class="lang">Scheme</li>
    <li class="lang">JavaScript</li>
    <li class="lang">Python</li>
    <li class="lang">Ruby</li>
    <li class="lang">Haskell</li>
</ol>
```

我做了如下尝试。
```js
var e = document.getElementById('test-list').children;

[].forEach.call(e,function(ee){
console.log(ee);
}); //正常输出所有的孩子

[].sort.call([3,4,1],function(a,b){
console.log(a+","+b);
}); //3,4; 4,1; [3, 4, 1]; 正常遍历执行。


[].sort.call(e,function(a,b){
console.log(a+","+b);
}); // 但是这个就输出不了任何东西！
```

我根据 sort() 对于普通Array的动作的log，猜测 sort() 的内部实现是逐二对比。而且，sort() 的 API 说明里也举了一个例子，证明是可以用于对象属性的对比的:
```js
var items = [
  { name: 'Edward', value: 21 },
  { name: 'Sharpe', value: 37 },
  { name: 'And', value: 45 },
  { name: 'The', value: -12 },
  { name: 'Magnetic' },
  { name: 'Zeros', value: 37 }
];
items.sort(function (a, b) {
  if (a.value > b.value) {
    return 1;
  }
  if (a.value < b.value) {
    return -1;
  }
  // a must be equal to b
  return 0;
});
```

那么为什么call(HTMLLIElement) 就不会开始遍历调用？

## 相关探索&强制解决方案
我发现一个小细节
```js
e[0].innerText = 232; //<li class="lang">232</li>
//但是！
e[0] = "sds"; //<li class="lang">232</li>
e[0] = document.createElement('li'); //e的打印值依然不变
```

也就是说，不能直接对DOM的element直接赋值!于是呢，我可以这样执行：
```js
//不用[].sort，我自己用冒泡实现了一个sort
function mySort(dom, func) {
    var num = dom.length;
    var i, j;
    var tmp;
    var ret;
    for (i = 0; i + 1 < num; i++) {
        for (j = i + 1; j < num; j++) {
            if ( ret = func(dom[i], dom[j]) < 0) {
                tmp = dom[i].innerText;
                //!!!
                // 注意！此处不要写成dom[i] = dom[j]
                // 因为dom[]不可被直接赋值！
                dom[i].innerText = dom[j].innerText;
                dom[j].innerText = tmp;
            }
        }
    }
    return dom;
};

mySort(e,function(a,b){
    return a.innerText < b.innerText ? 1:-1;
});
```

于是呢，我猜测是 `sort()` 是直接操作原Array的元素，而 `HTMLLIElement` 是无法被赋值，由于某种机制（？）， `sort` 发现了这一点，于是就直接返回不管了。

## 来自[StackOverFlow的回答](http://stackoverflow.com/questions/36675401/javascript-array-prototype-sort-can-not-call-on-dom-htmllielements)

>Interesting question! Unlike Chrome, which dies silently, the latest Firefox is more helpful:
```
TypeError: HTMLCollection doesn't have an indexed property setter for '0'
```

>which makes the problem clear: you cannot apply sort to an object that doesn't have numeric property setters (because sort attempts to sort in place and fails).

问题被连接到 [Using Array.prototype.sort.call to sort a HTMLCollection](http://stackoverflow.com/questions/7059090/using-array-prototype-sort-call-to-sort-a-htmlcollection)

>It seems sort cannot handle array-like objects. This is probably because NodeList does not provide any methods to change the list, but sort sorts the array in-place.

>Update: For more information, from the specification:

```
Perform an implementation-dependent sequence of calls to the [[Get]] , [[Put]], and [[Delete]] internal methods of obj.
```

## 来自[知乎的回答](https://www.zhihu.com/question/43452733/answer/95696026?group_id=705195683509977088)

>先讨论document.getElementById('test-list').children得到的是不是数组。不是，这是一个NodeList对象，是一个类数组对象。相似的，还有一个HTMLCollection对象，它们都是host objects，受浏览器环境的控制。正如你没有办法做这样的操作： `window.document = 123` ; 你同样无法对NodeList对象和HTMLCollection对象进行操作。对于这两类对象，只能读，而不能写。那么Array.sort会做什么事呢？为了节约内存空间，javascript在排序时是采用的“in-place”的策略，就是在原数组的基础上，通过不断交换不同位置的元素来达到排序的目的。既然这个NodeList和HTMLCollection无法操作，那么sort内部对元素进行交换的操作就无法完成，所以使用Array.sort是无法对NodeList和HTMLCollection排序的。而它们本身其实是有顺序的，它们的顺序是文档中匹配节点树状顺序。

>另一方面，Array.sort是如何处理这些host objects的。从表现上来看，是根本没有进行过比较。到V8代码里去看，我没找到具体的实现方法，有一个推测，可能不对：

```c
  // %RemoveArrayHoles returns -1 if fast removal is not supported.
  var num_non_undefined = %RemoveArrayHoles(array, length);

  if (num_non_undefined == -1) {
    // The array is observed, or there were indexed accessors in the array.
    // Move array holes and undefineds to the end using a Javascript function
    // that is safe in the presence of accessors and is observable.
    num_non_undefined = SafeRemoveArrayHoles(array);
  }

  QuickSort(array, 0, num_non_undefined);
```
>这是V8 sort方法的一个片断，可能在“%RemoveArrayHoles”方法中对元素是否能够移动进行了检查，最后得到num_non_undefined = 0，使得QuickSort方法没有运算就结束了。但这只是我的猜测。

>最后，如果要实现题主的目标该怎么做呢？也很简单，先把NodeList或者HTMLCollection对象转化成普通数组

## 问题的解决办法
### 漂亮的实现
避开DOM操作。
```js
var list = document.getElementById('test-list');
var texts = Array.prototype.map.call(list.children,function(node){
    return node.innerText.trim();
});
texts.sort();
texts.forEach(function(text,i){
    list.children[i].innerText=text;
});
```
### 我的实现
拷贝出来之后再拷贝回去。
```js
var list = document.getElementById('test-list');
var sliced = [].slice.apply(list.children);
sliced.sort(function(a,b){
    return a.innerText > b.innerText ? 1 : -1;
});
//删除所有孩子
var i = list.children.length;
for(;i>0;i--){
    list.removeChild(list.children[0]);
}

//加上拍好序的孩子
for(ss of sliced){
    list.appendChild(ss);
}
```