> 安装前请注意版本兼容性问题，如升级 Gcc-8.5.0 后编译升级 Glibc-2.34 会报错或需要升级相应的 Python3 来解决

**参考链接**

- **CentOS7 升级 Glibc 2.17 到2.28**：<https://roy.wang/centos7-upgrade-glibc/>
- **CentOS7.9 中的 Glibc2.17 源码编译升级到 Glibc2.31**：<https://segmentfault.com/a/1190000044126954>

## 一. 安装说明

CentOS 7 官方源的 Gcc 最新版本目前还是 `4.8.5`，默认的 Gcc 版本无法编译 Glibc 2.28，而安装 Glibc 所需的依赖，需要 Gcc 4.9 以上及 Make 4.0 以下，另外 Gcc 11.2 版本太新，也无法与 Glibc 2.28 兼容。

- Sys-OS：CentOS Linux release 7.9.2009 (Core)
- Kernel：Linux pbe-4044-c1 6.5.9-1.el7.elrepo.x86_64
- Make：GNU Make 4.2.1
- Gcc：gcc version 8.3.0 (GCC)
- Glibc：GLIBC_2.28

## 二. 升级 Gcc

安装 gcc-8.3.0 所依赖的环境

```sh
$ yum -y install bison wget bzip2 gcc gcc-c++ glibc-headers
```

编译升级 gcc-8.3.0

> PS：注意此处未选择常规 `yum install` 方式升级，而是选择耗时的编译方式，后面详细说明

```sh
$ wget https://ftp.gnu.org/gnu/gcc/gcc-8.3.0/gcc-8.3.0.tar.gz
$ tar -xf gcc-8.3.0.tar.gz && cd gcc-8.3.0
$ ./contrib/download_prerequisites
gmp-6.1.0.tar.bz2: OK
mpfr-3.1.4.tar.bz2: OK
mpc-1.0.3.tar.gz: OK
isl-0.18.tar.bz2: OK
All prerequisites downloaded successfully.

$ mkdir build && cd build
$ ../configure --enable-checking=release --enable-languages=c,c++ --disable-multilib
$ nohup make >& make.log &
true DO=all multi-do # make
$ make install
make[4]: Nothing to be done for `install-data-am'.
# 注意：重启后版本才能生效
$ init 6
```

重启后验证版本是否升级成功

```sh
$ gcc -v
Using built-in specs.
COLLECT_GCC=gcc
COLLECT_LTO_WRAPPER=/usr/local/libexec/gcc/x86_64-pc-linux-gnu/8.3.0/lto-wrapper
Target: x86_64-pc-linux-gnu
Configured with: ../configure --enable-checking=release --enable-languages=c,c++ --disable-multilib
Thread model: posix
gcc version 8.3.0 (GCC)

# 查看动态库版本情况，如非编译方式是无法升级动态库(libstdc++.so.6)
$ strings /usr/lib64/libstdc++.so.6 | grep GLIBC 
...
GLIBCXX_3.4.19
```

## 三. 升级 Make

将默认的 GNU Make 3.82 升至 GNU Make 4.2.1

```sh
$ wget http://ftp.gnu.org/gnu/make/make-4.2.1.tar.gz
$ tar -xf make-4.2.1.tar.gz && cd make-4.2.1
$ mkdir build && cd build
$ ../configure --prefix=/usr/local/make
$ make && make install
make[2]: Leaving directory `/usr/local/src/gcc-glibc/make-4.2.1/build'
make[1]: Leaving directory `/usr/local/src/gcc-glibc/make-4.2.1/build'

# 找出旧版本进行备份替换
$ whereis make
make: /usr/bin/make /usr/local/make /usr/share/man/man1/make.1.gz
$ cd /usr/bin && mv make make.bak
$ ln -sv /usr/local/make/bin/make /usr/bin/make
‘/usr/bin/make’ -> ‘/usr/local/make/bin/make’
$ make -v
GNU Make 4.2.1
```

## 四. 升级 Glibc

```sh
$ wget https://ftp.gnu.org/gnu/glibc/glibc-2.28.tar.gz
$ tar -xf glibc-2.28.tar.gz && cd glibc-2.28
$ mkdir build && cd build
```

在 Build 前需要修改配置文件，否则后续 `make install` 过程会报 `/usr/bin/ld: cannot find -lnss_test2`

```sh
$ vim ./glibc-2.28/scripts/test-installation.pl
126     if ($name ne "nss_ldap" && $name ne "db1"
127         && $name ne "thread_db"
128         && $name ne "nss_test1" 
129         && $name ne "nss_test2"  # 增加此行
130         && $name ne "libgcc_s") 
...
```

重新回到 Build 目录进行编译操作，另外编译前需添加 `--enable-obsolete-nsl` 参数

```sh
$ ../configure --prefix=/usr --disable-profile --enable-add-ons --with-headers=/usr/include --with-binutils=/usr/bin --enable-obsolete-nsl
$ nohup make -j4 >& make.log &
make[2]: Leaving directory '/usr/local/src/test/glibc-2.28/elf'
make[1]: Leaving directory '/usr/local/src/test/glibc-2.28'
$ make install
Your new glibc installation seems to be ok.
make[1]: Leaving directory '/usr/local/src/gcc-glibc/glibc-2.28'
```

验证服务，可以查看 Glibc 已从 GLIBC_2.17 更新至 GLIBC_2.28

```sh
$ strings /lib64/libc.so.6 |grep GLIBC_2.*
...
GLIBC_2.26
GLIBC_2.27
GLIBC_2.28
```

## 五. 升级 GLIBCXX

之前测试安装 NodeJS 18 以上版本时报错，需要更新 `GLIBC_2.28` 和 `GLIBCXX_3.4.21`，首次使用 `yum install devtoolset-8-gcc` 或以上版本，`GLIBC_2.28` 都可正常编译成功，但动态库则无法更新升级，最终只能通过编译安装 Gcc 来解决，下将讲解为什么选择耗时的编译方式。

> ```sh
> ****: /lib64/libc.so.6: version GLIBC_2.28' not found (required by ./****)
> ****: /lib64/libstdc++.so.6: version `GLIBCXX_3.4.21' not found (required by ./****)
> ```

