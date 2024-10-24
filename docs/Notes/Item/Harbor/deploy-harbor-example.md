> 本文主要参照 [官方文档](https://goharbor.io/docs/2.7.0/install-config/) 进行离线部署 Harbor 私有仓库

**安装说明**

Harbor 部署的前置环境，请参照 [官方](https://goharbor.io/docs/2.7.0/install-config/installation-prereqs/) 进行配置(前置环境略过，详细操作请自行百度)

- Docker-CE：v23.0.1
- Docker-compose：v2.16.0
- [Harbor](https://github.com/goharbor/harbor/releases)：v2.7.1

**Configure HTTP**

1）默认情况下，Harbor 部署使用 HTTP 来服务注册表请求，具体配置可参考 [官网](https://goharbor.io/docs/2.7.0/install-config/configure-yml-file/)

```sh
$ sudo tar -xf harbor-offline-installer-v2.7.1.tgz
$ cd ./harbor/ 
$ cp harbor.yml.tmpl harbor.yaml
# 仅修改hostname和注释https配置即可
hostname: 188.188.4.105
http:
  port: 80
harbor_admin_password: Harbor12345
database:
  password: root123
  max_idle_conns: 100
  max_open_conns: 900
  conn_max_lifetime: 5m
  conn_max_idle_time: 0
data_volume: /data
...
```

注：如使用 http 方式访问，只需要注释掉 https 的设置，和修改相应的 hostname 就可以了。

2）执行预备脚本`./prepare` ，待测试完出现 `Successfully` 表示可正常部署

```sh
$ ./prepare
Successfully called func: create_root_cert
Generated configuration file: /compose_location/docker-compose.yml
Clean up the input dir

$ ./install.sh
```

默认执行启动脚本即可启动服务，其它设置需要配置 https 才能执行，下面再述说；

**Configure HTTPS**

> 要配置 HTTPS，必须创建 SSL 证书。可使用由受信任的第三方CA签名的证书，也可以使用自签名证书。现介绍如何使用 OpenSSL 创建 CA，以及如何使用 CA 签署服务器证书和客户端证书。另也可以使用其他 CA 提供程序，例如 Let's Encrypt。具体配置可参考 [官网](https://goharbor.io/docs/2.7.0/install-config/configure-https/)

1）配置证书：生成证书颁发机构并颁发证书

```sh
$ sudo mkdir cert ; cd !$
$ openssl genrsa -out ca.key 4096
$ openssl req -x509 -new -nodes -sha512 -days 3650 \
    -subj "/C=CN/ST=DongGuan/L=DongGuan/O=example/OU=Personal/CN=reg.yuikuen.top" \
    -key ca.key \
    -out ca.crt
```

2）生成服务器证书

```sh
# 生成私钥并生成证书签名请求
$ openssl genrsa -out reg.yuikuen.top.key 4096
$ openssl req -sha512 -new \
    -subj "/C=CN/ST=DongGuan/L=DongGuan/O=example/OU=Personal/CN=reg.yuikuen.top" \
    -key reg.yuikuen.top.key \
    -out reg.yuikuen.top.csr
    
# 生成x509 v3扩展文件
# 无论是使用 FQDN 还是 IP 地址连接到 Harbor 主机，都必须创建此文件，以便为 Harbor 主机生成符合主题备用名称 (SAN) 和 x509 v3 的证书扩展要求
$ cat > v3.ext <<-EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1=reg.yuikuen.top
DNS.2=yuikuen.top
DNS.3=pbe.4105-container
EOF

# 使用v3.ext文件为Harbor主机生成证书，将CRS和CRT文件名替换为Harbor主机名
$ openssl x509 -req -sha512 -days 3650 \
    -extfile v3.ext \
    -CA ca.crt -CAkey ca.key -CAcreateserial \
    -in reg.yuikuen.top.csr \
    -out reg.yuikuen.top.crt
```

3）将生成后的 `ca.crt`，`yourdomain.com.crt` 和 `yourdomain.com.key` 文件提供给 Harbor 和 Docker

> Docker 需要将 CRT 文件作为 CA 证书，CERT 文件作为客户端证书

```sh
$ openssl x509 -inform PEM -in reg.yuikuen.top.crt -out reg.yuikuen.top.cert
$ mkdir -p /etc/docker/certs.d/reg.yuikuen.top
$ cp ca.crt *.top.cert *.top.key /etc/docker/certs.d/reg.yuikuen.top/
```

**如果将默认 `nginx` 端口 443映射到其他端口，需要按下述格式创建文件夹** `/etc/docker/certs.d/yourdomain.com:port`

4）重启 Docker 服务由此生效

```sh
$ systemctl daemon-reload ; systemctl restart docker

$ tree /etc/docker/certs.d/
/etc/docker/certs.d/
└── reg.yuikuen.top
    ├── ca.crt                <-- 签署注册表证书的证书颁发机构
    ├── reg.yuikuen.top.cert  <-- 由CA签名的服务器证书
    └── reg.yuikuen.top.key   <-- 由CA签名的服务器密钥

1 directory, 3 files
```

5）前置证书准备好后，下一步进行 [配置文件](https://goharbor.io/docs/2.7.0/install-config/configure-yml-file/) 修改

- hostname：`reg.yuikuen.top` 改为与证书对应的域名
- https.certificate：改为 *.cert 证书路径
- https.private_key：改为 *.key 证书路径

```yaml
$ cat harbor.yml | grep -vE '#|^$'
hostname: reg.yuikuen.top
http:
  port: 80
https:
  port: 443
  certificate: /opt/harbor/certs/reg.yuikuen.top.cert
  private_key: /opt/harbor/certs/reg.yuikuen.top.key
harbor_admin_password: Harbor12345
database:
  password: root123
  max_idle_conns: 100
  max_open_conns: 900
  conn_max_lifetime: 5m
  conn_max_idle_time: 0
data_volume: /data
...
```

6）同样执行预备脚本`./prepare` ，待测试完出现 `Successfully` 表示可正常部署

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

7）配置开机自启动服务

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
ExecStart=/usr/local/bin/docker-compose -f  /opt/tools/harbor/docker-compose.yml up
ExecStop=/usr/local/bin/docker-compose -f /opt/tools/harbor/docker-compose.yml down

[Install]
WantedBy=multi-user.target

$ systemctl enable harbor.service
Created symlink from /etc/systemd/system/multi-user.target.wants/harbor.service to /usr/lib/systemd/system/harbor.service.
```

8）验证功能，为 Harbor 设置 HTTPS 后，可以通过执行以下步骤来验证 HTTPS 连接

- 使用浏览器打开 https://domain.com 查看是否显示 Harbor 界面
- 在运行 Docker 守护进程的 PC 中，添加证书目录并将其证书 `ca.crt/domain.cert/domain.key`，确保未设置 `insecure-Registry`，之后使用 `docker login domain.com:port` 进行登录

**疑难解答：如遇问题可参考以下解决方案**：

1. 如 Chrome 浏览器提示安装警告，需要将 `ca.crt` 的 CA 证书导入浏览器使之消除警告。设置—安全—管理设备证书—添加至【受信任的根证书颁发机构】中(其它浏览器同理操作)

2. 私有部署无法访问，需要提前配置本地的 hosts 解析，具体可参考 [官网](https://goharbor.io/docs/2.7.0/install-config/troubleshoot-installation/)

```sh
$ docker login reg.yuikkuen.top
Username: admin
Password: 
Error response from daemon: Get "https://reg.yuikkuen.top/v2/": dial tcp: lookup reg.yuikkuen.top on 223.5.5.5:53: no such host
```

当 Docker 守护程序在某些操作系统上运行时，可能需要在操作系统级别信任证书

```sh
# Ubuntu
$ cp yourdomain.com.crt /usr/local/share/ca-certificates/yourdomain.com.crt 
$ update-ca-certificates

# CentOS
$ cp yourdomain.com.crt /etc/pki/ca-trust/source/anchors/yourdomain.com.crt
$ update-ca-trust
```

```sh
$ cat /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
188.188.4.105 reg.yuikuen.top

$ docker login reg.yuikuen.top
Username: admin
Password: 
WARNING! Your password will be stored unencrypted in /root/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store

Login Succeeded
```