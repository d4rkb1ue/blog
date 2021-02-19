---
title: "Pass 系统设计面试"
date: 2020-07-26T05:10:46-07:00
tags: ['interview']
---

## 经典问题

比如要求设计, 

1. Chat Messenger
2. Twitter Feed
3. Distributed Key-Value
4. Global Object ID

## 典型流程

解答这样的问题, 可以这样一步步边确认边回答, 

### 1. Data model/schema - 设计多种单体数据模型, 数据库关联关系

关键要考虑的数据特征是,

- 数据量
- 关联性 - 1:1, 1:N, N:N
- 读写分布
- 可变性 mutability
- 数据均匀性 - 读写均匀, 1:N?


#### 例子1 - 设计一个屏蔽词查询系统

这可以理解为就是一个 `超大 Set`. 
- 于是数据模型就很简单, 全局就一种 Data Class, 无模型间关联/关系. 
- 而这个系统中, 数据量极大, 读操作远远大于写操作, 而且基本只是增加新项目, 这对后面的 `读 API` 的设计来说是一个很好的考量点 - 毕竟读一个很少变的数据库比频繁变的数据库简单多了. 
- 不过数据显然非常不均匀, 有些 `key` 一定超级频繁, 比如问候对方家人相关的屏蔽词 - 这会影响后面 `Cache` 的设计. 

#### 例子2 - 设计一个电子银行系统

至少我们需要 `User`, `Account`, `Transaction`.
- `Account` 应该包含, `ID`, `UserIdRef`, `Balances`, `TransactionIdRefs` 
- 于是就能画出来一个 Class Diagram. 
- 这个问题的关键就在 OOD 上了, 数据量和读写分布不是关键要素, 主要是 `Transaction` 会很多, 讲究 Atomic 了. 

### 2. Traffic estimate - 估算系统中所有的数据流动

这个关系到我们的系统有多复杂. 比如设计一个购物系统可以很简单也可以很难, 就算功能简单到 12306, 只要订单足够多足够密集(春运), 那么并发性, 稳定性的要求就足够撑爆我们的系统设计. 

关键要考虑的是,

- 单个 request size
- request per sec
- 访问的特征 - 读写分布, 关联访问, 常用 Top 1-20% 的 hot data
- 突发 - 削峰用 MQ
- 应对高计算/数据库操作压力的任务
   - 要不提前准备
   - 要不排队
   - 要不牺牲点什么

#### 例子1 - 设计一个屏蔽词查询系统

呼应我们数据模型设计中提到的, 依次回答,  
- 单个 request 很小, 于是我们可以把多个 key 的 check 打包在一个 request 中, 最后的大小也不会超过一个普通的 Ethernet frame MTU 1500, 或者 IP packet 1480 Byte. 
- Request/sec 非常高. 此时可以 Do The Math 显得专业, 如果每秒有 100 人打算发篇文章, 而每个文章 500 字, 可以分词成 300 个关键词, 那么每秒就需要支持 100*300 个请求. 
- 访问特征显然绝大多数都是读, 无关联访问, 估计常用的 10% 的关键词占掉了 90% 的 request 量
- 大多数访问应该都是均匀的. 如果突发可以设计两级审核, 一轮即时审核只看 10% 的关键词, 让用户先发出去 + 一轮亡羊补牢再检查所有的关键词按需风控. 
- 这是一个纯关键词匹配问题, 没啥计算需求

可以参考 https://www.educative.io/courses/grokking-the-system-design-interview, 包括了更详细的 Do The Math 的流程. 

#### 例子3 - 设计一个全国温度收集系统

这个是我在亚麻面试中遇到的. 说我们在全国分布了上百万个温度 sensor, 现在需要设计一个系统收集这些数据并且实时展示出来 + 历史查询功能. 

- 显然单个 request 也很小. 大约就是个 tuple `(latitude, longitude, timestamp, celsiusdegree)` 也就 20 Byte 最多了. 
- 频率和面试官确认下, 比如他说每秒汇报一次. 那么就是 1,000,000 个请求每秒了. 如果这是一个简单的 1 个中心节点直接汇聚 1,000,000 的数据点, 显然对这个中心节点的要求太高了. 于是此时可以提到, 我们可以设计一个两层的 map-reduce 架构. 中心节点只和 1,000 个二级节点相连, 每个 sensor 节点可以 hash 一下自己的位置去访问最近的一个节点. 这样就变成 1:1,000:1,000,000 的关联关系了. 每个服务器节点都至多接受来自 1,000 个其他下级节点的通信
- 还可以再提一个, 因为 sensor 节点会拓展/替换/IP 会变动, 而中间服务器节点可以 load balancing, 固定 DNS 等等, 我们最好选择 push model. sensor 节点主动去把自己的数据 push 到数据中心. scalability 会好很多. 
- 因为这显然是一个 immutable 数据模型, 我们可以用 ElasticSearch 做存储, 可以用 `latitude+longitude`, 和 `timestamp` 做 index. 
- 因为最常用的查询就是实时查询, 面试官说我们会有个网页大家随时看, 这就是 Hot Data. 那么可以在中心节点上直接在内存中放一个实时 Cache 保存这一百万个节点的当时的数字. 其实大小也很小, 20Byte * 1M 不过才 20MB 而的一个数据结构. 
- 因为提供了历史查询功能, 那么其实是有计算需求的. 和面试官明确下查询的精度是什么, 比如只要求每个 sensor 每天的 `(min, max, avg)` 那么为了避免每次都去数据库 query 一天的 86400 个数据, 再做计算, 我们可以在当地时间 0 点时计算一下当天的这些数字然后以 `{(sensor+date): (min, max, avg)}` 这样的 `key-value` 组存下来. 

