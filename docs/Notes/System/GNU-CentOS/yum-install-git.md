> CentOS7 安装最新版本 Git

1）确认当前版本，配置存储库，启用 Wandisco GIT 存储库，在此之前先写入 `Yum` 存储库配置文件

```sh
$ git version
git version 1.8.3.1

$ vim /etc/yum.repos.d/wandisco-git.repo
[wandisco-git]
name=Wandisco GIT Repository
baseurl=http://opensource.wandisco.com/centos/7/git/$basearch/
enabled=1
gpgcheck=1
gpgkey=http://opensource.wandisco.com/RPM-GPG-KEY-WANdisco
```

2）导入存储库 GPG 密钥并安装

```sh
$ rpm --import http://opensource.wandisco.com/RPM-GPG-KEY-WANdisco
$ yum install git -y
```

3）再次验证 Git 版本

```sh
$ git version
git version 2.31.1
```