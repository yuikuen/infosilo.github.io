> 通过 K8s+Helm 部署 Bitnami RabbitMQ
>
> 参考链接：[Helm3-安装RabbitMQ](https://segmentfault.com/a/1190000040278467#item-3)

## 一. 前期准备

1）提前安装 helm 并添加源

```bash
$ helm repo add bitnami https://charts.bitnami.com/bitnami
$ helm repo list
NAME         	URL                                       
elastic      	https://helm.elastic.co                   
gitlab       	https://charts.gitlab.io                  
bitnami      	https://charts.bitnami.com/bitnami        
incubator    	https://charts.helm.sh/incubator          
stable       	https://charts.helm.sh/stable             
ingress-nginx	https://kubernetes.github.io/ingress-nginx
```

2）安装 rabbitmq 方法有很多下面列举几个常规安装方法：

- centos 7/8 安装 rabbitmq  [阿里云ECS CentOS提供安装](https://link.segmentfault.com/?url=https%3A%2F%2Fhelp.aliyun.com%2Fdocument_detail%2F53100.html%3Fspm%3D5176.smartservice_service_chat.0.0.ad23709a1rsjyv)
- k8s 安装 rabbitmq  [官方文档提供安装](https://link.segmentfault.com/?url=https%3A%2F%2Fwww.rabbitmq.com%2Fkubernetes%2Foperator%2Finstall-operator.html)
- helm 安装 rabbitmq  [社区大佬提供安装](https://link.segmentfault.com/?url=https%3A%2F%2Fphoenixnap.com%2Fkb%2Finstall-and-configure-rabbitmq-on-kubernetes)

**不同环境下安装方法**

- **安装开发和测试环境(dev、test)**
  - **k8s Service：type: NodePort | LoadBalance**
  - **RMQ管理界面：使用ip:port方式来访问，如：192.168.0.1:15672**
  - **AMQP 5672端口：我们也是使用ip:port来访问，如：192.168.0.1:5672**
- **安装预生产和生产环境(uat、prod)**
  - **k8s Service：type: ClusterIP，Ingress**
  - **RMQ管理界面：使用ingress里面配置的域名来访问，如：rabbitmq.demo.com**
  - **AMQP 5672端口：使用k8s internet dns解析出来的name来访问，如：`test-rabbitmq-headless.rabbit.svc.cluster.local:5672`**

## 二. 基本配置

1）查看 helm 可用的 chart 版本，可用`-l`查看所有版本

```bash
$ helm search repo rabbitmq
NAME                               	CHART VERSION	APP VERSION	DESCRIPTION                                       
bitnami/rabbitmq                   	8.22.0       	3.9.5      	Open source message broker software that implem...
bitnami/rabbitmq-cluster-operator  	0.1.3        	1.8.3      	The RabbitMQ Cluster Kubernetes Operator automa...
stable/prometheus-rabbitmq-exporter	0.5.6        	v0.29.0    	DEPRECATED Rabbitmq metrics exporter for promet...
stable/rabbitmq                    	6.18.2       	3.8.2      	DEPRECATED Open source message broker software ...
stable/rabbitmq-ha                 	1.47.1       	3.8.7      	DEPRECATED - Highly available RabbitMQ cluster,...
```

2）因为私有部署，需要修改个别配置文件，先行下载文件

```bash 
$ helm pull bitnami/rabbitmq --version=8.22.0
$ tar -xf rabbitmq-8.22.0.tgz
$ ls -l rabbitmq
total 120
-rw-r--r-- 1 root root   218 Sep  8 19:08 Chart.lock
drwxr-xr-x 3 root root    20 Sep 10 15:54 charts
-rw-r--r-- 1 root root   681 Sep  8 19:08 Chart.yaml
drwxr-xr-x 2 root root    64 Sep 10 15:54 ci
-rw-r--r-- 1 root root 57466 Sep  8 19:08 README.md
drwxr-xr-x 2 root root  4096 Sep 10 15:54 templates
-rw-r--r-- 1 root root  2815 Sep  8 19:08 values.schema.json
-rw-r--r-- 1 root root 42990 Sep  8 19:08 values.yaml
```

3）查看一下 values.yaml 对外提供的可用参数，也可以通过命令查看：

```bash
$ helm show values bitnami/rabbitmq
```

**主要配置信息**

```yaml
# (可选)修改image
image:
  registry: docker.io
  repository: rabbitmq
  tag: 3.9.5-management-alpine

# 账密及cookie定义
auth:
  username: intell
  password: "intell"
  existingPasswordSecret: ""
  erlangCookie: secretcookie

# 持久化存储，定义 storageClass 绑定 pvc、pv
persistence:
  enabled: true
  storageClass: "rabbitmq-storage"
  size: 8Gi
  
# 启用持久化存储时，若rabbitmq所有pod同时宕机，将无法重新启动，因此有必要提前开启clustering.forceBoot
clustering:
  enabled: true
  addressType: hostname
  rebalance: false
  forceBoot: true
  
# 指定时区
extraEnvVars: 
  - name: TZ
    value: "Asia/Shanghai"
    
# 指定副本数
replicaCount: 3
```
除修改配置文件外，也可在安装时使用`set`方式指定相关参数
```bash
$ helm install mq -n rabbitmq-cluster . \
  --set auth.username=intell,auth.password=intell,auth.erlangCookie=secretcookie
```

## 三. 测试环境

1）开发环境采用 `ip:port`来访问，需要配置 service，具体配置如下

```yaml
service:
  type: NodePort # 将ClusterIP改为NodePort
persistence:
  enabled: true
  storageClass: ""
  size: 8Gi
```

```bash
$ helm install mq -n rabbitmq-cluster .
```

2）查看 `rabbitmq-cluster` 命名空间下所有的 rabbitmq 资源，是否创建成功！

```bash
$ kubectl get all -n rabbitmq-cluster
NAME                READY   STATUS    RESTARTS   AGE
pod/mq-rabbitmq-0   1/1     Running   0          7m56s

NAME                           TYPE        CLUSTER-IP        EXTERNAL-IP   PORT(S)                                 AGE
service/mq-rabbitmq            ClusterIP   120.103.236.124   <none>        5672/TCP,4369/TCP,25672/TCP,15672/TCP   7m56s
service/mq-rabbitmq-headless   ClusterIP   None              <none>        4369/TCP,5672/TCP,25672/TCP,15672/TCP   7m56s

NAME                           READY   AGE
statefulset.apps/mq-rabbitmq   1/1     7m56s
```

等待一段时间会发现pod、svc、pvc、pv、statefulset全部创建完成，输出内容可发现对应的访问方式：

```bash
Obtain the NodePort IP and ports:
NODE_IP：
kubectl get nodes --namespace rabbitmq-cluster -o jsonpath="{.items[0].status.addresses[0].address}"

NODE_PORT_AMQP
kubectl get --namespace rabbitmq-cluster -o jsonpath="{.spec.ports[1].nodePort}" services mq-rabbitmq

NODE_PORT_STATS
kubectl get --namespace rabbitmq-cluster -o jsonpath="{.spec.ports[3].nodePort}" services mq-rabbitmq
```

- Node_ip 查看 k8s 节点真实 IP，如 188.188.3.121
- Node_port_amqp 是集群 5672 对应的 NodePort 端口，如 30736
- Node_port_stats 是集群 15672 对应的 NodePort 端口，如 30353

3）访问Rabbitmq管理界面在浏览器中输入：`http://188.188.3.121:30353`即可访问：

```bash
# 默认账号密码
Credentials:
    echo "Username      : user"
    echo "Password      : $(kubectl get secret --namespace rabbitmq-cluster mq-rabbitmq -o jsonpath="{.data.rabbitmq-password}" | base64 --decode)"
    echo "ErLang Cookie : $(kubectl get secret --namespace rabbitmq-cluster mq-rabbitmq -o jsonpath="{.data.rabbitmq-erlang-cookie}" | base64 --decode)"
```

![](https://img.17121203.xyz/i/2024/10/21/sg9kx0-0.webp)

**springboot 就可以通过 ip 地址来访问 Rabbitmq**

```yaml
spring:
  rabbitmq:
    host: 188.188.3.120
    port: 5672
    username: user
    password:
```

## 四. 生产环境

1）如开发需要通过域名访问，可以启用 ingress 及域名配置

```bash
ingress:
  enabled: true
  annotations:
    kubernetes.io/ingress.class: nginx
  hostName: rabbitmq.demo.net
```

2）最后就是要通过https访问，我们要启用tls：

```yaml
tls: true
tlsSecret: tls-secret-name
```

3）在此使用的是 `cert-manager.io/cluster-issuer` ，直接生成 tls 证书，[使用cert-manager申请免费的HTTPS证书](https://help.aliyun.com/document_detail/86533.html?spm=5176.2020520152.0.0.46e316ddfGLDXs#title-v89-nee-iuh)

```yaml
annotations:
    cert-manager.io/cluster-issuer: your-cert-manager-name
```

最终完整的 values.yaml 文件如下：

```yaml
ingress:
  enabled: true
  hostname: yk-rabbitmq.net
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod-http01
    nginx.ingress.kubernetes.io/force-ssl-redirect: 'true' 
  tls: true
  tlsSecret: letsencrypt-prod-http01
  certManager: true
  selfSigned: true
persistence:
  storageClass: "rabbitmq-nfs-storage"
  size: 8Gi 
```

```bash
$ helm install rmq -n rabbit .
$ kubectl get all -n rabbit
NAME                            READY   STATUS    RESTARTS   AGE
pod/cm-acme-http-solver-fczkr   1/1     Running   0          15h
pod/rmq-rabbitmq-0              1/1     Running   0          15h
pod/rmq-rabbitmq-1              1/1     Running   0          15h
pod/rmq-rabbitmq-2              1/1     Running   0          15h

NAME                                TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                                 AGE
service/cm-acme-http-solver-rwc98   NodePort    120.168.190.30   <none>        8089:30610/TCP                          15h
service/rmq-rabbitmq                ClusterIP   120.168.97.24    <none>        5672/TCP,4369/TCP,25672/TCP,15672/TCP   15h
service/rmq-rabbitmq-headless       ClusterIP   None             <none>        4369/TCP,5672/TCP,25672/TCP,15672/TCP   15h

NAME                            READY   AGE
statefulset.apps/rmq-rabbitmq   3/3     15h

$ kubectl get ingress -n rabbit
NAME                        CLASS    HOSTS             ADDRESS           PORTS     AGE
cm-acme-http-solver-ktctn   <none>   yk-rabbitmq.net   120.168.152.110   80        15h
rmq-rabbitmq                <none>   yk-rabbitmq.net   120.168.152.110   80, 443   15h
```

4）访问 Rabbitmq 管理界面在浏览器中输入：`http://yk-rabbitmq.net/`即可完成访问：

![](https://img.17121203.xyz/i/2024/10/21/sh8kg6-0.webp)

springboot 就可以通过 k8s intranet dns 解析的 name 来访问 Rabbitmq

```yaml
spring:
  rabbitmq:
    host: rmq-rabbitmq-headless.public-service.svc.cluster.local
    port: 5672
    username: user
    password:
```

## 五. 划分环境

使用rabbitmq非常方便，但是我们开发是有环境区分的：开发dev、测试test、预生产uat和生产pro，那么如何划分rabbitmq的环境呢?两种方式
1. 安装四种环境下的rabbitmq
2. 安装一次rabbitmq，通过visualhost划分不同环境

```yaml
# Spring
spring:
  # rabbitmq
  rabbitmq:
    host: 192.168.6.1
    # rabbitmq的端口
    port: 5672
    # rabbitmq的用户名
    username: xxx
    # rabbitmq的用户密码
    password: xxx
    # 虚拟主机，用来区分不同环境的队列
    virtual-host: dev
    #开启重试机制
    listener:
      retry:
        enabled: true
        #重试次数，默认为3次
        max-attempts: 3
```

## 六. 问题总结

**1、访问rabbitmq报：503**
如果你配置的域名路径如：`demo.com/rabbitmq`，这样的域名，那么你要配置成下面这样，才能正确访问，另外：**推荐使用一级或者二级、三级域名做为hostName不要使用path:/rabbitmq这种形式**

```yaml
rabbitmq:
  extraConfiguration: |-
    management.path_prefix = /rabbitmq/
ingress:
...
  hostName: demo.com
  path: /rabbitmq/
...
```

**2、springcloud 微服务访问 5672 端口连接报：time out**
原因：spring.rabbitmq.host 地址不应该是你的 ingress 外网域名:rabbitmq.demo.com，而应该是你内网[集群dns解析的地址](https://link.segmentfault.com/?url=https%3A%2F%2Fkubernetes.io%2Fzh%2Fdocs%2Ftasks%2Fadminister-cluster%2Fdns-debugging-resolution%2F%23is-dns-service-up)
解决：使用下面命令获取 test-rabbitmq 的内网解析地址，然后赋值到 spring.rabbitmq.host 重新连接即可

```bash
# 如果 pod 和服务的命名空间不相同，则 DNS 查询必须指定服务所在的命名空间。
# test-rabbitmq-headless.rabbit命名空间是rabbit
# 如果没有指定命名空间，可以使用kubectl exec -i -t dnsutils -- nslookup rmq-rabbitmq-headless 即可
$ kubectl exec -i -t dnsutils -- nslookup rmq-rabbitmq-headless.rabbit
Server:		120.168.0.10
Address:	120.168.0.10#53

Name:	rmq-rabbitmq-headless.rabbit.svc.cluster.local
Address: 172.25.92.127
Name:	rmq-rabbitmq-headless.rabbit.svc.cluster.local
Address: 172.25.244.247
Name:	rmq-rabbitmq-headless.rabbit.svc.cluster.local
Address: 172.18.195.16

# application.yml配置
spring.rabbitmq.host=rmq-rabbitmq-headless.rabbit.svc.cluster.local
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: dnsutils
  namespace: default
spec:
  containers:
  - name: dnsutils
    image: gcr.io/kubernetes-e2e-test-images/dnsutils:1.3
    command:
      - sleep
      - "3600"
    imagePullPolicy: IfNotPresent
  restartPolicy: Always
```

**3、rabbitmq 5672 端口只支持 amqp:协议，也就是说不能用 ingress 暴露，而ingress只能暴露 http 和 https，所以开发测试环境我们设置 service 的 type: NodePort 也就是这个原因**

<font color=red>4、如 ingress 未成功生效，可以重启服务器后再试</font>

