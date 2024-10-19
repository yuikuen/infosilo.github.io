> CentOS7.9 部署 RuoYi-Cloud

## 一. 安装 JAVA

JDK >= 1.8，自行到相关网站进行下载上传，并解压、配置环境变量

```sh
$ tar -xf jdk-8u331-linux-x64.tar.gz -C /usr/local/
$ mv /usr/local/jdk1.8.0_331 /usr/local/java

$ vim /etc/profile
# java
JAVA_HOME=/usr/local/java
JRE_HOME=/usr/local/java/jre
PATH=$PATH:$JAVA_HOME/bin:$JRE_HOME/bin
CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar:$JRE_HOME/lib
export JAVA_HOME JRE_HOME PATH CLASSPATH

$ source /etc/profile
$ ln -s /usr/local/java/bin/java /usr/bin/java
```

## 二. 安装 Maven

Maven >= 3.0，自行到相关网站进行下载上传，并解压、配置环境变量

```sh
$ tar -xf apache-maven-3.8.5-bin.tar.gz -C /usr/local/
$ mv /usr/local/apache-maven-3.8.5 /usr/local/maven

$ vim /etc/profile
# maven
export MAVEN_HOME=/usr/local/maven
export PATH=${JAVA_HOME}/bin:/usr/local/mysql/bin:${MAVEN_HOME}/bin:$PATH

$ source /etc/profile
```

