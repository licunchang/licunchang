[root@localhost ~]# df -T -h
Filesystem    Type    Size  Used Avail Use% Mounted on
/dev/mapper/VolGroup-lv_root
              ext4     45G  731M   42G   2% /
tmpfs        tmpfs    935M     0  935M   0% /dev/shm
/dev/sda1     ext4    485M   32M  428M   7% /boot
[root@localhost ~]# tune2fs -l /dev/mapper/VolGroup-lv_root | grep 'Block size'
Block size:               4096
