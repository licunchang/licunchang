**File Name** php-traps.md  

**Description** PHP "陷阱"    
**Author** LiCunchang(printf@live.com)  
**Version** 2.0.20130417  

------

## 1 urlencode() & rawurlencode()

* urlencode()

    > string urlencode ( string $str )    

    urlencode() 函数的作用是对 URL 进行字符串编码。将所有除 `-` 、 `_`  、 `.` 之外的非字母、数字字符进行处理，替换为 `%` 后跟两位十六进制数的形式，**空格则使用 `+` 进行替换**。此编码与 WWW 表单 POST 数据的编码方式是一样的，同时与 application/x-www-form-urlencoded 的媒体类型[编码方式](http://www.w3.org/TR/html401/interact/forms.html#h-17.13.4.1)一样。**由于历史原因，此编码在将空格编码为加号 `+` 方面与 RFC1738 编码不同。**

* rawurlencode()

    > string rawurlencode ( string $str )    

    urlencode() 函数的作用是按照 **RFC 3986** 对 URL 进行字符串编码。将所有除 `-` 、 `_`  、 `.` 、 `~` 之外的非字母、数字字符进行处理，替换为 `%` 后跟两位十六进制数的形式。这是在 RFC 3986 中描述的编码，是为了保护原义字符以免其被解释为特殊的 URL 定界符，同时保护 URL 格式以免其被传输媒体（像一些邮件系统）使用字符转换时弄乱。

    **注意** 在 php 5.3.0 之前，`~`是按照 RFC 1738 进行编码的。php 5.3.0 之后，不进行编码。

### Examples

    



## 2 echo & print 






















## References

1. Forms [http://www.w3.org/TR/html401/interact/forms.html#h-17.13.4.1](http://www.w3.org/TR/html401/interact/forms.html#h-17.13.4.1 "Forms")    
