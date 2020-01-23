---
title: Inject git commit hash on webpack
date: 2017-07-19 16:49:31
tags: [Web, Git, Webpack]
---

# Output

@ Chrome Dev-tool console
```
console.log(__VERSION__);
"da7698330a678f77............." // git commit HEAD's hash
```

You can use the DefinePlugin that will make your build info available inlined with your code:

## webpack.config.js
```js
const childProcess = require('child_process');

plugins = [
  // ...
  new webpack.DefinePlugin({
    __VERSION__: JSON.stringify(childProcess
      .execSync('git rev-list HEAD --max-count=1').toString()),
  })
];
```

## app.js
```js
if (typeof __VERSION__ === 'string') {
  (window as any).__VERSION__ = __VERSION__;
}
```


If you use typescript, append to types/index.d.ts to omit  type error
```ts
declare const __VERSION__:string;
```


# Ref
* [How can I inject a build number with webpack? - Stack Overflow](https://stackoverflow.com/questions/24663175/how-can-i-inject-a-build-number-with-webpack?answertab=oldest#tab-top)
* [list of plugins](http://webpack.github.io/docs/list-of-plugins.html#dependency-injection)