首次使用 `yum install devtoolset-8-gcc` 或以上版本升级结果如下：

```sh
$ strings /usr/lib64/libstdc++.so.6 | grep GLIBC 
...
GLIBCXX_3.4.19

$ find / -name 'libstdc++.so.6*'
/usr/lib64/libstdc++.so.6
/usr/lib64/libstdc++.so.6.0.19
/usr/share/gdb/auto-load/usr/lib64/libstdc++.so.6.0.19-gdb.py
/usr/share/gdb/auto-load/usr/lib64/libstdc++.so.6.0.19-gdb.pyc
/usr/share/gdb/auto-load/usr/lib64/libstdc++.so.6.0.19-gdb.pyo
/opt/rh/devtoolset-8/root/usr/share/gdb/auto-load/usr/lib/libstdc++.so.6.0.19-gdb.py
/opt/rh/devtoolset-8/root/usr/share/gdb/auto-load/usr/lib/libstdc++.so.6.0.19-gdb.pyc
/opt/rh/devtoolset-8/root/usr/share/gdb/auto-load/usr/lib/libstdc++.so.6.0.19-gdb.pyo
/opt/rh/devtoolset-8/root/usr/share/gdb/auto-load/usr/lib64/libstdc++.so.6.0.19-gdb.py
/opt/rh/devtoolset-8/root/usr/share/gdb/auto-load/usr/lib64/libstdc++.so.6.0.19-gdb.pyc
/opt/rh/devtoolset-8/root/usr/share/gdb/auto-load/usr/lib64/libstdc++.so.6.0.19-gdb.pyo

# libstdc++.so.6的软链接还是libstdc++.so.6.0.19
$ ls -l /usr/lib64/libstdc++.so*
lrwxrwxrwx. 1 root root     19 May 27 13:54 /usr/lib64/libstdc++.so.6 -> libstdc++.so.6.0.19
-rwxr-xr-x. 1 root root 995840 Sep 30  2020 /usr/lib64/libstdc++.so.6.0.19
```

尝试更新更高版本的 Gcc & Glibc 也是一样，最后只能全通过编译安装才能解决；

**解决方法**：编译安装 Gcc-8.3，再重链接动态库

安装方法如上述 `升级 Gcc` 步骤，但安装成功后并不代表已完成升级，还需要重做软链接至新的动态库

```sh
$ find / -name 'libstdc++.so.6*'
/usr/lib64/libstdc++.so.6
/usr/lib64/libstdc++.so.6.0.19
/usr/share/gdb/auto-load/usr/lib64/libstdc++.so.6.0.19-gdb.py
/usr/share/gdb/auto-load/usr/lib64/libstdc++.so.6.0.19-gdb.pyc
/usr/share/gdb/auto-load/usr/lib64/libstdc++.so.6.0.19-gdb.pyo
# 注意：通过编译安装会新增libstdc++.so.6.0.25文件
/usr/local/lib64/libstdc++.so.6.0.25
/usr/local/lib64/libstdc++.so.6
/usr/local/lib64/libstdc++.so.6.0.25-gdb.py
/usr/local/src/test/gcc-8.3.0/build/stage1-x86_64-pc-linux-gnu/libstdc++-v3/src/.libs/libstdc++.so.6.0.25
/usr/local/src/test/gcc-8.3.0/build/stage1-x86_64-pc-linux-gnu/libstdc++-v3/src/.libs/libstdc++.so.6
/usr/local/src/test/gcc-8.3.0/build/prev-x86_64-pc-linux-gnu/libstdc++-v3/src/.libs/libstdc++.so.6.0.25
/usr/local/src/test/gcc-8.3.0/build/prev-x86_64-pc-linux-gnu/libstdc++-v3/src/.libs/libstdc++.so.6
/usr/local/src/test/gcc-8.3.0/build/x86_64-pc-linux-gnu/libstdc++-v3/src/.libs/libstdc++.so.6.0.25
/usr/local/src/test/gcc-8.3.0/build/x86_64-pc-linux-gnu/libstdc++-v3/src/.libs/libstdc++.so.6
```

