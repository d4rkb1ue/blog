---
title: "测试替身 - Test Double"
date: 2020-09-01T02:19:57-07:00
tags: ["test", "coding", "python"]
---


1. 做测试的时候我们希望避免副作用。谁都不希望执行一遍测试，导致数据库塞满垃圾数据。
2. 我们还希望可以控制变量。希望在验证单一模块的时候不被其他潜在的坏模块/坏网络环境影响。在控制变量的时候，需要控制被替换模块的输入输出。尽量仿真。
3. 当然顺便可以加速测试避免做大批量计算和 IO，节约资源。

既然是测试，那么被测单元就是本身，但是我们要替换掉所有围着被测单元的其他环境。比如数据库相关的 lib，模块，网络模块，文件读写 lib 等等。这些用来承担模拟环境，替换真东西的假东西就是测试替身。

于是实现替身有这些方式。

## Fake object

最通用的情况下，可以自己造一个完全自定义的 `Fake object`。比如 patch 现存的一个 `lib`，自己去手写应该有什么假函数 - 该函数应该在什么被测单元输入时返回什么（即提供被测单元**间接输入**），应在在什么时候调用什么（即提供被测单元**间接输出**）。


实现上，可以是纯粹 echo 回音壁，或者是带计算+反射功能的哈哈镜（类似于一个 `lambda function`）。例如为了避免读写真数据库，用个简单的 `list`/`dict` 来记录状态的 `data model` - `moke object`。这是最灵活也是最麻烦的方式。

## 简单的 stub 桩

但如果是非常简单的替身，比如被测单元怎么调用都在返回/输出一样的东西，可以用 `stub` 桩模块。这样的就是**间接输入**。因为有些输入不是一开始以参数形式传入函数的，而是在运行通过 query 数据库，文件，远程 API 获取实时动态状态，以及为了接耦，安全，体积考虑单独获取的静态信息。

```python3
datetime = Mock()
datetime.today.return_value = tuesday

datetime.today()
# tuesday
datetime.today(whatever_para=1)
# tuesday
```

## Mock object - 懒人版的 Fake object

如果需求稍微高点，希望**对一些指定的输入返回输出**，可以尝试 `Mock object`，这是一种懒人版的 `Fake object`。如果不想手写里面的状态管理，或者状态很简单，或者我知道我就会只用指定的一些输入去计算。

举个例子，我要替换掉一个求导公式，如果我知道我在 test 中只有 2 种 `call` 这个 `object` 的输入，一个是 `x^2` 一个是 `ln(x)` 那我直接用个静态的 `dict` 来返回值就好了， 不用写一遍求导的完整公式。

```python
output = {
    "x^2": "2x",
    "ln(x)": "ln(x)",
}
```

## Mock object - 间接输出

反过来，如果对返回值没要求，却对**间接输出**感兴趣，比如对被测模块怎么`call` 别人十分在意，那就用永远都不会报错的 `(Magic) Mock object` - 这就像一个厚厚软软的白雪地一样，任由被测者随意在上面印出印记，只是个忠实的记录者。也叫做拥有 `Lazy Attributes and Methods` 的 `Mock object`。它的方法/属性在你 `call` 它的时候被产生，不会报错。

```python3
>>> from unittest.mock import Mock
>>> mock = Mock()
>>> mock.some_attribute
<Mock name='mock.some_attribute' id='4394778696'>
>>> mock.do_something()
<Mock name='mock.do_something()' id='4394778920'>
```
（以及可以看到，`mock` 的方法/属性 还是 `mock` 保证了可以递归的使用 `mock`）


于是可以事后通过 `assert` 这个 `object` 被 `call` 过多少次，以及被怎么（用什么 `parameter`）`call` 的。

```python3
>>> from unittest.mock import Mock

>>> json = Mock()
>>> json.loads(‘{“key”: “value”}’)
<Mock name=‘mock.loads()’ id=‘4391026640’>

>>> # Number of times you called loads():
… json.loads.call_count
1
>>> # The last loads() call:
… json.loads.call_args
call(‘{“key”: “value”}’)
>>> # List of loads() calls:
… json.loads.call_args_list
[call(‘{“key”: “value”}’)]
>>> # List of calls to json’s methods (recursively):
… json.method_calls
[call.loads(‘{“key”: “value”}’)]
```

## Test Spy - 黑盒子记录仪

如果间接输出逻辑很复杂，可以用高阶一些的 `Test Spy`。打比方，被测者找我要了个一个盒子，我给的同时在里面贴上一个摄像头偷偷录下这个盒子里都被装过什么，啥时候装的，交给过什么人。并且在合适的时候给予一定的反馈，尽量不露馅。

## 相关概念 Patcher

`Patcher` 不是测试替身。只是代表替换动作的抽象，或者理解为千斤顶。帮助你把原始 `object` 替换成假替身的所需的工具。很多时候可以直接简单的赋值，但是如果无法插入被测模块 `import` 的流程，那就需要借助别的工具啦。

## 相关概念 Fixture

`Fixture` 也不是测试替身，而是声明一个数据状态，这个状态可被继承/组合。和上面这些 `moker` 配合使用，可以用声明一个函数表示如何进入这个状态，以及退出这个状态要销毁什么。比如，
1. `Fixture1` 代表了一个 `databse 被替换的状态`，进入状态是使用 `Patcher` 对 `import` 的 `lib` 进行替换，退出此状态是换回去。
2. 再比如，在第一个例子里，我为了避免读写数据库造的假 `data model`，但是在测试真的 `data model` **读**逻辑对不对的时候，我可以声明一个含有提前配置好的数据状态，比如有个 user，进入此状态需要直接把假数据塞进空数据库里。*当然可以选择 `mock database access` 的 `SDK`。但是真数据库假数据更有说服力（减少了自己写的变量，毕竟写的 `mock` 也可能自己有问题）*

当然更多时候是在声明在运行时存在 `memory` 里的数据状态，比如假装这个指针后面应该有这个数据，直接塞进内存里。

## Refs.

1. [Test double - Wikipedia](https://en.wikipedia.org/wiki/Test_double)
2. [Test Double at XUnitPatterns.com](http://xunitpatterns.com/Test%20Double.html)