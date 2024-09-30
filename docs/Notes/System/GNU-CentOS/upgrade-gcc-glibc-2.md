> 安装前请注意版本兼容性问题，首选稳定版本

## 一. 安装说明

CentOS 7 官方源的 Gcc 最新版本目前还是 `4.8.5`，默认的 Gcc 版本无法编译 Glibc 2.28，而安装 Glibc 所需的依赖，需要 Gcc 4.9 以上及 Make 4.0 以下，另外 Gcc 11.2 版本太新，也无法与 Glibc 2.28 兼容。

- Sys-OS：CentOS Linux release 7.9.2009 (Core)
- Kernel：6.6.8-1.el7.elrepo.x86_64
- Make：GNU Make 4.4
- Gcc：gcc version 9.5.0 (GCC)
- Glibc：GLIBC_2.33
- Python：Python 3.6.15

PS：升级过程经多次安装测试，兼容性无问题

## 二. 升级 Gcc

安装依赖环境

> 默认最小化安装未含有 Gcc 环境，直接编译安装会报错

```sh
$ yum -y install bison wget bzip2 gcc gcc-c++ glibc-headers
$ wget https://ftp.gnu.org/gnu/gcc/gcc-9.5.0/gcc-9.5.0.tar.gz
$ tar -xf gcc-9.5.0.tar.gz; cd gcc-9.5.0
$ ./contrib/download_prerequisites
...
All prerequisites downloaded successfully.
```

备份旧版本文件，以防安装报错

```sh
$ whereis gcc g++
gcc: /usr/bin/gcc /usr/lib/gcc /usr/libexec/gcc /usr/share/man/man1/gcc.1.gz
g++: /usr/bin/g++ /usr/share/man/man1/g++.1.gz
$ cp -r /usr/bin/gcc /usr/bin/gcc_4.8.5
$ cp -r /usr/bin/g++ /usr/bin/g++_4.8.5
```

创建临时目录并进行编译安装

```sh
$ mkdir build && cd build
$ ../configure --enable-checking=release --enable-languages=c,c++ --disable-multilib --prefix=/usr
configure: creating ./config.status
config.status: creating Makefile
```

PS：如 `--prefix=/usr/local/gcc` 指定非系统目录，安装后需要重新软链(`ln -s`) gcc 和 g++

确认内核数可选择性加快编译

```sh
$ cat /proc/cpuinfo | grep "processor" | wc -l
16
$ nohup make -j8 >& make.log &
DO=all multi-do # make

$ make install
make[4]: Nothing to be done for `install-data-am'.
```

重启服务器并验证版本是否正确

```sh
$ init 6 
$ gcc -v
Using built-in specs.
COLLECT_GCC=gcc
COLLECT_LTO_WRAPPER=/usr/libexec/gcc/x86_64-pc-linux-gnu/9.5.0/lto-wrapper
Target: x86_64-pc-linux-gnu
Configured with: ../configure --enable-checking=release --enable-languages=c,c++ --disable-multilib --prefix=/usr
Thread model: posix
gcc version 9.5.0 (GCC)
```

**附加说明：**替换老版本 Gcc 动态库，如显示为新版本 3.4.28 则无需要操作

> Gcc 9.5.0 安装后动态库自动更新，但之前 Gcc 8.3.0 还是需要手动更新

```sh
$ strings /usr/lib64/libstdc++.so.6 | grep GLIBC
...
GLIBCXX_3.4.28

$ find / -name 'libstdc++.so.6*'
/usr/lib64/libstdc++.so.6.0.19
/usr/lib64/libstdc++.so.6
/usr/lib64/libstdc++.so.6.0.28

$ ls -l /usr/lib64/libstdc++.so*
lrwxrwxrwx. 1 root root       19 Dec 29 11:23 /usr/lib64/libstdc++.so -> libstdc++.so.6.0.28
lrwxrwxrwx. 1 root root       19 Dec 29 11:23 /usr/lib64/libstdc++.so.6 -> libstdc++.so.6.0.28
-rwxr-xr-x. 1 root root   995840 Sep 30  2020 /usr/lib64/libstdc++.so.6.0.19
-rwxr-xr-x. 1 root root 17714176 Dec 29 11:23 /usr/lib64/libstdc++.so.6.0.28
-rw-r--r--. 1 root root     2385 Dec 29 11:23 /usr/lib64/libstdc++.so.6.0.28-gdb.py
```

具体操作如下：

```sh
$ strings /usr/lib64/libstdc++.so.6 | grep GLIBC 
GLIBCXX_3.4.19

$ find / -name 'libstdc++.so.6*'
/usr/lib64/libstdc++.so.6.0.19
/usr/local/lib64/libstdc++.so.6.0.28

$ ls -l /usr/lib64/libstdc++.so*
lrwxrwxrwx. 1 root root     19 Dec 26 17:00 /usr/lib64/libstdc++.so.6 -> libstdc++.so.6.0.19
-rwxr-xr-x. 1 root root 995840 Sep 30  2020 /usr/lib64/libstdc++.so.6.0.19

