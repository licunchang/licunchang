**File Name** nginx-http-rewrite.md  

**Description** nginx http rewrite 入门    
**Author** LiCunchang(printf@live.com)  
**Version** 2.0.20130408  

------

# 1 概述

使用 **ngx\_http\_rewrite\_module** 模块允许正则替换URI，返回页面重定向，还可以按条件选择配置。

**ngx\_http\_rewrite\_module** 模块指令的处理顺序按照下面的执行：

1. 处理在 `server` 级别中定义的模块指令  
2. 根据请求查找 `location`  
3. 处理步骤2查找到的 `location` 中定义的模块指令。如果指令改变了 URI ，按新的 URI 查找 `location` 。这个循环至多重复10次，之后 nginx 返回错误 **500 (Internal Server Error)**

## 2 指令介绍

### 2.1 break

> **syntax:**    `break;`    
> **context:**    server, location, if    

停止处理当前这一轮的 ngx\_http\_rewrite\_module 指令集。例如：

Examples 1

    if ($slow) {
        limit_rate 10k;
        break;
    }

### 2.2 if

> **syntax:**    `if (condition) { ... }`     
> **context:**    server, location

计算 `condition` 的值，如果为 `true` 执行定义在大括号中的 rewrite 模块指令，并将 if 指令中的配置指定给请求。if 指令会从上一层配置中继承配置。

`condition` 可以是下面的任意一种：

* 变量名。如果变量为空或者为 `0`，则返回 `false`。**注意** 在 1.0.1 版本之前，以 `0` 开始的字符串也会被认为 `false`  
* 将变量与字符串使用 `=` 和 `!=` 运算符进行比较  
* 使用 `~` （大小写敏感）和 `~*` （大小写不敏感）运算符匹配变量与正则表达式。正则表达式可以包含匹配组，匹配结果后续可以使用变量 $1..$9 引用。也可以使用非运算符 `!~` 和 `!~*`。如果正则表达式中包含字符 `}` 或者 `;` ，整个表达式应该被包含在单引号或双引号的引用中  
* 使用 `-f` 和 `!-f` 运算符检查文件是否存在；
* 使用 `-d` 和 `!-d` 运算符检查目录是否存在；
* 使用 `-e` 和 `!-e` 运算符检查文件、目录或符号链接是否存在；
* 使用 `-x` 和 `!-x` 运算符检查可执行文件；

Examples 1 如果客户端 User Agent 为 MSIE，则 rewrite到 msie 文件夹中

    if ($http_user_agent ~ MSIE) {
        rewrite ^(.*)$ /msie/$1 break;
    }

Examples 2 如果客户端 cookie 匹配正则，则设置 `$id` 为cookie值

    if ($http_cookie ~* "id=([^;]+)(?:;|$)") {
        set $id $1;
    }

Examples 3 如果客户端 request_method 为 `POST`，则返回 405

    if ($request_method = POST) {
        return 405;
    }

Examples 4 ??

    if ($slow) {
        limit_rate 10k;
    }

Examples 5 防止盗链

    valid_referers none blocked server_names *.example.com;
    if ($invalid_referer) {
        return 403;
    }
        
**注意** nginx 是不支持 `if` 嵌套的，同时 `condition` 中不能使用多条件判断，下面的两则都是错误的。

    if (condition) {
        if (condition) {
            # 不支持嵌套
        }
    }

    if (condition_1 && condition_2) {
        # 不支持多条件判断
    }

### 2.3 return

> **syntax:**    `return code [text];` or `return code URL;` or `return URL;`     
> **context:**    server, location, if

停止处理并返回指定 code 给客户端。返回非标准的状态码 444 可以直接关闭连接而不返回响应头。

从 0.8.42 版开始，可以在指令中指定重定向的 URL（状态码为301、302、303和307），或者指定响应体文本（状态码为其它值）。响应体文本或重定向 URL 中可以包含变量。作为一种特殊情况，重定向 URL 可以简化为当前 server 的本地 URI，那么完整的重定向URL将按照请求协议（`$scheme`）、`server_name_in_redirect` 指令和 `port_in_redirect` 指令的配置进行补全。

另外，状态码为 302 的临时重定向使用的 URL 可以作为指令的唯一参数。该参数应该以 `http://`、`https://` 或者 `https://` 开始。URL 中可以包含变量。

> 0.7.51 版本以前只能返回下面状态码： 204、400、402 — 406、408、410、411、413、416 和 500 — 504。

> 直到1.1.16和1.0.13版，状态码307才被认为是一种重定向。

### 2.4 rewrite

> **syntax:**    `rewrite regex replacement [flag];`     
> **context:**    server, location, if

如果指定的正则表达式能匹配 URI，此 URI 将被 replacement 参数定义的字符串改写。rewrite 指令按其在配置文件中出现的顺序执行。flag 可以终止后续指令的执行。如果 replacement 的字符串以 `http://` 或 `https://` 开头，nginx 将结束执行过程，并返回给客户端一个重定向。

可选的 flag 参数可以是其中之一：

* **last**

    停止执行当前这一轮的 ngx\_http\_rewrite\_module 指令集，然后查找匹配改变后 URI 的新 location；

* **break**

    停止执行当前这一轮的 ngx\_http\_rewrite\_module 指令集；

* **redirect**

    在 replacement 字符串未以 `http://` 或 `https://` 开头时，使用返回状态码为 302 的临时重定向；

* **permanent**

    返回状态码为 301 的永久重定向。

