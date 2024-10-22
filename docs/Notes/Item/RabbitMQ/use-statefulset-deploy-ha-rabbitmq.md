> 通过 K8s+Statefulset 部署高可用 RabbitMQ

## 一. 安装说明

`RabbitMQ` 是实现了高级 [消息队列](https://cloud.tencent.com/product/cmq?from=10680) 协议 `AMQP` 的开源消息代理软件（亦称面向消息的 [中间件](https://cloud.tencent.com/product/tdmq?from=10680)）。

`RabbitMQ` 服务器是用 `Erlang` 语言编写的，而集群和故障转移是构建在开放电信平台框架上的。`AMQP`：`Advanced Message Queue`，高级消息队列协议。它是应用层协议的一个开放标准，为面向消息的中间件设计，基于此协议的客户端与消息中间件可传递消息，并不受产品、开发语言灯条件的限制

`AMQP` 具有如下的特性：

- 可靠性 `Reliablity`：使用了一些机制来保证可靠性，比如持久化、传输确认、发布确认
- 灵活的路由 `Flexible Routing`：在消息进入队列之前，通过 `Exchange` 来路由消息。对于典型的路由功能，`Rabbit` 已经提供了一些内置的 `Exchange` 来实现。针对更复杂的路由功能，可以将多个 `Exchange` 绑定在一起，也通过插件机制实现自己的`Exchange`
- 消息集群 `Clustering`：多个 `RabbitMQ` 服务器可以组成一个集群，形成一个逻辑`Broker`
- 高可用 `Highly Avaliable Queues`：队列可以在集群中的机器上进行镜像，使得在部分节点出问题的情况下队列仍然可用
- 多种协议 `Multi-protocol`：支持多种消息队列协议，如 `STOMP`、`MQTT` 等
- 多种语言客户端 `Many Clients`：几乎支持所有常用语言，比如 `Java`、`.NET`、`Ruby` 等
- 管理界面 `Management UI`：提供了易用的用户界面，使得用户可以监控和管理消息`Broker` 的许多方面
- 跟踪机制 `Tracing`：如果消息异常，`RabbitMQ` 提供了消息的跟踪机制，使用者可以找出发生了什么
- 插件机制 `Plugin System`：提供了许多插件，来从多方面进行扩展，也可以编辑自己的插件

**持久化和镜像队列**

`RabbitMQ` 持久化分为 `Exchange`、`Queue`、`Message`
- `Exchange` 和 `Queue` 持久化：指持久化 `Exchange`、`Queue` 元数据，持久化的是自身，服务宕机 `Exchange` 和 `Queue` 自身就没有了
- `Message` 持久化：顾名思义就是把每一条消息体持久化，服务宕机，消息不丢失

`RabbitMQ` 的队列 `Queue` 镜像，指 `master node` 在接受到请求后，会同步到其他节点上，以此来保证高可用。在 `confirm` 模式下，具体过程如下

```javascript
clientpublisher 发送消息 –> master node 接到消息 –> master node 将消息持久化到磁盘 –> 将消息异步发送给其他节点 –> master 将 ack 返回给 client publisher
```

**RabbitMQ 集群在 k8s 中的部署**

将 `RabbitMQ` 以集群的方式部署在 `k8s` 中，前提是 `RabbitMQ` 的每个节点都能像传统方式一样进行相互的服务发现。因此 `RabbitMQ` 在 `k8s` 集群中通过`rabbitmq_peer_discovery_k8s plugin` 与 `k8s apiserver` 进行交互，获取各个服务的 `URL`，且 `RabbitMQ` 在 `k8s` 集群中必须用 `statefulset` 和 `headless service` 进行匹配

> **需要注意的是**，`rabbitmq_peer_discovery_k8s` 是 `RabbitMQ` 官方基于第三方开源项目 `rabbitmq-autocluster` 开发，对 `3.7.X` 及以上版本提供的 `Kubernetes` 下的对等发现插件，可实现 `rabbitmq` 集群在 `k8s` 中的自动化部署，因此低于3.7.X版本请使用 `rabbitmq-autocluster`

## 二. 服务编排

- 部署的版本是 `3.8.3`
- 默认部署在 `default` 命名空间下，
- 持久化存储为 `storageclass` 动态存储，底层为 `nfs` 提供，参考：`Kubernetes 部署-NFS-Subdir-External-Provisioner`
- 镜像地址 `rabbitmq:3.8.3-management`

以下 `yaml` 参考自  [官方示例](https://github.com/rabbitmq/diy-kubernetes-examples/tree/master/minikube)

1）创建 configmap

```yaml
kind: ConfigMap
apiVersion: v1
metadata:
  name: rabbitmq-cluster-config
  namespace: default
  labels:
    addonmanager.kubernetes.io/mode: Reconcile
data:
    enabled_plugins: |
      [rabbitmq_management,rabbitmq_peer_discovery_k8s].
    rabbitmq.conf: |
      default_user = admin
      default_pass = admin
      ## Cluster formation. See https://www.rabbitmq.com/cluster-formation.html to learn more.
      cluster_formation.peer_discovery_backend = rabbit_peer_discovery_k8s
      cluster_formation.k8s.host = kubernetes.default.svc.cluster.local
      ## Should RabbitMQ node name be computed from the pod's hostname or IP address?
      ## IP addresses are not stable, so using [stable] hostnames is recommended when possible.
      ## Set to "hostname" to use pod hostnames.
      ## When this value is changed, so should the variable used to set the RABBITMQ_NODENAME
      ## environment variable.
      cluster_formation.k8s.address_type = hostname
      ## How often should node cleanup checks run?
      cluster_formation.node_cleanup.interval = 30
      ## Set to false if automatic removal of unknown/absent nodes
      ## is desired. This can be dangerous, see
      ##  * https://www.rabbitmq.com/cluster-formation.html#node-health-checks-and-cleanup
      ##  * https://groups.google.com/forum/#!msg/rabbitmq-users/wuOfzEywHXo/k8z_HWIkBgAJ
      cluster_formation.node_cleanup.only_log_warning = true
      cluster_partition_handling = autoheal
      ## See https://www.rabbitmq.com/ha.html#master-migration-data-locality
      queue_master_locator=min-masters
      ## See https://www.rabbitmq.com/access-control.html#loopback-users
      loopback_users.guest = false
      cluster_formation.randomized_startup_delay_range.min = 0
      cluster_formation.randomized_startup_delay_range.max = 2
      # default is rabbitmq-cluster's namespace
      # hostname_suffix
      cluster_formation.k8s.hostname_suffix = .rabbitmq-cluster.default.svc.cluster.local
      # memory
      vm_memory_high_watermark.absolute = 1GB
      # disk
      disk_free_limit.absolute = 2GB
```

部分参数说明：

- `enabled_plugins`：声明开启的插件名
- `default_pass/default_pass`：声明用户名和密码（虽然有部分文章记录可以通过环境变量的方式声明，但是经测试，针对此版本如果指定了 `configmap` 即 `rabbitmq` 的配置文件，声明的环境变量是没有用的，都需要在配置文件中指定）
- `cluster_formation.k8s.address_type`：从 `k8s` 返回的 `Pod` 容器列表中计算对等节点列表，这里只能使用主机名，官方示例中是 `ip`，但是默认情况下在 `k8s` 中 `pod` 的 `ip` 都是不固定的，因此可能导致节点的配置和数据丢失，后面的 `yaml` 中会通过引用元数据的方式固定 `pod` 的主机名。

2）创建 service

```yaml
kind: Service
apiVersion: v1
metadata:
  labels:
    app: rabbitmq-cluster
  name: rabbitmq-cluster
  namespace: default
spec:
  clusterIP: None
  ports:
  - name: rmqport
    port: 5672
    targetPort: 5672
  selector:
    app: rabbitmq-cluster

---
kind: Service
apiVersion: v1
metadata:
  labels:
    app: rabbitmq-cluster
  name: rabbitmq-cluster-manage
  namespace: default
spec:
  ports:
  - name: http
    port: 15672
    protocol: TCP
    targetPort: 15672
  selector:
    app: rabbitmq-cluster
  type: NodePort
```

上面定义了两个 `Service`，一个是 `rabbitmq` 的服务端口，一个是管理界面的端口，用户外部访问，这里通过 `NodePort` 方式进行暴露

3）创建 rbac 授权

前面的介绍中提到了 `RabbitMQ` 通过插件与k8s apiserver交互获得集群中节点相关信息，因此需要对其进行 `RBAC` 授权

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: rabbitmq-cluster
  namespace: default
---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: rabbitmq-cluster
  namespace: default
rules:
- apiGroups: [""]
  resources: ["endpoints"]
  verbs: ["get"]
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: rabbitmq-cluster
  namespace: default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: rabbitmq-cluster
subjects:
- kind: ServiceAccount
  name: rabbitmq-cluster
  namespace: default
```

4）创建 statefulset

`RabbitMQ` 在 `k8s` 中作为一个有状态应用进行部署，因此控制器类型为`StatefulSet`，`yaml` 中还定义了 `pvc` 相关内容

```yaml
kind: StatefulSet
apiVersion: apps/v1
metadata:
  labels:
    app: rabbitmq-cluster
  name: rabbitmq-cluster
  namespace: default
spec:
  replicas: 3
  selector:
    matchLabels:
      app: rabbitmq-cluster
  serviceName: rabbitmq-cluster
  template:
    metadata:
      labels:
        app: rabbitmq-cluster
    spec:
      containers:
      - args:
        - -c
        - cp -v /etc/rabbitmq/rabbitmq.conf ${RABBITMQ_CONFIG_FILE}; exec docker-entrypoint.sh
          rabbitmq-server
        command:
        - sh
        env:
        - name: TZ
          value: 'Asia/Shanghai'
        - name: RABBITMQ_ERLANG_COOKIE
          value: 'SWvCP0Hrqv43NG7GybHC95ntCJKoW8UyNFWnBEWG8TY='
        - name: K8S_SERVICE_NAME
          value: rabbitmq-cluster
        - name: POD_IP
          valueFrom:
            fieldRef:
              fieldPath: status.podIP
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: POD_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        - name: RABBITMQ_USE_LONGNAME
          value: "true"
        - name: RABBITMQ_NODENAME
          value: rabbit@$(POD_NAME).$(K8S_SERVICE_NAME).$(POD_NAMESPACE).svc.cluster.local
        - name: RABBITMQ_CONFIG_FILE
          value: /var/lib/rabbitmq/rabbitmq.conf
        image: rabbitmq:3.8.3-management
        imagePullPolicy: IfNotPresent
        livenessProbe:
          exec:
            command:
            - rabbitmq-diagnostics
            - status
          # See https://www.rabbitmq.com/monitoring.html for monitoring frequency recommendations.
          initialDelaySeconds: 60
          periodSeconds: 60
          timeoutSeconds: 15
        name: rabbitmq
        ports:
        - containerPort: 15672
          name: http
          protocol: TCP
        - containerPort: 5672
          name: amqp
          protocol: TCP
        readinessProbe:
          exec:
            command:
            - rabbitmq-diagnostics
            - status
          initialDelaySeconds: 20
          periodSeconds: 60
          timeoutSeconds: 10
        volumeMounts:
        - mountPath: /etc/rabbitmq
          name: config-volume
          readOnly: false
        - mountPath: /var/lib/rabbitmq
          name: rabbitmq-storage
          readOnly: false
        - name: timezone
          mountPath: /etc/localtime
          readOnly: true
      serviceAccountName: rabbitmq-cluster
      terminationGracePeriodSeconds: 30
      volumes:
      - name: config-volume
        configMap:
          items:
          - key: rabbitmq.conf
            path: rabbitmq.conf
          - key: enabled_plugins
            path: enabled_plugins
          name: rabbitmq-cluster-config
      - name: timezone
        hostPath:
          path: /usr/share/zoneinfo/Asia/Shanghai
  volumeClaimTemplates:
  - metadata:
      name: rabbitmq-storage
    spec:
      accessModes:
      - ReadWriteMany
      storageClassName: "managed-nfs-storage"
      resources:
        requests:
          storage: 2Gi
```

## 三. 部署检查

```bash
$ kubectl create -f .
configmap/rabbitmq-cluster-config created
service/rabbitmq-cluster created
service/rabbitmq-cluster-manage created
serviceaccount/rabbitmq-cluster created
role.rbac.authorization.k8s.io/rabbitmq-cluster created
rolebinding.rbac.authorization.k8s.io/rabbitmq-cluster created
statefulset.apps/rabbitmq-cluster created

$ kubectl get po,sts -l app=rabbitmq-cluster
NAME                     READY   STATUS    RESTARTS   AGE
pod/rabbitmq-cluster-0   1/1     Running   0          38m
pod/rabbitmq-cluster-1   1/1     Running   0          37m
pod/rabbitmq-cluster-2   1/1     Running   0          36m

NAME                                READY   AGE
statefulset.apps/rabbitmq-cluster   3/3     38m


$ kubectl logs -f rabbitmq-cluster-0
'/etc/rabbitmq/rabbitmq.conf' -> '/var/lib/rabbitmq/rabbitmq.conf'
2021-08-24 09:07:01.687 [info] <0.9.0> Feature flags: list of feature flags found:
2021-08-24 09:07:01.687 [info] <0.9.0> Feature flags:   [ ] drop_unroutable_metric
2021-08-24 09:07:01.687 [info] <0.9.0> Feature flags:   [ ] empty_basic_get_metric
2021-08-24 09:07:01.687 [info] <0.9.0> Feature flags:   [ ] implicit_default_bindings
2021-08-24 09:07:01.687 [info] <0.9.0> Feature flags:   [ ] quorum_queue
2021-08-24 09:07:01.688 [info] <0.9.0> Feature flags:   [ ] virtual_host_metadata
2021-08-24 09:07:01.688 [info] <0.9.0> Feature flags: feature flag states written to disk: yes
2021-08-24 09:07:01.722 [info] <0.269.0> ra: meta data store initialised. 0 record(s) recovered
2021-08-24 09:07:01.724 [info] <0.274.0> WAL: recovering []
2021-08-24 09:07:28.887 [info] <0.309.0> 
 Starting RabbitMQ 3.8.3 on Erlang 22.3.4.1
 Copyright (c) 2007-2020 Pivotal Software, Inc.
 Licensed under the MPL 1.1. Website: https://rabbitmq.com

  ##  ##      RabbitMQ 3.8.3
  ##  ##
  ##########  Copyright (c) 2007-2020 Pivotal Software, Inc.
  ######  ##
  ##########  Licensed under the MPL 1.1. Website: https://rabbitmq.com

  Doc guides: https://rabbitmq.com/documentation.html
  Support:    https://rabbitmq.com/contact.html
  Tutorials:  https://rabbitmq.com/getstarted.html
  Monitoring: https://rabbitmq.com/monitoring.html

  Logs: <stdout>

  Config file(s): /var/lib/rabbitmq/rabbitmq.conf

  Starting broker...2021-08-24 09:07:28.889 [info] <0.309.0> 
 node           : rabbit@rabbitmq-cluster-0.rabbitmq-cluster.default.svc.cluster.local
 home dir       : /var/lib/rabbitmq
 config file(s) : /var/lib/rabbitmq/rabbitmq.conf
 cookie hash    : H+IQL2spD4MDV4jPi7mMAg==
 log(s)         : <stdout>
 database dir   : /var/lib/rabbitmq/mnesia/rabbit@rabbitmq-cluster-0.rabbitmq-cluster.default.svc.cluster.local
...中间省略
 completed with 5 plugins.
2021-08-24 09:08:53.301 [info] <0.561.0> node 'rabbit@rabbitmq-cluster-1.rabbitmq-cluster.default.svc.cluster.local' up
2021-08-24 09:08:53.863 [info] <0.561.0> rabbit on node 'rabbit@rabbitmq-cluster-1.rabbitmq-cluster.default.svc.cluster.local' up
2021-08-24 09:09:54.886 [info] <0.561.0> node 'rabbit@rabbitmq-cluster-2.rabbitmq-cluster.default.svc.cluster.local' up
2021-08-24 09:09:55.495 [info] <0.561.0> rabbit on node 'rabbit@rabbitmq-cluster-2.rabbitmq-cluster.default.svc.cluster.local' up
```

进入到 `pod` 中通过客户端查看集群状态

```bash
$ kubectl exec -it rabbitmq-cluster-0 bash
kubectl exec [POD] [COMMAND] is DEPRECATED and will be removed in a future version. Use kubectl exec [POD] -- [COMMAND] instead.
root@rabbitmq-cluster-0:/# rabbitmqctl cluster_status
Cluster status of node rabbit@rabbitmq-cluster-0.rabbitmq-cluster.default.svc.cluster.local ...
Basics

Cluster name: rabbit@rabbitmq-cluster-0.rabbitmq-cluster.default.svc.cluster.local

Disk Nodes

rabbit@rabbitmq-cluster-0.rabbitmq-cluster.default.svc.cluster.local
rabbit@rabbitmq-cluster-1.rabbitmq-cluster.default.svc.cluster.local
rabbit@rabbitmq-cluster-2.rabbitmq-cluster.default.svc.cluster.local

Running Nodes

rabbit@rabbitmq-cluster-0.rabbitmq-cluster.default.svc.cluster.local
rabbit@rabbitmq-cluster-1.rabbitmq-cluster.default.svc.cluster.local
rabbit@rabbitmq-cluster-2.rabbitmq-cluster.default.svc.cluster.local

Versions

rabbit@rabbitmq-cluster-0.rabbitmq-cluster.default.svc.cluster.local: RabbitMQ 3.8.3 on Erlang 22.3.4.1
rabbit@rabbitmq-cluster-1.rabbitmq-cluster.default.svc.cluster.local: RabbitMQ 3.8.3 on Erlang 22.3.4.1
rabbit@rabbitmq-cluster-2.rabbitmq-cluster.default.svc.cluster.local: RabbitMQ 3.8.3 on Erlang 22.3.4.1
```

通过 `NodePort` 访问管理界面

```bash
$ kubectl get svc -l app=rabbitmq-cluster
NAME                      TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)           AGE
rabbitmq-cluster          ClusterIP   None             <none>        5672/TCP          45m
rabbitmq-cluster-manage   NodePort    120.100.38.129   <none>        15672:31585/TCP   45m
```

![](https://img.17121203.xyz/i/2024/10/22/i9kict-0.webp)

**参考链接**

- https://www.rabbitmq.com/cluster-formation.html 
- https://github.com/rabbitmq/diy-kubernetes-examples
- https://cloud.tencent.com/developer/article/1793774?from=article.detail.1782766