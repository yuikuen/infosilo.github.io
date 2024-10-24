> Compose 部署 Harbor-Offline v2.10.0

## 一. 软件简介

Harbor 是由 VMware 公司中国团队为企业用户设计的 Registry server 开源项目，包括了权限管理 (RBAC)、LDAP、审计、管理界面、自我注册、HA 等企业必需的功能，同时针对中国用户的特点，设计镜像复制和中文支持等功能。

另外软件还整合了两个开源的安全组件，一个是 Notary，另一个是 Clair。Notary 类似于私有 CA 中心，而 Clair 则是容器安全扫描工具，通过各大厂商提供的 CVE 漏洞库来获取最新漏洞信息，并扫描用户上传的容器是否存在已知的漏洞信息。

**各组件功能如下：**

- `Harbor-adminserver`：配置管理中心
- `Harbor-dbMySQL`：数据库
- `Harbor-jobservice`：负责镜像复制
- `Harbor-log`：记录操作日志
- `Harbor-ui`：Web 管理页面和 API
- `Nginx`：前端代理，负责前端页面和镜像上传/下载转发
- `Redis`：会话
- `Registry`：镜像存储

**Harbor 相关地址**

- 官网：https://goharbor.io/
- GitHub 地址：https://github.com/goharbor/harbor
- 操作文档：https://goharbor.io/docs/

**Harbor 安装方式**

- 在线安装：从 Docker Hub 下载 Harbor 相关镜像，因此安装软件包非常小
- 离线安装：安装包包含部署的相关镜像，因此安装包比较大

**系统要求:**

**在 Linux 主机上：** docker 17.06.0-ce+ 和 docker-compose 1.18.0+ 。

## 二. 生成证书

随着兼容 OCI 规范的 Helm Chart 在社区上被更广泛地接受，Helm Chart 能以 Artifact 的形式在 Harbor 中存储和管理，不再依赖 ChartMuseum，因此 Harbor 在后续版本中移除对 ChartMuseum 的支持。

虽然被废弃，但并不意味着不能用 Harbor 存储 Chart 了，而是用 OCI Chart 替找。

