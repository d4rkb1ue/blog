---
title: isNaN 也是个大坑
date: 2017-06-12 12:09:53
tags: [JavaScript]
---

> The isNaN() function determines whether a value is NaN or not. Note: coercion inside the isNaN function has interesting rules; you may alternatively want to use Number.isNaN(), as defined in ECMAScript 2015, or you can use typeof to determine if the value is Not-A-Number.


# Interesting?

```js
isNaN(NaN);       // true
isNaN(undefined); // true !!! WTF?
isNaN({});        // true !!! WTF?

isNaN('37');      // false: "37" is converted to the number 37 which is not NaN
isNaN('');        // false: the empty string is converted to 0 which is not NaN
isNaN('blabla');  // true, WTF?! parseInt("blabla") is 123 but Number("blabla") is NaN 
```

# Math.isNaN() is way more reliable

> The Number.isNaN() method determines whether the passed value is NaN and its type is Number. It is a more robust version of the original, global isNaN().

```js
Number.isNaN(NaN);        // true
Number.isNaN(0 / 0);      // true

Number.isNaN('NaN');      // false
Number.isNaN(undefined);  // false
Number.isNaN({});         // false
Number.isNaN('blabla');   // false
```

**So, never use `isNaN()`, use `Number.isNaN()` instead.**