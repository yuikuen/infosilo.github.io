DockerHub 官方镜像目前无法下拉，另外国内的某些镜像站，有时会突然停止提供服务，故自行搭建一个 Docker 加速服务器；

!!! Necessarily
    前提是需要自行准备一台可访问 DockerHub 的境外服务器

## 一. Install Docker & Compose

```sh
# Ubuntu、Debian
$ sudo apt-get update
$ sudo apt-get upgrade

# CentOS、Rocky、RedHat
$ yum update
$ yum upgrade

# Install
$ curl -fsSL https://get.docker.com -o get-docker.sh
$ sh get-docker.sh

# 参考 GitHub 地址查找最新版本号
# GitHub：<https://github.com/docker/compose/releases/latest>
$ curl -L "https://github.com/docker/compose/releases/download/v2.28.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
$ chmod +x /usr/local/bin/docker-compose
$ docker-compose -v
```

## 二. Deploy Registry-Server

编写 `docker-compose.yml` 文件进行部署 Registry-Server

```yml
#version: "3"
services:
  dockerproxy:
    image: registry:2.8.3
    container_name: reg-server
    restart: always
    ports:
      - "5000:5000"
    volumes:
      - ./data:/data
    environment:
      - REGISTRY_PROXY_REMOTEURL=https://registry-1.docker.io
      - REGISTRY_PROXY_USERNAME=dockerhub-username
      - REGISTRY_PROXY_PASSWORD=dockerhub-password
      - REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY=/data
     #- http_proxy=http://10.0.0.1:1080   for-proxy
     #- https_proxy=http://10.0.0.1:1080  for-proxy
```

PS：最后两条为通过局域网 HTTP/HTTPS 代理来加速 Docker 镜像的拉取，境外服务器无需配置；

```sh
$ docker-compose up -d
[+] Running 2/2
 ✔ Network dockerhub_default  Created                                                                                                                           0.1s 
 ✔ Container reg-server       Started                                                                                                                           0.8s 

$ docker ps
CONTAINER ID   IMAGE            COMMAND                  CREATED          STATUS          PORTS                                       NAMES
69048b44056f   registry:2.8.3   "/entrypoint.sh /etc…"   16 seconds ago   Up 15 seconds   0.0.0.0:5000->5000/tcp, :::5000->5000/tcp   reg-server

$ lsof -i:5000
COMMAND    PID USER   FD   TYPE DEVICE SIZE/OFF NODE NAME
docker-pr 1961 root    4u  IPv4  23929      0t0  TCP *:5000 (LISTEN)
docker-pr 1966 root    4u  IPv6  23934      0t0  TCP *:5000 (LISTEN)
```

上述输出即代表 Docker 私有加速服务已搭建完成，另外建议使用 Nginx 或其它中间件反向代理镜像服务器并启用 SSL

## 三. Generate AccessKey

!!! message
    官方无对国内阿里云 DNS 解析的支持，故采用第三方插件的形式使用

操作步骤：

- 获取 Aliyun 的 Key 和 Secret
- 通过镜像容器 Certbot/Certbot 执行验证 DNS 签发证书
- 配置 Nginx 添加证书
- 配置续期证书 Crontab 任务

获取阿里云的 Key 和 Secret 过程：

