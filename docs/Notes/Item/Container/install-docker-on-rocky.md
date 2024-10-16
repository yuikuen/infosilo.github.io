> 记录 RockyLinux9.4 下的 Docker 安装

## 一. 依赖环境

1. 安装依赖文件

```sh
$ sudo dnf update -y
$ sudo dnf install -y yum-utils device-mapper-persistent-data lvm2
```

2. 添加 Docker Yum 仓库

```sh
# 官方
$ sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
# 阿里云（国内网络推荐使用）
$ sudo yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
```

## 二. 安装 Docker

### 2.1 安装最新

```sh
$ sudo dnf install docker-ce docker-ce-cli containerd.io
```

### 2.2 指定版本

```sh
$ sudo dnf install docker-ce-<VERSION_STRING> docker-ce-cli-<VERSION_STRING> containerd.io
```

### 2.3 开机自启

```sh
$ sudo systemctl enable --now docker
$ sudo systemctl status docker
```

## 三. 配置优化

目前加速器的配置仅限于旧镜像，如发现速度慢或无法下拉，请查阅自建 Docker 加速器

```json
$ sudo mkdir -p /etc/docker
$ sudo tee /etc/docker/daemon.json <<-'EOF'
{
    "registry-mirrors": [
        "https://eihzr0te.mirror.aliyuncs.com",
        "https://reg.xxxxxxxx.tech",
        "https://dockerpull.com",
        "https://docker.anyhub.us.kg",
        "https://dockerhub.jobcher.com"
    ],
    "max-concurrent-downloads": 10,
    "max-concurrent-uploads": 5,
    "log-driver": "json-file",
    "log-opts": {
        "max-file": "3",
        "max-size": "500m"
    },
    "live-restore": true
}
EOF
```

重新加载 Docker 并重启服务（注意防火墙端口放行）

```sh
$ sudo systemctl daemon-reload; sudo systemctl restart docker
```

## 四. 安装 Compose

从 GitHub 的 Releases 中下载对应版本的 `docker-compose` 程序文件，授予执行权限即可

```sh
$ sudo curl -L "https://github.com/docker/compose/releases/download/v2.29.2/docker-compose-linux-$(uname -m)" -o /usr/local/bin/docker-compose
$ sudo chmod +x /usr/local/bin/docker-compose
$ sudo docker-compose --version 
```

## 卸载 Docker

!!! Warning "**温馨提示**"
    在卸载 Docker 前，最好移除所有的容器、镜像、卷和网络；
    停止所有正运行的容器，并且移除所有的 Docker 对象；

```sh
$ sudo docker container stop $(docker container ls -aq)
$ sudo docker system prune -a --volumes
$ sudo dnf remove docker-ce docker-ce-cli -y
```