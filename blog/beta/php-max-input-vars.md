**File Name** php-max-input-vars.md  

**Description** max_input_vars    
**Author** LiCunchang(printf@live.com)  
**Version** 2.0.20130426  

------

## 问题描述

> 在用表单 POST 数据到后端时，如果超过一定数量的字段，则会丢失一部分数据。

## 问题解决

从 PHP5.3.9 开始，在配置文件中引入了一个 `max_input_vars` 的变量，表示

max_input_vars 1000 PHP_INI_PERDIR 从 PHP 5.3.9 起可用。 


接受多少 输入的变量（限制分别应用于 $_GET、$_POST 和 $_COOKIE 超全局变量） 指令的使用减轻了以哈希碰撞来进行拒绝服务攻击的可能性。 如有超过指令指定数量的输入变量，将会导致 E_WARNING 的产生， 更多的输入变量将会从请求中截断。 此限制仅应用于一个多维输入数组的每个嵌套级别。 