### 3. 设计关键 APIs

这步也可以放在第二步. 就非常和需求耦合了, 就是设计所有增删改查的 API. 

#### 例子1 - 设计一个屏蔽词查询系统

因为我们提到因为单个 request 太小, 可以支持多个 key 在一个 request 中, 

- `check([list of word]) -> [list of boolean] // True: is blocked`
- `add([list of word])` 可以再顺嘴提一句, 这个 API 被用的频率应该很小

#### 例子3 - 设计一个全国温度收集系统

- `get_now() -> dict {location -> celsiusdegree}`
- `get_history(location, [list of date] or [date range]) -> [list of (date, min, max, avg)]` - 因为上面和面试官确认查询精度最多到 `天`
- `put([list of (latitude, longitude, timestamp, celsiusdegree)])` 也就是 sensor/二级节点汇报用的 API. 因为每个数据太小, 在二级节点汇报时用 `list` 打包下显然能大大减少总请求的数量. 

### 4. 考虑核心算法和业务性质主导的 Distribution

这个指的是, 当我们通过设计 API 把需求抽象到代码层面之后, 下面可以用数据结构和算法, 分布式设计来进一步细化我们的设计. 

#### 例子3 - 设计一个全国温度收集系统

其实对于这个例子, 刚刚已经在数据模型和数据流动中提到了关键的几点, 

1. 数据的汇总是 push model 方便 scaling
2. 使用分级汇报的方式. 二级节点把 sensor 节点的数据都汇总一遍, 把 1000 个数据点 reduce 成一个 pkg 再 push 给中心节点, 于是中心节点每秒只需要支持 1000 次 `put()` API 的调用
3. 因为读实时是最常用的 API, 直接在中心节点放个实时的 cache. 
4. cronjob 的计算下平均值把数据放在单独的数据库中, 避免重复计算. 

顺便, 我们可以分离读写的两个 server, 因为他们的特征差距很大, 天然完全分离 - `sensor -> put_server -> DB <- get_server <- user`. 

#### 例子4 - Global Object ID

这是一个超经典的问题. 即给每个 Object 分配一个全局唯一的 ID. 比如淘宝中, 每个产品一个 ID, 每个订单一个 ID. 在 Twitter 中, 每条 Twitte 一个 ID. Short-URL 每个 ID 一个 URL. 关键是, 

1. 显然在一个分布式系统中, 会有多个服务器同时分配 ID, 那么怎么保证多服务器分配不冲突的 ID? 
2. ID 需要有意义吗, 有意义的 ID 做主键好搜索好排序. 以及是不是要求时间上后面分配的 ID 一定要大于前面的? 
3. 不是绝对随机的 ID 分配会影响存取么? 如果 ID 和数据库节点绑定的话, 是不是会导致数据库节点被访问的频率不均匀? 如何配置 cache 和 locality? 
4. 分配之后呢, 在数据关联上, 有没有数据 affinity, 什么样的数据会同时被读取/搜索? 
5. 在分布上, 这些 ID 是都等读等写的吗? 比如有没有特别高频被读/写的? 

这个问题的算法就很重要了. 

1. 通过 Object 的属性 hash 出来 ID. 比如 Short-URL Original URL - `md5(url)`. 或者订单 `Order_ID == userid_productid_timestamp`. 不过也许我们并不想让 ID 是一个有逻辑的 ID, 可能会暴露数据本身, 有时我们并不想让 ID 可以被预测
2. increasing sequence number. 这对于单个 server 是最简单的方法了. 
3. 随机数字. 这个当然很简单, 不过有一些问题, 
   1. ID 长度必然有限制, 那么随机就会产生碰撞 (如果数据域太小的话，比如 8 位随机数字，其实 10,000 个 ID 就很大概率出现碰撞了), 而对于关键系统, 比如订单, 任何碰撞都是受不了的. 
   2. 再比如我们要求时间上后分配的 ID 要比前面的 ID 大方便 query. 随机无法满足这样的要求. 
