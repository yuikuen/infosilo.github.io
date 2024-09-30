1）查看操作系统版本

```sh
$ cat /etc/redhat-release
CentOS Linux release 7.2.1511 (Core)
```

如直接执行 `yum update -y` 进行升级，系统默认升级至新版本

2）如不想升级内核及系统版本，则在执行前修改 `/etc/yum.conf` 中的配置

```sh
$ vim /etc/yum.conf
# 在[main]后面添加以下配置
[main]
exclude=kernel*
exclude=centos-release*
```

3）执行更新命令并再次验证

```sh
$ yum update -y 
$ cat /etc/redhat-release
CentOS Linux release 7.2.1511 (Core)
```

PS：`yum update` 与 `yum upgrade` 基本可以认为是等价的，都会同时升级软件和内核，不升级内核而只更新其他软件包也可使用 `yum -–exclude=kernel* update`
