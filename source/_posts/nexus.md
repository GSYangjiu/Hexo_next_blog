---
title: 搭建Nexus Maven私服
date: 2018/1/30 20:46:25
tags: [Linux,Maven,后端]
categories: document
photo: https://s2.ax1x.com/2019/02/21/kRgNDI.png
---
<center>_做web开发的对Maven肯定不会陌生..._</center>
<!-- more -->

### 前言
做web开发的对Maven肯定不会陌生，强大的Maven为项目构建、项目管理和第三方Jar包管理提供了支撑。在一个项目中Maven默认提供的中央仓库是在远程网络服务Appache提供的，搭建一个新项目的时候经常下jar包下的捉急，太慢了，其实在maven的settings.xml配置文件中配置第三方镜像就ok了。但是这么简单这么可以满(zhuang)足(bi)！于是利用闲暇之余，捣鼓了一下怎么搭建nexus私服。至于什么是nexus私服，我们可以先看看文章顶部那张图。

私服就是相当于在Maven本地仓库和中心服务器之间搭建了一个代理服务器，你可将第三方jar包下载至Nexus服务器，在为本地仓库提供服务。而且在我们项目中，经常有一些自己提供的jar包，我们可以上传到私服，再建立服务依赖关系，这样代码就不存在泄露问题，而且管理也非常方便。

Ps：开始我以为Nexus只能提供maven管理，搭建完后才发现Nexus功能相当强大，还能进行提供doker，npm，yum等一系列代理服务，厉害了我的哥。

<!-- more -->

### Nexus搭建流程

*话不多说，是时候展示正真的技术。*

#### 安装Nexus
私服首先你肯定要有一个服务器，linux也好，windows也行。下文一linux为例演示
1、下载Nexus安装文件：http://www.sonatype.org/nexus/go
2、Ftp上传至linux服务器指定目录
3、解压就可以运行，不需要安装
4、cd到bin目录，输入命令：*./nexus start*

<img src="http://oyo2a85eo.bkt.clouddn.com//post/nexus/nexus_installation.png">

5、访问 `http://139.199.192.109:8081`或者`http://139.199.192.109:8081/nexus`,加不加nexus可能跟版本有关系，自己试试就行,ip为服务器地址，8081是Nexus默认端口，可以自己修改。

<img src="http://oyo2a85eo.bkt.clouddn.com//post/nexus/nexus_login.png">

6、默认用户：admin，密码：admin123，建议登陆后先修改一下密码

#### 配置Maven
直接贴出我Maven的settings.xml，上面<mirrors>是一些镜像地址，避免国内下载jar包太慢，在下面<profiles>中配置了Nexus仓库，注意对应关系，仓库地址Url可以在上一步，Nexus可视化后台中查看仓库详情Cpoy。
```xml
<?xml version="1.0" encoding="UTF-8"?>
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0 http://maven.apache.org/xsd/settings-1.0.0.xsd">

    <pluginGroups/>
    <proxies/>
    <mirrors>
		 <mirror>
			   <id>repo2</id>
			   <mirrorOf>central</mirrorOf>
			   <name>Human Readable Name for this Mirror.</name>
			  <url>http://repo2.maven.org/maven2/</url>
		 </mirror>
		 <mirror>
			   <id>net-cn</id>
			   <mirrorOf>central</mirrorOf>
			   <name>Human Readable Name for this Mirror.</name>
			   <url>http://maven.net.cn/content/groups/public/</url>
		 </mirror>
		 <mirror>
			   <id>ui</id>
			   <mirrorOf>central</mirrorOf>
			   <name>Human Readable Name for this Mirror.</name>
			  <url>http://uk.maven.org/maven2/</url>
		 </mirror>
		 <mirror>
			   <id>ibiblio</id>
			   <mirrorOf>central</mirrorOf>
			   <name>Human Readable Name for this Mirror.</name>
			  <url>http://mirrors.ibiblio.org/pub/mirrors/maven2/</url>
		 </mirror>
		 <mirror>
			   <id>jboss-public-repository-group</id>
			   <mirrorOf>central</mirrorOf>
			   <name>JBoss Public Repository Group</name>
			  <url>http://repository.jboss.org/nexus/content/groups/public</url>
		 </mirror>
		  <mirror>
		  <id>CN</id>
		   <name>OSChina Central</name>
		   <url>http://maven.oschina.net/content/groups/public/</url>
		   <mirrorOf>central</mirrorOf>
		 </mirror>
		 <mirror>
		   <id>alimaven</id>
		   <mirrorOf>central</mirrorOf>
		   <name>aliyun maven</name>
		   <url>http://maven.aliyun.com/nexus/content/groups/public/</url>
		 </mirror>
	</mirrors>

    <profiles>
        <profile>
            <id>nexus-public</id>
            <repositories>
                <repository>
                    <id>nexus-public</id>
                    <name>local public nexus</name>
                    <url>http://139.199.192.109:8081/repository/maven-public/</url>
                </repository>
            </repositories>
        </profile>
        <profile>
            <id>nexus-releases</id>
            <repositories>
                <repository>
                    <id>nexus-releases</id>
                    <name>local private nexus releases</name>
                    <url>http://139.199.192.109:8081/repository/maven-releases/</url>
                </repository>
            </repositories>
        </profile>
        <profile>
            <id>nexus-snapshots</id>
            <repositories>
                <repository>
                    <id>nexus-snapshots</id>
                    <name>local private nexus snapshots</name>
                    <url>http://139.199.192.109:8081/repository/maven-snapshots/</url>
                </repository>
            </repositories>
        </profile>
    </profiles>

    <activeProfiles>
        <activeProfile>nexus-public</activeProfile>
        <activeProfile>nexus-releases</activeProfile>
        <activeProfile>nexus-snapshots</activeProfile>
    </activeProfiles>

    <servers>
        <server>
            <id>releases</id>
            <username>admin</username>
            <password>admin123</password>
        </server>
        <server>
            <id>snapshots</id>
            <username>admin</username>
            <password>admin123</password>
        </server>
    </servers>

</settings>
```


#### 修改项目pom.xml
项目的pom文件中要加入下面这段代码。id需要和settings.xml中<servers>中的仓库id一致，但是不明白为什么又要再配置一次Url地址
```xml
<distributionManagement>
		<repository>
			<id>releases</id>
			<url>http://139.199.192.109:8081/repository/maven-releases/</url>
		</repository>
		<snapshotRepository>
			<id>snapshots</id>
			<url>http://139.199.192.109:8081/repository/maven-snapshots/</url>
		</snapshotRepository>
	</distributionManagement>
```

然后就可以在idea中使用了，下载的第三方jar包在Nexus中都会备份，就避免项目过大，每个人都要下载。使用deploy命令可以将当前项目打包上传到Nexus私服，很方便管理项目直接互相依赖。

<img src="http://oyo2a85eo.bkt.clouddn.com//post/nexus/deploy.png">

在Nexus后台可以查看当前仓库中存在的jar包

<img src="http://oyo2a85eo.bkt.clouddn.com//post/nexus/repository.png">
