> Redis 设置 Sentienl 哨兵模式

## 一. 安装说明

Redis 的几种常见使用方式有：
- Redis 单副本
- Redis 多副本(主从)
- Redis Sentinel(哨兵)
- Redis Cluster
- Redis 自研

1. **Redis 单副本**
   Redis 单副本，采用单个 Redis 节点部署架构，没有备用节点实时同步数据，不提供数据持久化和备份策略，适用于数据可靠性要求不高的纯缓存业务场景

2. **Redis 多副本(主从)**
   Redis 多副本，采用主从(replication)部署结构，相较于单副本而言最大的特点就是主从实例间数据实时同步，并且提供数据持久化和备份策略。主从实例部署在不同的物理服务器上，根据公司的基础环境配置，可以实现同时对外提供服务和读写分离策略

3. **Redis Sentinel(哨兵)**
   Redis Sentinel 集群是由若干 Sentinel 节点组成的分布式集群，可以实现故障发现、故障自动转移、配置中心和客户端通知。Redis Sentinel 的节点数量要满足 2n+1(n>=1)的奇数个

4. **Redis Cluster**
   Redis Cluster 集群节点最小配置 6 个节点以上(3 主 3 从)，其中主节点提供读写操作，从节点作为备用节点，不提供请求，只作为故障转移使用。采用虚拟槽分区，所有的键根据哈希函数映射到 0～16383 个整数槽内，每个节点负责维护一部分槽以及槽所印映射的键值数据

5. **Redis 自研**
   Redis 自研的高可用解决方案，主要体现在配置中心、故障探测和 failover 的处理机制上，通常需要根据企业业务的实际线上环境来定制化

> 哨兵模式是一种特殊的模式，首先 Redis 提供了哨兵的命令，哨兵是一个独立的进程，作为进程，它会独立运行。其原理是**哨兵通过发送命令，等待 Redis 服务器响应，从而监控运行的多个 Redis 实例**

