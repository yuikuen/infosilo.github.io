> Ubuntu24 安装后基本优化配置

### 1.1 修改 IP

```sh
$ cat /etc/netplan/50-cloud-init.yaml
# This file is generated from information provided by the datasource.  Changes
# to it will not persist across an instance reboot.  To disable cloud-init's
# network configuration capabilities, write a file
# /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg with the following:
# network: {config: disabled}
network:
    ethernets:
        enp6s18:
            addresses:
            - 188.188.4.110/24
            nameservers:
                addresses:
                - 223.5.5.5
                search: []
            routes:
            -   to: default
                via: 188.188.4.1
    version: 2
$ netplan apply
$ systemctl restart systemd-networkd
```

### 1.2 时间同步

```sh
# 查看配置
$ systemd-analyze cat-config systemd/timesyncd.conf

# 修改 24h 制
$ echo 'LC_TIME=en_DK.UTF-8' >> /etc/default/locale

# 配置同步
$ vim /etc/systemd/timesyncd.conf
[Time]
NTP=ntp1.aliyun.com
FallbackNTP=ntp.ubuntu.com
RootDistanceMaxSec=5
PollIntervalMinSec=32
PollIntervalMaxSec=2048
ConnectionRetrySec=30
SaveIntervalSec=60

$ timedatectl set-ntp true
$ timedatectl set-timezone Asia/Shanghai
$ timedatectl status
$ systemctl start systemd-timedated.service
```

### 1.3 常用软件

```sh
$ apt update
$ apt -y install bash-completion vim wget lvm2 unzip net-tools dnsutils sysstat rsync inetutils-ping parted
```

### 1.4 文件打开数

```sh
$ cat >> /etc/security/limits.conf <<EOF
* soft noproc 65535
* hard noproc 65535

* soft nofile 65535
* hard nofile 65535
EOF

$ echo 'ulimit -SHn 65535' >> /etc/profile
$ ulimit -n 65535
$ ulimit -u 65536
$ ulimit -a
```

### 1.5 内核优化

```sh
$ cat>>/etc/sysctl.conf<<EOF
# 缓存优化
vm.swappiness=0

# tcp 优化
net.ipv4.tcp_max_tw_buckets=5000
net.ipv4.tcp_max_syn_backlog=16384
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_tw_reuse=1
net.ipv4.tcp_fin_timeout=10

net.ipv4.tcp_keepalive_time=600
net.ipv4.tcp_keepalive_intvl=30
net.ipv4.tcp_keepalive_probes=3

net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
net.ipv6.conf.lo.disable_ipv6=1
net.ipv4.neigh.default.gc_stale_time=120
net.ipv4.conf.all.rp_filter=0 
net.ipv4.conf.default.rp_filter=0
net.ipv4.conf.default.arp_announce=2
net.ipv4.conf.lo.arp_announce=2
net.ipv4.conf.all.arp_announce=2
net.ipv4.ip_local_port_range=1024 65000

net.ipv4.ip_forward=1
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_synack_retries=2

net.bridge.bridge-nf-call-ip6tables=1
net.bridge.bridge-nf-call-iptables=1
net.netfilter.nf_conntrack_max=2310720
net.ipv6.neigh.default.gc_thresh1=8192
net.ipv6.neigh.default.gc_thresh2=32768
net.ipv6.neigh.default.gc_thresh3=65536
net.core.netdev_max_backlog=16384
net.core.rmem_max=16777216 
net.core.wmem_max=16777216

net.core.somaxconn = 32768 
fs.inotify.max_user_instances=8192 
fs.inotify.max_user_watches=524288 
fs.file-max=52706963
fs.nr_open=52706963
kernel.pid_max = 4194303
net.bridge.bridge-nf-call-arptables=1

vm.overcommit_memory=1 
vm.panic_on_oom=0 
vm.max_map_count=262144
EOF

$ sysctl -p
```