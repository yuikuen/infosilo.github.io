> CentOS 源码包安装 OpenJDK11

下载相应的版本源码包，解压至指定目录

```sh
$ wget https://download.java.net/java/ga/jdk11/openjdk-11_linux-x64_bin.tar.gz
$ tar -xf openjdk-11_linux-x64_bin.tar.gz -C /opt
```

配置环境变量，使其生效并验证是否成功
```sh
$ vim /etc/profile.d/jdk-11.sh
# Java Environment
export JAVA_HOME=/opt/jdk-11
export JRE_HOME=$JAVA_HOME/jre
export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar:$JRE_HOME/lib:$CLASSPATH
export PATH=$JAVA_HOME/bin:$PATH

$ source /etc/profile
$ java -version
openjdk version "11" 2018-09-25
OpenJDK Runtime Environment 18.9 (build 11+28)
OpenJDK 64-Bit Server VM 18.9 (build 11+28, mixed mode)
```
