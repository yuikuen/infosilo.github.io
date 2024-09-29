## 一. 安装说明

> confluence 是一个专业的企业知识管理与协同软件，可以用于构建企业 wiki
>
> 通过它可以实现团队成员之间的协作和知识共享。现在大多数公司都会部署一套 confluence，用作内部 wiki。现在 confluence 已收费，那么下面将介绍下 Docker 安装破解 confluence 的操作记录

Confluence 组成需要数据库的支持，可选择内嵌数据库，为了数据持久化管理，建议自行构建，操作步骤如下：

- Docker、Docker-compose 安装；
- Confluence 容器部署；
- MySQL 数据库部署，建立库并配置；
- 程序关联，并导入数据到建立的库表内；
- 抽出程序文件进行破解，再覆盖原文件；

**Docker 部署方式**

```sh
$ docker run -d --name confluence \
-p 8090:8090 \
--user root:root \
cptactionhank/atlassian-confluence:latest
```

启动后再准备创建一个空的数据库 confluencedb, 连接 mysql，成功后即可启动使用；一般的 Docker 部署为以上内容，不再详细说明，为了更快速部署，现采用 Docker-compose 进行说明

## 二. 编排部署

1）通过 docker-compose.yml 进行编排启动

```yaml
version: '3'
services:
  mysql:
    container_name: mysql
    image: mysql:5.7
    volumes:
      - /home/wiki/mysql/conf.d:/etc/mysql/conf.d
      - /home/wiki/mysql/data:/usr/local/mysql/data
      - /home/wiki/mysql/logs:/usr/local/mysql/logs
    restart: always
    ports:
      - "3306:3306"
    environment:
      MYSQL_ROOT_PASSWORD: confluence
      MYSQL_DATABASE: confluence
      MYSQL_USER: confluence
      MYSQL_PASSWORD: confluence

  confluence:
    container_name: confluence
    restart: always
    image: cptactionhank/atlassian-confluence:latest
    ports:
    - "8090:8090"
    - "8091:8091"
    links:
    - mysql:mysql
```

2）打开 `http://[dockerhost]:8090` 就可以看到 Confluence 的初始化和配置页面，按照提示进行 `产品安装`

> 在选择产品安装时，不勾选额外的插件直接下一步安装

3）到授权码界面下，选抄录 `服务器ID`，然后将系统中的授权文件复制至宿主机目录

```sh
$ docker cp confluence:/opt/atlassian/confluence/confluence/WEB-INF/lib/atlassian-extras-decoder-v2-3.4.1.jar .
```

4）使用 `Win-PC` 下载解压 `Confluence 破解工具`，并将 `atlassian-extras-decoder-v2-3.4.1.jar` 重命名为 `atlassian-extras-2.4.jar`

> 注：下列操作需要在 JAVA 环境下操作

5）输入相关信息至破解程序，点击 `.gen!` 进行破解

![](https://img.17121203.xyz/i/2024/09/29/qkyoji-0.webp)

> Sever ID：输入之前授权码界面下的 `服务器ID`，点击 `.patch!`，选择盘中的 `atlassian-extras-2.4.jar`，然后点击 `.gen!`

6）破解成功后会在 `atlassian-extras-2.4.jar` 所在目录生成一个 `*.bak` 文件(不用管)，现将 `*.jar` 改为原来的文件名 `atlassian-extras-decoder-v2-3.4.1.jar`，
之后通过 `Xftp` 工具将其放置容器的 `/opt/atlassian/confluence/confluence/WEB-INF/lib` 目录，并覆盖原 Jar 文件，重新启动 Confluence

7）重新回到安装并到授权码页面中，将刚破解的 Key 复制至 Confluence 中，接着按提示下一步安装

![](https://img.17121203.xyz/i/2024/09/29/qljs1b-0.webp)

## 三. 配置问题

安装过程中可能会遇到如下问题，可根据问题提示进行修改

- Confluence 不支持数据库排序规则 `utf8_general_ci`，需要使用 `utf8_bin`
  
  可直接在数据库中使用以下命令

  ```sql
  ALTER DATABASE confluence CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
  ALTER DATABASE confluence CHARACTER SET utf8 COLLATE utf8_bin;
  ```

  可使用第三方工具，如 `Navicat` 进行修改

  ![](https://img.17121203.xyz/i/2024/09/29/qm0xjr-0.webp)

  - 不正确的隔离级别，数据库必须使用 `READ-COMMITTED` 作为默认隔离级别
  
  可在 Navicat 中查看当前会话隔离级别,并设置系统隔离级别

  ```sql
  select @@tx_isolation;
  select @@global.tx_isolation;
  SET GLOBAL tx_isolation='READ-COMMITTED';
  ```

  如上不成功可使用 MySQL 通过连接字符串的链接方式，强制设备隔离级别

  ```sql
  jdbc:mysql://mysql:3306/confluence?sessionVariables=tx_isolation='READ-COMMITTED'
  ```

  或在 MySQL 配置文件 `/etc/mysql/mysql.conf.d/mysql.cnf` 中添加

  ```sh
  [client]
  default-character-set = utf8
   
  [mysql]
  default-character-set = utf8
   
  [mysqld]
  character_set_server = utf8
  collation-server = utf8_bin
  default-storage-engine = INNODB
  innodb_log_file_size = 2GB
  binlog_format = row
  transaction_isolation = READ-COMMITTED
  max_allowed_packet = 256M
  ```

- 超时 500
  
  进行容器目录，修改权限

  ```sh
  $ cd /var/atlassian/application-data/confluence/
  $ chmod 777 confluence.cfg.xml
  ```

- 乱码问题

  ```sh
  $ vi /var/atlassian/application-data/confluence/confluence.cfg.xml
  # 根据实际的数据库ip和端口，修改 hibernate.connection.url 的值，本文中修改为
  jdbc:mysql://127.0.0.1:3306/confluence?useUnicode=true&characterEncoding=UTF-8&useSSL=false
  
  # 合并解决隔离问题
  jdbc:mysql://wiki_mysql:3306/confluence?useUnicode=true&characterEncoding=UTF-8&useSSL=false&sessionVariables=tx_isolation='READ-COMMITTED'
  ```