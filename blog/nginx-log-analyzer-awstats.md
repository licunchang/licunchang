**File Name** nginx-log-analyzer-awstats.md

**Description** nginx 日志分析工具 awstats 
**Author** LiCunchang(printf@live.com)  
**Version** 1.0.20130427  

------

下载之后详细的文档在 _path-awstats-[vsersion]_/docs/ 中存在，能够阅读英文的话可以直接参考官方文档。

## 1 Installation

**下载地址** http://sourceforge.net/projects/awstats/

    cd /usr/local/src
    tar zxf /usr/local/src/awstats-7.1.1.tar.gz
    mkdir -p /usr/local/awstats/
    cp -R /usr/local/src/awstats-7.1.1/* /usr/local/awstats/

    yum install perl

## 2 Configuration

awstats_configure.pl 文件能自动帮你生成配置文件，同时将配置文件放在 /etc/awstats/ 目录下。

    perl /usr/local/awstats/tools/awstats_configure.pl

按照提示，输入相关的信息，对于 nginx 而言，提示

> Config file path ('none' to skip web server setup):

时输入 `none`，输入 `y` 创建一个新的配置文件，输入你的应用名称 _website_，默认存放地址为 /etc/awstats，这样就在 /etc/awstats/目录下生成了一个相应的配置文件awstats._website_.conf。

编辑配置文件 /etc/awstats/awstats._website_.conf

    vi /etc/awstats/awstats.www.licunchang.com.conf

修改以下配置

    LogFile="/data/logs/nginx/%YYYY-12%MM-12/www.licunchang.com.access_%YYYY-12%MM-12%DD-12*.log"
    LogType = W
    LogFormat = "%host - %host_r %time1 %methodurl %code %bytesd %refererquot %uaquot %otherquot"
    LogSeparator=" "
    SiteDomain="www.licunchang.com"
    DirData="/data/awstats"

其中 `LogFile`对应的是要分析的日志的完整路径，`LogFormat` 对应的是 nginx 默认的 main 日志格式，如下：

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                          '$status $body_bytes_sent "$http_referer" '
                          '"$http_user_agent" "$http_x_forwarded_for"';

其他格式的日志格式可以根据提醒改写 `LogFormat` 配置。其中的 `DirData` 存放 awstats 生成的分析数据，需要相应的读写权限。

    mkdir -p /data/awstats
    chmod 777 -R /data/awstats

## 3 Reporting

生成 awstats 统计数据，保存在 DirData 目录中

    /usr/local/awstats/wwwroot/cgi-bin/awstats.pl -update -config=www.licunchang.com

    mkdir -p /data/web/awstats.licunchang.com
    chmod 777 -R /data/web/awstats.licunchang.com

因为 nginx 对 Perl 的支持不太好，所以需要把 awstats 的统计数据生成 html 展现出来

    /usr/local/awstats/tools/awstats_buildstaticpages.pl -update -config=www.licunchang.com -lang=cn -dir=/data/web/awstats.licunchang.com -awstatsprog=/usr/local/awstats/wwwroot/cgi-bin/awstats.pl

配置 nginx server，然后就可以通过域名访问统计数据。

    cat > /usr/local/nginx/conf/servers/awstats.licunchang.com.conf <<'EOF'
    server {
        listen       80;
        server_name  awstats.licunchang.com;

        root /data/web/awstats.licunchang.com;
        index index.html;

        location / {
            # allow 10.10.10.0/24;
            autoindex on;
            access_log   off;
            error_log off;
        }
    }
    EOF

将图标和 css 文件拷贝到 web 目录下

    cp -R /usr/local/awstats/wwwroot/icon/* /data/web/awstats.licunchang.com/awstatsicons/
    cp -R /usr/local/awstats/wwwroot/css/* /data/web/awstats.licunchang.com/awstatscss/

## 4 Crontab



