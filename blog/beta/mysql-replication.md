## Setting the Replication Master Configuration

    # ${MASTER_DIR}/my.cnf
    [mysqld]
    log-bin=mysql-bin
    server-id=1

## Setting the Replication Slave Configuration
    
    # ${SLAVE_DIR}/my.cnf
    [mysqld]
    server-id=2
    relay_log=/data/mysql-slave/mysql-relay-bin
    log_slave_updates=1
    read_only=1

## Creating a User for Replication on Master

    mysql> CREATE USER 'replication'@'10.10.10.%' IDENTIFIED BY 'replication';
    mysql> GRANT REPLICATION SLAVE ON *.* TO 'replication'@'10.10.10.%';

## Obtaining the Replication Master Binary Log Coordinates

    mysql> FLUSH TABLES WITH READ LOCK;
    mysql> SHOW MASTER STATUS;


    mysql> CHANGE MASTER TO MASTER_HOST='10.10.10.236', MASTER_PORT=3306, MASTER_USER='replication', MASTER_PASSWORD='replication', MASTER_LOG_FILE='mysql-bin.000001', MASTER_LOG_POS=120;
    mysql> SHOW SLAVE STATUS;
    mysql> START SLAVE;
