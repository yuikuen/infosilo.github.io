> Docker-Compose 配置健康检查

Docker 原生健康检查机制，在 docker-compose 中已加入 healthcheck，配置运行的检查，有关健康检查如何工作的详细信息，可参阅 [HEALTHCHECK Dockerfile](https://docs.docker.com/engine/reference/builder/#healthcheck) 说明的文档

**官网示例**，healthcheck 支持的参数说明如下：

```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost"]
  interval: 1m30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

- test：健康检查命令，必须是字符串或列表，第一个参数必须是 `NONE/CMD/CMD-SHELL`
- interval：健康检查的间隔，默认为 30 秒，单位(h/m/s)
- timeout：健康检查命令运行超时时间，如果超过这个时间，本次健康检查就被视为失败，单位(h/m/s)
- retries：当连续失败指定次数后，则将容器状态视为 unhealthy
- start_period：应用启动期间的健康，检测不计入统计次数，但仍会发生检测

HEALTHCHECK 和 CMD, ENTRYPOINT 一样，HEALTHCHECK 只可以出现一次，如果写了多个，只有最后一个生效

HEALTHCHECK 的 CMD 命令和其他 CMD 命令一样，支持 SHELL 和 EXEC 两种格式。命令的返回值有以下几种：

| 返回值 | 意义                                   |
| ------ | --------------------------------------|
| 0      | healthy                               |
| 1      | unhealthy                             |
| n      | 重试指定次数仍失败，容器将被认为 unhealthy |

**实例参考**

```yaml
version: "3.8"

services:
  flask:
    build:
      context: ./flask
      dockerfile: Dockerfile
    image: flask-demo:latest
    environment:
      - REDIS_HOST=redis-server
      - REDIS_PASS=${REDIS_PASSWORD}
    healthcheck: # 添加健康检测
      test: ["CMD", "curl", "-f", "http://localhost:5000"]
      interval: 30s
      timeout: 3s
      retries: 3
      start_period: 40s
    depends_on:
      redis-server:
        condition: service_healthy
    networks:
      - backend
      - frontend

  redis-server:
    image: redis:latest
    command: redis-server --requirepass ${REDIS_PASSWORD}
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 1s
      timeout: 3s
      retries: 30
    networks:
      - backend

  nginx:
    image: nginx:stable-alpine
    ports:
      - 8000:80
    depends_on:
      - flask
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/conf.d/default.conf:ro
      - ./var/log/nginx:/var/log/nginx
    networks:
      - frontend

networks:
  backend:
  frontend:
```

注意：nginx 依赖的 flask 的状态是 `healthy` 的时候，才会启动，否则等待

```yaml
version: '2.1'
services:
  php:
    tty: true
    build:
      context: .
      dockerfile: tests/Docker/Dockerfile-PHP
      args:
        version: cli
    volumes:
      - ./src:/var/www/src
      - ./tests:/var/www/tests
      - ./build:/var/www/build
      - ./phpunit.xml.dist:/var/www/phpunit.xml.dist
    depends_on:
      couchbase:
        condition: service_healthy
      memcached:
        condition: service_started
      mysql:
        condition: service_healthy
      postgresql:
        condition: service_healthy
      redis:
        condition: service_healthy
  couchbase:
    build:
      context: .
      dockerfile: tests/Docker/Dockerfile-Couchbase
    healthcheck:
      test: ["CMD", "curl", "-f", "http://Administrator:password@localhost:8091/pools/default/buckets/default"]
      interval: 1s
      timeout: 3s
      retries: 60
  memcached:
    image: memcached
    # not sure how to properly healthcheck
  mysql:
    image: mysql
    environment:
      - MYSQL_ALLOW_EMPTY_PASSWORD=yes
      - MYSQL_ROOT_PASSWORD=
      - MYSQL_DATABASE=cache
    healthcheck:
      test: ["CMD", "mysql" ,"-h", "mysql", "-P", "3306", "-u", "root", "-e", "SELECT 1", "cache"]
      interval: 1s
      timeout: 3s
      retries: 30
  postgresql:
    image: postgres
    environment:
      - POSTGRES_PASSWORD=
      - POSTGRES_DB=cache
    healthcheck:
      test: ["CMD", "pg_isready"]
      interval: 1s
      timeout: 3s
      retries: 30
  redis:
    image: redis
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 1s
      timeout: 3s
      retries: 30
```
