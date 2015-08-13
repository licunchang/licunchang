**File Name** php-filter-function.md  

**Description** PHP 的 filter_* 函数简介    
**Author** LiCunchang(printf@live.com)  
**Version** 2.0.20130407  

------

## 1 filter\_has\_var

Checks if variable of specified type exists(检查是否存在指定输入类型的变量)

### 1.1 Description

    filter_has_var(type, variable_name)

### 1.2 Parameters

* **type**    必需。检查的类型。可能的值：`INPUT_GET`, `INPUT_POST`, `INPUT_COOKIE`, `INPUT_SERVER`, `INPUT_ENV`

* **variable\_name**    必需。要检查的变量的名称(例如: `name`)

### 1.3 Return Values

Returns **`TRUE`** on success or **`FALSE`** on failure.

### 1.4 Examples

    <?php
    //filter_has_var.php

    if(!filter_has_var(INPUT_GET, "name")){
        echo("1:Input type does not exist").'<br/>';
    }
    else{
        echo("2:Input type exists").'<br/>';
    }

    $_GET['password'] = 'password';

    if(!filter_has_var(INPUT_GET, "password")){
        echo("3:Input type does not exist").'<br/>';
    }
    else{
        echo("4:Input type exists").'<br/>';
    }

    if(isset($_GET['name'])){
        echo("5:Variable is set and is not NULL").'<br/>';
    }
    else{
        echo("6:Variable isn't set or is NULL").'<br/>';
    }

    if(empty($_GET['name'])){
        echo("7:Variable is empty").'<br/>';
    }
    else{
        echo("8:Variable isn't empty").'<br/>';
    }

    unset($_GET['name']);

    if(!isset($_GET['name'])){
        echo("9:Variable does not exist").'<br/>';
    }

    if(!filter_has_var(INPUT_GET, "name")){
        echo("10:Input type does not exist").'<br/>';
    }
    else{
        echo("11:Input type exists").'<br/>';
    }

    if(isset($_GET['name'])){
        echo("12:Variable is set and is not NULL").'<br/>';
    }
    else{
        echo("13:Variable isn't set or is NULL").'<br/>';
    }

    if(empty($_GET['name'])){
        echo("14:Variable is empty").'<br/>';
    }
    else{
        echo("15:Variable isn't empty").'<br/>';
    }

测试方式

1. GET http://localhost/filter\_has\_var.php?name=licunchang

    > 2:Input type exists    
    > 3:Input type does not exist    
    > 5:Variable is set and is not NULL    
    > 8:Variable isn't empty    
    > 9:Variable does not exist    
    > 11:Input type exists    
    > 13:Variable isn't set or is NULL    
    > 14:Variable is empty    

2. GET http://localhost/filter\_has\_var.php

    > 1:Input type does not exist    
    > 3:Input type does not exist    
    > 6:Variable isn't set or is NULL    
    > 7:Variable is empty    
    > 9:Variable does not exist    
    > 10:Input type does not exist    
    > 13:Variable isn't set or is NULL    
    > 14:Variable is empty    

3. GET http://localhost/test/filter\_has\_var.php?name=

    > 2:Input type exists    
    > 3:Input type does not exist    
    > 5:Variable is set and is not NULL    
    > 7:Variable is empty    
    > 9:Variable does not exist    
    > 11:Input type exists    
    > 13:Variable isn't set or is NULL    
    > 14:Variable is empty    
    
由上面得出：

1. `filter_has_var()` 函数只对数据的原始值进行检查，而不是对 `$_GET` 数组的元素进行检查，对 `$_GET` 数组的操作不影响结果，其他 `$_POST`、`$_COOKIE` 等类似。

2. `filter_has_var()` 函数不能检查变量 empty 的情况。

**其他** 据说 `filter_has_var()` 比 `isset()` 效率要高，未经验证。

## 2 filter\_id

Returns the filter ID belonging to a named filter(函数返回指定过滤器的 ID 号)

### 2.1 Description

    filter_id(filter_name)

### 2.2 Parameters

* **filter\_name**    必需。规定被获取 ID 号的过滤器。必须是过滤器名称（不是过滤器 ID 名）。可使用 filter_list() 函数来获取所有被支持的过滤器的名称。

### 2.3 Return Values

