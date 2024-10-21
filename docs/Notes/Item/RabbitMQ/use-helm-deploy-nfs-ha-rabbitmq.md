> 通过 K8s+Helm+NFS 部署高可用 RabbitMQ

## 一. 安装说明

教程为 aliyuncs RabbitMQ-HA 部署方案，具体流程如下：

- 通过 Helm 搜索并下载相关 RabbitMQ-HA 版本
- 拉取指定版本文件，解压并进行配置定制
- 创建 Namespace 和以 Helm Charts 方式创建构建
- 集群登录、测试功能等操作

## 二. 下载程序

1）添加仓库并下载源文件

```bash
# 仓库可以选用 bitnami 或 aliyuncs 代码可能有个别差异，但配置方法同理；

$ helm repo add aliyun https://kubernetes.oss-cn-hangzhou.aliyuncs.com/charts 
$ helm repo add aliyuncs https://apphub.aliyuncs.com
$ helm repo add bitnami https://charts.bitnami.com/bitnami

$ helm search repo rabbitmq-ha
NAME                	CHART VERSION	APP VERSION	DESCRIPTION                                       
aliyuncs/rabbitmq-ha	1.39.0       	3.8.0      	Highly available RabbitMQ cluster, the open sou...
# 可以加上版本号进行搜索并指定版本号下载
$ helm search repo rabbitmq-ha --versions
NAME                	CHART VERSION	APP VERSION	DESCRIPTION                                       
aliyuncs/rabbitmq-ha	1.39.0       	3.8.0      	Highly available RabbitMQ cluster, the open sou...
aliyuncs/rabbitmq-ha	1.38.2       	3.8.0      	Highly available RabbitMQ cluster, the open sou...
aliyuncs/rabbitmq-ha	1.38.1       	3.8.0      	Highly available RabbitMQ cluster, the open sou...
aliyuncs/rabbitmq-ha	1.36.4       	3.8.0      	Highly available RabbitMQ cluster, the open sou...
aliyuncs/rabbitmq-ha	1.36.3       	3.8.0      	Highly available RabbitMQ cluster, the open sou...
aliyuncs/rabbitmq-ha	1.36.0       	3.8.0      	Highly available RabbitMQ cluster, the open sou...
aliyuncs/rabbitmq-ha	1.34.1       	3.7.19     	Highly available RabbitMQ cluster, the open sou...
aliyuncs/rabbitmq-ha	1.34.0       	3.7.19     	Highly available RabbitMQ cluster, the open sou...
aliyuncs/rabbitmq-ha	1.33.0       	3.7.15     	Highly available RabbitMQ cluster, the open sou...
aliyuncs/rabbitmq-ha	1.32.4       	3.7.15     	Highly available RabbitMQ cluster, the open sou...
aliyuncs/rabbitmq-ha	1.32.3       	3.7.15     	Highly available RabbitMQ cluster, the open sou...
aliyuncs/rabbitmq-ha	1.32.2       	3.7.15     	Highly available RabbitMQ cluster, the open sou...
aliyuncs/rabbitmq-ha	1.32.0       	3.7.15     	Highly available RabbitMQ cluster, the open sou...
aliyuncs/rabbitmq-ha	1.31.0       	3.7.15     	Highly available RabbitMQ cluster, the open sou...
aliyuncs/rabbitmq-ha	1.30.0       	3.7.15     	Highly available RabbitMQ cluster, the open sou...
aliyuncs/rabbitmq-ha	1.29.1       	3.7.15     	Highly available RabbitMQ cluster, the open sou...
aliyuncs/rabbitmq-ha	1.29.0       	3.7.15     	Highly available RabbitMQ cluster, the open sou...
aliyuncs/rabbitmq-ha	1.28.0       	3.7.15     	Highly available RabbitMQ cluster, the open sou...
aliyuncs/rabbitmq-ha	1.27.2       	3.7.15     	Highly available RabbitMQ cluster, the open sou...
aliyuncs/rabbitmq-ha	1.27.1       	3.7.12     	Highly available RabbitMQ cluster, the open sou...
```

