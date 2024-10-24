> Docker ps 是用于查看服务器中容器状态(运行/暂停/停止)，及批量获取容器基本信息最常用的指令

## 一. 命令说明

语法：docker ps [OPTIONS] 

- `-a`：显示所有的容器，包括未运行的
- `-f`：根据条件过滤显示的内容
- `-l`：显示最近创建的容器
- `-n`：列出最近创建的n个容器
- `--no-trunc`：不截断输出
- `-q`：静默模式，只显示容器编号
- `-s`：显示总的文件大小

## 二. 状态说明

```sh
$ docker ps
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```

- `CONTAINER ID`：容器的唯一标识符号，自动生成，类似数据库中的主键
- `IMAGE`：创建容器使用的镜像名称
- `COMMAND`：运行容器时的命令
- `CREATED`：容器创建的时间
- `STATUS`：容器的运行状态
  - created（已创建）
  - restarting（重启中）
  - running（运行中）
  - removing（迁移中）
  - paused（暂停）
  - exited（停止）
  - dead（死亡）
- `PORTS`：容器开放的端口信息
- `NAMES`：容器的别名

## 三. 常用操作

| 常用命令                       | 解释                                                         |
| ------------------------------ | ------------------------------------------------------------ |
| docker ps -a                   | 列出当前服务器中所有的容器，无论是否在运行                   |
| docker ps -s                   | 列出各容器的文件大小（容器增加的大小/容器的虚拟大小）        |
| docker ps -q                   | 仅列出来 CONTAINER ID 字段                                   |
| docker ps -l                   | 显示最后一个运行的容器（无论该容器目前处于什么状态）         |
| docker ps -n x                 | x(数量)，显示最后 x 个运行的容器（无论该容器目前处于什么状态） |
| docker ps --no-trunc           | 不对输出进行截断操作，可以看到完整的 COMMAND ID              |
| docker ps -f                   | 使用过滤器来过滤输出                                         |
| docker ps --formart {{.Names}} | 以 go 的形式格式化输出列表                                   |

## 四. 实例演示

【示例一】批量停止所有容器

```sh
# 两个命令效果同理，都是批量操作
$ docker stop `docker ps -a -q`
$ docker stop $(docker ps -a | grep -v "CONTAINER" | awk '{print $1}')
```

【示例二】使用过滤器来过滤输出

`docker ps -f` 目前支持多个过滤器，具体如下：

- id（容器 id）
- label（容器标签）
- name（容器名称）
- exited （整数-容器退出状态码，只有在使用-all才有用）
- status 容器状态（created,restarting,running,paused,exited,dead）
- ancestor  过滤从指定镜像创建的容器
- before （容器的名称或id）,过滤在给定id或名称之后创建的容器
- isolation (default process hyperv) (windows daemon only)
- volume (数据卷名称或挂载点)，--过滤挂载有指定数据卷的容器
- network（网络id或名称），过滤连接到指定网络的容器

```sh
$ docker ps -f status=exited                              // 根据状态过滤
$ docker ps -f ancestor=597ce1600cf4 -f status=exited -a  // 过滤镜像名为597ce1600cf4的容器
$ docker ps -q -f name=xxx                                // 根据名称过滤得到容器编号
$ docker rm $(docker ps -q --filter status=created)       // 通过过滤并删除指定状态的容器
```

注意：ancestor 过滤镜像，如果制定的是某个父镜像，则过滤出的结果包含以此镜像构建的子镜像创建的容器，不仅仅是以该镜像直接创建的容器

【示例三】以 go 的形式格式化输出列表，常用 go 模板参数如下：

- `.ID`：容器的 ID
- `.Image`：镜像的 ID
- `.Command`  容器启动的命令
- `.CreatedAt` 创建容器的时间点
- `.RunngingFor` 从容器创建到现在过去的时间
- `.Ports` 暴露的端口
- `.Status` 容器的状态
- `.Size` 容器硬盘的大小
- `.Names` 容器的名称
- `.Label` 指定label的值
- `.Mounts` 挂载到这个容器的数据卷名称

```sh
# 输出容器名称&镜像
$ docker ps -a --format {{.Names}}---{{.Image}}

# 删除所有状态为exited的容器
$ docker rm 'docker ps -f status=exited --format {{.ID}}'
```