**Integer** on success or **`FALSE`** if filter doesn't exist.

### 2.4 Examples

    <?php
    //filter_id.php

    $filters = filter_list(); 
    foreach($filters as $filter_name) { 
        echo $filter_name .": ".filter_id($filter_name)."<br>"; 
    }

输出结果

    > int: 257    
    > boolean: 258    
    > float: 259    
    > validate_regexp: 272    
    > validate_url: 273    
    > validate_email: 274    
    > validate_ip: 275    
    > string: 513    
    > stripped: 513    
    > encoded: 514    
    > special_chars: 515    
    > full_special_chars: 522    
    > unsafe_raw: 516    
    > email: 517    
    > url: 518    
    > number_int: 519    
    > number_float: 520    
    > magic_quotes: 521    
    > callback: 1024    

## 3 filter_var

Filters a variable with a specified filter(通过指定的过滤器过滤变量)

### 2.1 Description

    filter_var(variable, filter, options)

### 2.2 Parameters

* **variable**    必需。规定要过滤的变量。
* **filter**    可选。规定要使用的过滤器的 ID。
* **options**    可选。规定包含标志/选项的数组。检查每个过滤器可能的标志和选项。

### 2.3 Return Values

**Integer** on success or **`FALSE`** if filter doesn't exist.

### 2.4 Examples










































## 3 filter\_input\_array

Gets external variables and optionally filters them(从脚本外部获取多项输入，并进行过滤。)

本函数无需重复调用 filter_input()，对过滤多个输入变量很有用。

### 3.1 Description

    filter_input(input_type, args)

### 3.2 Parameters

* **input\_type**    必需。规定输入类型。可能的值：`INPUT_GET`, `INPUT_POST`, `INPUT_COOKIE`, `INPUT_SERVER`, `INPUT_ENV`

* **args**    必需。规定过滤器参数数组。

合法的数组键是变量名。合法的值是过滤器 ID，或者规定过滤器、标志以及选项的数组。
该参数也可以是一个单独的过滤器 ID，如果是这样，输入数组中的所有值由指定过滤器进行过滤。

### 3.3 Return Values

如果成功，则返回被过滤的数据，如果失败，则返回 false。

### 3.4 Examples

    <?php
    error_reporting(E_ALL | E_STRICT);
    /* data actually came from POST
    $_POST = array(
        'product_id'    => 'libgd<script>',
        'component'     => '10',
        'versions'      => '2.0.33',
        'testscalar'    => array('2', '23', '10', '12'),
        'testarray'     => '2',
    );
    */

    $args = array(
        'product_id'   => FILTER_SANITIZE_ENCODED,
        'component'    => array('filter'    => FILTER_VALIDATE_INT,
                                'flags'     => FILTER_REQUIRE_ARRAY, 
                                'options'   => array('min_range' => 1, 'max_range' => 10)
                               ),
        'versions'     => FILTER_SANITIZE_ENCODED,
        'doesnotexist' => FILTER_VALIDATE_INT,
        'testscalar'   => array(
                                'filter' => FILTER_VALIDATE_INT,
                                'flags'  => FILTER_REQUIRE_SCALAR,
                               ),
        'testarray'    => array(
                                'filter' => FILTER_VALIDATE_INT,
                                'flags'  => FILTER_REQUIRE_ARRAY,
                               )

    );

    $myinputs = filter_input_array(INPUT_POST, $args);

    var_dump($myinputs);
    echo "\n";




















## filter\_input — Gets a specific external variable by name and optionally filters it


## filter\_list — Returns a list of all supported filters


## filter\_var\_array — Gets multiple variables and optionally filters them


## filter\_var — Filters a variable with a specified filter



## 附录：



INPUT_POST (integer)

    POST variables( POST 变量).

INPUT_GET (integer)

    GET variables( GET 变量).

INPUT_COOKIE (integer)

    COOKIE variables( COOOKIE 变量).

INPUT_ENV (integer)
    
    ENV variables( ENV 变量).

INPUT_SERVER (integer)

    SERVER variables( SERVER 变量).

INPUT_SESSION (integer)

    SESSION variables. (not implemented yet)

INPUT_REQUEST (integer)

    REQUEST variables. (not implemented yet)

FILTER_FLAG_NONE (integer)
    
    No flags.

