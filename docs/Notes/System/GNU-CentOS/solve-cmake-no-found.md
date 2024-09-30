> 解决 cmake: command not found 问题

1. 准备编译环境
```bash
$ yum -y install gcc gcc-c++
```

2. 获取源码，并解压
```bash
$ wget https://cmake.org/files/v3.19/cmake-3.19.0.tar.gztar -zxf cmake-3.19.0.tar.gzcd cmake-3.19.0
```
3. 编译安装
```bash
./bootstrapgmake && gmake installln -s /usr/local/bin/cmake /usr/bin/
```
4. 检查是否正确安装
```bash
$ cmake --version
cmake version 3.19.0
CMake suite maintained and supported by Kitware (kitware.com/cmake).
```