由于自带的软件源速度较慢，此处选择科大源：https://mirrors.ustc.edu.cn 或 清华源：https://mirrors4.tuna.tsinghua.edu.cn；涉入的软件源有三个，分别为 debian、pve、ceph，需要分别修改以下文件。

PS：提前备份相关配置文件

| 名称 | source 文件路径 |
|--|--|
|debian|`/etc/apt/sources.list`|
|pve|`/etc/apt/sources.list.d/pve-no-subscription.list`|
|ceph|`/etc/apt/sources.list.d/ceph.list`|

通过 Web 管理平台中的 Shell 登录后台操作

## 一. 更换 Debian 源

```sh
$ cp /etc/apt/sources.list /etc/apt/sources.list.back
$ vi /etc/apt/sources.list
# 注释所有内容，文末添加
deb http://mirrors.ustc.edu.cn/debian bookworm main contrib non-free non-free-firmware
deb http://mirrors.ustc.edu.cn/debian bookworm-updates main contrib non-free non-free-firmware
deb http://mirrors.ustc.edu.cn/debian bookworm-backports main contrib non-free non-free-firmware
deb http://mirrors.ustc.edu.cn/debian-security/ bookworm-security main contrib non-free non-free-firmware
```

## 二. 修改企业源

```sh
$ cp /etc/apt/sources.list.d/pve-enterprise.list /etc/apt/sources.list.d/pve-enterprise.list.back
$ vim /etc/apt/sources.list.d/pve-enterprise.list
# 注释所有内容，文末添加
deb https://mirrors.ustc.edu.cn/proxmox/debian/pve bookworm pve-no-subscription
```

添加 PVE 无订阅源

```sh
$ vi /etc/apt/sources.list.d/pve-no-subscription.list
deb https://mirrors.ustc.edu.cn/proxmox/debian/pve bookworm pve-no-subscription
```

## 三. 修改 Ceph 源

```sh
$ cp /etc/apt/sources.list.d/ceph.list /etc/apt/sources.list.d/ceph.list.back
$ vim /etc/apt/sources.list.d/ceph.list
# 注释所有内容，文末添加
deb https://mirrors.ustc.edu.cn/proxmox/debian/ceph-quincy bookworm no-subscription
```

## 四. CT Templates

另外，如需要加速下载 CT Templates，可替换相关源文件

```sh
$ cp /usr/share/perl5/PVE/APLInfo.pm /usr/share/perl5/PVE/APLInfo.pm_back
$ sed -i 's|http://download.proxmox.com|https://mirrors.ustc.edu.cn/proxmox|g' /usr/share/perl5/PVE/APLInfo.pm
```

最后确保所有更换的源文件生效，作重启 PVE 处理，重启后可按需更新

```sh
$ apt update -y; apt upgrade -y
```