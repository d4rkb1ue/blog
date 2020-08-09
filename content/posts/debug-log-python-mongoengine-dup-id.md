---
title: "Debug 日志 - Python Mongoengine Dup ID"
date: 2020-08-09T01:16:34-07:00
tags: ["debug", "python"]
---

## 需求和实现

需求是要实现 ID 递增, 一开始这么实现. 

```py
from mongoengine import *
class MyModel:
    name = StringField(primary_key=True, required=True)
	def clean():
		cnt = MyModel.objects.count()
		self.name = "Prefix" + str(cnt+1)
```

但是在, 多线程下（例如 websever 根据用户请求创建 `MyModel`）发现会出现 `Dup ID` 的报错. 于是我们加上锁, 

```py
_lock = threading.Lock()
def clean():
	with _lock:
		cnt = MyModel.objects.count()
		self.name = "Prefix" + str(cnt+1)
```

## 测试发现问题

测试下, 

```py
def test_create_regen_name():
    st = set()
    with concurrent.futures.ThreadPoolExecutor(max_workers=5) as executor:
        todos = {executor.submit(
            MyModel.objects.create) for _ in range(10)}
        for future in concurrent.futures.as_completed(todos):
            st.add(future.result()['name'])
    assert len(st) == 10
```

单元测试都是用 mongomock 的, 测试通过. 

**但是**在集成测试里, 没有用 mongomock 而是一个真正的空的 mongo 数据库, 却会报错!

## 原因

因为 `clean` 是个在 mongoengine `save` 前会 call 的 hook. 于是在对着真的、空的 mongo 的时候, 出现了这样的线程间 conflicts, 

```diff
Time		Thread1			    Thread2
+0			enter save()		
-1							    enter save()
+2			enter clean()
-3							    enter clean() 被 lock
+4			cnt = 0
+5			release lock
+		(*but not save yet*)
-6							    unlock
-7							    exec clean()
-6							    cnt = 0
+7			return to save()
+    (obj with _id=0 created)
-8							    releae lock
-9							    return to save()
-				                (dup ID error since try to save _id=0)
```

**原因是 `save()` 是不在 lock 中的. ** `save` 是 mongoengine 的内置行为. 

那为什么 mongomock 就 OK 呢? 我猜原因大概是 mongomock 永远是即时操作, 无法提供对并发的测试. 即, 当clean 后会超快的被 save 以至于都来不及 swith thread. 

## 正确的实现方式

这样的需求, 其实应该, 

在 MongoDB 创建一个独立的 `collection`, 独立的 `doc`, 像是这样. 

```py
{
    '_id'   : 'UNIQUE COUNT DOCUMENT IDENTIFIER',
    'COUNT' : 0,
    'NOTES' : 'Increment COUNT using findAndModify to ensure that the COUNT field will be incremented atomically with the fetch of this document',
}

```

然后用这样的代码去得到一个 seq number, 

```js
counter = db.uniqueIdentifierCounter.findAndModify({
    query: { _id: 'UNIQUE COUNT DOCUMENT IDENTIFIER' },
    update: {
        $inc: { COUNT: 1 },
    },
    writeConcern: 'majority'
})

db.mymodel.insert({
  _id: counter['_id'],
})
```

`findAndModify` 保证了 `count++` 操作的原子性. 

## Ref.

1. [Generating Globally Unique Identifiers for Use with MongoDB | MongoDB Blog](https://www.mongodb.com/blog/post/generating-globally-unique-identifiers-for-use-with-mongodb)
2. [mysql - How do you implement an auto-incrementing primary ID in MongoDB? - Stack Overflow](https://stackoverflow.com/questions/4356993/how-do-you-implement-an-auto-incrementing-primary-id-in-mongodb)
3. [python - Pymongo find and modify - Stack Overflow](https://stackoverflow.com/questions/23368575/pymongo-find-and-modify/23369162)

