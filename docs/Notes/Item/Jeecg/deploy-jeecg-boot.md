> CentOS 部署 Jeecg-Boot 项目
>
> PS: 项目更新迭代得很快，部署的方法都类同，具体变化请查阅官网

## 一. 环境准备

### 1.1 安装 Java

JDK >= 1.8，自行到相关网站进行下载上传，并解压、配置环境变量

```bash
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

### 1.2 安装 Maven

Maven >= 3.0，自行到相关网站进行下载上传，并解压、配置环境变量

```bash
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
<mirrors>
        <mirror>
           <id>aliyunmaven</id>
           <mirrorOf>*</mirrorOf>
           <name>阿里云公共仓库</name>
           <url>https://maven.aliyun.com/repository/public</url>
       </mirror>

       <mirror>
            <id>nexus-aliyun</id>
            <mirrorOf>*,!jeecg,!jeecg-snapshots,!getui-nexus</mirrorOf>
            <name>Nexus aliyun</name>
            <url>http://maven.aliyun.com/nexus/content/groups/public</url>
        </mirror> 
</mirrors>
```

### 1.3 安装 MySQL

1）删除旧版本的 MySQL 及相关配置文件

```bash
$ rpm -qa mysql
$ rpm -qa | grep mariadb 
$ rpm -e --nodeps mariadb-libs  # 文件名
$ rm -rf /etc/my.cnf
```

2）安装相关依赖环境并下载源码包(自行下载上传)

```bash
$ yum -y install ncurses-devel cmake libaio-devel openssl-devel
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

### 1.4 安装 NodeJS

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
$ sudo rm -rf node_modules package-lock.json && npm install
$ npm cache clean --force
$ npm config set registry http://registry.npmmirror.com
$ npm config get registry http://registry.npmmirror.com
```

### 1.5 安装 Nginx

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

## 二. 项目部署

### 2.1 后端配置

1）从 git 仓库 clone 下来最新代码 [Jeecg-Boot Gitee 地址](https://gitee.com/jeecg/jeecg-boot)  (当前最新版本： 3.2.0（发布日期：2022-04-25）)

```bash
$ cd /usr/local/
$ git clone https://gitee.com/jeecg/jeecg-boot.git
```

2）创建数据库并导入数据表

```sql
# 创建数据库
mysql> CREATE DATABASE `jeecg-boot` CHARACTER SET utf8 COLLATE utf8_general_ci;

# 导入数据库表及数据
mysql> use jeecg-boot;
mysql> source /usr/local/jeecg-boot/jeecg-boot/db/jeecgboot-mysql-5.7.sql;

# 修改数据库表，表名改成大写，原因不明，否则启动项目时会报错
mysql> alter table qrtz_fired_triggers rename to QRTZ_FIRED_TRIGGERS;
mysql> alter table qrtz_locks rename to QRTZ_LOCKS;
mysql> alter table qrtz_scheduler_state rename to QRTZ_SCHEDULER_STATE;
mysql> alter table qrtz_triggers rename to QRTZ_TRIGGERS;

mysql> show databases;
mysql> flush privileges;
```

3）修改配置文件 `application.yml & application-profile.name`

```yaml
$ cat jeecg-boot/jeecg-boot/jeecg-boot-module-system/src/main/resources/application.yml
spring:
  application:
    name: jeecg-system
  profiles:
    # active: '@profile.name@'
    active: 'dev'
```
单启动只需要配置 mysql & redis 即可，其他可后续根据需求进行配置
```yaml
$ cat jeecg-boot/jeecg-boot/jeecg-boot-module-system/src/main/resources/application-dev.yml
  # mysql配置，修改数据库连接地址、账号、密码
spring:
  datasource:
    dynamic:
      datasource:
        master:
          url: jdbc:mysql://127.0.0.1:3306/jeecg-boot?characterEncoding=UTF-8&useUnicode=true&useSSL=false&tinyInt1isBit=false&allowPublicKeyRetrieval=true&serverTimezone=Asia/Shanghai
          username: root
          password: newpassword
          driver-class-name: com.mysql.cj.jdbc.Driver
          
  # redis 配置
  redis:
    database: 0
    host: 127.0.0.1
    lettuce:
      pool:
        max-active: 8   #最大连接数据库连接数,设 -1 为没有限制
        max-idle: 8     #最大等待连接中的数量,设 0 为没有限制
        max-wait: -1ms  #最大建立连接等待时间。如果超过此时间将接到异常。设为-1表示无限制。
        min-idle: 0     #最小等待连接中的数量,设 0 为没有限制
      shutdown-timeout: 100ms
    password: ''
    port: 6379
```

4）打包并启动项目，`jeecg-boot-module-system/target/jeecg-boot-module-system-3.2.0.jar` 就是打包完成后的 jar 包文件

```bash
$ cd /usr/local/jeecg-boot
$ mvn clean install
$ cd jeecg-boot/jeecg-boot-module-system/target/
$ nohup java -jar jeecg-boot-module-system-3.2.0.jar &
# 查看日志显示访问地址即代表成功
...
2022-05-07 11:02:01.699 [main] INFO  org.quartz.core.QuartzScheduler:547 - Scheduler MyScheduler_$_Dev-Pc1651892515105 started.
2022-05-07 11:02:01.727 [main] INFO  org.jeecg.JeecgSystemApplication:61 - Started JeecgSystemApplication in 15.965 seconds (JVM running for 16.733)
2022-05-07 11:02:01.751 [main] INFO  org.jeecg.JeecgSystemApplication:37 - 
----------------------------------------------------------
	Application Jeecg-Boot is running! Access URLs:
	Local: 		http://localhost:8080/jeecg-boot/
	External: 	http://188.188.4.44:8080/jeecg-boot/
	Swagger文档: 	http://188.188.4.44:8080/jeecg-boot/doc.html
