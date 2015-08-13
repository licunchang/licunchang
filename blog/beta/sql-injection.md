**File Name** sql-injection.md    

**Description** SQL 注入浅谈  
**Author** LiCunchang(printf@live.com)  
**Version** 1.0.20130805  

------

从一个用户登录说起，一般来说用户登录需要填写 username 和 password ，然后提交到后端服务器查询，后端的处理逻辑类似于这样：

    $username = $_GET['username'];
    $sql = "SELECT `password` FROM `users` WHERE `username` = '$username'";

相关的测试脚本语句如下

    DROP DATABASE IF EXISTS `injection`;
    CREATE DATABASE IF NOT EXISTS `injection` DEFAULT CHARACTER SET 'utf8' DEFAULT COLLATE 'utf8_general_ci';
    USE `injection`;

    CREATE TABLE `users`
    (
        `uid`       MEDIUMINT UNSIGNED AUTO_INCREMENT COMMENT '用户ud',
        `username`  CHAR(20) NOT NULL DEFAULT '' COMMENT '用户名',
        `password`  CHAR(32) NOT NULL DEFAULT '' COMMENT '用户密码',
                    PRIMARY KEY(`uid`)
    )
    ENGINE=InnoDB COMMENT='用户表' DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci;

    INSERT INTO `users`(`username`, `password`) VALUES('admin', 'c2e30c1ac2e829bd64593a612dcac5df');
    INSERT INTO `users`(`username`, `password`) VALUES('test', 'ba921999a56eed0b86790c5e0fd3bb3a');
    INSERT INTO `users`(`username`, `password`) VALUES('injection', '1d4cac4d3a8e25db4f5fc533161c8aee');

好吧，问题来了，好事者在前端用户名的地方输入了这么一段字符串 `admin' OR 1=1 -- `，上面的 SQL 语句就变成了下面的样子

    SELECT `password` FROM `users` WHERE `username` = 'admin' OR 1=1 -- '

你看，这条语句并没有如我们预想的那样返回 admin 对应的 password，而是将所有库中的用户的 password 返回，这明显不是我们想要的。

发生这种

## 查看是否存在注入漏洞



## addslashes 

最经典的，我们在

## mysql\_real\_escape\_string

速度慢 关键是依赖于现有的 mysql 连接，速度可能是addslashes的二到三倍，而且在 php 5.5 中已经废弃，所以不推荐使用。同时还有函数 mysql_escape_string。



## magic\_quotes\_gpc 

5.4.0 始终返回 FALSE，因为这个魔术引号功能已经从 PHP 中移除了。同样不推荐使用。



## Prepared Statements

php 中使用预处理并不是像mysql的预处理那样  而是在客户端进行了SQL 的拼装，然后直接发送给服务器端进行执行，这样应该避免了http 的开销和会话的时间，同时见识使用bindValue 而不是 bindPrame 因为后者只能使用引用，而前者技能使用变量又能直接引用值类型



## 其他

### LIMIT

LIMIT 1;

这个并不能组织 SQL 注入，而是减少SQL 注入之后的影响范围。不过这个也是很容易被跳过的一个方法。因为这个参数通常在 SQL 语句的最后，所以如果有SQL注入的话 很容易通过注释避过。

















http://stackoverflow.com/questions/60174/how-to-prevent-sql-injection-in-php

http://shiflett.org/blog/2006/jan/addslashes-versus-mysql-real-escape-string