编译安装成功后会有新增文件 `libstdc++.so.6.0.25`，首先查看现 `libstdc++.so.6` 使用情况

```sh
# 目前libstdc++.so.6的软链接还是libstdc++.so.6.0.19
$ ls -l /usr/lib64/libstdc++.so*
lrwxrwxrwx. 1 root root     19 Nov 22 17:07 /usr/lib64/libstdc++.so.6 -> libstdc++.so.6.0.19
-rwxr-xr-x. 1 root root 995840 Sep 30  2020 /usr/lib64/libstdc++.so.6.0.19
```

现需要将 `/usr/local/lib64/libstdc++.so.6.0.25` 复制至 `/usr/lib64/`，删除旧的链接，再新建软链接

```sh
$ cp /usr/local/lib64/libstdc++.so.6.0.25 /usr/lib64/
$ ls -l /usr/lib64/libstdc++.so*
lrwxrwxrwx. 1 root root       19 Nov 22 17:07 /usr/lib64/libstdc++.so.6 -> libstdc++.so.6.0.19
-rwxr-xr-x. 1 root root   995840 Sep 30  2020 /usr/lib64/libstdc++.so.6.0.19
-rwxr-xr-x. 1 root root 12171056 Nov 24 16:34 /usr/lib64/libstdc++.so.6.0.25

$ rm -rf /usr/lib64/libstdc++.so.6
$ ln -s /usr/lib64/libstdc++.so.6.0.25 /usr/lib64/libstdc++.so.6
$ ls -l /usr/lib64/libstdc++.so*
lrwxrwxrwx. 1 root root       30 Nov 24 16:35 /usr/lib64/libstdc++.so.6 -> /usr/lib64/libstdc++.so.6.0.25
-rwxr-xr-x. 1 root root   995840 Sep 30  2020 /usr/lib64/libstdc++.so.6.0.19
-rwxr-xr-x. 1 root root 12171056 Nov 24 16:34 /usr/lib64/libstdc++.so.6.0.25

$ strings /usr/lib64/libstdc++.so.6 | grep GLIBC 
...
GLIBCXX_3.4.25
```

再次执行以下命令来查看，最高版本已到了 `GLIBCXX_3.4.25`，至此 Gcc & Glibc 完成更新。

## 六. 异常记录

问题一：重启服务器后登录报错 `-bash: warning: setlocale: LC_TIME: cannot change locale (en_US.UTF-8)`

问题原因：glibc 编译安装 `make && make install` 后系统中文和 locale 会有问题，导致中文乱码和程序 encode 等出问题，重新 `make localedata/install-locales` 即可

```sh
$ cd ./glibc-2.28/build
$ make localedata/install-locales
...
make[2]: Leaving directory '/usr/local/src/gcc-glibc/glibc-2.28/localedata'
make[1]: Leaving directory '/usr/local/src/gcc-glibc/glibc-2.28'
```

问题二：在 Glibc 进行 `configure` 编译时报如下错误

```sh
configure: error: 
*** These critical programs are missing or too old: make python
*** Check the INSTALL file for required versions.
```

问题原因：Gcc & Glicb 版本选择过高，需要 Python3 才能编译

```sh
$ yum -y install zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel gdbm-devel db4-devel libpcap-devel xz-devel
$ wget https://www.python.org/ftp/python/3.6.15/Python-3.6.15.tgz
$ tar -xf Python-3.6.15.tgz 
$ cd Python-3.6.15
$ ./configure --prefix=/usr/local/python3
$ make && make install
Installing collected packages: setuptools, pip
Successfully installed pip-18.1 setuptools-40.6.2
$ ln -s /usr/local/python3/bin/python3 /usr/bin/python3
# 添加环境变量
$ vim ~/.bash_profile
# 在第10行添加:/usr/local/python3/bin
10 PATH=$PATH:$HOME/bin:/usr/local/python3/bin
$ source ~/.bash_profile
$ python3 -V
Python 3.6.15
$ pip3 -V
pip 18.1 from /usr/local/python3/lib/python3.6/site-packages/pip (python 3.6)
```

PS：确认无误后，再回到 Glibc 的编译 configure 操作

问题三：Gcc & Glibc make 过程中报如下错误

```sh
make[2]: Entering directory '/usr/local/src/glibc/glibc-2.34/csu'
make[2]: *** Cannot open jobserver /tmp/GMfifo24146r: No such file or directory.  Stop.
make[2]: Leaving directory '/usr/local/src/glibc/glibc-2.34/csu'
make[1]: *** [Makefile:478: csu/subdir_lib] Error 2
make[1]: Leaving directory '/usr/local/src/glibc/glibc-2.34'
make: *** [Makefile:9: all] Error 2
```

问题原因：使用了 `make -j4` 多线程编译导致，改为 make 编译即可

PS：`make -j4` 命令，用于编译软件时指定并行编译的线程数，其 `-j4` 表示使用 4 个线程进行编译，以加快编译过程

