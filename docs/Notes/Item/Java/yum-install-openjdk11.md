> CentOS 安装 OpenJDK11 环境

1）删除旧版本文件

```bash
# 查看
rpm -qa | grep java
rpm -qa | grep jdk
# 批量卸载
rpm -qa | grep jdk | xargs rpm -e --nodeps
rpm -qa | grep java | xargs rpm -e --nodeps
```

2）查看版本并下载安装包

```bash
# OpenJDK1.8
$ yum search java-1.8.0-openjdk
$ yum install java-1.8.0-openjdk -y

# OpenJDK11
$ yum search java-11-openjdk
$ yum install -y java-11-openjdk java-11-openjdk-devel
```

3）查找安装目录

```bash
$ which java 或 ls -l $(which java)

# 如果显示的是/usr/bin/java请执行下面命令
$ ls -lr /usr/bin/java
$ ls -lrt /etc/alternatives/java

# 输出：/etc/alternatives/java -> /usr/lib/jvm/java-11-openjdk-11.0.13.0.8-1.el7_9.x86_64/bin/java
# 上面的/usr/lib/jvm/java-11-openjdk-11.0.13.0.8-1.el7_9.x86_64就是JAVA的安装路径
```

4）配置环境变量

```bash
# 通过yum方式安装默认安装在/usr/lib/jvm文件下
# 修改JAVA_HOME为/usr/lib/jvm/java-11-openjdk-11.0.13.0.8-1.el7_9.x86_64
# 编辑/etc/profile文件
$ cat /etc/profile.d/openjdk.sh
# Java Environment
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-11.0.13.0.8-1.el7_9.x86_64
export JRE_HOME=$JAVA_HOME/jre
export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/jre/lib/tools.jar:$JRE_HOME/lib:$CLASSPATH
export PATH=$JAVA_HOME/bin:$PATH

# 使其生效并验证版本信息
$ source /etc/profile

$ java -version
openjdk version "11" 2018-09-25
OpenJDK Runtime Environment 18.9 (build 11+28)
OpenJDK 64-Bit Server VM 18.9 (build 11+28, mixed mode)
```
