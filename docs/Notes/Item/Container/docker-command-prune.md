> Docker 命令 Prune

## 一. 概要说明

**无效 & 未使用镜像的产生和困惑**

1. 构建镜像过程中因为脚本错误导致很多镜像构建终止，产生很多 none 标签的版本
2. 手动构建镜像的时候没有进行提交，遗留来的垃圾镜像
3. 这些镜像占据较大的存储空间，需要删除

Docker 采用保守的方法来清理未使用的对象（通常称为“垃圾回收”），例如镜像、容器、卷和网络等；
除非明确要求 Docker 这样做，否则通常不会删除这些对象，这可能会导致 Docker 使用额外的磁盘空间。
对于每种类型的对象，Docker 都提供了一条 [prune](https://docs.docker.com/engine/reference/commandline/image_prune/) 命令。另外，可以使用 docker system prune 一次清理多种类型的对象。

## 二. 镜像清理

1）清理 none 镜像

> 默认情况下，只会清理没被标记且没被引用的镜像

```bash
$ docker images prune
WARNING! This will remove all dangling images.
Are you sure you want to continue? [y/N] y
Total reclaimed space: 0B
```

2）清理无容器使用的镜像

> 默认情况下，系统会提示是否继续，要绕过提示，请使用 `-f` 或 `--force` 标志
> 
> 可以使用 `--filter` 标志使用过滤表达式来限制修剪哪些镜像。例如，只考虑 24 小时前创建的镜像

```bash
$ docker image prune -a
# 默认情况下，系统会提示是否继续。要绕过提示，请使用 -f 或 --force 标志。
# 可以使用 --filter 标志使用过滤表达式来限制修剪哪些镜像。例如，只考虑 24 小时前创建的镜像
$ docker image prune -a --filter "until=24h"
```

## 三. 容器清理

> 停止容器后不会自动删除这个容器，除非在启动容器的时候指定了 `–rm` 标志
> 
> 一般停止状态的容器的可写层仍然占用磁盘空间。要清理掉这些，可以使用 `docker container prune` 命令

```bash
$ docker container prune
WARNING! This will remove all stopped containers.
Are you sure you want to continue? [y/N] y

$ docker container prune -a --filter "until=24h"
```

注：与镜像方式同理，容器清理也可使用过滤条件的方式

## 四. 网络清理

Docker 网络不会占用太多磁盘空间，但是它们会创建 iptables 规则，桥接网络设备和路由表条目。要清理这些东西，可以使用 docker network prune 来清理没有被容器未使用的网络

```bash
$ docker network prune
```

## 五. 定时清理

运行 `crontab -e` 命令编辑定时任务

```bash
$ crontab -e
$ 0 1 * * * docker image prune -a --force --filter "until=72h"
$ systemctl restart crond.service
```

上面的定时任务是每天夜里 1 点钟删除 3 天（72h）之前的 image。具体的操作时间和 image 保留时间，可根据实际的情况修改
