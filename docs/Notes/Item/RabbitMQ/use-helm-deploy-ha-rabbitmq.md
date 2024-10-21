> 通过 K8s+Helm 部署高可用 RabbitMQ
>
> Helm 详细部署请参考相关 Helm 文档，在此主要为 RabbitMQ-HA 部署

- 官方文档：https://helm.sh/docs/intro/install/
- 版本下载地址：https://github.com/helm/helm/releases

**实例流程**

- 通过 Helm 搜索并下载相关 RabbitMQ-HA 版本
- 拉取指定版本文件，解压并进行配置定制
- 创建 Namespace 和以 Helm Charts 方式创建构建
- 集群登录、测试功能等操作

**添加常用仓库**

```bash
$ helm version
version.BuildInfo{Version:"v3.5.4", GitCommit:"1b5edb69df3d3a08df77c9902dc17af864ff05d1", GitTreeState:"clean", GoVersion:"go1.15.11"}

# 添加仓库的方法，可使用 -h 查看或自行百度
$ helm repo add -h
add a chart repository

Usage:
  helm repo add [NAME] [URL] [flags]

$ helm repo add aliyuncs https://apphub.aliyuncs.com
$ helm repo add stable https://kubernetes.oss-cn-hangzhou.aliyuncs.com/charts
$ helm repo list
NAME         	URL                                                   
ingress-nginx	https://kubernetes.github.io/ingress-nginx            
aliyuncs     	https://apphub.aliyuncs.com                           
stable       	https://kubernetes.oss-cn-hangzhou.aliyuncs.com/charts
```

**查看可用版本并拉取**

```bash
$ helm search repo rabbitmq-ha
NAME                	CHART VERSION	APP VERSION	DESCRIPTION                                       
aliyuncs/rabbitmq-ha	1.39.0       	3.8.0      	Highly available RabbitMQ cluster, the open sou...
stable/rabbitmq-ha  	1.0.0        	3.7.3      	Highly available RabbitMQ cluster, the open sou...

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
stable/rabbitmq-ha  	1.0.0        	3.7.3      	Highly available RabbitMQ cluster, the open sou...
stable/rabbitmq-ha  	0.1.1        	3.7.0      	Highly available RabbitMQ cluster, the open sou...
```

```bash
$ helm pull aliyuncs/rabbitmq-ha --version=1.33.0
$ tar -xf rabbitmq-ha-1.33.0.tgz
$ tree rabbitmq-ha
rabbitmq-ha                
├── Chart.yaml                
├── OWNERS
├── README.md
├── templates
│   ├── alerts.yaml              
│   ├── configmap.yaml
│   ├── _helpers.tpl           
│   ├── ingress.yaml
│   ├── NOTES.txt            
│   ├── pdb.yaml
│   ├── rolebinding.yaml
│   ├── role.yaml
│   ├── secret.yaml
│   ├── serviceaccount.yaml
│   ├── service-discovery.yaml
│   ├── servicemonitor.yaml
│   ├── service.yaml
│   └── statefulset.yaml
└── values.yaml

1 directory, 18 files
```

```bash
# 参考文件
$ helm create rabbitmq-cluster
Creating rabbitmq-cluster
$ tree rabbitmq-cluster/
rabbitmq-cluster/
├── charts                        # 依赖文件
├── Chart.yaml                    # 这个chart的版本信息
├── templates                     # 模板
│   ├── deployment.yaml
│   ├── _helpers.tpl              # 自定义的模板或者函数
│   ├── hpa.yaml
│   ├── ingress.yaml
│   ├── NOTES.txt                 # 这个chart的信息
│   ├── serviceaccount.yaml
│   ├── service.yaml
│   └── tests
│       └── test-connection.yaml
└── values.yaml                   # 配置全局变量或者一些参数

3 directories, 10 files
```

**创建 Namespace**

helm 指定 namespaces，如果没有 namespaces 空间，就会报错，需要提前创建

```bash
$ kubectl create ns rabbitmq-cluster
```

镜像配置方面，可以修改 values.yaml

