**File Name** http-status-code.md

**Description** http 状态码  
**Author** LiCunchang(printf@live.com)  
**Version** 1.0.20130327  

------

## 概述

HTTP状态码（HTTP Status Code）是用以表示网页服务器HTTP响应状态的3位数字代码。它由 [RFC 2616](http://www.ietf.org/rfc/rfc2616.txt) 规范定义的，并得到RFC 2518、RFC 2817、RFC 2295、RFC 2774、RFC 4918等规范扩展。

## Informational 1xx

这一类型的状态码，代表请求已被接受，需要继续处理。这类响应是临时响应，只包含状态行和某些可选的响应头信息，并以空行结束。由于 HTTP/1.0 协议中没有定义任何 1xx 状态码，所以除非在某些试验条件下，服务器禁止向此类客户端发送 1xx 响应。


### 100 Continue



























