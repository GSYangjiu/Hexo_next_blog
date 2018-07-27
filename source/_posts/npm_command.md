---
title: npm常用命令
date: 2017/11/09 20:46:25
tags: [深圳,NPM,前端]
categories: document
photo: http://oyo2a85eo.bkt.clouddn.com/banner/cherry.jpg
---

<center>_不会前端的厨子不是好司机..._</center>
<!-- more -->

**查看当前镜像地址：**

npm get registry

**替换淘宝镜像：**

npm config set registry http://registry.npm.taobao.org/

**查看当前全局模块和cache位置：**

npm get prefix
npm get cache

**更改npm全局模块和cache默认安装位置：**

npm config set prefix "XXX\nodejs\node_global"
npm config set cache "XXX\nodejs\node_cache"
