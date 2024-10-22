> Dockerfile 构建 Jenkins-BlueOcean

```dockerfile
# 参照官方示例进行补充修改
FROM jenkins/jenkins:2.426.2-jdk17

# 切换到 root 用户，以便安装依赖
USER root

# 设置 Jenkins 更新源为清华大学镜像源
ENV JENKINS_UC_DOWNLOAD https://mirrors.tuna.tsinghua.edu.cn/jenkins/
ENV JENKINS_UC https://mirrors.tuna.tsinghua.edu.cn/jenkins/updates

# 将 Debian 软件源替换为清华大学镜像源
RUN sed -i 's@http://deb.debian.org@https://mirrors.tuna.tsinghua.edu.cn@g' /etc/apt/sources.list.d/debian.sources

# 安装所需的依赖
RUN apt-get update && apt-get install -y lsb-release apt-transport-https ca-certificates

# 导入 Docker 的 GPG 密钥
RUN curl -fsSLo /usr/share/keyrings/docker-archive-keyring.asc \
  https://download.docker.com/linux/debian/gpg

# 添加 Docker 的软件源
RUN echo "deb [arch=$(dpkg --print-architecture) \
  signed-by=/usr/share/keyrings/docker-archive-keyring.asc] \
  https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list

# 安装 Docker CLI
RUN apt-get update && apt-get install -y docker-ce-cli

# 切换回 jenkins 用户，并安装所需的 Jenkins 插件
USER jenkins
RUN jenkins-plugin-cli --plugins "blueocean docker-workflow"
```