#!/bin/bash
# description    MySQL Configure files
# author         LiCunchang(printf@live.com)

# Save config file temporarily
readonly TEMP_FILENAME=/tmp/mysql-$(date -d "now" +"%Y%m%d%H%M%S").cnf

# CPU cores number
cpu_core_number=$(more /proc/cpuinfo | grep "model name" | wc -l)
# Free memory
memory_free=$(free -m | grep Mem | awk '{print $4}')
# Number of bits
number_of_bits=$(getconf LONG_BIT)

cat > $TEMP_FILENAME <<'EOF'
# MySQL config file
#
# created via script(https://github.com/licunchang/licunchang)

# The following options will be passed to all MySQL clients
[client]
EOF

if [ ! -f $TEMP_FILENAME ]; then
    echo "error: no write access to $TEMP_FILENAME"
    exit 1
fi

echo "" >> $TEMP_FILENAME
echo "# The MySQL server" >> $TEMP_FILENAME
echo "[mysqld]" >> $TEMP_FILENAME

## key_buffer_size

## innodb_buffer_pool_size

## 































