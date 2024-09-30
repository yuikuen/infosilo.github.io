> QNAP Container Station 修改 Docker 镜像源

QNAP 市场中下载的 qpkg 应用，其环境变量就是自己的包环境中，如需要修改系统应用中的配置，则需要修改 qpkg 应用中对应的配置。即 `/share/CACHEDEV1_DATA/.qpkg/{app-name}` 中的配置

**修改 Container-Station 的 Docker 配置**

注意 QNAP 并不是常用的 Linux 系统，并无 `/etc/docker/daemon.json` 文件，在 qpkg 的 `container-station` 对应的则是 `/share/CACHEDEV1_DATA/.qpkg/container-station/etc/docker.json`，在 json 文件中添加镜像配置，如：

```json
// 在首个{下添加
{
    "registry-mirrors": [
        "https://dockerpull.com",
        "https://docker.anyhub.us.kg",
        "https://dockerhub.jobcher.com",
        "https://eihzr0te.mirror.aliyuncs.com"
    ],
...
}
```

PS：注意 Json 格式，可自行使用工具进行校验

重启 `Container-Station` 服务使其生效

> 请使用管理员或拥有 sudo 权限用户执行

```sh
$ sudo /etc/init.d/container-station.sh restart
$ docker pull vaultwarden/server:1.32.0-alpine
1.32.0-alpine: Pulling from vaultwarden/server
c6a83fedfae6: Pull complete 
e95985c9be87: Pull complete 
5d049aa48d1f: Pull complete 
471e47897d3d: Pull complete 
2c77ff5fe7ca: Pull complete 
Digest: sha256:e3efdc8a9961643f5f0d2c72596aedfe4b4fcfce9836e18c1e8ba0b8c2e06459
Status: Downloaded newer image for vaultwarden/server:1.32.0-alpine
docker.io/vaultwarden/server:1.32.0-alpine
```
