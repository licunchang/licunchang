**File Name** php-sudoku.md  

**Description** 所谓"69岁农民3天破解世界最难数独游戏"    
**Author** LiCunchang(printf@live.com)  
**Version** 2.0.20130526  

------

闲的蛋疼，写个程序递归一下新闻中"世界最难数独游戏"。

    8    0    0    0    0    0    0    0    0    

    0    0    3    6    0    0    0    0    0    

    0    7    0    0    9    0    2    0    0    

    0    5    0    0    0    7    0    0    0    

    0    0    0    0    4    5    7    0    0    

    0    0    0    1    0    0    0    3    0    

    0    0    1    0    0    0    0    6    8    

    0    0    8    5    0    0    0    1    0    

    0    9    0    0    0    0    4    0    0    

上代码

    <?php

    /**
     * 输出数独
     *
     */
    function output(& $sudoku){
        foreach($sudoku as $key_r => $row) {
            foreach($row as $key_c => $value) {
                echo $value . "&nbsp;&nbsp;&nbsp;&nbsp;";
            }
            echo "<br/><br/>";
        }
    }

    /**
     * 初始化数独
     *
     */
    function init(& $sudoku){

        for($row = 1; $row <= 9; $row++) { 
            for($col = 1; $col <= 9; $col++) { 
                $sudoku[$row][$col] = 0;
            }
        }

        $sudoku['1']['1'] = 8;
        $sudoku['2']['3'] = 3;
        $sudoku['2']['4'] = 6;
        $sudoku['3']['2'] = 7;
        $sudoku['3']['5'] = 9;
        $sudoku['3']['7'] = 2;
        $sudoku['4']['2'] = 5;
        $sudoku['4']['6'] = 7;
        $sudoku['5']['5'] = 4;
        $sudoku['5']['6'] = 5;
        $sudoku['5']['7'] = 7;
        $sudoku['6']['4'] = 1;
        $sudoku['6']['8'] = 3;
        $sudoku['7']['3'] = 1;
        $sudoku['7']['8'] = 6;
        $sudoku['7']['9'] = 8;
        $sudoku['8']['3'] = 8;
        $sudoku['8']['4'] = 5;
        $sudoku['8']['8'] = 1;
        $sudoku['9']['2'] = 9;
        $sudoku['9']['7'] = 4;
    }

    /**
     * 根据给出的行列编号给出可用的数字
     * 
     */
    function give(& $sudoku, $row, $col, $row_p, $col_p){
        if($row == 10 || $col == 10){
            exit;
        }
        if($sudoku[$row][$col] != 0){
            return array($sudoku[$row][$col] => 0, );
        }
        $temp = array(
                1 => 0,
                2 => 0,
                3 => 0,
                4 => 0,
                5 => 0,
                6 => 0,
                7 => 0,
                8 => 0,
                9 => 0,
            );

        for($i=1; $i <= 9; $i++) { 
            if(array_key_exists($sudoku[$row][$i], $temp) 
                && isset($temp[($sudoku[$row][$i])])){
                unset($temp[($sudoku[$row][$i])]);
            }
        }
        for($i=1; $i <= 9; $i++) { 
            if(array_key_exists($sudoku[$i][$col], $temp) 
                && isset($temp[($sudoku[$i][$col])])){
                unset($temp[($sudoku[$i][$col])]);
            }
        }
        $row_stt = (($row_p - 1) * 3 + 1);
        $row_end = ($row_p * 3);

        $col_stt = (($col_p - 1) * 3 + 1);
        $col_end = ($col_p * 3);

        for($i = $row_stt; $i <= $row_end; $i++) { 
            for($j = $col_stt; $j <= $col_end; $j++) { 
                if(array_key_exists($sudoku[$i][$j], $temp) 
                    && isset($temp[($sudoku[$i][$j])])){
                    unset($temp[($sudoku[$i][$j])]);
                }
            }
        }
        return $temp;
    }

    function sudoku($sudoku, $row = 1, $col = 1){
        $row ++;
        if($row > 9){
            if($col == 9){
                output($sudoku);
                exit;
            }
            $row = 1;
            $col ++;
        }

        $row_p = ceil($row / 3);
        $col_p = ceil($col / 3);
        $available_number = give($sudoku, $row, $col, $row_p, $col_p);

        if(empty($available_number)){
            return false;
        }
        foreach($available_number as $key => $value) {
            $sudoku[$row][$col] = $key;
            if(sudoku($sudoku, $row, $col)){
                break;
                if($row == 9 && $col == 9){
                    break;
                    return true;
                }
            }
        }
    }

    ini_set('max_input_nesting_level', '9999999');
    ini_set('max_execution_time', '9999999'); 
    ini_set('xdebug.max_nesting_level', '9999999');

    $sudoku = array();

    init($sudoku);

    //sudoku($sudoku, 0, 1);

    output($sudoku);

擦，写的好烂啊！

话说最少提供17个数字就能确定一个唯一的数独结果，从这个方面看，估计这个数独远非“世界最难”。

中国记者娱乐无下限！