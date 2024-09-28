> Compose 部署 Harbor-Offline v2.7.1

!!! Tip "注意版本"
    Harbor 从 v2.8.0 开始废弃 Notary & Chartmusuem

1）安装 Docker-CE & Docker-Compose

2）下载软件包并解压至指定目录下，根据各自需求下载对应版本 [Harbor-releases](https://github.com/goharbor/harbor/releases)

```sh
$ wget https://github.com/goharbor/harbor/releases/download/v2.7.1/harbor-offline-installer-v2.7.1.tgz
$ tar -xf harbor-offline-installer-v2.7.1.tgz -C /opt/cicd && cd /opt/cicd/harbor
```