2）下载源码包并进行修改

```bash
$ helm pull aliyuncs/rabbitmq-ha --version=1.39.0
$ tar -xf rabbitmq-ha-1.39.0.tgz
```

## 三. 修改配置

- 进入工作目录，配置持久化存储、副本数等
- 建议首次部署时直接修改 values 中的配置，而不是用 `–set` 的方式，这样后期 upgrade 不必重复设置

1）设置管理员密码

- 方式一，配置中指定

```yaml
# bitnami
$ vim ./values.yaml
auth:
  username: admin
  password: "admin@mq"
  existingPasswordSecret: ""
  erlangCookie: secretcookie
  
# aliyuncs
rabbitmqUsername: admin
rabbitmqPassword: admin@mq
managementUsername: management
managementPassword: management@mq
existingSecret: ""
rabbitmqErlangCookie: secretcookie
```
后期 `upgrade` 时亦可指定上述参数

- 方式二，在安装时通过 set 命令指定（避免密码泄露）

```bash
$ helm install rabbitmq --namespace rabbitmq-cluster --set ingress.enabled=true,ingress.hostName=yk-rabbitmq.net --set rabbitmqUsername=admin,rabbitmqPassword=admin@mq,managementPassword=management@mq,rabbitmqErlangCookie=secretcookie .
```

2）集群意外宕机强制启动

- 当 rabbitmq 启用持久化存储时，若 rabbitmq 所有 pod 同时宕机，将无法重新启动，因此有必要提前开启`forceBoot`

```yaml
forceBoot: true
```

3）指定副本数

```yaml
replicaCount: 3
```

4）域名访问

```yaml
ingress:
  enabled: true
  path: /
  hostName: yk-rabbitmq.net
  tls: true
  tlsSecret: myTlsSecret
  annotations: {}
```

5）存储配置

**此为参考项，因测试环境一般不作存储处理，个别生产环境需要存储可部署使用；**

```yaml
persistentVolume:
  enabled: false
  storageClass: "rabbitmq-nfs-storage"
  name: data
  accessModes:
    - ReadWriteOnce
  size: 8Gi
  annotations: {}
```

- 创建 rbac

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: rabbitmq-nfs
  # replace with namespace where provisioner is deployed
  namespace: rabbitmq-cluster