完整的重定向URL将按照请求协议（$scheme）、server\_name\_in\_redirect 指令和 port\_in\_redirect 指令的配置进行补全。

Example 1

    server {
        ...
        rewrite ^(/download/.*)/media/(.*)\..*$ $1/mp3/$2.mp3 last;
        rewrite ^(/download/.*)/audio/(.*)\..*$ $1/mp3/$2.ra  last;
        return  403;
        ...
    }

但是当上述指令写在 `/download/` 的 `location` 中时，应使用标志 `break` 代替 `last` ，否则 nginx 会重复10轮循环，然后返回错误500：

    location /download/ {
        rewrite ^(/download/.*)/media/(.*)\..*$ $1/mp3/$2.mp3 break;
        rewrite ^(/download/.*)/audio/(.*)\..*$ $1/mp3/$2.ra  break;
        return  403;
    }

如果 replacement 字符串包括新的请求参数，以往的请求参数会添加到新参数后面。如果不希望这样，在 replacement 字符串末尾加一个问号 `?`，就可以避免，比如：

    rewrite ^/users/(.*)$ /show?user=$1? last;

如果正则表达式中包含字符 `}` 或者 `;`，整个表达式应该被包含在单引号或双引号的引用中。

Note that outside location blocks, `last` and `break` are effectively the same.

rewrite 不对 **hostname** 或者 **query string** 进行操作，例如：

    http://www.licunchang.com/user/info?id=2000&t=1361235236

rewrite 只能操作 `/user/info` 这一部分，也就是变量 `$uri` 的值，要对 **query string** 也就是变量 `$query_string` 或者 `$args` 的值进行操作可以使用 `$arg_PARAMETER` 变量，比如上面的 url ，`$arg_id` 的值就是 `20000`。

    location ~* ^/user/ {
        if ($args ~* "id=\d+$") {
            rewrite ^ $scheme://$host/userinfo.php?id=$arg_id? permanent;
        }
    }
    
再比如要将 /friend.php?act=friend&fid=200000 重定向到 /user_info.php?act=others&uid=200000 使用下面的方法。

    if ($args ~* "act=friend&fid=\d+$"){
        rewrite ^/friend.php$ /user_info.php?act=others&uid=$arg_fid? permanent;
    }
 
### 2.5 rewrite\_log

> **syntax:**    `rewrite_log on | off;`  
> **default:**    `rewrite_log off;`  
> **context:**    server, location, if

开启或者关闭将 ngx\_http\_rewrite\_module 模块指令的处理日志以 notice 级别记录到错误日志( error\_log )中。

### 2.6 set

> **syntax:**    `set variable value;`  
> **context:**    server, location, if

为指定变量 variable 设置变量值 value。 value 可以包含文本、变量或者它们的组合。

### 2.7 uninitialized\_variable\_warn

> **syntax:**    `uninitialized_variable_warn on | off;`  
> **default:**    `uninitialized_variable_warn on;`  
> **context:**    server, location, if

控制是否记录变量未初始化的警告到日志。

## 3 内部实现

ngx\_http\_rewrite\_module 模块的指令在解析配置阶段被编译成 nginx 内部指令。这些内部指令在处理请求时被解释执行。而解释器是一个简单的虚拟堆栈机器（ a simple virtual stack machine）。

比如，下面指令

    location /download/ {
        if ($forbidden) {
            return 403;
        }

        if ($slow) {
            limit_rate 10k;
        }

        rewrite ^/(download/.*)/media/(.*)\..*$ /$1/mp3/$2.mp3 break;
    }

将被翻译成下面这些指令：

    variable $forbidden
    check against zero
        return 403
        end of code
    variable $slow
    check against zero
    match of regular expression
    copy "/"
    copy $1
    copy "/mp3/"
    copy $2
    copy ".mp3"
    end of regular expression
    end of code

请注意没有对应上面的 limit\_rate 指令的内部指令，因为这个指令与 ngx\_http\_rewrite\_module 模块无关。nginx 会为这个 if 块单独创建一个配置，包含 limit\_rate 等于10k。如果条件为真，nginx将把这个配置指派给请求。

指令

    rewrite ^/(download/.*)/media/(.*)\..*$ /$1/mp3/$2.mp3 break;

可以通过将正则表达式中的第一个斜线“/”放入圆括号，来实现节约一个内部指令：

    rewrite ^(/download/.*)/media/(.*)\..*$ $1/mp3/$2.mp3 break;

对应的内部指令将会是这样：

    match of regular expression
    copy $1
    copy "/mp3/"
    copy $2
    copy ".mp3"
    end of regular expression
    end of code

## References

1. Module ngx\_http\_rewrite\_module [http://nginx.org/en/docs/http/ngx\_http\_rewrite\_module.html](http://nginx.org/en/docs/http/ngx_http_rewrite_module.html "Module ngx_http_rewrite_module")    
2. ngx\_http\_rewrite\_module模块 [http://nginx.org/cn/docs/http/ngx\_http\_rewrite\_module.html](http://nginx.org/cn/docs/http/ngx_http_rewrite_module.html "ngx_http_rewrite_module模块")
3. Nginx Rewrite研究笔记 [http://blog.cafeneko.info/2010/10/nginx\_rewrite\_note](http://blog.cafeneko.info/2010/10/nginx_rewrite_note/ "Nginx Rewrite研究笔记") 
4. HttpCoreModule [http://wiki.nginx.org/HttpCoreModule](http://wiki.nginx.org/HttpCoreModule "HttpCoreModule") 
