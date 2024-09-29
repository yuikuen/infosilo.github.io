- [Sentinel 官网](https://sentinelguard.io/zh-cn/)
- [Sentinel 下载地址](https://github.com/alibaba/Sentinel/releases)

1）官方有提供下载地址，根据需要下载需要的版本，可参考 [官方 Wiki](https://github.com/alibaba/spring-cloud-alibaba/wiki/%E7%89%88%E6%9C%AC%E8%AF%B4%E6%98%8E)

```bash
$ mkdir /usr/local/sentinel/{bin,log}
$ wget https://github.com/alibaba/Sentinel/releases/download/1.8.1/sentinel-dashboard-1.8.1.jar
```

2）启动 Jar 包测试

```bash
$ java -jar sentinel-dashboard-1.8.1.jar

# 指定参数启动
$ java -Dserver.port=8282 -Dcsp.sentinel.dashboard.server=localhost:8282 -Dproject.name=sentinel-dashboard -jar sentinel-dashboard-1.8.1.jar
```

控制台启动配置项：

- `-Dserver.port=8080`：指定 Sentinel 控制台端口为 8080，可使用 -Dserver.port=新端口 进行设置
- `-Dcsp.sentinel.dashboard.server=localhost:8080`：指定控制台地址和端口，会自动向该地址发送心跳包。
- `-Dproject.name=sentinel-dashboard`：指定 Sentinel 控制台程序显示的名称
- `-Dcsp.sentinel.log.dir`：指定 Sentinel 日志文件目录，默认是：${user.home}/logs/csp/
- `-Dcsp.sentinel.api.port=xxxx`：本地的 Sentinel 客户端端口（可选，默认是 8719，有冲突会尝试向后探测）
  若启动多个应用，则需要通过 -Dcsp.sentinel.api.port=xxxx 指定客户端监控 API 的端口（默认是 8719）

用户可以通过如下参数进行鉴权配置：

- `-Dsentinel.dashboard.auth.username=sentinel` 用于指定控制台的登录用户名为 sentinel
- `-Dsentinel.dashboard.auth.password=123456` 用于指定控制台的登录密码为 123456；如省略则默认账密均为 sentinel
- `-Dserver.servlet.session.timeout=7200` 用于指定 Spring Boot 服务端 session 的过期时间，如 7200 表示 7200 秒；60m 表示 60 分钟，默认为 30 分钟；

3）配置开机自启

```bash
$ vim /usr/local/sentinel/bin/startup.sh
#!/bin/bash

nohup java -Dserver.port=8282 -Dcsp.sentinel.dashboard.server=localhost:8282 -Dproject.name=sentinel-dashboard -Dcsp.sentinel.log.dir=/usr/local/sentinel/log -jar /usr/local/sentinel/sentinel-dashboard-1.8.1.jar > /usr/local/sentinel/log/sentinel.log 2>&1 &
echo $! > /var/run/sentinel.pid

$ vim /usr/local/sentinel/bin/shutdown.sh
#!/bin/bash

kill -9 `cat /var/run/sentinel.pid`

$ chmod +x startup.sh shutdown.sh
```

```bash
$ vim /usr/lib/systemd/system/sentinel.service
[Unit]
Description=service for sentinel
After=syslog.target network.target remote-fs.target nss-lookup.target
     
[Service]
Type=forking
Environment="JAVA_HOME=/usr/local/java"
ExecStart=/usr/local/sentinel/bin/startup.sh
ExecStop=/usr/local/sentinel/bin/shutdown.sh
PrivateTmp=true
     
[Install]
WantedBy=multi-user.target

$ systemctl daemon-reload && systemctl enable --now sentinel
$ systemctl status sentinel
$ systemctl list-units --type=service
```