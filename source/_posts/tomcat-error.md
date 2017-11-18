---
title: <IDEA启动tomcat报错 Unable to ping server at localhost:1099
---

 <h3>正文</h3>

 在IDAE下启动tomcat时报错：

 Application Server was not connected before run configuration stop, reason: Unable to ping server at localhost:1099

 <img src="http://www.yangmiemie.info/wp-content/uploads/2017/11/tomcat-300x112.png" alt="" width="300" height="112" class="alignnone size-medium wp-image-81" />
 <hr />

 <!-- more -->

 <h3>解决方法</h3>

 上网查了查，发现大家给了这么几个解决方法

 <h4>1. jmx服务</h4>

 IDEA启用了jmx服务，而要启用tomcat的jmx服务比较麻烦，所以我们可以修改host文件来关闭jmx服务

 <blockquote>
   在/etc/hosts 中添加 127.0.0.1 localhost [计算机名]
     #   127.0.0.1       localhost  DESKTOP-TVV7CS3
 </blockquote>

 计算机名可以通过cmd中输入hostname来查询

 但我配置之后还是继续报错，所以不是这种原因

 <h4>2.java环境配置错误</h4>

 你的电脑里有多个jre，在IDEA里给Tomcat选jre时候必须要选你配置了环境变量的那个

 <h4>3.tomcat配置文件冲突</h4>

 tomcat bin文件夹中catalina.bat 文件中设置了jvm参数 set JAVA_OPTS= -Xmx1024M -Xms512M -XX:MaxPermSize=256m。把参数去掉就Ok了

 <img src="http://www.yangmiemie.info/wp-content/uploads/2017/11/host-300x75.png" alt="" width="300" height="75" class="alignnone size-medium wp-image-83" />

 问题解决