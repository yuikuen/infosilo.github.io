> CentOS7 安装单节点 RabbitMQ

## 一. 安装说明

> RabbitMQ 采用 Erlang 语言开发，所以在安装 RabbitMQ 前，需要安装 Erlang

- Linux 版本：CentOS Linux release 7.9.2009 (Core)
- erlang 版本：Erlang-24.2
- RabbitMQ 版本：RabbitMQ_Server-3.9.14

## 二. 安装 Erlang

- [Erlang 官网下载地址](http://www.erlang.org/download)
- [RabbitMQ Erlang 版本要求](https://www.rabbitmq.com/which-erlang.html)

![](https://img.17121203.xyz/i/2024/10/21/qj72fw-0.webp)

```bash
$ wget https://erlang.org/download/otp_src_24.2.tar.gz
```
1）安装相关依赖 
```bash
$ yum -y install make gcc gcc-c++ kernel-devel m4 ncurses-devel openssl-devel gtk2-devel binutils-devel unixODBC unixODBC-devel xz
```

2）解压编译安装 Erlang
```bash
$ tar -zxvf otp_src_24.2.tar.gz && cd otp_src_24.2
$ ./configure prefix=/usr/local/erlang
$ make && make install
```

3）配置环境变量并验证是否安装成功
```bash
$ echo 'export PATH=/usr/local/erlang/bin:$PATH' >> /etc/profile
$ source /etc/profile
$ erl -version
Erlang (SMP,ASYNC_THREADS) (BEAM) emulator version 12.2
```

## 三. 安装 RabbitMQ

> 安装前需要确认 Erlang 安装成功

[RabbitMQ 官网下载地址](https://www.rabbitmq.com/download.html)

![](https://img.17121203.xyz/i/2024/10/21/qjoxlm-0.webp)

1）下载程序包并配置环境变量
```bash
$ wget https://github.com/rabbitmq/rabbitmq-server/releases/download/v3.9.14/rabbitmq-server-generic-unix-3.9.14.tar.xz
$ xz -d rabbitmq-server-generic-unix-3.9.14.tar.xz && tar -xvf rabbitmq-server-generic-unix-3.9.14.tar -C /usr/local
$ cd /usr/local/ && mv rabbitmq_server-3.9.14 rabbitmq

$ echo 'export PATH=/usr/local/rabbitmq/sbin:$PATH' >> /etc/profile
$ source /etc/profile
```

2）启动并检验是否成功

```bash
$ rabbitmq-server -detached
$ ss -lntp | grep 5672
LISTEN     0      128          *:25672                    *:*                   users:(("beam.smp",pid=37754,fd=17))
LISTEN     0      128       [::]:5672                  [::]:*                   users:(("beam.smp",pid=37754,fd=32))
```
3）修改配置文件

[RabbitMQ 官方配置](https://www.rabbitmq.com/configure.html)

```bash
$ cat /usr/local/rabbitmq/env.sh
#!/bin/bash

host_name=$(hostname)
int_path=/usr/local/rabbitmq/
env_path=/usr/local/rabbitmq/etc/rabbitmq/
mq_path=/usr/local/rabbitmq/var/lib/rabbitmq/mnesia/
mq_name=$(ls -l $mq_path | awk '{print $NF}' | grep rabbit | head -n1 | awk -F '@' '{print $NF}')
address=$(ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:")

if [ ${host_name} == ${mq_name} ];then
  # rabbitmq节点名称,注意集群唯一
  echo "NODENAME=rabbit@${host_name}"  >> $env_path/rabbitmq-env.conf
  # 绑定网络接口IP
  echo "NODE_IP_ADDRESS=${address}" >> $env_path/rabbitmq-env.conf
  # 端口，默认5672
  echo "NODE_PORT=5672" >> $env_path/rabbitmq-env.conf
  # mnesia所在路径，默认$RABBITMQ_HOME/var/lib/rabbitmq/mnesia
  echo "MNESIA_BASE=${mq_path}" >> $env_path/rabbitmq-env.conf
else
  echo "Configuration failed, please check the script"
fi

$ chmod a+x !$
$ sh /usr/local/rabbitmq/env.sh
```

4）添加浏览器管理插件，默认安装是没有管理页面，需要手动安装

```bash
$ rabbitmq-plugins enable rabbitmq_management
Enabling plugins on node rabbit@Dev-Pc:
rabbitmq_management
The following plugins have been configured:
  rabbitmq_management
  rabbitmq_management_agent
  rabbitmq_web_dispatch
Applying plugin configuration to rabbit@Dev-Pc...
The following plugins have been enabled:
  rabbitmq_management
  rabbitmq_management_agent
  rabbitmq_web_dispatch

started 3 plugins.
```

![](https://img.17121203.xyz/i/2024/10/21/qk9g1l-0.webp)

5）添加用户密码

> RabbitMQ 有默认用户密码，`guest/guest` 该用户密码只能在本地登陆，若在浏览器中登陆，须创建新用户密码
```bash
$ rabbitmqctl add_user rabbitmq_user rabbitmq_pwd
Adding user "rabbitmq_user" ...
Done. Don't forget to grant the user permissions to some virtual hosts! See 'rabbitmqctl help set_permissions' to learn more.
```

6）检查用户及分配权限

```bash
# 检查用户列表
$ rabbitmqctl list_users
Listing users ...
user	tags
guest	[administrator]
rabbitmq_user	[]

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

7）启动消息队列服务

```bash
$ rabbitmqctl start_app
Starting node rabbit@Dev-Pc ...

# 验证15672端口存在表示消息队列服务启动成功
$ ss -lntp | grep 15672
LISTEN     0      1024         *:15672                    *:*                   users:(("beam.smp",pid=37754,fd=34))
```

8）浏览器登陆 RabbitMQ 管理界面

在浏览器中访问 IP:15672 进行登陆，若出现 `ReferenceError:disable_stats is not defined`，可 `ctrl+f5` 清除页面缓存后重新登陆

![](https://img.17121203.xyz/i/2024/10/21/qkga6m-0.webp)

9）配置开机自启
- 方法一：修改环境变量，直接开机自启，启动时会报异常，无视即可；
```bash
$ echo '/usr/local/rabbitmq/sbin/rabbitmq-server -detached && rabbitmqctl start_app' >> /etc/profile
$ source /etc/profile
```

- 方法二：创建启动脚本，开机检测脚本，实现自启动
```bash
$ cat /etc/init.d/rabbitmq-server
#!/bin/sh
#
# rabbitmq-server RabbitMQ broker
#
# chkconfig: - 80 05
# description: Enable AMQP service provided by RabbitMQ
#
 
### BEGIN INIT INFO
# Provides:          rabbitmq-server
# Required-Start:    $remote_fs $network
# Required-Stop:     $remote_fs $network
# Description:       RabbitMQ broker
# Short-Description: Enable AMQP service provided by RabbitMQ broker
### END INIT INFO
 
# Source function library.
. /etc/init.d/functions
export HOME=/root
PATH=/sbin:/usr/sbin:/bin:/usr/bin:/usr/local/erlang/bin
NAME=rabbitmq-server

DAEMON=/usr/local/rabbitmq/sbin/${NAME}
CONTROL=/usr/local/rabbitmq/sbin/rabbitmqctl
DESC=rabbitmq-server
USER=root
ROTATE_SUFFIX=
INIT_LOG_DIR=/usr/local/rabbitmq/var/log/rabbitmq
PID_FILE=/usr/local/rabbitmq/var/run/rabbitmq/pid
 
START_PROG="daemon"
LOCK_FILE=/var/lock/subsys/$NAME
 
test -x $DAEMON || exit 0
test -x $CONTROL || exit 0
 
RETVAL=0
set -e
 
[ -f /etc/default/${NAME} ] && . /etc/default/${NAME}
 
ensure_pid_dir () {
    PID_DIR=`dirname ${PID_FILE}`
    if [ ! -d ${PID_DIR} ] ; then
        mkdir -p ${PID_DIR}
        chown -R ${USER}:${USER} ${PID_DIR}
        chmod 755 ${PID_DIR}
    fi
}
 
remove_pid () {
    rm -f ${PID_FILE}
    rmdir `dirname ${PID_FILE}` || :
}
 
start_rabbitmq () {
    status_rabbitmq quiet
    if [ $RETVAL = 0 ] ; then
        echo RabbitMQ is currently running
    else
        RETVAL=0
        ensure_pid_dir
        set +e
        RABBITMQ_PID_FILE=$PID_FILE $START_PROG $DAEMON \
            > "${INIT_LOG_DIR}/startup_log" \
            2> "${INIT_LOG_DIR}/startup_err" \
            0<&- &
        $CONTROL wait $PID_FILE >/dev/null 2>&1
        RETVAL=$?
        set -e
        case "$RETVAL" in
            0)
                echo SUCCESS
                if [ -n "$LOCK_FILE" ] ; then
                    touch $LOCK_FILE
                fi
                ;;
            *)
                remove_pid
                echo FAILED - check ${INIT_LOG_DIR}/startup_\{log, _err\}
                RETVAL=1
                ;;
        esac
    fi
}
 
stop_rabbitmq () {
    status_rabbitmq quiet
    if [ $RETVAL = 0 ] ; then
        set +e
        $CONTROL stop ${PID_FILE} > ${INIT_LOG_DIR}/shutdown_log 2> ${INIT_LOG_DIR}/shutdown_err
        RETVAL=$?
        set -e
        if [ $RETVAL = 0 ] ; then
            remove_pid
            if [ -n "$LOCK_FILE" ] ; then
                rm -f $LOCK_FILE
            fi
        else
            echo FAILED - check ${INIT_LOG_DIR}/shutdown_log, _err
        fi
    else
        echo RabbitMQ is not running
        RETVAL=0
    fi
}
 
status_rabbitmq() {
    set +e
    if [ "$1" != "quiet" ] ; then
        $CONTROL status 2>&1
    else
        $CONTROL status > /dev/null 2>&1
    fi
    if [ $? != 0 ] ; then
        RETVAL=3
    fi
    set -e
}
 
rotate_logs_rabbitmq() {
    set +e
    $CONTROL rotate_logs ${ROTATE_SUFFIX}
    if [ $? != 0 ] ; then
        RETVAL=1
    fi
    set -e
}
 
restart_running_rabbitmq () {
    status_rabbitmq quiet
    if [ $RETVAL = 0 ] ; then
        restart_rabbitmq
    else
        echo RabbitMQ is not runnning
        RETVAL=0
    fi
}
 
restart_rabbitmq() {
    stop_rabbitmq
    start_rabbitmq
}
 
case "$1" in
    start)
        echo -n "Starting $DESC: "
        start_rabbitmq
        echo "$NAME."
        ;;
    stop)
        echo -n "Stopping $DESC: "
        stop_rabbitmq
        echo "$NAME."
        ;;
    status)
        status_rabbitmq
        ;;
    rotate-logs)
        echo -n "Rotating log files for $DESC: "
        rotate_logs_rabbitmq
        ;;
    force-reload|reload|restart)
        echo -n "Restarting $DESC: "
        restart_rabbitmq
        echo "$NAME."
        ;;
    try-restart)
        echo -n "Restarting $DESC: "
        restart_running_rabbitmq
        echo "$NAME."
        ;;
    *)
        echo "Usage: $0 {start|stop|status|rotate-logs|restart|condrestart|try-restart|reload|force-reload}" >&2
        RETVAL=1
        ;;
esac
 
exit $RETVAL
```
```bash
# 添加到开机自检测
$ chkconfig --add rabbitmq-server
$ chkconfig rabbitmq-server on
$ chkconfig --list

# 关闭命令及删除命令
$ chkconfig rabbitmq-server off
$ chkconfig --del rabbitmq-server
```