FILTER_REQUIRE_SCALAR (integer)
    
    Flag used to require scalar as input

FILTER_REQUIRE_ARRAY (integer)
    
    Require an array as input.

FILTER_FORCE_ARRAY (integer)
    
    Always returns an array(数组).

FILTER_NULL_ON_FAILURE (integer)

    Use NULL instead of FALSE on failure.

FILTER_VALIDATE_INT (integer)
    
    ID of "int" filter(整形).

FILTER_VALIDATE_BOOLEAN (integer)

    ID of "boolean" filter(布尔类型).

FILTER_VALIDATE_FLOAT (integer)

    ID of "float" filter(浮点数类型).

FILTER_VALIDATE_REGEXP (integer)

    ID of "validate_regexp" filter(正则表达式).

FILTER_VALIDATE_URL (integer)

    ID of "validate_url" filter(URL).

FILTER_VALIDATE_EMAIL (integer)
    
    ID of "validate_email" filter(Email).

FILTER_VALIDATE_IP (integer)

ID of "validate_ip" filter(IP地址).

FILTER_DEFAULT (integer)
    
    ID of default ("string") filter.

FILTER_UNSAFE_RAW (integer)
    
    ID of "unsafe_raw" filter.

FILTER_SANITIZE_STRING (integer)

    ID of "string" filter.

FILTER_SANITIZE_STRIPPED (integer)

    ID of "stripped" filter.

FILTER_SANITIZE_ENCODED (integer)
    
    ID of "encoded" filter.

FILTER_SANITIZE_SPECIAL_CHARS (integer)
    
    ID of "special_chars" filter.

FILTER_SANITIZE_EMAIL (integer)
    
    ID of "email" filter.

FILTER_SANITIZE_URL (integer)
    
    ID of "url" filter.

FILTER_SANITIZE_NUMBER_INT (integer)
    
    ID of "number_int" filter.

FILTER_SANITIZE_NUMBER_FLOAT (integer)
    
    ID of "number_float" filter.

FILTER_SANITIZE_MAGIC_QUOTES (integer)
    
    ID of "magic_quotes" filter.

FILTER_CALLBACK (integer)
    
    ID of "callback" filter.

FILTER_FLAG_ALLOW_OCTAL (integer)
    
    Allow octal notation (0[0-7]+) in "int" filter.

FILTER_FLAG_ALLOW_HEX (integer)
    
    Allow hex notation (0x[0-9a-fA-F]+) in "int" filter.

FILTER_FLAG_STRIP_LOW (integer)
    
    Strip characters with ASCII value less than 32.

FILTER_FLAG_STRIP_HIGH (integer)
    
    Strip characters with ASCII value greater than 127.

FILTER_FLAG_ENCODE_LOW (integer)
    
    Encode characters with ASCII value less than 32.

FILTER_FLAG_ENCODE_HIGH (integer)
    
    Encode characters with ASCII value greater than 127.

FILTER_FLAG_ENCODE_AMP (integer)
    
    Encode &.

FILTER_FLAG_NO_ENCODE_QUOTES (integer)
    
    Don't encode ' and ".

FILTER_FLAG_EMPTY_STRING_NULL (integer)
    
    (No use for now.)

FILTER_FLAG_ALLOW_FRACTION (integer)
    
    Allow fractional part in "number_float" filter.

FILTER_FLAG_ALLOW_THOUSAND (integer)
    
    Allow thousand separator (,) in "number_float" filter.

FILTER_FLAG_ALLOW_SCIENTIFIC (integer)
    
    Allow scientific notation (e, E) in "number_float" filter.

FILTER_FLAG_PATH_REQUIRED (integer)
    
    Require path in "validate_url" filter.

FILTER_FLAG_QUERY_REQUIRED (integer)
    
    Require query in "validate_url" filter.

FILTER_FLAG_IPV4 (integer)
    
    Allow only IPv4 address in "validate_ip" filter(IPv4).

FILTER_FLAG_IPV6 (integer)
    
    Allow only IPv6 address in "validate_ip" filter(IPv6).

FILTER_FLAG_NO_RES_RANGE (integer)
    
    Deny reserved addresses in "validate_ip" filter.

FILTER_FLAG_NO_PRIV_RANGE (integer)
    
    Deny private addresses in "validate_ip" filter.


