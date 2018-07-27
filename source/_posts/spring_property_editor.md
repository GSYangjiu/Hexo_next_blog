---
title: Spring属性注册编辑器
date: 2018/7/25 12:02:00
tags: [武汉,Spring,后端]
categories: document
photo: http://oyo2a85eo.bkt.clouddn.com//post/notes
---

<center>_Spring DI..._</center>
<!-- more -->

### 情景
**Spring DI** 注入的时候可以很轻松的注入普通变量，也可以通过嵌套注入对象，但嵌套的对象的属性还是普通变量。加假如我们要注入一个 *Date* 类型就会比较麻烦。

```
    public class UserManger {
        private Date dataValue;

        public Date getDataValue() {
            return dataValue;
        }

        public void setDataValue(Date dataValue) {
            this.dataValue = dataValue;
        }

        @Override
        public String toString() {
            return "UserManger{" +
                    "dataValue=" + dataValue +
                    '}';
        }
    }
```
在配置文件中对日期属性进行注入：
```
    <bean id="userManger" class="spring.entity.UserManger">
        <property name="dataValue">
            <value>2018-07-25</value>
        </property>
    </bean>
```
测试代码：
```
    @Test
    public void testData() {
        ApplicationContext ctx = new ClassPathXmlApplicationContext("spring-web-context.xml");
        UserManger userManger = (UserManger) ctx.getBean("userManger");
        System.out.println(userManger);
    }
```

如果按照我们常规这样使用，程序就会报错，因为UserManager中的dataValue属性是 *Date* 类型，而在XML配置中却是 *String* 类型。
```
org.springframework.beans.factory.BeanCreationException: Error creating bean with name 'userManger' defined in class path resource [spring-web-context.xml]:
Initialization of bean failed; nested exception is org.springframework.beans.ConversionNotSupportedException: Failed to convert
property value of type 'java.lang.String' to required type 'java.util.Date' for property 'dataValue'; nested exception is java.lang.IllegalStateException: Cannot
convert value of type [java.lang.String] to required type [java.util.Date] for property 'dataValue': no matching editors or conversion strategy found

	at org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory.doCreateBean(AbstractAutowireCapableBeanFactory.java:553)
    ··· ···
	at com.intellij.rt.execution.junit.IdeaTestRunner$Repeater.startRunnerWithArgs(IdeaTestRunner.java:47)
	at com.intellij.rt.execution.junit.JUnitStarter.prepareStreamsAndStart(JUnitStarter.java:242)
	at com.intellij.rt.execution.junit.JUnitStarter.main(JUnitStarter.java:70)
```

### 解决方案
>Spring提供两种解决方案

#### 使用自定义属性编辑器
使用自定义属性编辑器，通过继承 **ProPetyEdiTorSupport** ,重写 **setAsText** 方法，具体步骤如下。

##### 编写自定义的属性编辑器
```
    public class DateProPertyEditor extends PropertyEditorSupport {
        private String format = "yyyy-MM-dd";

        public void setFormat(String format) {
            this.format = format;
        }

        @Override
        public void setAsText(String text) throws IllegalArgumentException {
            System.out.println("text: " + text);
            SimpleDateFormat sdf = new SimpleDateFormat(format);
            try {
                Date d = sdf.parse(text);
                this.setValue(d);
            } catch (ParseException e) {
                e.printStackTrace();
            }
        }
    }
```

##### 将自定义的属性编辑器注册到Spring中
```
    <bean class="org.springframework.beans.factory.config.CustomEditorConfigurer">
        <property name="customEditors">
            <map>
                <entry key="java.util.Date" value="spring.DatePropertyEditor">
                </entry>
            </map>
        </property>
    </bean>
```

输出结果：
```
log4j:WARN No appenders could be found for logger (org.springframework.core.env.StandardEnvironment).
log4j:WARN Please initialize the log4j system properly.
log4j:WARN See http://logging.apache.org/log4j/1.2/faq.html#noconfig for more info.
text: 2018-07-25
UserManger{dataValue=Wed Jul 25 00:00:00 CST 2018}
```

主要就是在配置文件中引入 **CustomEditorConfigurer** ，并在属性 **customEditors** 中加入自定义的属性编辑器，key为属性编辑器要处理的类型，value为属性编辑器Class。通过这样配置，当Spring再注入bean的属性时一旦遇到java.util.Date类型的属性会自动调用自定义的DatePropertyEditor解析器进行解析，并用解析结果代替配置属性进行注入。

#### 注册Spring自带的属性编辑器CustomDateEditor

##### 定义属性编辑器
```
    public class DatePropertyEditorRegistrar implements PropertyEditorRegistrar {
        @Override
        public void registerCustomEditors(PropertyEditorRegistry registry) {
            registry.registerCustomEditor(Date.class, new CustomDateEditor(new SimpleDateFormat("yyyy-MM-dd"), true));
        }
    }
```
###### 注册到Spring中
```
    <bean class="org.springframework.beans.factory.config.CustomEditorConfigurer">
        <property name="propertyEditorRegistrars">
            <list>
                <bean class="spring.DatePropertyEditorRegistrar"></bean>
            </list>
        </property>
    </bean>
```