4. 提前准备好批量取用. 这个是很棒的主意. 我们抽象出一个 Key Generation Service 
   1. 直接生成大量 Key 放在数据库准备好. 就可以让一个进程完成, 于是没有冲突问题. 
   2. 一开始每个 API server 有一个 Key pool, 启动时去数据库里申领几千几万个 unique ID. 创建新的订单时在自己的 pool 里面拿一个. 当用完了, 比如 30min, 再去拿一次. 这样其实每个 server 的暂停服务的时间也很短, 配合下 LB. 
   3. cornor case. 即便 server 突然断电, 也不过是浪费了一些 ID, 是可接受的.  

### 5. 各种通用优化

基本上所有的系统都可以加上. 

#### Load Balancing

**For single point of failure, uniform, consistent, scale-up.**

- 系统内部的 LB,
   1. 在 database 和 app 之间
   2. 在 API server 之间
   3. 在 worker 和 API server 之间, etc. 
   
   比如数据库就是解耦出来的一个组件, 又明确的 API 层就可以加 LB 了. API servers 之间可以用 service-mesh 服务发现来让每个组件都是高可用的. 
- 系统整体对用户间的 LB - 可以按网络模型安排多层 LB. 
   1. 首先单个 API server 本地可以先有个 Nginx 做 reverse proxy 进行 throttling 之类的保护. 
   1. 然后多个 servers 间可以用 Nginx 或者 HAProxy 做 LB/API gateway. 
   1. 那么又要给多个 L4/7 的 LB/API gateway 前面加上 L3 的 Float IP 的 LB, 用 MACVLAN, IPVLAN 什么的. 
   1. 再前面又可以有 DNS 层的 LB. DNS 直接 round-robin 或者高级的比如 Consul.io 自带健康监测/有状态 LB 算法 (Least Connection/Response time/Traffic/Round robin/Hashing) 的 DNS. 

#### Stand-by

不至于/不方便上 LB 的地方统统来个 stand-by server, 比如上面提到的 Key Generation Service 因为一致性的原因, 上 LB 太麻烦. 那就 Stand-by 一下吧. 

#### Cache

只要感觉费劲就加一层 Cache. 除了数据 Cache, 还有比如数据库的连接池也是 Cache. 花时间的地方, 大都可以用空间复杂度换时间复杂度. 

- 内存里先安排个 Cache
- API server 可以来个 Cache. 分一层就放一层 Cache. 数据库可以有自己的 Cache (Index 比如)
- 再上个 Distributed cache - Redis, Memcached
- 需要计算的, 需要 query 的, 常用的 API 统统安排上 Cache

#### 数据爆炸

随着系统用下去, 怎么保证在 10 年后系统数据超级多的时候还能顺畅运转? 

Data partition 一下, 比如
- time-based
- userid-based
- UserIP-based

分两类, 
1. 横向分, 分段分块
    - 比如屏蔽词检索. 按开头首字母各自有各自的 server. 
    - 比如订单搜索. 按不同年份有不同的 server. 
2. 纵向分, 分层分级 - 一层指向一层, 指针, 指针组, 指向指针组的指针, 像 B+ Tree. 或者 Abstract metadata 数据表树形再分布. 
    - 比如订单. 2020 年的一层, 每月的一层, 每日的一层, 每小时的... etc. 于是在 query 的时候, 一个请求会一步步转发到下一个 server. 当然也可以把这样的转发关系放在一个单独的 mapping service 里, 这个 server 的内存里就有这棵树, 可以根据时间戳直接返回应该去找哪个数据库节点. API server 直达那个节点, 避免层层转发. 
    - 比如屏蔽词检索. `T` 开头的一个问一个 server, 再看是 `TM` 开头的, 再转发, 再转发负责 `TMD` 开头的 server, 一个 Tire 一样的服务器分配. 

### 6. 收尾 Bonus - 业务性质导致可以牺牲的地方

1. 实时性/一致性/可用性 的 trade off. 比如是不是可以给用户展示 5 分钟前的数据? 
2. 顶级功能/次级功能, 高感知属性/次感知属性. 用户常用的功能优化下? 
3. 精确. 比如在温度查询的例子里, 我们想要平均值可以需要计算一天 86400 个数据的平均, 或者, 只抽取每小时第一秒的数据计算平均值. 鉴于温度不会忽上忽下, 这样稍微牺牲了精度但是只要计算 24 个数据即可. 
4. 性能. 那些地方运算多? 
5. 稳定. LB 和 Stand-by 太贵的地方放弃下? 
6. 备份. 冷备, 热备, 多地备
7. 可以异步做的高计算/高延迟步骤就异步做. 比如, 提前计算好每日的平均温度. 
8. 感觉冲突/互相影响就分开, 中间加个同步机制. 
9.  服务间 或 服务和 client 间的同步问题. pull model, push model, 或者混合.


## Refs.

1. https://leetcode.com/discuss/interview-question/system-design
2. https://www.educative.io/courses/grokking-the-system-design-interview