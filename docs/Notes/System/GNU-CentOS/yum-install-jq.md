## 一. 安装说明

JSON 是一种轻量级的数据交换格式。其采用完全独立于语言的文本格式，具有方便人阅读和编写，同时也易于机器的解析和生成。这些特性决定了 JSON 格式越来越广泛的应用于现代的各种系统中。作为系统管理员，在日常的工作中无论是编辑配置文件或者通过 http 请求查询信息，我们都不可避免的要处理 JSON 格式的数据。

jq 是一款命令行下处理 JSON 数据的工具。其可以接受标准输入，命令管道或者文件中的 JSON 数据，经过一系列的过滤器(filters)和表达式的转后形成我们需要的数据结构并将结果输出到标准输出中。jq 的这种特性使我们可以很容易地在 Shell 脚本中调用它。

## 二. 安装 JQ

1）添加 epel 源

```sh
$ wget http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
$ rpm -ivh epel-release-latest-7.noarch.rpm
$ yum repolist
```

2）安装 JQ

```sh
$ yum install jq
```