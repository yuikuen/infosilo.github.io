## 一. 安装说明

Jenkins 2.357 和将发布的 LTS 版本开始，Jenkins 需要 Java 11 才能使用，将放弃 Java 8，请注意兼容性问题。

- System：CentOS7.9.2009 Minimal
- Java：java-11-openjdk-11.0.13.0.8-1.el7_9.x86_64
- PostgreSQL：postgresql10
- SonarQube：sonarqube-8.9.6.50800

```bash
# 演示环境，直接关闭 SELinux & Firewalld 或开放对应服务
$ sed -i '/SELINUX/s/enforcing/disabled/' /etc/selinux/config && setenforce 0 
$ systemctl disable --now firewalld.service 

$ firewall-cmd --zone=public --add-port=9000/tcp --permanent
$ firewall-cmd --reload
```

> 注意：根据不同版本，需要的环境支持也不一样，在此使用得是 JDK11、PostgreSQL 12

- [环境要求](https://docs.sonarqube.org/8.9/requirements/requirements/)
- [官网下载地址](https://www.sonarqube.org/downloads/)
- [SonarQube 汉化包](https://github.com/xuhuisheng/sonar-l10n-zh/releases)

## 二. 环境准备

1）**内核配置**

```bash
$ vim /etc/sysctl.conf
# 文件末尾加入如下配置
vm.max_map_count=262144
fs.file-max=65536
$ sysctl -p
```

```bash
$ vim /etc/security/limits.conf
# 文件末尾加入如下配置
*	soft	nofile	65536
*	hard	nofile	65536
*	soft	nproc	4096
*	hard	nproc	4096
```

2）安装 Java

```bash
$ yum install -y java-11-openjdk java-11-openjdk-devel

# 查看并确认具体安装路径
$ which java
$ ls -lr /usr/bin/java
$ ls -lrt /etc/alternatives/java
/etc/alternatives/java -> /usr/lib/jvm/java-11-openjdk-11.0.13.0.8-1.el7_9.x86_64/bin/java

# 配置环境变量
$ vim /etc/profile
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-11.0.13.0.8-1.el7_9.x86_64
export CLASSPATH=.:$JAVA_HOME/jre/lib/rt.jar:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
export PATH=$PATH:$JAVA_HOME/bin
$ source /etc/profile
```

3）安装 PostgreSQL

- 下载 RPM 文件安装并初始化

```bash
$ yum install https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm -y
$ yum install postgresql10-contrib postgresql10-server -y
$ /usr/pgsql-10/bin/postgresql-10-setup initdb
```

- 修改配置，开启访问权限

```bash
$ cp /var/lib/pgsql/10/data/pg_hba.conf{,.bak}

# 将 peer、ident 改为 trust ，改了6行
$ vim /var/lib/pgsql/10/data/pg_hba.conf
# "local" is for Unix domain socket connections only
local   all             all                                     trust
# IPv4 local connections:
host    all             all             127.0.0.1/32            trust
# IPv6 local connections:
host    all             all             ::1/128                 trust
# Allow replication connections from localhost, by a user with the
# replication privilege.
local   replication     all                                     trust
host    replication     all             127.0.0.1/32            trust
host    replication     all             ::1/128                 trust
```

```bash
$ systemctl enable --now postgresql-10.service
```

- 创建用户及数据库

```bash
$ su - postgres
Last login: Mon Nov  1 11:14:43 CST 2021 on pts/0
-bash-4.2$ psql
psql (10.18)
Type "help" for help.
postgres=# CREATE DATABASE sonar TEMPLATE template0 ENCODING 'utf8' ;
postgres=# create user sonar;
postgres=# alter user sonar with password 'sonar';
postgres=# alter role sonar createdb;
postgres=# alter role sonar superuser;
postgres=# alter role sonar createrole;
postgres=# alter database sonar owner to sonar;
postgres=# \q
-bash-4.2$ exit
```

## 三. 安装 SonarQube

- 添加独立用户，下载安装包并解压修改权限

```bash
$ adduser sonar
$ wget -c https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-8.9.6.50800.zip
$ unzip sonarqube-8.9.6.50800.zip
$ mv sonarqube-8.9.6.50800 /usr/local/sonarqube
$ chown -R sonar:sonar /usr/local/sonarqube/
```

- 配置修改，链接 postgresql

```bash
$ vim /usr/local/sonarqube/conf/sonar.properties
sonar.jdbc.username=sonar
sonar.jdbc.password=sonar
sonar.jdbc.url=jdbc:postgresql://localhost/sonar
sonar.jdbc.maxActive=60
sonar.jdbc.maxIdle=5
sonar.jdbc.minIdle=2
sonar.jdbc.maxWait=5000
sonar.jdbc.minEvictableIdleTimeMillis=600000
sonar.jdbc.timeBetweenEvictionRunsMillis=30000
sonar.jdbc.removeAbandoned=true
sonar.jdbc.removeAbandonedTimeout=60
```

- 修改环境变量

```bash
$ vim /etc/profile
export SONAR_HOME=/usr/local/sonarqube
export SONAR_RUNNER_HOME=/usr/local/sonar-scanner
export PATH=$PATH:$SONAR_RUNNER_HOME/bin
export PATH=$PATH:$SONAR_HOME/bin
$ source /etc/profile
```

- 启动服务并设置开机自启

```bash
$ su - sonar
$ cd /usr/local/sonarqube/bin/linux-x86-64/
$ ./sonar.sh start
Starting SonarQube...
Started SonarQube.
# 其他命令
Usage: ./sonar.sh { console | start | stop | force-stop | restart | status | dump }
```

```bash
$ vim /etc/systemd/system/sonar.service
[Unit]
Description=SonarQube Server
After=syslog.target network.target
 
[Service]
Type=forking
ExecStart=/usr/local/sonarqube/bin/linux-x86-64/sonar.sh start
ExecStop= /usr/local/sonarqube/bin/linux-x86-64/sonar.sh stop
LimitNOFILE=65536
LimitNPROC=4096
User=sonar
Group=sonar
Restart=on-failure
 
[Install]
WantedBy=multi-user.target

$ systemctl restart sonar.service
$ systemctl enable --now sonar.service && systemctl status sonar.service
```

## 四. 程序汉化

> 汉化请自行到 Github 下载相应版本，再上传到 `./sonarqube/extensions/plugins`，重启服务即可
>
> 默认账密 admin/admin，http://server-IP:9000

[汉化插件]:https://github.com/xuhuisheng/sonar-l10n-zh

SonarQube 汉化包兼容列表如下：

| **SonarQube** | **9.0** | **9.1** | **9.2** | **9.3** |         |         |         |         |         |         |
| ------------- | ------- | ------- | ------- | ------- | ------- | ------- | ------- | ------- | ------- | ------- |
| sonar-l10n-zh | 9.0     | 9.1     | 9.2     | 9.3     |         |         |         |         |         |         |
| **SonarQube** | **8.0** | **8.1** | **8.2** | **8.3** | **8.4** | **8.5** | **8.6** | **8.7** | **8.8** | **8.9** |
| sonar-l10n-zh | 8.0     | 8.1     | 8.2     | 8.3     | 8.4     | 8.5     | 8.6     | 8.7     | 8.8     | 8.9     |
| **SonarQube** | **7.0** | **7.1** | **7.2** | **7.3** | **7.4** | **7.5** | **7.6** | **7.7** | **7.8** | **7.9** |
| sonar-l10n-zh | 1.20    | 1.21    | 1.22    | 1.23    | 1.24    | 1.25    | 1.26    | 1.27    | 1.28    | 1.29    |
| **SonarQube** | **6.0** | **6.1** | **6.2** | **6.3** | **6.4** | **6.5** | **6.6** | **6.7** |         |         |
| sonar-l10n-zh | 1.12    | 1.13    | 1.14    | 1.15    | 1.16    | 1.17    | 1.18    | 1.19    |         |         |
| **SonarQube** |         |         |         |         | **5.4** | **5.5** | **5.6** |         |         |         |
| sonar-l10n-zh |         |         |         |         | 1.9     | 1.10    | 1.11    |         |         |         |
| **SonarQube** | **4.0** | **4.1** |         |         |         |         |         |         |         |         |
| sonar-l10n-zh | 1.7     | 1.8     |         |         |         |         |         |         |         |         |
| **SonarQube** |         | **3.1** | **3.2** | **3.3** | **3.4** | **3.5** | **3.6** | **3.7** |         |         |
| sonar-l10n-zh |         | 1.0     | 1.1     | 1.2     | 1.3     | 1.4     | 1.5     | 1.6     |         |         |