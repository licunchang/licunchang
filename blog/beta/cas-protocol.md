**File Name** cas-protocol.md
**Description**  CAS 协议
**Author** LiCunchang (printf@live.com)
**Version** 1.0.20140408

------

## 1 Introduction

This is the official specification of the CAS 1.0 and 2.0 protocols. It is subject to change.

### 1.1 Conventions & Definitions

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119[1].

* "Client" refers to the end user and/or the web browser.
* "Server" refers to the Central Authentication Service server.
* "Service" refers to the application the client is trying to access.
* "Back-end service" refers to the application a service is trying to access on behalf of a client. This can also be referred to as the "target service."
* <LF\> is a bare line feed (ASCII value 0x0a).

## 2 CAS URIs

CAS 是一个基于 HTTP 的协议，所以这就要求CAS的每一个组件都能通过特定的 URL 进行访问，本章节讨论这些特定的 URL。

### 2.1 /login as credential requestor

URL `/login` 扮演两种角色：作为一个凭证索取者，并且作为一个凭证接收者。它作为一个凭证接收者响应凭证，否则，在其他情况下它作为一个凭证索取者。

如果客户端已经和 CAS 建立了一个单点登录会话，



## Appendix A: References





