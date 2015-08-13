**File Name** php-garbage-collection.md  

**Description** PHP 垃圾回收机制    
**Author** LiCunchang(printf@live.com)  
**Version** 2.0.20130417  

------

## 1 Reference Counting Basics

每个php变量存在一个叫"zval"的变量容器中。一个zval变量容器，除了包含变量的类型和值，还包括两个字节的额外信息。第一个是"is_ref"，是个bool值，用来标识这个变量是否是属于引用集合(reference set)。通过这个字节，php引擎才能把普通变量和引用变量区分开来，由于php允许用户通过使用&来使用自定义引用，zval变量容器中还有一个内部引用计数机制，来优化内存使用。第二个额外字节是"refcount"，用以表示指向这个zval变量容器的变量(也称符号即symbol)个数。所有的符号存在一个符号表中，其中每个符号都有作用域(scope)，那些主脚本(比如：通过浏览器请求的的脚本)和每个函数或者方法也都有作用域。

    /* zend.h */
    typedef struct _zval_struct zval;

    struct _zval_struct {
        /* Variable information */
        zvalue_value value;     /* value */
        zend_uint refcount__gc;
        zend_uchar type;    /* active type */
        zend_uchar is_ref__gc;
    };

当一个变量被赋常量值时，就会生成一个zval变量容器，如下例这样：  

    <?php
    $a = "new string";
    ?>

在上例中，新的变量a，是在当前作用域中生成的。并且生成了类型为 string 和值为new string的变量容器。在额外的两个字节信息中，"is_ref"被默认设置为 FALSE，因为没有任何自定义的引用生成。"refcount" 被设定为 1，因为这里只有一个变量使用这个变量容器. 注意到当"refcount"的值是1时，"is_ref"的值总是FALSE. 如果你已经安装了» Xdebug，你能通过调用函数 xdebug_debug_zval()显示"refcount"和"is_ref"的值。

    <?php
    $a = "new string";
    xdebug_debug_zval('a');
    ?>

以上例程会输出：

    a:
    (refcount=1, is_ref=0),string 'new string' (length=10)

把一个变量赋值给另一变量将增加引用次数(refcount).

    <?php
    $a = "new string";
    $b = $a;
    xdebug_debug_zval( 'a' );
    ?>

以上例程会输出：

    a:
    (refcount=2, is_ref=0),string 'new string' (length=10)

这时，引用次数是2，因为同一个变量容器被变量 a 和变量 b关联.当没必要时，php不会去复制已生成的变量容器。变量容器在”refcount“变成0时就被销毁. 当任何关联到某个变量容器的变量离开它的作用域(比如：函数执行结束)，或者对变量调用了函数 unset()时，”refcount“就会减1，下面的例子就能说明:

    <?php
    $a = "new string";
    $c = $b = $a;
    xdebug_debug_zval( 'a' );
    unset( $b, $c );
    xdebug_debug_zval( 'a' );
    ?>

以上例程会输出：

    a:
    (refcount=3, is_ref=0),string 'new string' (length=10)
    a:
    (refcount=1, is_ref=0),string 'new string' (length=10)

如果我们现在执行 unset($a);，包含类型和值的这个变量容器就会从内存中删除。







    <?php
    $a = array( 'meaning' => 'life', 'number' => 42 );
    xdebug_debug_zval( 'a' );
    ?>



    a:
    (refcount=1, is_ref=0),
    array (size=2)
      'meaning' => (refcount=1, is_ref=0),string 'life' (length=4)
      'number' => (refcount=1, is_ref=0),int 42



    <?php
    $a = array( 'meaning' => 'life', 'number' => 42 );
    $a['life'] = $a['meaning'];
    xdebug_debug_zval( 'a' );
    ?>


    a:
    (refcount=1, is_ref=0),
    array (size=3)
      'meaning' => (refcount=2, is_ref=0),string 'life' (length=4)
      'number' => (refcount=1, is_ref=0),int 42
      'life' => (refcount=2, is_ref=0),string 'life' (length=4)



    <?php
    $a = array( 'meaning' => 'life', 'number' => 42 );
    $a['life'] = $a['meaning'];
    unset( $a['meaning'], $a['number'] );
    xdebug_debug_zval( 'a' );
    ?>


    a:
    (refcount=1, is_ref=0),
    array (size=1)
      'life' => (refcount=1, is_ref=0),string 'life' (length=4)

    <?php
    $a = array( 'one' );
    $a[] =& $a;
    xdebug_debug_zval( 'a' );
    ?>


    a:
    (refcount=2, is_ref=1),
    array (size=2)
      0 => (refcount=1, is_ref=0),string 'one' (length=3)
      1 => (refcount=2, is_ref=1),
        &array



    <?php
    $a = array( 'one' );
    $a[] =& $a;
    unset($a);
    xdebug_debug_zval( 'a' );
    ?>


    <?php
    $a = "string";
    xdebug_debug_zval('a');
    $b = $a;
    xdebug_debug_zval('a');
    xdebug_debug_zval('b');
    $c = & $a;
    xdebug_debug_zval('a');
    xdebug_debug_zval('b');
    xdebug_debug_zval('c');
    ?>

    a:
    (refcount=1, is_ref=0),string 'string' (length=6)
    a:
    (refcount=2, is_ref=0),string 'string' (length=6)
    b:
    (refcount=2, is_ref=0),string 'string' (length=6)
    a:
    (refcount=2, is_ref=1),string 'string' (length=6)
    b:
    (refcount=1, is_ref=0),string 'string' (length=6)
    c:
    (refcount=2, is_ref=1),string 'string' (length=6)


    <?php
    $a = "string";
    xdebug_debug_zval('a');
    $b = $a;
    xdebug_debug_zval('a');
    xdebug_debug_zval('b');
    $b = "licunchang";
    xdebug_debug_zval('a');
    xdebug_debug_zval('b');
    ?>


    a:
    (refcount=1, is_ref=0),string 'string' (length=6)
    a:
    (refcount=2, is_ref=0),string 'string' (length=6)
    b:
    (refcount=2, is_ref=0),string 'string' (length=6)
    a:
    (refcount=1, is_ref=0),string 'string' (length=6)
    b:
    (refcount=1, is_ref=0),string 'licunchang' (length=10)


    <?php
    $a = "string";
    xdebug_debug_zval('a');
    $b = & $a;
    xdebug_debug_zval('a');
    xdebug_debug_zval('b');
    $b = "licunchang";
    xdebug_debug_zval('a');
    xdebug_debug_zval('b');
    ?>

    a:
    (refcount=1, is_ref=0),string 'string' (length=6)
    a:
    (refcount=2, is_ref=1),string 'string' (length=6)
    b:
    (refcount=2, is_ref=1),string 'string' (length=6)
    a:
    (refcount=2, is_ref=1),string 'licunchang' (length=10)
    b:
    (refcount=2, is_ref=1),string 'licunchang' (length=10)



    <?php

    $a = "string";
    $b = "string";

    xdebug_debug_zval('a');
    xdebug_debug_zval('b');
    ?>

    a:
    (refcount=1, is_ref=0),string 'string' (length=6)
    b:
    (refcount=1, is_ref=0),string 'string' (length=6)