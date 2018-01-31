---
title: Mybatis insert 返回主键
date: 2017/12/05 16:46:25
tags: [深圳,Mybatis]
categories: Web
---

<center>_还是插插插..._</center>
<img src="http://oyo2a85eo.bkt.clouddn.com/banner/tony.png">
<!-- more -->

### mybatis做insert操作的时候返回插入的那条数据的id

#### 对于支持具有自增长方式的数据库（如mysql）<br>
设置 **useGeneratedKeys="true"**
```
<insert id="insert" parameterType="Place" useGeneratedKeys="true" keyProperty="id">
        insert into m_place(
        name,
        address,
        create_time,
        update_time
        )values(
        #{name},
        #{address},
        #{createTime},
        #{updateTime}
        )
    </insert>
```
注意，返回值不是主键，返回的是被操作的记录条数。要获取主键：
```
placeDAO.insert(newPlace);
System.out.println("主键：" + newPlace.getId());
dateRecord.setAgreePlace(newPlace.getId().intValue());
```
insert操作之后，传入的newPlace的实体会自动获取主键。

#### 对于不支持具有自增长方式的数据库（如Oracle）<br>

```
<insert id="xxx" parameterType="yyy">
         <selectKey keyProperty="id" resultType="long" order="BEFORE">
            select my_seq.nextval from dual
         </selectKey>
       ...
</insert>
```
