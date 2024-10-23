> Docker 开启 2376 远程管理端口

上篇已介绍了 Docker 2375 端口是如何开启并配置使用的。现因开放 2375 端口的监听，从而引发一系列安全问题，针对问题根源可关闭 2375 端口并采用 TLS 加密 2376 端口来解决，详细可参考 [官网](https://docs.docker.com/engine/security/protect-access/)

## 一. 密钥生成

1）创建存放密钥目录，生成 CA 公/私钥

```bash
$ mkdir /etc/docker/tls && cd /etc/docker/tls

# 需要连续输入两次相同的密码
$ openssl genrsa -aes256 -out ca-key.pem 4096

# 依次输入密码、国家、省、市、组织名称等
$ openssl req -new -x509 -days 365 -key ca-key.pem -sha256 -out ca.pem

# 生成server-key.pem
$ openssl genrsa -out server-key.pem 4096
```

2）配置白名单，推荐配置 0.0.0.0，允许所有 IP 连接但只有证书才可以连接成功

```bash
# 把下面的IP换成你自己服务器外网的IP或者域名
$ openssl req -subj "/CN=188.188.3.112" -sha256 -new -key server-key.pem -out server.csr
$ echo subjectAltName = IP:188.188.3.112,IP:0.0.0.0 >> extfile.cnf
```

3）执行命令，将 Docker 守护程序密钥的扩展使用属性设置为仅用于服务器身份验证

```bash
$ echo extendedKeyUsage = serverAuth >> extfile.cnf

# 执行命令，并输入之前设置的密码，生成签名证书
$ openssl x509 -req -days 365 -sha256 -in server.csr -CA ca.pem -CAkey ca-key.pem \
  -CAcreateserial -out server-cert.pem -extfile extfile.cnf
```

4）生成客户端的 key.pem，到时候把生成好的几个公钥私钥拷出去即可

```bash
$ openssl genrsa -out key.pem 4096
$ openssl req -subj '/CN=client' -new -key key.pem -out client.csr

# 执行命令，要使密钥适合客户端身份验证，请创建扩展配置文件
$ echo extendedKeyUsage = clientAuth >> extfile.cnf
```

5）生成 cert.pem，需要输入前面设置的密码，生成签名证书

```bash
$ openssl x509 -req -days 365 -sha256 -in client.csr -CA ca.pem -CAkey ca-key.pem \
  -CAcreateserial -out cert.pem -extfile extfile.cnf
  
# 删除不需要的文件，两个证书签名请求
$ rm -v client.csr server.csr
```

6）修改权限，要保护您的密钥免受意外损坏，请删除其写入权限。要使它们只能被您读取，更改文件模式

```bash
# 证书可以是对外可读的，删除写入权限以防止意外损坏
$ chmod -v 0400 ca-key.pem key.pem server-key.pem
$ chmod -v 0444 ca.pem server-cert.pem cert.pem
```

## 二. 配置修改

修改 Docker 配置，使 Docker 守护程序仅接受来自提供 CA 信任的证书的客户端的连接

```bash
$ vim /lib/systemd/system/docker.service
# ExecStart=/usr/bin/dockerd 下面增加
ExecStart=/usr/bin/dockerd \
        --tlsverify \
        --tlscacert=/etc/docker/tls/ca.pem \
        --tlscert=/etc/docker/tls/server-cert.pem \
        --tlskey=/etc/docker/tls/server-key.pem \
        -H tcp://0.0.0.0:2376 \
        -H unix://var/run/docker.sock

$ systemctl daemon-reload 
$ systemctl restart docker
```

## 三. 检验测试

查看 2376 端口是否启动，并本地连接测试 Docker API 是否可用

```sh
$ netstat -nltp | grep 2376
tcp6       0      0 :::2376                 :::*                    LISTEN      5881/dockerd

# 没有指定证书访问测试
$ curl https://188.188.3.112:2376/info

# 指定证书访问测试
$ curl https://188.188.3.112:2376/info --cert /etc/docker/tls/cert.pem --key /etc/docker/tls/key.pem --cacert /etc/docker/tls/ca.pem
```

## 四. IDEA 配置

将客户端所需的 `ca.pem、cert.pem、key.pem` 3个密钥文件从服务器下载到本地，并修改 IDEA 的 Docker 连接

```xml
# pom.xml 文件参考
<build>
    <plugins>
        <plugin>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-maven-plugin</artifactId>
        </plugin>
        <plugin>
            <groupId>com.spotify</groupId>
            <artifactId>docker-maven-plugin</artifactId>
            <version>1.0.0</version>
            <executions>
                <!--执行mvn package,即执行 mvn clean package docker:build-->
                <execution>
                    <id>build-image</id>
                    <phase>package</phase>
                    <goals>
                        <goal>build</goal>
                    </goals>
                </execution>
            </executions>

            <configuration>
                <!-- 镜像名称 -->
                <imageName>${project.artifactId}</imageName>
                <!-- 指定标签 -->
                <imageTags>
                    <imageTag>latest</imageTag>
                </imageTags>
                <!-- 基础镜像-->
                <baseImage>openjdk:8-jdk-alpine</baseImage>

                <!-- 切换到容器工作目录-->
                <workdir>/</workdir>

                <entryPoint>["java","-jar","${project.build.finalName}.jar"]</entryPoint>

                <!-- 指定远程 Docker API地址  -->
                <dockerHost>https://a.youlai.store:2376</dockerHost>
                <!-- 指定tls证书的目录 -->
                <dockerCertPath>C:\certs\docker\a.youlai.store</dockerCertPath>

                <!-- 复制 jar包到docker容器指定目录-->
                <resources>
                    <resource>
                        <targetPath>/</targetPath>
                        <!-- 用于指定需要复制的根目录，${project.build.directory}表示target目录 -->
                        <directory>${project.build.directory}</directory>
                        <!-- 用于指定需要复制的文件，${project.build.finalName}.jar就是打包后的target目录下的jar包名称　-->
                        <include>${project.build.finalName}.jar</include>
                    </resource>
                </resources>
            </configuration>
        </plugin>
    </plugins>
</build>
```

## 五. 脚本参考

```bash
#!/bin/bash
set -e
if [ -z $1 ];then
        echo "请输入Docker服务器主机名"
        exit 0
fi
HOST=$1
mkdir -p /data/cert/docker
cd /data/cert/docker
openssl genrsa -aes256 -out ca-key.pem 4096
openssl req -new -x509 -days 365 -key ca-key.pem -sha256 -out ca.pem
openssl genrsa -out server-key.pem 4096
openssl req -subj "/CN=$HOST" -sha256 -new -key server-key.pem -out server.csr
# 配置白名单，推荐配置0.0.0.0，允许所有IP连接但只有证书才可以连接成功
echo subjectAltName = DNS:$HOST,IP:0.0.0.0 > extfile.cnf
openssl x509 -req -days 365 -sha256 -in server.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out server-cert.pem -extfile extfile.cnf
openssl genrsa -out key.pem 4096
openssl req -subj '/CN=client' -new -key key.pem -out client.csr
echo extendedKeyUsage = clientAuth > extfile.cnf
openssl x509 -req -days 365 -sha256 -in client.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out cert.pem -extfile extfile.cnf
rm -v client.csr server.csr
chmod -v 0400 ca-key.pem key.pem server-key.pem
chmod -v 0444 ca.pem server-cert.pem cert.pem
```

```bash
#创建 Docker TLS 证书
#!/bin/bash

#相关配置信息
SERVER="IP地址"
PASSWORD="自己设置密码"
COUNTRY="CN"  ##地区码可以随便填
STATE="JS"   ##地区码可以随便填
CITY="SZ"  ##地区码可以随便填
ORGANIZATION="org"   ##自定义随便填
ORGANIZATIONAL_UNIT="org"  ##自定义随便填
EMAIL=""  ##邮箱随便填

###开始生成文件###
echo "开始生成文件"

#切换到生产密钥的目录，按照上面的脚本目录，新建一个pme目录用来生成加密文件
cd /etc/docker/tls/pem
#生成ca私钥(使用aes256加密)
openssl genrsa -aes256 -passout pass:$PASSWORD  -out ca-key.pem 2048
#生成ca证书，填写配置信息
openssl req -new -x509 -passin "pass:$PASSWORD" -days 3650 -key ca-key.pem -sha256 -out ca.pem -subj "/C=$COUNTRY/ST=$STATE/L=$CITY/O=$ORGANIZATION/OU=$ORGANIZATIONAL_UNIT/CN=$SERVER/emailAddress=$EMAIL"

#生成server证书私钥文件
openssl genrsa -out server-key.pem 2048
#生成server证书请求文件
openssl req -subj "/CN=$SERVER" -new -key server-key.pem -out server.csr
#配置白名单  你使用的是服务器Ip的话,请将前面的DNS换成IP  echo subjectAltName = IP:$SERVER,IP:0.0.0.0 >> extfile.cnf
sh -c  'echo "subjectAltName = IP:'$SERVER',IP:0.0.0.0" >> extfile.cnf'
sh -c  'echo "extendedKeyUsage = serverAuth" >> extfile.cnf'
#使用CA证书及CA密钥以及上面的server证书请求文件进行签发，生成server自签证书
openssl x509 -req -days 3650 -in server.csr -CA ca.pem -CAkey ca-key.pem -passin "pass:$PASSWORD" -CAcreateserial  -out server-cert.pem  -extfile extfile.cnf

#生成client证书RSA私钥文件
openssl genrsa -out key.pem 2048
#生成client证书请求文件
openssl req -subj '/CN=client' -new -key key.pem -out client.csr

sh -c 'echo extendedKeyUsage = clientAuth >> extfile.cnf'
#生成client自签证书（根据上面的client私钥文件、client证书请求文件生成）
openssl x509 -req -days 3650 -in client.csr -CA ca.pem -CAkey ca-key.pem  -passin "pass:$PASSWORD" -CAcreateserial -out cert.pem  -extfile extfile.cnf

#更改密钥权限
chmod 0400 ca-key.pem key.pem server-key.pem
#更改密钥权限
chmod 0444 ca.pem server-cert.pem cert.pem
#删除无用文件
rm client.csr server.csr -rf
echo "生成文件完成"
###生成结束###
```
