> CentOS7 升级 OpenSSL3.0.3

默认版本是提示版本过低，无法编译 OpenLDAP，故需升级操作

```sh
$ openssl version
OpenSSL 1.0.2k-fips  26 Jan 2017
```

安装 IPC/cmd.pm 模块，openssl-3.0 编译需要

```sh
$ yum install perl-IPC-Cmd perl-Data-Dumper perl-Test-Taint
$ tar -xf openssl-3.0.3.tar.gz && cd openssl-3.0.3
$ ./config
$ make && make install
```

编译安装完后，检查是否缺少库

```sh
$ ldd /usr/local/bin/openssl 
        linux-vdso.so.1 =>  (0x00007ffeca3f7000)
        libssl.so.3 => not found
        libcrypto.so.3 => not found
        libdl.so.2 => /lib64/libdl.so.2 (0x00007f3f1fe9c000)
        libpthread.so.0 => /lib64/libpthread.so.0 (0x00007f3f1fc80000)
        libc.so.6 => /lib64/libc.so.6 (0x00007f3f1f8b3000)
        /lib64/ld-linux-x86-64.so.2 (0x00007f3f200a0000)
```

将安装的库引入，创建备份并链接新版本

```sh
$ echo "/usr/local/lib64/" > /etc/ld.so.conf.d/openssl3.0.3.conf
$ ldconfig -v

$ mkdir -p /usr/bakup/usr/bin
$ mv /usr/bin/openssl /usr/bakup/usr/bin/
$ ln -s /usr/local/bin/openssl /usr/bin/openssl

# 再次检查版本
$ openssl version
```