> Docker-compose 是 Docker 官方的开源项目，负责实现对 Docker 容器集群的快速编排
>
> 简单来说：就是来管理多个容器的，定义启动顺序的，合理编排，方便管理

Docker-compose 将所管理的容器分为三层，分别是工程(Project)、服务(Service)以及容器(Container)

运行目录下的所有文件(docker-compose.yml 文件、extends 文件或环境变量等) 组成一个工程，如无特殊指定，工程名即为当前目录名。

一个工程当中，可包含多个服务，每个服务定义了容器运行的镜像、参数、依赖；一个服务中可包括多个容器实例，但 docker-compose 并没解决负载均衡的问题，因此需要借助其它工具来实现服务发现以及负载均衡，如 consul。

工程配置文件默认为 `docker-compose.yml`，另可通过环境变量 `COMPOSE_FILE -f` 参数自定义配置文件，其自定义多个有依赖关系的服务及每个人服务运行的容器；用户可通过一个单独的 docker-compose.yml 模板文件(YAML 格式)来定义一组关联的应用容器为一个项目(Project)

**YAML 格式注意事项**

- 不支持制表符 tab 键缩进，只能使用空格缩进
- 通过开关缩进 2个空格
- 字符后缩进 1个空格，如冒号`:`、逗号`,`、横杠`-`
- 用 `#` 号来表示注释
- 如包含特殊字符用单引号 `‘’` 引起来作来普通字符，如用双引号`“”` 表示特殊字符本身的意思
- 布尔值必须用 `“”` 括起来
- YAML 区分大小写

| 字段           | 描述                                                         |
| -------------- | ------------------------------------------------------------ |
| build          | 指定 Dockerfile 文件名，需要 build 的子级标签中用 dockerfile 标签指定 |
| dockerfile     | 构建镜像上下文路径                                           |
| context        | 可 dockerfile 路径或执行 git 仓库的 url 地址                 |
| images         | 指定镜像(已存在)                                             |
| command        | 执行命令，会覆盖容器启动后默认执行的命令(覆盖 dockerfile 中的 CMD 命令) |
| container_name | 指定容器名称，由于容器名称是唯一的，如指定自定义名称，则无法 scale 指定容器数量 |
| deploy         | 指定部署和运行服务相关配置，只能在 swarm 模式使用            |
| environment    | 添加环境变量                                                 |
| networks       | 加入网络，引用顶级networks下条目                             |
| ports          | 暴露容器端口，与 -p 相同                                     |
| volumes        | 挂载一个宿主机目录或命令卷到容器，命令卷要在顶级 volumes 定义卷名称 |
| volumes_from   | 从另一个服务或容器挂载卷，可选参数：ro 和 rw（仅版本 2 支持） |
| hostname       | 在容器内设置内核参数                                         |
| links          | 连接到另一个容器，- 服务名称[:]                              |
| privileged     | 用来给容器 root 权限，注意是不安全的，true 开启              |
| restart        | 重启策略，定义是否重启容器                                   |
| depends_on     | 此标签用于解决容器的依赖，启动先后问题，如启动应用容器，则需先启动数据库容器 |

**额外知识：重启策略**

- `no`：默认策略，在容器退出时不重启容器；
- `on-failure`：在容器非正常退出时(退出状态非0)，才会重启容器；
- `on-failure[:max-retries]`：使用 `:max-retries` 选项限制尝试重启的次数，如 `on-failure:3`
- `always`：在容器退出时总是重启容器
- `unless-stopped`：在容器退出时总是重启容器，但不考虑在 Docker 守护进程启动时就已经停止了的容器

**部分参数说明**

