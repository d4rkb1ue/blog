---
title: 渗透问题 (Percolation) 中 backwash 的解决
date: 2016-10-10 02:49:48
tags: [Java, Algorithms]
---

# 参考
[Avoid Backwash Issue in Percolation Problem](http://www.sigmainfy.com/blog/avoid-backwash-in-percolation.html)

# Q: 渗透问题

[Percolation-week1](https://github.com/d4rkb1ue/Algs-part1-coursera/tree/master/Percolation-week1)



将一个不透水的均质方块分割为矩阵N*N，最上方为水源。随机打开矩阵中任意格子，重复此项操作多次，直到产生一条路径使水能穿过这个方块到达最下方。

## 思路

采用weighted-quick-union算法（with Path compression）

## 数据结构

和课上所用的weighted-quick-union算法一致，采用PPT的写法，模拟出2个虚拟点，分别是top和bottom。isFull就是判断这个点是否 is_connected(self,top)

# Bug：backwash


>In the context of Percolation, the backwash issue is that some site might be mistakenly judged as a full site (A full site is an open site that can be connected to an open site in the top row via a chain of neighboring (left, right, up, down) open sites.) if we directly adopt the dummy nodes suggested in the course material, i.e., a top virtual node connected to each site in the first first top row, another bottom virtual node connected to each site in the last bottom row. More concretely, it is just as the following pic shows (adopted from this post)


backwash：对于一个已经渗透的矩阵，存在**仅**连接底部但是不连接上方的格子 A ，A 应该处于不连通的状态；但是若存在 backwash 问题，则 A 处在连通状态。

![percolation-backwash.png](/images/percolation-backwash.png)


# 解决

## 方法1: 取消底部节点

Instead of using a BOTTOM point connecting to all the last points in last row. just deciding whether percolate by testing any point in last row connected to TOP point.

## 方法2: 使用两个 WeightedQuickUnionUF Object

> The easiest way to tackle this problem is to use two different Weighted Quick Union Union Find objects. The only difference between them is that one has only top virtual site (let’s call it uf_A), the other is the normal object with two virtual sites top one and the bottom one (let’s call it uf_B) suggested in the course, uf_A has no backwash problem because we “block” the bottom virtual site by removing it. uf_B is for the purpose to efficiently determine if the system percolates or not as described in the course. So every time we open a site (i, j) by calling Open(i, j), within this method, we need to do  union() twice: uf_A.union() and uf_B.union(). Obviously the bad point of the method is that: semantically we are saving twice the same information which doesn’t seem like a good pattern indeed. The good aspect might be it is the most straightforward and natural approach for people to think of.

## 方法3: 使用自定义 WeightedQuickUnionUF（每个节点多一个 connect2top 属性）

>And there turned out to be more elegant solutions without using 2 WQUUF if we can modify the API or we just wrote our own UF algorithm from scratch. The solution is from “Bobs Notes 1: Union-Find and Percolation (Version 2)“:  Store two bits with each component root. One of these bits is true if the component contains a cell in the top row. The other bit is true if the component contains a cell in the bottom row. Updating the bits after a union takes constant time. Percolation occurs when the component containing a newly opened cell has both bits true, after the unions that result from the cell becoming open. Excellent! However, this one involves the modification of the original API. Based on this and some other discussion from other threads in the discussion forum, I have come up with the following approach which need not to modify the given API but adopt similar idea by associating each connected component root with the information of connection to top and/or bottom sites.
