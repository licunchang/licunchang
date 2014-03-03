**File Name** mysql-character-set-collation.md  
**Description**  MySQL 的 character set 和 collation 简介   
**Author** LiCunchang (printf@live.com)  
**Version** 1.0.20130320  

------

## 1 什么是 character set 和 collation ？

### 1.1 Character set

>A **character set** is a set of symbols and encodings. [[1]][1]

character set 是一套符号及其编码的集合。举个例子，我们有四个字母的字母表，“A”、“B”、“a”、“b”，我们把四个字母依次编码为“A” = 0, “B” = 1, “a” = 2, “b” = 3。那么，字母 `A` 就是一个符号，而数字 `0` 就是符号 `A` 的编码。然后这四个字母和和四个字母所对应的编码就是一套 character set。

### 1.2 Collation

>A **collation** is a set of rules for comparing characters in a character set. [[1]][1]

Collation 就是在相应的 character set 下比较 character 的规则。在上面的 character set 中，我们要比较字母 “A” 和 “B” ，最简单的方式就是去比较两个字符的编码：“A” 对应 0 ，“B” 对应 1 ，因为 0 小于 1 ，所以我们就说 “A” 小于 “B” ，这样，我们就为上面的拥有四个字母的 character set 建立了一套比较的规则，这套规则就叫做 collation 。这种简单比较字符编码的 collation 通常我们称为 **binary collation** 。

但是有时候我们比较字母的时候会忽略大小写的因素，那么基于这种考虑的比较规则就有两个步骤：1) 将比较的两个字母同时转换成相同的大写或者小写形式；2) 比较它们各自的编码。这样的比较规则就比上面单纯比较字母编码的规则要复杂一些。这是一种 **case-insensitive collation(大小写不敏感 collation)**

实际上，大部分的 character set 中包含许许多多的字符，甚至包括一些多字节字符或者特殊字符。与此同时，相应的 collation 也有很多的比较规则，不局限于判断字符的大小写或者编码，甚至包括字符的音调等。总而言之，存在多种多样的 character set，然后每一种 character set 有多种多样的 collation 。

### 1.3 MySQL中的 character set 和 collation

MySQL 包含了对多种 character set 和相应 collation 的支持，其中：

* 可以使用多种多样的 character set 来存储数据
* 每一种 character set 至少有一种 collation
* 可以在同一个服务器、同一个数据库甚至同一个表中使用不同的 character set 来存储数据
* 可以在`server`、`database`、`table`或`column`级别对 character set 进行设定

我们可以通过在客户端下执行`SHOW CHARACTER SET`来查看 MySQL 所支持的 character set，下面的代码截取自一部分显示结果：

    mysql> SHOW CHARACTER SET;
    +----------+-----------------------------+---------------------+--------+
    | Charset  | Description                 | Default collation   | Maxlen |
    +----------+-----------------------------+---------------------+--------+
    | big5     | Big5 Traditional Chinese    | big5_chinese_ci     |      2 |
    | dec8     | DEC West European           | dec8_swedish_ci     |      1 |
    | cp850    | DOS West European           | cp850_general_ci    |      1 |
    ……
    | eucjpms  | UJIS for Windows Japanese   | eucjpms_japanese_ci |      3 |
    +----------+-----------------------------+---------------------+--------+
    39 rows in set (0.00 sec)

在 MySQL 中任何给定的 character set 都至少提供一种 collation ，有的 character set 甚至包含多种 collation 。使用 `SHOW COLLATION` 命令列出当前系统所提供的 collation 。

    mysql> SHOW COLLATION;
    +--------------------------+----------+-----+---------+----------+---------+
    | Collation                | Charset  | Id  | Default | Compiled | Sortlen |
    +--------------------------+----------+-----+---------+----------+---------+
    | big5_chinese_ci          | big5     |   1 | Yes     | Yes      |       1 |
    | big5_bin                 | big5     |  84 |         | Yes      |       1 |
    | dec8_swedish_ci          | dec8     |   3 | Yes     | Yes      |       1 |
    ……
    | eucjpms_bin              | eucjpms  |  98 |         | Yes      |       1 |
    +--------------------------+----------+-----+---------+----------+---------+
    197 rows in set (0.01 sec)

