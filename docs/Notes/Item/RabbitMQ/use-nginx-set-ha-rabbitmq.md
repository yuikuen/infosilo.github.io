> 通过 Nginx 实现高可用 RabbitMQ

## 一. 安装说明

> 搭建集群前，需要在各个节点安装好 RabbitMQ，具体安装参考 `RabbitMQ 各部署方式` & [RabbitMQ Erlang 版本要求](https://www.rabbitmq.com/which-erlang.html)

- System：CentOS7.9.2009 Minimal
- Erlang：Erlang-23.3.4.11
- RabbitMQ：RabbitMQ_Server-3.8.2
- Nginx：Nginx-1.21.4

- 服务器规划

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

## 二. 安装 Erlang

- 下载程序并安装相关依赖

```bash
$ yum -y install socat

$ wget https://github.com/rabbitmq/erlang-rpm/releases/download/v23.3.4.11/erlang-23.3.4.11-1.el7.x86_64.rpm
$ rpm -i erlang-23.3.4.11-1.el7.x86_64.rpm
warning: erlang-23.3.4.11-1.el7.x86_64.rpm: Header V4 RSA/SHA256 Signature, key ID cc4bbe5b: NOKEY

$ erl -version
Erlang (SMP,ASYNC_THREADS,HIPE) (BEAM) emulator version 11.2.2.10
```

## 三. 安装 RabbitMQ

> 安装前需要确认 Erlang 安装成功，如未注明指定节点，默认所有节点操作一样,自行到
> [RabbitMQ 官网](https://www.rabbitmq.com/download.html) 下载

1）下载程序并配置环境变量

```bash
$ wget https://github.com/rabbitmq/rabbitmq-server/releases/download/v3.8.29/rabbitmq-server-generic-unix-3.8.29.tar.xz
$ tar -xvf rabbitmq-server-generic-unix-3.8.29.tar -C /opt
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

4）配置开机自启服务

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

> 前面已定义了 `.erlang.cookie` 文件内容，该文件相当于密钥令牌，集群中各节点通过该令牌进行相互认证

```bash
# 分别在三个节点上查看该文件内容是否相同
$ more /root/.erlang.cookie
rabbitmq-cluster-cookie
```

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

或使用任一节点在浏览器上打开 IP:15672 管理页面，如下图显示绿色表示成功

3）配置镜像队列

通过命令方式和管理页面方式实现：同步 `virtual host` 为 "/" 下名称前缀为 "mirroring" 的交换机和队列，并且自动保存到另两节点上

```bash
# policy配置格式，命令行配置镜像队列，在任一节点上执行如下命令
$ rabbitmqctl set_policy [-p ] [--priority ] [--apply-to ] 

# 同步virtual host为 "/"下名称前缀为 "mirroring"的交换机和队列，并且自动保存到两个节点上
$ rabbitmqctl set_policy -p / --priority 1 --apply-to all myPolicy "^mirroring" '{"ha-mode":"exactly","ha-params":2,"ha-sync-mode":"automatic"}'
```

## 五. 安装 Nginx

```bash
# 下载依赖并编辑安装
$ yum -y install gcc pcre pcre-devel zlib zlib-devel openssl openssl-devel
$ wget http://nginx.org/download/nginx-1.21.4.tar.gz
$ tar -xf nginx-1.21.4.tar.gz && cd nginx-1.21.4
$ ./configure --prefix=/usr/local/nginx 
$ make && make install 

# 配置关机自启
$ vim /lib/systemd/system/nginx.service
[Unit]
Description=nginx
After=network.target

[Service]
Type=forking
ExecStart=/usr/local/nginx/sbin/nginx
ExecReload=/usr/local/nginx/sbin/nginx -s reload
ExecStop=/usr/local/nginx/sbin/nginx -s stop
PrivateTmp=true

[Install]
WantedBy=multi-user.target

$ systemctl enable --now nginx && systemctl status nginx && systemctl status nginx
```

## 六. 负载均衡

```bash
$ cp /usr/local/nginx/conf/nginx.conf /usr/local/nginx/conf/nginx.conf.bak.$(date +%F_%T)
$ vim /usr/local/nginx/conf/nginx.conf
# 增加一行
include /usr/local/nginx/vhosts/*.conf;

$ vim /usr/local/nginx/vhosts/rabbitmq.conf
upstream rabbitmq {
    server 188.188.4.210:15672  max_fails=2 fail_timeout=1;
    server 188.188.4.211:15672  max_fails=2 fail_timeout=1;
    server 188.188.4.212:15672  max_fails=2 fail_timeout=1;
}

server {
 listen 81;
 #server_name rabbitmq.yuikuen.top;
 server_name 127.0.0.1;
 charset utf-8;

 location / {
   proxy_pass http://rabbitmq;
        proxy_set_header           Host $host;
        proxy_set_header           X-Real-IP $remote_addr;
        proxy_set_header           X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_connect_timeout 300s;
        proxy_send_timeout 300s;
        proxy_read_timeout 300s;
    }
}
```

![](https://img.17121203.xyz/i/2024/10/22/idlhg9-0.webp)

**上图为未加入集群的负载情况，仅代表 Nginx 负载成功**

![](https://img.17121203.xyz/i/2024/10/22/idonzz-0.webp)

**最终效果如上图所示**

