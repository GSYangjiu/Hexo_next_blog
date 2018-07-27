---
title: Content-Type和@RequestBody
date: 2017/10/15 21:36:25
tags: [深圳,SpringMVC,后端]
categories: document
photo: http://oyo2a85eo.bkt.clouddn.com/banner/dusk.jpg
---

<center>_一点点失去..._</center>
<!-- more -->

最近公司开发app平台，前后端分离，我这边主要使用springMVC写一些接口供前端调用，然后改写一下以前微信平台的servise方法，前端调接口的的时候出现了一个问题，请求400，后台拿不到值，看了下代码和文档，发现是前端请求头改成了 **application/json**

#### 一.从form的enctype属性到Content-Type

表单的enctype有三种常见的属性：
>1、application/x-www-form-urlencoded

写html的时候我们都知道form有个属性enctype，如果不修改的话，缺省值是application/x-www-form-urlencoded，这个值表示会将表单数据用&符号做一个简单的拼接。例如：
```
POST /post_test.php HTTP/1.1
Accept-Language: zh-CN
User-Agent: Mozilla/4.0
Content-Type: application/x-www-form-urlencoded
Host: 192.168.12.102
Content-Length: 42
Connection: Keep-Alive
Cache-Control: no-cache
title=test&content=%B3%AC%BC%B6%C5%AE%C9%FA&submit=post+article
```
这种情况，后台在controller对应的方法中的参数直接添加对应的bean，springMVC可以根据参数的名字自动完成装配

当请求头中Content-Type为application/json时，后台controller中添加注解@RequestBody，将请求数据注入到一个String字符串中，把字符串转换成Json对象，在解析这个Json对象根据约定的API文档中的参数名获取传输数据。
例：
```
@ResponseBody
@RequestMapping("/toMyInfoStep6.do")
public Message toMyInfoStep6(@RequestBody String paramsJson) throws IOException {
 Message msg = null;
 try {
     JSONObject JO = JSON.parseObject(paramsJson);
     String token = (String) JO.get("token");
     UserInfo myInfo = userInfoService.getUserByToken(token);
     if (myInfo.getStatus() == 0) {
         msg = new Message(MessageType.M11209);
         return msg;
     }
     msg = new Message();
     Map<String, Object> map = new HashMap<>();
     map.put("myInfo", myInfo);
     map.put("confirm", userInfoService.getUserCertInfoById(myInfo.getId()));
     msg.setMap(map);
 } catch (Exception e) {
     logger.error("APP UserInfoController toMyInfoStep6 method error", e);
     msg = new Message(MessageType.M10001);
 }
 return msg;
}
```

>2、multipart/form-data

表单数据被编码为一条消息，页上的每个&lt;input&gt;对应消息中的一个部分，用boundary=---------------------------36243265420146"分割各个部分（boundary值由浏览器生成）。它不会对字符进行编码，一般用于传输二进制文件（图片、视频、、、）。

>3、text/plain

表单数据中的空格转换为 "+"加号，但不对特殊字符编码。（get方式会这样，post时不会）
