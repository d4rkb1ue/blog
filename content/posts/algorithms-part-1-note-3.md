---
title: Algorithms Notes/Stack&Queue (Week 2 Part 1)
date: 2016-11-12 22:53:08
tags: [Algorithms, Coursera]
---

# Why Stack?

- Why not other Java powerful colllection libraries?

    Powerful like "Swiss Knife" but lack of efficiency.

- Except for efficiency, when stack is more convenient?

    + Parsing in a compiler.
    
    + Back button in a Web browser. 
    
    + Implementing function calls in a compiler. (**Function call**: push local environment and return address; **Return**: pop return address and local environment.)

    *Recursive function: **Can always use an explicit stack to remove recursion.***

## Excellenct usage example of stack: Two-stack algorithm. [E. W. Dijkstra]



### Goal

Evaluate infix expressions.

```
( 1 + ( ( 2 + 3 ) * ( 4 * 5) ) )
```

- *Only deal with single number, `+`, `*`*

### Algorithm

- Value: push onto the value stack
- Operator: push onto the operator stack
- Left parenthesis: ignore
- Right parenthesis: pop operator and two values; push the result of applying that operator to those values onto the value stack.

### Go

![stack-ex-two-stack-algroithms](/images/algorithem_coursera/stack-ex-two-stack-algroithms.png)

### Implement

```java
public class Evaluate{
    public static void main(String[] args){
        Stack<String> ops = new Stack<String>();
        Stack<Double> vals = new Stack<Double>();
        while (!StdIn.isEmpty()){
            String s = StdIn.readString();
            if ( s.equals("(") ){} // ignore
            else if ( s.equals("+") || s.equals("*") ){ // push operator
                ops.push(s);
            }
            else if ( s.equals(")") ){
                String op = ops.pop();
                if ( op.equals("+") ){
                    vals.push(vals.pop() + vals.pop());
                }
                else if ( op.equals("*") ){
                    vals.push(vals.pop() * vals.pop());
                }
            }
            else{ // number
                vals.push(Double.parseDouble(s));
            }
        }
        StdOut.println(vals.pop());
    }
}
```


### Further observations

- 后置运算符不影响算法

```
( 1 ( ( 23 + ) ( 4 5 *) * ) + )
```

- 无运算符也不影响算法！

```
1 2 3 + 4 5 * * +
```

观察到所有运算符都伴随着`)`，那么直接以运算符为出栈计算条件。

# Style

- Modilar reusable libraries: 接口实现分离

# Stack

- FILO

## Interface

```java
public class StackOfStrings{
    StackOfStrings();
    void push(String item);
    String pop();
    boolean isEmpty();
}
```

## Implement by Linked list

```java
public class StackOfStrings{
    private class node{
        String item;
        Node next;
    }
    private first = null;
    
    //public StackOfStrings()

    public void push (String item){
        Node oldFirst = first;
        first = new Node();
        first.item = item;
        first.next = oldFirst;
    }

    public String pop(){
        String ret = first.item;
        first = first.next;
        return ret;
    }
    
    public boolean isEmpty(){
        return first == null;
    }
}
```

## Implement by Array

```java
public class StackOfStrings{
    private String[] s;
    private int N = 0; // ahead of exist data
    
    // cap: capacity
    public StackOfStrings(int cap){
        s = new String[cap];}
    
    public boolean isEmpty(){
        return N == 0;}

    public void push(String item){
        s[N++] = item;}

    public String pop (){
        String ret = s[--N];
        // for java avoid 'loitering'
        S[N] = null; // remove the reference of the poped one
        return ret;}
}
```

*Defect: determine the maximum capacity ahead of time*

## Implement by Resizing Array

### Grow size

To realize a resizing array stack, we have 2 approaches:

1. Create a new array 1 size bigger mirrors old array and +1 item once push
2. Create a new array **TWICE** bigger mirror old array once **FULL**(term: Amortize Analyse)

But App[1] is to expansive: 

- Copy time: 1+2+3+...+N = N^2/2

App[2] is cheaper:

