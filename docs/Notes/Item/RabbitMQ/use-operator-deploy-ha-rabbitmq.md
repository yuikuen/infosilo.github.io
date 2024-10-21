> 通过 K8s+Operator 部署高可用 RabbitMQ

## 一. 安装说明

> 安装步骤主要参考[官方示例](https://www.rabbitmq.com/kubernetes/operator/quickstart-operator.html)

1. k8s 版本要 1.18 及其以上
2. 能够在 master 节点上使用 kubectl 命令来管理整个 k8s 集群
3. 有默认的一个 StorageClass 存储类，因为默认情况下 RabbitMQ Operator 创建的 RabbitMQ 集群会为每个实例使用 StorageClass 分配一个 10G 的 PVC。但是官方提供的yaml文件中并没有设置使用 StorageClass 存储类的配置，所以需要一个默认的 StorageClass 存储类。

> 若没有这个默认的 StorageClass 存储类，则创建 RabbitMQ 集群时创建的 pod 状态是 Pending，具体原因是：pod has unbound immediate PersistentVolumeClaims

查看默认 StorageClass 储存类，注意 default

```bash
# kubectl get sc -o wide
NAME                    PROVISIONER                     RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
nfs-164                 nfs-nfs-164                     Delete          WaitForFirstConsumer   false                  37d
rook-ceph-block         rook-ceph.rbd.csi.ceph.com      Delete          Immediate              true                   24h
rook-cephfs (default)   rook-ceph.cephfs.csi.ceph.com   Delete          Immediate              true                   23h
storage                 nfs-storage                     Delete          WaitForFirstConsumer   false                  39d
```

安装步骤

- 安装 RabbitMQ 集群操作员
- 使用 RabbitMQ 集群操作员部署 RabbitMQ 集群
- 查看 RabbitMQ日志
- 访问 RabbitMQ 管理 UI
- 设置应用访问 RabbitMQ 集群

- 第一种方式是采用插件的方式，详见地址：[ https://cloud.tencent.com/developer/article/1782766](https://cloud.tencent.com/developer/article/1782766)
  需要先安装插件管理工具 krew，然后才能使用插件的方式进行安装。在安装的过程中会从 GitHub 上下载东西，访问 GitHub 慢的不建议采用这种方式

- 第二种方式是通过 yaml 文件的方式进行安装，这里采用这种方式进行

## 二. 安装 Operator

1）使用 yaml 文件的方式进行安装 cluster-operator ( [yaml 文件下载地址](https://github.com/rabbitmq/cluster-operator/releases) )

```bash
# kubectl create -f cluster-operator.yaml       
namespace/rabbitmq-system created
customresourcedefinition.apiextensions.k8s.io/rabbitmqclusters.rabbitmq.com created
serviceaccount/rabbitmq-cluster-operator created
role.rbac.authorization.k8s.io/rabbitmq-cluster-leader-election-role created
clusterrole.rbac.authorization.k8s.io/rabbitmq-cluster-operator-role created
rolebinding.rbac.authorization.k8s.io/rabbitmq-cluster-leader-election-rolebinding created
clusterrolebinding.rbac.authorization.k8s.io/rabbitmq-cluster-operator-rolebinding created
deployment.apps/rabbitmq-cluster-operator created
```

2）会创建一个新的名称空间：rabbitmq-system

```bash
# kubectl get all -n rabbitmq-system
NAME                                             READY   STATUS    RESTARTS   AGE
pod/rabbitmq-cluster-operator-7c65454ff9-f52b2   1/1     Running   0          32m

NAME                                        READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/rabbitmq-cluster-operator   1/1     1            1           32m

NAME                                                   DESIRED   CURRENT   READY   AGE
replicaset.apps/rabbitmq-cluster-operator-7c65454ff9   1         1         1       32m
```

3）通过上面的显示可以发现有个一脉相承的如下关系：

```html
资源类型：deployment =》 replicaset =》 pod
具体名称 ：rabbitmq-cluster-operator =》rabbitmq-cluster-operator-7c65454ff9 =》rabbitmq-cluster-operator-7c65454ff9-td2pm
```

4）新的自定义资源 rabbitmqclusters.rabbitmq.com。自定义资源允许我们定义用于创建 RabbitMQ 集群的 API。以及一些 rbac 角色。这些是操作员创建、更新和删除 RabbitMQ 集群所必需的。

```bash
# kubectl get customresourcedefinitions.apiextensions.k8s.io 
NAME                                             CREATED AT
...
rabbitmqclusters.rabbitmq.com                    2021-06-04T02:21:42Z
...
```

## 三. 安装 RabbitMQ

1）使用 cluster-operator 创建 RabbitMQ 集群

[简单的 yaml 文件模版](https://github.com/rabbitmq/cluster-operator/tree/main/docs/examples/hello-world)，这是最简单的 RabbitmqCluster 定义。唯一显示指定的属性是集群的名称。其他一切都将根据集群运营商的默认值进行配置。

[examples 模版目录](https://github.com/rabbitmq/cluster-operator/tree/main/docs/examples/) 还有许多其他引用，比如用 TLS、mTLS 创建 RabbitMQ 集群，用生产默认值设置集群，添加社区插件等等。

```yaml
# cat rabbitmq.yaml
apiVersion: rabbitmq.com/v1beta1
kind: RabbitmqCluster
metadata:
  name: my-rabbit-cluster
  namespace: rabbitmq-system
```

> 注意：默认没有写名称空间则会部署到defalut中，这里修改成rabbitmq-system

```bash
# kubectl create -f rabbitmq.yaml 
rabbitmqcluster.rabbitmq.com/my-rabbit-cluster created
```

2）在 rabbitmq-system 命名空间中创建了一个名为 my-rabbit-cluster 的 RabbitMQ 集群。可以在创建 RabbitMQ 集群时看到它：

```bash
# kubectl get pod -n rabbitmq-system
NAME                                         READY   STATUS    RESTARTS   AGE
my-rabbit-cluster-server-0                   1/1     Running   0          80s
```

3）还可以看到创建的 rabbitmqclusters.rabbitmq.com 自定义资源的实例。

```bash
# kubectl get rabbitmqclusters.rabbitmq.com -n rabbitmq-system
NAME                AGE
my-rabbit-cluster   2m33s
```

4）查看 RabbitMQ 日志

```bash
# kubectl logs my-rabbit-cluster-server-0 -n rabbitmq-system
 Starting RabbitMQ 3.8.16 on Erlang 24.0.2
 Copyright (c) 2007-2021 VMware, Inc. or its affiliates.
 Licensed under the MPL 2.0. Website: https://rabbitmq.com

  ##  ##      RabbitMQ 3.8.16
  ##  ##
  ##########  Copyright (c) 2007-2021 VMware, Inc. or its affiliates.
  ######  ##
  ##########  Licensed under the MPL 2.0. Website: https://rabbitmq.com

  Doc guides: https://rabbitmq.com/documentation.html
  Support:    https://rabbitmq.com/contact.html
  Tutorials:  https://rabbitmq.com/getstarted.html
  Monitoring: https://rabbitmq.com/monitoring.html

  Logs: <stdout>

  Config file(s): /etc/rabbitmq/rabbitmq.conf
                  /etc/rabbitmq/conf.d/10-operatorDefaults.conf
                  /etc/rabbitmq/conf.d/11-default_user.conf
                  /etc/rabbitmq/conf.d/90-userDefinedConfiguration.conf

  Starting broker...2021-06-04 03:05:59.646 [info] <0.273.0> 
 node           : rabbit@my-rabbit-cluster-server-0.my-rabbit-cluster-nodes.rabbitmq-system
 home dir       : /var/lib/rabbitmq
 config file(s) : /etc/rabbitmq/rabbitmq.conf
                : /etc/rabbitmq/conf.d/10-operatorDefaults.conf
                : /etc/rabbitmq/conf.d/11-default_user.conf
                : /etc/rabbitmq/conf.d/90-userDefinedConfiguration.conf
 cookie hash    : kH25nUaPr1ngafL6UipoTQ==
 log(s)         : <stdout>
 database dir   : /var/lib/rabbitmq/mnesia/rabbit@my-rabbit-cluster-server-0.my-rabbit-cluster-nodes.rabbitmq-system
```

5）访问 RabbitMQ 管理 UI

**获取用户名和密码**

```bash
username="$(kubectl get secret my-rabbit-cluster-default-user -n rabbitmq-system -o jsonpath='{.data.username}' | base64 --decode)"
echo "username: $username"  

password="$(kubectl get secret my-rabbit-cluster-default-user -n rabbitmq-system -o jsonpath='{.data.password}' | base64 --decode)"
echo "password: $password"
```

默认会创建一个类型是 ClusterIP 的 svc

```bash
# kubectl get svc -n rabbitmq-system
NAME                      TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)                        AGE
my-rabbit-cluster         ClusterIP   10.3.255.186   <none>        5672/TCP,15672/TCP,15692/TCP   8m18s
my-rabbit-cluster-nodes   ClusterIP   None           <none>        4369/TCP,25672/TCP             8m18s
```

- 办法一是修改 ClusterIP 类型为 NodePort，使用宿主机 IP 和 nodeport 端口来访问

```html
# kubectl edit svc my-rabbit-cluster -n rabbitmq-system
```

> 注:这种方式一开始修改后是能够访问使用的，但是删除集群后重新创建并这样设置，就无法修改成 NodePort了，很是奇怪。

- 办法二是使用 kube-proxy 进行代理来实现访问

```bash
# kubectl port-forward svc/my-rabbit-cluster 15672      
Forwarding from 127.0.0.1:15672 -> 15672
Forwarding from [::1]:15672 -> 15672
```

现在我们可以通过 localhost:15672 在打开浏览器并查看管理 UI。或者，可以运行 curl 命令来验证访问：

```bash
curl -u$username:$password localhost:15672/api/overview
```

```bash
[root@develop-master-1 ~]# username="$(kubectl get secret my-rabbit-cluster-default-user -n rabbitmq-system -o jsonpath='{.data.username}' | base64 --decode)" && echo "username: $username"
username: YNbrfwcmEqnuJD6BZthuWZP9bTJQuYmW
[root@develop-master-1 ~]# password="$(kubectl get secret my-rabbit-cluster-default-user -n rabbitmq-system -o jsonpath='{.data.password}' | base64 --decode)" && echo "password: $password"
password: 88DzY3WQ51Q2Q9FfWJKrTaQpLUgSfeWP
[root@develop-master-1 ~]# curl -uYNbrfwcmEqnuJD6BZthuWZP9bTJQuYmW:88DzY3WQ51Q2Q9FfWJKrTaQpLUgSfeWP localhost:15672/api/overview
{"management_version":"3.8.16","rates_mode":"basic","sample_retention_policies":{"global":[600,3600,28800,86400],"basic":[600,3600],"detailed":[600]},"exchange_types":[{"name":"direct","description":"AMQP direct exchange, as per the AMQP specification","enabled":true},{"name":"fanout","description":"AMQP fanout exchange, as per the AMQP specification","enabled":true},{"name":"headers","description":"AMQP headers exchange, as per the AMQP specification","enabled":true},{"name":"topic","description":"AMQP topic exchange, as per the AMQP specification","enabled":true}],"product_version":"3.8.16","product_name":"RabbitMQ","rabbitmq_version":"3.8.16","cluster_name":"my-rabbit-cluster","erlang_version":"24.0.2","erlang_full_version":"Erlang/OTP 24 [erts-12.0.2] [source] [64-bit] [smp:2:2] [ds:2:2:10] [async-threads:1]","disable_stats":false,"enable_queue_totals":false,"message_stats":{},"churn_rates":{"channel_closed":0,"channel_closed_details":{"rate":0.0},"channel_created":0,"channel_created_details":{"rate":0.0},"connection_closed":60,"connection_closed_details":{"rate":0.0},"connection_created":0,"connection_created_details":{"rate":0.0},"queue_created":0,"queue_created_details":{"rate":0.0},"queue_declared":0,"queue_declared_details":{"rate":0.0},"queue_deleted":0,"queue_deleted_details":{"rate":0.0}},"queue_totals":{},"object_totals":{"channels":0,"connections":0,"consumers":0,"exchanges":7,"queues":0},"statistics_db_event_queue":0,"node":"rabbit@my-rabbit-cluster-server-0.my-rabbit-cluster-nodes.default","listeners":[{"node":"rabbit@my-rabbit-cluster-server-0.my-rabbit-cluster-nodes.default","protocol":"amqp","ip_address":"::","port":5672,"socket_opts":{"backlog":128,"nodelay":true,"linger":[true,0],"exit_on_close":false}},{"node":"rabbit@my-rabbit-cluster-server-0.my-rabbit-cluster-nodes.default","protocol":"clustering","ip_address":"::","port":25672,"socket_opts":[]},{"node":"rabbit@my-rabbit-cluster-server-0.my-rabbit-cluster-nodes.default","protocol":"http","ip_address":"::","port":15672,"socket_opts":{"cowboy_opts":{"sendfile":false},"port":15672}},{"node":"rabbit@my-rabbit-cluster-server-0.my-rabbit-cluster-nodes.default","protocol":"http/prometheus","ip_address":"::","port":15692,"socket_opts":{"cowboy_opts":{"sendfile":false},"port":15692,"protocol":"http/prometheus"}}],"contexts":[{"ssl_opts":[],"node":"rabbit@my-rabbit-cluster-server-0.my-rabbit-cluster-nodes.default","description":"RabbitMQ Management","path":"/","cowboy_opts":"[{sendfile,false}]","port":"15672"},{"ssl_opts":[],"node":"rabbit@my-rabbit-cluster-server-0.my-rabbit-cluster-nodes.default","description":"RabbitMQ Prometheus","path":"/","cowboy_opts":"[{sendfile,false}]","port":"15692","protocol":"'http/prometheus'"}]}
```

6）设置应用访问 RabbitMQ 集群

```bash
# username="$(kubectl get secret my-rabbit-cluster-default-user -n rabbitmq-system -o jsonpath='{.data.username}' | base64 --decode)"
# password="$(kubectl get secret my-rabbit-cluster-default-user -n rabbitmq-system -o jsonpath='{.data.password}' | base64 --decode)"
# service="$(kubectl get service my-rabbit-cluster -n rabbitmq-system -o jsonpath='{.spec.clusterIP}')"
# kubectl run perf-test --image=pivotalrabbitmq/perf-test -- --uri amqp://$username:$password@$service

pod/perf-test created

# kubectl logs --follow perf-test
id: test-041921-512, time: 1.000s, sent: 4720 msg/s, received: 2109 msg/s, min/median/75th/95th/99th consumer latency: 3075/22253/33855/75681/89195 µs
id: test-041921-512, time: 2.000s, sent: 16538 msg/s, received: 13698 msg/s, min/median/75th/95th/99th consumer latency: 91432/157833/203565/344737/356844 µs
id: test-041921-512, time: 3.001s, sent: 18142 msg/s, received: 17832 msg/s, min/median/75th/95th/99th consumer latency: 268145/343634/378988/437575/450074 µs
id: test-041921-512, time: 4.001s, sent: 20991 msg/s, received: 17456 msg/s, min/median/75th/95th/99th consumer latency: 264207/345566/373946/407531/425332 µs
id: test-041921-512, time: 5.015s, sent: 24398 msg/s, received: 13231 msg/s, min/median/75th/95th/99th consumer latency: 358486/701769/755296/803202/832797 µs
id: test-041921-512, time: 6.017s, sent: 14616 msg/s, received: 12665 msg/s, min/median/75th/95th/99th consumer latency: 834423/1083012/1225606/1335011/1374533 µs
id: test-041921-512, time: 7.019s, sent: 16229 msg/s, received: 14603 msg/s, min/median/75th/95th/99th consumer latency: 1335783/1502060/1614123/1700792/1742414 µs
可以看出，perf-test每秒能够产生和消耗大约12000条消息。
```

## 四. 创建监控

**使用 Prometheus & Grafana 监控 rabbitmq 集群，可参考 **[官方文档地址](https://www.rabbitmq.com/prometheus.html)

注意：当扩充增加到 2 个甚至更多的时候，需要 k8s 节点资源是否足够。如报错：`0/3 nodes are available: 3 Insufficient cpu.` 原因是 k8s 节点资源资源不足。
1）创建 rabbitmq 集群时使用的是默认配置，默认配置中资源要求如下：

```yaml
Limits:
  cpu:     2
  memory:  2Gi
Requests:
  cpu:      1
  memory:   2Gi
```

2）自动生成第二个 pod 时查看的详情如下：

```bash
Name:           my-rabbit-cluster-server-1
Namespace:      rabbitmq-system
Priority:       0
Node:           <none>
Labels:         app.kubernetes.io/component=rabbitmq
                app.kubernetes.io/name=my-rabbit-cluster
                app.kubernetes.io/part-of=rabbitmq
                controller-revision-hash=my-rabbit-cluster-server-b7d484587
                statefulset.kubernetes.io/pod-name=my-rabbit-cluster-server-1
Annotations:    prometheus.io/port: 15692
                prometheus.io/scrape: true
Status:         Pending
IP:             
IPs:            <none>
Controlled By:  StatefulSet/my-rabbit-cluster-server
Init Containers:
  setup-container:
    Image:      rabbitmq:3.8.16-management
    Port:       <none>
    Host Port:  <none>
    Command:
      sh
      -c
      cp /tmp/erlang-cookie-secret/.erlang.cookie /var/lib/rabbitmq/.erlang.cookie && chown 999:999 /var/lib/rabbitmq/.erlang.cookie && chmod 600 /var/lib/rabbitmq/.erlang.cookie ; cp /tmp/rabbitmq-plugins/enabled_plugins /operator/enabled_plugins && chown 999:999 /operator/enabled_plugins ; chown 999:999 /var/lib/rabbitmq/mnesia/ ; echo '[default]' > /var/lib/rabbitmq/.rabbitmqadmin.conf && sed -e 's/default_user/username/' -e 's/default_pass/password/' /tmp/default_user.conf >> /var/lib/rabbitmq/.rabbitmqadmin.conf && chown 999:999 /var/lib/rabbitmq/.rabbitmqadmin.conf && chmod 600 /var/lib/rabbitmq/.rabbitmqadmin.conf
    Limits:
      cpu:     100m
      memory:  500Mi
    Requests:
      cpu:        100m
      memory:     500Mi
    Environment:  <none>
    Mounts:
      /operator from rabbitmq-plugins (rw)
      /tmp/default_user.conf from rabbitmq-confd (rw,path="default_user.conf")
      /tmp/erlang-cookie-secret/ from erlang-cookie-secret (rw)
      /tmp/rabbitmq-plugins/ from plugins-conf (rw)
      /var/lib/rabbitmq/ from rabbitmq-erlang-cookie (rw)
      /var/lib/rabbitmq/mnesia/ from persistence (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from my-rabbit-cluster-server-token-vgvp4 (ro)
Containers:
  rabbitmq:
    Image:       rabbitmq:3.8.16-management
    Ports:       4369/TCP, 5672/TCP, 15672/TCP, 15692/TCP
    Host Ports:  0/TCP, 0/TCP, 0/TCP, 0/TCP
    Limits:
      cpu:     2
      memory:  2Gi
    Requests:
      cpu:      1
      memory:   2Gi
    Readiness:  tcp-socket :amqp delay=10s timeout=5s period=10s #success=1 #failure=3
    Environment:
      MY_POD_NAME:                    my-rabbit-cluster-server-1 (v1:metadata.name)
      MY_POD_NAMESPACE:               default (v1:metadata.namespace)
      RABBITMQ_ENABLED_PLUGINS_FILE:  /operator/enabled_plugins
      K8S_SERVICE_NAME:               my-rabbit-cluster-nodes
      RABBITMQ_USE_LONGNAME:          true
      RABBITMQ_NODENAME:              rabbit@$(MY_POD_NAME).$(K8S_SERVICE_NAME).$(MY_POD_NAMESPACE)
      K8S_HOSTNAME_SUFFIX:            .$(K8S_SERVICE_NAME).$(MY_POD_NAMESPACE)
    Mounts:
      /etc/pod-info/ from pod-info (rw)
      /etc/rabbitmq/conf.d/10-operatorDefaults.conf from rabbitmq-confd (rw,path="operatorDefaults.conf")
      /etc/rabbitmq/conf.d/11-default_user.conf from rabbitmq-confd (rw,path="default_user.conf")
      /etc/rabbitmq/conf.d/90-userDefinedConfiguration.conf from rabbitmq-confd (rw,path="userDefinedConfiguration.conf")
      /operator from rabbitmq-plugins (rw)
      /var/lib/rabbitmq/ from rabbitmq-erlang-cookie (rw)
      /var/lib/rabbitmq/mnesia/ from persistence (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from my-rabbit-cluster-server-token-vgvp4 (ro)
Conditions:
  Type           Status
  PodScheduled   False 
Volumes:
  persistence:
    Type:       PersistentVolumeClaim (a reference to a PersistentVolumeClaim in the same namespace)
    ClaimName:  persistence-my-rabbit-cluster-server-1
    ReadOnly:   false
  plugins-conf:
    Type:      ConfigMap (a volume populated by a ConfigMap)
    Name:      my-rabbit-cluster-plugins-conf
    Optional:  false
  rabbitmq-confd:
    Type:                Projected (a volume that contains injected data from multiple sources)
    SecretName:          my-rabbit-cluster-default-user
    SecretOptionalName:  <nil>
    ConfigMapName:       my-rabbit-cluster-server-conf
    ConfigMapOptional:   <nil>
  rabbitmq-erlang-cookie:
    Type:       EmptyDir (a temporary directory that shares a pod's lifetime)
    Medium:     
    SizeLimit:  <unset>
  erlang-cookie-secret:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  my-rabbit-cluster-erlang-cookie
    Optional:    false
  rabbitmq-plugins:
    Type:       EmptyDir (a temporary directory that shares a pod's lifetime)
    Medium:     
    SizeLimit:  <unset>
  pod-info:
    Type:  DownwardAPI (a volume populated by information about the pod)
    Items:
      metadata.labels['skipPreStopChecks'] -> skipPreStopChecks
  my-rabbit-cluster-server-token-vgvp4:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  my-rabbit-cluster-server-token-vgvp4
    Optional:    false
QoS Class:       Burstable
Node-Selectors:  <none>
Tolerations:     node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                 node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type     Reason            Age                From               Message
  ----     ------            ----               ----               -------
  Warning  FailedScheduling  33s (x2 over 33s)  default-scheduler  0/3 nodes are available: 3 Insufficient cpu.
```
