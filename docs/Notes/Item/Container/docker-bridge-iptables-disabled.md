> 解决 Docker 安装后报错 WARNING: bridge-nf-call-iptables is disabled（Firewall Enabled）

**实验场景**：Rocky Linux release 9.4 (Blue Onyx) + Docker + Firewall Enabled

## 一. 问题分析

此警告信息表明 Docker 需要依赖内核的网络过滤器（bridge-nf-call-iptables）来进行网络地址转换（NAT），但该功能当前被禁用，导致容器网络不正常，如无法访问外部网络。

```sh
# 检查相关服务状态信息
$ systemctl status docker
level=warning msg="WARNING: bridge-nf-call-iptables is disabled"
level=warning msg="WARNING: bridge-nf-call-ip6tables is disabled"

$ docker info
WARNING: bridge-nf-call-iptables is disabled
WARNING: bridge-nf-call-ip6tables is disabled

# 查看转发模块配置，为空
$ lsmod | grep br_netfilter
```

## 二. 解决方法

### 2.1 加载模块

由于将 Linux 系统作为路由则必须要开启 IP 转发功能，不开启就会导致 Docker 应用无法访问

```sh
# 手动加载模块测试是否生成（该方式重启后失效）
$ modprobe br_netfilter
$ lsmod | grep br_netfilter
br_netfilter           36864  0
bridge                409600  1 br_netfilter
```

新增开机自加载 br_netfilter 模块（永久生效）

> 此处需要注意！RockyLinux 路径不一样，非 CentOS 的 `/etc/sysconfig/modules/*.modules`

```sh
$ cat > /etc/modules-load.d/br_netfilter.conf << EOF
br_netfilter
EOF

$ chmod 755 /etc/modules-load.d/br_netfilter.conf
```

### 2.2 开启转发

```sh
$ cat > /etc/sysctl.d/docker.conf <<EOF
net.bridge.bridge-nf-call-ip6tables=1
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-arptables=1
net.ipv4.ip_forward=1
EOF
```

```sh
$ sysctl -p /etc/sysctl.d/docker.conf
# 执行可能会报提示，可忽略；或先执行 modprobe br_netfilter 临时生效再执行 sysctl -p
# sysctl: cannot stat /proc/sys/net/bridge/bridge-nf-call-iptables: No such file or directory
```

### 2.3 检查验证

最后检查相关状态服务，重启验证是否开机自生效

```sh
$ lsmod | grep br_netfilter
br_netfilter           36864  0
bridge                409600  1 br_netfilter

$ sysctl net.bridge.bridge-nf-call-iptables
net.bridge.bridge-nf-call-iptables = 1

$ docker info; systemctl status docker（systemctl daemon-reload;systemctl restart docker）
```
最后 WARNING 错误提示已无；
