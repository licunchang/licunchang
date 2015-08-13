**File Name** linux-practices.md  
**Description**  Linux Practices    
**Author** LiCunchang (printf@live.com)  
**Version** 1.0.20140321  

------



	service cpuspeed stop
 
    chkconfig --del cpuspeed



## 1

    sudo !!

以root的身份执行上一条命令 。

## 2

    cd –

回到上一次的目录 。

## 3

    ^old^new

替换前一条命令里的部分字符串。

场景：`echo "wanderful"`，其实是想输出 `echo "wonderful"`。只需要 `^a^o` 就行了，对很长的命令的错误拼写有很大的帮助。