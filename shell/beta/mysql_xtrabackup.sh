#!/bin/bash
#description    backup mysql via xtrabackup, run at 00:00 everyday
#crontab        00 00 * * * /bin/bash /data/cron/nginx_logs_cut.sh
#author         LiCunchang(printf@live.com)

MYSQL_CLIENT=/usr/local/mysql/bin/mysql

XTRABACKUP_PATH=/usr/local/xtrabackup/

MYSQL_BACKUP=/data/backup/mysql/

if [ ! -d $MYSQL_BACKUP ]; then
    mkdir -p $MYSQL_BACKUP
fi


if [ "xtrabackup" != `$MYSQL_CLIENT -uroot -proot -P3306 -Bse "SELECT user FROM mysql.user WHERE user='xtrabackup'"` ]; then
    $MYSQL_CLIENT -uroot -proot -P3306 <<'EOF'
CREATE USER 'xtrabackup'@'localhost' IDENTIFIED BY 'xtrabackup';
GRANT RELOAD, LOCK TABLES, REPLICATION CLIENT ON *.* TO 'xtrabackup'@'localhost';
FLUSH PRIVILEGES;
EOF
fi

# Make a Local Full Backup (Create, Prepare and Restore)


# Making an Incremental Backup













chmod 444 $MYSQL_BACKUP  -R




















### PART 1: Move web logs to the backup directory which named by year & month.






LOGS_PATH=/usr/local/nginx/logs/
APP_NAME=(www.licunchang.com mysql.licunchang.com)
LOGS_BACKUP=/data/logs/nginx/$(date -d "yesterday" +"%Y%m")/










