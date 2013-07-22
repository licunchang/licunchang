**File Name** mysql-user-defined-variables-example-1.md

**Description** MySQL 用户自定义变量示例一则  
**Author** LiCunchang(printf@live.com)  
**Version** 1.0.20130722  

------

下面是示例库
    
    CREATE TABLE `users`
    (
        `uid`       MEDIUMINT UNSIGNED AUTO_INCREMENT COMMENT '用户ud',
        `username`  CHAR(20) NOT NULL DEFAULT '' COMMENT '用户名',
        `point`     INT UNSIGNED NOT NULL DEFAULT '0' COMMENT '用户积分',
                    PRIMARY KEY(`uid`)
    )
    ENGINE=InnoDB COMMENT='用户表' DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci;

    INSERT INTO `users`(`uid`, `username`, `point`) VALUES ('1', 'admin', '1000');

    CREATE TABLE `records`
    (
        `rid`       MEDIUMINT UNSIGNED AUTO_INCREMENT COMMENT '记录id',
        `type`      TINYINT UNSIGNED NOT NULL DEFAULT '0' COMMENT '类型(1:收入;2:消费)',
        `amount`    INT UNSIGNED NOT NULL DEFAULT '0' COMMENT '消费积分',
        `balance`   INT UNSIGNED NOT NULL DEFAULT '0' COMMENT '账户余额',
                    PRIMARY KEY(`rid`)
    )
    ENGINE=InnoDB COMMENT='积分记录表' DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci;

上面的是一个很常见的用户信息表和积分记录表，用户有积分属性，积分有 **收入** 和 **消费** 两种状态，而 `records` 表记录了用户积分的变动历史。

一般情况下，用户收入 1000 个积分，则 SQL 事务如下：

    START TRANSACTION;
    UPDATE `users` SET `point`=`point`+1000 WHERE `uid`=1;
    SELECT `point` FROM `users` WHERE `uid`=1;
    INSERT INTO `records`(`type`, `amount`, `balance`) VALUES ('1', '1000', ${point});
    COMMIT; OR ROLLBACK;

首先，更新用户信息表，将用户信息表中的积分字段加 1000，更新成功后，查询当前用户的积分数，然后第三步插入这条变更记录到 `records` 表，这样中间的第二步查询用户积分数这个必不可少，负责无法得到在第三步中的 `balance` 列的数据。这时候我们可以使用用户自定义变量来完成这个步骤。

    START TRANSACTION;
    UPDATE `users` SET `point`=@balance WHERE `uid`=1 AND @balance:=`point`+1000;
    INSERT INTO `records`(`type`, `amount`, `balance`) VALUES ('1', '1000', @balance);
    COMMIT; OR ROLLBACK;

这样的好处就是减少了一次数据库查询(上面的第二步：查询用户当前积分数)，于是我们复制同样的过程于用户消费积分的过程中，不过这时候我们发现了一些异样：

    START TRANSACTION;
    UPDATE `users` SET `point`=@balance WHERE `uid`=1 AND @balance:=`point`-3000;
    INSERT INTO `records`(`type`, `amount`, `balance`) VALUES ('0', '3000', @balance);
    COMMIT; OR ROLLBACK;

经过上面的两次增加积分操作，用户 uid=1 此时有 3000 的积分额度，我们对此用户执行消费 3000 积分的操作，但是此时第一步执行结果却是 `0 row(s) affected`，同时 `users` 表的 `point` 字段数值没有发生变化，仔细查看后发现问题出在 `AND @balance:=point-3000` 上，账户原本有 3000 积分，则 `@balance` 变量则为 `3000 - 3000 = 0` 积分，那么这个表达式的值便是 `0`，原来的 SQL 便变成了 `UPDATE users SET point=0 WHERE uid=1 AND 0`，这也难怪会出现 `0 row(s) affected` 了。

怎么解决呢？自然是设法让 `AND @balance:=point-3000` 的表达式值不影响整个语句的执行，我们可以让用户自定义变量的表达式部分为永真即可，下面给出解决方案：

    START TRANSACTION;
    UPDATE `users` SET `point`=@balance WHERE `uid`=1 AND (@balance:=`point`-3000)+1;
    INSERT INTO `records`(`type`, `amount`, `balance`) VALUES ('0', '3000', @balance);
    COMMIT; OR ROLLBACK;

DONE。