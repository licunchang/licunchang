**File Name** php-login-system.md    

**Description** PHP 登录系统安全问题  
**Author** LiCunchang(printf@live.com)  
**Version** 1.0.20131102  

------

PART I: How To Log In

1. 一般来说，验证码通常是最后的解决方法。验证码很让人讨厌，有时候人们也很难识别。大多数验证码对机器人是没有效果的，并且所有的验证码在第三世界低廉的劳动力面前都显得很渺小。并且有些验证码的实现存在歧视不健全人的违法风险。如果你真的要使用验证码，那么推荐使用 reCAPTCHA，因为这些验证码已经证实是被识别软件识别错误的图形。

2. 尽量阻止浏览器在 form 或者 input 中使用 autocomplete 功能来存储和取回密码。因为在现实世界中，你的客户可能在不同的系统中有很多的账户，妥协于便利性，他们在这些不同的账户中使用了同一个密码，你不能寄希望于他们记住那么多的不同的帐号和密码。虽然有很多优秀的密码管理软件，但是一旦这些密码管理软件被攻破……

3. 目前最有效的方式的阻止在登录过程中出现的数据窃听、抓包的方式就是使用一种基于证书的加密手段（比如 ssl）。其他任何方法都能轻易被破解，

4. 在向客户端发送经过认证的 token 之后，


PART II: How To Remain Logged In - The Infamous "Remember Me" Checkbox



## 1 怎样登录

### 1.1 POST or GET

其实，POST 和 GET 在安全性上半斤八两，虽然 POST 不会将信息暴露在 URL 中，但是其实在公网的客户端和服务器之间进行传送的时候，信息一样是暴露的，为了保证信息是安全的，使用 SSL 是必须的，

1. 验证码通常是这个环节中最后一道需要考虑的措施。通常来说，验证码是让人讨厌的，反人类的，因为验证码的产生也是基于辨识机器和人类，




不要在数据库中存放任何token，而是存放他们的hash值，因为一旦数据库被盗窃，用户的token将成为问题。

永远不要使用安全问题的方式，


http://stackoverflow.com/questions/198462/is-either-get-or-post-more-secure-than-the-other/1744404#1744404