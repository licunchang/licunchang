**File Name** nginx-practices.md  
**Description**  Nginx Practices    
**Author** LiCunchang (printf@live.com)  
**Version** 1.0.20140321  

------

## Request ID

In most cases you don't need a custom module, you can simply set a header with a combination of embedded variables of http_core_module which is (most probably) unique. Example:

    location / {
        proxy_pass http://upstream;
        proxy_set_header X-Request-Id $pid-$msec-$remote_addr-$request_length;
    }

This would yield a request id like "31725-1406109429.299-127.0.0.1-1227" and should be "unique enough" to serve as a trace id.


try_files & $fastcgi_path_info

http://huoding.com/2013/10/23/290
https://trac.nginx.org/nginx/ticket/321
https://www.nginx.com/resources/wiki/start/topics/examples/phpfcgi/#

https://servers.ustclug.org/2014/09/nginx-try_files-fallacy/


## redirect http request to https request

HTTP Strict Transport Security

add_header Strict-Transport-Security "max-age=63072000; includeSubdomains; preload";

