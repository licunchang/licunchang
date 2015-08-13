**File Name** google-shell-style-guide.md

**Description** shell 编程规范 From Google(中文简例)  
**Author** LiCunchang(printf@live.com)  
**Version** 1.0.20130527  

------

## 源地址

[http://google-styleguide.googlecode.com/svn/trunk/shell.xml](http://google-styleguide.googlecode.com/svn/trunk/shell.xml)

## 1 Background(背景知识)

### 1.1 Which Shell to Use(使用哪一种 shell )

**Bash** 是唯一允许执行的 shell 脚本语句。

可执行脚本的 Sha-Bang 行必须以 `#!/bin/bash` 开始，

### 1.2 When to use Shell(什么时候使用 shell )

shell 只在小型工具脚本或者封装里面使用。

因为 shell 不是一种开发语言

## 2 Shell Files and Interpreter Invocation

### 2.1 File Extensions

可执行脚本不使用扩展名(强烈推荐)或者 `.sh` 扩展名，库脚本必须 `.sh` 扩展名同时必须是不可执行的。

在程序执行的时候，我们没必要知道程序是由什么语言编写的，同时 shell 也不要求有一个扩展名，所以我们倾向于不使用扩展名。

但是，对库文件来说，知道是什么语言编写的是十分重要的，因为通常会有相同库文件的不同语言实现。这样就能根据扩展名来进行区别。

### 2.2 SUID/SGID

SUID 和 SGID 在 shell 脚本中是被禁止的。

在 shell 中使用 SUID/SGID 有太多的安全问题，如果需要这方面的功能，建议使用 `sudo`。

## 3 Environment

### 3.1 STDOUT vs STDERR

所有的错误信息必须输出到 **STDERR**。

这样就能区别

## 4 Comments

### 4.1 File Header

内容的开头必须有描述功能的文本。

### 4.2 Function Comments

任何函数必须有函数注释。

函数的注释必须包括：

* 函数功能描述
* 全局变量使用或者修改
* 参数
* 返回值

例子

    #!/bin/bash
    #
    # Perform hot backups of Oracle databases.

    export PATH='/usr/xpg4/bin:/usr/bin:/opt/csw/bin:/opt/goog/bin'

    #######################################
    # Cleanup files from the backup dir
    # Globals:
    #   BACKUP_DIR
    #   ORACLE_SID
    # Arguments:
    #   None
    # Returns:
    #   None
    #######################################
    cleanup() {
      ...
    }

### 4.3 Implementation Comments



### 4.4 TODO Comments


## 5 Formatting(格式)

### 5.1 Indentation(缩进)

缩进两个空格，不使用**tab**。


### 5.2 Line Length and Long Strings

行长度最多 80 个字符。



### 5.3 Pipelines

除非在一行中放不下所有的管道，否则它们应该写在一行中。

### 5.4 Loops

把 `:do` 和 `:then` 放于 `while`、`for`、`if` 的同一行。


### 5.5 Variable expansion


### 5.6 Quoting

* 永远使用引号包含变量、命令、空格、
* 
*
* 
* 使用 `"$@"`，除非你有足够的理由使用 `$*`



## 6 Features and Bugs


### 6.1 Command Substitution

使用 `$(command)` 来替代反单引号。



### 6.2 Test, [ and [[

比起 `test` `[` `/usr/bin/[` 来 `[[ ... ]]` 更值得推荐。

### 6.3 Testing Strings


### 6.4 Wildcard Expansion of Filenames


### 6.5 Eval

`eval` 函数应该避免使用。

### 6.6 Pipes to While


## 7 Naming Conventions


### 7.1 Function Names



### 7.2 Variable Names


### 7.3 Constants and Environment Variable Names


### 7.4 Source Filenames

小写文件名，单词之间使用下划线 `_` 来分割。

### 7.5 Read-only Variables

使用 `readonly` 或者 `declare -r` 来确保变量是只读的。

### 7.6 Use Local Variables



### 7.7 Function Location



### 7.8 main

对于很长的脚本来说，使用一个叫 `main` 的函数来包含其他函数作为脚本入口很有必要。

## 8 Calling Commands


### 8.1 Checking Return Values


### 8.2 Builtin Commands vs. External Commands


## 9 Conclusion(结论)














