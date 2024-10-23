> CentOS7 安装 Docker-Compose
>
> [Docker Compose ](https://docs.docker.com/compose/install/other/) 是 docker 提供的一个命令行工具，用来定义和运行由多个容器组成的应用

## 一. 官方安装

1）[GitHub Compose](https://github.com/docker/compose/releases) 官方地址选择版本，以下述命令进行下载（可手动修改版本号）

```sh
$ curl -SL https://github.com/docker/compose/releases/download/v2.16.0/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
```

2）添加执行权限并检查

```sh
$ chmod +x /usr/local/bin/docker-compose
$ docker-compose version
Docker Compose version v2.16.0
```

## 二. 常规安装

一般采用官网下载的方式在国内访问都较慢，可直接下载版本文件至本地进行安装

```sh
$ wget https://github.com/docker/compose/releases/download/v2.16.0/docker-compose-linux-x86_64
$ mv docker-compose-linux-x86_64 /usr/local/bin/docker-compose
$ chmod +x /usr/local/bin/docker-compose
$ docker-compose --version
Docker Compose version v2.16.0
```
