> CentOS7.9 安装 Redis6.x(Gcc4.8.5)
>
> Redis 6.x 以上要求 gcc 版本必须是 5 以上

- System：CentOS7.9.2009 Minimal
- Gcc：4.8.5 以上
- Redis：redis-6.2.6

**程序链接**

- [Redis 官网地址](https://redis.io/)
- [Redis 下载地址](https://download.redis.io/releases/)

1）下载依赖组件，升级 gcc 版本

```bash
$ gcc -v 
gcc version 4.8.5 20150623 (Red Hat 4.8.5-44) (GCC)

$ yum -y install centos-release-scl scl-utils-build
$ yum -y install devtoolset-9-gcc devtoolset-9-gcc-c++ devtoolset-9-binutils
$ scl enable devtoolset-9 bash
```

2）修改环境变量

> 注：scl只是临时操作，长期生效需设置到系统环境变量

```bash
$ echo "source /opt/rh/devtoolset-9/enable" >>/etc/profile
$ source /etc/profile
```

3）下载 Redis 包并编译安装

```bash
$ wget https://download.redis.io/releases/redis-6.2.6.tar.gz
$ tar -xf redis-6.2.6.tar.gz
$ cd redis-6.2.6
$ make && make install PREFIX=/usr/local/redis
$ mkdir -p /usr/local/redis/{etc,log} && cp redis.conf /usr/local/redis/etc/
```

3）创建开机自启服务

```bash
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

4）设置命令软链接

```bash
$ ln -s /usr/local/redis/bin/redis-cli /usr/bin/redis
$ echo 'export PATH=/usr/local/redis/bin:$PATH' >> /etc/profile
$ source /etc/profile
```