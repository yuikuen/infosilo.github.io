!!! info "问题场景"
    PVE 的虚拟机在使用过程中，偶尔会出现虚拟机假死或无法关闭的情况，并提示 `TASK ERROR: VM quit/powerdown failed – got timeout` 显示关闭退出无反应、超时等

**解决方案**

进入 PVE 管理后台，点击 Shell 控制台，通过 PS 命令查找对应虚拟机的 VM 进程号并 `kill`

```sh
# 将 id 号换成需要关闭的虚拟机
$ ps -ef | grep "/usr/bin/kvm -id 100" | grep -v grep
$ kill -9 ${PID}
```
