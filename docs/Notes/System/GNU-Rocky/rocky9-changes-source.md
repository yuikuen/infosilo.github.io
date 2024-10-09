> Rocky Linux 更换国内镜像源

Rocky Linux 9 最小化安装默认 repo

```sh
$ dnf repolist
repo id                                               repo name
appstream                                             Rocky Linux 9 - AppStream
baseos                                                Rocky Linux 9 - BaseOS
extras                                                Rocky Linux 9 - Extras

$ ll /etc/yum.repos.d/
total 20
-rw-r--r--. 1 root root 6610 May  1 08:29 rocky-addons.repo
-rw-r--r--. 1 root root 1165 May  1 08:29 rocky-devel.repo
-rw-r--r--. 1 root root 2387 May  1 08:29 rocky-extras.repo
-rw-r--r--. 1 root root 3417 May  1 08:29 rocky.repo
```

## 一. 官方镜像

官方镜像列表：<https://mirrors.rockylinux.org/mirrormanager/mirrors>，CN 开头的站点

## 二. 配置方法

### 2.1 基本源

将系统的镜像源改为国内镜像源

```sh
$ sed -e 's|^mirrorlist=|#mirrorlist=|g' \
    -e 's|^#baseurl=http://dl.rockylinux.org/$contentdir|baseurl=https://mirrors.zju.edu.cn/rocky|g' \
    -i.bak \
    /etc/yum.repos.d/[Rr]ocky*.repo
```

更换其它镜像源，则将对应的 `Mirror Name` 替换即可（恢复同理操作），另外注意路径 `/rocky`，如阿里云镜像则是 `rockylinux`

**常用地址源**

- 阿里云：mirrors.aliyun.com/rockylinux

- 上交大：mirror.sjtu.edu.cn/rocky

- 南京大：mirror.nju.edu.cn/rocky

- 淅江大：mirrors.zju.edu.cn/rocky

- 中科大：mirrors.ustc.edu.cn/rocky

### 2.2 EPEL

启用并安装 EPEL Repo

```sh
$ dnf config-manager --set-enabled crb
$ dnf install epel-release
```

将 repo 配置中的地址替换为淅江大镜像站地址

> 新版本会多一个 epel-cisco-openh264.repo，国内镜像站暂无 `Cisco OpenH264` 仓库

```sh
# 执行语句中，过滤掉 epel-cisco-openh264.repo
$ sed -e 's!^metalink=!#metalink=!g' \
    -e 's!^#baseurl=!baseurl=!g' \
    -e 's!https\?://download\.fedoraproject\.org/pub/epel!https://mirrors.zju.edu.cn/epel!g' \
    -e 's!https\?://download\.example/pub/epel!https://mirrors.zju.edu.cn/epel!g' \
    -i /etc/yum.repos.d/epel{,-testing}.repo
```

更新仓库缓存

```sh
$ dnf clean all 
$ dnf makecache
```

### 2.3 恢复更换

有时因区域问题，可能会导致某些软件包未能成功下载，可尝试更换源处理

```sh
# 将国内镜像源恢复默认，再将地址改为阿里云
$ sed -e 's|^#mirrorlist=|mirrorlist=|g' \
    -e 's|^baseurl=https://mirrors.zju.edu.cn/rocky|#baseurl=http://dl.rockylinux.org/$contentdir|g' \
    -i.bak \
    /etc/yum.repos.d/[Rr]ocky*.repo

$ sed -e 's|^mirrorlist=|#mirrorlist=|g' \
    -e 's|^#baseurl=http://dl.rockylinux.org/$contentdir|baseurl=https://mirrors.aliyun.com/rockylinux|g' \
    -i.bak \
    /etc/yum.repos.d/[Rr]ocky*.repo

# EPEL 同理更换
$ sed -e 's|^#metalink=|metalink=|g' \
    -e 's|^baseurl=https://mirrors.zju.edu.cn|#baseurl=https://download.example/pub|g' \
    -i.bak \
    /etc/yum.repos.d/epel{,-testing}.repo

$ sed -e 's|^metalink=|#metalink=|g' \
    -e 's|^#baseurl=https://download.example/pub|baseurl=https://mirrors.aliyun.com|g' \
    -i.bak \
    /etc/yum.repos.d/epel{,-testing}.repo
```

**参考链接**

Rocky Linux yum/dnf repo/mirrors 国内镜像列表及更换方法：<https://www.cnblogs.com/sysin/p/18256194>
