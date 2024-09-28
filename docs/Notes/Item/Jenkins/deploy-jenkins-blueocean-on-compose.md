> 因之前使用的 `jenkinsci/blueocean` 已多年未作更新，故改为 `jenkins/jenkins:2.426.1-lts-alpine`。但后期调用宿主机执行 `pipeline & docker` 命令会报错，提前挂载的 library 也无效

![](https://img.17121203.xyz/i/2024/09/15/i7oiyu-0.webp)

目前方案为使用自行构建镜像方式，提前配置软件源及安装 Blue Ocean 插件，另不再调用本地宿主机，而是通过 `docker:dind` 容器进行调用，后续更新直接修改 Dockerfile 的 image 版本即可

```dockerfile
FROM jenkins/jenkins:2.476-jdk17

USER root
# 设置Jenkins下载源和更新源为清华大学镜像
ENV JENKINS_UC_DOWNLOAD=https://mirrors.tuna.tsinghua.edu.cn/jenkins/
ENV JENKINS_UC=https://mirrors.tuna.tsinghua.edu.cn/jenkins/updates
# 替换Debian源为清华大学镜像
RUN sed -i 's@http://deb.debian.org@https://mirrors.tuna.tsinghua.edu.cn@g' /etc/apt/sources.list.d/debian.sources \
    && apt-get update \
    && apt-get install -y lsb-release apt-transport-https ca-certificates \
    && curl -fsSLo /usr/share/keyrings/docker-archive-keyring.asc https://download.docker.com/linux/debian/gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.asc] https://download.docker.com/linux/debian $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list \
    && apt-get update \
    && apt-get install -y docker-ce-cli \
    # 清理不必要的文件和缓存
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

USER jenkins
# 安装Jenkins插件：Blue Ocean和Docker Workflow
RUN jenkins-plugin-cli --plugins "blueocean docker-workflow"
```

通过挂载 volumes 方式，后期构建任务以 `docker:dind` 容器执行

```yml
#version: '3.9'
services:
  jenkins:
    build:
      context: '/opt/devops/jenkins'
      dockerfile: Dockerfile
    image: jenkins-blueocean:2.476-jdk17
    container_name: jenkins-blueocean
    restart: always
    privileged: true
    user: root
    tty: true
    networks:
      - jenkins
    ports:
      - 8080:8080
      - 50000:50000
    environment:
      - TZ=Asia/Shanghai
      - DOCKER_HOST=tcp://docker:2376
      - DOCKER_CERT_PATH=/certs/client
      - DOCKER_TLS_VERIFY=1
    volumes:
      - ./jenkins-data:/var/jenkins_home
      - ./jenkins-docker-certs:/certs/client:ro

  dind:
    image: "docker:27.2.1-dind"
    container_name: jenkins-docker
    restart: always
    privileged: true
    tty: true
    networks:
      jenkins:
        aliases:
          - docker
    ports:
      - 2376:2376
    environment:
      - DOCKER_TLS_CERTDIR=/certs
    volumes:
      - ./jenkins-data:/var/jenkins_home
      - ./jenkins-docker-certs:/certs/client
      - ./jenkins-docker-graph:/var/lib/docker
      - /lib/modules/:/lib/modules/
    command: --storage-driver=overlay2

volumes:
  jenkins-data:
  jenkins-docker-certs:
  jenkins-docker-graph:
networks:
  jenkins:
    driver: bridge
```

```sh
$ docker ps -a
CONTAINER ID   IMAGE                           COMMAND                  CREATED             STATUS             PORTS                                                                                      NAMES
664bfc0cebfe   jenkins-blueocean:2.476-jdk17   "/usr/bin/tini -- /u…"   About an hour ago   Up About an hour   0.0.0.0:8080->8080/tcp, :::8080->8080/tcp, 0.0.0.0:50000->50000/tcp, :::50000->50000/tcp   jenkins-blueocean
2bf32ab56b23   docker:27.2.1-dind              "dockerd-entrypoint.…"   About an hour ago   Up About an hour   2375/tcp, 0.0.0.0:2376->2376/tcp, :::2376->2376/tcp                                        jenkins-docker

$ docker exec -it jenkins-blueocean cat /var/jenkins_home/secrets/initialAdminPassword
0d3404cf9ec54d44aafa294b99a34b70
```

![](https://img.17121203.xyz/i/2024/09/15/m9yyxk-0.webp)
