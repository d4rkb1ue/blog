---
title: Javascript Puzzles or Jokes
date: 2017-02-27 22:05:59
tags: [JavaScript]
---

Just for fun. 

- 1 - - 1 === 2
- 1.toString()
- 0.8 - 0.6 !== 0.2
- [] + [] === ""
- [] !== []
- [] + {}
- {} + []
- {1} + {}
- parseInt(0.0000008)




# 1 - - 1
```js
1 - - 1 // 2
1 - - - - - - - - 1 // 2
```

1 - (-1)
1 - (-(-(-(-1))))

# 1.toString()
```js
1.toString(); // error
1..toString(); // "1"
```

`1.` must be a number. `1` will be parsed as label, and it's illegal.

# 0.8 - 0.6 !== 0.2
```js
0.2 - 0.1 === 0.1; // true
0.8 - 0.6 === 0.2; // false
```


floating point number calculation precision

toString(16): show int in hexadecimal format
```js
0.2.toString(16); // "0.33333333333334"
0.1.toString(16); // "0.1999999999999a"
(0.8 - 0.6).toString(16); // "0.33333333333338"
(0.2 - 0.1).toString(16); // "0.1999999999999a"
```

# [] + [] === ""
```js
[] + [] === ""; // true
```

`[]` is an Object,  `+` will force the object become a string. So,
```js
[].toString(); // ""
```

# [] !== []
```
[] === []; // false
```

first `[]` is an Object, and 2nd `[]` is another Object. They just share the same parent(prototype).

# [] + {}
```js
[] + {}; // "[object Object]" 
{} + {}; // "[object Object][object Object]"
{} + [] === 0; // true
({} + []); // "[object Object]"
```

`[]` is array. `{}` is object. `+` will force them become string. So, `[] -> ""`, `{} -> [object Object]`;

so `{...}` can be either parsed as Object or as Code Block. 

But if statement start with `{`, it will be parsed as **BLOCK** 
```js
{
// empty block here
}
+[] // same as Number([]), 0
```

`{} + {}`: for some reason, this two guys were parsed as object again...

`({} + [])`: force the `{}` to be parsed as Object


# {1}
```js
{1}; // 1
{1} + {2}; // error
1 + {}; // "1[object Object]"
{1} + {}; // NaN
{} + {1}; // error
{} + 1 === 1; // true
{1} + 2 === 2; // true
1 + {2}; // error
{} + '1' === 1; // true
```
 

`{1};` : code block. same as `1`(a number)

`{1} + {2}`: both code block. so the `nothing.. + nothing..` is illegal

`1 + {}`: `{}` -> string. The statment can only be parsed as `number + object`, `number + {code block}` is unacceptable.

`{1} + {}`: `{1}` is code block. So it get ignored. just gone. `+{}` === `Number({})` === `NaN`

`{} + {1}`: both code block. `({1}) // error`: `{0}` can only parsed as code block. so same as `{1} + {2}`

`{1} + 1 === 1` === `{} + 1 === 1` === `+1 === 1`  

`1 + {2}`: 1+ code block, error

`{} + '1' === 1`: 

```js
typeof({} + '1'); // "string"
typeof(+ '1'); // "number"
```

`{}` just gone. `+` will let the `'1'` become number. 

So,
```js
{} + 1; // 1, {} just gone
{1} + 2; // 2, {1} just gone
{} + 'a'; // NaN, + force the 'a' become a number, aka Number('a')
```

# parseInt(0.0000008) === 8
```js
parseInt(0.0000008); // 8
parseInt(0.000008); // 0
```

```js
0.0000008; // 8e-7
0.000008; // 0.000008
```

when `parseInt()` met a non-number character, it **NOT** throw an error, just return what it has before. In `8e-7`, is "8"


---

# Ref

- [Why does {} + [] return 0 in Javascript?](http://stackoverflow.com/questions/11939044/why-does-return-0-in-javascript)

- [各个编程语言都有哪些「黑点」？](https://www.zhihu.com/question/53584423/answer/135635766)

- [More Fun :)](http://javascript-puzzlers.herokuapp.com)
