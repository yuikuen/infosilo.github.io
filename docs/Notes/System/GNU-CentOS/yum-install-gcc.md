## 一. 前言

CentOS7 官方源的 gcc 最新版本是 4.8.5，对于新的项目只能升级现有版本，而升级的方法有两种：手动编译和源安装

```sh
$ hostnamectl
   Static hostname: pbe.4111-cluster01
         Icon name: computer-vm
           Chassis: vm
        Machine ID: b0e9ca883f1c428da99e0177883fddb5
           Boot ID: 595c891d40b14d09a6831218de5a599c
    Virtualization: kvm
  Operating System: CentOS Linux 7 (Core)
       CPE OS Name: cpe:/o:centos:centos:7
            Kernel: Linux 6.2.12-1.el7.elrepo.x86_64
      Architecture: x86-64

$ cat /etc/redhat-release 
CentOS Linux release 7.9.2009 (Core)

$ gcc -v
gcc version 4.8.5 20150623 (Red Hat 4.8.5-44) (GCC)
```

## 二. 安装

1）安装依赖并确认需要安装的版本文件

```sh
$ yum install -y centos-release-scl

# 列出现Gcc版本
$ yum list |grep devtoolset |grep gcc.x86_64
devtoolset-10-gcc.x86_64                   10.2.1-11.2.el7        centos-sclo-rh
devtoolset-11-annobin-plugin-gcc.x86_64    10.38-1.el7            centos-sclo-rh
devtoolset-11-gcc.x86_64                   11.2.1-9.1.el7         centos-sclo-rh
devtoolset-7-gcc.x86_64                    7.3.1-5.16.el7         centos-sclo-rh
devtoolset-8-gcc.x86_64                    8.3.1-3.2.el7          centos-sclo-rh
devtoolset-9-gcc.x86_64                    9.3.1-2.2.el7          centos-sclo-rh

$ yum install -y devtoolset-8-gcc*
$ yum install -y devtoolset-9-gcc*
```

> 软件包可同时安装，其不会相互覆盖或冲突

```sh
$ rpm -qa |grep devtoolset
...
devtoolset-9-gcc-9.3.1-2.2.el7.x86_64
devtoolset-8-gcc-8.3.1-3.2.el7.x86_64
```

2）因为不会覆盖系统默认的 gcc，可使用不同方式来加载使用

- 绝对路径

```sh
$ rpm -ql devtoolset-8-gcc-8.3.1-3.2.el7.x86_64
/opt/rh/devtoolset-8/root/usr/bin/cc
...
$ gcc -v
gcc version 4.8.5 20150623 (Red Hat 4.8.5-44) (GCC) 
# 并存两个版本，以绝对路径方式调用
$ /opt/rh/devtoolset-8/root/usr/bin/gcc -v
gcc version 8.3.1 20190311 (Red Hat 8.3.1-3) (GCC) 
```

- 添加可执行文件路径到 PATH 环境变量，常规操作：永久生效

```sh
$ mv /usr/bin/gcc /usr/bin/gcc-4.8.5
$ ln -s /opt/rh/devtoolset-8/root/bin/gcc /usr/bin/gcc
$ echo "source /opt/rh/devtoolset-8/enable" >>/etc/profile
```

- 官方推荐的加载命令

> 注意：只对当前终端生效

```sh
$ scl enable devtoolset-8 bash
$ gcc -v
gcc version 8.3.1 20190311 (Red Hat 8.3.1-3) (GCC)
```

- 执行安装软件自带的脚本

```sh
# x为需要启动的版本
$ source /opt/rh/devtoolset-x/enable
$ gcc -v
gcc version 9.3.1 20200408 (Red Hat 9.3.1-2) (GCC)
```

**问题记录：虽然已更新了 Gcc，但在运行某些程序时，还是会提示以下报错，只能采用 `手动编译` 的方法了，详情请查看[CentOS_升级Gcc+Glibc](../centos_升级gcc-glibc)**

```sh
****: /lib64/libc.so.6: version GLIBC_2.28' not found (required by ./****)
****: /lib64/libstdc++.so.6: version `GLIBCXX_3.4.21' not found (required by ./****)
```

```sh
$ find / -name 'libstdc++.so.6*'
/usr/lib64/libstdc++.so.6
/usr/lib64/libstdc++.so.6.0.19
/usr/share/gdb/auto-load/usr/lib64/libstdc++.so.6.0.19-gdb.py
/usr/share/gdb/auto-load/usr/lib64/libstdc++.so.6.0.19-gdb.pyc
/usr/share/gdb/auto-load/usr/lib64/libstdc++.so.6.0.19-gdb.pyo

$ strings /usr/lib64/libstdc++.so.6 | grep 'CXXABI'
CXXABI_1.3
CXXABI_1.3.1
CXXABI_1.3.2
CXXABI_1.3.3
CXXABI_1.3.4
CXXABI_1.3.5
CXXABI_1.3.6
CXXABI_1.3.7
CXXABI_TM_1

$ strings /usr/lib64/libstdc++.so.6 | grep GLIBC 
GLIBCXX_3.4
GLIBCXX_3.4.1
GLIBCXX_3.4.2
GLIBCXX_3.4.3
GLIBCXX_3.4.4
GLIBCXX_3.4.5
GLIBCXX_3.4.6
GLIBCXX_3.4.7
GLIBCXX_3.4.8
GLIBCXX_3.4.9
GLIBCXX_3.4.10
GLIBCXX_3.4.11
GLIBCXX_3.4.12
GLIBCXX_3.4.13
GLIBCXX_3.4.14
GLIBCXX_3.4.15
GLIBCXX_3.4.16
GLIBCXX_3.4.17
GLIBCXX_3.4.18
GLIBCXX_3.4.19
GLIBC_2.3
GLIBC_2.2.5
GLIBC_2.14
GLIBC_2.4
GLIBC_2.3.2
GLIBCXX_DEBUG_MESSAGE_LENGTH

$ strings /usr/local/lib64/libstdc++.so.6.0.21 | grep 'CXXABI'
strings: '/usr/local/lib64/libstdc++.so.6.0.21': No such file
```