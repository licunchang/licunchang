#!/bin/bash

MYSQL_SERVER='127.0.0.1'
MYSQL_USER='root'
MYSQL_PASSWORD='root'
MYSQL_PORT='3306'

MYSQL='/usr/local/mysql/bin/mysql'

query() {
    $MYSQL $1 -uroot -proot -P3306 -Bse $2
}

close() {

}

/usr/local/mysql/bin/mysql mysql -uroot -proot -P3306 -Bse 'SELECT `host`, `user`, `password` FROM `user`'


/usr/local/mysql/bin/mysql mysql -uroot -proot -P3306 <<'EOF'
SELECT `host`, `user`, `password` FROM `user`;
EOF

rows=`/usr/local/mysql/bin/mysql mysql -uroot -proot -P3306 -Bse 'SELECT \`host\`, \`user\`, \`password\` FROM \`user\`'`

for row in $rows
do
    echo $row
done



-e, --execute=name  Execute command and quit. (Disables --force and history
                      file.)
MBQL::Connect() {
# MBQL::Connect server user pass database
    MYSQL=$1
    USER=$2
    MYSQLPASSWD=$3
    DATABASE=$4
    mkfifo /tmp/mybashql.$$.mysql.in /tmp/mybashql.$$.mysql.out
    mysql -n -N --disable-auto-rehash   \
            -h$MYSQL                    \
            -u$USER                     \
            -p$MYSQLPASSWD              \
            information_schema          \
            </tmp/mybashql.$$.mysql.in  \
            >/tmp/mybashql.$$.mysql.out \
            &
    exec 3> /tmp/mybashql.$$.mysql.in
    exec 4< /tmp/mybashql.$$.mysql.out
    echo "select count(data_type)
        from COLUMNS
        where
            table_schema = 'information_schema'
            and table_name = 'tables'
            and column_name = 'table_name';
        USE $DATABASE;" >&3
    read -u 4 results
    (( results == 1 )) || MBQL::Die "Mysql connection failed!"
}
# to get bash HL add let is_bash=1 to your .vimrc
# vim:tabstop=4:textwidth=79:syntax=sh:filetype=sh: