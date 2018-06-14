---
title: SpringMVC @Value
date: 2017/10/20 20:46:25
tags: [深圳,SpringMVC]
categories: Web
photo: http://oyo2a85eo.bkt.clouddn.com/banner/Sunset.jpg
---
<center>老是忘记这个</center>
<!-- more -->

## @Value注入静态变量
昨天写代码时用@value注入一个值，调试的时候发现值为空，应该是没有注入成功，注入方式使用@value和往常一样，仔细和往常代码比对发现这次注入的变量多了static修饰符。遂想到springMVC @ value注入**静态变量**和**普通变量**的方式是不是有所不同，查了一下发现注入方式确实存在区别，所以随手记下来。

### @Value注入普通变量

直接使用@value注入
```
    private @Value("#{config_muguang['app_key']}") String MASTER_SECRET;
    private @Value("#{config_muguang['master_secret']}") String APP_KEY;
```

#### @Value注入静态变量

注入**静态变量**的时候要给set方法注入
```
    private static String MASTER_SECRET;
    private static String APP_KEY;

    @Value("#{config_muguang['app_key']}")
    public void setAppKey(String db) {
        JPush.APP_KEY = db;
    }

    @Value("#{config_muguang['master_secret']}")
    public void setMasterSecret(String db) {
        JPush.MASTER_SECRET = db;
    }
```

#### @Value注入静态变量方法总结
给set方法注入是最常用的，还有没有其他方法给**静态变量**注入值呢？

>1、xml通过bean注入
>2、给参数注入，执行set方法
>3、通过中间变量赋值

```
    public static String zhifuUrl;
    @Value("${zhifu.url}")
    private String zhifuUrlTmp;

    @PostConstruct
    public void init() {
    zhifuUrl = zhifuUrlTmp;
}
```

#### PS:
使用@Value标签给变量注入值的时候class上一定要加上@Component

## @Value #和$
先直接来看看使用方法
```
    @Value("${historyConf}")
    @Value("#{config_weixin['api_key']}")
```

### #
#### 方法一
```
    <bean id="config_weixin" class="org.springframework.beans.factory.config.PropertiesFactoryBean">
    <property name="locations">
        <list>
            <value>classpath:weixin.properties</value>
        </list>
    </property>
    </bean>
```

#### 方法二
```
    <util:properties id="config_weixin" location="classpath:weixin.properties" />
```
两种方式等价，都是通过在Spring配置文件中构建一个bean指向properties配置文件，使用时
**@Value("#{config_weixin['api_key']}")** config_weixin为bean的id，api_key为properties配置文件中key的值。方式二比一简单些，但是使用util标签，要引入util的xsd；

### $
在#使用方法的基础上加上：
```
    <bean id="propertyConfigurer" class="org.springframework.beans.factory.config.PreferencesPlaceholderConfigurer">
        <property name="properties" ref="config_weixin"/>
    </bean>
```
相当于将config_weixin中所有key扩展到了全局变量中，使用时 **@Value("${historyConf}")** historyConf就是配置文件中的key值，不需要再加上配置文件名称。

### 总结
_1、{}里面的内容必须符合SpEL表达式
2、\#{…} 用于执行SpEl表达式，并将内容赋值给属性
3、${…} 主要用于加载外部属性文件中的值
4、\#{…} 和${…} 可以混合使用，但是必须#{}外面，${}在里面，因为因为spring执行${}是时机要早于#{}。_
