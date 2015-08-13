**File Name** 15-examples-to-master-linux-command-line-history.md  

**Description** 15 Examples To Master Linux Command Line History    
**Author** LiCunchang(printf@live.com)  
**Version** 1.0.20130408    
**See** [15 Examples To Master Linux Command Line History](http://www.thegeekstuff.com/2008/08/15-examples-to-master-linux-command-line-history/)  

------

## 1 使用 HISTTIMEFORMAT 显示命令执行时间

    # export HISTTIMEFORMAT='%F %T '
    # history | more
    1  2008-08-05 19:02:39 service network restart
    2  2008-08-05 19:02:39 exit
    3  2008-08-05 19:02:39 id
    4  2008-08-05 19:02:39 cat /etc/redhat-release

## 2 使用 Control + R 搜索历史

    # [Press Ctrl+R from the command prompt,
    which will display the reverse-i-search prompt]
    (reverse-i-search)`red': cat /etc/redhat-release
    [Note: Press enter when you see your command,
    which will execute the command from the history]
    # cat /etc/redhat-release
    Fedora release 9 (Sulphur)