$ cp /usr/local/lib64/libstdc++.so.6.0.28 /usr/lib64/
$ ls -l /usr/lib64/libstdc++.so*
lrwxrwxrwx. 1 root root       19 Dec 26 17:00 /usr/lib64/libstdc++.so.6 -> libstdc++.so.6.0.19
-rwxr-xr-x. 1 root root   995840 Sep 30  2020 /usr/lib64/libstdc++.so.6.0.19
-rwxr-xr-x. 1 root root 17714176 Dec 28 17:59 /usr/lib64/libstdc++.so.6.0.28

$ ln -s /usr/lib64/libstdc++.so.6.0.28 /usr/lib64/libstdc++.so.6
$ ls -l /usr/lib64/libstdc++.so*
lrwxrwxrwx. 1 root root       30 Dec 28 18:00 /usr/lib64/libstdc++.so.6 -> /usr/lib64/libstdc++.so.6.0.28
-rwxr-xr-x. 1 root root   995840 Sep 30  2020 /usr/lib64/libstdc++.so.6.0.19
-rwxr-xr-x. 1 root root 17714176 Dec 28 17:59 /usr/lib64/libstdc++.so.6.0.28

$ strings /usr/lib64/libstdc++.so.6 | grep GLIBC 
...
GLIBCXX_3.4.28
```

## 三. 升级 Make

备份旧版本文件，再创建目录进行编译安装

```sh
$ whereis make
make: /usr/bin/make /usr/local/make /usr/share/man/man1/make.1.gz
$ cd /usr/bin && cp make make_3.82
$ wget https://ftp.gnu.org/gnu/make/make-4.4.tar.gz
$ tar -xf make-4.4.tar.gz; cd make-4.4
$ mkdir build && cd build
$ ../configure --prefix=/usr
$ make && make install
$ make -v
GNU Make 4.4
Built for x86_64-pc-linux-gnu
Copyright (C) 1988-2022 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <https://gnu.org/licenses/gpl.html>
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
```

PS：同理，如 `--prefix=/usr/local/make` 则需要 `ln -sv` 重链 `/usr/bin/make`

## 四. 升级 Python3

> 新版本 Glibc 编译需要 Python3 环境，提前安装

```sh
$ yum -y install zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel gdbm-devel db4-devel libpcap-devel xz-devel
$ wget https://www.python.org/ftp/python/3.6.15/Python-3.6.15.tgz
$ tar -xf Python-3.6.15.tgz; cd Python-3.6.15
$ ./configure --prefix=/usr/local/python3
$ make && make install
$ ln -s /usr/local/python3/bin/python3 /usr/bin/python3
$ sed -i '10s|$|:/usr/local/python3/bin|' ~/.bash_profile
$ source ~/.bash_profile
$ ln -s /usr/local/python3/bin/pip3 /usr/bin/pip3
$ python3 -V
Python 3.6.15
$ pip3 -V
pip 18.1 from /usr/local/python3/lib/python3.6/site-packages/pip (python 3.6)
```

## 五. 升级 Glibc

在编译前需要修改配置文件，否则后续 `make install` 过程会报 `/usr/bin/ld: cannot find -lnss_test2`

```sh
$ wget https://ftp.gnu.org/gnu/glibc/glibc-2.33.tar.gz
$ tar -xf glibc-2.33.tar.gz; cd glibc-2.33
$ vim ./scripts/test-installation.pl
126     if ($name ne "nss_ldap" && $name ne "db1"
127         && $name ne "thread_db"
128         && $name ne "nss_test1" 
129         && $name ne "nss_test2"  # 增加此行
130         && $name ne "libgcc_s") 
...
```

创建临时目录并进行编译操作

```sh
$ mkdir build && cd build
$ ../configure --prefix=/usr --disable-profile --enable-add-ons --with-headers=/usr/include --with-binutils=/usr/bin --disable-sanity-checks --disable-werror
$ nohup make >& make.log &
$ make install
$ strings /lib64/libc.so.6 |grep GLIBC_2.*
...
GLIBC_2.33
```

PS：此处不建议使用 `-j4` 之类多线程操作，因为容易引发报错 `make: *** [Makefile:9: all] Error 2`

**参考说明：**

- `--prefix=/usr`: 指定安装目录的前缀为 /usr，即将 glibc 安装到 /usr 目录下。
- `--disable-profile`: 禁用生成性能分析相关的库和文件。
- `--enable-add-ons`: 启用额外的 glibc 插件。
- `--with-headers=/usr/include`: 指定头文件的路径为 `/usr/include`，这样在编译过程中可以使用该路径下的头文件。
- `--with-binutils=/usr/bin`: 指定 binutils 工具的路径为 `/usr/bin`，这样在编译过程中可以使用该路径下的 binutils 工具。
- `--disable-sanity-checks`: 禁用一些安全性检查，这样可以加快编译过程。
- `--disable-werror`: 禁止将警告视为错误，即编译过程中的警告不会导致编译失败。

**异常处理：**重启服务器后登录报错 `-bash: warning: setlocale: LC_TIME: cannot change locale (en_US.UTF-8)`

问题原因：glibc 编译安装 `make && make install` 后系统中文和 locale 会有问题，导致中文乱码和程序 encode 等出问题，重新 `make localedata/install-locales` 即可

```sh
$ cd ../glibc-2.33/build
$ make localedata/install-locales
```