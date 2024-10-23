> Dockerfile 命令示例

> Dockerfile 是一个用来构建镜像的文本文件，其内容包含了各构建镜像所需的指令和说明

### FROM

> **指定基础镜像**，并且 Dockerfile 中第一条指令必须是 FROM 指令，且在同一个 Dockerfile 中创建多个镜像时，可以使用多个 FROM 指令

**语法：**

```dockerfile
FROM <image> 
FROM <image>:<tag> 
```

其中`<tag>`是可选项，如果没有选择，那么默认值为`latest`

**样例：**

```dockerfile
FROM scratch
FROM scratch:latest
```

---

### MAINTAINER

> **指定生成镜像的作者名称**，指令已被弃用，可以使用 `LABEL` 指令进行替代

**语法：**

```dockerfile
MAINTAINER <name>
```

---

### LABEL

> **为镜像指定标签**

**语法：**

```dockerfile
LABEL <key1>=<value1> <key2>=<value2> ...
```

注：LABEL 是键值对，多个键值对以空格进行隔开，如其中包含空格，可用 " " 进行圈起来

**样例：**

```dockerfile
LABEL version="1.0"
LABEL "com.example.vendor"="ACME Incorporated"
# 太长需要换行则使用\符号
LABEL description="This text illustrates \
      that label-values can span multiple lines."
LABEL multi.label1="value1" \
      multi.label2="value2" \
             other="value3"
```

说明：LABEL 会继承基础镜像中的 LABEL，如遇 key 相同，则值覆盖。另可使用 `docker inspect` 查看镜像标签

```sh
$ docker inspect --format '{{json .Config.Labels}}' test | python3 -m json.tool
# "test"为容器名称，"python3 -m json.tool"为将其格式化为JSON输出
```

---

### ENV

> **设置环境变量**，无论接下来的指令(如 ENV、ADD、COPY 等，其调用格式为 `$variable_name` 或 `${variable_name}` )，还是在容器中运行的程序，都可使用这定义的环境变量

**语法：**

```dockerfile
ENV <key> <value> 
ENV <key>=<value> ... 
```

说明：两者的区别就是第一种是一次设置一个，第二种是一次设置多个

**示例：**

```dockerfile
ENV word hello
RUN echo $word
```

> 注意：
> 如果你想通过 CMD 或者 ENTRYPOINT 指令的 exec 格式来打印环境，就像下面这样：
> `CMD ["echo", $MODE]`
> `CMD ["echo", "$MODE"]`
> 这样都是不能正确输出环境变量的值的，你可以改成 `exec格式` 来执行 `shell命令`，如下所示：
> `CMD ["sh", "-c", "echo $MODE"]`
> 如此，就能正确输出环境变量的值了！

---

### ARG

> **设置环境变量**，构建参数与 ENV 指令一样，都是设置环境变量

**区别：**作用域不一样，ARG 设置的环境变量仅对 Dockerfile 内有效，也就是只有 `docker build` 的过程中有效，构建好的镜像内不存在此环境变量，之后容器运行时也是不会存在此环境变量(另注意：不要使用 ARG 来保存密码之类的信息，因为可通过 `docker history` 可查看到)

ARG 构建命令在 `docker build` 中可直接使用 `--build-arg <varname>=<value>` 来覆盖

**语法：**

```dockerfile
ARG <name>[=<default value>]
```

**示例：**

```dockerfile
FROM busybox
ARG app="python-pip"
RUN apt-get update && apt-get install -y $app && rm -rf /var/lib/apt/lists/*

FROM busybox
ARG user1
ARG buildno

FROM busybox
ARG user1=someuser
ARG buildno=1
```

说明：如 ARG 定义参数默认值，那当 build 镜像时，如没有指定参数值，那将会使用这个默认值

----

### WORKDIR

> **指定工作目录**，用于为 RUN、CMD、ENTRYPOINT、COPY 和 ADD 指令设定工作目录。
>
> 指定的工作目录，会在构建镜像的每一层中都存在（指定的工作目录必须是提前创建好）

`docker build` 构建镜像过程中，每一个 RUN 命令都是新建的一层，只有通过 WORKDIR 创建的目录才会一直存在，另外 WORKDIR 也可调用由 ENV 指定的变量

**语法：**

```dockerfile
WORKDIR <工作目录路径>
```

**样例：**

```dockerfile
WORKDIR /var/log1
WORKDIR /var/log2

ENV DIRPATH /path
WORKDIR $DIRPATH
```

---

### VOLUME

> **定义匿名数据卷**，可实现挂载功能，可以将此地文件夹或者其他容器中的文件夹挂在到这个容器中

**语法：**

