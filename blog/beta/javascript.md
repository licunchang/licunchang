**File Name** javascript.md  
**Description**  《Javascript权威指南》读书笔记  
**Author** LiCunchang (printf@live.com)  
**Version** 1.0.20141001  

------

## 2 词法结构

Javascript 是用 Unicode 字符集编写的。

## 3 类型、值和变量

Javascript 的数据类型分为两类：原始类型（primitive type）和对象类型（object type）。Javascript 中的原始类型包括数字、字符串和布尔值。Javascript 中有两个特殊的原始值：null（空）和 undefined（未定义）。

普通的 Javascript 对象是“命名值”的无序集合，Javascript 还定义了一种特殊对象——数组，表示带编号的值的有序集合。Javascript 还定义了一种特殊对象——函数。

除了数组（Array）和函数（Function）类之外，Javascript 语言核心还定义了其他三种有用的类：日期（Date）、正则（RegExp）、错误（Error）。

从技术讲，只有 Javascript 对象才能拥有方法，然而，数字、字符串和布尔值也可以拥有自己的方法，在 Javascript 中，只有 null 和 undefined 是无法拥有方法的值。

在 Javascript 中对象和数组属于可变类型，数字、布尔值、字符串、null 和 undefined 属于不可变类型。

Javascript 采用词法作用域（lexcal scoping），不在任何函数内声明的变量称作全局变量，它在 Javascript 程序中的任何地方都是可见的。在函数内声明的变量具有函数作用域并且只在函数内可见。

Javascript 不区分整数值和浮点数值，Javascript 中的所有数字均用浮点数值表示，

Javascript 中的算术运算在溢出（overflow）、下溢（underflow）或被零整除时不会报错，当数字运算结果超过了 Javascript 所能表示的数字上限（溢出），结果为一个特殊的无穷大（infinity）值，在 Javascript 中以 Infinity 表示，同样的，当负数的值超过了 Javascript 所能表示的负数范围，结果为负无穷大，在 Javascript 中以 -Infinity 表示，无穷大值的行为特性和我们所期望的是一致的：基于他们的加减乘除运算结果还是无穷大值（当然还保留他们的正负号）。

下溢（underflow）是当运算结果无限接近于零并比 Javascript 能表示的最小值还小的时候发生的一种情形，这种情况下，Javascript 将会返回 0 ，当一个负数发生下溢时，Javascript 返回一个特殊的值“负零”，这个值几乎和正常的零完全一致。

被零整除在 Javascript 并不报错，它只是简单的返回无穷大或者负无穷大，但是有一个例外，零除以零是没有意义的，这种整除运算结果也是一个非数字值，用 NaN 表示，Javascript中的非数字值有一点特殊：他和任何值都不相等，包括自身，也就是说，没办法通过 x == NaN 来判断变量 x 是否是 NaN ，相反，应当使用 x != x 来判断，当且仅当x为NaN 的时候，表达式的值才是 true。

字符串是一组由 16 位值组成的不可变的有序序列，每个字符通常来自于 Unicode 字符集。Javascript 采用 UTF-16 编码的 Unicode 字符集，Javascript 字符串是由一组无符号的 16 位值组成的序列，对于不能表示为 16 位的Unicode 字符则遵循 UTF-16 编码规则——用两个 16 位值组成的一个序列表示，这意味着**一个长度为 2 的 Javascript 字符串有可能表示一个 Unicode 字符**。

Javascript 定义了 RegExp() 构造函数，用来创建表示文本匹配模式的对象，这些模式称为“正则表达式”，Javascript 采用 Perl 中的正则表达式语法，尽管 RegExp 并不是语言中的基本数据类型，但是他们依然具有直接量写法，可以直接在 Javascript 程序中使用，在两条斜线之间的文本构成了一个正则表达式直接量，第二条斜线之后也可以跟随一个或多个字母，用来修饰匹配模式的含义。

任意 Javascript 的值都可以转换为布尔值，下面的这些值会被转换成 false： underfined、null、0、-0、NaN、""，其他所有值，包括所有对象数组等都回转换成 true。

null 是 Javascript 的关键字，对 null 执行 typeof ，结果返回字符串 “object”。同样，对 undefined 执行 typeof 也返回 “object”，他们分别是各自类型的唯一一个成员，尽管 null 和undefined 是不同的，但他们都表示“值的空缺”，两者往往可以互换，判断相等运算符“==” 认为两者是相等的。如果要将他们赋值给变量或者属性，或将他们作为参数传入函数，最佳选择是使用null。

全局对象（global object）是一类非常重要的对象，全局对象的属性是全局定义的符号，Javascript 程序可以直接使用，当 Javascript 解释器启动或者任何Web浏览器加载新页面的时候，它将创建一个新的全局对象，并给他一组定义的初始属性，全局对象的初始属性并不是保留字，但是他们应该当作保留字来对待，

在代码的最顶级——不在任何函数内的 Javascript 代码——可以使用Javascript 关键字 this 来引用全局对象：`var global = this; // 定义一个引用全局对象的全局变量`。在客户端 Javascript 中，在其表示的浏览器窗口中的所有 Javascript 代码中，Window 对象充当了全局对象，这个全局 Window 对象有一个属性 window 引用其自身，它可以代替 this 来引用全局对象。Window 对象定义了核心全局属性，但他也针对web浏览器和客户端 Javascript 定义了一少部分其他全局属性。全局对象同样包含了为程序定义的全局值，**如果代码声明了一个全局变量，这个全局变量就是全局对象的一个属性。**

对象到布尔值的转换非常简单：所有对象，包括数组和函数都转换成 true。对于包装对象也是如此，`new Boolean(false)` 是一个对象而不是原始值，它将转换为 true。

对象到字符串和对象到数字的转换是通过待转换对象的一个方法来完成的。所有的对象继承了两个转换方法，第一个是 `toString()`，它的作用是返回一个反映这个对象的字符串，另一个转换对象的函数是 `valueOf()`，这个方法的任务并未详细定义，如果存在任意原始值，它就默认将对象转换为表示它的原始值，对象是复合值，而且大多数对象无法真正表示为一个原始值，因此默认的 valueOf() 方法简单地返回对象本身，而不是返回一个原始值。





































