**File Name** mysqlnd_ms.md  

**Description**  mysqlnd_ms 介绍     
**Author** licunchang  
**Version** 1.0.20131204  

------

## mysqlnd_ms 简介

安装

    cd /usr/local/src/
    tar zxf mysqlnd_ms-1.5.2.tgz
    cd mysqlnd_ms-1.5.2
    /usr/local/php/bin/phpize
    ./configure --with-php-config=/usr/local/php/bin/php-config
    make
    make install

启用插件 (php.ini)

    [mysqlnd_ms]
    extension=mysqlnd_ms.so
    mysqlnd_ms.enable=1
    mysqlnd_ms.force_config_usage = 1
    mysqlnd_ms.config_file=/usr/local/php/etc/mysqlnd_ms_plugin.ini

添加 mysqlnd_ms 的配置文件 mysqlnd_ms_plugin.ini (基于 JSON 格式的)

    {
        "utrans": {
            "master": {
                "master_0": {
                    "host": "localhost",
                    "socket": "\/tmp\/mysql.sock",
                    "port": "3306"
                }
            },
            "slave": {
                "slave_0": {
                    "host": "localhost",
                    "socket": "\/tmp\/mysql-slave.sock",
                    "port": "3307"
                }
            }
        }
    }

修改项目数据库配置信息(项目用的是 codeigniter)

    $db['default']['hostname'] = 'utrans';

mysqlnd_ms 的配置文件中，你可以添加多个 section ，相当于数据源，上面的例子中只有一个 section 叫做 `utrans`，每个 section 必须有且只有一个主服务器和一系列从服务器，多主的拓扑结构目前不支持。如果在 section 中至少配置两个服务器那么该插件就开始切换连接进行负载均衡了。切换数据库连接并不总是对用户透明的，在某些场景下会产生一系列的问题。同时需要注意，主从库连接的用户名和密码必须一致(我们用的这个插件版本比较高，可以不一致，不过不折腾为妙)。

PHP MySQL 中的 connection 是一对一的服务器客户端的连接， mysqld_ms 改变了这个定义，使用 mysqlnd_ms 意味着一个 "connection" 至少包含一个 master 服务器的连接和一定数量的 slave 服务器的连接，这是一种连接池的概念。

    <?php
        $mysqli = new mysqli("myapp", "username", "password", "database");
        if (!$mysqli)
            /* 简单的错误处理 */
            die(sprintf("[%d] %s\n", mysqli_connect_errno(), mysqli_connect_error()));

        /* 连接 1, 因为不是 SELECT 语句，所以在 master 服务器上执行 */
        if (!$mysqli->query("SET @myrole='master'")) {
            printf("[%d] %s\n", $mysqli->errno, $mysqli->error);
        }

        /* 连接 2, SELECT 语句在 SLAVE 服务器上执行 */
        if (!($res = $mysqli->query("SELECT @myrole AS _role"))) {
            printf("[%d] %s\n", $mysqli->errno, $mysqli->error);
        } 
        else {
            $row = $res->fetch_assoc();
            $res->close();
            /* 打印输出结果 */
            printf("@myrole = '%s'\n", $row['_role']);
        }
        $mysqli->close();
    ?>

上面的程序输出下面的结果

    @myrole = ''

在上面的程序的两个语句之间进行了主从的负载切换，第一个语句因为不是 `SELECT` 语句，所以选择在 master 服务器上执行，这条语句设置了一个用户变量。第二条语句是 `SELECT @myrole AS _role` 这是一个 “read-only” 的语句，执行在 slave 服务器上，因为用户自定义变量是会话有效的，切换连接之后自然也就无法取到用户自定义变量。

程序开发者有责任仔细考虑 SQL 语句的上下文环境，确保程序正确的运行，同时，这些陷阱能很容易的通过添加 SQL hints 来避免。

