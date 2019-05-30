---
title: Spring循环依赖
date: 2019/5/29 16:33:25
tags: [武汉,Spring,后端]
categories: document
photo: https://s2.ax1x.com/2019/05/30/VKDA8s.md.jpg
---

<center>_Spring循环依赖的三种方式..._</center>
<!-- more -->

### 前言
Spring相关知识中比较基础和常见的内容，一直没有记录下来。

### Spring依赖注入三种方式
#### 构造器参数循环依赖
Spring容器会将每一个正在创建的Bean 标识符放在一个**当前创建Bean池**中，Bean标识符在创建过程中将一直保持在这个池中，因此如果在创建Bean过程中发现自己已经在**当前创建Bean池**里时将抛出BeanCurrentlyInCreationException异常表示循环依赖；而对于创建完毕的Bean将从**当前创建Bean池**中清除掉。

```java
public class StudentA {
    private StudentB studentB ;

    public void setStudentB(StudentB studentB) {
        this.studentB = studentB;
    }

    public StudentA() {
    }

    public StudentA(StudentB studentB) {
        this.studentB = studentB;
    }
}
```

```java
public class StudentB {
    private StudentC studentC ;

    public void setStudentC(StudentC studentC) {
        this.studentC = studentC;
    }

    public StudentB() {
    }

    public StudentB(StudentC studentC) {
        this.studentC = studentC;
    }
}
```

```java
public class StudentC {
    private StudentA studentA ;

    public void setStudentA(StudentA studentA) {
        this.studentA = studentA;
    }

    public StudentC() {
    }

    public StudentC(StudentA studentA) {
        this.studentA = studentA;
    }
}
```

三个类StudentA有参构造是StudentB。StudentB的有参构造是StudentC，StudentC的有参构造是StudentA ，这样就产生了一个循环依赖的情况。

我们都把这三个Bean交给Spring管理，并用有参构造实例化：
```xml
    <bean id="a" class="com.zfx.student.StudentA">
        <constructor-arg index="0" ref="b"></constructor-arg>
    </bean>
    <bean id="b" class="com.zfx.student.StudentB">
        <constructor-arg index="0" ref="c"></constructor-arg>
    </bean>
    <bean id="c" class="com.zfx.student.StudentC">
        <constructor-arg index="0" ref="a"></constructor-arg>
    </bean>
```

测试类：
```java
public class Test {
    public static void main(String[] args) {
        ApplicationContext context = new ClassPathXmlApplicationContext("com/zfx/student/applicationContext.xml");
        //System.out.println(context.getBean("a", StudentA.class));
    }
}
```

运行结果：
```java
Caused by: org.springframework.beans.factory.BeanCurrentlyInCreationException:
	Error creating bean with name 'a': Requested bean is currently in creation: Is there an unresolvable circular reference?
```

原因：Spring容器先创建单例StudentA，StudentA依赖StudentB，然后将A放在**当前创建Bean池**中，此时创建StudentB,StudentB依赖StudentC ,然后将B放在**当前创建Bean池**中,此时创建StudentC，StudentC又依赖StudentA， 但是，此时Student已经在池中，所以会报错，，因为在池中的Bean都是未初始化完的，所以会依赖错误 ，（初始化完的Bean会从池中移除）

#### Setter方式单例，默认方式
如果要说setter方式注入的话，我们最好先看一张Spring中Bean实例化的图

[![VK0FeS.md.jpg](https://s2.ax1x.com/2019/05/30/VK0FeS.md.jpg)](https://imgchr.com/i/VK0FeS)

如图中前两步骤得知：Spring是先将Bean对象实例化之后再设置对象属性的

修改配置文件为set方式注入

```xml
<!--scope="singleton"(默认就是单例方式)  -->
    <bean id="a" class="com.zfx.student.StudentA" scope="singleton">
        <property name="studentB" ref="b"></property>
    </bean>
    <bean id="b" class="com.zfx.student.StudentB" scope="singleton">
        <property name="studentC" ref="c"></property>
    </bean>
    <bean id="c" class="com.zfx.student.StudentC" scope="singleton">
        <property name="studentA" ref="a"></property>
    </bean>
```
测试类同上，打印结果为：
```java
com.zfx.student.StudentA@1fbfd6
```

为什么用set方式就不报错了呢？
    我们结合上面那张图看，Spring先是用构造实例化Bean对象 ，此时Spring会将这个实例化结束的对象放到一个Map中，并且Spring提供了获取这个未设置属性的实例化对象引用的方法。
结合我们的实例来看，，当Spring实例化了StudentA、StudentB、StudentC后，紧接着会去设置对象的属性，此时StudentA依赖StudentB，就会去Map中取出存在里面的单例StudentB对象，以此类推，不会出来循环的问题。

#### setter方式原型，prototype
修改配置文件为：

```xml
    <bean id="a" class="com.zfx.student.StudentA" scope="prototype">
        <property name="studentB" ref="b"></property>
    </bean>
    <bean id="b" class="com.zfx.student.StudentB" scope="prototype">
        <property name="studentC" ref="c"></property>
    </bean>
    <bean id="c" class="com.zfx.student.StudentC" scope="prototype">
        <property name="studentA" ref="a"></property>
    </bean>
```
scope="prototype" 意思是 每次请求都会创建一个实例对象。两者的区别是：有状态的bean都使用Prototype作用域，无状态的一般都使用singleton单例作用域。

打印结果：
```java
Caused by: org.springframework.beans.factory.BeanCurrentlyInCreationException:
	Error creating bean with name 'a': Requested bean is currently in creation: Is there an unresolvable circular reference?
```

为什么原型模式就报错了呢？
对于**prototype**作用域Bean，Spring容器无法完成依赖注入，因为**prototype**作用域的Bean，Spring容器不进行缓存，因此无法提前暴露一个创建中的Bean。

### 总结
**prototype**使用的不多，所有主要需要区分的还是构造器注入和Setter注入两种方式，他们的区别在于构造器注入是“构造”，即“创建”的时候就要去注入依赖，所有会造成循环依赖报错，而Setter注入是先构造对象，再通过Setter方法注入属性，所以循环依赖不会报错，理解了这个就很清楚了。
