> CentOS 通过 YUM 安装 Docker-CE

Docker 支持 64 位版本 CentOS 7/8 并且要求内核版本不低于 3.10。 CentOS 7 满足最低内核的要求，但由于内核版本比较低，部分功能（如 `overlay2` 存储层驱动）无法使用，并且部分功能可能不太稳定，建议提前升级内核。

## 一. 卸载旧版

旧版本的 Docker 称为 `docker` 或者 `docker-engine`，使用以下命令卸载旧版本：

```sh
$ sudo yum remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-selinux \
                  docker-engine-selinux \
                  docker-engine
```

## 二. 配置源址

执行以下命令安装依赖包，鉴于国内网络问题，强烈建议使用国内源，官方源请在注释中查看

```sh
$ yum -y install yum-utils device-mapper-persistent-data lvm2
$ yum-config-manager \
    --add-repo \
    https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

# 官方源
# $ sudo yum-config-manager \
#     --add-repo \
#     https://download.docker.com/linux/centos/docker-ce.repo

$ sed -i 's/download.docker.com/mirrors.aliyun.com\/docker-ce/g' /etc/yum.repos.d/docker-ce.repo
$ yum makecache fast
```

PS：如果需要测试版本的 Docker 请执行以下命令

```sh
$ sudo yum-config-manager --enable docker-ce-test
```

## 三. 程序安装

查看现可用版本（一般使用社区版 docker-ce）

```sh
$ yum list docker-ce --showduplicates | sort -r
 * updates: mirrors.aliyun.com
Loading mirror speeds from cached hostfile
Loaded plugins: fastestmirror
 * extras: mirrors.aliyun.com
docker-ce.x86_64            3:23.0.1-1.el7                      docker-ce-stable
docker-ce.x86_64            3:23.0.0-1.el7                      docker-ce-stable
...
 * base: mirrors.aliyun.com
Available Packages

# 安装最新版本
$ yum -y install docker-ce docker-ce-cli containerd.io docker-compose-plugin

# 如需安装指定版本，可自定义，如下：
# $ yum -y install docker-ce-[VERSION]
$ yum -y install docker-ce-20.10.* docker-cli-20.10.*

$ docker version
Client: Docker Engine - Community
 Version:           23.0.1
 API version:       1.42
 Go version:        go1.19.5
 Git commit:        a5ee5b1
 Built:             Thu Feb  9 19:51:00 2023
 OS/Arch:           linux/amd64
 Context:           default
Cannot connect to the Docker daemon at unix:///var/run/docker.sock. Is the docker daemon running?
```

启动 Docker 服务，功能测试

```sh
$ systemctl enable --now docker
$ systemctl status docker

$ docker run --rm hello-world
Unable to find image 'hello-world:latest' locally
latest: Pulling from library/hello-world
2db29710123e: Pull complete 
Digest: sha256:6e8b6f026e0b9c419ea0fd02d3905dd0952ad1feea67543f525c73a0a790fefb
Status: Downloaded newer image for hello-world:latest

Hello from Docker!
This message shows that your installation appears to be working correctly.
```

若能正常输出以上信息，则说明安装成功。

## 四. 创建用户