- 从 v2.6.0 开始弃用 Chartmuseum，并在 v2.8.0 中开始删除。更多详情，请参阅讨论：[15057](https://github.com/goharbor/harbor/discussions/15057)
- 从 v2.6.0 开始弃用 Notary（签名者和服务器），并在 v2.8.0 中开始删除，更多详情，请参阅讨论：[16612](https://github.com/goharbor/harbor/discussions/16612)

> 版本选择的是 harbor-offline-installer-v2.7.2.tgz，暂未删除相关功能模块

### 2.1 基本安装

默认情况下，Harbor 不附带CA证书认证的。也就是说，Harbor 可以在没有安全性的情况下部署，以便可以快速通过 HTTP 连接到访问

```sh
$ tar -xf harbor-offline-installer-v2.7.2.tgz -C /opt/cicd
$ cd /opt/cicd/harbor; cp harbor.yml.tmpl harbor.yml
```

PS：修改 `harbor.yml` 的 hostname 和注释 https 配置即可执行

```sh
$ ./prepare
Successfully called func: create_root_cert
Generated configuration file: /compose_location/docker-compose.yml
Clean up the input dir
$ ./install.sh
```

### 2.2 配置 HTTPS

配置 HTTPS，必须创建 SSL 证书，可使用由受信任的第三方 CA 签名的证书，也可以使用 OpenSSL 进行自签名证书。下述将根据官网操作详细说明如何使用 OpenSSL 创建 CA，以及如何使用 CA 签署服务器证书和客户端证书

#### 2.2.1 生成证书颁发机构证书

> 生产环境中，一般是从 CA 获取证书，例如：阿里云购买域名后可下载相关域名的 CA 证书

1）生成 CA 证书私钥（Generate a CA certificate private key.）

```sh
$ mkdir -p /opt/cicd/harbor/certs
$ cd !$
$ openssl genrsa -out ca.key 4096
Generating RSA private key, 4096 bit long modulus
................++
.............++
e is 65537 (0x10001)
```

2）根据上面生成的 CA 证书私钥，再生成 CA 证书 ca.crt（Generate the CA certificate.）

```sh
$ openssl req -x509 -new -nodes -sha512 -days 3650 \
 -subj "/C=CN/ST=GuangDong/L=DongGuan/O=DevOps/OU=IT/CN=reg.yuikuen.top" \
 -key ca.key \
 -out ca.crt
 
# 参数说明：
-new 指生成证书请求
-x509 表示直接输出证书
-key 指定私钥文件
-days 指定证书过期时间为3650天
-out 导出结束后证书文件
-subj 输入证书拥有者信息
```

- /C=Country 国家 CN
- /ST=State or Province 省 GuangDong
- /L=Location or City 城市 DongGuan
- /O=Organization 组织或企业 DevOps
- /OU=Organization Unit 部门 IT
- /CN=Common Name 域名或 IP

示例说明：参考百度 CA 证书的 `-subj` 相关参数

```sh
CN = baidu.com
O = Beijing Baidu Netcom Science Technology Co., Ltd
L = beijing
ST = beijing
C = CN
```

#### 2.2.2 生成服务器证书

生成 CA 证书后，下面继续生成服务器的证书

> 证书通常包含一个 `.crt` 和 `.key` 文件

1）生成私钥 yourdomain.com.key（Generate a private key.）

```sh
$ openssl genrsa -out reg.yuikuen.top.key 4096
................++
.............++
e is 65537 (0x10001)
```

2）生成证书签名请求(CSR)yourdomain.com.csr（Generate a certificate signing request (CSR).）

```sh
$ openssl req -sha512 -new \
 -subj "/C=CN/ST=GuangDong/L=DongGuan/O=DevOps/OU=IT/CN=reg.yuikuen.top" \
 -key reg.yuikuen.top.key \
 -out reg.yuikuen.top.csr
```

3）生成一个 x509 v3 扩展文件（Generate an x509 v3 extension file.）

> 无论是使用 FQDN 还是 IP 地址连接到 Harbor 主机，都必须创建此文件，Harbor 主机才能生成符合主题备用名称（SAN）和 x509 v3 的证书扩展要求

```sh
$ cat > v3.ext <<-EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1=reg.yuikuen.top
DNS.2=reg.yuikuen
EOF
```

4）使用该 `v3.ext` 文件为 Harbor 主机生成证书 yourdomain.com.crt

```sh
$ openssl x509 -req -sha512 -days 3650 \
 -extfile v3.ext \
 -CA ca.crt -CAkey ca.key -CAcreateserial \
 -in reg.yuikuen.top.csr \
 -out reg.yuikuen.top.crt
Signature ok
subject=/C=CN/ST=GuangDong/L=DongGuan/O=DevOps/OU=IT/CN=reg.yuikuen.top
Getting CA Private Key
```

## 三. 提供证书

生成后证书颁发机构的 `ca.crt` 以及服务器的证书 `yourdomain.com.crt` 和 `yourdomain.com.key` 文件后，需要将其提供到 Harbor 和 Docker 进行证书配置

1）首先将服务器证书 `yourdomain.com.crt` 的编码格式转换为 `yourdomain.com.cert`，提供 Docker 使用

```sh
$ openssl x509 -inform PEM -in reg.yuikuen.top.crt -out reg.yuikuen.top.cert
$ ls -al
total 32
drwxr-xr-x 2 root root  171 Jan  3 14:53 .
drwxr-xr-x 3 root root  154 Jan  3 11:58 ..
-rw-r--r-- 1 root root 2025 Jan  3 14:49 ca.crt
-rw-r--r-- 1 root root 3243 Jan  3 14:48 ca.key
-rw-r--r-- 1 root root   17 Jan  3 14:52 ca.srl
-rw-r--r-- 1 root root 2082 Jan  3 14:53 reg.yuikuen.top.cert
-rw-r--r-- 1 root root 2082 Jan  3 14:52 reg.yuikuen.top.crt
-rw-r--r-- 1 root root 1704 Jan  3 14:51 reg.yuikuen.top.csr
-rw-r--r-- 1 root root 3243 Jan  3 14:50 reg.yuikuen.top.key
-rw-r--r-- 1 root root  252 Jan  3 14:51 v3.ext
```

2）将服务器证书，密钥和 CA 文件复制至 Harbor 主机上的 Docker Certificate 目录中

> 必须创建 Docker 对应的文件目录

```sh
$ echo "188.188.4.44 reg.yuikuen.top" >> /etc/hosts
$ mkdir -p /etc/docker/certs.d/reg.yuikuen.top
$ cp ca.crt *.top.cert *.top.key /etc/docker/certs.d/reg.yuikuen.top/
$ tree /etc/docker/certs.d/
/etc/docker/certs.d/
└── reg.yuikuen.top
    ├── ca.crt               <-- 签署注册表证书的证书颁发机构
    ├── reg.yuikuen.top.cert <-- CA签署的服务器证书
    └── reg.yuikuen.top.key  <-- CA签名的服务器密钥
```

PS：其实就是 Docker 访问镜像仓库的客户端证书，另外如将默认 443 端口修改了的，需要创建对应端口的目录

```sh
$ mkdir -p /etc/docker/certs.d/yourdomain.com:port或/etc/docker/certs.d/harbor_IP:port
```

3）配置 Hosts 并重启 Docker 服务使其生效

```sh
$ systemctl daemon-reload ; systemctl restart docker
```

## 四. 程序安装

1）配置 Harbor 的 YML 文件

```sh
$ tar -xf harbor-offline-installer-v2.7.2.tgz -C /opt/cicd
$ cd /opt/cicd/harbor; cp harbor.yml.tmpl harbor.yml
$ cat harbor.yml | grep -vE '#|^$'
# 修改hostname
hostname: reg.yuikuen.top
http:
  port: 80
https:
  port: 443
  # 配置CA证书路径，指定Harbor服务器的证书以及私钥
  certificate: /opt/cicd/harbor/certs/reg.yuikuen.top.cert
  private_key: /opt/cicd/harbor/certs/reg.yuikuen.top.key
harbor_admin_password: Harbor12345
database:
  password: root123
  max_idle_conns: 100
  max_open_conns: 900
  conn_max_lifetime: 5m
  conn_max_idle_time: 0
# 镜像存储路径
data_volume: /opt/cicd/harbor/data
```

2）执行预备脚本 `./prepare`，待测试完出现 `Successfully` 表示可正常部署

```sh
$ ./prepare
Successfully called func: create_root_cert
Generated configuration file: /compose_location/docker-compose.yml
Clean up the input dir
$ ./install.sh --with-chartmuseum --with-notary --with-trivy
[+] Running 17/17
✔ ----Harbor has been installed and started successfully.----
```

**参数说明**：注意如使用 v2.8.0 及以上版本，则使用 `./install.sh --with-trivy`，其它步骤一致

- Notary：镜像签名认证
- Trivy： 容器漏洞扫描
- Chart Repository Service： Helm chart 仓库服务

3）验证 HTTPS 连接

- 使用浏览器打开 [https://domain.com](https://domain.com/) 查看是否显示 Harbor 界面
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

$ docker login reg.yuikuen.top
$ echo "Harbor12345" | docker login -u admin --password-stdin reg.yuikuen.top
Username: admin
Password: 
WARNING! Your password will be stored unencrypted in /root/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store

Login Succeeded
```

如还是无法登录成功，则配置 Docker 服务信任主机

```json
$ cat /etc/docker/daemon.json 
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

## 五. 附加功能

1）配置开机自启服务

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

