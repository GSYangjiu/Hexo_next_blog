---
title: SpringMVC @value注入static变量
date: 2017/10/20 20:46:25
tags: [深圳,SpringMVC]
categories: Web
---

<center>_不如早还乡..._</center>
<img src="http://oyo2a85eo.bkt.clouddn.com/banner/Sunset.jpg">

<!-- more -->
昨天写代码时用@value注入一个值，调试的时候发现值为空，应该是没有注入成功，注入方式使用@value和往常一样，仔细和往常代码比对发现这次注入的变量多了static修饰符。遂想到springMVC @ value注入**静态变量**和**普通变量**的方式是不是有所不同，查了一下发现注入方式确实存在区别，所以随手记下来。

### @value注入普通变量

直接使用@value注入
```
    private @Value("#{config_muguang['app_key']}") String MASTER_SECRET;
    private @Value("#{config_muguang['master_secret']}") String APP_KEY;
```

#### @value注入静态变量

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

#### @value注入静态变量方法总结
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
使用@value标签给变量注入值的时候class上一定要加上@Component
