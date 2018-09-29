---
title: 跨域与解决方案
date: 2018/9/27 12:02:00
tags: [武汉,Web,前端]
categories: document
photo: http://oyo2a85eo.bkt.clouddn.com/cloudyday.jpg
---

<center>_跨向全栈..._</center>
<!-- more -->

### 同源策略
**前后端分离项目** 经常需要处理跨域问题，总所周知，跨域问题是由于浏览器的 *同源策略* 导致的。所以先介绍下浏览器同源策略： **“如果两个页面的协议，域名和端口（如果有指定）都相同，则两个页面具有相同的源。”**

例如相对于<http://www.yangmiemie.info/index/page.html>网址：

| URL | 同源 | 原因 |
| ------ | ------ | ------ |
| <http://www.yangmiemie.info/index/other.html> | 成功 |  |
| <http://www.yangmiemie.info/index/inner/another.html> | 成功 |  |
| <https://www.yangmiemie.info/secure.html> | 失败 | 不同协议 ( https和http ) |
| <http://www.yangmiemie.info:81/index/etc.html> | 失败 | 不同端口 ( 81和80) |
| <http://github.yangmiemie.info/index/other.html> | 失败 | 不同域名 ( www和github ) |

不同源的网址访问就会发生跨域问题，主要是浏览器为了防止CSRF攻击，什么是CSRF攻击就不展开讲了，简单描述一下就是现在绝大部分浏览器都是cookie共享的，如果你同时打开了网站A和钓鱼网站B，由于你已经登陆了网站A，sessionId已经储存在cookie中，网站B可以利用网站A的cookie发起直接向网站A服务器发起恶意请求，实现攻击操作。由于有同源策略，网站B发起的Ajax请求就会失败。

那么如果我们的项目是前后端分离的，前后端部署在不同的服务器上，发起的请求也都是不同源的，这个时候就需要实现跨域访问了。一般跨域解决方案有两种，**jsonp** 和 **cors**。

### 解决方案
#### jsonp
jsop解决跨域问题较为简单粗暴，基本思想是，网页通过添加一个&lt;script&gt;元素，向服务器请求JSON数据，这种做法不受同源政策限制( **拥有"src"这个属性的标签都拥有跨域的能力** )；服务器收到请求后，将数据放在一个指定名字的回调函数里传回来。jsonp需要在URL后追加一个 **callback** 参数指定回调函数名。
例如：

```javascript
    function addScriptTag(src) {
        var script = document.createElement('script');
        script.setAttribute("type","text/javascript");
        script.src = src;
        document.body.appendChild(script);
    }

    window.onload = function () {
        addScriptTag('http://www.yangmiemie.info/getUserName?id=001&callback=show');
    }

    function show(data) {
        console.log('username is ' + data.username);
    };
```

上面代码是jsonp的实现原理，平时如果使用jquery进行跨域请求，代码如下

```javascript
    $.ajax({
             type: "get",
             async: false,
             url: "http://www.yangmiemie.info/getUserName?id=001",
             dataType: "jsonp",
             jsonp: "callback",//传递给请求处理程序或页面的，用以获得jsonp回调函数名的参数名(一般默认为:callback)
             jsonpCallback:"show",//自定义的jsonp回调函数名称，默认为jQuery自动生成的随机函数名，也可以写"?"，jQuery会自动为你处理数据
             success: function(data){
                 console.log('username is ' + data.username);
             },
             error: function(){
                 console.log('fail');
             }
         });
```

服务器支持jsonp，必须通过jsonp参数获取jsonp回调函数名的参数名，然后按指定格式返回，所以可以在后台添加逻辑控制，比如指定可以跨域接口，来确保服务器安全。

```java
    String callback = request.getParameter("callback"); //不指定函数名默认 callback
    return callback + "(" + jsonStr + ")"
```
需要注意的是jsonp只能发送 **get** 请求。

#### cors
相对于 **jsonp**， **cors**原理较为复杂，但是使用cors非常简单，因为现在大多数浏览器的支持，整个cors的通信过程，都是浏览器自动完成的，不需要用户参与。浏览器一旦发现AJAX请求跨源，就会自动添加一些附加的头信息，有时还会多出一次附加的请求，但用户不会有感觉。