默认情况下，`docker` 命令会使用 [Unix socket (opens new window)](https://en.wikipedia.org/wiki/Unix_domain_socket) 与 Docker 引擎通讯。而只有 `root` 用户和 `docker` 组的用户才可以访问 Docker 引擎的 Unix socket。出于安全考虑，一般 Linux 系统上不会直接使用 `root` 用户。因此，更好地做法是将需要使用 `docker` 的用户加入 `docker` 用户组。

```sh
# 一般安装时已存在，普通用户无管理权限
$ sudo groupadd docker
$ cat /etc/group | grep docker
docker:x:994:
# 使用普通用户admin执行则提示权限不足
[Mon Feb 20 admin@pbe ~]$ docker ps
permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock: Get "http://%2Fvar%2Frun%2Fdocker.sock/v1.24/containers/json": dial unix /var/run/docker.sock: connect: permission denied
```

将当前用户加入 `docker` 组，重启服务器即可生效

```sh
# 添加当前用户并刷新服务
$ sudo usermod -aG docker $USER
$ newgrp docker
$ cat /etc/group | grep docker
docker:x:994:admin

[Mon Feb 20 admin@pbe ~]$ docker ps
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES

# 指定组移除指定用户
$ sudo usermod -aG docker admin
```

## 五. 镜像加速

如果在使用过程中发现拉取 Docker 镜像十分缓慢，可以配置 Docker 国内镜像加速

```json
$ cat > /etc/docker/daemon.json << EOF
{
  "registry-mirrors": [
      "https://eihzr0te.mirror.aliyuncs.com",
      "https://dockerhub.mirrors.nwafu.edu.cn/",
      "https://mirror.ccs.tencentyun.com",
      "https://docker.mirrors.ustc.edu.cn/",
      "https://reg-mirror.qiniu.com",
      "http://hub-mirror.c.163.com/",
      "https://registry.docker-cn.com"]
}
EOF

$ systemctl daemon-reload && systemctl restart docker
```

## 六. 优化设置

1）内核参数：如果在 CentOS 使用 Docker 看到下面的这些警告信息，可添加内核配置参数以启用这些功能

```sh
WARNING: bridge-nf-call-iptables  is disabled
WARNING: bridge-nf-call-ip6tables is disabled

$ sudo tee -a /etc/sysctl.conf <<-EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables  = 1
EOF

$ sudo sysctl -p
```

2）安全策略：设置防火墙规则，让其通行(可略，根据实际环境操作)

```sh
$ vim /lib/systemd/system/docker.service
[Service]
ExecStartPost=/sbin/iptables -I FORWARD -s 0.0.0.0/0 -j ACCEPT
```

3）配置文件：修改日志/上传下载参数，在配置时注意版本的兼容性，具体请查看 [官方文档](https://docs.docker.com/engine/reference/commandline/dockerd/#options)

```json
$ vim /etc/docker/daemon.json
{
  "registry-mirrors": [
      "https://eihzr0te.mirror.aliyuncs.com",
      "https://dockerhub.mirrors.nwafu.edu.cn/",
      "https://mirror.ccs.tencentyun.com",
      "https://docker.mirrors.ustc.edu.cn/",
      "https://reg-mirror.qiniu.com",
      "http://hub-mirror.c.163.com/",
      "https://registry.docker-cn.com"
      ],
   "max-concurrent-downloads": 10,
   "max-concurrent-uploads": 5,
   "log-driver": "json-file",
   "log-opts": {    
      "max-size": "300m",
      "max-file": "2"  
      },  
   "live-restore": true
}
```

- `"registry-mirrors"`：镜像加速
- `"max-concurrent-downloads"`：同时下载的最大数目
- `"max-concurrent-uploads"`：同时上传的最大数目
- `"log-driver"`：日志驱动，Json 格式
- `"log-opts"`：日志配置，大小 300m，文件最多 2个，轮循存储，路径：`/var/lib/docker/containers`
- `"live-restore"`：重启策略，docker 守护进程重启，容器不受影响

**附加完整配置清单说明**

```json
{
  #用一组新的注册表替换守护程序将向其推送不可分发工件的注册表集
  "allow-nondistributable-artifacts": [],
  "api-cors-header": "",
  #指定要使用的授权插件
  "authorization-plugins": [],
  "bip": "",
  #标志设置docker0为默认桥接网络
  "bridge": "",
  "cgroup-parent": "",
  "cluster-advertise": "",
  #使用新地址重新加载发现存储。
  "cluster-store": "",
  #使用新选项重新加载发现存储。
  "cluster-store-opts": {},
  "containerd": "/run/containerd/containerd.sock",
  "containerd-namespace": "docker",
  "containerd-plugin-namespace": "docker-plugins",
  "data-root": "",
  #当设置为 true 时，它将守护程序更改为调试模式
  "debug": true,
  "default-address-pools": [
    {
      "base": "172.30.0.0/16",
      "size": 24
    },
    {
      "base": "172.31.0.0/16",
      "size": 24
    }
  ],
  "default-cgroupns-mode": "private",
  "default-gateway": "",
  "default-gateway-v6": "",
  "default-runtime": "runc",
  "default-shm-size": "64M",
  "default-ulimits": {
    "nofile": {
      "Hard": 64000,
      "Name": "nofile",
      "Soft": 64000
    }
  },
  #设定容器DNS的地址，在容器的 /etc/resolv.conf文件中可查看
  "dns": [],
  "dns-opts": [],
  #设定容器的搜索域
  "dns-search": [],
  "exec-opts": [],
  "exec-root": "",
  "experimental": false,
  #明确启用或禁用特定功能
  "features": {},
  "fixed-cidr": "",
  "fixed-cidr-v6": "",
  "group": "",
  "hosts": [],
  "icc": false,
  "init": false,
  "init-path": "/usr/libexec/docker-init",
  "insecure-registries": [],
  "ip": "0.0.0.0",
  "ip-forward": false,
  "ip-masq": false,
  #阻止 Docker 守护进程添加 iptables 规则
  "iptables": false,
  "ip6tables": false,
  "ipv6": false,
  #docker主机的标签，很实用的功能,例如定义：–label nodeName=host-121
  "labels": [],
  #启用在守护进程停机期间保持容器活动
  "live-restore": true,
  #Default driver for container logs (default "json-file")
  "log-driver": "json-file",
  "log-level": "",
  #日志配置
  "log-opts": {
    "cache-disabled": "false",
    "cache-max-file": "5",
    "cache-max-size": "20m",
    "cache-compress": "true",
    "env": "os,customer",
    "labels": "somelabel",
    "max-file": "5",
    "max-size": "10m"
  },
  #每次拉取的最大并发下载量
  "max-concurrent-downloads": 3,
  #每次推送的最大并发上传量
  "max-concurrent-uploads": 5,
  #每次拉取的最大下载尝试次数
  "max-download-attempts": 5,
  "mtu": 0,
  "no-new-privileges": false,
  "node-generic-resources": [
    "NVIDIA-GPU=UUID1",
    "NVIDIA-GPU=UUID2"
  ],
  "oom-score-adjust": -500,
  "pidfile": "",
  "raw-logs": false,
  #镜像源管理
  "registry-mirrors": [],
  #可用于运行容器的可用OCI运行时列表
  "runtimes": {
    "cc-runtime": {
      "path": "/usr/bin/cc-runtime"
    },
    "custom": {
      "path": "/usr/local/bin/my-runc-replacement",
      "runtimeArgs": [
        "--debug"
      ]
    }
  },
  "seccomp-profile": "",
  #默认 false，启用selinux支持
  "selinux-enabled": false,
  "shutdown-timeout": 15,
  "storage-driver": "",
  "storage-opts": [],
  "swarm-default-advertise-addr": "",
  #启动TLS认证开关
  "tls": true,
  "tlscacert": "",
  "tlscert": "",
  "tlskey": "",
  "tlsverify": true,
  "userland-proxy": false,
  "userland-proxy-path": "/usr/libexec/docker-proxy",
  "userns-remap": ""
}
```
