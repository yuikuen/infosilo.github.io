> 主从服务器好处是起到备份解析记录与负载均衡的作用，通过部署从服务器可减轻主服务器的负载压力，提升用户的查询效率

- 准备两台服务器，IP：188.188.4.44(主)、IP：188.188.4.201(从)
- 前置环境及安装部署一致，详细可参考 CentOS7安装Bind DNS服务

1）主配置文件(从)

```bash
$ vim 
options {
    listen-on port 53 { any;};         #监听本地所有的IP
    allow-query       { any;};         #所有的客户端都可以查询区域数据库，实现解析 
}
```

2）区域配置文件(主)

首先在主服务器的区域配置文件中允许该从服务器的更新请求，即修改allow-update {允许更新区域信息的主机地址;};参数，然后重启主服务器的 DNS 服务程序。主服务器确保区域数据文件中为每个从服务器配置 NS 记录。

```bash
$ vim /etc/named.rfc1912.zones
// 增加正反向-从服务器配置
zone "yuikuen.top" IN {
    type master;
    file "yuikuen.top.zone";
    allow-update { 188.188.4.201; };
};

zone "4.188.188.in-addr.arpa" IN {
    type master;
    file "188.188.4.arpa";
    allow-update { 188.188.4.201; };
};

// 刷新配置文件并重启服务
$ rndc reload
$ systemctl restart named
```

3）数据配置文件(从)，从服务器无需写解析数据文件，直接从主服务器同步数据文件；

<font color=red>注意：区域数据库文件 yuikuen.top.zone 在 centos6 是明文，而在 centos7 是密文</font>

```bash
// 从主服务器同步解析数据到从服务器上
$ rndc reload
server reload successful
$ systemctl restart named

$ cat /etc/named.rfc1912.zones | tail -n 11
zone "yuikuen.top" IN {
        type slave;
        file "slaves/yuikuen.top.zone";
        masters { 188.188.4.44; };
};

zone "4.188.188.in-addr.arpa" IN {
        type slave;
        file "slaves/188.188.4.arpa";
        masters { 188.188.4.44; };
};

$ ls /var/named/slaves
188.188.4.arpa  yuikuen.top.zone
```

4）为了展示效果，使用 win 客户端添加两个 dns 地址，模拟主服务器关机，dns 服务是否失效；

**参考链接**

- [Linux环境下搭建主从DNS服务器](https://mp.weixin.qq.com/s/CL0evzegiAUKL-rvEc2xQg)
- [Linux部署DNS服务器](https://mp.weixin.qq.com/s/5y1mp6xnUfn1OHqjAEm-rQ)