要列出 **utf8** character set 支持的 collation ，执行`SHOW COLLATION LIKE 'utf8_%'`。

    mysql> SHOW COLLATION LIKE 'utf8_%';
    +--------------------------+---------+-----+---------+----------+---------+
    | Collation                | Charset | Id  | Default | Compiled | Sortlen |
    +--------------------------+---------+-----+---------+----------+---------+
    | utf8_general_ci          | utf8    |  33 | Yes     | Yes      |       1 |
    | utf8_bin                 | utf8    |  83 |         | Yes      |       1 |
    | utf8_unicode_ci          | utf8    | 192 |         | Yes      |       8 |
    ……
    | utf8mb4_sinhala_ci       | utf8mb4 | 243 |         | Yes      |       8 |
    +--------------------------+---------+-----+---------+----------+---------+
    45 rows in set (0.01 sec)

MySQL 的 Collation 有以下特点：

* 每一种 collation 只对应一种 character set，也就是说不同的 character set 不可能拥有相同的 collation
* 每一种 character set 都有一个默认的 collation。在`SHOW COLLATION`命令的结果中，第四列的“Default”就是相应的 character set所对应的 collation，
* collation 的命名有一些规律：通常以相关联的 character set 的名字为前缀，然后中间一般是语种的名称，最后以 **\_ci** (case insensitive 大小写不敏感)， **\_cs** (case sensitive 大小写敏感)， 或者 **\_bin** (binary)结尾

[Collation-Charts.ORG](http://collation-charts.org)提供了各种 collation 的更详细的说明。

## 2 MySQL中 character set 和 collation 的 level

MySQL中可以在 server，database，table，column 四个级别对 character set 和 collation 进行设定。甚至我们还可以单独对字符串(string literal)设定其 character set 和 collation 。

### 2.1 Server Character Set & Collation

使用 `SHOW VARIABLES LIKE 'character_set_server'` 和 `SHOW VARIABLES LIKE 'collation_server'` 命令来查看当前系统 server 级别的 character set 和 collation 设定：

    mysql> SHOW VARIABLES LIKE 'character_set_server';
    +----------------------+-------+
    | Variable_name        | Value |
    +----------------------+-------+
    | character_set_server | utf8  |
    +----------------------+-------+
    1 row in set (0.00 sec)
    mysql> SHOW VARIABLES LIKE 'collation_server';
    +------------------+-----------------+
    | Variable_name    | Value           |
    +------------------+-----------------+
    | collation_server | utf8_general_ci |
    +------------------+-----------------+
    1 row in set (0.00 sec)

如果要进行修改，可以在启动的时候在启动参数或者配置文件中对 server 的 character set 和 collation 进行设定。其中启动参数可以使用 `--character-set-server` 和 `--collation-server` 来设定:

    shell> mysqld --character-set-server=utf8 --collation-server=utf8_general_ci

也可以在配置文件中`[mysqld]`的段落使用 `character_set_server=charset` 和 `collation_server=collation`来设定:
    
    # my.ini(windows) or my.cnf(*nix)
    # -------------------------------------------------
    [mysqld]
    character_set_server=utf8
    collation_server=utf8_general_ci

二者的效果是相同的。

server 的 character set 和 collation 的设定规则如下：

1. 如果在启动参数或者配置文件中同时指定了正确的 `--character-set-server` 和 `--collation-server` 那么系统将使用指定的 character set 和 collation
2. 只是指定了 `--character-set-server` 那么 将使用指定的 character set 默认的 collation
3. 如果没有指定 `--character-set-server` 那么 character set 和 collation 将使用默认的 character set(latin1)和 collation(latin1\_swedish\_ci)

_注意_：如果你想修改系统默认的 character set(latin1)和 collation(latin1_swedish_ci)，那么你必须在编译的时候指定

    shell> cmake . -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_general_ci

cmake 编译的时候和 mysqld 启动的时候都会对指定的 character set 和 collation 进行合法性检查，如果不符合要求，那么程序将报错返回停止执行。

server 级别的 character set 和 collation 作用只是当使用 `CREATE DATABASE` 语句创建数据库没有指定 character set 和 collation 时提供一个默认值，除此之外，没有其他作用。

### 2.2 Database Character Set and Collation

每一个 database 都可以单独设定 character set 和 collation 。`CREATE DATABASE` 和 `ALTER DATABASE` 语句里面提供选项进行 database 的 character set 和 collation 的设定：

    CREATE DATABASE db_name
        [[DEFAULT] CHARACTER SET charset_name]
        [[DEFAULT] COLLATE collation_name]

    ALTER DATABASE db_name
        [[DEFAULT] CHARACTER SET charset_name]
        [[DEFAULT] COLLATE collation_name]

这样可以单独设定每个 database 的 character set 和 collation ，在每个 database 目录下的 **db.opt** 文件中可以查看该 database 的 character set 和 collation 。这样就使得在同一个 server 下能存在不同 character set 和 collation 的 database。

database 的 character set 和 collation 的设定规则如下：

1. 如果 `CREATE DATABASE` 或 `ALTER DATABASE` 同时设定了 `CHARACTER SET X` 和 `COLLATE Y`，那么 character set 就是 **X**， collation 就是 **Y**
2. 如果只是设定了 `CHARACTER SET X`，那么 character set 使用 **X**，同时使用 **X** 的对应默认 collation
3. 如果只是设定了 `COLLATE Y`，collation 为 **Y**， 同时使用 **Y** 对应的 character set
4. 除以上情况，使用 server 的 character set 和 collation

Database 级别的 character set 和 collation 作用是当使用 `CREATE TABLE` 没有指定 character set 时，作为 table 的默认值，除此之外， `LOAD DATA INFILE` 也使用 database 级别的 character set 和 collation。

你可以通过 `SHOW VARIABLES LIKE 'character_set_database'` 和 `SHOW VARIABLES LIKE 'collation_database'` 命令来查看当前系统默认 database 级别的 character set 和 collation 设定，如果没有默认 database，那么这两个变量和 server 级别的 `character_set_server`、`collation_server`保持一致：

    mysql> SHOW VARIABLES LIKE 'character_set_database';
    +------------------------+-------+
    | Variable_name          | Value |
    +------------------------+-------+
    | character_set_database | utf8  |
    +------------------------+-------+
    1 row in set
    mysql> SHOW VARIABLES LIKE 'collation_database';
    +--------------------+-----------------+
    | Variable_name      | Value           |
    +--------------------+-----------------+
    | collation_database | utf8_general_ci |
    +--------------------+-----------------+
    1 row in set

### 2.3 Table Character Set & Collation

每张表也可以设定自己的 character set 和 collation ，你可以使用 `CREATE TABLE ` 或者 `ALTER TABLE` 语句来设定：

    CREATE TABLE tbl_name (column_list)
        [[DEFAULT] CHARACTER SET charset_name]
        [COLLATE collation_name]]

    ALTER TABLE tbl_name
        [[DEFAULT] CHARACTER SET charset_name]
        [COLLATE collation_name]

