> Compose 部署 Harbor-Offline v2.7.1

!!! Tip "注意版本"
    Harbor 从 v2.8.0 开始废弃 Notary & Chartmusuem

1）安装 Docker-CE & Docker-Compose

2）下载软件包并解压至指定目录下，根据各自需求下载对应版本 [Harbor-releases](https://github.com/goharbor/harbor/releases)

```sh
$ wget https://github.com/goharbor/harbor/releases/download/v2.7.1/harbor-offline-installer-v2.7.1.tgz
$ tar -xf harbor-offline-installer-v2.7.1.tgz -C /opt/cicd && cd /opt/cicd/harbor
```

3）创建证书目录，OpenSSL 生成自签证书

```sh
$ mkdir certs ; cd ./certs
$ openssl req -newkey rsa:4096 -nodes -sha256 \
-keyout ca.key \
-x509 -out ca.crt \
-subj "/C=CN/ST=DG/L=DG/O=DEVOPS/CN=reg.yuikuen.top" -days 365000
```

- req：产生证书签发申请命令
- -newkey：生成新私钥
- rsa:4096：生成密钥位数
- -nodes：私钥不加密
- -sha256：使用 SHA-2 哈希算法
- -keyout：将新创建的私钥写入的文件名
- -x509：签发 X.509 格式证书命令，X.509 是最通用的一种签名证书格式
- -out：指定要写入的输出文件名
- -subj：指定用户信息
- -days：有效期（36500 表示 100 年）

4）修改 `harbor.yml` 配置文件

> 主要配置是否使用 Https 协议，其它详细参数说明可参考 [官方链接](https://goharbor.io/docs/2.7.0/install-config/configure-yml-file/)

```sh
$ cat harbor.yml | grep -vE '#|^$'
hostname: reg.yuikuen.top
http:
  port: 80
https:
  port: 443
  # OpenSSL生成自签证书
  certificate: /opt/cicd/harbor/certs/ca.crt
  private_key: /opt/cicd/harbor/certs/ca.key
harbor_admin_password: Abc@123
database:
  password: root123
  max_idle_conns: 100
  max_open_conns: 900
  conn_max_lifetime: 5m
  conn_max_idle_time: 0
data_volume: /opt/cicd/harbor/data
trivy:
  ignore_unfixed: false
  skip_update: false
  offline_scan: false
  security_check: vuln
  insecure: false
jobservice:
  max_job_workers: 10
notification:
  webhook_job_max_retry: 10
chart:
  absolute_url: disabled
log:
  level: info
  local:
    rotate_count: 50
    rotate_size: 200M
    location: /var/log/harbor
_version: 2.7.0
proxy:
  http_proxy:
  https_proxy:
  no_proxy:
  components:
    - core
    - jobservice
    - trivy
upload_purging:
  enabled: true
  age: 168h
  interval: 24h
  dryrun: false
cache:
  enabled: false
  expire_hours: 24
```

5）执行预备脚本`./prepare` ，待测试完出现 `Successfully` 表示可正常部署

```sh
$ ./prepare
Successfully called func: create_root_cert
Generated configuration file: /compose_location/docker-compose.yml
Clean up the input dir

$ ./install.sh --with-chartmuseum --with-notary --with-trivy
✔ ----Harbor has been installed and started successfully.----
```

- `--with-chartmuseum` 安装 chart 仓库，不使用 helm 可不添加该参数
- `--with-notary` 启用镜像签名，必须是 https 才可以，否则会报错 `ERROR:root:Error: the protocol must be https when Harbor is deployed with Notary`

6）配置 Docker & Harbor 和 Host 等服务信任主机

```json
cat /etc/docker/daemon.json 
{
  "insecure-registries": [
      "https://reg.yuikuen.top"
      ],
  "registry-mirrors": [
      "http://hub-mirror.c.163.com/",
      "https://registry.docker-cn.com"
      ],
}
```

添加 host 配置

```sh
$ vim /etc/hosts
188.188.3.33 reg.yuikuen.top
```

7）重启 Docker 服务及重启 Docker-Compose Harbor 加载配置

```sh
$ systemctl daemon-reload && systemctl restart docker
$ cd /opt/cicd/harbor ; docker-compose restart
```

8）登录测试是否正常

> 登录方式：`docker login -u ${USERNAME} -p ${PASSWORD} ${harbor_Server_IP}:${port}`

```sh
$ docker login -u admin -p reg.yuikuen.top
$ echo "Abc@123" | docker login -u admin --password-stdin reg.yuikuen.top
$ docker login https://reg.yuikuen.top
```

9）开机自启动

```sh
$ cat /usr/lib/systemd/system/harbor.service
[Unit]
Description=Harbor
After=docker.service systemd-networkd.service systemd-resolved.service
Requires=docker.service
Documentation=http://github.com/vmware/harbor

[Service]
Type=simple
Restart=on-failure
RestartSec=5
ExecStart=/usr/local/bin/docker-compose -f  /opt/cicd/harbor/docker-compose.yml up
ExecStop=/usr/local/bin/docker-compose -f /opt/cicd/harbor/docker-compose.yml down

[Install]
WantedBy=multi-user.target

$ systemctl enable harbor.service
Created symlink from /etc/systemd/system/multi-user.target.wants/harbor.service to /usr/lib/systemd/system/harbor.service.
```