**File Name** php-variables.md  

**Description** PHP Variables 简介    
**Author** LiCunchang(printf@live.com)  
**Version** 2.0.20130409  

------

## 1 $\_SERVER["SCRIPT\_NAME"] & $\_SERVER["PHP\_SELF"] & $\_SERVER["REQUEST\_URI"] & $\_SERVER["DOCUMENT\_URI"]

http://www.licunchang.com/data/?name=licunchang

$_SERVER["SCRIPT_NAME"]     /data/index.php
$_SERVER["REQUEST_URI"]     /data/?name=licunchang
$_SERVER["DOCUMENT_URI"]    /data/index.php
$_SERVER["PHP_SELF"]        /data/index.php

http://www.licunchang.com/data/

$_SERVER["SCRIPT_NAME"]     /data/index.php
$_SERVER["REQUEST_URI"]     /data/
$_SERVER["DOCUMENT_URI"]    /data/index.php
$_SERVER["PHP_SELF"]        /data/index.php

http://www.licunchang.com/

$_SERVER["SCRIPT_NAME"]     /index.php
$_SERVER["REQUEST_URI"]     /
$_SERVER["DOCUMENT_URI"]    /index.php
$_SERVER["PHP_SELF"]        /index.php

http://www.licunchang.com/data/index

$_SERVER["SCRIPT_NAME"]     /data/index.php
$_SERVER["REQUEST_URI"]     /data/index
$_SERVER["DOCUMENT_URI"]    /data/index.php
$_SERVER["PHP_SELF"]        /data/index.php

/usr/local/php/bin/php -f /data/web/www.licunchang.com/index.php 

$_SERVER["PHP_SELF"]            /data/web/www.licunchang.com/index.php
$_SERVER["SCRIPT_NAME"]         /data/web/www.licunchang.com/index.php