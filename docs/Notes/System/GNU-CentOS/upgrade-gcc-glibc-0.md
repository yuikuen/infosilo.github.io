**参考链接**

- **CentOS7 升级 Glibc 2.17 到2.28**：<https://roy.wang/centos7-upgrade-glibc/>

## 一. 安装说明

CentOS 7 官方源的 Gcc 最新版本目前还是 `4.8.5`，默认的 Gcc 版本无法编译 Glibc 2.28，而安装 Glibc 所需的依赖，需要 Gcc 4.9 以上及 Make 4.0 以下，另外 Gcc 11.2 版本太新，也无法与 Glibc 2.28 兼容。

```sh
****: /lib64/libc.so.6: version GLIBC_2.28' not found (required by ./****)
```

- Sys-OS：CentOS Linux release 7.9.2009 (Core)
- Kernel：Linux pbe-4044-c1 6.5.9-1.el7.elrepo.x86_64
- Make：GNU Make 4.2.1
- Gcc：gcc version 8.3.0 (GCC)
- Glibc：GLIBC_2.28

## 二. 升级 Make

升级 GLIBC 之前需要升级 make 和安装 bison，并且需要升级 GCC，首先安装 gcc 所依赖的环境

```sh
$ yum -y install bison wget bzip2 gcc gcc-c++ glibc-headers
```

升级 GNU Make 3.82 到 4.2.1

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
$ make -v
GNU Make 4.2.1
```

## 三. 升级 Gcc

升级 Gcc 4.8.5 到 8.3.1-3

```sh
# 删除旧版本文件并指定版本安装
$ yum remove gcc -y
$ yum install centos-release-scl -y
$ yum install devtoolset-8 -y
# 将配置写入环境变量，永久生效
$ echo "source /opt/rh/devtoolset-8/enable" >> /etc/profile
$ source /etc/profile
```

如临时生效配置可执行：`scl enable devtoolset-8 bash`

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

PS：上述方法经过测试，全程无报错升级至 Glibc_2.28，虽然 Gcc & Glibc 都升级成功，但升级后的动态库(libstdc+.so.*) 还是为旧版本