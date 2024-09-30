> 解决 error: Please reinstall the libzip distributio 或 error: system libzip must be upgraded to version >= 0.11 错误

1. 准备编译环境

```bash
$ yum install openssl-devel bzip2 bzip2-devel
```

2. 下载源码，并解压
```bash
$ wget https://libzip.org/download/libzip-1.7.3.tar.gz && tar -zxf libzip-1.7.3.tar.gz && cd libzip-1.7.3
# 备用下载地址：https://down.24kplus.com/linux/libzip/libzip-1.7.3.tar.gz3、编译安装

$ mkdir build && cd build \
&& cmake -DCMAKE_INSTALL_PREFIX=/usr .. \
&& make \
&& sudo make install
```
如果提示 cmake: command not found，需要先安装 cmake。