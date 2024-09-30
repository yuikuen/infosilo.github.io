**实验场景**：因项目需求，需要配置一台 Nginx 反向代理服务器，为运行在不同网段的机器提供代理转发服务。因此，此台 Nginx 服务器需要配置双网卡，以访问不同网段的机器

虽然配置了 33 和 34 的双网卡，但是服务器无法自动选择哪个网关与不同网段进行通信。假设服务器默认网关为 33 网段，虽然配置了双网卡，当服务器 ping 34 网段时，也默认走 33 网段的网关。因此，需要设置静态路由，指定服务器访问 33 网段时走 34 网关

首先查看网卡信息及查看现路由表信息

```sh
$ ip a
2: ens33: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
  link/ether 00:0c:29:d3:6c:ea brd ff:ff:ff:ff:ff:ff
  inet 192.168.37.128/24 brd 192.168.37.255 scope global noprefixroute ens33
     valid_lft forever preferred_lft forever
  inet 192.168.37.130/24 brd 192.168.37.255 scope global secondary dynamic ens33
     valid_lft 1233sec preferred_lft 1233sec
  inet6 fe80::20c:29ff:fed3:6cea/64 scope link 
     valid_lft forever preferred_lft forever
3: ens34: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
  link/ether 00:0c:29:d3:6c:f4 brd ff:ff:ff:ff:ff:ff
  inet 192.168.37.129/24 brd 192.168.37.255 scope global noprefixroute ens34
     valid_lft forever preferred_lft forever
  inet 192.168.206.138/24 brd 192.168.206.255 scope global dynamic ens34
     valid_lft 1336sec preferred_lft 1336sec
  inet6 fe80::20c:29ff:fed3:6cf4/64 scope link 
     valid_lft forever preferred_lft forever
...

$ route -n
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         192.168.37.254  0.0.0.0         UG    0      0        0 ens33
0.0.0.0         192.168.206.254 0.0.0.0         UG    101    0        0 ens34
192.168.37.0    0.0.0.0         255.255.255.0   U     100    0        0 ens33
192.168.206.0   0.0.0.0         255.255.255.0   U     0      0        0 ens34
```
Flags：总共有多个旗标，代表的意义如下：
- U (route is up)：该路由是有效的；
- H (target is a host)：目标是一部主机 (IP) 而非网域；
- G (use gateway)：需要透过外部的主机 (gateway) 来转递封包（一般指向默认网关）

添加静态路由有多种方法。其中编辑 `/etc/sysconfig/network-script/` 里的文件，实行路由表的永久添加。
通过查看路由表 `route -n` 或者 `ip addr` 查看地址，得知网卡名称为 ens33 和 ens34，则可通过编写 route-ens33 文件，实现路由的永久添加。

```sh
$ cd /etc/sysconfig/network-scripts/
$ vim route-ens33
192.168.20.0/24 via 192.168.37.254 dev ens33
192.168.37.0/24 via 192.168.37.254 dev ens33
```

重启网络查看路由表是否更新

```sh
$ systemctl restart network && route
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
default         gateway         0.0.0.0         UG    0      0        0 ens33
default         gateway         0.0.0.0         UG    0      0        0 ens34
192.168.20.0    192.168.37.254  255.255.255.0   UG    0      0        0 ens33
192.168.37.0    192.168.37.254  255.255.255.0   UG    0      0        0 ens33
```

发现显示的默认网关同时走 ens33 和 ens34,接下来需要配置 ens33 的网卡,把之前配置的 ens33 网卡的网关禁用

```sh
$ vim /etc/sysconfig/network-scripts/ifcfg-ens33
TYPE=Ethernet
BOOTPROTO=none
NAME=ens33
DEVICE=ens33
ONBOOT=yes
IPADDR=192.168.37.128
NETMASK=255.255.255.0
#GATEWAY=192.168.37.254
DNS=8.8.8.8
```

重启网卡再次检查

```sh
$ systemctl restart network && route
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
default         gateway         0.0.0.0         UG    0      0        0 ens34
192.168.20.0    192.168.37.254  255.255.255.0   UG    0      0        0 ens33
192.168.37.0    192.168.37.254  255.255.255.0   UG    0      0        0 ens33
```