```dockerfile
VOLUME ["<路径1>", "<路径2>"...]
VOLUME <路径>
```

说明： ["/路径"] 可以是一个 JsonArray ，也可以是多个值

**样例：**

```dockerfile
VOLUME ["/var/log/"]
VOLUME /var/log
VOLUME /var/log /var/db

# 定义一个匿名卷
FROM ubuntu:16.04
VOLUME /data

# 定义多个匿名卷
FROM ubuntu:16.04
VOLUME ["/data", "/command"]
```

注：一般的使用场景为需要持久化存储数据，这里的`/data`和`/command`目录在容器运行时会自动挂载为匿名卷，任何向`/data`和`/command`目录中写入的信息都不会记录进容器存储层，从而保证了容器存储层的无状态化！容器匿名卷目录指定可以通过`docker run`命令中指定`-v`参数来进行覆盖

---

### USER

> **指定执行后续命令的用户和用户组**，这里只是切换后续命令执行的用户（用户和用户组必须提前已经存在）
>
> 在 USER 命令之前可使用 RUN 命令创建需要的用户，默认情况下容器的运行身份为 root 用户

**语法：**

```dockerfile
# 可以指定用户名或者UID，组名或者GID
USER <user>[:<group>]
USER <UID>[:<GID>]
```

说明：`USER` 指令还可以在 `docker run` 命令中使用 `-u` 参数进行覆盖

**样例：**

```dockerfile
RUN groupadd -r docker && useradd -r -g docker docker
USER docker

# 注意如使用alpine此类基础镜像，创建的命令为addgroup/adduser
RUN set -eux \
 && addgroup --gid 1000 DemoUser \
 && adduser -S -u 1000 -g DemoUser -h /opt/java/ -s /bin/sh -D DemoUser
```

---

### RUN

> **运行指定的命令**，其包含两种语法格式

**语法：**

```dockerfile
# shell格式:像命令行中输入shell脚本命令一样
1. RUN <command>
在linux操作系统上默认为/bin/sh -c
在windows操作系统上默认为cmd /S /C

# exec格式:像是函数调用的格式,可将executable理解成为可执行文件,后面就是参数值
2. RUN ["executable", "param1", "param2"]
```

**样例：**

```dockerfile
# shell格式
RUN /bin/bash -c 'source $HOME/.bashrc; echo $HOME'
# exec格式
RUN ["/bin/bash", "-c", "echo hello"] 

# 设置正确时区样例,一个指令执行更新/下载/安装/清除等操作
ENV TZ=Asia/Shanghai
RUN set -eux \
 && apk add --no-cache --update tzdata \
 && ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime \
 && echo ${TZ} > /etc/timezone \
 && rm -rf /var/cache/apk/*
```

注：多行命令不建议写多个 RUN，原因是 Dockerfile 中每一个指令都会建立一层，n 个 RUN 就构建 n 层镜像，造成镜像的臃肿、多层，增加构建的时间，书写时的换行符是 `\`

---

### CMD

> **容器启动时要运行的命令**，其包含三种语法格式

补充说明：RUN & CMD 区别

**RUN** 是构建容器时就运行的命令以及提交运行结果

**CMD** 是容器启动时执行的命令，在构建时并不运行，构建时仅指定命令是什么

**语法：**

```dockerfile
# 第一种就是shell这种执行方式和写法
CMD command param1 param2

# 第二种是可执行文件加上参数的形式（推荐）
CMD ["executable","param1","param2"] 

# 该写法是为 ENTRYPOINT 指令指定的程序提供默认参数
CMD ["<param1>","<param2>",...]  
```

说明：参数一定要用双引号，不能是单引号，原因是参数传递后，docker 解析的是一个 JSON array

**样例：**

```dockerfile
CMD [ "sh", "-c", "echo $HOME" ]
CMD [ "echo", "$HOME" ] 
```

---

### ENTRYPOINT

> **为容器指定默认运行程序**，类似 CMD 指令的功能，使得容器像是一个单独的可执行程序

补充说明：在 Dockerfile 内，ENTRYPOINT 或 CMD 指令会自动覆盖之前的指令(ENTRYPOINT/CMD)，即指令只能写一条，如写了多条指令也都只有最后一条生效。

另与 CMD 不同的是，由 ENTRYPOINT 启动的程序不会被 `docker run` 命令行指定的参数所覆盖，而且这些**命令行参数会被当作参数传递给 ENTRYPOINT 指令指定的程序**，不过 `docker run` 命令的`--entrypoint`选项的参数可覆盖 ENTRYPOINT 指令指定的程序。

CMD & ENTRYPOINT  区别总结：

- 相同点：
  - 只能写一条，如果写了多条，那么只有最后一条生效
  - 容器启动时才运行，运行时机相同
- 不同点：
  - ENTRYPOINT 不会被运行的 command 覆盖，而 CMD 则会被覆盖
  - 如 Dockerfile 中同时写了 ENTRYPOINT 和 CMD，并且 CMD 指令不是一个完整的可执行命令，那么CMD 指定的内容将会作为 ENTRYPOINT 的参数
  - 如 Dockerfile 中同时写了 ENTRYPOINT 和 CMD，并且 CMD 指令是一个完整的可执行命令，那么两个会互相覆盖

```dockerfile
FROM ubuntu 
ENTRYPOINT ["rm", "docker2"] 
CMD ["-rf"]
# 执行结果：rm docker2 -rf

