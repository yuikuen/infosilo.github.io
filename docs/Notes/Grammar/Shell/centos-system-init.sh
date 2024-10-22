#/bin/bash
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin

# 更改主机名
# hostnamectl set-hostname <hostname>

# 修改PS1样式
# echo 'PS1="[\e[1;34;40m\]\d \e[31;40m\]\u\e[32;40m\]@\e[35;40m\]\h \e[36;40m\]\W\[\e[0m\]]\\$ "' > /etc/profile.d/env.sh
echo 'PS1="[\e[1;34;40m\]\t \e[31;40m\]\u\e[32;40m\] @ \e[36;40m\]\W\[\e[0m\]]\\$ "' > /etc/profile.d/env.sh

# 隐藏服务器版本
> /etc/issue

# 修改字符集
localectl set-locale LANG=en_US.UTF-8

# 解决ssh连接速度慢的问题
sed -i '/GSSAPIAuthentication/{s/yes/no/}' /etc/ssh/sshd_config
sed -i 's/\#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config
# sed -i '134i GSSAPIAuthentication no\nUseDNS no' /etc/ssh/sshd_config

# 更新yum源
if egrep "7.[0-9]" /etc/redhat-release &>/dev/null; then
    wget -O /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
    wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
elif egrep "6.[0-9]" /etc/redhat-release &>/dev/null; then
    wget -O /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-6.repo
    wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-6.repo
fi
yum clean all

# 设置时区并同步时间
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
if ! crontab -l | grep "ntpdate" &>/dev/null; then
    (echo "*/5 * * * * /usr/sbin/ntpdate ntp.aliyun.com >/dev/null 2>&1"; crontab -l) | crontab
fi

# 禁用selinux
sed -i '/SELINUX/{s/enforcing/disabled/}' /etc/selinux/config

# 关闭防火墙
if egrep "7.[0-9]" /etc/redhat-release &>/dev/null; then
    systemctl stop firewalld.service
    systemctl disable firewalld.service
elif egrep "6.[0-9]" /etc/redhat-release &>/dev/null; then
    service iptables stop
    chkconfig iptables off
fi

# 关闭postfix服务
if egrep "7.[0-9]" /etc/redhat-release &>/dev/null; then
    systemctl stop postfix.service
    systemctl disable postfix.service
elif egrep "6.[0-9]" /etc/redhat-release &>/dev/null; then
    service postfix stop
    chkconfig postfix off
fi

# 历史命令显示操作时间；命令行历史数；忽略所有以空格开头的命令。
if ! grep "HISTTIMEFORMAT" /etc/profile &>/dev/null; then
    echo 'export HISTTIMEFORMAT="%F %T `whoami` "' >> /etc/profile
    echo "export HISTSIZE=50" >>/etc/profile
    echo "export HISTFILESIZE=50" >> /etc/profile
    echo "export HISTCONTROL=ignorespace" >>/etc/profile
fi

# SSH超时时间，改变umask
if ! grep "TMOUT=3600" /etc/profile &>/dev/null; then
    echo "export TMOUT=3600" >> /etc/profile
    echo "umask 022" >> /etc/profile
fi

# 禁止root远程登录
sed -i 's/\#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config

# 禁止定时任务向发送邮件
sed -i 's/^MAILTO=root/MAILTO=""/' /etc/crontab

# 设置最大打开文件数
if ! grep "* soft nofile 65535" /etc/security/limits.conf &>/dev/null; then
cat >> /etc/security/limits.conf << EOF
* soft nproc 65535
* hard nproc 65535
* soft nofile 65535
* hard nofile 65535
EOF
fi
echo "ulimit -SHn 65535" >> /etc/profile
echo "ulimit -SHn 65535" >> /etc/rc.local

# 系统内核优化
if ! grep "net.ipv4" /etc/sysctl.conf &>/dev/null; then
cat >> /etc/sysctl.conf << EOF
###调整网络数据包转发
net.ipv4.ip_forward = 1
net.ipv4.tcp_max_syn_baklog = 65536
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
###调整系统级别的文件描述符的数量
fs.file-max = 6553500
###调整系统级别的允许线程的数量
kernel.pid_max=1000000
###内存资源使用相关设定
vm.vfs_cache_pressure = 100000
vm.max_map_count = 262144
vm.swappiness = 0
net.core.wmem_default = 8388608   
net.core.rmem_default = 8388608  
net.core.rmem_max = 16777216 
net.core.wmem_max = 16777216 
net.ipv4.tcp_rmem = 4096 8192 4194304 
net.ipv4.tcp_wmem = 4096 8192 4194304    
##应对DDOS攻击,TCP连接建立设置
net.ipv4.tcp_syncookies = 1 
net.ipv4.tcp_synack_retries = 2  
net.ipv4.tcp_syn_retries = 2   
net.ipv4.tcp_max_syn_backlog = 262144 
##应对timewait过高,TCP连接断开设置
net.ipv4.tcp_max_tw_buckets = 30000  
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_tw_len = 1
net.ipv4.tcp_tw_reuse = 1 
net.ipv4.tcp_timestamps = 0   
net.ipv4.tcp_fin_timeout = 120 
net.ipv4.ip_local_port_range = 1024 65535
###TCP keepalived 连接保鲜设置
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.tcp_keepalive_intvl = 15 
net.ipv4.tcp_keepalive_probes = 5
###其他TCP相关调节
net.nf_conntrack_max = 16404388
net.core.somaxconn = 32768 
net.core.netdev_max_backlog = 262144
net.ipv4.tcp_mem = 94500000 915000000 927000000
net.ipv4.tcp_max_orphans = 3276800    
net.ipv4.tcp_sack = 1  
net.ipv4.tcp_window_scaling = 1
net.netfilter.nf_conntrack_tcp_timeout_established = 10800
EOF
fi

# 减少SWAP使用
if ! grep "vm.swappiness" /etc/sysctl.conf &>/dev/null; then
cat >> /etc/sysctl.conf << EOF
vm.swappiness = 0
EOF
fi
# echo "0" > /proc/sys/vm/swappiness
# 临时生效

# 安装系统性能分析工具及其他
yum install gcc make autoconf vim sysstat net-tools iostat iftop iotop lrzsz bzip2 gcc gcc-c++ -y

# 重启服务器
reboot