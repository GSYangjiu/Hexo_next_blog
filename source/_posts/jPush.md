---
title: 极光推送-ios/Android平台 Notification构建
date: 2017/11/23 15:10:00
tags: [深圳,Utils,后端]
categories: document
photo: http://oyo2a85eo.bkt.clouddn.com/banner/coke.jpg
---

<center>_想来生活无非是痛苦和美丽..._</center>
<!-- more -->

## 极光推送
最近App开发采用React Native + java前后端分离的方式，前端调用后台接口，后台返回数据。在某些应用情景，后台需要推送消息给用户客户端，基于敏捷开发，我们选择了集成极光推送的模式来推送给用户各种消息。

### 极光推送的两种方式
1. 使用极光推送官方提供的推送请求API

  第一种方式即，我们在后台按照极光文档讲推送内容封装成Json体，再去访问官方的API接口，提交Json请求体，实现推送功能。
  然而这种方式操作过于繁琐，格式也不好定义，因为要自己去将请求体转按照官方文档规则换成Json，代码量相对于第二种方式来说也比较多，官方也并不推荐这一种方式。

2. 使用官方提供的第三方SDK

  第二种方式需要通过在pom.xml文件中添加下面代码，添加Maven依赖。

```
  <dependency>
    <groupId>cn.jpush.api</groupId>
    <artifactId>jpush-client</artifactId>
    <version>3.3.3</version>
  </dependency>
```
  添加Maven依赖后就可以在项目中直接调用极光官方封装好的方法来封装我们的消息体，非常简单直接。

### 极光推送Demo

```
package com.mg.open.common;

import cn.jpush.api.JPushClient;
import cn.jpush.api.push.PushResult;
import cn.jpush.api.push.model.Message;
import cn.jpush.api.push.model.Platform;
import cn.jpush.api.push.model.PushPayload;
import cn.jpush.api.push.model.audience.Audience;
import cn.jpush.api.push.model.notification.AndroidNotification;
import cn.jpush.api.push.model.notification.IosNotification;
import cn.jpush.api.push.model.notification.Notification;
import com.mg.web.common.utils.Push;
import com.mg.web.friend.dao.IPushMessageDAO;
import com.mg.web.friend.entity.PushMessage;
import org.apache.log4j.Logger;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.annotation.PostConstruct;
import java.util.HashMap;
import java.util.Map;

/**
* Created by Yang on 2017/11/4 0004.
*/
@Component
public class JPush {
  private static final Logger logger = Logger.getLogger(JPush.class);
  private static String MASTER_SECRET;
  private static String APP_KEY;

  @Autowired
  private IPushMessageDAO pushMessageDAO;

  //静态工具类注入service
  private static JPush jPush;

  @PostConstruct
  private void init() {
      jPush = this;
      jPush.pushMessageDAO = this.pushMessageDAO;
  }

  @Value("#{config_muguang['app_key']}")
  public void setAppKey(String db) {
      JPush.APP_KEY = db;
  }

  @Value("#{config_muguang['master_secret']}")
  public void setMasterSecret(String db) {
      JPush.MASTER_SECRET = db;
  }

  public static void pushAll(PushMessage pushMessage, Push push) throws Exception {
      JPushClient jPushClient = new JPushClient(MASTER_SECRET, APP_KEY);
      PushPayload payload = PushPayload.newBuilder()
              .setPlatform(Platform.android_ios())
              .setAudience(Audience.all())
              .setNotification(Notification.newBuilder()
                      .addPlatformNotification(AndroidNotification.newBuilder()
                              .addExtras(push.getMap())
                              .setAlert(pushMessage.getAlert())
                              .setTitle(pushMessage.getTitle())
                              .build())
                      .addPlatformNotification(IosNotification.newBuilder()
                              .addExtras(push.getMap())
                              .setAlert(pushMessage.getAlert())
                              .build())
                      .build())
              .build();

      //获取推送结果
      PushResult result = jPushClient.sendPush(payload);
      //保存推送消息
      pushMessage.setPushCode(push.getCode());
      pushMessage.setMsgId(result.msg_id);
      pushMessage.setSendno(result.sendno);
      jPush.pushMessageDAO.insert(pushMessage);
  }

  public static void pushByAlias(String token, PushMessage pushMessage, Push push) throws Exception {
      JPushClient jPushClient = new JPushClient(MASTER_SECRET, APP_KEY);
      PushPayload payload = PushPayload.newBuilder()
              .setPlatform(Platform.android_ios())
              .setAudience(Audience.alias(token))
              .setNotification(Notification.newBuilder()
                      .addPlatformNotification(AndroidNotification.newBuilder()
                              .addExtras(push.getMap())
                              .setAlert(pushMessage.getAlert())
                              .setTitle(pushMessage.getTitle())
                              .build())
                      .addPlatformNotification(IosNotification.newBuilder()
                              .addExtras(push.getMap())
                              .setAlert(pushMessage.getAlert())
                              .build())
                      .build())
              .build();

      //获取推送结果
      PushResult result = jPushClient.sendPush(payload);
      //保存推送消息
      pushMessage.setPushCode(push.getCode());
      pushMessage.setMsgId(result.msg_id);
      pushMessage.setSendno(result.sendno);
      jPush.pushMessageDAO.insert(pushMessage);
  }
}

```

