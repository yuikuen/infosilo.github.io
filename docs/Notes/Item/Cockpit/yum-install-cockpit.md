> [Cockpit](https://cockpit-project.org/running.html) 是一款基于 Web 的可视化管理工具，对一些常见的命令行管理操作都有界面支持，比如用户管理、防火墙管理、服务器资源监控等

测试环境为 CentOS 7 版本，此外 Cockpit 还支持其他 Linux 发行版，请自行体验；
另程序可根据需要进行[扩展](https://cockpit-project.org/applications.html)，实现各应用监控

## 一. 程序安装

1）Cockpit 安装(具体功能介绍请参考官网)

```bash
$ yum install -y cockpit cockpit-storaged cockpit-networkmanager cockpit-packagekit cockpit-ostree cockpit-machines cockpit-podman cockpit-selinux cockpit-kdump cockpit-sosreport cockpit-docker cockpit-dashboard
```

可自行安装其他扩展来实现功能

```bash
$ yum install -y cockpit-composer cockpit-certificates cockpit-389-ds cockpit-session-recording cockpit-subscriptions cockpit-ovirt-dashboard cockpit-zfs
```

2）启动程序并开放服务

```bash
$ systemctl enable --now cockpit.socket
$ firewall-cmd --permanent --zone=public --add-service=cockpit
$ firewall-cmd --reload
```

3）浏览器访问 9090 端口测试

![](https://img.17121203.xyz/i/2024/09/29/qgrzb6-0.webp)

用户名和密码就是 linux 服务器的用户名和密码，登陆即可进入首页

## 二. 功能介绍

![](https://img.17121203.xyz/i/2024/09/29/qgv5vd-0.webp)

- 仪表盘：其他服务器也安装 Cockpit，可将机器添加到监控列表
- 网络监控：可配置防火墙，开放或禁止服务、端口等功能
- 虚拟容器：运行镜像以及拉取新镜像
- 还有更多的功能，在此就不再逐一介绍，请自行搭建体验。