```yaml
image:
  repository: rabbitmq
  tag: 3.8.14-management-alpine   # 修改镜像版本
  pullPolicy: IfNotPresent
  ## Optionally specify an array of imagePullSecrets.
  ## Secrets must be manually created in the namespace.
  ## ref: https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/
  ##
  # pullSecrets:
  #   - myRegistrKeySecretName
```

```bash
$ helm install rabbitmq --namespace  rabbitmq-cluster --set ingress.enabled=true,ingress.hostName=rabbitmq.smart.net --set rabbitmqUsername=smart,rabbitmqPassword=smart,managementPassword=intell,rabbitmqErlangCookie=secretcookie .
NAME: rabbitmq
LAST DEPLOYED: Fri Apr 30 15:13:51 2021
NAMESPACE: rabbitmq-cluster
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
** Please be patient while the chart is being deployed **

  Credentials:

    Username            : smart
    Password            : $(kubectl get secret --namespace rabbitmq-cluster rabbitmq-rabbitmq-ha -o jsonpath="{.data.rabbitmq-password}" | base64 --decode)
    Management username : management
    Management password : $(kubectl get secret --namespace rabbitmq-cluster rabbitmq-rabbitmq-ha -o jsonpath="{.data.rabbitmq-management-password}" | base64 --decode)
    ErLang Cookie       : $(kubectl get secret --namespace rabbitmq-cluster rabbitmq-rabbitmq-ha -o jsonpath="{.data.rabbitmq-erlang-cookie}" | base64 --decode)

  RabbitMQ can be accessed within the cluster on port 5672 at rabbitmq-rabbitmq-ha.rabbitmq-cluster.svc.cluster.local

  To access the cluster externally execute the following commands:

    export POD_NAME=$(kubectl get pods --namespace rabbitmq-cluster -l "app=rabbitmq-ha" -o jsonpath="{.items[0].metadata.name}")
    kubectl port-forward $POD_NAME --namespace rabbitmq-cluster 5672:5672 15672:15672

  To Access the RabbitMQ AMQP port:

    amqp://127.0.0.1:5672/ 

  To Access the RabbitMQ Management interface:

    URL : http://127.0.0.1:15672
```

**查看集群状态**

```bash
$ kubectl get svc,pod,ingress -n rabbitmq-cluster
NAME                                     TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)                       AGE
service/rabbitmq-rabbitmq-ha             ClusterIP   None         <none>        15672/TCP,5672/TCP,4369/TCP   82s
service/rabbitmq-rabbitmq-ha-discovery   ClusterIP   None         <none>        15672/TCP,5672/TCP,4369/TCP   82s

NAME                         READY   STATUS    RESTARTS   AGE
pod/rabbitmq-rabbitmq-ha-0   1/1     Running   0          82s
pod/rabbitmq-rabbitmq-ha-1   1/1     Running   0          56s
pod/rabbitmq-rabbitmq-ha-2   1/1     Running   0          31s

NAME                                             CLASS    HOSTS                ADDRESS         PORTS   AGE
ingress.networking.k8s.io/rabbitmq-rabbitmq-ha   <none>   rabbitmq.smart.net   10.106.105.44   80      82s

$ helm list  -n rabbitmq-cluster
NAME    	NAMESPACE       	REVISION	UPDATED                                	STATUS  	CHART             	APP VERSION
rabbitmq	rabbitmq-cluster	1       	2021-04-30 15:43:54.838712305 +0800 CST	deployed	rabbitmq-ha-1.33.0	3.7.15
$ helm status rabbitmq -n rabbitmq-cluster
# 状态信息为安装成功打印的信息
```

**删除集群**

```bash
$ helm uninstall rabbitmq -n rabbitmq-cluster
```

**补充**

```bash
Usage:
  helm install [NAME] [CHART] [flags]
$ helm install rabbitmq --dry-run .
# 模拟运行

Usage:
  helm uninstall RELEASE_NAME [...] [flags]
$ helm  uninstall rabbitmq -n rabbitmq-cluster --keep-history
# 卸载保留历史记录
```