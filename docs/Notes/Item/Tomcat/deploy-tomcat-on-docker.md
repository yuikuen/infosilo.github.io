## 一. 快速部署

```sh
$ docker run -d \
 --name tomcat \
 --restart always \
 --privileged=true \
 -p 8080:8080 \
 -v /home/tomcat:/usr/local/tomcat/webapps \
 -v /etc/localtime:/etc/localtime \
 tomcat
```

进入程序目录，配置默认页

```sh
$ docker exec -it tomcat bash
$ cp -r webapps.dist/* ./webapps
```

## 二. 管理页面

- 如果想要进入 `/manager/html` 页面，则新建或编辑 `conf/Catalina/localhost/manager.xml`
- 如果想要进入 `/host-manager/html` 页面，则新建或编辑 `conf/Catalina/localhost/host-manager.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Context privileged="true" antiResourceLocking="false"
         docBase="${catalina.home}/webapps/manager">
    <Valve className="org.apache.catalina.valves.RemoteAddrValve" allow="^.*$" />
</Context>
```

首先，需要配置的配置文件是 `${catalina.home}/conf/tomcat-users.xml` 先给 Tomcat 访问相关的功能分配角色和配置登录验证用户密码，在最后的</tomcat-users>前面增加

```xml
<role rolename ="manager-gui"/>
<role rolename ="manager-status"/>
<role rolename ="manager-script"/>
<role rolename ="admin-gui"/>
<role rolename ="admin-script"/>
<user username ="manager" password ="manager" roles ="manager-gui,manager-status,manager-script,admin-gui,admin-script"/>
```