Table 的 character set 和 collation 的设定规则如下：

1. 如果同时指定了 `CHARACTER SET X` 和 `COLLATE Y`，那么 character set 就是 **X** collation 就是 **Y**
2. 如果只指定了 `CHARACTER SET X` 而没有指定 `COLLATE` ，那么使用 **X** 和 **X** 对应默认的 collation
3. 如果只指定了 `COLLATE Y` 而没有指定 `CHARACTER SET` ，那么使用 **Y** 和 **Y** 对应关联的 character set
4. 除以上情况以外，使用 database 级别的 character set 和 collation 

table 级别的 character set 和 collation 作用是当 column 的character set 和 collation 没有设定的时候提供默认值。table 级别的 character set 和 collation 是 MySQL 对标准 SQL 的扩展。

### 2.4 Column Character Set and Collation

每一个 character 类型的 column(CHAR、VARCHAR、TEXT类型等) 都可以设定 character set 和 collation ，你可以在 `CREATE TABLE` 或 `ALTER TABLE` 语句中 column 属性中进行设定：

    col_name {CHAR | VARCHAR | TEXT} (col_length)
        [CHARACTER SET charset_name]
        [COLLATE collation_name]

同样的，ENUM 或者 SET 类型的 column 也能进行单独的设定：

    col_name {ENUM | SET} (val_list)
        [CHARACTER SET charset_name]
        [COLLATE collation_name]

Column 的 character set 和 collation 的设定规则如下：

1. 如果同时指定了 `CHARACTER SET X` 和 `COLLATE Y`，那么 character set 就是 **X** collation 就是 **Y**    

        CREATE TABLE t1
        (
            col1 CHAR(10) CHARACTER SET utf8 COLLATE utf8_unicode_ci
        ) CHARACTER SET latin1 COLLATE latin1_bin;

    如上面的例子：character set 和 collation 都明确指定了， 所以 `col1` 的character set 是 **utf8**，collation 是 **utf8\_unicode\_ci**

