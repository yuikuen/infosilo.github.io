## 一. 前言

最近在测试某应用项目时遇到以下报错，主要原因是系统(CentOS7)自带的 Glibc 版本太低了，现版本无法满足后续的测试，故升级并记录一下

> 另外 Gcc 版本不能太新，否则无法与 Glibc 兼容

`****: /lib64/libc.so.6: version GLIBC_2.28' not found (required by ./****)`

## 二. 安装

### 2.1 安装 gcc-8

升级 GLIBC 之前需要升级 make 和安装 bison，并且需要升级 GCC，首先安装 gcc 所依赖的环境

```sh
$ yum -y install bison bzip2 gcc gcc-c++ glibc-headers
```

升级 GNU Make 3.82 到 4.2.1

```sh
$ wget http://ftp.gnu.org/gnu/make/make-4.2.1.tar.gz
$ tar -zxvf make-4.2.1.tar.gz
$ cd make-4.2.1
$ mkdir build
$ cd build
$ ../configure --prefix=/usr/local/make && make && make install
$ export PATH=/usr/local/make/bin:$PATH
$ ln -s /usr/local/make/bin/make /usr/local/make/bin/gmake
$ make -v
GNU Make 4.2.1
```

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

### 2.2 安装 Glibc-2.28

```sh
$ wget https://ftp.gnu.org/gnu/glibc/glibc-2.28.tar.gz
$ tar -xf glibc-2.28.tar.gz
$ cd glibc-2.28
$ mkdir build && cd build
# 根据服务器CPU性能不同，编译时间不同，建议后台执行
$ ../configure --prefix=/usr --disable-profile --enable-add-ons --with-headers=/usr/include --with-binutils=/usr/bin
$ make -j4 && make install
# nohup make -j4 >& make.log &
# make install
```

如直接编译安装会报错，虽然不处理也可更新使用，问题解决方法如下

- `make install` 过程报错 `/usr/bin/ld: cannot find -lnss_test2`
- `make && make install` 后系统中文和 locale 会有问题，导致中文乱码和程序 encode 等出问题

```sh
# build前修改配置文件
$ vim ./glibc-2.28/scripts/test-installation.pl
126     if ($name ne "nss_ldap" && $name ne "db1"
127         && $name ne "thread_db"
128         && $name ne "nss_test1" 
129         && $name ne "nss_test2"  # 增加此行
130         && $name ne "libgcc_s") 
...

# 另外编译前添加`--enable-obsolete-nsl`参数
../configure --prefix=/usr --disable-profile --enable-add-ons --with-headers=/usr/include --with-binutils=/usr/bin --enable-obsolete-nsl
```
```sh
$ nohup make -j4 >& make.log &
$ make install
# 安装更新后需要同步更新locale相关文件
$ make localedata/install-locales
```

最后查询是否升级成功

```sh
$ strings /lib64/libc.so.6 |grep GLIBC_2.28
GLIBC_2.28
GLIBC_2.28
```

## 2.3 总结

上述方法经过测试，全程无报错升级至 Glibc_2.28，之前编译报错的问题也得以解决，详细说明可参考链接博文的说明。
另外虽然 Gcc & Glibc 都升级成功，但升级后的动态库(libstdc+.so.*)还是为旧版本，此在另外的博文进行讲解。
