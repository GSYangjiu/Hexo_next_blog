---
title: Spring AOP初探——通知
date: 2017/9/09 20:46:25
tags: [深圳,Spring]
categories: Web
---

"Aspect-Oriented Programming（面向切面编程），它其实是 OOP（Object-Oriented Programing，面向对象编程）思想的补充和完善"

### 前言

说道Spring，就离不开AOP，都知道AOP是面向切面编程，但什么是切面，又如何面向切面编程，面向切面编程和面向对象编程有什么区别，Spring中众多的概念名称容易让人头晕目眩（切身体会）

我们先来看看软件工程Coding的几个阶段，从最开始的汇编语言，可以说是面向机器编程，到C，用一个个函数来控制流程，可以说是面向过程编程，到Java，有了对象的抽象，**类**，用一个个抽象的类来实现各种功能，代码易维护，易复用，降低了系统的耦合度，是大家所熟知的面向对面编程，即OOP。我们知道，面向对象的特点是继承、多态和封装。而封装就要求将功能分散到不同的对象中去。实际上也就是说，让不同的类设计不同的方法。这样代码就分散到一个个的类中去了。这样做的好处是降低了代码的复杂程度，使类可重用。
但是人们也发现，在分散代码的同时，也增加了代码的重复性。什么意思呢？比如说，我们在两个类中，可能都需要在每个方法中做日志。按面向对象的设计方法，我们就必须在两个类的方法中都加入日志的内容。也许他们是完全相同的，但就是因为面向对象的设计让类与类之间无法联系，而不能将这些重复的代码统一起来。也许有人会说，那好办啊，我们可以将这段代码写在一个独立的类独立的方法里，然后再在这两个类中调用。但是，这样一来，这两个类跟我们上面提到的独立的类就有耦合了，它的改变会影响这两个类。那么，有没有什么办法，能让我们在需要的时候，随意地加入代码呢？于是AOP出现了，在运行时，动态地将代码切入到类的指定方法、指定位置上，那些类需要实现的交叉的功能就是所谓的**切面**。而通知，即为切面的具体实现。
本文为Spring初探，首先来介绍一下Spring中的五种通知，用实例来揭开AOP的朦胧的面纱。

---

<!-- more -->

### 正文

前文谈到通知，即为AOP切面的具体实现，比如有几个类要实现共同功能，如日志，或者资源关闭，连接关闭等功能，这就是一个切面，而如何实现这些功能的，依赖的就是通知。

Spring中有五种通知：

>前置通知（Before Advice）：在切入点选择的连接点处的方法之前执行的通知，该通知不影响正常程序执行流程（除非该通知抛出异常，该异常将中断当前方法链的执行而返回）。

>后置通知（After Advice）：在切入点选择的连接点处的方法之后执行的通知（无论方法执行是否成功都会被调用）。

>环绕通知（Around Advices）：环绕着在切入点选择的连接点处的方法所执行的通知，环绕通知可以在方法调用之前和之后自定义任何行为，并且可以决定是否执行连接点处的方法、替换返回值、抛出异常等等。

>异常通知（After throwing Advice）: 在切入点选择的连接点处的方法抛出异常返回时执行的通知，必须是连接点处的方法抛出任何异常返回时才调用异常通知。

>引用通知（After returning Advice）：在切入点选择的连接点处的方法正常执行完毕时执行的通知，必须是连接点处的方法没抛出任何异常正常返回时才调用。

下文主要以介绍前置通知来介绍AOP思想。

#### 一、前置通知
前置通知需实现MethodBeforeAdvice接口(org.springframework.aop.MethodBeforeAdvice)，该接口中只有一个before()方法

    public class MyMethodeBeforeAdvice implements MethodBeforeAdvice{

        /**
         * method:被调用的方法
         * args:给method传递的参数
         * target：目标对象
         */
        @Override
        public void before(Method method, Object[] args, Object target)
                throws Throwable {
            System.out.println("记录日志..."+method.getName());
        }
    }

接口定义：
接口TestServiceInter1和TestServiceInter2中分别定义了sayHai()和sayBey()方法
    public interface TestServiceInter1 {
        public void sayHai();
    }

    public interface TestServiceInter2 {
        public void sayBey();
    }

TestService类实现了TestServiceInter1和TestServiceInter2接口
    public class TestService implements TestServiceInter1,TestServiceInter2{
        private String name;
        @Override
        public void sayHai() {
            System.out.println("Hello! "+name);
        }

        @Override
        public void sayBey() {
            System.out.println("Bey! "+name);

        }
        public String getName() {
            return name;
        }
        public void setName(String name) {
            this.name = name;
        }
    }

Spring配置文件beans.xml中配置
    <?xml version="1.0" encoding="UTF-8"?>
    <beans
        xmlns="http://www.springframework.org/schema/beans"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xmlns:p="http://www.springframework.org/schema/p"
        xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans-3.0.xsd">

    <!-- 配置被代理的对象 -->
    <bean id="testService" class="com.itheima.aop.TestService">
        <property name="name" value="Yang"/>
    </bean>

    <!-- 配置前置通知 -->
    <bean id="MyMethodeBeforeAdvice" class="com.itheima.aop.MyMethodeBeforeAdvice">
    </bean>


    <!-- 配置代理对象 -->
    <bean id="proxyFactoryBean" class="org.springframework.aop.framework.ProxyFactoryBean">
    <!-- 代理接口集 -->
        <property name="proxyInterfaces">
            <list>
                <value>com.itheima.aop.TestServiceInter1</value>
                <value>com.itheima.aop.TestServiceInter2</value>
            </list>
        </property>
        <!-- 把通知织入代理对象 -->
        <property name="interceptorNames">
            <!-- 相当于把MyMethodeBeforeAdvice前置通知和代理对象关联，可以把通知看成拦截器 -->
            <value>MyMethodeBeforeAdvice</value>
        </property>
        <!-- 配置被代理对象 -->
        <property name="target" ref="testService"/>
    </bean>
    </beans>

