!!! Tip
    Tachidesk 是一个免费的开源漫画阅读器服务器，通过安装扩展插件，订阅并聚合漫画源，独立的 Tachiyomi 兼容软件，实现多平台使用 Tachiyomi.

## 一. 简介

**Project 项目地址**

Suwayomi：<https://github.com/Suwayomi>

Tachiyomi：<https://github.com/tachiyomiorg>

**App 软件工具**

Tachimanga：<https://github.com/tachimanga>（Tachiyomi for iOS.）

Tachiyomi：<https://github.com/tachiyomiorg>（close.）

Mihon：<https://mihon.app>（Tachiyomi for Android.）

**Extension Repo 扩展插件**

Keiyoushi：<https://keiyoushi.github.io/extensions>

- Repo：<https://raw.githubusercontent.com/keiyoushi/extensions/repo/index.min.json>

Tachiyomi：<https://tachiyomi.org/extensions>

- Repo：<https://raw.githubusercontent.com/tachiyomiorg/extensions/repo/index.min.json>

Suwayomi：<https://github.com/Suwayomi/tachiyomi-extension>

- Repo：<https://raw.githubusercontent.com/everfio/tachiyomi-extensions/repo/index.min.json>

## 二. 安装

**项目地址**

项目采用 Docker-Compose & Tachidesk 快速部署，详细参数配置如下：

Tachidesk：<https://github.com/Suwayomi/docker-tachidesk>

FlareSolverr：<https://github.com/FlareSolverr/FlareSolverr>

Docker Releases：<https://github.com/suwayomi/docker-tachidesk/pkgs/container/tachidesk>

Docker compose：<https://github.com/Suwayomi/docker-tachidesk/blob/main/docker-compose.yml>

Dockerfile：<https://github.com/suwayomi/docker-tachidesk>

创建数据目录，授权读写权限

```sh
$ mkdir -p ./tachidesk/data
$ chmod -R 777 ./data
```

```yaml
version: '3.7'
services:
  suwayomi:
    image: ghcr.io/suwayomi/tachidesk:v1.1.1-r1586
    container_name: tachidesk
    restart: on-failure:3
    expose:
      - "4567"
    ports:
      - 4567:4567
    environment:
      - TZ=Asia/Shanghai
      - BIND_IP=0.0.0.0
      - BIND_PORT=4567
      # Downloader
      - DOWNLOAD_AS_CBZ=true
      - AUTO_DOWNLOAD_CHAPTERS=false # 自动检查新章节则自动下载
      - AUTO_DOWNLOAD_EXCLUDE_UNREAD=true # 忽略未读自动下载 
      # Auth
      - BASIC_AUTH_ENABLED=true
      - BASIC_AUTH_USERNAME=username
      - BASIC_AUTH_PASSWORD=password
      # Extension repos
      - EXTENSION_REPOS=["https://raw.githubusercontent.com/keiyoushi/extensions/repo", "https://raw.githubusercontent.com/tachiyomiorg/extensions/repo", "https://raw.githubusercontent.com/everfio/tachiyomi-extensions/repo"]
    volumes:
      - ./data:/home/suwayomi/.local/share/Tachidesk
  # 按需，可忽略
  flaresolverr:
    image: ghcr.io/flaresolverr/flaresolverr:v3.3.21
    container_name: flaresolverr
    restart: unless-stopped
    environment:
      - TZ=Asia/Shanghai
      - LOG_LEVEL=info
      - LOG_HTML=false
      - CAPTCHA_SOLVER=none
    ports:
      - 8191:8191
```
