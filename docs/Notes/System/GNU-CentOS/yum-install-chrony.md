> 最近部署 Kube-Prometheus 时，虽然已安装了 ntpdate 并同步了 `time2.aliyun.com` ,但还是提示 `Clock not synchronising.` 以此为例重新安装 chrony 并开启同步功能

[Chrony](https://chrony.tuxfamily.org/comparison.html) 是网络时间协议（NTP）的通用实现，具体介绍 & 其它时间同步软件对比

## 一. 安装服务

```bash
$ yum install -y chrony

# 默认配置文件
$ cat /etc/chrony.conf 

# 使用 pool.ntp.org 项目中的公共服务器。以server开，理论上想添加多少时间服务器都可以
# Use public servers from the pool.ntp.org project.
# Please consider joining the pool (http://www.pool.ntp.org/join.html).
server 0.centos.pool.ntp.org iburst
server 1.centos.pool.ntp.org iburst
server 2.centos.pool.ntp.org iburst
server 3.centos.pool.ntp.org iburst

# 下列为新增的公共服务器
# 国家服务器
server 0.cn.pool.ntp.org
server 1.cn.pool.ntp.org
server 2.cn.pool.ntp.org
server 3.cn.pool.ntp.org
# 阿里
server ntp.aliyun.com
# 腾讯
server time1.cloud.tencent.com
server time2.cloud.tencent.com
server time3.cloud.tencent.com
server time4.cloud.tencent.com
server time5.cloud.tencent.com
# 苹果
server time.asia.apple.com
# 微软
server time.windows.com
# 其他
server cn.ntp.org.cn

# 根据实际时间计算出服务器增减时间的比率，然后记录到一个文件中，在系统重启后为系统做出最佳时间补偿调整
# Record the rate at which the system clock gains/losses time.
driftfile /var/lib/chrony/drift

# 如果系统时钟的偏移量大于1秒，则允许系统时钟在前三次更新中步进
# Allow the system clock to be stepped in the first three updates
# if its offset is larger than 1 second.
makestep 1.0 3

# 启用实时时钟（RTC）的内核同步
# Enable kernel synchronization of the real-time clock (RTC).
rtcsync

# 通过使用 hwtimestamp 指令启用硬件时间戳
# Enable hardware timestamping on all interfaces that support it.
#hwtimestamp *

# Increase the minimum number of selectable sources required to adjust
# the system clock.
#minsources 2

# 指定 NTP 客户端地址，以允许或拒绝连接到扮演时钟服务器的机器
# Allow NTP client access from local network.
#allow 192.168.0.0/16

# Serve time even if not synchronized to a time source.
#local stratum 10

# 指定包含 NTP 身份验证密钥的文件
# Specify file containing keys for NTP authentication.
#keyfile /etc/chrony.keys

# 指定日志文件的目录
# Specify directory for log files.
logdir /var/log/chrony

# 选择日志文件要记录的信息
# Select which information is logged.
#log measurements statistics tracking
```

## 二. 基本操作

```bash
# 启动服务
$ systemctl start chronyd

# 开机启动
$ systemctl enable chronyd

# 查看当前状态
$ systemctl status chronyd

# 查看亚洲时区
$ timedatectl list-timezones | grep Asia

# 设置时区
$ timedatectl set-timezone Asia/Shanghai
```

## 三. 验证效果

```bash
# 查看现有的时间服务器
$ chronyc sources -v

# 查看时间服务器状态
$ chronyc sourcestats -v

# 显示时钟同步相关参数
$ chronyc tracking

# 查看当前时区及时间
$ timedatectl 
```

## 四. 扩展内容

```bash
# 使用 ntpdate 同步时间
$ ntpdate ntp.aliyun.com

# chronyd 未启动时，如下命令同步时间
$ chronyd -q 'server pool.ntp.org iburst'

# chronyd 启动时，使用如下命令同步时间
$ chronyc -a 'burst 4/4' && sleep 10 && chronyc -a makestep

# date 设置时间
$ date -s '2021-06-03 19:00:00'

# 关闭 ntp 同步后，才可以使用 timedatectl 进行时间设置
$ timedatectl set-ntp false

# 设置日期和时间
$ timedatectl set-time '2021-06-03 19:00:00'

# 设置日期
$ timedatectl set-time '2021-06-03'

# 设置时间
$ timedatectl set-time '19:00:00'

# 设置完成后，再开启
$ timedatectl set-ntp true
```