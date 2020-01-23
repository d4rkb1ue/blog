---
title: diff typeof & '!=='
date: 2017-05-03 23:51:31
tags: [JavaScript]
---


> `typeof` allows the identifier to never have been declared before.

So it’s safer in that regard:

```js
if (typeof neverDeclared === "undefined"); 
//no errors

if (neverDeclared === null);
//throws ReferenceError: neverDeclared is not defined
```



---

# Ref

- [typeof-undefined-vs-null](http://stackoverflow.com/questions/2703102/typeof-undefined-vs-null)