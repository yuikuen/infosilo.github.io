> 记录 Ubuntu-24.04 下的 Docker 安装

## 一. 依赖环境

1. 安装依赖文件

```sh
$ sudo apt update
$ sudo apt install apt-transport-https ca-certificates curl gnupg-agent software-properties-common -y
```

2. 配置 GPG 密码、设置 stable 仓库

```sh
$ suod curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
$ sudo add-apt-repository \
"deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
```

PS：如提示连接异常，则更换国内阿里云源进行配置

```sh
$ sudo curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo apt-key add -
$ sudo add-apt-repository  \
"deb [arch=amd64] https://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable"
```

## 二. 安装 Docker

### 2.1 安装最新

```sh
$ sudo apt-get update
$ sudo apt install docker-ce docker-ce-cli containerd.io -y
```

安装完成后，Docker 服务将自动启动

```sh
$ sudo docker --version; sudo systemctl status docker
```

### 2.2 指定版本

如有需要指定版本，可查阅需要的安装版本

```sh
$ sudo apt list -a docker-ce
$ sudo apt install docker-ce=<VERSION> docker-ce-cli=<VERSION> containerd.io
```

### 2.3 禁止更新

如需阻止 Docker 自动更新，锁住它的版本

```sh
$ sudo apt-mark hold docker-ce
```

### 2.4 设置用户

默认情况下，只有 root 或具有 sudo 权限的用户可执行命令；如需要以非 root 用户执行命令，则需要将指定用户添加到 Docker 用户组（该用户组在软件安装过程中已被创建）

```sh
$ sudo useradd -aG docker $USER # $USER代表当前用户名
```

## 三. 安装 Compose

从 GitHub 的 Releases 中下载对应版本的 `docker-compose` 程序文件，授予执行权限即可

```sh
$ sudo curl -L "https://github.com/docker/compose/releases/download/v2.29.2/docker-compose-linux-$(uname -m)" -o /usr/local/bin/docker-compose
$ sudo chmod +x /usr/local/bin/docker-compose
$ sudo docker-compose --version 
```

## 四. 配置优化

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
$ sudo systemctl daemon-reload; sudo systemctl restart docker
```

## 五. 卸载 Docker

!!! Warning "**温馨提示**"
    在卸载 Docker 前，最好移除所有的容器、镜像、卷和网络；
    停止所有正运行的容器，并且移除所有的 Docker 对象；

```sh
$ sudo docker container stop $(docker container ls -aq)
$ sudo docker system prune -a --volumes
```

```sh
$ sudo apt-get purge docker-ce docker-ce-cli containerd.io
$ sudo apt autoremove
```
