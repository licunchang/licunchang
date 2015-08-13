**File Name** php-mysql-multipage.md  

**Description** PHP 分页    
**Author** LiCunchang(printf@live.com)  
**Version** 2.0.20130408  

------

构造测试环境，插入10w条数据

    <?php

    if(!function_exists('random')){
        function random($length, $numeric = 0) {
            PHP_VERSION < '4.2.0' ? mt_srand((double)microtime() * 1000000) : mt_srand();
            $seed = base_convert(md5(print_r($_SERVER, 1).microtime()), 16, $numeric ? 10 : 35);
            $seed = $numeric ? (str_replace('0', '', $seed).'012340567890') : ($seed.'zZ'.strtoupper($seed));
            $hash = '';
            $max = strlen($seed) - 1;
            for($i = 0; $i < $length; $i++) {
                $hash .= $seed[mt_rand(0, $max)];
            }
            return $hash;
        }
    }

    /*
    DROP DATABASE IF EXISTS `multipage`;
    CREATE DATABASE IF NOT EXISTS `multipage` DEFAULT CHARACTER SET 'utf8' DEFAULT COLLATE 'utf8_general_ci';
    USE `multipage`;

    CREATE TABLE `users`
    (
        `uid`       MEDIUMINT UNSIGNED AUTO_INCREMENT COMMENT '用户ud',
        `username`  CHAR(20) NOT NULL DEFAULT '' COMMENT '用户名',
        `password`  CHAR(32) NOT NULL DEFAULT '' COMMENT '用户密码',
        `salt`      CHAR(4) NOT NULL DEFAULT '' COMMENT '密码salt',
                    PRIMARY KEY(`uid`)
    )
    ENGINE=InnoDB COMMENT='用户表' DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci;
     */

    $host     = 'localhost';
    $dbname   = 'multipage';
    $charset  = 'utf8';
    $username = 'root';
    $password = 'root';
    $port     = '3306';

    set_time_limit(0);

    $dsn = "mysql:host={$host};dbname={$dbname};port={$port};charset={$charset}";
    $options = array(
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    );
    try {
        $dbh = new PDO($dsn, $username, $password, $options);
    } catch (PDOException $e) {
        echo 'Connection failed: ' . $e->getMessage();
    }

    for ($i=0; $i <= 100000; $i++) {

        $sth = $dbh->prepare('
            INSERT INTO `users` (`username`, `password`, `salt`)
            VALUES (:username, :password, :salt)
        ');

        $data_salt = random(4);
        $data_username = random(rand(6, 20));
        $data_password = md5($data_username.$data_salt);

        $sth->bindValue(':username', $data_username);
        $sth->bindValue(':password', $data_password);
        $sth->bindValue(':salt', $data_salt);
        
        $sth->execute();
    }