修改 `Maven Setting.xml` 配置文件，配置参考 [阿里云云效 Maven](https://developer.aliyun.com/mvn/guide) 使用指南

```xml
$ mkdir -p /usr/local/maven/repo                            //创建本地仓库目录
$ vim /usr/local/maven/conf/settings.xml
   | Default: ${user.home}/.m2/repository
  -->
  <localRepository>/usr/local/maven/repo</localRepository>  //取消注释并修改本地仓库位置
  
# 添加阿里云公共仓库
<mirror>
  <id>aliyunmaven</id>
  <mirrorOf>*</mirrorOf>
  <name>阿里云公共仓库</name>
  <url>https://maven.aliyun.com/repository/public</url>
</mirror>
```

## 三. 安装 MySQL

1）删除旧版本的 MySQL 及相关配置文件

```bash
$ rpm -qa mysql
$ rpm -qa | grep mariadb 
$ rpm -e --nodeps mariadb-libs  # 文件名
$ rm -rf /etc/my.cnf
```

2）安装相关依赖环境并下载源码包(自行下载上传)

```bash
$ yum -y install ncurses-devel cmake libaio-devel openssl-devel gcc gcc-c++ bison
```

3）解压目录并根据需求进行配置安装(基于 cmake 进行配置)

```bash
$ tar -xf mysql-boost-5.7.37.tar.gz
$ cd mysql-5.7.37

$ cmake . \
-DCMAKE_INSTALL_PREFIX=/usr/local/mysql \
-DMYSQL_DATADIR=/usr/local/mysql/data \
-DMYSQL_TCP_PORT=3306 \
-DMYSQL_UNIX_ADDR=/usr/local/mysql/mysql.sock \
-DWITH_INNOBASE_STORAGE_ENGINE=1 \
-DWITH_PARTITION_STORAGE_ENGINE=1 \
-DWITH_FEDERATED_STORAGE_ENGINE=1 \
-DWITH_BLACKHOLE_STORAGE_ENGINE=1 \
-DWITH_MYISAM_STORAGE_ENGINE=1 \
-DENABLED_LOCAL_INFILE=1 \
-DEXTRA_CHARSETS=all \
-DDEFAULT_CHARSET=utf8mb4 \
-DDEFAULT_COLLATION=utf8mb4_general_ci \
-DWITH_SSL=system \
-DWITH_BOOST=boost

$ make -j2 && make install
```

4）数据初始化，创建一个数据库专用账号 mysql(其所属组也为 mysql)

```bash
$ useradd -r -s /sbin/nologin mysql
$ id mysql
$ cd /usr/local/mysql
$ chown -R mysql:mysql /usr/local/mysql

# 数据库初始化操作，记录密码
$ bin/mysqld --initialize --user=mysql --basedir=/usr/local/mysql --datadir=/usr/local/mysql/data
...
2022-04-03T02:43:31.295939Z 1 [Note] A temporary password is generated for root@localhost: ygnt#l2X(fzx
```

5）拷贝 mysql.server 脚本到 `/etc/init.d` 目录，编写 MySQL 配置文件，然后启动数据库

```bash
$ cp support-files/mysql.server /etc/init.d/mysql
$ service mysql start
Starting MySQL.Logging to '/usr/local/mysql/data/Dev-Pc.err'.
 SUCCESS!

$ vim my.cnf
[mysqld]
basedir=/usr/local/mysql
datadir=/usr/local/mysql/data
socket=/usr/local/mysql/mysql.sock

$ service mysql restart
Shutting down MySQL.. SUCCESS! 
Starting MySQL. SUCCESS!
```

6）重置管理员密码并设置安全配置

```sql
$ bin/mysqladmin -uroot password 'newpassword' -p
Enter password:
mysqladmin: [Warning] Using a password on the command line interface can be insecure.
Warning: Since password will be sent to server in plain text, use ssl connection to ensure password safety.

# 重置后测试是否成功登录
$ bin/mysql -uroot -p
Enter password: 
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 3
Server version: 5.7.37 Source distribution

Copyright (c) 2000, 2022, Oracle and/or its affiliates.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> exit

$ bin/mysql_secure_installation
# 第一项回车跳过外，其他都选y
Securing the MySQL server deployment.

Enter password for user root: 
The 'validate_password' plugin is installed on the server.
The subsequent steps will run with the existing configuration
of the plugin.
Using existing password for root.

Estimated strength of the password: 50 
Change the password for root ? ((Press y|Y for Yes, any other key for No) : 

 ... skipping.
By default, a MySQL installation has an anonymous user,
allowing anyone to log into MySQL without having to have
a user account created for them. This is intended only for
testing, and to make the installation go a bit smoother.
You should remove them before moving into a production
environment.

Remove anonymous users? (Press y|Y for Yes, any other key for No) : y
Success.
```

7）添加服务至开机启动并配置环境变量

```bash
$ chkconfig --add mysql
$ chkconfig mysql on

$ vim /etc/profile
# MySQL
export MYSQL_HOME=/usr/local/mysql
export PATH=$PATH:$MYSQL_HOME/bin

$ source /etc/profile
```

## 四. 安装 NodeJS

1）下载至服务器并执行解压命令

```bash
$ wget https://npmmirror.com/mirrors/node/v16.14.2/node-v16.14.2-linux-x64.tar.xz
$ tar -xf node-v16.14.2-linux-x64.tar.xz -C /usr/local/
```

2）重名并添加系统环境变量

```bash
$ mv /usr/local/node-v16.14.2-linux-x64 nodejs

$ echo 'export PATH=/usr/local/nodejs/bin:$PATH' >> /etc/profile
$ source /etc/profile

$ ln -s /usr/local/nodejs/bin/npm  /usr/local/bin/
$ ln -s /usr/local/nodejs/bin/node /usr/local/bin/
```

3）配置淘宝源

```bash
# 参考性配置，非必须
$ npm config set registry http://registry.npmmirror.com
$ npm config get registry http://registry.npmmirror.com
```

## 五. 安装 Nacos

1）在 GitHub 上下载编译好的 nacos 安装包，下载地址: [Release](https://github.com/alibaba/nacos/releases)

```bash
$ tar -xvf nacos-server-2.0.3.tar.gz -C /usr/local/
```

2）登录 MySQL ，创建数据库并初始化 [SQL 数据源](https://github.com/alibaba/nacos/blob/master/distribution/conf/nacos-mysql.sql)

```sql
mysql> create database nacos_db character set utf8 collate utf8_bin;
mysql> create user 'nacos'@'%' identified by 'nacos';
mysql> grant all privileges on nacos_db.* to 'nacos'@'%';
mysql> flush privileges;

# 切换数据库，执行nacos初始化数据脚本
mysql> use nacos_db;
mysql> source /usr/local/nacos/conf/nacos-mysql.sql;

mysql> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| nacos_db           |
| performance_schema |
| sys                |
+--------------------+
7 rows in set (0.00 sec)
```

3）配置 nacos 后端数据库，在 nacos 的 conf 目录下修改 [application.properties 配置文件](https://github.com/alibaba/nacos/blob/master/distribution/conf/application.properties)

```bash
$ vim /usr/local/nacos/conf/application.properties
#*************** Config Module Related Configurations ***************#
### If use MySQL as datasource:
spring.datasource.platform=mysql

### Count of DB:
db.num=1

### Connect URL of DB:
# 注意：数据库地址、库名、时区的修改
db.url.0=jdbc:mysql://188.188.4.44:3306/nacos_db?characterEncoding=utf8&connectTimeout=1000&socketTimeout=3000&autoReconnect=true&useUnicode=true&useSSL=false&serverTimezone=Asia/Shanghai
db.user.0=nacos
db.password.0=nacos
```

4）脚本默认的启动方式为集群模式，需要修改成 standalone

```bash
$ vim ./nacos/bin/startup.sh
# 将55行的MODE改成standalone,单机启动
 54 export SERVER="nacos-server" 
 55 export MODE="standalone"
 56 export FUNCTION_MODE="all"
 57 export MEMBER_LIST=""
 58 export EMBEDDED_STORAGE=""
```

5）启动服务并测试

```bash
$ sh /usr/local/nacos/bin/startup.sh
/usr/local/java/bin/java -Djava.ext.dirs=/usr/local/java/jre/lib/ext:/usr/local/java/lib/ext  -Xms512m -Xmx512m -Xmn256m -Dnacos.standalone=true -Dnacos.member.list= -Xloggc:/usr/local/nacos/logs/nacos_gc.log -verbose:gc -XX:+PrintGCDetails -XX:+PrintGCDateStamps -XX:+PrintGCTimeStamps -XX:+UseGCLogFileRotation -XX:NumberOfGCLogFiles=10 -XX:GCLogFileSize=100M -Dloader.path=/usr/local/nacos/plugins/health,/usr/local/nacos/plugins/cmdb -Dnacos.home=/usr/local/nacos -jar /usr/local/nacos/target/nacos-server.jar  --spring.config.additional-location=file:/usr/local/nacos/conf/ --logging.config=/usr/local/nacos/conf/nacos-logback.xml --server.max-http-header-size=524288
nacos is starting with standalone
nacos is starting，you can check the /usr/local/nacos/logs/start.out

$ tail -f /usr/local/nacos/logs/start.out
2022-04-27 14:43:22,299 INFO Creating filter chain: any request, [org.springframework.security.web.context.request.async.WebAsyncManagerIntegrationFilter@3a08078c, org.springframework.security.web.context.SecurityContextPersistenceFilter@2b289ac9, org.springframework.security.web.header.HeaderWriterFilter@31ceba99, org.springframework.security.web.csrf.CsrfFilter@859ea42, org.springframework.security.web.authentication.logout.LogoutFilter@4487c0c2, org.springframework.security.web.savedrequest.RequestCacheAwareFilter@73d3e555, org.springframework.security.web.servletapi.SecurityContextHolderAwareRequestFilter@18460128, org.springframework.security.web.authentication.AnonymousAuthenticationFilter@53830483, org.springframework.security.web.session.SessionManagementFilter@bbf9e07, org.springframework.security.web.access.ExceptionTranslationFilter@2af46afd]

2022-04-27 14:43:22,443 INFO Initializing ExecutorService 'taskScheduler'

2022-04-27 14:43:22,464 INFO Exposing 16 endpoint(s) beneath base path '/actuator'

2022-04-27 14:43:22,593 INFO Tomcat started on port(s): 8848 (http) with context path '/nacos'

2022-04-27 14:43:22,597 INFO Nacos started successfully in stand alone mode. use external storage

2022-04-27 14:43:33,951 INFO Initializing Servlet 'dispatcherServlet'

2022-04-27 14:43:33,967 INFO Completed initialization in 15 ms
```

6）打开浏览器访问 nacos，默认账密 `nacos/nacos`

7）配置 systemd 管理 nacos

**注：**虽然系统已配置了 java 环境，并且直接调用 `startup.sh` 也能成功启动，但使用服务 `service` 就无法启动，原因是服务脚本的环境与系统环境变量不能共享

```bash
# 添加 nacos 服务运行用户
$ useradd -s /sbin/nologin -M nacos

# 修改 nacos 目录权限
$ chown -R nacos:nacos /usr/local/nacos

# 修改配置文件，注释并增加实际java路径
[ ! -e "$JAVA_HOME/bin/java" ] && JAVA_HOME=/usr/local/java
#[ ! -e "$JAVA_HOME/bin/java" ] && JAVA_HOME=$HOME/jdk/java
#[ ! -e "$JAVA_HOME/bin/java" ] && JAVA_HOME=/usr/java
#[ ! -e "$JAVA_HOME/bin/java" ] && JAVA_HOME=/opt/taobao/java
#[ ! -e "$JAVA_HOME/bin/java" ] && unset JAVA_HOME

# 创建 service 文件
$ cat > /usr/lib/systemd/system/nacos.service <<EOF
[Unit]
Description=nacos
After=network.target

[Service]
Type=forking
Environment="JAVA_HOME=/usr/local/java"
ExecStart=/usr/local/nacos/bin/startup.sh
ExecReload=/usr/local/nacos/bin/shutdown.sh
ExecStop=/usr/local/nacos/bin/shutdown.sh
PrivateTmp=true
User=nacos
Group=nacos

[Install]
WantedBy=multi-user.target
EOF

$ systemctl daemon-reload && systemctl enable --now nacos.service && systemctl status nacos
```

## 六. 安装 Sentinel

- [Sentinel 官网](https://sentinelguard.io/zh-cn/)
- [Sentinel 下载地址](https://github.com/alibaba/Sentinel/releases)

1）官方有提供下载地址，根据需要下载需要的版本，可参考 [官方 Wiki](https://github.com/alibaba/spring-cloud-alibaba/wiki/%E7%89%88%E6%9C%AC%E8%AF%B4%E6%98%8E)

```bash
$ mkdir /usr/local/sentinel/{bin,log}
$ wget https://github.com/alibaba/Sentinel/releases/download/1.8.1/sentinel-dashboard-1.8.1.jar
```

2）启动 Jar 包测试

```bash
$ java -jar sentinel-dashboard-1.8.1.jar

# 指定参数启动
$ java -Dserver.port=8718 -Dcsp.sentinel.dashboard.server=localhost:8718 -Dproject.name=sentinel-dashboard -jar sentinel-dashboard-1.8.1.jar
```

3）配置开机自启

```bash
$ vim /usr/local/sentinel/bin/startup.sh
#!/bin/bash

nohup java -Dserver.port=8718 -Dcsp.sentinel.dashboard.server=localhost:8718 -Dproject.name=sentinel-dashboard -Dcsp.sentinel.log.dir=/usr/local/sentinel/log -jar /usr/local/sentinel/sentinel-dashboard-1.8.1.jar > /usr/local/sentinel/log/sentinel.log 2>&1 &
echo $! > /var/run/sentinel.pid

$ vim /usr/local/sentinel/bin/shutdown.sh
#!/bin/bash

kill -9 `cat /var/run/sentinel.pid`

$ chmod +x startup.sh shutdown.sh
```

```bash
$ vim /usr/lib/systemd/system/sentinel.service
[Unit]
Description=service for sentinel
After=syslog.target network.target remote-fs.target nss-lookup.target
     
[Service]
Type=forking
Environment="JAVA_HOME=/usr/local/java"
ExecStart=/usr/local/sentinel/bin/startup.sh
ExecStop=/usr/local/sentinel/bin/shutdown.sh
PrivateTmp=true
     
[Install]
WantedBy=multi-user.target

$ systemctl daemon-reload && systemctl enable --now sentinel
$ systemctl status sentinel
$ systemctl list-units --type=service
```

## 七. 安装 Nginx

1）安装依依赖包

```bash
$ yum -y install gcc pcre pcre-devel zlib zlib-devel openssl openssl-devel
```

2）下载源码并解压编译运行

```bash
$ wget http://nginx.org/download/nginx-1.21.4.tar.gz
$ tar -xf nginx-1.21.4.tar.gz && cd nginx-1.21.4
# 进入解压后的资源包，测试环境暂不指定任何参数，单一指定安装路径，直接执行编译并安装
$ ./configure --prefix=/usr/local/nginx 
$ make && make install 

# 配置环境变量
$ echo 'export PATH=/usr/local/nginx/sbin:$PATH' >> /etc/profile
$ source /etc/profile
$ nginx -t
nginx: the configuration file /usr/local/nginx/conf/nginx.conf syntax is ok
nginx: configuration file /usr/local/nginx/conf/nginx.conf test is successful
```

3）设置开机自启

```bash
$ vim /lib/systemd/system/nginx.service
[Unit]
Description=nginx
After=network.target

[Service]
Type=forking
ExecStart=/usr/local/nginx/sbin/nginx
ExecReload=/usr/local/nginx/sbin/nginx -s reload
ExecStop=/usr/local/nginx/sbin/nginx -s stop
PrivateTmp=true

[Install]
WantedBy=multi-user.target
```

4）开启服务并查看状态

```bash
$ systemctl enable --now nginx && systemctl status nginx
● nginx.service
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; vendor preset: disabled)
   Active: active (running) since Fri 2021-11-19 23:08:08 CST; 8ms ago
  Process: 21862 ExecStart=/usr/local/nginx/sbin/nginx (code=exited, status=0/SUCCESS)
 Main PID: 21863 (nginx)
   CGroup: /system.slice/nginx.service
           ├─21863 nginx: master process /usr/local/nginx/sbin/nginx
           └─21865 nginx: worker process

Nov 19 23:08:08 share systemd[1]: Starting nginx.service...
Nov 19 23:08:08 share systemd[1]: Started nginx.service.

$ ps -ef | grep nginx
root     21863     1  0 23:08 ?        00:00:00 nginx: master process /usr/local/nginx/sbin/nginx
nobody   21865 21863  0 23:08 ?        00:00:00 nginx: worker process
root     21867 16208  0 23:08 pts/0    00:00:00 grep --color=auto nginx
```
1）安装依依赖包

```bash
$ yum -y install gcc pcre pcre-devel zlib zlib-devel openssl openssl-devel
```

2）下载源码并解压编译运行

```bash
$ wget http://nginx.org/download/nginx-1.21.4.tar.gz
$ tar -xf nginx-1.21.4.tar.gz && cd nginx-1.21.4
# 进入解压后的资源包，测试环境暂不指定任何参数，单一指定安装路径，直接执行编译并安装
$ ./configure --prefix=/usr/local/nginx 
$ make && make install 

# 配置环境变量
$ echo 'export PATH=/usr/local/nginx/sbin:$PATH' >> /etc/profile
$ source /etc/profile
$ nginx -t
nginx: the configuration file /usr/local/nginx/conf/nginx.conf syntax is ok
nginx: configuration file /usr/local/nginx/conf/nginx.conf test is successful
```

3）设置开机自启

```bash
$ vim /lib/systemd/system/nginx.service
[Unit]
Description=nginx
After=network.target

[Service]
Type=forking
ExecStart=/usr/local/nginx/sbin/nginx
ExecReload=/usr/local/nginx/sbin/nginx -s reload
ExecStop=/usr/local/nginx/sbin/nginx -s stop
PrivateTmp=true

[Install]
WantedBy=multi-user.target
```

4）开启服务并查看状态

```bash
$ systemctl enable --now nginx && systemctl status nginx
● nginx.service
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; vendor preset: disabled)
   Active: active (running) since Fri 2021-11-19 23:08:08 CST; 8ms ago
  Process: 21862 ExecStart=/usr/local/nginx/sbin/nginx (code=exited, status=0/SUCCESS)
 Main PID: 21863 (nginx)
   CGroup: /system.slice/nginx.service
           ├─21863 nginx: master process /usr/local/nginx/sbin/nginx
           └─21865 nginx: worker process

Nov 19 23:08:08 share systemd[1]: Starting nginx.service...
Nov 19 23:08:08 share systemd[1]: Started nginx.service.

$ ps -ef | grep nginx
root     21863     1  0 23:08 ?        00:00:00 nginx: master process /usr/local/nginx/sbin/nginx
nobody   21865 21863  0 23:08 ?        00:00:00 nginx: worker process
root     21867 16208  0 23:08 pts/0    00:00:00 grep --color=auto nginx
```

## 八. 部署 Item

### 8.1 后端服务

1）从 git 仓库 clone 下来最新代码 [Ruoyi Gitee 地址](https://gitee.com/y_project/RuoYi-Cloud)

```bash
$ cd /usr/local
$ git clone https://gitee.com/y_project/RuoYi-Cloud.git
```

2）创建数据库并导入数据表

```sql
# 创建两个数据库
mysql> CREATE DATABASE `ry-cloud` CHARACTER SET utf8 COLLATE utf8_general_ci;
mysql> CREATE DATABASE `ry-config` CHARACTER SET utf8 COLLATE utf8_general_ci;

# 导入数据库表
mysql> use ry-cloud;
mysql> source /usr/local/RuoYi-Cloud/sql/quartz.sql;
mysql> source /usr/local/RuoYi-Cloud/sql/ry_20210908.sql;

mysql> use ry-config;
mysql> source /usr/local/RuoYi-Cloud/sql/ry_config_20220424.sql;
mysql> flush privileges;
```

注意：若依官方提供的 `ry_config_20220424.sql` 中的内容与上部署的 Nacos 官方 `nacos-mysql.sql` 基本一致，除以下配置管理的配置外。在此可直接抽取内容导入即可使用，或直接使用若依提供的 `ry_config_20220424.sql`，根据个人喜好选择；

- 方法一：根据若依提供的数据库进行创建并导入数据，再修改 Nacos 的配置文件，如上述操作

```bash
# 备份Nacos配置文件，并修改成指定的数据库、账密
$ cd /usr/local/nacos/conf
$ cp application.properties application.properties.bak.$(date +%F)
$ vim application.properties
#*************** Config Module Related Configurations ***************#
### If use MySQL as datasource:
spring.datasource.platform=mysql

### Count of DB:
db.num=1

### Connect URL of DB:  注意修改成若依的数据库、账号、密码等信息
db.url.0=jdbc:mysql://127.0.0.1:3306/ry-config?characterEncoding=utf8&connectTimeout=1000&socketTimeout=3000&autoReconnect=true&useUnicode=true&useSSL=false&serverTimezone=Asia/Shanghai
db.user.0=root
db.password.0=newpassword
```

- 方法二：如使用 Nacos 的数据库的话，可使用客户端工具，比如 navicat 连到上面创建的 nacos 数据库，导入表数据

```sql
insert into config_info(id, data_id, group_id, content, md5, gmt_create, gmt_modified, src_user, src_ip, app_name, tenant_id, c_desc, c_use, effect, type, c_schema) values 
(1,'application-dev.yml','DEFAULT_GROUP','spring:\n  autoconfigure:\n    exclude: com.alibaba.druid.spring.boot.autoconfigure.DruidDataSourceAutoConfigure\n  mvc:\n    pathmatch:\n      matching-strategy: ant_path_matcher\n\n# feign 配置\nfeign:\n  sentinel:\n    enabled: true\n  okhttp:\n    enabled: true\n  httpclient:\n    enabled: false\n  client:\n    config:\n      default:\n        connectTimeout: 10000\n        readTimeout: 10000\n  compression:\n    request:\n      enabled: true\n    response:\n      enabled: true\n\n# 暴露监控端点\nmanagement:\n  endpoints:\n    web:\n      exposure:\n        include: \'*\'\n','aaa73b809cfd4d0058893aa13da57806','2020-05-20 12:00:00','2022-04-24 10:26:34','nacos','0:0:0:0:0:0:0:1','','','通用配置','null','null','yaml','null'),
(2,'ruoyi-gateway-dev.yml','DEFAULT_GROUP','spring:\n  redis:\n    host: localhost\n    port: 6379\n    password: \n  cloud:\n    gateway:\n      discovery:\n        locator:\n          lowerCaseServiceId: true\n          enabled: true\n      routes:\n        # 认证中心\n        - id: ruoyi-auth\n          uri: lb://ruoyi-auth\n          predicates:\n            - Path=/auth/**\n          filters:\n            # 验证码处理\n            - CacheRequestFilter\n            - ValidateCodeFilter\n            - StripPrefix=1\n        # 代码生成\n        - id: ruoyi-gen\n          uri: lb://ruoyi-gen\n          predicates:\n            - Path=/code/**\n          filters:\n            - StripPrefix=1\n        # 定时任务\n        - id: ruoyi-job\n          uri: lb://ruoyi-job\n          predicates:\n            - Path=/schedule/**\n          filters:\n            - StripPrefix=1\n        # 系统模块\n        - id: ruoyi-system\n          uri: lb://ruoyi-system\n          predicates:\n            - Path=/system/**\n          filters:\n            - StripPrefix=1\n        # 文件服务\n        - id: ruoyi-file\n          uri: lb://ruoyi-file\n          predicates:\n            - Path=/file/**\n          filters:\n            - StripPrefix=1\n\n# 安全配置\nsecurity:\n  # 验证码\n  captcha:\n    enabled: true\n    type: math\n  # 防止XSS攻击\n  xss:\n    enabled: true\n    excludeUrls:\n      - /system/notice\n  # 不校验白名单\n  ignore:\n    whites:\n      - /auth/logout\n      - /auth/login\n      - /auth/register\n      - /*/v2/api-docs\n      - /csrf\n','2f5a6b5a4ccf20b5801c5cf842456ec6','2020-05-14 14:17:55','2021-07-30 09:07:14',NULL,'0:0:0:0:0:0:0:1','','','网关模块','null','null','yaml','null'),
(3,'ruoyi-auth-dev.yml','DEFAULT_GROUP','spring: \r\n  redis:\r\n    host: localhost\r\n    port: 6379\r\n    password: \r\n','b7354e1eb62c2d846d44a796d9ec6930','2020-11-20 00:00:00','2021-02-28 21:06:58',NULL,'0:0:0:0:0:0:0:1','','','认证中心','null','null','yaml','null'),
(4,'ruoyi-monitor-dev.yml','DEFAULT_GROUP','# spring\r\nspring: \r\n  security:\r\n    user:\r\n      name: ruoyi\r\n      password: 123456\r\n  boot:\r\n    admin:\r\n      ui:\r\n        title: 若依服务状态监控\r\n','d8997d0707a2fd5d9fc4e8409da38129','2020-11-20 00:00:00','2020-12-21 16:28:07',NULL,'0:0:0:0:0:0:0:1','','','监控中心','null','null','yaml','null'),
(5,'ruoyi-system-dev.yml','DEFAULT_GROUP','# spring配置\r\nspring: \r\n  redis:\r\n    host: localhost\r\n    port: 6379\r\n    password: \r\n  datasource:\r\n    druid:\r\n      stat-view-servlet:\r\n        enabled: true\r\n        loginUsername: admin\r\n        loginPassword: 123456\r\n    dynamic:\r\n      druid:\r\n        initial-size: 5\r\n        min-idle: 5\r\n        maxActive: 20\r\n        maxWait: 60000\r\n        timeBetweenEvictionRunsMillis: 60000\r\n        minEvictableIdleTimeMillis: 300000\r\n        validationQuery: SELECT 1 FROM DUAL\r\n        testWhileIdle: true\r\n        testOnBorrow: false\r\n        testOnReturn: false\r\n        poolPreparedStatements: true\r\n        maxPoolPreparedStatementPerConnectionSize: 20\r\n        filters: stat,slf4j\r\n        connectionProperties: druid.stat.mergeSql\\=true;druid.stat.slowSqlMillis\\=5000\r\n      datasource:\r\n          # 主库数据源\r\n          master:\r\n            driver-class-name: com.mysql.cj.jdbc.Driver\r\n            url: jdbc:mysql://localhost:3306/ry-cloud?useUnicode=true&characterEncoding=utf8&zeroDateTimeBehavior=convertToNull&useSSL=true&serverTimezone=GMT%2B8\r\n            username: root\r\n            password: password\r\n          # 从库数据源\r\n          # slave:\r\n            # username: \r\n            # password: \r\n            # url: \r\n            # driver-class-name: \r\n      # seata: true    # 开启seata代理，开启后默认每个数据源都代理，如果某个不需要代理可单独关闭\r\n\r\n# seata配置\r\nseata:\r\n  # 默认关闭，如需启用spring.datasource.dynami.seata需要同时开启\r\n  enabled: false\r\n  # Seata 应用编号，默认为 ${spring.application.name}\r\n  application-id: ${spring.application.name}\r\n  # Seata 事务组编号，用于 TC 集群名\r\n  tx-service-group: ${spring.application.name}-group\r\n  # 关闭自动代理\r\n  enable-auto-data-source-proxy: false\r\n  # 服务配置项\r\n  service:\r\n    # 虚拟组和分组的映射\r\n    vgroup-mapping:\r\n      ruoyi-system-group: default\r\n  config:\r\n    type: nacos\r\n    nacos:\r\n      serverAddr: 127.0.0.1:8848\r\n      group: SEATA_GROUP\r\n      namespace:\r\n  registry:\r\n    type: nacos\r\n    nacos:\r\n      application: seata-server\r\n      server-addr: 127.0.0.1:8848\r\n      namespace:\r\n\r\n# mybatis配置\r\nmybatis:\r\n    # 搜索指定包别名\r\n    typeAliasesPackage: com.ruoyi.system\r\n    # 配置mapper的扫描，找到所有的mapper.xml映射文件\r\n    mapperLocations: classpath:mapper/**/*.xml\r\n\r\n# swagger配置\r\nswagger:\r\n  title: 系统模块接口文档\r\n  license: Powered By ruoyi\r\n  licenseUrl: https://ruoyi.vip','ac8913dee679e65bb7d482df5f267d4e','2020-11-20 00:00:00','2021-01-27 10:42:25',NULL,'0:0:0:0:0:0:0:1','','','系统模块','null','null','yaml','null'),
(6,'ruoyi-gen-dev.yml','DEFAULT_GROUP','# spring配置\r\nspring: \r\n  redis:\r\n    host: localhost\r\n    port: 6379\r\n    password: \r\n  datasource: \r\n    driver-class-name: com.mysql.cj.jdbc.Driver\r\n    url: jdbc:mysql://localhost:3306/ry-cloud?useUnicode=true&characterEncoding=utf8&zeroDateTimeBehavior=convertToNull&useSSL=true&serverTimezone=GMT%2B8\r\n    username: root\r\n    password: password\r\n\r\n# mybatis配置\r\nmybatis:\r\n    # 搜索指定包别名\r\n    typeAliasesPackage: com.ruoyi.gen.domain\r\n    # 配置mapper的扫描，找到所有的mapper.xml映射文件\r\n    mapperLocations: classpath:mapper/**/*.xml\r\n\r\n# swagger配置\r\nswagger:\r\n  title: 代码生成接口文档\r\n  license: Powered By ruoyi\r\n  licenseUrl: https://ruoyi.vip\r\n\r\n# 代码生成\r\ngen: \r\n  # 作者\r\n  author: ruoyi\r\n  # 默认生成包路径 system 需改成自己的模块名称 如 system monitor tool\r\n  packageName: com.ruoyi.system\r\n  # 自动去除表前缀，默认是false\r\n  autoRemovePre: false\r\n  # 表前缀（生成类名不会包含表前缀，多个用逗号分隔）\r\n  tablePrefix: sys_\r\n','8c79f64a4cca9b821a03dc8b27a2d8eb','2020-11-20 00:00:00','2021-01-26 10:36:45',NULL,'0:0:0:0:0:0:0:1','','','代码生成','null','null','yaml','null'),
(7,'ruoyi-job-dev.yml','DEFAULT_GROUP','# spring配置\r\nspring: \r\n  redis:\r\n    host: localhost\r\n    port: 6379\r\n    password: \r\n  datasource:\r\n    driver-class-name: com.mysql.cj.jdbc.Driver\r\n    url: jdbc:mysql://localhost:3306/ry-cloud?useUnicode=true&characterEncoding=utf8&zeroDateTimeBehavior=convertToNull&useSSL=true&serverTimezone=GMT%2B8\r\n    username: root\r\n    password: password\r\n\r\n# mybatis配置\r\nmybatis:\r\n    # 搜索指定包别名\r\n    typeAliasesPackage: com.ruoyi.job.domain\r\n    # 配置mapper的扫描，找到所有的mapper.xml映射文件\r\n    mapperLocations: classpath:mapper/**/*.xml\r\n\r\n# swagger配置\r\nswagger:\r\n  title: 定时任务接口文档\r\n  license: Powered By ruoyi\r\n  licenseUrl: https://ruoyi.vip\r\n','d6dfade9a2c93c463ae857cd503cb172','2020-11-20 00:00:00','2021-01-26 10:36:04',NULL,'0:0:0:0:0:0:0:1','','','定时任务','null','null','yaml','null'),
(8,'ruoyi-file-dev.yml','DEFAULT_GROUP','# 本地文件上传    \r\nfile:\r\n    domain: http://127.0.0.1:9300\r\n    path: D:/ruoyi/uploadPath\r\n    prefix: /statics\r\n\r\n# FastDFS配置\r\nfdfs:\r\n  domain: http://8.129.231.12\r\n  soTimeout: 3000\r\n  connectTimeout: 2000\r\n  trackerList: 8.129.231.12:22122\r\n\r\n# Minio配置\r\nminio:\r\n  url: http://8.129.231.12:9000\r\n  accessKey: minioadmin\r\n  secretKey: minioadmin\r\n  bucketName: test','5382b93f3d8059d6068c0501fdd41195','2020-11-20 00:00:00','2020-12-21 21:01:59',NULL,'0:0:0:0:0:0:0:1','','','文件服务','null','null','yaml','null'),
(9,'sentinel-ruoyi-gateway','DEFAULT_GROUP','[\r\n    {\r\n        \"resource\": \"ruoyi-auth\",\r\n        \"count\": 500,\r\n        \"grade\": 1,\r\n        \"limitApp\": \"default\",\r\n        \"strategy\": 0,\r\n        \"controlBehavior\": 0\r\n    },\r\n	{\r\n        \"resource\": \"ruoyi-system\",\r\n        \"count\": 1000,\r\n        \"grade\": 1,\r\n        \"limitApp\": \"default\",\r\n        \"strategy\": 0,\r\n        \"controlBehavior\": 0\r\n    },\r\n	{\r\n        \"resource\": \"ruoyi-gen\",\r\n        \"count\": 200,\r\n        \"grade\": 1,\r\n        \"limitApp\": \"default\",\r\n        \"strategy\": 0,\r\n        \"controlBehavior\": 0\r\n    },\r\n	{\r\n        \"resource\": \"ruoyi-job\",\r\n        \"count\": 300,\r\n        \"grade\": 1,\r\n        \"limitApp\": \"default\",\r\n        \"strategy\": 0,\r\n        \"controlBehavior\": 0\r\n    }\r\n]','9f3a3069261598f74220bc47958ec252','2020-11-20 00:00:00','2020-11-20 00:00:00',NULL,'0:0:0:0:0:0:0:1','','','限流策略','null','null','json','null');
```

因为在我的环境提前部署了 Seata，导入时提示 id 问题的错误，解决方法删除上面的 id 和数字序列 `1,2,3,4...`，新环境可忽略

![](https://img.17121203.xyz/i/2024/10/19/r3wc1h-0.webp)

3）重启 Nacos 后即可打开浏览器进行确认是否成功导入 `config` 配置

![](https://img.17121203.xyz/i/2024/10/19/r3ybuu-0.webp)

4）配置文件都是一些参数的修改，如 MySQL 的配置、Redis 的配置等(因都是本地部署，默认即可)

- 选择 `ruoyi-system-dev.yml` 并点击编辑按钮进行修改，然后点击发布即可

```yaml
# 根据自身的配置进行修改成新建的数据库和账密
      datasource:
          # 主库数据源
          master:
            driver-class-name: com.mysql.cj.jdbc.Driver
            url: jdbc:mysql://localhost:3306/ry-cloud?useUnicode=true&characterEncoding=utf8&zeroDateTimeBehavior=convertToNull&useSSL=true&serverTimezone=GMT%2B8
            username: root
            password: newpassword
```

![](https://img.17121203.xyz/i/2024/10/19/r41nyy-0.webp)

- 选择 `ruoyi-gen-dev.yml` 并点击编辑按钮进行修改，然后点击发布即可

```yaml
# spring配置
spring: 
  redis:
    host: localhost
    port: 6379
    password: 
  datasource: 
    driver-class-name: com.mysql.cj.jdbc.Driver
    url: jdbc:mysql://localhost:3306/ry-cloud?useUnicode=true&characterEncoding=utf8&zeroDateTimeBehavior=convertToNull&useSSL=true&serverTimezone=GMT%2B8
    username: root
    password: newpassword
```

- 选择 `ruoyi-job-dev.yml` 并点击编辑按钮进行修改，然后点击发布即可

```yaml
# spring配置，修改方法跟上述一致
spring: 
  redis:
    host: localhost
    port: 6379
    password: 
  datasource:
    driver-class-name: com.mysql.cj.jdbc.Driver
    url: jdbc:mysql://localhost:3306/ry-cloud?useUnicode=true&characterEncoding=utf8&zeroDateTimeBehavior=convertToNull&useSSL=true&serverTimezone=GMT%2B8
    username: root
    password: newpassword
```

5）后端打包与启动

```bash
$ mkdir -p /opt/app/ruoyi-cloud
$ cd /usr/local/RuoYi-Cloud
$ mvn clean install
```

等待很长一段时间后出现 BUILD SUCCESS 表示成功，然后将打包好的 jar 包统一放在一起，挨个启动即可

```bash
# 网关服务
$ cp ruoyi-gateway/target/ruoyi-gateway.jar /opt/app/ruoyi-cloud
# 权限服务
$ cp ruoyi-auth/target/ruoyi-auth.jar /opt/app/ruoyi-cloud
# 管理后台
$ cp ruoyi-modules/ruoyi-system/target/ruoyi-modules-system.jar /opt/app/ruoyi-cloud
# 监控模块
$ cp ruoyi-visual/ruoyi-monitor/target/ruoyi-visual-monitor.jar /opt/app/ruoyi-cloud
# 定时任务
$ cp ruoyi-modules/ruoyi-job/target/ruoyi-modules-job.jar /opt/app/ruoyi-cloud
# 文件模块
$ cp ruoyi-modules/ruoyi-file/target/ruoyi-modules-file.jar /opt/app/ruoyi-cloud

# 拷贝完成后进入目录挨个启动
$ nohup java -jar ruoyi-gateway.jar &
$ nohup java -jar ruoyi-auth.jar &
$ nohup java -jar ruoyi-modules-system.jar &
# 以上三个是必须启动的，后面三个可选
$ nohup java -jar ruoyi-visual-monitor.jar &
$ nohup java -jar ruoyi-modules-job.jar &
$ nohup java -jar ruoyi-modules-file.jar &
```

### 8.2 前端服务

1）进入项目目录，并修改启动端口，默认80(根据自身情况进行修改)

```js
$ cd RuoYi-Cloud/ruoyi-ui
$ vim vue.config.js
const name = process.env.VUE_APP_TITLE || '若依管理系统' // 网页标题
const port = process.env.port || process.env.npm_config_port || 80 // 端口
```

2）打包正式环境(注意：打包前配置 Nodejs 淘宝源加速)

```bash
$ sudo rm -rf node_modules package-lock.json && npm install
$ npm cache clean --force
$ npm install -g npm@8.8.0
$ npm run build:prod
  Images and other types of assets omitted.

 DONE  Build complete. The dist directory is ready to be deployed.
 INFO  Check out deployment instructions at https://cli.vuejs.org/guide/deployment.html
```

3）将打包生成后的 `dist/*` 文件发布到 Nginx 目录即可

```bash
$ cp -rf dist /usr/local/nginx/html/ruoyi-cloud
```

4）配置 Nginx 并重新加载配置

```bash
$ vim /usr/local/nginx/conf/nginx.conf
server {
        listen       80;
        server_name  localhost;

        location / {
            root   html/ruoyi-cloud;
            try_files $uri $uri/ /index.html;
            index  index.html index.htm;
        }

        location /prod-api/ {
            proxy_set_header Host $http_host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header REMOTE-HOST $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_pass http://localhost:8080/;
     }

        location /dev-api/ {
            proxy_set_header Host $http_host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header REMOTE-HOST $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_pass http://localhost:8080/;
     }
}

# 保存后生新加载一下
$ nginx -s reload
```

5）访问页面测试

![](https://img.17121203.xyz/i/2024/10/19/r2s885-0.webp)