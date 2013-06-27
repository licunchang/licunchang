**File Name** vim-textwidth-80.md  

**Description** Vim 字行宽度设置   
**Author** LiCunchang(printf@live.com)  
**Version** 1.0.20130626  

------

在 vim7.3 中支持 `set colorcolumn=80` 这样的语法，但是在编辑器中看起来有些抢眼，可以使用下面的方法，添加到 `~/.vimrc` 文件：

    highlight OverLength ctermbg=red ctermfg=white guibg=#592929
    match OverLength /\%>80v.\+/

## References
1. Vim 80 column layout concerns [http://stackoverflow.com/questions/235439/vim-80-column-layout-concerns](http://stackoverflow.com/questions/235439/vim-80-column-layout-concerns "Vim 80 column layout concerns")