----------------------------------------------------------
```

### 2.2 前端配置

1）进入项目目录，查看配置文件(版本不一样，配置也有所不同，可参考 [官网配置说明](http://doc.jeecg.com/2043886))

```bash
$ cd jeecg-boot/ant-design-vue-jeecg

# 注意：Linux下文件是隐藏的
$ ls -al
total 1344
drwxr-xr-x    6 root root   4096 May  7 11:57 .
drwxr-xr-x    6 root root    150 May  6 16:30 ..
-rw-r--r--    1 root root     86 May  6 16:30 babel.config.js
drwxr-xr-x    2 root root      6 May  7 11:57 dist
-rw-r--r--    1 root root   1200 May  6 16:30 Dockerfile
-rw-r--r--    1 root root    254 May  6 16:30 .dockerignore
-rw-r--r--    1 root root    661 May  6 16:30 .editorconfig
-rw-r--r--    1 root root    162 May  6 16:30 .env
-rw-r--r--    1 root root    356 May  7 11:42 .env.development
-rw-r--r--    1 root root    191 May  7 11:55 .env.production
-rw-r--r--    1 root root    195 May  6 16:30 .env.test
-rw-r--r--    1 root root      4 May  6 16:30 .eslintignore
-rw-r--r--    1 root root     26 May  6 16:30 .gitattributes
-rw-r--r--    1 root root    214 May  6 16:30 .gitignore
-rw-r--r--    1 root root    655 May  6 16:30 idea.config.js
-rw-r--r--    1 root root  12242 May  6 16:30 LICENSE
drwxr-xr-x 1115 root root  32768 May  7 11:10 node_modules
-rw-r--r--    1 root root   3157 May  6 16:30 package.json
-rw-r--r--    1 root root 722744 May  6 16:30 package-lock.json
-rw-r--r--    1 root root     64 May  6 16:30 .prettierrc
drwxr-xr-x    5 root root    149 May  6 16:30 public
-rw-r--r--    1 root root   3195 May  6 16:30 README.md
drwxr-xr-x   13 root root   4096 May  6 16:30 src
-rw-r--r--    1 root root   3328 May  6 16:30 vue.config.js
-rw-r--r--    1 root root 507634 May  6 16:30 yarn.lock

$ cat .env
NODE_ENV=production
VUE_APP_PLATFORM_NAME=JeecgBoot 企业级低代码平台
# 开启单点登录
VUE_APP_SSO=false
# 开启微应用模式
VUE_APP_QIANKUN=false
```

通过上述可以看到，默认的接口地址配置是 `.env.production`，如部署之后发现前端报错 Network Error，验证码依旧显示 404，那就检查是否修改错其他的配置文件了

```bash
$ cat .env.production
# 修改接口地址
NODE_ENV=production
VUE_APP_API_BASE_URL=http://188.188.4.44:8080/jeecg-boot
VUE_APP_CAS_BASE_URL=http://188.188.4.44:8888/cas
VUE_APP_ONLINE_BASE_URL=http://fileview.jeecg.com/onlinePreview
```

2）打包正式环境(注意：打包前配置 Nodejs 淘宝源加速)

```bash
$ npm run build
  Images and other types of assets omitted.

 DONE  Build complete. The dist directory is ready to be deployed.
 INFO  Check out deployment instructions at https://cli.vuejs.org/guide/deployment.html
```

3）将打包生成后的 `dist/*` 文件发布到 Nginx 目录即可

```bash
$ rm -rf /usr/local/nginx/html/*
$ cp -rf dist/* /usr/local/nginx/html/
```

4）配置 Nginx 并重新加载配置 [官方参考](http://doc.jeecg.com/2043886)

```bash
$ vim /usr/local/nginx/conf/nginx.conf
    # nginx.conf的http中加入以下片断，开启Nginx压缩，解决前端访问慢问题
    gzip on;
    gzip_min_length 1k;
    gzip_comp_level 9;
    gzip_types text/plain application/javascript application/x-javascript text/css application/xml text/javascript application/x-httpd-php image/jpeg image/gif image/png;
    gzip_vary on;
    gzip_disable "MSIE [1-6]\.";

    server {
		listen       80;
		server_name  localhost;

		#后台服务配置，配置了这个location便可以通过http://域名/jeecg-boot/xxxx 访问		
		location ^~ /jeecg-boot {
			proxy_pass              http://127.0.0.1:8080/jeecg-boot/;
			proxy_set_header        Host 127.0.0.1;
			proxy_set_header        X-Real-IP $remote_addr;
			proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
		}
		#解决Router(mode: 'history')模式下，刷新路由地址不能找到页面的问题
		location / {
			root   html;
			index  index.html index.htm;
			if (!-e $request_filename) {
				rewrite ^(.*)$ /index.html?s=$1 last;
				break;
			}
		}
	}

# 保存后生新加载一下
$ nginx -s reload
```

通过：`http://你的域名` 访问项目，出现如下页面，使用账户/密码：admin/123456 登录成功即可