2. 如果只指定了 `CHARACTER SET X` 而没有指定 `COLLATE` ，那么使用 **X** 和 **X** 对应默认的 collation

        CREATE TABLE t1
        (
            col1 CHAR(10) CHARACTER SET utf8
        ) CHARACTER SET latin1 COLLATE latin1_bin;

    如上面的例子：只指定了 `col1` 的 character set 是 **utf8**，但是没有指定 `COLLATE`，则 collation 使用**utf8**对应的默认的 collation 为 **utf8_general_ci**，

3. 如果只指定了 `COLLATE Y` 而没有指定 `CHARACTER SET` ，那么使用 **Y** 和 **Y** 对应关联的 character set

        CREATE TABLE t1
        (
            col1 CHAR(10) COLLATE utf8_polish_ci
        ) CHARACTER SET latin1 COLLATE latin1_bin;

    如上面的例子：`col1` 只指定了 collation 为 **utf8\_polish\_ci**，没有指定 character set，则 character set 使用 **utf8\_polish\_ci** 对应关联的 character set 为 **utf8**。

4. 除以上情况，使用 table 的 character set 和 collation

        CREATE TABLE t1
        (
            col1 CHAR(10)
        ) CHARACTER SET latin1 COLLATE latin1_bin;

    如上面的例子：`col1` 的 character set 为 **latin1**，collation 为 **latin1\_bin**

**注意** 如果试图使用 `ALTER TABLE` 修改 column 的 character set，如果修改前后两种 character set 不兼容，那么可能会出现数据丢失的情况。

### 2.5 Character String Literal Character Set and Collation

除以上以外，我们还可以对字符串（String Literal）设置 character set 和 collation。

字符串可以使用 **introducer** 来指定 character set 同时使用 `COLLATE` 来指定 collation。

    [_charset_name]'string' [COLLATE collation_name]

例如：

    SELECT 'string';
    SELECT _latin1'string';
    SELECT _latin1'string' COLLATE latin1_danish_ci;

例子中的第一条，`SELECT 'string'` 中的字符串使用 `character_set_connection` 和 `collation_connection` 定义的 character set 和 collation 。

类似于 `_charset_name` 表达方式我们叫做 **introducer**，它告诉解析器接下来的字符串使用 character set X 来处理，这种表示方法并不像 `CONVERT()` 函数那样改变 **introducer** 内的字符串的 character set ，他没有改变字符串的值，同时，**introducer** 在十六进制形式和数字形式前面都是合法的，或者在位字节之前。

    SELECT _latin1 x'AABBCC';
    SELECT _latin1 0xAABBCC;
    SELECT _latin1 b'1100011';
    SELECT _latin1 0b1100011;

这种情况下，如果只指定了 character set ，则使用相对应的 collation，如果 character set 没指定，则使用 `character_set_connection` 和 `collation_connection`。

to be continued.

## See also

*  Character Set Support [http://dev.mysql.com/doc/refman/5.5/en/charset.html](http://dev.mysql.com/doc/refman/5.5/en/charset.html "Character Set Support")
*  Collation-Charts.ORG [http://collation-charts.org/](http://collation-charts.org/ "Collation-Charts.ORG")

## References

1. Character Sets and Collations in General [http://dev.mysql.com/doc/refman/5.5/en/charset-general.html][1]    
2. mysql字符集与校验规则的设置, taobaodba, [http://www.taobaodba.com/html/181\_mysql\_charset\_collation\_set.html](http://www.taobaodba.com/html/181_mysql_charset_collation_set.html "mysql字符集与校验规则的设置")
3. 深入Mysql字符集设置, Laruence, [http://www.laruence.com/2008/01/05/12.html](http://www.laruence.com/2008/01/05/12.html)  
4. MySQL Data Methods, [http://www.webreference.com/programming/mysql_data/4.html](http://www.webreference.com/programming/mysql_data/4.html)
5. String Literals, [http://dev.mysql.com/doc/refman/5.5/en/string-literals.html](http://dev.mysql.com/doc/refman/5.5/en/string-literals.html)
6. Expression Evaluation and Type Conversion, [http://82.157.70.109/mirrorbooks/mysqlguide4.1-5.0/0672326736/ch03lev1sec6.html](http://82.157.70.109/mirrorbooks/mysqlguide4.1-5.0/0672326736/ch03lev1sec6.html)

[1]: http://dev.mysql.com/doc/refman/5.5/en/charset-general.html "Character Sets and Collations in General" 





