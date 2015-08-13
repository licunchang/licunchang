**File Name** linux-etc-security-limits-conf.md

**Description** /etc/security/limits.conf 介绍  
**Author** LiCunchang(printf@live.com)  
**Version** 1.0.20130527  

------




centos 6

cat /etc/security/limits.conf

*     soft    nproc   65536
*     hard    nproc   65536
*     soft    nofile  65536
*     hard    nofile  65536

cat /etc/security/limits.d/90-nproc.conf





Each line describes a limit for a user in the form:
    <domain>        <type>  <item>  <value>

    #Where:
    #<domain> can be:
    #        - an user name
    #        - a group name, with @group syntax
    #        - the wildcard *, for default entry
    #        - the wildcard %, can be also used with %group syntax,
    #                 for maxlogin limit
    #
    #<type> can have the two values:
    #        - "soft" for enforcing the soft limits
    #        - "hard" for enforcing hard limits
    #
    #<item> can be one of the following:
    #        - core - limits the core file size (KB)
    #        - data - max data size (KB)
    #        - fsize - maximum filesize (KB)
    #        - memlock - max locked-in-memory address space (KB)
    #        - nofile - max number of open files
    #        - rss - max resident set size (KB)
    #        - stack - max stack size (KB)
    #        - cpu - max CPU time (MIN)
    #        - nproc - max number of processes
    #        - as - address space limit (KB)
    #        - maxlogins - max number of logins for this user
    #        - maxsyslogins - max number of logins on the system
    #        - priority - the priority to run user process with
    #        - locks - max number of file locks the user can hold
    #        - sigpending - max number of pending signals
    #        - msgqueue - max memory used by POSIX message queues (bytes)
    #        - nice - max nice priority allowed to raise to values: [-20, 19]
    #        - rtprio - max realtime priority
    #
    #<domain>      <type>  <item>         <value>