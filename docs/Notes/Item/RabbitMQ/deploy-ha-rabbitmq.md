> CentOS7 部署高可用 RabbitMQ

## 一. 安装说明

> 一般单节点负载过高会导致服务响应过慢，使用集群方式则能够避免这种情况，通过 HAProxy 实现负载均衡，再使用 Keepalived 服务实现虚拟 VIP-IP 异常漂移，任一节点服务宕机均不会影响服务的正常运行

RabbitMQ 集群可使得 RabbitMQ 节点宕机时，消费者和生产者都可以正常继续运行，并且可以承载更多的业务量，增加系统吞吐量；
客户端通过虚拟 IP 进行访问 HAProxy，再通过 Keepalived 将其发放到 Master 节点上的 HAProxy，若 Master 节点上的 HAProxy 宕机，则会发放到 Slave 节点上，之后访问到 RabbitMQ 集群

- 集群规划图如下所示：

![](https://img.17121203.xyz/i/2024/10/21/qp68sf-0.webp)

- 配置信息

| IP            | 主机名    | 服务                        |
| ------------- | --------- | --------------------------- |
| 188.188.4.210 | ssd-dev01 | RabbitMQ                    |
| 188.188.4.211 | ssd-dev02 | RabbitMQ+HAProxy+Keepalived |
| 188.188.4.212 | ssd-dev03 | RabbitMQ+HAProxy+Keepalived |

- 配置 IP 地址和主机之间的映射

```bash
# 所有节点提前配置hostname
$ hostnamectl set-hostname ssd-dev01 && bash
$ hostnamectl set-hostname ssd-dev02 && bash
$ hostnamectl set-hostname ssd-dev03 && bash

$ cat >> /etc/hosts << EOF
188.188.4.210 ssd-dev01
188.188.4.211 ssd-dev02
188.188.4.212 ssd-dev03
EOF
```

- 版本信息

> 安装方法很多，可自行选择，如使用 `yum -y install` 命令进行安装，本文选择源码安装的原因主要是方便管理，建议实际生产中尽量使用源码安装，方便后期运维管理

1. Linux 版本：CentOS Linux release 7.9.2009 (Core)
2. erlang 版本：Erlang-23.3.4.11
3. RabbitMQ 版本：RabbitMQ_Server-3.8.29
4. HAProxy 版本：Haproxy-2.5.5
5. Keepalived 版本：Keepalived-2.2.7

## 二. 安装 Erlang

> 安装前建议参考 [Erlang Github 官方说明](https://github.com/rabbitmq/erlang-rpm)，Readme 上有说明版本的兼容性问题

```bash
# 安装依赖
$ yum -y install socat

# 在此选用了rpm方式安装，因为二进制源码安装会报错，需要修改配置文件的环境变量
$ wget https://github.com/rabbitmq/erlang-rpm/releases/download/v23.3.4.11/erlang-23.3.4.11-1.el7.x86_64.rpm
$ rpm -i erlang-23.3.4.11-1.el7.x86_64.rpm
warning: erlang-23.3.4.11-1.el7.x86_64.rpm: Header V4 RSA/SHA256 Signature, key ID cc4bbe5b: NOKEY

$ erl -version
Erlang (SMP,ASYNC_THREADS,HIPE) (BEAM) emulator version 11.2.2.10
```

## 三. 安装 RabbitMQ

1）下载程序并配置环境变量

```bash
$ wget https://github.com/rabbitmq/rabbitmq-server/releases/download/v3.8.29/rabbitmq-server-generic-unix-3.8.29.tar.xz
$ tar -xvf rabbitmq-server-generic-unix-3.8.29.tar.xz -C /opt/
$ cd /opt && mv rabbitmq_server-3.8.29 rabbitmq

$ echo 'export PATH=/opt/rabbitmq/sbin:$PATH' >> /etc/profile
$ source /etc/profile
```

2）创建用户并修改权限

```bash
$ useradd rabbitmq
$ mkdir -p /opt/rabbitmq/var/lib/rabbitmq /opt/rabbitmq/var/log/rabbitmq
$ chown rabbitmq.rabbitmq -R /opt/rabbitmq
```

3）创建配置文件

```bash
# 添加浏览器管理插件，默认安装是没有管理页面
$ cat >> /opt/rabbitmq/etc/rabbitmq/enabled_plugins <<EOF
[rabbitmq_management].
EOF
```

```bash
# 注意$hostname自行修改节点实际hostname
$ cat >> /opt/rabbitmq/etc/rabbitmq/rabbitmq-env.conf <<EOF
RABBITMQ_NODENAME=rabbit@$hostname
RABBITMQ_NODE_IP_ADDRESS=0.0.0.0
RABBITMQ_NODE_PORT=5672
RABBITMQ_LOG_BASE=/opt/rabbitmq/var/log/rabbitmq
RABBITMQ_MNESIA_BASE=/opt/rabbitmq/var/lib/rabbitmq/mnesia
EOF
```

```bash
$ cat >> /opt/rabbitmq/etc/rabbitmq/rabbitmq.conf <<EOF
listeners.tcp.default = 5672
num_acceptors.tcp = 10

management.tcp.port = 15672
management.tcp.ip   = 0.0.0.0
management.http_log_dir = /opt/rabbitmq/var/log/rabbitmq/management_access
	
vm_memory_high_watermark.absolute = 512MiB
vm_memory_high_watermark_paging_ratio = 0.3

loopback_users.guest = true
EOF
```

4）配置开机自启动服务

```bash
$ cat >> /etc/systemd/system/rabbitmq-server.service <<EOF
[Unit]
Description=RabbitMQ broker
After=syslog.target network.target

[Service]
Type=notify
User=rabbitmq
Group=rabbitmq
UMask=0027
NotifyAccess=all
TimeoutStartSec=3600
LimitNOFILE=32768
Restart=on-failure
RestartSec=10
WorkingDirectory=/opt/rabbitmq/var/lib/rabbitmq
ExecStart=/opt/rabbitmq/sbin/rabbitmq-server
ExecStop=/opt/rabbitmq/sbin/rabbitmqctl shutdown
SuccessExitStatus=69

[Install]
WantedBy=multi-user.target
EOF
```

5）设置 Cookie 并启动

```bash
$ echo "rabbitmq-cluster-cookie" >> ~/.erlang.cookie
$ echo "rabbitmq-cluster-cookie" >> /home/rabbitmq/.erlang.cookie
$ chown rabbitmq.rabbitmq /home/rabbitmq/.erlang.cookie
$ chmod 600 ~/.erlang.cookie /home/rabbitmq/.erlang.cookie
$ systemctl daemon-reload && systemctl enable --now rabbitmq-server
$ systemctl status rabbitmq-server
```

6）添加 RabbitMQ 账密，并分配权限

```bash
# 检查用户列表
$ rabbitmqctl list_users
Listing users ...
user	tags
guest	[administrator]
rabbitmq_user	[]

# RabbitMQ 有默认用户密码，guest/guest该用户密码只能在本地登陆，若在浏览器中登陆，须创建新用户密码
$ rabbitmqctl add_user rabbitmq_user rabbitmq_pwd
Adding user "rabbitmq_user" ...
Done. Don't forget to grant the user permissions to some virtual hosts! See 'rabbitmqctl help set_permissions' to learn more.

# 为rabbitmq_user用户添加管理员角色
$ rabbitmqctl set_user_tags rabbitmq_user administrator 
Setting tags for user "rabbitmq_user" to [administrator] ...

# 设置rabbitmq_user用户权限，允许访问vhost及read/write
$ rabbitmqctl set_permissions -p / rabbitmq_user ".*" ".*" ".*"
Setting permissions for user "rabbitmq_user" in vhost "/" ...

# 检查权限列表
$ rabbitmqctl list_permissions -p /
Listing permissions for vhost "/" ...
user	configure	write	read
rabbitmq_user	.*	.*	.*
guest	.*	.*	.*
```

## 四. 配置集群

1）RabbitMQ 集群添加节点，分别在 ssd-dev02、ssd-dev03 上执行如下命令，将其加入集群中

```bash
# ssd-dev02操作
$ rabbitmqctl stop_app
$ rabbitmqctl join_cluster --ram rabbit@ssd-dev01
$ rabbitmqctl start_app

# ssd-dev03操作
$ rabbitmqctl stop_app
$ rabbitmqctl join_cluster --ram rabbit@ssd-dev01
$ rabbitmqctl start_app
```

2）验证集群是否配置成功

```bash
$ rabbitmqctl cluster_status
Cluster status of node rabbit@ssd-dev01 ...
Basics

Cluster name: rabbit@ssd-dev01

Disk Nodes

rabbit@ssd-dev01

RAM Nodes

rabbit@ssd-dev02
rabbit@ssd-dev03

Running Nodes

rabbit@ssd-dev01
rabbit@ssd-dev02
rabbit@ssd-dev03

Versions

rabbit@ssd-dev01: RabbitMQ 3.8.2 on Erlang 23.3.4.11
rabbit@ssd-dev02: RabbitMQ 3.8.2 on Erlang 23.3.4.11
rabbit@ssd-dev03: RabbitMQ 3.8.2 on Erlang 23.3.4.11
...(略)
```

或使用任一节点在浏览器上打开 IP:15672 管理页面，显示绿色表示成功

3）配置镜像队列，配置可[参考文档](https://www.rabbitmq.com/ha.html)，`policy` 策略的意思就是要设置 Exchanges 或者 queue 的数据需要如何复制、同步，可通过命令方式和管理页面方式实现。

```bash
# policy配置格式，命令行配置镜像队列，在任一节点上执行如下命令，示例如下
$ rabbitmqctl set_policy [-p ] [--priority ] [--apply-to ] 
$ rabbitmqctl set_policy ha-all "^" '{"ha-mode":"all"}'

# 同步virtual host为 "/"下名称前缀为 "mirroring"的交换机和队列，并且自动保存到两个节点上
$ rabbitmqctl set_policy -p / --priority 1 --apply-to all myPolicy "^mirroring" '{"ha-mode":"exactly","ha-params":3,"ha-sync-mode":"automatic"}'
```

## 五. 安装 Haproxy

- [Haproxy 官网下载地址](https://www.haproxy.org/#down)

1）解压编译安装

```bash
$ yum -y install glibc glibc-devel pcre pcre-devel openssl openssl-devel systemd-devel zlib-devel
$ wget https://www.haproxy.org/download/2.5/src/haproxy-2.5.5.tar.gz
$ tar -zxvf haproxy-2.5.5.tar.gz && cd haproxy-2.5.5
$ make ARCH=x86_64 \
  TARGET=linux-glibc \
  USE_PCRE=1 \
  USE_OPENSSL=1 \
  USE_ZLIB=1 \
  USE_SYSTEMD=1 \
  USE_CPU_AFFINITY=1 \
  PREFIX=/opt/haproxy
$ make install PREFIX=/opt/haproxy  
```

参数说明：

- ARCH=x86_64 表示使用 ARCH 指定框架，可选项
- TARGET=linux-glibc 通用 linux 内核
- USE_PCRE=1 PCRE 支持正则表达式，用于用户请求的 uri
- USE_OPENSSL=1 https，证书
- USE_ZLIB=1 开启压缩
- USE_SYSTEMD=1 使用 systemd 启动 haproxy 主进程
- PREFIX=/opt/haproxy 指定安装路径

2）设置环境变量

```bash
$ echo 'export PATH=/opt/haproxy/sbin:$PATH' >> /etc/profile
$ source /etc/profile
$ haproxy -v
HAProxy version 2.5.5-384c5c5 2022/03/14 - https://haproxy.org/
Status: stable branch - will stop receiving fixes around Q1 2023.
Known bugs: http://www.haproxy.org/bugs/bugs-2.5.5.html
Running on: Linux 5.4.188-1.el7.elrepo.x86_64 #1 SMP Mon Mar 28 09:10:07 EDT 2022 x86_64
```

3）创建配置文件，节点2 & 节点3 配置一样

```bash
$ mkdir -p /etc/haproxy
$ vim /etc/haproxy/haproxy.cfg
#---------------------------------------------------------------------
# Global settings
#---------------------------------------------------------------------
global
log 127.0.0.1 local0 info
pidfile /opt/haproxy/haproxy.pid          # haproxy的pid存放路径,启动进程的用户必须有权限访问此文件
maxconn 4000                              # 最大连接数，默认4000
daemon                                    # 创建1个进程进入deamon模式运行。此参数要求将运行模式设置为daemon
#---------------------------------------------------------------------
# defaults settings
#---------------------------------------------------------------------
# 注意：因为要使用tcp的负载，屏蔽掉与http相关的默认配置
defaults
mode http                                 # 默认的模式mode { tcp|http|health }，tcp是4层，http是7层，health只会返回OK
log global
option httplog                            # 采用http日志格式
option dontlognull                        # 启用该项，日志中将不会记录空连接。所谓空连接就是在上游的负载均衡器
option http-server-close                  # 每次请求完毕后主动关闭http通道
option forwardfor except 127.0.0.0/8      # 如果后端服务器需要获得客户端真实ip需要配置的参数，可以从Http Header中获得客户端ip
option redispatch                         # serverId对应的服务器挂掉后,强制定向到其他健康的服务器
retries 3                                 # 3次连接失败就认为服务不可用，也可以通过后面设置
timeout http-request 10s 
timeout queue 1m
timeout connect 10s                       # 连接超时时间
timeout client 1m                         # 客户端连接超时时间
timeout server 1m                         # 服务器端连接超时时间
timeout http-keep-alive 10s
timeout check 10s
maxconn 3000                              # 最大连接数
#--------------------------------------------------------
### haproxy 监控页面地址是：http://IP:1080/hastatus
listen admin_stats
    bind *:1080                           # 监听的地址和端口，默认端口1080
    mode http                             # 模式
    option tcplog
    stats refresh 5s                      # 页面自动刷新间隔,每隔5s刷新
    stats uri /hastatus                   # 访问路径，在域名后面添加/stats可以查看haproxy监控状态,默认为/haproxy?stats
    stats realm welcome login\ Haproxy    # 提示信息，空格之前加\
    stats auth admin:123456               # 登陆用户名和密码
    stats hide-version                    # 隐藏软件版本号
    stats admin if TRUE                   # 当通过认证才可管理
#-------------------------------------------------
frontend rabbitmq
    mode tcp
    bind *:5679
    timeout client 168h
    default_backend rabbitmq_nodes
    log global
    option tcplog
backend rabbitmq_nodes
    mode tcp
    balance roundrobin
    server ssd-dev01 188.188.4.210:5672 check inter 2000 rise 2 fall 3 weight 1  #节点一
    server ssd-dev02 188.188.4.211:5672 check inter 2000 rise 2 fall 3 weight 1  #节点二
    server ssd-dev03 188.188.4.212:5672 check inter 2000 rise 2 fall 3 weight 1  #节点三

#rabbitmq 集群配置
listen rabbitmq_admin
    bind  0.0.0.0:15679
    mode http
    balance roundrobin
    server ssd-dev01 188.188.4.210:15672 check inter 2000 rise 2 fall 3 weight 1  #节点一
    server ssd-dev02 188.188.4.211:15672 check inter 2000 rise 2 fall 3 weight 1  #节点二
    server ssd-dev03 188.188.4.212:15672 check inter 2000 rise 2 fall 3 weight 1  #节点三
```

开启日志记录：安装 Haproxy 之后，默认是没有开启日志记录的，需要根据 rsyslog 通过 udp 的方式获取 Haproxy 日志信息

```bash
$ vim /etc/rsyslog.conf
    # 打开以下两行注解，开启 514 USP监听
    $ModLoad imudp
    $UDPServerRun 514
    # 添加日志目录 (local0与haproxy.cfg中global log保持一致)
    local2.*   /var/log/haproxy/haproxy.log

$ vim /etc/sysconfig/rsyslog
    # 修改如下内容（若没有则添加）
    SYSLOGD_OPTIONS="-r -m 0 -c 2"
    
# 重启生效
$ systemctl restart rsyslog && systemctl status rsyslog
```

3）启动并查看状态，配置开机自启

```bash
$ haproxy -f /etc/haproxy/haproxy.cfg
Configuration file is valid
$ lsof -i:1080
COMMAND  PID USER   FD   TYPE DEVICE SIZE/OFF NODE NAME
haproxy 3296 root    4u  IPv4  26318      0t0  TCP *:socks (LISTEN)
```

```bash
$ cat >> /usr/lib/systemd/system/haproxy.service << EOF
[Unit]
Description=HAProxy Load Balancer
After=syslog.target network.target

[Service]
ExecStartPre=/opt/haproxy/sbin/haproxy -f /etc/haproxy/haproxy.cfg -c
ExecStart=/opt/haproxy/sbin/haproxy -Ws -f /etc/haproxy/haproxy.cfg -p /opt/haproxy/haproxy.pid
ExecReload=/bin/kill -USR2 \$MAINPID

[Install]
WantedBy=multi-user.target
EOF

$ systemctl enable --now haproxy && systemctl status haproxy
```

4）使用浏览器访问 IP:1080/hastatus，输入账密即可访问 Haproxy 监控界面

![](https://img.17121203.xyz/i/2024/10/21/qrdyok-0.webp)

## 六. 安装 Keepalived

- [Keepalived 官网下载地址](https://www.keepalived.org/download.html)

1）安装依赖并下载程序解压

```bash
$ yum install -y gcc openssl-devel popt-devel ipvsadm libnl3-devel net-snmp-devel libnl libnl-devel libnfnetlink-devel
$ wget https://www.keepalived.org/software/keepalived-2.2.7.tar.gz
$ tar -xf keepalived-2.2.7.tar.gz && cd keepalived-2.2.7
```

2）编译安装

```bash
$ ./configure --prefix=/opt/keepalived
$ make && make install
```

3）创建配置文件

```bash
$ mkdir -p /etc/keepalived
# keepalived默认读取的配置文件
$ cp /opt/keepalived/etc/keepalived/keepalived.conf.sample /etc/keepalived/keepalived.conf
# 配置启动服务
$ cp /usr/local/src/keepalived-2.2.7/keepalived/etc/init.d/keepalived /etc/init.d
$ cp /opt/keepalived/etc/sysconfig/keepalived /etc/sysconfig/
$ cp /opt/keepalived/sbin/keepalived /usr/sbin/
```

4）节点2 & 节点3 修改配置文件

```bash
# ssd-dev02
$ vim /etc/keepalived/keepalived.conf
! Configuration File for keepalived

global_defs {
   script_user root
   enable_script_security
   router_id node1
   vrrp_skip_check_adv_addr
#   vrrp_strict
   vrrp_garp_interval 0
   vrrp_gna_interval 0
}

vrrp_instance VI_1 {
    #keepalived角色，MASTER表示主节点 BACKUP从节点
    state MASTER
	#指定检测的网卡
    interface ens192
	#虚拟路由的id，主备节点设置相同
    virtual_router_id 240
	#优先级，主节点的优先级需要设置的比从节点高
    priority 100
	#设置主备之间的检查时间，单位s
    advert_int 1
	#定义验证类型和密码
    authentication {
        auth_type PASS
        auth_pass 1111
    }
	# 另一个节点的ip
	unicast_peer {
		188.188.4.212
	}
	#虚拟ip
    virtual_ipaddress {
        188.188.4.200
    }
}

virtual_server 188.188.4.200 1080 {
    virtual_server 
    delay_loop 6
    lb_algo rr
    lb_kind NAT
    persistence_timeout 50
    protocol TCP

    real_server 188.188.4.211 1080 {
        weight 1
	# 监控脚本
        notify_down /etc/keepalived/check.sh
		TCP_CHECK {
		  connect_timeout 10
		  retry 3
		  connect_port 1080
		}
    }
}
```

```bash
# ssd-dev03
$ vim /etc/keepalived/keepalived.conf
! Configuration File for keepalived

global_defs {
   script_user root
   enable_script_security
   router_id node2
   vrrp_skip_check_adv_addr
#   vrrp_strict
   vrrp_garp_interval 0
   vrrp_gna_interval 0
}

vrrp_instance VI_1 {
    #keepalived角色，MASTER表示主节点 BACKUP从节点
    state BACKUP
	#指定检测的网卡
    interface ens192
	#虚拟路由的id，主备节点设置相同
    virtual_router_id 240
	#优先级，主节点的优先级需要设置的比从节点高
    priority 90
	#设置主备之间的检查时间，单位s
    advert_int 1
	#定义验证类型和密码
    authentication {
        auth_type PASS
        auth_pass 1111
    }
	# 另一个节点的ip
	unicast_peer {
		188.188.4.211
	}
	#虚拟ip
    virtual_ipaddress {
        188.188.4.200
    }
}

virtual_server 188.188.4.200 1080 {
    virtual_server 
    delay_loop 6
    lb_algo rr
    lb_kind NAT
    persistence_timeout 50
    protocol TCP

    real_server 188.188.4.212 1080 {
        weight 1
	# 监控脚本
        notify_down /etc/keepalived/check.sh
		TCP_CHECK {
		  connect_timeout 10
		  retry 3
		  connect_port 1080
		}
    }
}
```

5）创建 check 脚本

```bash
# 脚本内容 监听haproxy端口1080
$ cat /etc/keepalived/check.sh
#! /bin/bash
counter=$(ss -tanlp | grep "LISTEN" | grep "1080"|wc -l)
if [ "${counter}" -eq 0 ]
then
   pkill keepalived
fi

$ chmod +x /etc/keepalived/check.sh
```

6）启动并设置开机自启

```bash
$ /etc/init.d/keepalived start
$ systemctl enable keepalived && systemctl status keepalived
```
