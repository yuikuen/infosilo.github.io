## 一. 安装说明

> Seata 是阿里巴巴开源的分布式事务中间件，一种分布式事务解决方案，具有高性能和易于使用的微服务架构
>
> 因 Seata 是基于 Java 开发的，所以需要先在机器上准备 Java 环境，并且提前安装好 Nacos (单机或集群都可)

- [Seata 官网](https://seata.io/zh-cn/)
- [Seata 官方代码地址](https://github.com/seata/seata)
- [Seata 官方文档地址](https://seata.io/zh-cn/docs/overview/what-is-seata.html)

注：每个 Spring Cloud Alibaba 版本及其自身所适配的各组件对应版本，建议安装前请根据项目要求进行版本选择；

**服务部署流程：**

- 下载程序项目文件
- 打开 `config/file.conf` 修改 `mode="db"`，数据库连接信息（URL\USERNAME\PASSWORD）
- 创建新数据库 `seata_db`，新建表 `/script/server/db/mysql.sql`（[seata提供的资源信息](https://github.com/seata/seata/tree/1.3.0/script/server/db)）
- 修改并导入 seata 全局参数 `/script/config-center/config.txt`（[seata提供的资源信息](https://github.com/seata/seata/tree/1.3.0/script/config-center)）
- 启动服务并创建开机自启服务

## 二. 安装 Java

1）官方站下载，版本自行选择下载并上传服务器，在此选择 [Jdk1.8](https://www.oracle.com/java/technologies/downloads/#java8)

```bash
$ tar -xf jdk-8u331-linux-x64.tar.gz -C /usr/local/
$ mv /usr/local/jdk1.8.0_331 /usr/local/java
```

2）配置环境变量

```bash
$ vim /etc/profile
# java
JAVA_HOME=/usr/local/java
JRE_HOME=/usr/local/java/jre
PATH=$PATH:$JAVA_HOME/bin:$JRE_HOME/bin
CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar:$JRE_HOME/lib
export JAVA_HOME JRE_HOME PATH CLASSPATH

$ source /etc/profile
```

## 三. 安装 Seata

1）下载并解压，

```bash
$ wget https://github.com/seata/seata/releases/download/v1.3.0/seata-server-1.3.0.tar.gz
$ tar -xf seata-server-1.3.0.tar.gz -C /usr/local/

$ wget https://github.com/seata/seata/archive/refs/heads/1.3.0.zip
$ unzip seata-1.3.0.zip
$ mv seata-1.3.0/script /usr/local/seata
$ cd /usr/local/seata
```

2）创建日志目录并修改配置

```xml
$ mkdir logs
$ vim conf/logback.xml
# 修改成刚创建的目录
29     <property name="LOG_HOME" value="/usr/local/seata/logs"/>
```

3）修改配置文件，存储方式选择 db，配置数据库连接信息，以及处理事务的全局性表

> 注意：driverClassName 驱动的配置需要根据 mysql 的版本决定
>
> - mysql5.+ 使用 driverClassName = "com.mysql.jdbc.Driver"
> - mysql8 使用 driverClassName = "com.mysql.cj.jdbc.Driver"

```bash
$ vim conf/file.conf
## transaction log store, only used in seata-server
store {
  ## store mode: file、db、redis
  mode = "db"   # 修改存储模式,默认为file

  ## database store property
  db {
    ## the implement of javax.sql.DataSource, such as DruidDataSource(druid)/BasicDataSource(dbcp)/HikariDataSource(hikari) etc.
    datasource = "druid"
    ## mysql/oracle/postgresql/h2/oceanbase etc.
    dbType = "mysql"
    driverClassName = "com.mysql.jdbc.Driver"
    # 修改数据库源的地址
    url = "jdbc:mysql://188.188.4.44:3306/seata_db"
    user = "seata"
    password = "seata"
    minConn = 5
    maxConn = 30
    globalTable = "global_table"
    branchTable = "branch_table"
    lockTable = "lock_table"
    queryLimit = 100
    maxWait = 5000
  }
```
4）创建数据库，并导入全局性表

```sql
mysql> create database seata_db character set utf8 collate utf8_bin;
mysql> create user 'seata'@'%' identified by 'seata';
mysql> grant all privileges on seata_db.* to 'seata'@'%';
mysql> flush privileges;

mysql> use seata_db;
mysql> source /usr/local/seata/script/server/db/mysql.sql;
mysql> show databases;
mysql> flush privileges;
```
5）修改 `seata/conf/registry.conf` 文件，配置选用的 a.注册中心类型(nacos)、注册中心的连接信息；b.配置中心的类型，配置中心的连接信息

```bash
$ cd /usr/local/seata/conf
$ vim registry.conf
# 注册中心
registry {
  # file 、nacos 、eureka、redis、zk、consul、etcd3、sofa
  type = "nacos"  # 修改连接方式，默认为file
  
  # 仅修改nacos配置
  nacos {
    application = "seata-server"
    serverAddr = "188.188.4.44:8848"
    group = "SEATA_GROUP"
    namespace = ""
    cluster = "default"
    username = "nacos"
    password = "nacos"
  }

# 配置中心
config {
  # file、nacos 、apollo、zk、consul、etcd3
  type = "nacos"

  nacos {
    serverAddr = "188.188.4.44:8848"
    namespace = ""
    group = "SEATA_GROUP"
    username = "nacos"
    password = "nacos"
  }
```

6）修改 `script/config-center/config.txt` 配置文件，配置 seata 事务的相关属性

> 注意事项：
>
> 1. 下载源码时注意对应版本
> 2. my_test_tx_group 需要与 bootstrap.yml 或者 application.yml 中配置的 seata.tx-service-group 的值一致
> 3. 配置的 default 必须要等于 registry.conf 中配置的 cluster="default"
> 4. store.mode=db配置为db的方式，则需要配置db数据库方式的连接信息 store.db.url、store.db.user、store.db.password，此数据库存储下存放的表 global_table、branch_table、lock_table，用于记录全局性的事务信息
> 5. store.db.driverClassName 的配置连接方式，注意 MySQL 版本驱动配置
> 6. service.default.grouplist=ip:port 为访问 seata 服务器的地址和端口，仅注册中心为 file 时使用，默认端口 8091

```bash
$ vim seata/script/config-center/config.txt
transport.type=TCP
transport.server=NIO
transport.heartbeat=true
transport.enableClientBatchSendRequest=false
transport.threadFactory.bossThreadPrefix=NettyBoss
transport.threadFactory.workerThreadPrefix=NettyServerNIOWorker
transport.threadFactory.serverExecutorThreadPrefix=NettyServerBizHandler
transport.threadFactory.shareBossWorker=false
transport.threadFactory.clientSelectorThreadPrefix=NettyClientSelector
transport.threadFactory.clientSelectorThreadSize=1
transport.threadFactory.clientWorkerThreadPrefix=NettyClientWorkerThread
transport.threadFactory.bossThreadSize=1
transport.threadFactory.workerThreadSize=default
transport.shutdown.wait=3
# 事务分组:异地容错机制
# my_test_tx_group可自定义,如guangzhou、shanghai
# default必须对应registry的cluster
service.vgroupMapping.my_test_tx_group=default
service.default.grouplist=127.0.0.1:8091
service.enableDegrade=false
service.disableGlobalTransaction=false
client.rm.asyncCommitBufferLimit=10000
client.rm.lock.retryInterval=10
client.rm.lock.retryTimes=30
client.rm.lock.retryPolicyBranchRollbackOnConflict=true
client.rm.reportRetryCount=5
client.rm.tableMetaCheckEnable=false
client.rm.sqlParserType=druid
client.rm.reportSuccessEnable=false
client.rm.sagaBranchRegisterEnable=false
client.tm.commitRetryCount=5
client.tm.rollbackRetryCount=5
client.tm.degradeCheck=false
client.tm.degradeCheckAllowTimes=10
client.tm.degradeCheckPeriod=2000
# mode改为db 
store.mode=db
store.file.dir=file_store/data
store.file.maxBranchSessionSize=16384
store.file.maxGlobalSessionSize=512
store.file.fileWriteBufferCacheSize=16384
store.file.flushDiskMode=async
store.file.sessionReloadReadSize=100
store.db.datasource=druid
store.db.dbType=mysql
store.db.driverClassName=com.mysql.jdbc.Driver
# 改为创建的seata数据库,用户名和密码
store.db.url=jdbc:mysql://188.188.4.44:3306/seata_db?useUnicode=true
store.db.user=seata
store.db.password=seata
store.db.minConn=5
store.db.maxConn=30
store.db.globalTable=global_table
store.db.branchTable=branch_table
store.db.queryLimit=100
store.db.lockTable=lock_table
store.db.maxWait=5000
store.redis.host=127.0.0.1
store.redis.port=6379
store.redis.maxConn=10
store.redis.minConn=1
store.redis.database=0
store.redis.password=null
store.redis.queryLimit=100
server.recovery.committingRetryPeriod=1000
server.recovery.asynCommittingRetryPeriod=1000
server.recovery.rollbackingRetryPeriod=1000
server.recovery.timeoutRetryPeriod=1000
server.maxCommitRetryTimeout=-1
server.maxRollbackRetryTimeout=-1
server.rollbackRetryTimeoutUnlockEnable=false
client.undo.dataValidation=true
client.undo.logSerialization=jackson
client.undo.onlyCareUpdateColumns=true
server.undo.logSaveDays=7
server.undo.logDeletePeriod=86400000
client.undo.logTable=undo_log
client.log.exceptionRate=100
transport.serialization=seata
transport.compressor=none
metrics.enabled=false
metrics.registryType=compact
metrics.exporterList=prometheus
metrics.exporterPrometheusPort=9898
```
导入全局参数，可忽略参数直接指定 Nacos 地址即可；

```bash
$ sh ${SEATAPATH}/script/config-center/nacos/nacos-config.sh -h 188.188.4.44 -p 8848 -g SEATA_GROUP -t 787964a5-e21d-4eb8-9999-9bcc9244bd48
-h:默认host，指定nacos远程地址
-p:port，指定nacos远程端口
-g:配置分组，默认值为'SEATA_GROUP' 
-t:租户信息，对应Nacos命名空间ID字段，默认值为空
```
7）浏览器登录 Nacos 查看服务是否添加成功；

8）启动 Seata Server 服务

```bash
$ nohup sh seata-server.sh -p 8091 -h 188.188.4.44 > /tmp/seata.out 2>&1 &
```
| 参数 | 全写         | 作用                       | 备注                                                         |
| :--: | :----------- | :------------------------- | :----------------------------------------------------------- |
|  -h  | --host       | 指定在注册中心注册的 IP    | 不指定时获取当前的 IP，外部访问部署在云环境和容器中的 server 建议指定 |
|  -p  | --port       | 指定 server 启动的端口     | 默认为 8091                                                  |
|  -m  | --storeMode  | 事务日志存储方式           | 支持`file`,`db`,`redis`，默认为 `file` 注:redis需seata-server 1.3版本及以上 |
|  -n  | --serverNode | 用于指定seata-server节点ID | 如 `1`,`2`,`3`..., 默认为 `1`                                |
|  -e  | --seataEnv   | 指定 seata-server 运行环境 | 如 `dev`, `test` 等, 服务启动时会使用 `registry-dev.conf` 这样的配置 |

9）配置 systemd 服务，并设置开机启动

> 如果 java 没有安装在 usr 文件夹下需要添加连接 `ln -s /usr/local/java/bin/java /usr/bin/java`，否则无法启动 

```bash
# 创建启动脚本
$ vim /usr/local/seata/bin/seata-start.sh
#!/bin/bash
# 上述连接无添加时，可在脚本上指定java环境
export JAVA_HOME=/usr/local/java/
sh /usr/local/seata/bin/seata-server.sh -p 8091 -h 188.188.4.44
$ chmod +x !$

# 添加 nacos 服务运行用户
$ useradd -s /sbin/nologin -M seata
$ chown -R seata:seata /usr/local/seata

# 创建 service 文件
$ cat > /usr/lib/systemd/system/seata.service <<EOF
[Unit]
Description=seata
Documentation=https://seata.io/zh-cn/
After=network.targe
 
[Service]
User=seata
Group=seata
Type=simple
ExecStart=/usr/local/seata/bin/seata-start.sh
Restart=always
PrivateTmp=true
 
[Install]
WantedBy=multi-user.target
EOF

$ systemctl daemon-reload && systemctl enable --now seata.service && systemctl status seata
```