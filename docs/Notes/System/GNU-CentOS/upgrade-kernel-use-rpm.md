> 过旧的内核可能已不再维护或有安全漏洞等问题，并且部署环境/程序也有不兼容的情况
>
> PS：**更新内核是有风险的，在操作之前慎重，严谨在生产环境上操作**

1）到 [ELREPO](https://elrepo.org/linux/kernel/) 下载自身需要的 RPM 包

> 实际生产环境一般需要指定内核版本，并且无法联网安装，这时需提前下载 [RPM 包](http://elrepo.org/linux/kernel/el7/x86_64/RPMS/) 进行安装

```sh
$ wget https://elrepo.org/linux/kernel/el7/x86_64/RPMS/kernel-ml-6.1.11-1.el7.elrepo.x86_64.rpm
$ wget https://elrepo.org/linux/kernel/el7/x86_64/RPMS/kernel-ml-devel-6.1.11-1.el7.elrepo.x86_64.rpm
```

如上述下载较慢可选择 [清华大学 rpm 源](https://mirrors.tuna.tsinghua.edu.cn/elrepo/kernel/el7/x86_64/RPMS/) 下载所需的内核升级 rpm 包，一般下载 kernel-ml 和 kernel-ml-devel 即可

```sh
$ wget https://mirrors.tuna.tsinghua.edu.cn/elrepo/kernel/el7/x86_64/RPMS/kernel-ml-6.1.11-1.el7.elrepo.x86_64.rpm --no-check-certificate
$ wget https://mirrors.tuna.tsinghua.edu.cn/elrepo/kernel/el7/x86_64/RPMS/kernel-ml-devel-6.1.11-1.el7.elrepo.x86_64.rpm --no-check-certificate
```

2）下载后直接加载安装

```sh
$ ls -al
-rw-r--r--.  1 root root 62903796 Feb  9 20:05 kernel-ml-6.1.11-1.el7.elrepo.x86_64.rpm
-rw-r--r--.  1 root root 15052848 Feb  9 20:05 kernel-ml-devel-6.1.11-1.el7.elrepo.x86_64.rpm

$ rpm -ivh kernel-ml-6.1.11-1.el7.elrepo.x86_64.rpm kernel-ml-devel-6.1.11-1.el7.elrepo.x86_64.rpm --nodeps --force
warning: kernel-ml-6.1.11-1.el7.elrepo.x86_64.rpm: Header V4 DSA/SHA256 Signature, key ID baadae52: NOKEY
Preparing...                          ################################# [100%]
Updating / installing...
   1:kernel-ml-devel-6.1.11-1.el7.elre################################# [ 50%]
   2:kernel-ml-6.1.11-1.el7.elrepo    ################################# [100%]
```

3）配置内核，查看现有内核版本

```sh
$ awk -F\' '$1=="menuentry " {print i++ " : " $2}' /etc/grub2.cfg
0 : CentOS Linux (6.1.11-1.el7.elrepo.x86_64) 7 (Core)
1 : CentOS Linux (3.10.0-1160.el7.x86_64) 7 (Core)
2 : CentOS Linux (0-rescue-5ad1beefc86b458a8e9b19dd5a4cbca9) 7 (Core)
```

如果提示如下错误可执行下面语句进行修复，没则请跳过

```sh
awk: fatal: cannot open file `/etc/grub2.cfg' for reading (No such file or directory)
# 执行下述语句进行修复
$ grub2-mkconfig -o /boot/grub2/grub.cfg
```

4）将序号 0 的设置为密码的启动项并重新加载、重启服务器

```sh
$ grub2-set-default 0
$ grub2-mkconfig -o /boot/grub2/grub.cfg && reboot now
```

5）卸载旧内核，**非必要，可自行选择**

```sh
$ rpm -qa | grep kernel
$ yum -y remove $(rpm -qa | grep kernel | grep '3')
```

**内核相关包说明**

- kernel-lt [The Linux kernel. (The core of any Linux-based operating system.)]
  - 最核心的包，所有Linux系统的基础
- kernel-lt-devel [Development package for building kernel modules to match the kernel.]
  - 内核开发包，更多是提供给内核开发人员开发内核的一些功能模块
- kernel-lt-doc [Various bits of documentation found in the kernel sources.]
  - 内核包的指引文档
- kernel-lt-headers [Header files of the kernel, for use by glibc.]
  - 内核的头文件，一般其他应用需要调用内核能力就要引入这些头文件
- kernel-lt-tools [Assortment of tools for the kernel.]
  - 内核级别的一些工具
- kernel-lt-tools-libs [Libraries for the kernel tools.]
  - 内核级别工具所依赖的包
- kernel-lt-tools-libs-devel [Development package for the kernel tools libraries.]
  - 内核级别工具开发所需的依赖包