**File Name** base64.md  

**Description** base64    
**Author** LiCunchang(printf@live.com)   
**Version** 3.0.20130728  

------


Base64 是一种基于 64 个可打印字符来表示二进制数据的表示方法。由于 2 的 6 次方等于64，所以每 6 个 bit 为一个单元，对应某个可打印字符。三个字节有 24 个 bit ，对应于 4 个 Base64 单元，即 3 个字节需要用 4 个可打印字符来表示。它可用来作为电子邮件的传输编码。在 Base64 中的可打印字符包括字母 A-Z、a-z、数字0-9 ，这样共有62个字符，此外两个可打印符号在不同的系统中而不同。一些如uuencode的其他编码方法，和之后binhex的版本使用不同的64字符集来代表6个二进制数字，但是它们不叫Base64。
Base64常用于在通常处理文本数据的场合，表示、传输、存储一些二进制数据。包括MIME的email，email via MIME, 在XML中存储复杂数据.










http://zh.wikipedia.org/wiki/Base64