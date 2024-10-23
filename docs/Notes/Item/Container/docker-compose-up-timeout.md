> 解决 Docker-Compose 启动请求超时

使用 docker 运行一个中型的项目，包含 40多个微服务及相关的 docker。由于 `docker-compose up` 同时启动的服务过多，超过了请求 HTTP 限制的 60s 时间仍未全部成功启动起来，所以出现了超时错误

```sh
ERROR: An HTTP request took too long to complete. Retry with --verbose to obtain debug information.
If you encounter this issue regularly because of slow network conditions, consider setting COMPOSE_HTTP_TIMEOUT to a higher value (current value: 60).
```

**解决方案**

因请求时间默认为 60s，那就将 `COMPOSE_HTTP_TIMEOUT` 值调大，并转为环境变量

```sh
$ vim /etc/profile
export COMPOSE_HTTP_TIMEOUT=500
export DOCKER_CLIENT_TIMEOUT=500

$ source /etc/profile
```

最后重新执行 `docker-compose up` 即可
