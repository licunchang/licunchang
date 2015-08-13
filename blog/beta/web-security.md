**File Name** web-security.md  

**Description** WEB 安全防护    
**Author** LiCunchang(printf@live.com)   
**Version** 1.0.20130924  

------

去参加面试，谈及web安全防护，竟然一时讲不出太多，回来之后整理一下。

验证！必须要验证，不管在什么情况下，变量在改变语境的情况下，都要针对变量所处的新语境进行转义，确保变量的角色不会发生变化，这里验证的不止是用户的输入。

## sql injection

参数类型为数字，

## XSS

## CSRF

## slowloris

把这个列了出来，这个跟上面的不太相同了，这个属于，刚知道这个问题的时候还欣喜若狂的download了一个脚本，然后跃跃欲试想把自己的测试环境搞掉，不过测试一番之后发现，Nginx的并发能力真的是令人叹服，至于 Apache，没试过。