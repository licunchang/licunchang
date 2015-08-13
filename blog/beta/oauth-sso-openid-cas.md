**File Name** oauth-sso-openid-cas.md  
**Description**  OAUTH SSO OpenID CAS    
**Author** LiCunchang (printf@live.com)  
**Version** 1.0.20140408   

------

## OpenID   

> http://openid.net/  
> OpenID Connect is an interoperable authentication protocol based on the OAuth 2.0 family of specifications. It uses straightforward REST/JSON message flows with a design goal of “making simple things simple and complicated things possible”. It’s uniquely easy for developers to integrate, compared to any preceding Identity protocol.
     
OpenID 系统的第一部分是身份验证，即如何通过 URI 来认证用户身份。目前的网站都是依靠用户名和密码来登录认证，这就意味着大家在每个网站都需要注册用户名和密码，即便你使用的是同样的密码。如果使用 OpenID （参见规范），你的网站地址（URI）就是你的用户名，而你的密码安全的存储在一个 OpenID 服务网站上（你可以自己建立一个 OpenID 服务网站，也可以选择一个可信任的 OpenID 服务网站来完成注册）。
     
问题描述:我在sina上面有一个用户名，sohu有一个,baidu有一个,google有一个。这些用户名和密码可以一样也可以不一样，要是不一样的话我还得记那么多的信息，头痛!而即使我让这些用户名和密码都一样，那么要是有一天我把密码给忘掉了，我需要通过找回功能把这些信息找回来。那么只有老老实实的一个一个网站来，头更痛。
     
而登录一个支持 OpenID 的网站非常简单（即便你是第一次访问这个网站也是一样）。只需要输入你注册好的 OpenID 用户名，然后你登录的网站会跳转到你的 OpenID 服务网站，在你的 OpenID 服务网站输入密码（或者其它需要填写的信息）验证通过后，你会回到登录的网站并且已经成功登录。 OpenID 系统可以应用于所有需要身份验证的地方，既可以应用于单点登录系统，也可以用于共享敏感数据时的身份认证。”

## OAUTH

> http://oauth.net/    
> An open protocol to allow secure authorization in a simple and standard method from web, mobile and desktop applications.

典型案例：如果一个用户R拥有两项服务：一项服务是图片在线存储服务A，另一个是图片在线打印服务B。由于服务A与服务B是由两家不同的服务提供商提供的，所以用户在这两家服务提供商的网站上各自注册了两个用户，假设这两个用户名各不相同，密码也各不相同。当用户要使用服务B打印存储在服务A上的图片时，用户该如何处理？法一：用户可能先将待打印的图片从服务A上下载下来并上传到服务B上打印，这种方式安全但处理比较繁琐，效率低下；法二：用户将在服务A上注册的用户名与密码提供给服务B，服务B使用用户的帐号再去服务A处下载待打印的图片，这种方式效率是提高了，但是安全性大大降低了，服务B可以使用用户的用户名与密码去服务A上查看甚至篡改用户的资源。
      
OAUTH 是一种开放的协议，为桌面程序或者基于BS的web应用提供了一种简单的，标准的方式去访问需要用户授权的API服务。OAUTH类似于Flickr Auth、Google's AuthSub、Yahoo's BBAuth、 Facebook Auth等。OAUTH认证授权具有以下特点：

   1. 简单：不管是OAUTH服务提供者还是应用开发者，都很容易于理解与使用；
   2. 安全：没有涉及到用户密钥等信息，更安全更灵活； 
   3. 开放 任何服务提供商都可以实现OAUTH，任何软件开发商都可以使用OAUTH；

用白话文来说就是：“A提供了基于OAUTH协议的服务，现在B想要访问用户R放在A上面的资源，B需要向A申请，而A需要询问用户R是否同意B访问这个资源，这个时候A是需要R通过用户名和密码登录的（这个用户名只是用户R在A上注册的，跟B没有一点关系）,如果用户R同意了，那么以后B就可以访问这个资源了。整个过程R都没有向B透露一点相关的用户信息。”

## CAS

> http://www.jasig.org/cas  
> Central Authentication Service (CAS)  

CAS is an HTTP-based protocol that requires each of its components to be accessible through specific URIs. This section will discuss each of the URIs.





## SSO

SSO英文全称Single Sign On，单点登录。SSO是在多个应用系统中，用户只需要登录一次就可以访问所有相互信任的应用系统。它包括可以将这次主要的登录映射到其他应用中用于同一个用户的登录的机制。它是目前比较流行的企业业务整合的解决方案之一。

比如说某网站D，它下面有许多独立的模块，有的是视屏频道，有的是体育频道等。每个频道都有用户验证和登录这块。现在问题来了，我在频道A登录了，可以享有会员待遇，那么当我跳到频道B的时候，由于是单独的模块，我还是需要登录。这个太恶心了。那我不干了，以后不上这个网站了。

那怎么才能让用户在频道A登录以后，以后去任何一个频道都不需要再次登录呢？而sso就是为了解决这个问题而产生的。


## Appendix A: References