---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: rabbitmq-nfs-runner
rules:
  - apiGroups: [""]
    resources: ["nodes"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["persistentvolumes"]
    verbs: ["get", "list", "watch", "create", "delete"]
  - apiGroups: [""]
    resources: ["persistentvolumeclaims"]
    verbs: ["get", "list", "watch", "update"]
  - apiGroups: ["storage.k8s.io"]
    resources: ["storageclasses"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["events"]
    verbs: ["watch","create", "update", "patch"]
  - apiGroups: [""]
    resources: ["services", "endpoints"]
    verbs: ["get","create","list", "watch","update"]
  - apiGroups: ["extensions"]
    resources: ["podsecuritypolicies"]
    resourceNames: ["nfs-provisioner"]
    verbs: ["use"]
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: run-rabbitmq-nfs
subjects:
  - kind: ServiceAccount
    name: rabbitmq-nfs
    # replace with namespace where provisioner is deployed
    namespace: rabbitmq-cluster
roleRef:
  kind: ClusterRole
  name: rabbitmq-nfs-runner
  apiGroup: rbac.authorization.k8s.io
---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: leader-locking-rabbitmq-nfs
  # replace with namespace where provisioner is deployed
  namespace: rabbitmq-cluster
rules:
  - apiGroups: [""]
    resources: ["endpoints"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: leader-locking-rabbitmq-nfs
  # replace with namespace where provisioner is deployed
  namespace: rabbitmq-cluster
subjects:
  - kind: ServiceAccount
    name: rabbitmq-nfs
    # replace with namespace where provisioner is deployed
    namespace: rabbitmq-cluster
roleRef:
  kind: Role
  name: leader-locking-rabbitmq-nfs
  apiGroup: rbac.authorization.k8s.io

$ kubectl create -f rbac.yaml
$ kubectl get sa,clusterrole,clusterrolebinding -n rabbitmq-cluster | grep nfs
serviceaccount/rabbitmq-nfs     1         3m18s
clusterrole.rbac.authorization.k8s.io/rabbitmq-nfs-runner                                                    2021-08-26T08:19:18Z
clusterrolebinding.rbac.authorization.k8s.io/run-rabbitmq-nfs                                       ClusterRole/rabbitmq-nfs-runner                                                    3m18s
```

- 创建 nfs-client-provisioner

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: rabbitmq-nfs
  labels:
    app: rabbitmq-nfs
  # replace with namespace where provisioner is deployed
  namespace: rabbitmq-cluster
spec:
  replicas: 1
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: rabbitmq-nfs
  template:
    metadata:
      labels:
        app: rabbitmq-nfs
    spec:
      serviceAccountName: rabbitmq-nfs
      containers:
        - name: nfs-client-provisioner
          image: registry.cn-hongkong.aliyuncs.com/yuikuen/nfs-subdir-external-provisioner:v4.0.2
          volumeMounts:
            - name: nfs-client-root
              mountPath: /persistentvolumes
          env:
            - name: PROVISIONER_NAME
              value: rabbitmq-nfs
            - name: NFS_SERVER
              value: 188.188.3.110
            - name: NFS_PATH
              value: /nfs/rabbitmq
      volumes:
        - name: nfs-client-root
          nfs:
            server: 188.188.3.110
            path: /nfs/rabbitmq
            
$ kubectl create deployment.yaml
$ kubectl get po -n rabbitmq-cluster
NAME                            READY   STATUS    RESTARTS   AGE
mq-rabbitmq-ha-0                1/1     Running   0          63m
mq-rabbitmq-ha-1                1/1     Running   0          62m
mq-rabbitmq-ha-2                1/1     Running   0          62m
rabbitmq-nfs-5659546d5d-btrp6   1/1     Running   0          13s
```

- 创建 storageclass

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: rabbitmq-nfs-storage
  namespace: rabbitmq-cluster
provisioner: rabbitmq-nfs     # 需要对应 PROVISIONER_NAME
reclaimPolicy: Retain

$ kubectl create -f storageclass.yaml
$ kubectl get sc
NAME                   PROVISIONER    RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
rabbitmq-nfs-storage   rabbitmq-nfs   Retain          Immediate           false                  3s
```

6）开启持久化数据，重新部署 rabbitmq，验证状态

```bash
$ kubectl get po,pvc,pv -n rabbitmq-cluster && ll /nfs/rabbitmq/
NAME                                READY   STATUS    RESTARTS   AGE
pod/mq-rabbitmq-ha-0                1/1     Running   0          81s
pod/mq-rabbitmq-ha-1                1/1     Running   0          54s
pod/mq-rabbitmq-ha-2                1/1     Running   0          32s
pod/rabbitmq-nfs-5659546d5d-btrp6   1/1     Running   0          16m

NAME                                          STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS           AGE
persistentvolumeclaim/data-mq-rabbitmq-ha-0   Bound    pvc-e083fdfa-e101-44c8-b993-413c0068e961   8Gi        RWO            rabbitmq-nfs-storage   81s
persistentvolumeclaim/data-mq-rabbitmq-ha-1   Bound    pvc-820896a6-f609-4da8-9be9-df6102cdd616   8Gi        RWO            rabbitmq-nfs-storage   54s
persistentvolumeclaim/data-mq-rabbitmq-ha-2   Bound    pvc-901d6c8c-12e1-4fc1-ba89-8b456d598ee8   8Gi        RWO            rabbitmq-nfs-storage   32s

NAME                                                        CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                                    STORAGECLASS           REASON   AGE
persistentvolume/pvc-820896a6-f609-4da8-9be9-df6102cdd616   8Gi        RWO            Retain           Bound    rabbitmq-cluster/data-mq-rabbitmq-ha-1   rabbitmq-nfs-storage            54s
persistentvolume/pvc-901d6c8c-12e1-4fc1-ba89-8b456d598ee8   8Gi        RWO            Retain           Bound    rabbitmq-cluster/data-mq-rabbitmq-ha-2   rabbitmq-nfs-storage            32s
persistentvolume/pvc-e083fdfa-e101-44c8-b993-413c0068e961   8Gi        RWO            Retain           Bound    rabbitmq-cluster/data-mq-rabbitmq-ha-0   rabbitmq-nfs-storage            80s
total 0
drwxrwxrwx 3 root root 42 Aug 26 16:58 rabbitmq-cluster-data-mq-rabbitmq-ha-0-pvc-e083fdfa-e101-44c8-b993-413c0068e961
drwxrwxrwx 3 root root 42 Aug 26 16:58 rabbitmq-cluster-data-mq-rabbitmq-ha-1-pvc-820896a6-f609-4da8-9be9-df6102cdd616
drwxrwxrwx 3 root root 42 Aug 26 16:58 rabbitmq-cluster-data-mq-rabbitmq-ha-2-pvc-901d6c8c-12e1-4fc1-ba89-8b456d598ee8

$ kubectl exec -it mq-rabbitmq-ha-0 -n rabbitmq-cluster -- bash
bash-5.1$ rabbitmqctl cluster_status
RABBITMQ_ERLANG_COOKIE env variable support is deprecated and will be REMOVED in a future version. Use the $HOME/.erlang.cookie file or the --erlang-cookie switch instead.
Cluster status of node rabbit@mq-rabbitmq-ha-0.mq-rabbitmq-ha-discovery.rabbitmq-cluster.svc.cluster.local ...
Basics

Cluster name: rabbit@mq-rabbitmq-ha-0.mq-rabbitmq-ha-discovery.rabbitmq-cluster.svc.cluster.local

Disk Nodes

rabbit@mq-rabbitmq-ha-0.mq-rabbitmq-ha-discovery.rabbitmq-cluster.svc.cluster.local
rabbit@mq-rabbitmq-ha-1.mq-rabbitmq-ha-discovery.rabbitmq-cluster.svc.cluster.local
rabbit@mq-rabbitmq-ha-2.mq-rabbitmq-ha-discovery.rabbitmq-cluster.svc.cluster.local

Running Nodes

rabbit@mq-rabbitmq-ha-0.mq-rabbitmq-ha-discovery.rabbitmq-cluster.svc.cluster.local
rabbit@mq-rabbitmq-ha-1.mq-rabbitmq-ha-discovery.rabbitmq-cluster.svc.cluster.local
rabbit@mq-rabbitmq-ha-2.mq-rabbitmq-ha-discovery.rabbitmq-cluster.svc.cluster.local

Versions

rabbit@mq-rabbitmq-ha-0.mq-rabbitmq-ha-discovery.rabbitmq-cluster.svc.cluster.local: RabbitMQ 3.8.14 on Erlang 23.3.2
rabbit@mq-rabbitmq-ha-1.mq-rabbitmq-ha-discovery.rabbitmq-cluster.svc.cluster.local: RabbitMQ 3.8.14 on Erlang 23.3.2
rabbit@mq-rabbitmq-ha-2.mq-rabbitmq-ha-discovery.rabbitmq-cluster.svc.cluster.local: RabbitMQ 3.8.14 on Erlang 23.3.2

Maintenance status

Node: rabbit@mq-rabbitmq-ha-0.mq-rabbitmq-ha-discovery.rabbitmq-cluster.svc.cluster.local, status: not under maintenance
Node: rabbit@mq-rabbitmq-ha-1.mq-rabbitmq-ha-discovery.rabbitmq-cluster.svc.cluster.local, status: not under maintenance
Node: rabbit@mq-rabbitmq-ha-2.mq-rabbitmq-ha-discovery.rabbitmq-cluster.svc.cluster.local, status: not under maintenance
```

![](https://img.17121203.xyz/i/2024/10/21/r6ddlx-0.webp)

## 四. 外部访问

资源有限，未采用云平台作测试，详细可参考下述链接

[RabbitMQ 集群&镜像模式]:https://blog.csdn.net/qq_14999375/article/details/119085363

**方式一：Service-Nodeport（5672，15672）**

```yaml
$ kubectl get svc -n rabbitmq-cluster mq-rabbitmq-ha -o yaml > service-clusterip.yaml
apiVersion: v1
kind: Service
metadata:
  name: rabbitmq-nodeport
  namespace: test
spec:
  ports:
  - name: amqp
    port: 5672
    protocol: TCP
    targetPort: amqp
    nodePort: 32672
  - name: http-stats
    port: 15672
    protocol: TCP
    targetPort: stats
    nodePort: 32673
  selector:
    app.kubernetes.io/instance: rabbitmq
    app.kubernetes.io/name: rabbitmq
  type: NodePort
```

**方式二：Service-公网 LoadBalancer（5672，15672）**

```yaml
$ vim service-loadbalancer.yaml
apiVersion: v1
kind: Service
metadata:
  name: rabbitmq-loadbalance
  namespace: test
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: external
    service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: ip
    service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
spec:
  ports:
  - name: amqp
    port: 5672
    protocol: TCP
    targetPort: amqp
  - name: http-stats
    port: 15672
    protocol: TCP
    targetPort: stats
  selector:
    app.kubernetes.io/instance: rabbitmq
    app.kubernetes.io/name: rabbitmq
  type: LoadBalancer
```

**方式三：Service-私网 LoadBalancer（5672）+Ingress-公网 ALB（15672）**

```yaml
$ vim service-lb-internal.yaml
apiVersion: v1
kind: Service
metadata:
  name: rabbitmq-lb-internal
  namespace: test
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: external
    service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: ip
    # service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing #注释后即为私网
spec:
  ports:
  - name: amqp
    port: 5672
    protocol: TCP
    targetPort: amqp
  selector:
    app.kubernetes.io/instance: rabbitmq
    app.kubernetes.io/name: rabbitmq
  type: LoadBalancer
```

```yaml
$ vim ingress-alb.yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: rabbitmq
  namespace: test
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
  labels:
    app: rabbitmq
spec:
  rules:
    - http:
        paths:
          - path: /*
            backend:
              serviceName: "rabbitmq"
              servicePort: 15672
```

## 五. 镜像模式

镜像模式：将需要消费的队列变为镜像队列，存在于多个节点，这样就可以实现 RabbitMQ 的 HA 高可用性。作用就是消息实体会主动在镜像节点之间实现同步，而不是像普通模式那样，在 consumer 消费数据时临时读取。缺点就是，集群内部的同步通讯会占用大量的网络带宽

```bash
$ kubectl exec -it -n rabbitmq-cluster mq-rabbitmq-ha-0 -- bash
bash-5.1$ rabbitmqctl list_policies
Listing policies for vhost "/" ...

bash-5.1$ rabbitmqctl set_policy ha-all "^" '{"ha-mode":"all" , "ha-sync-mode":"automatic"}'
Setting policy "ha-all" for pattern "^" to "{"ha-mode":"all" , "ha-sync-mode":"automatic"}" with priority "0" for vhost "/" ...

bash-5.1$ rabbitmqctl list_policies
Listing policies for vhost "/" ...
vhost	name	pattern	apply-to	definition	priority
/	ha-all	^	all	{"ha-mode":"all","ha-sync-mode":"automatic"}	0
```

![](https://img.17121203.xyz/i/2024/10/21/r74bbp-0.webp)

## 六. 清理集群

```sh
$ helm uninstall mq -n rabbitmq-cluster

$ kubectl delete pvc -n rabbitmq-cluster data-mq-rabbitmq-ha-0 data-mq-rabbitmq-ha-1 data-mq-rabbitmq-ha-2
# 如有存储，需要手动删除
```

## 七. 补充内容

```sh
# 模拟运行
$ helm install helm-test2 --set fullnameOverride=aaaaaaa --dry-run .

# 删除并保留历史记录
$ helm  uninstall rabbitmq -n rabbitmq-cluster --keep-history

# 修改并更新集群
$ helm upgrade rabbitmq-cluster -n public-service .
```