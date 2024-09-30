> CentOS7 实现 RAR 文件解压

**问题场景**：现有个解压包 `apache-maven-3.6.2-jars-20221202.rar` 在 CentOS7 中无法解压使用

```sh
$ yum install epel-release -y
$ yum install unar -y
# 带密码解压，空密码直接回车跳过
$ unar -p apache-maven-3.6.2-jars-20221202.rar
```