## 查看backlog

	[root@localhost web]# ss -ln
	Recv-Q Send-Q             Local Address:Port               Peer Address:Port
	0      128                    127.0.0.1:9000                          *:*
	0      128                           :::3306                         :::*
	0      128                            *:80                            *:*
	0      128                           :::22                           :::*
	0      128                            *:22                            *:*
	0      100                          ::1:25                           :::*
	0      100                    127.0.0.1:25                            *:*

Send-Q 字段就是

## 异步加载js

为防止JavaScript阻止网页加载，建议您在加载JavaScript时使用HTML异步属性。例如：

    <script async src="my.js">

