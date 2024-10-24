> PVE-7.x 更换镜像源

镜像源选择：

- [Debian 软件仓库镜像使用帮助](https://mirrors.tuna.tsinghua.edu.cn/help/debian/)

- [Proxmox 软件仓库镜像使用帮助](https://mirrors.tuna.tsinghua.edu.cn/help/proxmox/)

## 一. 更换软件源

一般情况下，将 `/etc/apt/sources.list` 文件中 Debian 默认的源地址 `http://deb.debian.org/` 替换为镜像地址即可

1）首先备份 PVE 原始的官方源

```sh
$ mv /etc/apt/sources.list /etc/apt/sources.list.bak
```

2）注释默认源并添加国内 Debian 软件源

PS：具体可参考 `Debian 软件仓库镜像使用帮助`，内有详细说明，参考如下：

```sh
# 默认注释了源码镜像以提高 apt update 速度，如有需要可自行取消注释
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye main contrib non-free
deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye main contrib non-free

deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye-updates main contrib non-free
deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye-updates main contrib non-free

deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye-backports main contrib non-free
deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye-backports main contrib non-free

# deb https://mirrors.tuna.tsinghua.edu.cn/debian-security bullseye-security main contrib non-free
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian-security bullseye-security main contrib non-free

deb https://security.debian.org/debian-security bullseye-security main contrib non-free
deb-src https://security.debian.org/debian-security bullseye-security main contrib non-free
```

## 二. 更换 PVE 源

```sh
$ vi /etc/apt/sources.list.d/pve-enterprise.list
#deb https://enterprise.proxmox.com/debian/pve bullseye pve-enterprise
```

屏蔽企业源

```sh
$ vi /etc/apt/sources.list.d/pve-no-subscription.list
deb https://mirrors.tuna.tsinghua.edu.cn/proxmox/debian/pve bullseye pve-no-subscription
```

## 三. CT Templates

如果你需要加速 Proxmox 网页端下载 CT Templates，可以替换 CT Templates 的源。

具体方法：将 `/usr/share/perl5/PVE/APLInfo.pm` 文件中默认的源地址 `http://download.proxmox.com` 替换为

```sh
https://mirrors.tuna.tsinghua.edu.cn/proxmox
```

可以使用如下命令修改：

```sh
$ cp /usr/share/perl5/PVE/APLInfo.pm /usr/share/perl5/PVE/APLInfo.pm_back
$ sed -i 's|http://download.proxmox.com|https://mirrors.tuna.tsinghua.edu.cn/proxmox|g' /usr/share/perl5/PVE/APLInfo.pm
```

针对 `/usr/share/perl5/PVE/APLInfo.pm` 文件的修改，重启后生效。