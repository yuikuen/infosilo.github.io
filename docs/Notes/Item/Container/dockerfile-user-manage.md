> 简要说明 Dockerfile 构建时的进行运行用户

默认情况下，容器中的进程以 root 用户权限运行，并且这个 root 用户和宿主机中的 root 是同一个用户，那就意味着一旦容器中的拥有最高权限，所有这些独立的容器(其实是进程)可以共享一个内核，就有可能控制宿主机上的一切！

## 一. 默认用户

一般如果容器启动，不做相关的设置，进程默认都以 root 用户权限启动，下面以各个 demo 进行说明

```sh
$ docker run -d --name sleepme ubuntu sleep infinity
$ docker exec -it sleepme bash
root@88f0dec72938:/# id
uid=0(root) gid=0(root) groups=0(root)
```

注：上面命令中并没使用 sudo，并且宿主机登录用户为 root，uid 为 0

在宿主机中查看 sleep 进程信息：

```sh
$ ps -ef|grep sleep
root     13741 13721  0 11:41 ?        00:00:00 sleep infinity
root     13825 13606  0 11:54 pts/0    00:00:00 grep --color=auto sleep
```

sleep 进程的有效用户名称是 root，也就是说 sleep 进程具有 root 权限，然后进入容器内部查看，sleep 进程也具有 root 权限；

```sh
root@88f0dec72938:/# ps aux| grep sleepme
root        27  0.0  0.0   3312   740 pts/0    S+   04:18   0:00 grep --color=auto sleepme
```

那就对应了<font color=red>容器内的 root 用户和宿主机上的 root 用户是同一个</font>，原因就是整个系统共享同一个内核，而内核只管理一套 uid 和 gid

## 二. 指定身份

> 通过 Dockerfile 中的 USER 命令或者是 docker run 命令的 `--user` 参数指定容器中进程的用户身份

1）在 Dockerfile 中添加一个用户 appuser，并使用 USER 命令指定以该用户的身份运行程序

```dockerfile
$ cat Dockerfile
FROM ubuntu
RUN groupadd -g 1000 appuser && useradd -m -u 1000 -g appuser appuser
USER appuser
ENTRYPOINT ["sleep", "infinity"]
```
```sh
$ docker build -t sleep .
Sending build context to Docker daemon  2.048kB
Step 1/4 : FROM ubuntu
 ---> ba6acccedd29
Step 2/4 : RUN groupadd -g 1000 appuser && useradd -m -u 1000 -g appuser appuser
 ---> Running in 8e6f790c60b4
Removing intermediate container 8e6f790c60b4
 ---> ca170f1eae32
Step 3/4 : USER appuser
 ---> Running in 0bc69a433a89
Removing intermediate container 0bc69a433a89
 ---> 3028bcebd365
Step 4/4 : ENTRYPOINT ["sleep", "infinity"]
 ---> Running in 1eeb8df4c0b5
Removing intermediate container 1eeb8df4c0b5
 ---> 1dbc7e1f8b10
Successfully built 1dbc7e1f8b10
Successfully tagged sleep:latest
```

使用 sleep 镜像启动一个容器，并查看进程信息

```sh
$ docker run -d --name sleepme2 sleep:latest
# 宿主机
ps aux| grep sleep
1000     14821  0.0  0.0   2516   592 ?        Ss   13:44   0:00 sleep infinity

$ docker exec -it sleepme2 bash
appuser@13e744b0e65f:/$ ps aux|grep sleep
appuser      1  0.0  0.0   2516   592 ?        Ss   05:44   0:00 sleep infinity
```

容器中的当前用户就是设置的 appuser，查看容器中的 `/etc/passwd` 文件，会发现 appuser 的 uid 就是 1000

（如宿主机系统中存在一个 uid 为 1000 的用户，那容器中的程序以 appuser (1000) 的身份运行，那宿主机就会将此认为是宿主机的 1000 用户，所以在容器内部，用户 appuser 能够获取容器外部用户 1000 的权利和特权，并且在宿主机上授予用户或 uid 1000 的特权也将授予容器内的 appuser）


2）通过 `docker run ` 命令的 `--user` 参数指定容器中进程的用户身份

```sh
$ docker run -d --user 1000 --name sleepmd ubuntu sleep infinity
$ ps aux| grep sleep
1000     15067  0.2  0.0   2516   588 ?        Ss   13:58   0:00 sleep infinity
```

因在命令行上指令了参数 `--user 1000`，所以这里 sleep 进程的有效用户显示为 1000

```bash
$ docker run -d --user 0 --name sleepme2 ubuntu sleep infinity
$ ps aux|grep sleep
root     15425  0.2  0.0   2516   528 ?        Ss   14:07   0:00 sleep infinity
```

指定了 `--user 0` 参数的进程，显示有效用户为 root，说明命令行参数覆盖了 Dockerfile 中 USER 命令的设置

## 三. 实例介绍

- Alpine 指定用户执行程序

```sh
# alpine测试用户创建
$ cat Dockerfile 
FROM alpine:3.15.0
RUN addgroup -g 1001 -S appuser && adduser -u 1001 -S appuser -G appuser
USER 1001
ENTRYPOINT ["sleep","3600"]

# jdk:alpine创建用户并指定用户运行jar进程
$ cat Dockerfile 
FROM yk-harbor.net/public/jdk:alpine_glibc-8u202 
RUN addgroup -g 1001 -S vault && adduser -u 1001 -S vault -G vault
USER vault 
ADD app.jar /
ENTRYPOINT ["sh","-c","java ${JAVA_OPTS} -jar /app.jar ${0} ${@}"]
```

**另外 Ubuntu 与 Centos 下 useradd 与 adduser 有所不同，在此记录一下**

```dockerfile
# 基础镜像
FROM ubuntu
# build参数
ARG user=test
# 安装依赖
RUN apt-get update && apt-get install -y sudo 
# 添加用户：赋予sudo权限，指定密码
RUN useradd --create-home --no-log-init --shell /bin/bash ${user} \
    && adduser ${user} sudo \
    && echo "${user}:1" | chpasswd
# 改变用户的UID和GID
# RUN usermod -u 1000 ${user} && usermod -G 1000 ${user}
# 指定容器起来的工作目录
WORKDIR /home/${user}
# 指定容器起来的登录用户
USER ${user}
# RUN是构建时执行
RUN echo "${user}" > world.txt
```
