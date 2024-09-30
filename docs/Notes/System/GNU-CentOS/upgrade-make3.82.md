## 一. 安装说明

CentOS 默认的 `GNU Make` 版本较低，无法进行编译升级 GLIBC
- Linux 系统：Centos7.9 x86_64
- Make 版本：GNU Make 3.82

```sh
$ make -v
GNU Make 3.82
Built for x86_64-redhat-linux-gnu
Copyright (C) 2010  Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
```

## 二. 编译安装

1）到 [*gnu*](https://ftp.gnu.org/pub/gnu/make/) 下载安装包

```sh
$ wget https://ftp.gnu.org/pub/gnu/make/make-4.4.tar.gz --no-check-certificate
```

2）解压编译安装，并验证版本

```sh
$ tar -xf make-4.4.tar.gz ; cd make-4.4
$ ./configure --prefix=/usr
$ type make;make check;make install
$ make -v
GNU Make 4.4
Built for x86_64-pc-linux-gnu
Copyright (C) 1988-2022 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <https://gnu.org/licenses/gpl.html>
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
```