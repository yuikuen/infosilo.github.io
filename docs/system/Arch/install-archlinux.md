**Arch Linux** 是一款基于 x86-64 架构的 Linux 发行版，系统安装、删除和更新软件的软件包管理器叫做 **pacman**。系统安装映像只简单地包含系统主要组件，采用滚动发行模式来获取系统更新和软件的最新版本，以社区 Wiki 的形式提供文档，简称为 [Arch Wiki](https://wiki.archlinux.org/)

## 一. 前期准备

1）**镜像下载** 主要有两个途径，一个是 Arch 官方提供的 [下载地址](https://archlinux.org/download/)，另外的是其它镜像站提供的下载地址，如 [阿里云镜像站](https://mirrors.aliyun.com/archlinux/)

2）**镜像烧录** 建议使用 Rufus 进行，过程自行度娘，镜像烧录步骤较为简单，在此不详细说明；

注：根据 Arch Wiki 介绍，Arch 是不支持安全启动的，而一般电脑默认开启安全启动，所以需要先到 BIOS 里面关闭安全启动( Secure Boot )，同时需要先关闭 Windows 的快速启动

## 二. 网络设置

> 安装过程需要安装各种服务、组件，网络是必须的

1）确认网卡是否被禁用，使用以下命令解除网卡禁用

```sh
$ rfkill list
$ rfkill unblock all
```

2）连接网络，使用 iwctl 工具扫描并进行连接

```sh
$ iwctl
-------------下面为iwctl界面，不同于终端-----------
[iwd] help                                     // 输入help回车可以查看使用说明
[iwd] device list                              // 回车后可以查看当前网卡设备，一般为 wlan0
[iwd] station <device> scan                    // <device>替换为上面的网卡设备，这条命令可以让网卡扫描wifi设备
[iwd] station <device> get-networks            // 会车后可以显示当前可连接网络
[iwd] station <device> connect <wifi name>     // 连接wifi, <wifi name> 为上面获取的wifi名称
password:                                      // 如果wifi为加密wifi,输入密码回车
[iwd] quit                                     // 退出 wifi 连接界面
```
