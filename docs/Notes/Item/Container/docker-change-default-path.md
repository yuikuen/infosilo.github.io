> Docker 更换镜像容器默认路径
>
> 默认的镜像和容器存储位置在 `/var/lib/docker`，现磁盘已满，需要将其默认存储改至新盘路径

修改 `docker.service` 文件，添加新的路径

```sh
$ vim /etc/systemd/system/multi-user.target.wants/docker.service
[Service]
Type=notify
# the default is not to use systemd for cgroups because the delegate issues still
# exists and systemd currently does not support the cgroup feature set required
# for containers run by docker
ExecStart=/usr/bin/dockerd --graph=/home/docker -H tcp://0.0.0.0:2375 -H unix://var/run/docker.sock -H fd:// --containerd=/run/containerd/containerd.sock  # 在此增加 --graph=/home/docker 
ExecReload=/bin/kill -s HUP $MAINPID
ExecStartPost=/sbin/iptables -I FORWARD -s 0.0.0.0/0 -j ACCEPT
TimeoutSec=0
RestartSec=2
Restart=always
...
```

- --graph=/data/docker：docker新的存储位置
- --storage-driver=overlay ： 当前docker所使用的存储驱动

注：存储驱动貌似不改也会变成 overlay，重启并查看是否成功修改

```sh
$ systemctl daemon-reload
$ systemctl restart docker
$ docker info
```

