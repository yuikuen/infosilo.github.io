> [Apache Tomcat 下载地址](https://tomcat.apache.org/)

1. 确保 JDK 环境正常，再根据实际需要下载源码包

```sh
$ wget https://mirrors.tuna.tsinghua.edu.cn/apache/tomcat/tomcat-8/v8.5.73/bin/apache-tomcat-8.5.73.tar.gz
$ tar -xf apache-tomcat-8.5.73.tar.gz -C /usr/local/
$ mv apache-tomcat-8.5.73 tomcat
```

2. 解压后即可启动 Tomcat，检查是否安装成功

```sh
$ cd /usr/local/tomcat/bin
$ ./sh startup.sh 
Using CATALINA_BASE:   /usr/local/tomcat
Using CATALINA_HOME:   /usr/local/tomcat
Using CATALINA_TMPDIR: /usr/local/tomcat/temp
Using JRE_HOME:        /usr/local/java/jre
Using CLASSPATH:       /usr/local/tomcat/bin/bootstrap.jar:/usr/local/tomcat/bin/tomcat-juli.jar
Tomcat started.

$ lsof -i:8080
COMMAND  PID USER   FD   TYPE DEVICE SIZE/OFF NODE NAME
java    2000 root   49u  IPv6  59146      0t0  TCP *:webcache (LISTEN)

$ curl http://188.188.3.112:8080
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="UTF-8" />
        <title>Apache Tomcat/8.5.40</title>
        <link href="favicon.ico" rel="icon" type="image/x-icon" />
        <link href="favicon.ico" rel="shortcut icon" type="image/x-icon" />
        <link href="tomcat.css" rel="stylesheet" type="text/css" />
    </head>
...
```

配置开机自启，为其配置 pid 和添加 tomcat.service

```sh
$ vim /usr/local/tomcat/bin/catalina.sh
# Copy CATALINA_BASE from CATALINA_HOME if not already set
[ -z "$CATALINA_BASE" ] && CATALINA_BASE="$CATALINA_HOME"
CATALINA_PID="$CATALINA_BASE/tomcat.pid"  # 设置pid。一定要加在CATALINA_BASE定义后面，要不然pid会生成到/下面

$ vim /lib/systemd/system/tomcat.service 
[Unit]
Description=Tomcat
After=syslog.target network.target remote-fs.target nss-lookup.target

[Service]
Type=forking

Environment="JAVA_HOME=/usr/local/java"

PIDFile=/usr/local/tomcat/tomcat.pid
ExecStart=/usr/local/tomcat/bin/startup.sh
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s QUIT $MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target
```