1. 登录 [RAM 控制台](https://ram.console.aliyun.com/overview)
2. 在左侧导航栏，选择 **身份管理 > 用户**，创建 **用户** 会自动生成一对 key 和 secret
3. 根据界面提示完成安全验证
4. 在**创建 AccessKey** 对话框，查看 AccessKey ID 和 AccessKey Secret。另建议**下载 CSV 文件**，下载 AccessKey 信息。或单击**复制**，复制 AccessKey 信息保存下来。

PS：登录名称自定义，另访问方式选择 **OpenAPI 调用访问** 即可，另外创建完成后建议下载 CSV，后续 AccessKey ID 和 AccessKey Secret 会消失。

生成 Key 和 Secret 后，为用户添加权限，或者点击授权，给用户进行 `AliyunDNSFullAccess` 授权，完成后即可进行下一步操作；

## 四. Certbot-Aliyun & Nginx

安装 Aliyun Cli 工具（简化安装过程，采用 Docker 镜像方式）

```sh
$ docker pull certbot/certbot:v2.10.0
$ cat Dockerfile 
FROM certbot/certbot:v2.10.0
RUN pip install certbot-dns-aliyun
$ docker build -t certbot-aliyun .
```

创建和授权对应配置文件，配置 access_key 和 access_key_secret

```sh
$ touch /opt/certbot/credentials.ini
dns_aliyun_access_key = AccessKeyId
dns_aliyun_access_key_secret = AccessKeySecret
$ chmod 600 /opt/certbot/credentials.ini
```

最后执行验证 DNS 签发证书命令，其中签发的方式有以下三种：

- dns-aliyun：使用 DNS TXT 记录获取证书
- standalone：本地运行 HTTP 服务器（不支持通配符）
- webroot：将必要的验证文件保存到指定 webroot 目录内的 .well-known/acme-challenge/
  目录（不支持通配符）

```sh
$ docker run -it --rm \
 -v /opt/certbot:/etc/letsencrypt \
 certbot-aliyun certonly \
 --dns-aliyun-credentials /etc/letsencrypt/credentials.ini \
 -d example.tech -d *.example.tech
```

PS：按照提示选择签发方式 `1`，再输入邮箱账号，之后一直 `y` 即可生成证书文件；

```sh
$ tree . -l 3
.
├── Dockerfile
├── accounts
│   └── acme-v02.api.letsencrypt.org
│       └── directory
│           └── abcdd043a8acc4daec1c90e81f01aa8a
│               ├── meta.json
│               ├── private_key.json
│               └── regr.json
├── archive
│   └── example.tech
│       ├── cert1.pem
│       ├── chain1.pem
│       ├── fullchain1.pem
│       └── privkey1.pem
├── credentials.ini
├── live
│   ├── README
│   └── example.tech
│       ├── README
│       ├── cert.pem -> ../../archive/example.tech/cert1.pem
│       ├── chain.pem -> ../../archive/example.tech/chain1.pem
│       ├── fullchain.pem -> ../../archive/example.tech/fullchain1.pem
│       └── privkey.pem -> ../../archive/example.tech/privkey1.pem
├── readme
├── renewal
│   └── example.tech.conf
└── renewal-hooks
    ├── deploy
    ├── post
    └── pre
3
Segmentation fault (core dumped)
```

部署 Nginx，并通过 [Qualys SSL Labs](https://www.ssllabs.com/ssltest/) 状态工具验证

```yml
$ cat docker-compose.yml 
services:
  nginx:
    image: nginx:1.24.0-alpine3.17-perl
    container_name: proxy
    restart: always
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./conf.d:/etc/nginx/conf.d
      - /opt/certbot:/etc/nginx/certs
      - ./log/nginx:/var/log/nginx
      - ./html:/usr/share/nginx/html
```

```sh
$ cat conf.d/dockerhub.conf 
server {
   listen 80;
   server_name reg.example.tech;
   location / {
       return 301 https://$host$request_uri;
   }
}

server {
   listen 443 ssl;
   server_name reg.example.tech;
   ssl_certificate     /etc/nginx/certs/live/example.tech/fullchain.pem;
   ssl_certificate_key /etc/nginx/certs/live/example.tech/privkey.pem;
   location / {
       proxy_pass http://localhost:5000;
       proxy_set_header Host $host;
       proxy_set_header X-Real-IP $remote_addr;
       proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
       proxy_set_header X-Forwarded-Proto $scheme; 
   }
   # HSTS
   add_header Strict-Transport-Security "max-age=31536000; includeSubDomains";
}
```

## 五. Configuring Docker Json

编辑 `/etc/docker/daemon.json` 

```json
{
    "registry-mirrors": ["https://your_registry_url"]  # your_registry_url 为你的加速地址
}
```

重新加载 systemd 守护进程并重启 Docker

```sh
$ systemctl daemon-reload;systemctl restart docker

$ time docker pull calciumion/new-api
Using default tag: latest
latest:Pulling from calciumion/new-api
ec99f8b99825:Pull complete
a43101c380af:Pull complete
824c2ba96ecb:Pull complete
3feb21a1e4e2:Pull complete
Digest:sha256:41073ec18ebc08ef90795f24ea30878987766ae607d7e3de5c8ede5653ebbfbStatus: Downloaded newer image for calciumion/new-api:latest
docker.io/calciumion/new-api:latest
real
user
sys
1m16.355s
0m0.043s
0m0.047s
```

## 六. Reduced Port Exposure

```sh
# 新建网络
$ docker network create proxy_net
```

```yml
services:
  dockerproxy:
    image: registry:2.8.3
    container_name: reg-server
    restart: always
    # 修改端口监听方式
    expose:
      - "5000"
    volumes:
      - ./data:/data
    environment:
      - REGISTRY_PROXY_REMOTEURL=https://registry-1.docker.io
      - REGISTRY_PROXY_USERNAME=dockerhub-username
      - REGISTRY_PROXY_PASSWORD=dockerhub-password
      - REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY=/data
    # 加入新建网络
    networks:
      - back
networks:
  back:
    external: true
    name: proxy_net
```

```yml
services:
  nginx:
    image: nginx:1.24.0-alpine3.17-perl
    container_name: ng-proxy
    restart: always
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./conf.d:/etc/nginx/conf.d
      - /opt/certbot:/etc/nginx/certs
      - ./log/nginx:/var/log/nginx
      - ./html:/usr/share/nginx/html
    # 加入新建网络
    networks:
      - front
networks:
  front:
    external: true
    name: proxy_net
```

```sh
server {
   listen 80;
   server_name reg.example.tech;
   location / {
       return 301 https://$host$request_uri;
   }
}

server {
   listen 443 ssl;
   server_name reg.example.tech;
   ssl_certificate     /etc/nginx/certs/live/example.tech/fullchain.pem;
   ssl_certificate_key /etc/nginx/certs/live/example.tech/privkey.pem;
   location / {
       # 改为back容器名称
       proxy_pass http://dockerproxy:5000;
       proxy_set_header Host $host;
       proxy_set_header X-Real-IP $remote_addr;
       proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
       proxy_set_header X-Forwarded-Proto $scheme; 
   }
   # HSTS
   add_header Strict-Transport-Security "max-age=31536000; includeSubDomains";
}
```