##### 两种请求
浏览器将cors请求分成两类，简单请求和非简单请求，只要同时满足以下两大条件，就属于简单请求。
>(1) 请求方法是以下三种方法之一：  
>    HEAD  
>    GET  
>    POST  
>(2) HTTP的头信息不超出以下几种字段：  
>    Accept    
>    Accept-Language  
>    Content-Language  
>    Last-Event-ID  
>    Content-Type：只限于三个值application/x-www-form-urlencoded、multipart/form-data、text/plain

##### 简单请求
对于简单请求，浏览器直接发出CORS请求。具体来说，就是在头信息之中，增加一个Origin字段。
下面是一个例子，浏览器发现这次跨源AJAX请求是简单请求，就自动在头信息之中，添加一个Origin字段。
>GET /cors HTTP/1.1  
Origin: http://api.bob.com  
Host: api.alice.com 
Accept-Language: en-US  
Connection: keep-alive  
User-Agent: Mozilla/5.0...  

Origin字段用来说明，本次请求来自哪个源（协议 + 域名 + 端口）。服务器根据这个值，决定是否同意这次请求。

##### 非简单请求
当请求方法不满足简单请求的两大条件时，比如请求方法是PUT或DELETE，或者Content-Type字段类型是application/json，该次请求就属于非简单请求。

非简单请求的CORS请求，会在正式通信之前，增加一次HTTP查询请求，称为"预检"请求（preflight）。

预检请求响应头
>OPTIONS /cors HTTP/1.1     
Origin: http://api.bob.com  
Access-Control-Request-Method: PUT  
Access-Control-Request-Headers: X-Custom-Header 
Host: api.alice.com 
Accept-Language: en-US  
Connection: keep-alive  
User-Agent: Mozilla/5.0...  

##### cors总结
使用CORS解决跨域问题，简单来看就是在请求的请求头中添加了 **Origin** 字段，该字段包含请求的发起域名，服务器的响应头中包含了 **Access-Control-Allow-Origin** 字段，该字段包含服务器支持的域名。再加上其他可选附带字段，提供更多信息，例如 **
Access-Control-Allow-Methods** 、 **Access-Control-Allow-Headers** 、 **Access-Control-Max-Age** 等，这个过程客户端编码过程是无感知的，也就是说普通跨域请求：只服务端设置Access-Control-Allow-Origin即可，可以通过服务端代码实现，也可以通过nginx配置，而前端无须设置，若要带cookie请求：服务端端需要另外开启 **Access-Control-Allow-Credentials: true** ，前端需要AJAX请求中打开 **withCredentials** 属性。

#### jsonp和cors对比
jsonp和cors但就使用来说都较为简单，实现原理jsonp较为简单，便于理解，但是jsonp只能支持 **get** 请求，cors不受此限制。
cors更为强大和规范，jsonp更像一种早期开发者通过自身智慧想到的解决跨域问题的方案，后来用的人多了就成了一种默认的方法，而cors受到浏览器和服务端的支持，更为规范。个人建议还是使用cors来解决跨域问题。

#### 其他跨域方案
跨域问题其实还有很多种解决方案，包括前端到后端，总觉得一个开发者视界应该广阔些，不应局限于一种技术、语言、解决方案，才能更从容地应对千变万化的需求。

下面几种方案只简单介绍一下
>iframe

使用iframe实现跨域，更类似于两个不同域名的网站通过iframe拼接到一起。
```javascript
    // 父窗口：(http://www.domain.com/a.html)
    <iframe id="iframe" src="http://child.domain.com/b.html"></iframe>
    <script>
    document.domain = 'domain.com';
    var user = 'admin';
    </script>
    
    // 子窗口：(http://child.domain.com/b.html)
    <script>
    document.domain = 'domain.com';
    // 获取父窗口中变量
    alert('get js data from parent ---> ' + window.parent.user);
    </script>
```

>nginx代理和Nodejs中间件代理跨域

同源策略是浏览器的安全策略，不是HTTP协议的一部分。服务器端调用HTTP接口只是使用HTTP协议，不会执行JS脚本，不需要同源策略，也就不存在跨越问题。所以通过搭建一个代理服务器，转发请求以解决跨域问题。

>WebSocket协议跨域

WebSocket已经更换了协议，都不是http\https了，它实现了浏览器与服务器全双工通信，同时允许跨域通讯，使用较少。