FROM ubuntu
ENTRYPOINT ["top", "-b"]  
CMD ls -al
# 执行结果：ls -al,top -b不会执行
```

**语法：**

```dockerfile
# exec格式（推荐）
ENTRYPOINT ["executable", "param1", "param2"] 

# shell格式
ENTRYPOINT command param1 param2
```

**样例：**

```dockerfile
FROM ubuntu 
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/* 
ENTRYPOINT ["curl", "-s", "http://ip.cn"]

# 将其构建成镜像ubuntu:v1.2，下面我们创建并启动容器：
docker run -it ubuntu:v1.2

# 将会在控制台输出我们相应的公网IP信息！
# 此时，如果我们还需要获取HTTP头信息时，我们可以这样：
docker run -it ubuntu:v1.2 -i
```

> 组合 ENTRYPOINT 和 CMD 指令的最佳实践：
> 组合使用 ENTRYPOINT 和 CMD 命令式, 确保你一定用的是 exec 表示法. 如果有其中一个用的是 shell 表示法, 或者一个是 shell 表示法, 另一个是 exec 表示法, 你永远得不到你预期的效果。只有当 ENTRYPOINT 和CMD 都用 exec 表示法, 才能得到预期的效果

---

### COPY

> **复制文件或目录到容器里指定路径**，从上下文目录中复制文件或者目录到容器里指定路径

**语法：**

```dockerfile
COPY [--chown=<user>:<group>] <src>... <dest>
COPY [--chown=<user>:<group>] ["<src>",... "<dest>"]
```

- **[--chown=:]** ：可选参数，用户改变复制到容器内文件的拥有者和属组

- **<源路径>** ：源文件或者源目录， 可用通配符表达式，如 `COPY hom* /mydir/` & `COPY hom?.txt /mydir/`，源路径必须是 build 上下文中的路径，不能是其父目录中的文件，如源路径是目录，则其内部文件或子目录会递归复制，但**源路径目录自身不会被复制**，并且指定了多个源路径，或源路径中使用了通配符，则目录路径必须是一个目录，且必须以 `/` 结尾
- **<目标路径>** ：容器内的指定路径，建议为目标路径使用绝对路径，否则 COPY 指令则以 WORKDIR 为其起始路径，另外**如目标路径事先不存在，则会被自动创建**，包括其父目录路径

**样例：**

```dockerfile
# 复制宿主机文件index.html到容器/data/html/index.html
COPY index.html /data/html/index.html   

# 复制宿主机data目录下文件（包括子目录）到容器/data/目录下，并不会复制目录本身
COPY data  /data/    
```

---

### ADD

> **复制文件或目录到容器里指定路径**，指令与 COPY 使用类似**（同样需求下，官方推荐使用 COPY）**
>
> 除原功能类似外，ADD 支持使用 TAR 文件和 URL 路径，并会将其 tar 压缩文件 （gzip,bzip2,xz）解压缩，如指定的是 url，会从指定的 url 下载文件放到目录中（注：如 url 下载的文件为 tar 文件，则不会自动展开）

**语法：**

```dockerfile
ADD [--chown=<user>:<group>] <src>... <dest>
ADD [--chown=<user>:<group>] ["<src>",... "<dest>"]
```

**样例：**

```dockerfile
ADD /data/src/nginx-1.14.0.tar.gz /data/src/
ADD test relativeDir/ 
ADD test /relativeDir
ADD http://example.com/foobar /
```

注：尽量不要把<scr>写成一个文件夹，如果<src>是一个文件夹了，复制整个目录的内容,包括文件系统元数据

---

### EXPOSE

> **为容器打开指定要监听的端口以实现与外部通信**，功能为暴露容器运行时的监听端口给外部，但并不会使容器访问主机的端口，如使得容器与主机的端口有映射关系，则必须在容器启动时加上 `-P` 参数

**语法：**

```dockerfile
EXPOSE <port> [<port>/<protocol>...]
```

**样例：**

```dockerfile
EXPOSE 80/tcp
EXPOSE 80/udp

$ docker run --rm --name nginx -itd -P nginx:v1.4
$ docker run --rm --name nginx -itd -p 80:80 nginx:v1.4
```

---

### ONBUILD

> **用于延迟构建命令的执行**，概要说明就是本次构建镜像的过程中不会执行，当新的 Dockerfile 使用了之前构建的镜像，则会执行之前在 Dockerfile 里的 ONBUILD 指定的命令

`ONBUILD`是一个特殊的指令，它后面跟着的是其他指令，比如`COPY`、`RUN`等，而这些命令在当前镜像被构建时，并不会被执行，只有以当前镜像为基础镜像去构建下一级镜像时，才会被执行。

**语法：**

```dockerfile
ONBUILD <其他指令>
```

**样例：**

```dockerfile
from ubuntu:16.04
WORKDIR /data
ONBUILD RUN mkdir test
```

---

### STOPSIGNAL

> **设置将发送到容器以退出的系统调用信号**，这个信号可以是一个有效的无符号数字，与内核的`syscall`表中的位置相匹配，如`9`，或者是`SIGNAME`格式的信号名，如`SIGKILL`，作用是当容器退出时给系统发送什么样的指令

**语法：**

```dockerfile
STOPSIGNAL signal
```

**样例：**

默认的停止信号是`SIGTERM`，在`docker stop`的时候会给容器内PID为1的进程发送这个signal，通过`--stop-signal`可以设置自己需要的signal，主要的目的是为了让容器内的应用程序在接收到signal之后可以先做一些事情，实现容器的平滑退出。如果不做任何处理，容器将在一段时间之后强制退出，会造成业务的强制中断，这个时间默认是10s。

---

### HEALTHCHECK

> **容器健康状况检查**，用于指定某个程序或指令来监控容器服务的运行状态是否正常

**语法：**

```dockerfile
# 设置检查容器健康状况的命令
HEALTHCHECK [OPTIONS] CMD <命令>

# 如果基础镜像有健康检查指令，使用这行可以屏蔽掉其健康检查指令
HEALTHCHECK NONE
```

OPTIONS 参数说明：
- **--interval=<间隔>**：两次检查的时间间隔，默认为 30s
- **--timeout=<时长>**：检查命令运行超时时间，如超过这个时间，本次检查将判定为失败，默认为 30s
- **--retries=<次数>** ：当连接失败指定次数后，则将容器状态视为 `unhealthy`，默认为 3次
- **--start-period=DURATION**：启动时间，默认为 0s，如指定此参数，则必须大于 0s。参数为需要启动的容器提供了初始化的时间段，在这个时间段如检查失败，则不会记录失败次数，如在启动时间内成功执行了健康检查，则容器将被视为已经启动，如在启动时间内再次出现检查失败，则会记录失败次数

**样例：**

```dockerfile
HEALTHCHECK --interval=5m --timeout=3s \
  CMD curl -f http://localhost/ || exit 1
```

注：`HEALTHCHECK` 命令只能出现一次，如出现多次则只有最后一个生效，另该命令返回值说明了容器的状态：

- 0：healthy - 容器健康，可正常使用；
- 1：unhealthy - 容器工作不正常，需要诊断；
- 2：reserved - 保留，不要使用这个返回值；

在 `CMD` 关键字之后的 `command` 可以是一个 shell 命令

例如：`HEALTHCHECK CMD /bin/check-running` 或一个 exec 数组（参考 [ENTRYPOINT]）

---

### SHELL

> **重写各指令的 Shell 格式所使用的默认 Shell**，默认的 shell，Linux 是 ["/bin/sh", "-c"]，Windows 是 ["cmd", "/S", "/C"]

`SHELL` 指令必须在`dockerfile`中以`JSON`格式编写，而 Windows 则有 cmd、powershell、sh 等，SHELL 指令可出现多次，每条指令都会覆盖所有之前的 SHELL 指令，并影响后续指令

**样例：**

```dockerfile
FROM microsoft/windowsservercore

# Executed as cmd /S /C echo default
RUN echo default

# Executed as cmd /S /C powershell -command Write-Host default
RUN powershell -command Write-Host default

# Executed as powershell -command Write-Host hello
SHELL ["powershell", "-command"]
RUN Write-Host hello

# Executed as cmd /S /C echo hello
SHELL ["cmd", "/S", "/C"]
RUN echo hello
```

当在 Dockerfile 中使用它们的 shell 格式时，以下指令可能会受到 SHELL 指令的影响：`RUN`、`CMD` 和 `ENTRYPOINT`
