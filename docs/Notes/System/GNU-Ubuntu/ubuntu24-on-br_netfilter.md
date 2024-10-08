> Ubuntu24 开启 br_netfilter

`br_netfilter` 模块允许在 Linux 桥接网络上使用防火墙标记数据包，对于网络地址转换（NAT）和其他网络操作至关重要

**操作步骤**

检查模块是否已经加载：

```sh
$ lsmod | grep br_netfilter

# 如未加载，可手动加载模块
$ sudo modprobe br_netfilter
```

!!! info "注意事项"
    为了让模块在系统重启后自动加载，需要将它添加到系统的模块加载列表中

```sh
$ echo 'br_netfilter' | sudo tee -a /etc/modules
```

PS：重启系统或重新启动网络服务来确保模块被正确加载

另外需要确保 `net.bridge.bridge-nf-call-iptables` 内核参数被设置为 1，以便允许 iptables 规则被桥接过滤

```sh
$ sudo sysctl -w net.bridge.bridge-nf-call-iptables=1
```

永久生效则需将其添加到 `/etc/sysctl.conf` 文件中

```sh
$ echo 'net.bridge.bridge-nf-call-iptables=1' | sudo tee -a /etc/sysctl.conf
# 最后执行命令生效和检查
$ sudo sysctl -p
$ lsmod | grep br_netfilter
br_netfilter           32768  0
bridge                421888  1 br_netfilter
```



