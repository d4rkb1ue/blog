---
title: JavaScript 继承机制-1-构造函数和亲子鉴定
date: 2016-06-08 03:17:30
tags: [JavaScript]
---

*本节介绍对象的4种创建方式，不涉及继承。*

## 1. 最简单的继承方式
如函数：
```js
function Cat(name,color){
　　　　return {
　　　　　　name:name,
　　　　　　color:color
　　　　}
　　}
```
这可以被看作是一个基本的构造函数。调用方式为：
```js
var cat1 = Cat("大毛","黄色");
```

## 2. 引入this

进阶一下，如果包含this的函数会自动被当作是一个构造函数，如：
```js
function Cat(name,color){
　　　　this.name=name;
　　　　this.color=color;
　　}
```

这时，调用方式被规定为

```js
var cat1 = new Cat("大毛","黄色");
```

这两个函数等效的话，那么**`new`操作符可以被看作是**：

>1. 创建一个空`Obj: {}` 之后把指向这个Obj的指针作为构造函数的`this`参数。

>2. `Cat.apply(this,...)`

## 两种方式的差别
### 1. 对生成的`cat1`赋了一个`constructor`的值。

调用
```js
cat1.constructor
```

第一种方式返回：
```js
Object() { [native code] }
```

第二种方式返回：
```js
function Cat(name,color){… //即第二个构造函数
```

### 2. instanceof  操作符

第一种：
```js
cat1 instanceof Cat; //false
```
第二种：
```js
cat1 instanceof Cat; //true
```

### 第二种方式的弊端：浪费内存

为Cat对象添加一个不变的属性”type”和方法eat，如：
```js
function Cat(name,color){
　　　　this.name = name;
　　　　this.color = color;
　　　　this.type = "猫科动物";
　　　　this.eat = function(){alert("吃老鼠");};
　　}
```

调用2次，产生2个对象：
```js
var cat1 = new Cat("大毛","黄色");
var cat2 = new Cat ("二毛","黑色");
```

比较其重复属性：
```js
cat1.type === cat2.type; //true //字符串只有一个，猜测应该是首先把这个string实例化,指针都赋给2个对象
cat1.eat === cat2.eat; //false //但是方法被重复出现了
```

于是，引入
## 3. Prototype模式
改动上面的`constructor`为：
```js
function Cat(name,color){
　　　this.name = name;
　　　this.color = color;
}
Cat.prototype.type = "猫科动物";
Cat.prototype.eat = function(){alert("吃老鼠")};
```

调用2次，产生2个对象。调用后测试：
```js
cat1.eat == cat2.eat; //true
```

### Prototype模式下的指针到底怎么指
在这时如果修改`cat1.eat`为其他，并不影响`cat2.eat`和`Cat.prototype.eat`。并且调用`cat1.eat`也会指向新的值。再次执行`new Cat`也依然会指向`Cat.prototype.eat`。

猜测在调用一个对象的属性的时候，会首先查看自身是否有这个属性，没有的话就想上找，找他的prototype是否有。依次向上。验证：

```js
‘eat’ in cat1 //true cat1有’eat’这个属性,不管是不是本地属性

cat1.hasOwnProperty('eat'); //false 但是这个属性并不是她自己的,是继承自prototype对象的属性

cat1.eat = function ddd(){}; //为cat1.eat赋一个独立的值。

cat1.hasOwnProperty('eat'); //true 现在是他自己的了

cat2.hasOwnProperty('eat'); //false 这件事cat2并不知情

cat1.prototype === cat2.prototype; //true 但是他们还是好兄弟

cat1 instanceof Cat; //true
```

## 各种亲子鉴定的函数

### 1. constructor
```js
cat1.constructor == Cat; //true
cat1.constructor == Object; //false
```

### 2. instanceof
```js
cat1 instanceof Cat; //true
cat1 instanceof Object; //true
```

### 3. prototype.isPrototypeOf
```js
Cat.prototype.isPrototypeOf(cat1); //true
Object.prototype.isPrototypeOf(cat1); //true
```

---
## 参考
[Javascript 面向对象编程（一）：封装 @阮一峰](
http://www.ruanyifeng.com/blog/2010/05/object-oriented_javascript_encapsulation.html)

[Javascript继承机制的设计思想 @阮一峰](http://www.ruanyifeng.com/blog/2011/06/designing_ideas_of_inheritance_mechanism_in_javascript.html)
