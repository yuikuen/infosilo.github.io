> Dockerfile 构建 OpenJDK8u327-font(1001)

源镜像使用 `frolvlad` 封装好的 [alpine-glibc](https://github.com/Docker-Hub-frolvlad/docker-alpine-glibc) 作为基础镜像，仅增加了 Jar 包指定执行目录及账户，另外为了更好的支持中文格式，安装了 Win 宋体字体

```dockerfile
FROM frolvlad/alpine-glibc:alpine-3.17_glibc-2.34

ARG JAVA_PACKAGE=8.372.07-r0

ENV TZ=Asia/Shanghai \
    LANG='zh_CN.UTF-8' LANGUAGE='zh_CN:zh' LC_ALL='zh_CN.UTF-8'
  # LANG='en_US.UTF-8' LANGUAGE='en_US:en'

COPY ./SimSun.ttf /usr/share/fonts/win/simsun.ttf

RUN apk add --update tzdata curl openjdk8=${JAVA_PACKAGE} \
 && set -eux \
 && ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime \
 && echo ${TZ} > /etc/timezone \
 && rm -rf /var/cache/apk/* \
 && mkdir /deployments \
 && chmod "g+rwX" /deployments \
 && chown 1001:root /deployments \
 && chmod 777 /usr/share/fonts/win/simsun.* \
 && fc-cache -fv \
 && echo "securerandom.source=file:/dev/urandom" >> /usr/lib/jvm/default-jvm/jre/lib/security/java.security \
 # 关闭安全套接字层SSL加密,防止与SQL_Server连接时报错,可按需忽略
 && sed -i 's/^jdk.tls.disabledAlgorithms=SSLv3/#&/' /usr/lib/jvm/java-1.8-openjdk/jre/lib/security/java.security
```