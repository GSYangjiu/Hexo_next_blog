---
title: 泛型extends和super
date: 2018/10/12 15:42:00
tags: [武汉,Java]
categories: document
photo: http://oyo2a85eo.bkt.clouddn.com/cloudyday.jpg
---

<center>_困扰了很久的问题_</center>
<!-- more -->

### 前景
不带继承的泛型使用很简单，基本上熟悉了Java多态就能很轻松的使用，但是日常中阅读源码时经常会碰到具有继承关系的泛型使用，**extends** 和 **super** ，例如Collections中的copy方法
```java
    public static <T> void copy(List<? super T> dest, List<? extends T> src) {
        int srcSize = src.size();
        if (srcSize > dest.size())
            throw new IndexOutOfBoundsException("Source does not fit in dest");

        if (srcSize < COPY_THRESHOLD ||
            (src instanceof RandomAccess && dest instanceof RandomAccess)) {
            for (int i=0; i<srcSize; i++)
                dest.set(i, src.get(i));
        } else {
            ListIterator<? super T> di=dest.listIterator();
            ListIterator<? extends T> si=src.listIterator();
            for (int i=0; i<srcSize; i++) {
                di.next();
                di.set(si.next());
            }
        }
    }
```
这个时候就有点糊，往往一带而过，知道这个函数大概是接收个什么参数然后就继续往下看实现了，但长期以往总是一知半解，基础就很薄弱了，说起什么好像都懂一点但做起来就磕磕碰碰。搞技术一定要稳扎稳打，不能畏难，不能抱有侥幸。

### 定义
首先，**<? extends T>** 和 **<? super T>** 是Java泛型中的“通配符（Wildcards）”和“边界（Bounds）”的概念。

><? extends T>：是指 “上界通配符（Upper Bounds Wildcards）”   
><? super T>：是指 “下界通配符（Lower Bounds Wildcards）”

**里氏替换原则**

> 子类完全拥有父类的方法，且具体子类必须实现父类的抽象方法。     
> 子类中可以增加自己的方法。     
> 当子类覆盖或实现父类的方法时，方法的形参要比父类方法的更为宽松。      
> 当子类覆盖或实现父类的方法时，方法的返回值要比父类更严格。     

**协变和逆变**   
逆变与协变用来描述类型转换（type transformation）后的继承关系，其定义：如果A、B表示类型，f(⋅)表示类型转换，≤表示继承关系（比如，A≤B表示A是由B派生出来的子类；

> f(⋅)是逆变（contravariant）的，当A≤B时有f(B)≤f(A)成立；    
> f(⋅)是协变（covariant）的，当A≤B时有f(A)≤f(B)成立；    
> f(⋅)是不变（invariant）的，当A≤B时上述两个式子均不成立，即f(A)与f(B)相互之间没有继承关系；

### 为什么要使用通配符
举个例子，我们现在用Fruit类和他的派生类Apple，和一个最简单的容器类：Plate。Plate可以放一个“泛型”的东西。
```java
    class Food{}
    class Fruit extends Food{}
    class Apple extends Fruit{}
        
    class Plate<T>{
        private T item;
        public Plate(T t){item=t;}
        public void set(T t){item=t;}
        public T get(){return item;}
    }
```

现在我定义一个“水果盘子”，逻辑上水果盘子当然可以装苹果。

```java
    Plate<Fruit> plate = new Plate<Apple>(new Apple());
```

但实际上Java编译器不允许这个操作。会报错，“装苹果的盘子”无法转换成“装水果的盘子”。编辑器的逻辑是：

> 苹果 IS-A 水果    
> 装苹果的盘子 NOT-IS-A 装水果的盘子

容器里装的东西之间具有继承关系，但是容器之间是没有继承关系的。为了解决这个问题，<? extends T> 和 <? super T>就被发明了。     
而Java中的泛型是不变的，extends和super从根本上讲是为了把数据类型的关系延续到容器上，实现协变和逆变。

### 协变和逆变

**<? extends T>** 实现了泛型的协变，例如:

```java
    Plate<? extends Fruit> plate = new Plate<Apple>();
    //泛型擦除后，变为：
    Plate<Apple> plate = new Plate<Apple>();
```

**<? super T>** 实现了泛型的逆变，例如：

```java
    Plate<? super Fruit> plate = new Plate<Food>();
    //泛型擦除后，变为：
    Plate<Food> plate = new Plate<Food>();
```

通过 **<? extends T>** 和 **<? super T>** 实现了泛型的协变和逆变，而且没有破坏里氏替换原则。

### 上下界通配符的副作用
先看代码

```java
    Plate<? extends Fruit> plate = new Plate<>();
    plate.set(new Apple()); //Error
```

#### 上界<? extends T>不能往里存，只能往外取
IntellIj会检测到编译时异常，通常我们会觉得，plate是个装水果的盘子，为什么不能装苹果？因为编译器没办法确定Plate存放的具体的元素类型，只能知道是个Fruit的子类，你放了一个Apple，Apple是Fruit的子类，但是编译器不能确定Plate中要放的是不是Apple。**<? extends T>** 只能确保Plate中的元素一定是Fruit的子类，并不是指只要是Fruit的子类就一定能放到Plate中，所以叫做 **上界通配符**。   

```java
    Plate<? extends Fruit> p = new Plate<Apple>(new Apple());
    	
    //不能存入任何元素
    p.set(new Fruit());    //Error
    p.set(new Apple());    //Error

    //读取出来的东西只能存放在Fruit或它的基类里。
    Fruit newFruit1 = p.get();
    Object newFruit2 = p.get();
    Apple newFruit3 = p.get();    //Error
```
同理，取的时候不能用Apple去接，只能用Fruit或者Fruit的基类去接。

#### 下界<? super T>不影响往里存，但往外取只能放在Object对象里
```java
    Plate<? super Fruit> p = new Plate<Fruit>(new Fruit());

    //存入元素正常
    p.set(new Fruit());
    p.set(new Apple());

    //读取出来的东西只能存放在Object类里。
    Apple newFruit3 = p.get();    //Error
    Fruit newFruit1 = p.get();    //Error
    Object newFruit2 = p.get();
```
当时用 **<? super T>** 时，编译器会知道Plate中的元素一定是Fruit或Fruit的基类，而Apple是Fruit的子类，所以可以向Plate中添加Apple，但取的时候不能确定取出来究竟是Fruit的哪个父类，只能用所有对象的父类Object来接收，元素的类型信息就会丢失。

### PECS (Producer Extends Consumer Super)
究竟什么时候用extends什么时候用super呢？《Effective Java》给出了答案：
