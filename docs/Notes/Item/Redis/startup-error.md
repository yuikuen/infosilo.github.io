> 解决 Redis 启动报错

## 一. Error-Bind

**错误提示**：`Warning: Could not create server TCP listening socket ::1:6379: bind: Cannot assign requested address`

```bash
# redis启动时载入的配置文件有一个无效参数，修改redis.conf，把bind 127.0.0.1的注释，并改成0
$ vim ./redis.conf
  72 # IF YOU ARE SURE YOU WANT YOUR INSTANCE TO LISTEN TO ALL THE INTERFACES
  73 # JUST COMMENT OUT THE FOLLOWING LINE.
  74 # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  75 #bind 127.0.0.1 -::1
  76 bind 0.0.0.0
```

## 二. Error-Fail

错误提示：`Redis cluster_state:fail`  `CLUSTERDOWN Hash slot not served`

> 搭建的 Redis 集群，正常启动并登录，但无法使用

```bash
$ kubectl -n public-service  exec -it drc-redis-0-0 -- redis-cli cluster info
cluster_state:fail
cluster_slots_assigned:16380
cluster_slots_ok:16380
cluster_slots_pfail:0
cluster_slots_fail:0
cluster_known_nodes:6
cluster_size:3
cluster_current_epoch:8
cluster_my_epoch:1
cluster_stats_messages_sent:1007

# 登陆进去测试
xxx.xxx.xxx.xxx>set test aaa
报错(error) CLUSTERDOWN Hash slot not served
```

**原因** 是没有分配槽，因为 redis 集群要分配 16384 个槽来储存数据，那么没有分配槽则报如上错误

**解决方案** 执行下面步骤来修复

```bash
$ kubectl -n public-service  exec -it drc-redis-0-0 -- redis-cli cluster check 127.0.0.1:6379
[ERR] Not all 16384 slots are covered by nodes
$ kubectl -n public-service  exec -it drc-redis-0-0 -- redis-cli cluster fix 127.0.0.1:6379
```

询问的时候记得输入 yes，不要输入 y

## 三. Error-Memory

**错误提示**：`WARNING overcommit_memory is set to 0! Background save may fail under low memory condition. To fix this issue add 'vm.overcommit_memory = 1' to /etc/sysctl...is to take effect.`

```bash
# 原因分析：overcommit_memory设置为0，在内存不足的情况下，后台保存会失败，要解决这个问题需要将此值改为1，然后重新加载，使其生效
$ echo 'vm.overcommit_memory=1' >> /etc/sysctl.conf 
$ sysctl -p
```

## 四. Error-Tcp-Baklog

**错误提示**：`WARNING: The TCP backlog setting of 511 cannot be enforced because /proc/sys/net/core/somaxconn is set to the lower value of 128.`

```bash
# 将/proc/sys/net/core/somaxconn值设置为redis配置文件中的tcp-baklog值一致即可
$ echo '511' > /proc/sys/net/core/somaxconn

# 上述为临时处理方法，永久生效需要配置内核
$ echo 'net.core.somaxconn= 1024' >> /etc/sysctl.conf
$ sysctl -p
```

## 五. Error-THP

**错误提示**：`WARNING you have Transparent Huge Pages (THP) support enabled in your kernel. This will create latency and memory usage issues with Redis. To fix this issue run the command .`

```bash
# 警告：您的内核中启用了透明的大页面（THP）支持。这将创建与ReDIS的延迟和内存使用问题。若要修复此问题，请运行命令“EngEng/mS/mL/mM/ExpListNo.HugPoIP/启用”为root，并将其添加到您的/etc/rc.local，以便在重新启动后保留设置。在禁用THP之后，必须重新启动redis。
$ echo 'never' > /sys/kernel/mm/transparent_hugepage/enabled

# 上述为临时处理方法，永久生效需要配置到开机自启
$ vim /etc/rc.local
if test -f /sys/kernel/mm/transparent_hugepage/enabled; then
   echo never > /sys/kernel/mm/transparent_hugepage/enabled
fi
```