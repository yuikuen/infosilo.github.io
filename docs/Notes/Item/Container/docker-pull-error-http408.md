> Docker 解决拉取镜像报 HTTP-408 错误

**问题描述**

在使用 Docker 下拉镜像时，出现解析错误，具体报错如下：

```sh
error parsing HTTP 408 response body: invalid character '<' looking for beginning of value: "<html><body><h1>408 Request Time-out</h1>\nYour browser didn't send a complete request in time.\n</body></html>\n"
Error response from daemon: error parsing HTTP 408 response body: invalid character '<' looking for beginning of value: "<html><body><h1>408 Request Time-out</h1>\nYour browser didn't send a complete request in time.\n</body></html>\n"
```

**问题分析**

该报错的主要问题是响应超时，排查处理方法：

1. 确保网络畅通，是否正常连接互联网；
2. 修改 `/etc/docker/daemon.json` 添加其他国内镜像仓库，因为官方的可能访问超时；
3. 命令行输入 `docker login`，登录自己的 docker hub 账号，因官方有限制镜像拉取次数；

```sh
$ docker login
Login with your Docker ID to push and pull images from Docker Hub. If you don't have a Docker ID, head over to https://hub.docker.com to create one.
Username: yuikuen
Password: 
WARNING! Your password will be stored unencrypted in /root/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store

Login Succeeded
$ docker pull nginx:1.24.0-alpine3.17-perl
1.24.0-alpine3.17-perl: Pulling from library/nginx
f56be85fc22e: Already exists 
81234aecc257: Pull complete 
bb5936af66b7: Pull complete 
f7c8639dc75e: Pull complete 
d0071b96733a: Pull complete 
b6b60f9051a8: Pull complete 
44286d6df869: Pull complete 
1e1af8824822: Pull complete 
Digest: sha256:5e8a746339fd48cf2219f728d3f45bce6f71b37156467ea181727d4b3f3a7258
Status: Downloaded newer image for nginx:1.24.0-alpine3.17-perl
docker.io/library/nginx:1.24.0-alpine3.17-perl
```
