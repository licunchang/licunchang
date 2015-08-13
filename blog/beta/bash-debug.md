**File Name** bash-debug.md  

**Description** bash 调试    
**Author** LiCunchang(printf@live.com)  
**Version** 2.0.20130626  

------

## 1 trap

`trap` 是 bash 内置命令，通过`man trap`可以查看该命令的说明。它用于捕获指定的信号并执行预定义的命令。


    [root@localhost ~]# kill -l
     1) SIGHUP       2) SIGINT       3) SIGQUIT      4) SIGILL       5) SIGTRAP
     6) SIGABRT      7) SIGBUS       8) SIGFPE       9) SIGKILL     10) SIGUSR1
    11) SIGSEGV     12) SIGUSR2     13) SIGPIPE     14) SIGALRM     15) SIGTERM
    16) SIGSTKFLT   17) SIGCHLD     18) SIGCONT     19) SIGSTOP     20) SIGTSTP
    21) SIGTTIN     22) SIGTTOU     23) SIGURG      24) SIGXCPU     25) SIGXFSZ
    26) SIGVTALRM   27) SIGPROF     28) SIGWINCH    29) SIGIO       30) SIGPWR
    31) SIGSYS      34) SIGRTMIN    35) SIGRTMIN+1  36) SIGRTMIN+2  37) SIGRTMIN+3
    38) SIGRTMIN+4  39) SIGRTMIN+5  40) SIGRTMIN+6  41) SIGRTMIN+7  42) SIGRTMIN+8
    43) SIGRTMIN+9  44) SIGRTMIN+10 45) SIGRTMIN+11 46) SIGRTMIN+12 47) SIGRTMIN+13
    48) SIGRTMIN+14 49) SIGRTMIN+15 50) SIGRTMAX-14 51) SIGRTMAX-13 52) SIGRTMAX-12
    53) SIGRTMAX-11 54) SIGRTMAX-10 55) SIGRTMAX-9  56) SIGRTMAX-8  57) SIGRTMAX-7
    58) SIGRTMAX-6  59) SIGRTMAX-5  60) SIGRTMAX-4  61) SIGRTMAX-3  62) SIGRTMAX-2
    63) SIGRTMAX-1  64) SIGRTMAX




    trap [-lp] [[arg] sigspec ...]
              The command arg is to be read and executed when the shell receives signal(s) sigspec.  If arg is absent (and there is a single  sigspec)  or  -,
              each  specified signal is reset to its original disposition (the value it had upon entrance to the shell).  If arg is the null string the signal
              specified by each sigspec is ignored by the shell and by the commands it invokes.  If arg is not present and -p has been supplied, then the trap
              commands  associated  with  each  sigspec  are displayed.  If no arguments are supplied or if only -p is given, trap prints the list of commands
              associated with each signal.  The -l option causes the shell to print a list of signal names and their corresponding numbers.  Each  sigspec  is
              either a signal name defined in <signal.h>, or a signal number.  Signal names are case insensitive and the SIG prefix is optional.  If a sigspec
              is EXIT (0) the command arg is executed on exit from the shell.  If a sigspec is DEBUG, the command arg is executed before every simple command,
              for  command,  case  command, select command, every arithmetic for command, and before the first command executes in a shell function (see SHELL
              GRAMMAR above).  Refer to the description of the extdebug option to the shopt builtin for details of its effect on the DEBUG trap.  If a sigspec
              is  ERR, the command arg is executed whenever a simple command has a non-zero exit status, subject to the following conditions.  The ERR trap is
              not executed if the failed command is part of the command list immediately following a while or until keyword, part of the test in an if  state-
              ment,  part  of  a && or ││ list, or if the command’s return value is being inverted via !.  These are the same conditions obeyed by the errexit
              option.  If a sigspec is RETURN, the command arg is executed each time a shell function or a script executed with the . or source builtins  fin-
              ishes  executing.   Signals  ignored upon entry to the shell cannot be trapped, reset or listed.  Trapped signals that are not being ignored are
              reset to their original values in a child process when it is created.  The return status is false if any  sigspec  is  invalid;  otherwise  trap
              returns true.

trap 'command' signal
其中signal是要捕获的信号，command是捕获到指定的信号之后，所要执行的命令。可以用kill –l命令看到系统中全部可用的信号名，捕获信号后所执行的命令可以是任何一条或多条合法的shell语句，也可以是一个函数名。
shell脚本在执行时，会产生三个所谓的“伪信号”，(之所以称之为“伪信号”是因为这三个信号是由shell产生的，而其它的信号是由操作系统产生的)，通过使用trap命令捕获这三个“伪信号”并输出相关信息对调试非常有帮助。


信号名 何时产生
EXIT    从一个函数中退出或整个脚本执行完毕
ERR 当一条命令返回非零状态时(代表命令执行不成功)
DEBUG   脚本中每一条命令执行之前



通过捕获EXIT信号,我们可以在shell脚本中止执行或从函数中退出时，输出某些想要跟踪的变量的值，并由此来判断脚本的执行状态以及出错原因,其使用方法是：
trap 'command' EXIT　或　trap 'command' 0

