---
title: JavaScript ES6中export及export default的区别
date: 2018/6/13 15:02:00
tags: [武汉,ES6,前端]
categories: document
photo: http://oyo2a85eo.bkt.clouddn.com/%E4%B8%AD%E5%8D%97%E8%B4%A2%E7%BB%8F_%E6%99%9A%E9%9C%9E
---

<center>最近开始学习 **Vue** ，接触到了很多 **ES6** 的语法</center>
<!-- more -->

## ES6的模块化的基本规则或特点

1、每一个模块只加载一次， 每一个JS只执行一次， 如果下次再去加载同目录下同文件，直接从内存中读取。 一个模块就是一个单例，或者说就是一个对象；
2、每一个模块内声明的变量都是局部变量， 不会污染全局作用域；
3、模块内部的变量或者函数可以通过export导出；
4、一个模块可以导入别的模块_

## export、import和export default

export、import这两个很好理解，从字面意思就可以知道一个导出，一个导入。

export用于对外输出本模块（一个文件可以理解为一个模块）常量、函数、文件、模块；
import用于在一个模块中加载另一个含有export接口的模块，通过import+(常量 | 函数 | 文件 | 模块)名的方式，将其导入。

export default也是导出区别在于export default导出相当于为模块指定默认输出，export default和import时都不需要加上大括号，通过import import的就是export default的内容，因此一个文件中export可以有多个，但是export default只能有一个

```js
    //a.js文件
    let name = "Vincent";
    export { name }

    //main.js文件
    import { name } from "/.a.js"

    //可以写成：
    //a.js文件
    let name = "Vincent";
    export default name

    //main.js文件
    import name from "/.a.js"
```

## 几种导出方式
### 1、使用 export{} 导出
这里import要和export对应
```js
    //a.js文件
    let name = "Vincent";
    let method = function(){
        console.log("method")
    }
    export { name, method }

    //main.js文件
    import { name, method } from "/.a.js"
```

### 2、使用 export{ a as b} 导出
相当于导出时重命名
```js
    //a.js文件
    let name = "Vincent";
    export { name as firstName}

    //main.js文件
    import { firstName } from "/.a.js"
```

### 3、export时定义变量或者函数
类似于Java中的匿名函数
```js
    //a.js文件
    export let method == () => {console.log("method")}, name = "vincent";

    //main.js文件
    import { method, name } from "/.a.js"
```

### 4、export default
其实export default主要用于当一个js模块文件只有一个个功能的时候，直接用export default导出，导出时不需要为该模块命名,导入时自定义名称，非常方便。
```js
    //a.js文件
    export default "Vincent";

    //main.js文件
    import name from "/.a.js"
```

### 5、使用 export{ a as default} 导出
导出时将某个功能设置为默认模块，导入时自定义名称。
```js
    //a.js文件
    let method = () => "Vincent";
    export { method as default}

    //main.js文件
    import { defaultMethod } from "/.a.js"
```

### 6、使用 export a from  导出
相当于导出其他模块功能，结合5使用，重命名他模块中的默认导出，再导出，多用于新建一个js，统一管理import/export关系
```js
    export { default as Navbar } from './Navbar'
    export { default as Sidebar } from './Sidebar/index.vue'
    export { default as TagsView } from './TagsView'
    export { default as AppMain } from './AppMain'
```

## 参考
https://www.cnblogs.com/diligenceday/p/5503777.html
https://www.cnblogs.com/xiaotanke/p/7448383.html
