
## 1 负载均衡技术

### 1.1 DNS

实现负载均衡最简单的方法就是为一系列的用户提供一系列服务器。这种方法在内网(Intranet)上比较容易实现，但是在互联网(internet)上就不太合适。常用的方式便是 DNS 轮询(DNS roundrobin)，如果一个 DNS 服务器上对应一个域名有多条记录，那么它将以轮询顺序返回。通过这种方式，对于一个域名不同的用户将看到不同的地址从而连接到不同的服务器上。这通常用在多站点的负载均衡上，但是这种方式需要应用对上下文环境无关联性。所以，这种方式通常用在搜索引擎、POP 服务器、或者分发静态内容的网站上。这种方法单独使用不能保证高可用性，需要格外的手段去检测服务器状态，将错误的服务器替换掉。因为这些原因，DNS 轮询通常是作为一种补充方案，而不能作为主要方案。

    $ host -t a google.com
    google.com has address 74.125.128.100
    google.com has address 74.125.128.101
    google.com has address 74.125.128.102
    google.com has address 74.125.128.113
    google.com has address 74.125.128.138
    google.com has address 74.125.128.139

### 1.2 Reducing the number of users per server

一种更通用的方式是将用户的访问分散到多个服务器上。这种方式需要在用户和服务器之间放置负载均衡器，它可以是一台硬件，也可以用安装在前端服务器或者直接就是安装在应用服务器上的软件来实现。因为多部署了一台负载均衡器，所以整个系统出现错误的几率也就增加了，通常的做法是我们需要为主负载均衡器添加一台备机。

一般来说，一台硬件负载均衡器工作在网络层(四层负载均衡)(原文:a hardware load balancer will work at the network packets level)，通常扮演着路由器的角色，使用下面的方法进行负载均衡：

* 直接路由(Direct routing)

    负载均衡器将同一个服务地址路由到在同一个网段且和负载均衡器拥有同一服务地址的本地物理服务器。好处就是不用修改服务地址，后端服务器直接将响应返回给用户而不通过负载均衡器，所以这种方式处理能力很强，经常用在高流量的网站的前端服务器当中，另一方面，需要掌握tcp/IP的相关知识，才能正确配置各种设备和服务器。

* 隧道(Tunnelling)

    工作方式很像是直接路由方式，但是后端服务器和负载均衡器之间可以建立隧道，所以后端服务器可以位于远程网络上，服务器可以直接回复。

* IP地址转换(IP address translation:NAT)

    用户连接到一个虚拟的目标地址，负载均衡器将这个虚拟的地址转换成后端服务器的地址。乍一看这种方案比较容易部署，因为后端服务器配置不用太麻烦。但是需要很严格的要求，一个常见的错误就是应用服务器在某些响应中暴露自己的内部地址。同样的，这种方式需要负载均衡器处理更多的工作，不断的转换前后端地址，维护一个会话表，而且所有的网络流量都需要通过负载均衡器。有时候负载均衡器的会话超时时间设置的过短会导致一些副作用，比如 ACK storm，在这种情况下，唯一的解决方案就是增大会话超时时间，但这很容易使得负载均衡器的会话表维护超负荷。

负载均衡器我们也可以用软件的方式实现，它们更多的扮演着一个反向代理服务器的角色(七层负载均衡)，在前端对外伪装成服务器，然后将网络流量转发。这种情况下用户不能直接从外部访问到提供服务的服务器，并且有些协议可能得不到负载均衡。软件实现的负载均衡器需要比硬件负载均衡器更强的处理能力，但是因为他们连接了用户与服务器之间的通讯，通过只转发其所能理解的请求来提供第一层的安全保护，这是为什么我们经常在这些产品上发现URL过滤的功能。

### 1.2.1 Testing the servers

负载均衡器必须要知道后端服务器有哪些是处于可用状态，所以，负载均衡器要周期性的发送一些请求来确定服务器的状态，这些测试叫做健康检查(health checks)。一个崩溃的服务器可能会相应ping请求，但是不能相应TCP连接。一台挂起的服务器可能会相应tcp连接，但是不能响应http请求。当一个多层的web应用服务器被牵扯进来的时候，虽然有些http请求不能响应，但是可能还有其他一些http请求能够响应，所以我们真正感兴趣的是在应用和负载均衡器允许下怎样选择最具代表性的测试。有些测试需要从数据库中获取数据来验证所有环节都是有效的。缺点是这些测试会消耗掉一定的服务器资源（CPU、线程等）。 它们需要间隔足够的时间防止服务器的负载过重，但又要保证能快速检测出死掉的服务器。健康检查是负载均衡中最复杂的部分，在进行一系列测试后，通常最后应用开发人员完成一个专门用于负载均衡器的特定需求，来执行有代表性内部的测试。对于这个问题，软件负载均衡器是最具灵活性的，因为大多数情况下它们都会提供脚本处理的能力，当某个检查需要修改该代码，在短时间内软件的编辑者就可以完成。


### 1.2.2 Selecting the best server

负载均衡器有许多方式来选择最佳服务器来分担压力。一个最常见的误解就是把请求分配给最先响应的服务器，这种做法自然是错误的，因为如果一台服务器有某些方面的原因导致总是响应最快，那么就获得大多数的请求分配从而导致不平衡。另一个常见的就是把请求分配给最少压力的服务器，虽然这种做法在会话期很长的环境中是很管用的，但是这种方式在web应用中就不太好使，因为

为了平衡服务器之间的压力，轮询(roundrobin)通常是最好的方法，轮流分配给每一台服务器，

## 2 Persistence

## 2.1 Cookie learning



## 2.2 Cookie insertion


## 2.3 Persistence limitations - SSL


























http://1wt.eu/articles/2006_lb/
http://virtualadc.blog.51cto.com/3027116/580832
http://virtualadc.blog.51cto.com/3027116/591396

