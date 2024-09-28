> RockyLinux 修改 SSH 默认端口后，无法正常启动

**问题分析**

将原默认端口 22 修改成任意端口，且开启新端口后，无法重启相关服务和报错；

```sh
# 修改端口并开启端口放行
$ vim /etc/ssh/sshd_config
Port 12345

$ firewall-cmd --zone=public --add-port=12345/tcp --permanent
$ firewall-cmd --reload
```

```sh
$ systemctl restart sshd
Job for sshd.service failed because the control process exited with error code.
See "systemctl status sshd.service" and "journalctl -xeu sshd.service" for details.
```

根据提示查看服务状态及日志情况

```sh
$ systemctl status sshd
● sshd.service - OpenSSH server daemon
     Loaded: loaded (/usr/lib/systemd/system/sshd.service; enabled; preset: enabled)
     Active: activating (auto-restart) (Result: exit-code) since Thu 2024-08-29 15:43:08 CST; 9s ago
       Docs: man:sshd(8)
             man:sshd_config(5)
    Process: 4648 ExecStart=/usr/sbin/sshd -D $OPTIONS (code=exited, status=255/EXCEPTION)
   Main PID: 4648 (code=exited, status=255/EXCEPTION)
        CPU: 17ms

$ journalctl -u sshd.service
...
Aug 29 15:43:08 pbe.101.rocky systemd[1]: Starting OpenSSH server daemon...
Aug 29 15:43:08 pbe.101.rocky sshd[4648]: error: Bind to port 12345 on 0.0.0.0 failed: Permission denied.
Aug 29 15:43:08 pbe.101.rocky sshd[4648]: error: Bind to port 12345 on :: failed: Permission denied.
Aug 29 15:43:08 pbe.101.rocky systemd[1]: sshd.service: Main process exited, code=exited, status=255/EXCEPTION
Aug 29 15:43:08 pbe.101.rocky sshd[4648]: fatal: Cannot bind any address.
Aug 29 15:43:08 pbe.101.rocky systemd[1]: sshd.service: Failed with result 'exit-code'.
Aug 29 15:43:08 pbe.101.rocky systemd[1]: Failed to start OpenSSH server daemon.
```

通过日志发现 `error: Bind to port 12345 on 0.0.0.0 failed: Permission denied` 权限不足

**解决方法**

排除防火墙问题，系统默认开启的 Selinux，尝试关闭重启服务测试

```sh
$ setenforce 0
$ systemctl restart sshd.service
$ systemctl status sshd.service
● sshd.service - OpenSSH server daemon
     Loaded: loaded (/usr/lib/systemd/system/sshd.service; enabled; preset: enabled)
     Active: active (running) since Thu 2024-08-29 16:09:42 CST; 20min ago
       Docs: man:sshd(8)
             man:sshd_config(5)
   Main PID: 1472 (sshd)
      Tasks: 1 (limit: 23152)
     Memory: 3.4M
        CPU: 63ms
     CGroup: /system.slice/sshd.service
             └─1472 "sshd: /usr/sbin/sshd -D [listener] 0 of 10-100 startups"

Aug 29 16:09:42 pbe.101.rocky systemd[1]: Starting OpenSSH server daemon...
Aug 29 16:09:42 pbe.101.rocky sshd[1472]: Server listening on 0.0.0.0 port 12345.
Aug 29 16:09:42 pbe.101.rocky sshd[1472]: Server listening on :: port 12345.
Aug 29 16:09:42 pbe.101.rocky systemd[1]: Started OpenSSH server daemon.
```

通过 `setenforce 1` 临时关闭测试得出，原因为 Selinux 限制导致，永久关闭

```sh
$ sed -i 's/SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
```
