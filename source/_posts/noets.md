---
title: Notes
date: 2018/7/13 10:02:00
tags: [武汉,笔记]
categories: document
photo: http://oyo2a85eo.bkt.clouddn.com//post/notes
---

<center>_笔记..._</center>
<!-- more -->

### js遍历数组

#### 数组的长度只查询一次而非每次循环都要查询

```
    for(var i=0,len=keys.length; i<len; i++){
        //循环体不变
    }
```


#### 稀疏数组遍历

1、排除null，undefined

```js
    for(var i=0; i<a.length; i++){
        if(!a[i]) continue;//跳过null、undefined
        //循环体
    }
```

2、跳过undefined和不存在的元素

```js
    for(var i=0; i<a.length; i++){
        if(a[i] === undefined) continue;//跳过undefined和不存在的元素
        //循环体
    }
```

3、跳过不存在的元素，仍处理undefined

```js
    for(var i=0; i<a.length; i++){
        if(!(i in a)) continue;//跳过undefined和不存在的元素
        //循环体
    }
```

还可以使用 **for/in** 循环，不存在的索引将不会遍历到
**for/in** 注意点：
1、**for/in** 循环能枚举继承的属性名，如添加到 **Array.prototype** 。由于这个原因，在数组上不应该使用 **for/in** 循环，除非使用额外的检测方法来过滤不想要的属性。
2、**for/** 循环遍历对象属性顺序不确定，如果算法依赖于遍历的顺序，最好使用常规 **for** 循环
--《JavaScript权威指南》P150

*** Oracle恢复删除表
TableName:表名
```sql
    select * from recyclebin WHERE ORIGINAL_NAME LIKE 'TableName%';
    flashback table TableName to before drop;
```
