**File Name** rsync.md  
**Description**  rsync    
**Author** LiCunchang (printf@live.com)  
**Version** 1.0.20131124  

------

    rpm -qa | grep rsync 
    rpm -e rsync-2.6.8-3.1 

    cd /usr/local/src/
    tar zxf rsync-3.1.0.tar.gz
    cd /usr/local/src/rsync-3.1.0
    ./configure --prefix=/usr/local/rsync --disable-ipv6
    make
    make install

    mkdir /etc/rsync/

    vi /etc/rsync/rsyncd.conf
    


    pid file = /var/run/rsyncd.pid 
    port = 873 
    address = 10.10.10.236
    uid = www
    gid = www
    use chroot = no
    read only = yes
    log file = /data/logs/rsyncd/rsyncd.log
    hosts allow = 10.10.10.0/24

    [www.utrans.com]
        path = /data/web/www.utrans.com/
        auth users = www
        secrets file = /etc/rsync/rsyncd.secrets

    vi /etc/rsync/rsyncd.secrets

    www:www

    chmod 600 /etc/rsync/rsyncd.secrets

    /usr/local/rsync/bin/rsync --daemon --config=/etc/rsync/rsyncd.conf --ipv4



    vi /etc/rsync/rsyncd.secrets

    www

    chmod 600 /etc/rsync/rsyncd.secrets

    /usr/local/rsync/bin/rsync -vzrtopg --exclude='.svn/' --progress --password-file=/etc/rsync/rsyncd.secrets www@10.10.10.236::www.utrans.com /data/web/www.utrans.com/

    /usr/local/rsync/bin/rsync -vzrtopg --exclude-from=/etc/rsync/exclude.list --progress --password-file=/etc/rsync/rsyncd.secrets www@10.10.10.236::www.utrans.com /data/web/www.utrans.com/

    vi /etc/rsync/exclude.list
    
    .svn
    data/*
    .project
    .travis.yml
    application/logs/*


    /usr/local/rsync/bin/rsync -vzrtopg --progress --delete --password-file=/etc/rsync/rsyncd.secrets www@10.10.10.236::www.utrans.com /data/web/www.utrans.com/ > /data/logs/rsyncd/$(date +"%Y%m%d%H%M%S").log