通过 添加 SQL hints 能告诉 mysqlnd_ms 如何来选择从连接池中选择一个正确的连接，这能帮助解决因为连接切换而带来的问题。因为 SQL hints 包裹在注释中，SQL server 、 MySQL Proxy和其他防火墙等都能进行忽略，所以不对执行结果产生影响，mysqlnd_ms 有三个 SQL hints ：

* `MYSQLND_MS_MASTER_SWITCH` 使用主服务器连接
* `MYSQLND_MS_SLAVE_SWITCH` 使用备服务器连接
* `MYSQLND_MS_LAST_USED_SWITCH` 使用上一条查询采用的连接

同时，这三条 SQL hints 只有出现在 SQL 语句的开始的时候才有效，因为 mysqlnd_ms 只会检测 SQL 语句的开始部分看是否有 hints。上面的演示程序修改为下面的样子可以避免连接切换带来的问题：

    <?php
        $mysqli = new mysqli("myapp", "username", "password", "database");
        if (mysqli_connect_errno())
        /* 简单的错误处理 */
        die(sprintf("[%d] %s\n", mysqli_connect_errno(), mysqli_connect_error()));

        /* 连接1 运行在Master服务器上 */
        if (!$mysqli->query("SET @myrole='master'")) {
            printf("[%d] %s\n", $mysqli->errno, $mysqli->error);
        }

        /* 因为有 SQL hints 的存在 同样运行在master服务器上 */
        if (!($res = $mysqli->query(sprintf("/*%s*/SELECT @myrole AS _role", MYSQLND_MS_LAST_USED_SWITCH)))) {
            printf("[%d] %s\n", $mysqli->errno, $mysqli->error);
        } 
        else {
            $row = $res->fetch_assoc();
            $res->close();
            printf("@myrole = '%s'\n", $row['_role']);
        }
        $mysqli->close();
    ?>

上面的程序就能输出正确的结果了：

    @myrole = 'master'

在上面的程序中，使用 `MYSQLND_MS_LAST_USED_SWITCH` 阻止了会话从主服务器连接切换到从服务器连接。

当从服务器的数据可能延迟于主服务器，而需要对数据保持很高的准确性的时候，在 `SELECT` 语句中使用 SQL hints 能使得能使用主服务器的连接。

当前版本 mysqlnd_ms 是事务不安全的，目前也没有任何类型的 MySQL 负载均衡器能够界定事务。在这种情况下你就必须在事务中使用 SQL hints 来保证插件不会在事务中进行连接的切换。

**注意** 文档中说从 php5.4 开始，mysqlnd_ms 可以监控 api 状态的变化从而界定事务的边界，试了一下，好像还是不太好用，有时间再调整吧，万无一失的方法就是使用 SQL hints 强制使用某个连接。 http://www.php.net/manual/zh/mysqlnd-ms.quickstart.transactions.php

## 程序中使用方法

如果程序中使用的是直接拼写 SQL 的方式，则使用下面的方式

    $sql = "SELECT `id`, `length` FROM `audio` WHERE `batch_id`='$batch_id' AND `valid`='0' AND $state LIMIT $start, $limit";

    // 添加 SQL Hint
    $sql = sprintf("/*%s*/$sql", MYSQLND_MS_MASTER_SWITCH);

    log_message('INFO', '['.__METHOD__ . ']'."\t".'[LINE:' . __LINE__ . ']'."\t[".is_select($sql)."]\t".$sql);
    $query = $this->db->query($sql);

如果程序中使用的是 Codeigniter 的 Active Record 类方法，则使用下面的方法

    $this->db->select('user_language_map.*,language.name as l_name');
    $this->db->from('user_language_map');
    $this->db->join('language','language.id=user_language_map.language_id','LEFT');
    $this->db->where('user_id',$row->user_id);
    
    // 添加 SQL Hint
    $this->db->sql_hint(MYSQLND_MS_MASTER_SWITCH);

    $lquery = $this->db->get();

