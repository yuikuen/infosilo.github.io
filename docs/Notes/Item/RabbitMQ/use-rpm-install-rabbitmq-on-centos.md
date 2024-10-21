> CentOS7 使用 RPM 安装 RabbitMQ

RabbitMQ 采用 Erlang 语言开发，安装前建议先查看 [Erlang官方说明](https://github.com/rabbitmq/erlang-rpm) 并注意 Readme 上的版本兼容问题

- System：CentOS7.9.2009 Minimal
- Erlang：Erlang-23.3.4.11
- RabbitMQ：RabbitMQ_Server-3.8.29

## 一. 安装 Erlang

> RabbitMQ 需要 Erlang 环境

1）下载组件后直接安装

```bash
$ yum -y install socat

$ wget https://github.com/rabbitmq/erlang-rpm/releases/download/v23.3.4.11/erlang-23.3.4.11-1.el7.x86_64.rpm
$ rpm -i erlang-23.3.4.11-1.el7.x86_64.rpm
warning: erlang-23.3.4.11-1.el7.x86_64.rpm: Header V4 RSA/SHA256 Signature, key ID cc4bbe5b: NOKEY

$ erl -version
Erlang (SMP,ASYNC_THREADS,HIPE) (BEAM) emulator version 11.2.2.10
```

## 二. 安装 RabbitMQ

1）同样下载程序直接安装

```bash
$ wget https://github.com/rabbitmq/rabbitmq-server/releases/download/v3.8.29/rabbitmq-server-3.8.29-1.el7.noarch.rpm

$ rpm -i rabbitmq-server-3.8.29-1.el7.noarch.rpm
warning: rabbitmq-server-3.8.29-1.el7.noarch.rpm: Header V4 RSA/SHA512 Signature, key ID 6026dfca: NOKEY

$ systemctl enable --now rabbitmq-server
$ systemctl status rabbitmq-server
● rabbitmq-server.service - RabbitMQ broker
   Loaded: loaded (/usr/lib/systemd/system/rabbitmq-server.service; enabled; vendor preset: disabled)
   Active: active (running) since Fri 2022-04-22 15:30:27 CST; 7s ago
 Main PID: 1514 (beam.smp)
   Status: "Initialized"
   CGroup: /system.slice/rabbitmq-server.service
           ├─1514 /usr/lib64/erlang/erts-11.2.2.10/bin/beam.smp -W w -MBas ageffcbf -MHas ageffcbf -MBlmbcs 512 -MHlmbcs 512 -MMmcs 30 -P 1048576 -t 5000000 -stbt db ...
           ├─1529 erl_child_setup 32768
           ├─1558 /usr/lib64/erlang/erts-11.2.2.10/bin/epmd -daemon
           ├─1585 inet_gethost 4
           └─1586 inet_gethost 4

Apr 22 15:30:24 Dev-Pc rabbitmq-server[1514]: TLS Library: OpenSSL - OpenSSL 1.0.2k-fips  26 Jan 2017
Apr 22 15:30:24 Dev-Pc rabbitmq-server[1514]: Doc guides:  https://rabbitmq.com/documentation.html
Apr 22 15:30:24 Dev-Pc rabbitmq-server[1514]: Support:     https://rabbitmq.com/contact.html
Apr 22 15:30:24 Dev-Pc rabbitmq-server[1514]: Tutorials:   https://rabbitmq.com/getstarted.html
Apr 22 15:30:24 Dev-Pc rabbitmq-server[1514]: Monitoring:  https://rabbitmq.com/monitoring.html
Apr 22 15:30:24 Dev-Pc rabbitmq-server[1514]: Logs: /var/log/rabbitmq/rabbit@Dev-Pc.log
Apr 22 15:30:24 Dev-Pc rabbitmq-server[1514]: /var/log/rabbitmq/rabbit@Dev-Pc_upgrade.log
Apr 22 15:30:24 Dev-Pc rabbitmq-server[1514]: Config file(s): (none)
Apr 22 15:30:27 Dev-Pc rabbitmq-server[1514]: Starting broker... completed with 0 plugins.
Apr 22 15:30:27 Dev-Pc systemd[1]: Started RabbitMQ broker.

$ lsof -i:5672
COMMAND   PID     USER   FD   TYPE DEVICE SIZE/OFF NODE NAME
beam.smp 1514 rabbitmq   95u  IPv6  23013      0t0  TCP *:amqp (LISTEN)
```

查看启动服务文件 `rabbitmq-server.service`，可查看到相关配置信息

```bash
$ cat /usr/lib/systemd/system/rabbitmq-server.service
[Unit]
Description=RabbitMQ broker
After=syslog.target network.target

[Service]
Type=notify
User=rabbitmq
Group=rabbitmq
UMask=0027
NotifyAccess=all
TimeoutStartSec=600

# To override LimitNOFILE, create the following file:
#
# /etc/systemd/system/rabbitmq-server.service.d/limits.conf
#
# with the following content:
#
# [Service]
# LimitNOFILE=65536

LimitNOFILE=32768

# Note: systemd on CentOS 7 complains about in-line comments,
# so only append them here
#
# Restart:
# The following setting will automatically restart RabbitMQ
# in the event of a failure. systemd service restarts are not a
# replacement for service monitoring. Please see
# https://www.rabbitmq.com/monitoring.html
Restart=on-failure
RestartSec=10
WorkingDirectory=/var/lib/rabbitmq
ExecStart=/usr/sbin/rabbitmq-server
ExecStop=/usr/sbin/rabbitmqctl shutdown
# See rabbitmq/rabbitmq-server-release#51
SuccessExitStatus=69

[Install]
WantedBy=multi-user.target
```