> Docker Maven 插件简用说明

在持续集成过程中，项目工程一般使用 Maven 编译打包，然后生成镜像，通过镜像上线，能够大大提供上线效率，同时能够快速动态扩容，快速回滚等。[docker-maven-plugin](https://github.com/spotify/docker-maven-plugin) 插件就是为了在 Maven 工程中，通过简单的配置，自动生成镜像并推送到仓库中

## 一. Demon 示例

测试 Java Maven 项目用 docker-maven 插件打镜像，上传镜像等操作，需要先安装一下 Docker、Maven、Java 等等，这里忽略安装过程

- 配置 Docker_Host-[建议：开启 2376 端口启用 TLS 加密的方式进行]

docker-maven-plugin 插件默认连接本地 Docker 地址为：localhost:2375，所以需要先设置环境变量

注意：如果没有设置 DOCKER_HOST 环境变量，可以命令行显示指定 DOCKER_HOST 来执行，如我本机指定 DOCKER_HOST：`DOCKER_HOST=unix:///var/run/docker.sock mvn clean install docker:build`

- 构建镜像-可以使用两种方式，第一种是将构建信息指定到 POM 中，第二种是使用已存在的 Dockerfile 构建

第一种方式，支持将 `FROM, ENTRYPOINT, CMD, MAINTAINER` 以及 `ADD` 信息配置在 POM 中，不需要使用 Dockerfile 配置。但是如果使用 `VOLUME` 或其他 Dockerfile 中的命令的时候，需要使用第二种方式，创建一个 Dockerfile，并在 POM 中配置 `dockerDirectory` 来指定路径即可

1）指定构建信息到 Pom 中构建

```xml
<build>
    <plugins>
        <plugin>
            <groupId>com.spotify</groupId>
            <artifactId>docker-maven-plugin</artifactId>
            <version>1.0.0</version>
            <configuration>
                <imageName>mavendemo</imageName>
                <baseImage>java</baseImage>
                <maintainer>docker_maven docker_maven@email.com</maintainer>
                <workdir>/ROOT</workdir>
                <cmd>["java", "-version"]</cmd>
                <entryPoint>["java", "-jar", "${project.build.finalName}.jar"]</entryPoint>
                <!-- 这里是复制 jar 包到 docker 容器指定目录配置 -->
                <resources>
                    <resource>
                        <targetPath>/ROOT</targetPath>
                        <directory>${project.build.directory}</directory>
                        <include>${project.build.finalName}.jar</include>
                    </resource>
                </resources>
            </configuration>
        </plugin>
    </plugins>
```

2）使用 Dockerfile 构建

```xml
<build>
    <plugins>
         <plugin>
            <groupId>com.spotify</groupId>
            <artifactId>docker-maven-plugin</artifactId>
            <version>1.0.0</version>
            <configuration>
                <imageName>mavendemo</imageName>
                <dockerDirectory>${basedir}/docker</dockerDirectory> <!-- 指定 Dockerfile 路径-->
                <!-- 这里是复制 jar 包到 docker 容器指定目录配置，也可以写到 Docokerfile 中 -->
                <resources>
                    <resource>
                        <targetPath>/ROOT</targetPath>
                        <directory>${project.build.directory}</directory>
                        <include>${project.build.finalName}.jar</include>
                    </resource>
                </resources>
            </configuration>
        </plugin>   
    </plugins>
</build>
```

```dockerfile
${basedir}/docker/Dockerfile 配置

FROM java
MAINTAINER docker_maven docker_maven@email.com
WORKDIR /ROOT
CMD ["java", "-version"]
ENTRYPOINT ["java", "-jar", "${project.build.finalName}.jar"]
```

上两种方式执行`docker:build`效果是一样的，执行输出过程大致如下：

```sh
[INFO] --- docker-maven-plugin:1.0.0:build (default-cli) @ mavenDemo ---
[INFO] Building image mavendemo
Step 1/5 : FROM java
 ---> d23bdf5b1b1b
Step 2/5 : MAINTAINER docker_maven docker_maven@email.com
 ---> Using cache
 ---> 2faf180d4a50
Step 3/5 : WORKDIR /ROOT
 ---> Using cache
 ---> 862210f7956a
Step 4/5 : ENTRYPOINT java -jar mavenDemo.jar
 ---> Running in 96bbe83de6ec
 ---> c29009c88993
Removing intermediate container 96bbe83de6ec
Step 5/5 : CMD java -version
 ---> Running in f69b8d2a75b1
 ---> bc8d54014325
Removing intermediate container f69b8d2a75b1
Successfully built bc8d54014325
```

## 二. 执行命令

- `mvn clean package docker:build` 只执行 build 操作
- `mvn clean package docker:build -DpushImage` 执行 build 完成后 push 镜像
- `mvn clean package docker:build -DpushImageTag` 执行 build 并 push 指定 tag 的镜像

注意：这里必须指定至少一个 `imageTag`，它可以配置到 POM 中，也可以在命令行指定

命令行指定：`mvn clean package docker:build -DpushImageTags -DdockerImageTags=imageTag_1 -DdockerImageTags=imageTag_2`，POM 文件中指定配置如下：

```xml
<build>
  <plugins>
    ...
    <plugin>
      <configuration>
        ...
        <imageTags>
           <imageTag>imageTag_1</imageTag>
           <imageTag>imageTag_2</imageTag>
        </imageTags>
      </configuration>
    </plugin>
    ...
  </plugins>
</build>
```

**绑定 Docker 命令到 Maven 各个阶段**

绑定 Docker 命令到 Maven 各个阶段，可以把 Docker 分为 build、tag、push，然后分别绑定 Maven 的 package、deploy 阶段。此时，只需要执行 `mvn deploy` 就可以完成整个 build、tag、push 操作了，当执行 `mvn build` 就只完成 build、tag 操作。除此此外，当想跳过某些步骤或者只执行某个步骤时，不需要修改 POM 文件，只需要指定跳过 docker 某个步骤即可。比如当工程已经配置好了自动化模板了，但是这次只需要打镜像到本地自测，不想执行 push 阶段，那么此时执行要指定参数 `-DskipDockerPush` 就可跳过 push 操作了

```xml
<build>
    <plugins>
        <plugin>
            <groupId>com.spotify</groupId>
            <artifactId>docker-maven-plugin</artifactId>
            <version>1.0.0</version>
            <configuration>
                <imageName>mavendemo</imageName>
                <baseImage>java</baseImage>
                <maintainer>docker_maven docker_maven@email.com</maintainer>
                <workdir>/ROOT</workdir>
                <cmd>["java", "-version"]</cmd>
                <entryPoint>["java", "-jar", "${project.build.finalName}.jar"]</entryPoint>
                <resources>
                    <resource>
                        <targetPath>/ROOT</targetPath>
                        <directory>${project.build.directory}</directory>
                        <include>${project.build.finalName}.jar</include>
                    </resource>
                </resources>
            </configuration>
            <executions>
                <execution>
                    <id>build-image</id>
                    <phase>package</phase>
                    <goals>
                        <goal>build</goal>
                    </goals>
                </execution>
                <execution>
                    <id>tag-image</id>
                    <phase>package</phase>
                    <goals>
                        <goal>tag</goal>
                    </goals>
                    <configuration>
                        <image>mavendemo:latest</image>
                        <newName>docker.io/wanyang3/mavendemo:${project.version}</newName>
                    </configuration>
                </execution>
                <execution>
                    <id>push-image</id>
                    <phase>deploy</phase>
                    <goals>
                        <goal>push</goal>
                    </goals>
                    <configuration>
                        <imageName>docker.io/wanyang3/mavendemo:${project.version}</imageName>
                    </configuration>
                </execution>
            </executions>
        </plugin>
    </plugins>
</build>
```

以上示例，当我们执行 `mvn package` 时，执行 build、tag 操作，当执行 `mvn deploy` 时，执行build、tag、push 操作。如果我们想跳过 docker 某个过程时，只需要：

- `-DskipDockerBuild` 跳过 build 镜像
- `-DskipDockerTag` 跳过 tag 镜像
- `-DskipDockerPush` 跳过 push 镜像
- `-DskipDocker` 跳过整个阶段

例如：想执行 package 时，跳过 tag 过程，那么就需要 `mvn package -DskipDockerTag`

## 三. 私有仓库

实际工作环境中，需要 push 镜像到公司私有 Docker 仓库中，使用 `docker-maven-plugin` 插件也是很容易实现，有几种方式实现：

1）修改 POM 文件 imageName 操作

```xml
...
<configuration>
    <imageName>registry.example.com/spring/mavendemo:v1.0.0</imageName>
    ...
</configuration>
...
```

2）修改 POM 文件中 newName 操作

```xml
...
<configuration>
    <imageName>mavendemo</imageName>
    ...
</configuration>
<execution>
    <id>tag-image</id>
    <phase>package</phase>
    <goals>
        <goal>tag</goal>
    </goals>
    <configuration>
        <image>mavendemo</image>
        <newName>registry.example.com/wanyang3/mavendemo:v1.0.0</newName>
    </configuration>
</execution>
...
```

## 四. 安全认证

当 push 镜像到 Docker 仓库中时，不管是共有还是私有，经常会需要安全认证，登录完成之后才可以进行操作。当然，可以通过命令行 `docker login -u user_name -p password docker_registry_host` 登录，但是对于自动化流程来说，就不是很方便了。使用 docker-maven-plugin 插件可以很容易实现安全认证

1）首先在 Maven 的配置文件 setting.xml 中增加相关 server 配置，主要配置 Docker registry 用户认证信息

```xml
<servers>
  <server>
    <id>my-docker-registry</id>
    <username>test</username>
    <password>12345678</password>
    <configuration>
      <email>test@mail.com</email>
    </configuration>
  </server>
</servers>
```

然后只需要在 pom.xml 中使用 server id 即可

```xml
<plugin>
  <plugin>
    <groupId>com.spotify</groupId>
    <artifactId>docker-maven-plugin</artifactId>
    <version>1.0.0</version>
    <configuration>
      <imageName>registry.example.com/wanyang3/mavendemo:v1.0.0</imageName>
      ...
      <serverId>my-docker-registry</serverId>
    </configuration>
  </plugin>
</plugins>
```

## 五. 参数说明

docker-maven-plugin 插件还提供了很多很实用的配置

| 参数                                    | 说明                                                         | 默认值 |
| --------------------------------------- | ------------------------------------------------------------ | ------ |
| <forceTags>true</forceTags>             | build 时强制覆盖 tag，配合 imageTags 使用                    | false  |
| <noCache>true</noCache>                 | build 时，指定 –no-cache 不使用缓存                          | false  |
| <pullOnBuild>true</pullOnBuild>         | build 时，指定 –pull=true 每次都重新拉取基础镜像             | false  |
| <pushImage>true</pushImage>             | build 完成后 push 镜像                                       | false  |
| <pushImageTag>true</pushImageTag>       | build 完成后，push 指定 tag 的镜像，配合 imageTags 使用      | false  |
| <retryPushCount>5</retryPushCount>      | push 镜像失败，重试次数                                      | 5s     |
| <retryPushTimeout>10</retryPushTimeout> | push 镜像失败，重试时间                                      | 10s    |
| <rm>true</rm>                           | build 时，指定 –rm=true 即 build 完成后删除中间容器          | false  |
| <useGitCommitId>true</useGitCommitId>   | build 时，使用最近的 git commit id 前7位作为 tag，例如：image:b50b604，前提是不配置 newName | false  |