```yaml
##服务基于已经存在的镜像
services:
  web:
    image: hello-world
    
##服务基于dockerfile
build: /path/to/build/dir
build: ./dir
build:
  context: ../
  dockerfile: path/of/Dockerfile
build: ./dir
image: webapp:tag

##command
command命令可以覆盖容器启动后默认执行的命令
command: bundle exec thin -p 3000
command: [bundle, exec, thin, -p, 3000]

##container_name
Compose 的容器名称格式是：<项目名称><服务名称><序号>
虽然可以自定义项目名称、服务名称，但是如果你想完全控制容器的命名，可以使用这个标签指定
container_name: app

##depends_on
depends_on解决了容器的依赖、启动先后的问题
version: '2'
services:
  web:
    build: .
    depends_on:
      - db
      - redis
  redis:
    image: redis
  db:
  
##dns
dns: 8.8.8.8
dns:
  - 8.8.8.8
  - 9.9.9.9
dns_search: example.com
dns_search:
  - dc1.example.com
  - dc2.example.com
  
##tmfs
挂载临时目录到容器内部，与run的参数一样效果
tmpfs: /run
tmpfs:
  - /run
  - /tmp
  
##environment
设置镜像变量，它可以保存变量到镜像里，也就是说启动的容器也会包含这些变量设置
environment:
  RACK_ENV: development
  SHOW: 'true'
  SESSION_SECRET:
environment:
  - RACK_ENV=development
  - SHOW=true
  - SESSION_SECRET
  
##expose
用于指定暴露的端口，但是只是作为参考，端口映射的话还得ports标签
expose:
 - "3000"
 - "8000"
 
##external_links
在使用Docker的过程中，我们会有许多单独使用docker run启动的容器，为了使Compose能够连接这些不在docker-compose.yml中定义的容器，我们需要一个特殊的标签，就是external_links，它可以让Compose项目里面的容器连接到那些项目配置外部的容器（前提是外部容器中必须至少有一个容器是连接到与项目内的服务的同一个网络里面）
external_links:
 - redis_1
 - project_db_1:mysql
 - project_db_1:postgresql
 
##extra_hosts
添加主机名的标签，就是往容器内部/etc/hosts文件中添加一些记录
extra_hosts:
 - "somehost:162.242.195.82"
 - "otherhost:50.31.209.229"
 
##labels
向容器添加元数据，和Dockerfile的lable指令一个意思
labels:
  com.example.description: "Accounting webapp"
  com.example.department: "Finance"
  com.example.label-with-empty-value: ""
labels:
  - "com.example.description=Accounting webapp"
  - "com.example.department=Finance"
  - "com.example.label-with-empty-value"
  
##links
解决容器连接问题，与docker的–link一样的效果，会连接到其他服务中的容器,使用的别名将会自动在服务容器中的/etc/hosts里创建
links:
 - db
 - db:database
 - redis
 
##ports
用作端口映射
使用HOST:CONTAINER格式或者只是指定容器的端口，宿主机会随机映射端口
ports:
 - "3000"
 - "8000:8000"
 - "49100:22"
 - "127.0.0.1:8001:8001"
当使用HOST:CONTAINER格式来映射端口时，如果你使用的容器端口小于60你可能会得到错误得结果，因为YAML将会解析xx:yy这种数字格式为60进制。所以建议采用字符串格式

##security_opt
为每个容器覆盖默认的标签。简单说来就是管理全部服务的标签，比如设置全部服务的user标签值为USER
security_opt:
  - label:user:USER
  - label:role:ROLE
  
##volumes
挂载一个目录或者一个已经存在的数据卷容器，可以直接使用[HOST:CONTAINER]这样的格式，或者使用[HOST:CONTAINER:ro]这样的格式，或者对于容器来说，数据卷是只读的，这样可以有效保护宿主机的文件系统。
compose的数据卷指定路径可以是相对路径，使用 . 或者 … 来指定性对目录
volumes:
  // 只是指定一个路径，Docker 会自动在创建一个数据卷（这个路径是容器内部的）。
  - /var/lib/mysql
  
  // 使用绝对路径挂载数据卷
  - /opt/data:/var/lib/mysql
  
  // 以 Compose 配置文件为中心的相对路径作为数据卷挂载到容器。
  - ./cache:/tmp/cache
  
  // 使用用户的相对路径（~/ 表示的目录是 /home/<用户目录>/ 或者 /root/）。
  - ~/configs:/etc/configs/:ro
  
  // 已经存在的命名的数据卷。
  - datavolume:/var/lib/mysql
  
如果你不使用宿主机的路径，你可以指定一个volume_driver。
volume_driver: mydriver

##volumes_from
从其它容器或者服务挂载数据卷，可选的参数是:ro或者:rw，前者表示容器只读，后者表示容器对数据卷是可读可写的，默认是可读可写的
volumes_from:
  - service_name
  - service_name:ro
  - container:container_name
  - container:container_name:rw
  
##network_mode
网络模式，与docker client的–net参数类似，只是相对多了一个service:[sevice name]的格式
network_mode: "bridge"
network_mode: "host"
network_mode: "none"
network_mode: "service:[service name]"
network_mode: "container:[container name/id]"

##networks
加入指定网络
services:
  some-service:
    networks:
     - some-network
     - other-network
```

**Docker-Compose 常用命令**

运行时需要结合 `docker-compose` 一起使用，且必须要在含有 `docker-compose.yml` 文件的目录中

| 命令               | 描述                         |
| ------------------ | ---------------------------- |
| build              | 重新构建服务                 |
| ps                 | 列出容器                     |
| up                 | 创建和启动容器               |
| exec               | 在容器里面执行命令           |
| scale              | 指定一个服务容器启动数量     |
| top                | 显示正运行的容器进程         |
| logs               | 查看服务容器的输出           |
| down               | 删除容器、网络、数据卷和镜像 |
| stop/start/restart | 停止/启动/重启服务           |

**示例分析1**：单 docker-compose.yml

