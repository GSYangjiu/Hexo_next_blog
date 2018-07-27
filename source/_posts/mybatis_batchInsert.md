---
title: Mybatis批量插入
date: 2017/12/19 16:46:25
tags: [深圳,Mybatis,后端]
categories: document
photo: http://oyo2a85eo.bkt.clouddn.com/banner/shenzhen.jpg
---

<center>_插插插..._</center>
<!-- more -->

### 批量插入
在for循环中插入数据，当循环次数比较大时，效率很低。使用批量插入效率就会高很多。<br>
什么是 **批量插入**：在每次循环中插入是插入一条数据，我们可以把要插入的数据用一个集合保存起来，比如List（建议用Linklist，LinkList增删效率比ArrayList高），等到遍历完毕，再做插入操作，当数据量非常庞大时，可以分批插入。

### 插入的三种方式
#### 普通insert

```
<insert id="insert" parameterType="CoffeeDateMessage" useGeneratedKeys="true" keyProperty="id">
        insert into m_coffee_date_message(
        coffee_date_id,
        publisher,
        user_id,
        scope,
        phone,
        open_id,
        send_count,
        break_time,
        status
        )values(
        #{coffeeDateId},
        #{publisher},
        #{userId},
        #{scope},
        #{phone},
        #{openId},
        #{sendCount},
        #{breakTime},
        #{status}
        )
    </insert>
```
#### 使用jdbc批量插入

```
Connection conn;
try {
    Class.forName("com.mysql.jdbc.Driver");
    conn = DriverManager.getConnection("jdbc:mysql://192.168.0.200:3306/xxx", "root", "root");
    conn.setAutoCommit(false);
    String sql = "insert into test_user (u_name,create_date) value (?,SYSDATE())";
    PreparedStatement prest = conn.prepareStatement(sql, ResultSet.TYPE_SCROLL_SENSITIVE,
            ResultSet.CONCUR_READ_ONLY);
    conn.setAutoCommit(false);

    for (int i = 1; i <= 100; i++) {
        prest.setString(1, "a" + i);
        prest.addBatch();
    }
    prest.executeBatch();
    conn.commit();
    conn.close();
} catch (Exception ex) {
    ex.printStackTrace();
}
```
#### mybatis批量插入

```
<insert id="batchInsertList" parameterType="java.util.List">
        insert into m_coffee_date_message
        (
        coffee_date_id,
        publisher,
        user_id,
        scope,
        phone,
        open_id,
        send_count,
        break_time,
        status
        )
        values
        <foreach item="item" index="index" collection="list" separator=",">
            (
            #{item.coffeeDateId},
            #{item.publisher},
            #{item.userId},
            #{item.scope},
            #{item.phone},
            #{item.openId},
            #{item.sendCount},
            #{item.breakTime},
            #{item.status}
            )
        </foreach>
    </insert>
```

### 三种方式效率
效率没有自己测试，拿别人的测试结果，<a href="http://blog.csdn.net/chenpy/article/details/53912752">原地址</a>，THKS，侵删。</br>

数据量分别是10，100，300，1000，5000条数据</br>
数量级别：10 批量插入耗时：141 非批量插入耗时：93 jdbc批量插入耗时：195</br>
数量级别：100 批量插入耗时：164 非批量插入耗时：970 jdbc批量插入耗时：718</br>
数量级别：300 批量插入耗时：355 非批量插入耗时：3030 jdbc批量插入耗时：1997</br>
数量级别：500 批量插入耗时：258 非批量插入耗时：5355 jdbc批量插入耗时：2974</br>
数量级别：1000 批量插入耗时：422 非批量插入耗时：8787 jdbc批量插入耗时：6440</br>
数量级别：5000 批量插入耗时：870 非批量插入耗时：43498 jdbc批量插入耗时：30368

<img id="YangBlog2" src="http://oyo2a85eo.bkt.clouddn.com//post/mybatis_batchInsert/mybatis_batchInsert.png">
