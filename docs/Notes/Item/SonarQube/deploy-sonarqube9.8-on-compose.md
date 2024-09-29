> SonarQube 是一个开源的代码分析平台，用来持续分析和评测项目源代码的质量

1）修改宿主的系统最大虚拟内存，否则会报以下错误

`max virtual memory areas vm.max_map_count [65530] is too low, increase to at least [262144]`

```sh
$ cat /etc/sysctl.conf | grep 'max_map_count'
vm.max_map_count = 262144
```

2）编写 `docker-compose.yml` 文件并启动服务

```yaml
version: '3.6'
services:
  pgsql:
    image: postgres:12.14-alpine
    restart: always
    container_name: scan_postgressql
    ports:
      - '5432:5432'
    healthcheck:
      test: ["CMD", "pg_isready"]
      interval: 1s
      timeout: 3s
      retries: 30
    environment:
      TZ: Asia/Shanghai
      POSTGRES_USER: sonar_user
      POSTGRES_PASSWORD: sonar_passwd
      POSTGRES_DB: sonar
    volumes:
      - './postgresql:/var/lib/postgresql'
    networks:
      - sonar-network
      
  sonarqube:
    image: sonarqube:9.8.0-community
    restart: always
    container_name: scan_sonarqube
    ports:
      - '9000:9000'
    healthcheck:
      test: ["CMD-SHELL", "nc -w 1 -z -v localhost 9000"]
      interval: 5m30s
      timeout: 5s
      retries: 2
      start_period: 30s
    depends_on:
      - pgsql
    environment:
      TZ: Asia/Shanghai
      SONARQUBE_JDBC_URL: jdbc:postgresql://pgsql:5432/sonar
      SONARQUBE_JDBC_USERNAME: sonar_user
      SONARQUBE_JDBC_PASSWORD: sonar_passwd
      SONAR_CE_JAVAOPTS: -Xmx1024m
      SONAR_WEB_JAVAOPTS: -Xmx1024m
      SONAR_SEARCH_JAVAOPTS: -Xms1024m -Xmx1024m 
    volumes:
      - '/etc/localtime:/etc/localtime:ro'
      - './sonar_conf:/opt/sonarqube/conf'
      - './sonar_data:/opt/sonarqube/data'
      - './sonar_logs:/opt/sonarqube/logs'
      - './sonar_extensions:/opt/sonarqube/extensions'
    links:
      - 'pgsql'
    networks:
      - sonar-network
networks:
  sonar-network:
    driver: bridge
```

3）启动服务并登录（默认账密 admin）

```sh
$ docker ps
CONTAINER ID   IMAGE                                  COMMAND                  CREATED          STATUS                  PORTS                                                                 NAMES
22d6c6298142   sonarqube:9.8.0-community              "/opt/sonarqube/bin/…"   10 minutes ago   Up 10 minutes           0.0.0.0:9000->9000/tcp                                                sonarqube
625d801711fe   postgres:12.14-alpine                  "docker-entrypoint.s…"   10 minutes ago   Up 10 minutes           0.0.0.0:5432->5432/tcp                                                postgres-sql
```

4）如登录成功可自行 [sonar-l10n-zh](https://github.com/xuhuisheng/sonar-l10n-zh/releases) 下载对应的汉化包

```sh
$ cd ./sonar_extensions/downloads
$ wget https://github.com/xuhuisheng/sonar-l10n-zh/releases/download/sonar-l10n-zh-plugin-9.8/sonar-l10n-zh-plugin-9.8.jar
```

下载完重新 Docker-compose 服务即可生效