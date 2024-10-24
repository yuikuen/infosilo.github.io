> CentOS 源码包安装 OracleJDK8

安装方法相对简单，直接下载相应版本的源码包，解压并设置环境变量即可
Java 安装一般为 [OpenJDK](https://jdk.java.net/8/) 或 [OracleJDK](https://www.oracle.com/java/technologies/downloads/)，可按需要选择

首先删除旧档文件，强制删除

```sh
$ rpm -qa | grep java
$ rpm -qa | grep java | xargs rpm -e --nodeps
```

将下载好的软件包解压至指定位置，设置环境变量并测试是否成功

```sh
$ tar -xf jdk-8u241-linux-x64.tar.gz -C /opt
$ cat /etc/profile.d/jdk8.sh
# OracleJDK
export JAVA_HOME=/opt/jdk1.8.0_241
export JRE_HOME=${JAVA_HOME}/jre
export CLASSPATH=.:${JAVA_HOME}/lib:${JRE_HOME}/lib
export PATH=${JAVA_HOME}/bin:$PATH

$ source /etc/profile
$ java -version
```