- Copy time: 1+2+4+8+...+N (共log(2,N)项) = 2^(log(2,N)) - 1 = 2N -1;

### Shrink size

- Halve(1/2) the array when array is **HALF** full

    Get expansive in worst case: consider the array is half full, and operations tasks just `Push-Pop-Push-Pop-...` which lead to `DoubleSize-HalveSize-DoubleSize-HalveSize-...`

A better solution is:

- Halve size when array is **ONE-QUARTER** full

    `if(N>0 && N==s.length/4) resize(s.length/2);`

    So, in this case, the array is always **between 25% and 100%** full. This can achieve a more efficient performance in average, but may cause some interupt all of the sudden.

Here's an example:

![resize-array-shirk-strategy](/images/algorithem_coursera/resize-array-shirk-strategy.png)

## Comparison

### Memeory usage

- Linked list: 16B(Object head) + 8B(inner class overhead) + 8B(ref to string) + 8B(ref to next node) = 40B per item.

- Resize array: 8B(ref to string) per item(totally full) ~ 32B per item(1/4 full, worst case)

### Implementation

- Linked list: constant time for each operation; Extra time/space to deal with the link
- Resize array: shorter amortized(average) time; less space(in any case)

# Queues

- FIFO

## Interface

```java
public class QueueOfStrings{
    QueueOfStrings();
    void enqueue(String item);
    String dequeue();
    boolean isEmpty();
}
```

## Implement by Linked list

```java
public class QueueOfStrings{
    private class Node{
        String item;
        Node next;
    }
    private Node first, last;

    public void enqueue(String item){
        Node oldlast = last;
        last = new Node();
        last.item = item;
        last.next = null;
        if (isEmpty()){
            first = last;
        }
        else{
            oldlast.next = last;    
        }
    }
    public String dequeue(){
        String ret = first.item;
        first = first.next;
        if(isEmpty()){
            last = null;
        }
        return ret;
    }
    public boolean isEmpty(){
        return first == null;
    }
}
```

# Generics

Usage

```java
Stack<Apple> s = new Stack<Apple>();
Apple a = new Apple();
s.push(a); // OK
Orange b = new Orange();
s.push(b); // Error
a = s.pop();
```

Implement

```java
public class FixedCapacityStack<Item>{
    private Item[] s;
    // N is 1 ahead of the current item
    private int N = 0;
    public FixedCapacityStack(int cap){
        // Ugly cast, but 
        // s = new Item[cap]; 
        // is not allowed in the Java
        s = (Item[]) new Object[cap];
    }
    public boolean isEmpty(){
        return N == 0;
    }
    public void push(Item item){
        s[N++] = item;
    }
    public Item pop(){
        return s[--N];
    }
}
```

## Autoboxing

for the primative types, like `int`, `double`:

```java
Stack<Integer> s = new Stack<Integer>();
s.push(17); // = s.push(Integer.valueOf(17));
int a = s.pop(); // = s.pop().intValue();
```

# Iteration

Keep the internal representation **black** by implement the `java.lang.Iterable` interface.

```java
public interface Iterable<Item>{
    Iterator<Item> iterator();
}
public interface Iterator<Item>{
    boolean hasNext();
    Item next();
    void remove(); // optional
}
```

So, the data structure can be used like:

```java
for (String s : stack){
    StdOut.println(s);
}
// or
Iterator<String> i = stack.iterator();
while (i.hasNext()){
    String s = i.next();
    StdOut.println(s);
}
```

## Implementation

Stack iterator: linked-list implementation

```java
import java.until.Iterator;
public class Stack<Item> implements Iterable<Item>{
    ...
    public Iterator<Item> iterator(){
        return new ListIterator();
    }
    private class ListIterator implements Iterator<Item>{
        // current is the next, which has not been poped
        private Node current = first;
        public boolean hasNext(){
            return current != null;
        }
        public void remove(){ /* not supported */ }
        public Item next(){
            Item ret = current.item;
            current = current.next;
            return ret;
        }// end ListIterator.next()
    }// end internal class: ListIterator
}// end public class: Stack
```