![](https://img.17121203.xyz/i/2024/10/21/nfdv1z-0.webp)

**Redis 哨兵的作用**

- 通过发送命令，让 Redis 服务器返回监控其运行状态，包括主服务器和从服务器
- 当哨兵监测到 master 宕机，会自动将 slave 切换成 master，然后通过**发布订阅模式**通知其他的从服务器，修改配置文件，让它们切换主机

> Redis 安装过程不再演示，主要演示配置 3个哨后和一主二从的 Redis 服务
>
> 一个哨兵进程对 Redis 服务器进行监控，可能会出现问题，为此可以使用多个哨兵进行监控。各个哨兵之间还会进行监控，这样就形成了多哨兵模式

![](https://img.17121203.xyz/i/2024/10/21/oug2fw-0.webp)

| 服务类型 | 是否是主服务器 | IP地址        | 端口  |
| -------- | -------------- | ------------- | ----- |
| Redis(M) | 是             | 188.188.4.210 | 6379  |
| Redis(S) | 否             | 188.188.4.211 | 6379  |
| Redis(S) | 否             | 188.188.4.212 | 6379  |
| Sentinel | -              | 188.188.4.210 | 26379 |
| Sentinel | -              | 188.188.4.211 | 26379 |
| Sentinel | -              | 188.188.4.212 | 26379 |

## 二. 配置主从

1）配置 Redis 主从服务，修改 `redis.conf` 文件(从服务器比主服务器多一个 slaveof 的配置和密码)

```bash
# Master
$ vim /usr/local/redis/etc/redis.conf
bind 0.0.0.0                 # 配置Redis服务器可跨网络访问
requirepass 123456           # 设置密码
logfile "/usr/local/redis/log/redis.log"
```

```bash
# Slave
$ vim /usr/local/redis/etc/redis.conf
bind 0.0.0.0                 # 配置Redis服务器可跨网络访问
requirepass 123456           # 设置密码
logfile "/usr/local/redis/log/redis.log"
replicaof 188.188.4.210 6379 # 指定Master服务器
masterauth 123456            # Master服务器密码
```

2）分别重启主从节点的 Redis 服务，出现如下界面代表主从配置成功

```bash
$ systemctl restart redis && systemctl status redis
```

![](https://img.17121203.xyz/i/2024/10/21/ov29qe-0.webp)

![](https://img.17121203.xyz/i/2024/10/21/ov4zsw-0.webp)

3）测试功能，登录主节点，运行 info replication 也可以看到配置的从节点

```bash
# Master
$ redis-cli
127.0.0.1:6379> auth 123456
OK
127.0.0.1:6379> info replication
# Replication
role:master
connected_slaves:2
slave0:ip=188.188.4.211,port=6379,state=online,offset=462,lag=1
slave1:ip=188.188.4.212,port=6379,state=online,offset=462,lag=1
master_failover_state:no-failover
master_replid:e6390266fdecd75b7f42fcfb8dc7781683ccf4f1
master_replid2:0000000000000000000000000000000000000000
master_repl_offset:462
second_repl_offset:-1
repl_backlog_active:1
repl_backlog_size:1048576
repl_backlog_first_byte_offset:1
repl_backlog_histlen:462
127.0.0.1:6379> 
```

```bash
# Slave
$ redis-cli 
127.0.0.1:6379> auth 123456
OK
127.0.0.1:6379> info replication
# Replication
role:slave
master_host:188.188.4.210
master_port:6379
master_link_status:up
master_last_io_seconds_ago:2
master_sync_in_progress:0
slave_read_repl_offset:546
slave_repl_offset:546
slave_priority:100
slave_read_only:1
replica_announced:1
connected_slaves:0
master_failover_state:no-failover
master_replid:e6390266fdecd75b7f42fcfb8dc7781683ccf4f1
master_replid2:0000000000000000000000000000000000000000
master_repl_offset:546
second_repl_offset:-1
repl_backlog_active:1
repl_backlog_size:1048576
repl_backlog_first_byte_offset:1
repl_backlog_histlen:546
127.0.0.1:6379>
```

## 三. 配置哨兵

1）配置 3个哨兵，每个哨兵配置一样(Redis 解压包内有 `sentinel.conf` 配置文件，直接 copy 修改)

```bash
$ cp /usr/local/src/redis-6.2.6/sentinel.conf /usr/local/redis/etc/
$ vim sentinel.conf
bind 0.0.0.0                                 # 监听IP地址
protected-mode no                            # 关闭保护模式
daemonize yes                                # 以守护进程方式运行
logfile "/usr/local/redis/log/sentinel.log"  # 日志地址
# 配置监听的主服务器，这里sentinel monitor代表监控，mymaster代表服务器的名称，可以自定义，
# 188.188.4.210代表监控的主服务器，6379代表端口，1代表主挂了，从机投票接替，设2时表示只有两个或两个以上的哨兵认为主服务器不可用的时候，才会进行failover操作
sentinel monitor mymaster 188.188.4.210 6379 2  
sentinel auth-pass mymaster 123456
```

2）启动所有主机的哨兵，查看日志可以看到哨兵之间互相都可发现，并且监控起了master

```bash
# 通过哨兵模式的配置文件来启动哨兵
$ redis-sentinel /usr/local/redis/etc/sentinel.conf
```

注意启动的顺序。首先是主机的 Redis 服务进程，然后启动从机的服务进程，最后启动3个哨兵的服务进程

3）查看日志信息确认哨兵是否正常工作

```bash
$ tail -f sentinel.log 
3409:X 25 Apr 2022 15:23:46.930 # Redis version=6.2.6, bits=64, commit=00000000, modified=0, pid=3409, just started
3409:X 25 Apr 2022 15:23:46.930 # Configuration loaded
3409:X 25 Apr 2022 15:23:46.931 * monotonic clock: POSIX clock_gettime
3409:X 25 Apr 2022 15:23:46.932 * Running mode=sentinel, port=26379.
3409:X 25 Apr 2022 15:23:46.932 # Sentinel ID is 788515206623e806df3b5b6786a0527c6dfcc121
3409:X 25 Apr 2022 15:23:46.932 # +monitor master mymaster 188.188.4.210 6379 quorum 2
3409:X 25 Apr 2022 15:24:16.964 # +sdown sentinel 704d2de7c32d1f3b5f7a18ae0a68c55d86ec02d6 188.188.4.211 26379 @ mymaster 188.188.4.210 6379
3409:X 25 Apr 2022 15:24:16.964 # +sdown sentinel dbbe42b84b9b3cfdcc163a0413d1070f438b81eb 188.188.4.212 26379 @ mymaster 188.188.4.210 6379
3409:X 25 Apr 2022 15:24:32.585 # -sdown sentinel 704d2de7c32d1f3b5f7a18ae0a68c55d86ec02d6 188.188.4.211 26379 @ mymaster 188.188.4.210 6379
3409:X 25 Apr 2022 15:24:52.380 # -sdown sentinel dbbe42b84b9b3cfdcc163a0413d1070f438b81eb 188.188.4.212 26379 @ mymaster 188.188.4.210 6379
```

通过上述信息可以看到哨兵模式监控的主机(4.210)，和另两个哨兵模式监控的两个从机(4.211、4.212)

4）测试哨兵模式，让 Master 模拟宕机

```bash
# Master操作
$ redis-cli 
127.0.0.1:6379> auth 123456
OK
127.0.0.1:6379> shutdown
not connected> 
```

可以查看日志，发现哨兵已开始进行投票，`+switch-master` 即就是主从切换的过程，而 `4.211` 成为 Master

![](https://img.17121203.xyz/i/2024/10/21/ow7wvm-0.webp)

```bash
# Slave 188.188.4.211查看info replication,已成为Master
$ redis-cli 
127.0.0.1:6379> auth 123456
OK
127.0.0.1:6379> info replication
# Replication
role:master
connected_slaves:1
slave0:ip=188.188.4.212,port=6379,state=online,offset=199663,lag=1
master_failover_state:no-failover
master_replid:4d8626cb58b9764b63c9235b4a1881a20f12b5e0
master_replid2:7c661bd49f2ff3a277d158bee04e230dfb5794c0
master_repl_offset:199663
second_repl_offset:155919
repl_backlog_active:1
repl_backlog_size:1048576
repl_backlog_first_byte_offset:1
repl_backlog_histlen:199663
127.0.0.1:6379>
```

5）配置开机自启动

```bash
$ cat > /usr/lib/systemd/system/sentinel.service << EOF
[Unit]
Description=Redis persistent key-value database
After=network.target
After=network-online.target
Wants=network-online.target

[Service]
Type=forking
ExecStart=/usr/local/redis/bin/redis-sentinel /usr/local/redis/etc/sentinel.conf 
ExecStop=/usr/local/redis/bin/redis-cli -h 127.0.0.1 -p 26379 shutdown
#需要先创建用户
#User=redis
#Group=redis
#RuntimeDirectory=redis
#RuntimeDirectoryMode=0755

[Install]
WantedBy=multi-user.target
EOF

$ systemctl enable --now sentinel.service
```

