> RabbitMQ 启动报错，缺少 Erlang

**问题描述**：在使用命令 `systemctl daemon-reload && systemctl enable --now rabbitmq-server` 启动 Rabbitmq 时报错

```bash
$ systemctl daemon-reload && systemctl enable --now rabbitmq-server
Created symlink from /etc/systemd/system/multi-user.target.wants/rabbitmq-server.service to /etc/systemd/system/rabbitmq-server.service.
Job for rabbitmq-server.service failed because the control process exited with error code. See "systemctl status rabbitmq-server.service" and "journalctl -xe" for details.
```

根据上述错误信息，使用 `journalctl -xe` 命令查看启动失败日志：

```bash
# 通过问题描述，发现是 rabbitmq-server 文件第 73 没有找到 erlang
Apr 21 18:05:55 rabbitmq systemd[1]: Starting RabbitMQ broker...
-- Subject: Unit rabbitmq-server.service has begun start-up
-- Defined-By: systemd
-- Support: http://lists.freedesktop.org/mailman/listinfo/systemd-devel
-- 
-- Unit rabbitmq-server.service has begun starting up.
Apr 21 18:05:55 rabbitmq rabbitmq-server[54795]: /opt/rabbitmq/sbin/rabbitmq-server: line 73: exec: erl: not found
Apr 21 18:05:55 rabbitmq systemd[1]: rabbitmq-server.service: main process exited, code=exited, status=127/n/a
Apr 21 18:05:55 rabbitmq systemd[1]: Failed to start RabbitMQ broker.
-- Subject: Unit rabbitmq-server.service has failed
-- Defined-By: systemd
-- Support: http://lists.freedesktop.org/mailman/listinfo/systemd-devel
-- 
-- Unit rabbitmq-server.service has failed.
```

**解决方法**：在 rabbitmq-server 文件第 73行前添加 erlang 的环境变量

```bash
    check_start_params
    # 在73行前增加erlang的环境变量
    export PATH=/opt/erlang/bin:$PATH
    exec erl \
        -pa "$RABBITMQ_SERVER_CODE_PATH" \
        ${RABBITMQ_START_RABBIT} \
        -boot "${SASL_BOOT_FILE}" \
        +W w \
        ${RABBITMQ_DEFAULT_ALLOC_ARGS} \
        ${RABBITMQ_SERVER_ERL_ARGS} \
        ${RABBITMQ_SERVER_ADDITIONAL_ERL_ARGS} \
        ${RABBITMQ_SERVER_START_ARGS} \
        -syslog logger '[]' \
        -syslog syslog_error_logger false \
        -kernel prevent_overlapping_partitions false \
        "$@"
}
```

然后执行启动命令，再查看 rabbitmq 状态

```bash
$ systemctl status rabbitmq-server
● rabbitmq-server.service - RabbitMQ broker
   Loaded: loaded (/etc/systemd/system/rabbitmq-server.service; enabled; vendor preset: disabled)
   Active: active (running) since Fri 2022-04-22 09:20:53 CST; 11min ago
  Process: 2080 ExecStop=/opt/rabbitmq/sbin/rabbitmqctl shutdown (code=exited, status=127)
 Main PID: 2088 (beam.smp)
   CGroup: /system.slice/rabbitmq-server.service
           ├─2088 /opt/erlang/lib/erlang/erts-12.2/bin/beam.smp -W w -MBas ageffcbf -MHas ageffcbf -MBlmbcs 512 -MHlmbcs 512 -MMmcs 30 -P 1048576 -t 5000000 -stbt db ...
           ├─2099 erl_child_setup 32768
           ├─2129 /opt/erlang/lib/erlang/erts-12.2/bin/epmd -daemon
           ├─2156 inet_gethost 4
           └─2157 inet_gethost 4
...
Apr 22 09:20:53 rabbitmq systemd[1]: Started RabbitMQ broker.

$ ss -lntp|grep 5672
LISTEN     0      128          *:25672                    *:*                   users:(("beam.smp",pid=2088,fd=18))
LISTEN     0      128       [::]:5672                  [::]:*                   users:(("beam.smp",pid=2088,fd=33))
```