> CentOS7.9 部署 RuoYi-Vue

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
$ sudo rm -rf node_modules package-lock.json && npm install
$ npm cache clean --force
$ npm config set registry http://registry.npmmirror.com
$ npm config get registry http://registry.npmmirror.com
```

## 五. 安装 Nginx

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

## 六. 部署 Item

### 6.1 后端服务

1）从 git 仓库 clone 下来最新代码 [Ruoyi Gitee 地址](https://gitee.com/y_project/RuoYi-Vue)

```bash
$ cd /usr/local
$ git clone https://gitee.com/y_project/RuoYi-Vue.git
```

2）创建数据库并导入数据表

```mysql
mysql> create database ruoyi_vue character set utf8 collate utf8_bin;
mysql> use ruoyi_vue;
mysql> source /usr/local/RuoYi-Vue/sql/quartz.sql;
mysql> source /usr/local/RuoYi-Vue/sql/ry_20210908.sql;
mysql> show databases;
mysql> flush privileges;
```

3）修改配置文件 `application.yml & application-druid.yml` 的项目启动端口、数据源等

```yaml
$ vim RuoYi-Vue/ruoyi-admin/src/main/resources/application.yml
# 开发环境配置
server:
  # 服务器的HTTP端口，默认为80
  port: 10080
  
# Spring配置
spring:
  # redis 配置
  redis:
    # 地址，根据实际修改
    host: localhost
    # 端口，默认为6379
    port: 6379
    # 数据库索引
    database: 0
    # 密码
    password:
```

```yaml
$ vim RuoYi-Vue/ruoyi-admin/src/main/resources/application-druid.yml
# 数据源配置
spring:
    datasource:
        type: com.alibaba.druid.pool.DruidDataSource
        driverClassName: com.mysql.cj.jdbc.Driver
        druid:
            # 主库数据源
            master:
                # 数据库地址及库名注意要与之前创建的一致
                url: jdbc:mysql://localhost:3306/ruoyi_vue?useUnicode=true&characterEncoding=utf8&zeroDateTimeBehavior=convertToNull&useSSL=true&serverTimezone=GMT%2B8
                username: root
                password: password
```

4）打包并启动项目，`RuoYi/ruoyi-admin/target/ruoyi-admin.jar` 就是打包完成后的 jar 包文件

```bash
$ cd /usr/local/RuoYi-Vue
$ mvn clean install -pl com.ruoyi:ruoyi-admin -am
$ nohup java -jar /usr/local/RuoYi-Vue/ruoyi-admin/target/ruoyi-admin.jar &
```

### 6.2 前端服务

1）进入项目目录，并修改启动端口

```js
$ cd RuoYi-Vue/ruoyi-ui
$ vim vue.config.js
const name = process.env.VUE_APP_TITLE || '若依管理系统' // 网页标题
const port = process.env.port || process.env.npm_config_port || 80 // 端口
```

2）打包正式环境(注意：打包前配置 Nodejs 淘宝源加速)

```bash
$ npm run build:prod
  Images and other types of assets omitted.

 DONE  Build complete. The dist directory is ready to be deployed.
 INFO  Check out deployment instructions at https://cli.vuejs.org/guide/deployment.html
```

3）将打包生成后的 `dist/*` 文件发布到 Nginx 目录即可

```bash
$ cp -rf dist /usr/local/nginx/html/ruoyi-vue
```

4）配置 Nginx 并重新加载配置

```bash
$ vim /usr/local/nginx/conf/nginx.conf
server {
        listen       80;
        server_name  localhost;

        location / {
            root   html/ruoyi-vue;
            try_files $uri $uri/ /index.html;
            index  index.html index.htm;
        }

        location /prod-api/ {
            proxy_set_header Host $http_host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header REMOTE-HOST $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_pass http://localhost:10081/;
     }

        location /dev-api/ {
            proxy_set_header Host $http_host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header REMOTE-HOST $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_pass http://localhost:10081/;
     }
}

# 保存后生新加载一下
$ nginx -s reload
```