一开始没有仔细去看源码，分平台推送构建了两个PushPayload，分别推送ios和Android，后来在网上查阅资料发现可以通过 **.newBuilder.addPlatformNotification()** 的方法构造对应不同平台的Notification。

还有就是要注意一下springMVC怎么注入 **static** 变量和dao，其他的就没有什么好说的了。

### Build模式

没有接触过Build模式的话看见上面那种一长串的 **.set** ，最后 **.build()** 的写法可能会觉得奇怪，这种写法第一次见识是在
《Effective Java》中，通过静态内部类Builder和隐式构造函数避免了当变量较多是使用重载构造器的繁琐，而且当这些参数中包含必选和可选的时候，重载构造器可能就要排列组合了，想想就觉得滑稽，手动滑稽。使用get/set又可能会是Bean在构造过程中处于几个状态，而且get/set那么low的写法怎么会有Builde模式的代码看起来简洁优雅。

示例代码：
```
public class NutritionFact3
{
    //均是final，不可变

    private final int servingSize;// required
    private final int servings;// required
    private final int calories;// optional
    private final int fat;// optional
    private final int sodium;// optional
    private final int carbohydrate;// optional

    public static class Builder
    {
        // 必须参数
        private final int servingSize;// required
        private final int servings;// required

        // 可选参数
        private int calories = 0;// optional
        private int fat = 0;// optional
        private int sodium = 0;// optional
        private int carbohydrate = 0;// optional

        // 必须参数必须通过通过构造参数传递
        public Builder(int servingSize, int servings)
        {
            this.servingSize = servingSize;
            this.servings = servings;
        }

        // 构建calories,返回本身，以便可以把调用连接起来
        public Builder calories(int calories)
        {
            this.calories = calories;
            return this;
        }

        // 构建sodium
        public Builder sodium(int sodium)
        {
            this.sodium = sodium;
            return this;
        }

        // 构建fat
        public Builder fat(int fat)
        {
            this.fat = fat;
            return this;
        }

        // 构建carbohydrate
        public Builder carbohydrate(int carbohydrate)
        {
            this.carbohydrate = carbohydrate;
            return this;
        }

        //build,返回NutritionFact3
        public NutritionFact3 build()
        {
            return new NutritionFact3(this);
        }
    }

    // 隐藏构造函数
    private NutritionFact3(Builder builder)
    {
        servingSize = builder.servingSize;
        servings = builder.servings;
        calories = builder.calories;
        fat = builder.fat;
        sodium = builder.sodium;
        carbohydrate = builder.carbohydrate;
    }

    public static void main(Stringargs)
    {
        NutritionFact3 cocaCola = new NutritionFact3.Builder(240, 8).calories(100).sodium(35).carbohydrate(27).build();
    }
}
```
<a href="http://tanfujun.com/2017/03/21/Effective-Java-%E8%AF%BB%E4%B9%A6%E7%AC%94%E8%AE%B0-2-%E9%81%87%E5%88%B0%E5%A4%9A%E4%B8%AA%E6%9E%84%E9%80%A0%E5%99%A8%E5%8F%82%E6%95%B0%E8%80%83%E8%99%91%E4%BD%BF%E7%94%A8%E6%9E%84%E5%BB%BA%E5%99%A8/">以上代码引用自晓晨DEV的技术博客，THKS</a>
