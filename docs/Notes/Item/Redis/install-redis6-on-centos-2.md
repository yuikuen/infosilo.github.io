> CentOS7.9 安装 Redis6.x(Gcc9.5.0)
>
> Redis 6.x 以上要求 gcc 版本必须是 5 以上

- Sys-OS：CentOS Linux release 7.9.2009 (Core)
- Kernel：6.6.8-1.el7.elrepo.x86_64
- Make：GNU Make 4.4
- Gcc：gcc version 9.5.0 (GCC)
- Glibc：GLIBC_2.33
- Python：Python 3.6.1

1）下载 Reids 包并编译安装

```sh
$ wget https://download.redis.io/releases/redis-6.2.6.tar.gz
$ tar -xf redis-6.2.6.tar.gz
$ cd redis-6.2.6
$ make && make install PREFIX=/usr/local/redis
$ mkdir -p /usr/local/redis/{etc,log} && cp redis.conf /usr/local/redis/etc/
```

2）创建开机自启服务

```sh
$ vim /usr/lib/systemd/system/redis.service
[Unit]
Description=Redis
After=network.target

[Service]
# Type=forking
PIDFile=/var/run/redis_6379.pid
ExecStart=/usr/local/redis/bin/redis-server /usr/local/redis/etc/redis.conf
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s QUIT $MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target

$ systemctl daemon-reload && systemctl enable --now redis
$ systemctl status redis
● redis.service - Redis
   Loaded: loaded (/usr/lib/systemd/system/redis.service; enabled; vendor preset: disabled)
   Active: active (running) since Sat 2022-02-12 17:59:49 CST; 28s ago
 Main PID: 1107 (redis-server)
   CGroup: /system.slice/redis.service
           └─1107 /usr/local/redis/bin/redis-server 127.0.0.1:6379
```

3）设置软链接

```sh
$ ln -s /usr/local/redis/bin/redis-cli /usr/bin/redis
$ echo 'export PATH=/usr/local/redis/bin:$PATH' > /etc/profile.d/redis.sh
$ source /etc/profile
```