在main函数中实例化一个TestServiceInter1或TestServiceInter2对象，可以分别调用sayHai()或sayBey()方法

    public class Test {
        public static void main(String[] args) {
            ApplicationContext ac = new ClassPathXmlApplicationContext("com/itheima/aop/beans.xml");
            TestServiceInter1 ts = (TestServiceInter1) ac.getBean("proxyFactoryBean");
            ts.sayHai();
            //TestServiceInter2 ts = (TestServiceInter2) ac.getBean("proxyFactoryBean");
            //ts.sayBey();
        }
    }

最后我们来看一下结果：
实例化TestServiceInter1时：

    log4j:WARN No appenders could be found for logger (org.springframework.context.support.ClassPathXmlApplicationContext).
    log4j:WARN Please initialize the log4j system properly.
    记录日志...sayHai
    Hello! Yang

实例化TestServiceInter2时：

    log4j:WARN No appenders could be found for logger (org.springframework.context.support.ClassPathXmlApplicationContext).
    log4j:WARN Please initialize the log4j system properly.
    记录日志...sayBey
    Bey! Yang

我们还可以看到，配置一个通知需要
1.定义接口</br>
2.编写对象（被代理对象=目标对象）</br>
3.编写通知（前置通知在目标方法调用前调用）</br>
4.1 在bean.xml文件中配置</br>
4.2 配置被代理对象</br></br>
4.3 配种通知</br>
4.4.1 配置代理对象（ProxyFactoryBean的对象实例）</br>
4.4.2 配置代理接口集</br>
4.4.3 织入通知</br>
4.4.4 为代理对象配置被代理通知</br>

我们可以看到无论TestServiceInter1还是TestServiceInter2，都依赖于前置通知MyMethodeBeforeAdvice中的before()方法实现了记录日志的功能，但具体实现又有所不同。

TestServiceInter1和TestServiceInter2的交叉功能：记录日志就是一个切面，而该切面的具体实现交由通知来实现（在此示例中为前置通知），通过在beans.xml文件中实现了即插即用，既实现了代码的复用，又没有增加类与类之间的耦合关系。

被代理对象TestService即为目标对象，其中sayHaier()或sayBey()就是目标对象的目标方法，所有通知都是围绕着这个方法，所有目标方法也叫做AOP的切入点亦或是连接点。关于切入点和连接点我还没搞太清楚，网上大概说：

>连接点是个虚的概念，可简单理解为切入点的集合；他只是对应用程序的所有需要进行插入切面的一个统称；
>每个切入点都对应具体的连接点，在运行期spring就是根据这些切入点的定义，将通知或者拦截器插入到具体的连接点上。

个人理解为AOP中切入点一定是一个连接点，而一个连接点为切入提供了可能，可以通过配置通知变成切入点。

#### 二、后置通知
后置通知与前置通知基本类似，后置通知需要实现AfterReturningAdvice接口(org.springframework.aop.AfterReturningAdvice)中的afterReturning()方法。配置后在目标方法执行之后执行，常用来处数据库连接或资源关闭功能。
当需要在代理对象中织入多个通知的时候可以使用<list></list>来配置

    <bean id="proxyFactoryBean" class="org.springframework.aop.framework.ProxyFactoryBean">
    <!-- 代理接口集 -->
        <property name="proxyInterfaces">
            <list>
                <value>com.itheima.aop.TestServiceInter</value>
                <value>com.itheima.aop.TestServiceInter2</value>
            </list>
        </property>
        <!-- 把通知织入代理对象 -->
        <property name="interceptorNames">
            <list>
                <!-- 相当于把MyMethodeBeforeAdvice前置通知和代理对象关联，可以把通知看成拦截器 -->
                <value>MyMethodeBeforeAdvice</value>
                <value>MyAfterReturningAdvice</value>
            </list>
        </property>
        <!-- 配置被代理对象 -->
        <property name="target" ref="test1Service">

        </property>
    </bean>

#### 三、环绕通知
环绕通知需实现MethodInterceptor接口(org.aopalliance.intercept.MethodInterceptor)中invoke()方法。

    public class MyMethodInterceptor implements MethodInterceptor {
        @Override
        public Object invoke(MethodInvocation arg0) throws Throwable {
            System.out.println("环绕通知被调用：调用方法前执行  ");
            Object obj = arg0.proceed();
            System.out.println("环绕通知被调用：调用方法后执行  ");
            return obj;
        }
    }

该方法中传入参数arg0代表目标方法。通过Object obj = arg0.proceed();我们可以控制哪些动作在目标方法前执行，哪些动作在目标方法后执行。

#### 四、异常通知
异常通知需实现ThrowsAdvice接口(org.springframework.aop.ThrowsAdvice)中的afterThrowing()方法，配置同前置通知，异常通知在目标方法抛出异常时执行。

#### 五、引用通知
最后一个是引入通知，引入通知不需要编写相应的类，只需要进行配置，目的是用来指定哪些方法需要执行相应的通知，如，我们想指定只有sayHai()方法执行前置通知，

    <!-- 定义前置通知的切入点（引用通知） -->
    <bean id="myMethodBeforeAdviceFilter" class="org.springframework.aop.support.NameMatchMethodPointcutAdvisor">
        <property name="advice" ref="myMethodBeforeAdvice"></property>
        <property name="mappedNames">
            <list>
                <value>sayHai</value>
            </list>
        </property>
    </bean>
