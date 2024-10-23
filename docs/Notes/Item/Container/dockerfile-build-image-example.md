> Dockerfile 镜像构建示例

Dockerfile 是一个用于编写 Docker 镜像生成过程的文件，其有特定的语法。
基本操作：在一个文件目录中，拥有一个 Dockerfile 文件，其内容满足语法要求，在此路径下执行命令 `docker build --tag name:tag .`，就可构建一个镜像

注：alpine 最小、slim 稍大、默认的最大，Repository 提供的基础镜像，建议采用使用 `alpine`

- `openjdk:<version>`
- `openjdk:<version>-slim`
- `openjdk:<version>-alpine`

**【常规示例】**

```dockerfile
# From 基础镜像
FROM openjdk:8-alpine

#　工作目录[可选]　
WORKDIR /home/xx

# 定义镜像创建者[可选]　
LABEL maintainer=user@example.com

# 前端界面路径[可选]　
# RUN mkdir -p /opt/java/front/spring-boot-example-web

# 后端程序路径
WORKDIR /opt/java/spring-boot-example

COPY ./*.jar ./spring-boot-example.jar
COPY ./libsigar-amd64-linux.so /usr/lib/

# 设置环境或者编码utf8[可选]
#jdk enviroment
ENV JAVA_HOME=/usr/java/jdk1.8.0_231
ENV JRE_HOME=/usr/java/jdk1.8.0_231/jre
ENV CLASSPATH=$JAVA_HOME/lib:$JAVA_HOME/jre/lib
ENV PATH=$JAVA_HOME/bin:$PATH

# 设置端口
EXPOSE 8888

# 设置容器中用户组和用户[可选]
RUN set -eux && addgroup --gid 1000 DemoUser && adduser -S -u 1000 -g DemoUser -h /opt/java/ -s /bin/sh -D DemoUser

# 采用此用户进行操作怕[可选]
USER Rambo
ENTRYPOINT ["java", "-jar", "./spring-boot-example.jar"]

# 执行命令
CMD ["java", "-jar", "/xxx/xxx.jar"]
或者
CMD ["/data/xxx.sh"]
```

**【示例一】设置容器正确时区**

```dockerfile
FROM openjdk:8-alpine
# 效果一样,调用或下载安装
ENV TZ=Asia/Shanghai
RUN set -eux \
 && ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime \
 && echo ${TZ} > /etc/timezone
 
ENV TZ=Asia/Shanghai
RUN set -eux \
 && apk add --no-cache --update tzdata \
 && ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime \
 && echo ${TZ} > /etc/timezone \
 && rm -rf /var/cache/apk/*
```

**【示例二】非 root 用户权限启动应用程序**

```dockerfile
FROM openjdk:8-alpine
# 全称与简写效果是一样的,具体要求：创建用户组/用户、指定家目录和指令环境,并以新用户登陆操作
RUN set -eux \
 && addgroup --gid 1000 userName \
 && adduser --system --uid 1000 --gid 1000 \
    --home=opt/java/ --shell=/bin/sh \
    --disabled-password userName
USER userName

RUN set -eux \
 && addgroup --gid 1000 userName \
 && adduser -S -u 1000 -g userName \
    -h /opt/java/ -s /bin/sh -D userName
USER userName
```