```yaml
version: "3.7"  # docker版本
services:  # 工程服务的模块
  redis:  # 服务1名称(自定义)
    image: redis:alpine  # 镜像名称(已存在)
    ports:  # 映射端口号，格式效果一样
      - "6379"  # - "6379:6379"
    networks:  # 项目指定在一个网络中
      - frontend
    deploy:  # 指定运行服务相关配置
      replicas: 2  # 副本数为2个
      update_config:  # 更新相关配置
        parallelism: 2
        delay: 10s
      restart_policy:  # 重启策略
        condition: on-failure
  db:
    image: postgres:9.4
    volumes:  # 映射至宿主机目录
      - db-data:/var/lib/postgresql/data
    networks:
      - backend
    deploy:
      placement:
        constraints: [node.role == manager]
  vote:
    image: dockersamples/examplevotingapp_vote:before
    ports:
      - "5000:80"
    networks:
      - frontend
    depends_on:                      # 启动顺序，redis启动后才启动vote
      - redis
    deploy:
      replicas: 2
      update_config:
        parallelism: 2
      restart_policy:
        condition: on-failure
  result:
    image: dockersamples/examplevotingapp_result:before
    ports:
      - "5001:80"
    networks:
      - backend
    depends_on:
      - db
    deploy:
      replicas: 1
      update_config:
        parallelism: 2
        delay: 10s
      restart_policy:
        condition: on-failure
  worker:
    image: dockersamples/examplevotingapp_worker
    networks:
      - frontend
      - backend
    deploy:
      mode: replicated
      replicas: 1
      labels: [APP=VOTING]
      restart_policy:
        condition: on-failure
        delay: 10s
        max_attempts: 3
        window: 120s
      placement:
        constraints: [node.role == manager]
  visualizer:
    image: dockersamples/visualizer:stable
    ports:
      - "8080:8080"
    stop_grace_period: 1m30s
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock"
    deploy:
      placement:
        constraints: [node.role == manager]
networks:  # 定义服务器到网桥
  frontend:
  backend:
volumes:  # 声明上面服务中自动创建的键名 
  db-data:
```

**示例2**：docker-compose.yml + Dockerfile

```yaml
version : "3.0"  #docker的版本
services :   #服务的模块
    tomcat :  #服务名称
        container_name: tomcat01  # 相当于run -name
        image : tomcat:8.0-jre8  #使用镜像名称
        ports :   #端口号 可以是数组
            - "8080:8080"
        networks:
            - hello
        depends_on: #说明该服务器需要依赖mysql redis elsaticsearch 都启动才启动该服务
            -   mysql #书写的服务名
            - redis
            - elsaticsearch
    tomcat1:
        container_name: tomcat02
        image: tomcat:8.0-jre8
        ports:
            - "8081:8080"
        volumes: # 宿主机雨容器中目录数据卷共享
            - ./api:/lumen/api  #自定义路径映射
            - tomcatwebapps:/usr/local/tomcat/webapps
        networks: # 项目指定在一个网络中
            - hello
        depends_on:
            - mysql
            - redis
            - elsaticsearch
        healthcheck: #心跳机制
            test: ["CMD", "curl", "-f","http://localhost"]
            interval: 1m30s
            timeout: 10s
            retries: 3
       # sysctls: # 用来修改容器内系统的参数
           # - net.core.somaxconn:1024
           # - net.ipv4.tcp_syncookies:0
        ulimits: # 用来修改容器内系统最大进程数
            nproc: 65535
            nofile:
                soft: 20000
                hard: 40000

    mysql :
        container_name: mysql
        image : mysql:5.7.23
        ports:
            -   "3307:3306"
        volumes:
            - mysqldata:/var/lib/mysql
            - mysqlconf:/etc/mysql
        #environment: # 环境变量 如果密码比较敏感 可以使用env_file 来保存配置文件
        #    - MYSQL_ROOR_PASSWORD:root
        environment:
            - MYSQL_VERSION=5.6
            - MYSQL_DATABASE=${MYSQL_DATABASE}
            - MYSQL_USER=root
            - MYSQL_PASSWORD=yes
            #- MYSQL_ROOT_PASSWcORD=${MYSQL_ROOT_PASSWORD}
            - MYSQL_ROOT_PASSWCORD=root
            - MYSQL_ALLOW_EMPTY_PASSWORD=yes
            - MYSQL_RANDOM_ROOT_PASSWORD=123456
        networks:
            - hello

    redis :
        image : redis:5.0.10
        container_name: redis
        ports:
            -   "6380:6379"
        volumes:
            -   redisdata:/data
        networks:
            - hello
       # command:
        #    -   "redis-server --appendonly yes" # run镜像之后覆盖容器默认命令
    elsaticsearch:
        build:
            context: .  #用来指定dockerfile的目录，
            dockerfile: Dockerfile #指定文件名
        hostname: elasticsearch
        networks:
            - hello

volumes: #声明上面服务中自动创建的键名
    tomcatwebapps: # 生命键名的数据卷 自动创建键名会在文件夹名会加入项目名
        external : false # 使用自定义卷名 # true 确定使用卷名
    mysqldata:
    mysqlconf:
    redisdata:

networks: #定义服务器到网桥
    hello: #定义上面使用的网桥 默认网桥为bridge
        external : false # 使用外部的网桥名称  如果没有该行 或者为false 则自动创建一个项目名称加上定义的网桥名称例（hello_hello）
```

```dockerfile
FROM elasticsearch:7.17.7
#RUN yum install -y vim
EXPOSE 5672
EXPOSE 15672
WORKDIR /lumen
WORKDIR api
COPY api/index.php /lumen/api
```