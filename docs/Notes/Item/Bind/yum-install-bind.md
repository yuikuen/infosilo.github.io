> DNS(Domain Name Service) 域名解析服务，就是将域名和 ip 之间做相应的转换，以下为快速安装 bind9 实现内网 DNS 服务

## 一. 服务安装

- System：CentOS7.9.2009 Minimal
- Bind：bind-9.11.4-26.P2.el7_9.9.x86_64

1）开放服务协议或直接禁用安全配置

```bash
$ firewall-cmd --zone=public --add-port=53/tcp --permanent
$ firewall-cmd --zone=public --add-port=53/udp --permanent
$ firewall-cmd --reload

$ sed -i '/SELINUX/s/enforcing/disabled/' /etc/selinux/config && setenforce 0 
$ systemctl disable --now firewalld.service
```

2）下载依赖组件，并启动服务

```bash
$ yum -y install bind*
$ systemctl enable --now named.service

$ ps -eaf|grep named
named     1743     1  2 14:38 ?        00:00:00 /usr/sbin/named -u named -c /etc/named.conf
root      1751  1448  0 14:38 pts/0    00:00:00 grep --color=auto named

$ ss -nult|grep :53
udp    UNCONN     0      0      127.0.0.1:53                    *:*                  
udp    UNCONN     0      0         [::1]:53                 [::]:*                  
tcp    LISTEN     0      10     127.0.0.1:53                    *:*                  
tcp    LISTEN     0      10        [::1]:53                 [::]:* 
```

## 二. 配置解析

在配置Bind服务时，主要用到以下三个配置文件：

- 主配置文件（/etc/named.conf）：用来定义bind服务程序的运行
- 区域配置文件（/etc/named.rfc1912.zones）：用来保存域名和IP地址对应关系的所在位置。
  
  类似于图书的目录，对应着每个域和相应IP地址所在的具体位置，当需要查看或修改时，可根据这个位置找到相关文件

- 数据配置文件目录（/var/named）：该目录用来保存域名和IP地址真实对应关系的数据配置文件

1）修改主配置文件，允许所有客户端访问

```bash
$ sed -i -e 's/127.0.0.1/any/' -e 's/localhost/any/' /etc/named.conf

$ cat /etc/named.conf
options {
    # 监听所有IP
	listen-on port 53 { any; };
	listen-on-v6 port 53 { ::1; };
	directory 	"/var/named";
	dump-file 	"/var/named/data/cache_dump.db";
	statistics-file "/var/named/data/named_stats.txt";
	memstatistics-file "/var/named/data/named_mem_stats.txt";
	recursing-file  "/var/named/data/named.recursing";
	secroots-file   "/var/named/data/named.secroots";
    # 允许所有客户端访问区域数据库
	allow-query     { any; };

    recursion yes;

	dnssec-enable yes;
	dnssec-validation yes;
```

2）修改区域配置文件，添加正反向解析

```bash
$ cat /etc/named.rfc1912.zones

// 示例格式（正反一样）
zone "ZONE_NAME" IN {                  // 添加自定义域
    type {master|slave|hint|forward};  // 指定类型 hint(根区域),master(主区域),slave(辅助区域)
    file "ZONE_NAME.zone";             // 指定区域数据库文件名
    allow-update { none; };
};

// 正向解析
zone "yuikuen.top" IN {
    type master;
    file "yuikuen.top.zone";
	allow-update { none; };
};

// 反向解析
zone "4.188.188.in-addr.arpa" IN {
	type master;
	file "188.188.4.arpa";
	allow-update { none; };
};
```

3）数据配置文件

```bash
$ cd /var/named
$ cp -p named.localhost yuikuen.top.zone
# 正向解析，与区域文件名要一致
$ cat yuikuen.top.zone 
$TTL 1D
@	IN SOA	@ rname.invalid. (
					0	    ; serial    // 更新序列号
					1D	    ; refresh   // 更新时间
					1H	    ; retry     // 重试时间
					1W	    ; expire    // 失效时间
					3H )	; minimum   // 无效解决记录的缓存时间
	NS	@
	A	127.0.0.1
	AAAA	::1
ldap    IN      A       188.188.4.111
gitlab  IN   	A	    188.188.4.112
```

```bash
$ cp -p named.loopback 188.188.4.arpa
# 反向解析，与区域文件名要一致
$ cat 188.188.4.arpa
$TTL 1D
@	IN SOA	@ rname.invalid. (
					0       ; serial
					1D      ; refresh
					1H	    ; retry
					1W	    ; expire
					3H )	; minimum
	NS	@
	A	127.0.0.1
	AAAA	::1
	PTR	localhost.
111     IN      PTR     ldap.yuikuen.top.
112 	IN	    PTR	    gitlab.yuikuen.top.
```

## 三. 启动验证

```bash
$ chown named.named yuikuen.top.zone 188.188.4.arpa
# 验证配置文件格式
$ named-checkconf /etc/named.conf
$ named-checkzone yuikuen.top /var/named/yuikuen.top.zone
zone yuikuen.top/IN: loaded serial 0
OK
$ named-checkzone 188.188.4.arpa /var/named/188.188.4.arpa
zone 188.188.4.arpa/IN: loaded serial 0
OK

# 刷新配置，重启服务
$ rndc reload
$ systemctl restart named
$ systemctl enable named
```

**Win-Pc 修改 dns 后进行 ping 或 nslookup 测试**

```c
C:\Users\ztnb0>ping gitlab.yuikuen.top

正在 Ping gitlab.yuikuen.top [188.188.4.112] 具有 32 字节的数据:
来自 188.188.4.112 的回复: 字节=32 时间=29ms TTL=62
来自 188.188.4.112 的回复: 字节=32 时间=43ms TTL=62
来自 188.188.4.112 的回复: 字节=32 时间=45ms TTL=62
来自 188.188.4.112 的回复: 字节=32 时间=5ms TTL=62

188.188.4.112 的 Ping 统计信息:
    数据包: 已发送 = 4，已接收 = 4，丢失 = 0 (0% 丢失)，
往返行程的估计时间(以毫秒为单位):
    最短 = 5ms，最长 = 45ms，平均 = 30ms

C:\Users\ztnb0>nslookup 188.188.4.112
服务器:  UnKnown
Address:  188.188.4.110

名称:    gitlab.yuikuen.top
Address:  188.188.4.112
```
