> 通过 Qnap-Nas & Docker-Compose 部署私有密码管理 Vaultwarden

Vaultwarden 其实是 Bitwarden 的第三方轻量版，使用 Bitwarden 为基础，采用 Rust 重写的轻量级 RS 版，功能与 Bitwarden 几乎一样。

![](https://img.17121203.xyz/i/2024/09/14/oxekjb-0.webp)

首先打开 Qnap-Nas 的文件管理器，创建一个数据目录

![](https://img.17121203.xyz/i/2024/09/14/p09fzy-0.webp)

可通过 WebUi 或直接打开 SSH 工具进行管理员模式，输入部署命令

```sh
$ cd /share/CACHEDEV2_DATA/Silo
$ mkdir -p Vaultwarden/vw_data
$ touch Vaultwarden/docker-compose.yml
$ cat !$
version: "3"
services:
  vaultwarden:
    image: vaultwarden/server:1.30.5-alpine
    container_name: vaultwarden
    restart: unless-stopped
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 2048M
        reservations:
          cpus: '0.25'
          memory: 1024M
    ports:
      - "10255:80"
    environment:
      - DOMAIN=https://vw.example.com
      - LOGIN_RATELIMIT_MAX_BURST=10
      - LOGIN_RATELIMIT_SECONDS=60
      - ADMIN_RATELIMIT_MAX_BURST=10
      - ADMIN_RATELIMIT_SECONDS=60
      - ADMIN_SESSION_LIFETIME=20
      - ADMIN_TOKEN=8vshhgPaC
      - SENDS_ALLOWED=true
      - SIGNUPS_ALLOWED=false
      - EMERGENCY_ACCESS_ALLOWED=true
      - WEB_VAULT_ENABLED=true
    volumes:
      - "/share/CACHEDEV2_DATA/Silo/Vaultwarden/vw_data:/data"
```

**变量说明**

```sh
environment:
  - DOMAIN=https://vw.domain.com:8443  # 与Vaultwarden关联的域名，反代非标准443端口 
  - LOGIN_RATELIMIT_MAX_BURST=10       # 登录/两步验证尝试中的最大请求次数
  - LOGIN_RATELIMIT_SECONDS=60         # 限制登录次数前，同一IP的登录请求间隔(秒)
  - ADMIN_RATELIMIT_MAX_BURST=5        # 同上，对于admin账户的请求次数限制
  - ADMIN_RATELIMIT_SECONDS=60         # 同上，对于admin账户限制请求间隔(秒)
  - ADMIN_SESSION_LIFETIME=20          # admin账户会话持续时间
  - ADMIN_TOKEN=8vshhgPaC              # 管理界面令牌，若不设置管理面板将被禁用，可使用`openssl rand -base64 48`输出
  - SERVER_ADMIN_EMAIL=example.com     # 邮箱
  - SENDS_ALLOWED=true                 # 控制是否允许用户创建Bitwarden sends
  - SIGNUPS_ALLOWED=true               # 控制新用户是否可以未受邀请注册，true/false
  - SIGNUPS_DOMAINS_WHITELIST=example.com,example.net,example.org # 即使上面设置为false，本条用户仍可注册(域名以,间隔)
  - EMERGENCY_ACCESS_ALLOWED=true      # 控制新用户是否可以启用紧急访问其账户的权限
  - WEB_VAULT_ENABLED=true             # 创建admin账户后建议修改为false，进行重建以防未授权访问
```

如无报错，可直接在浏览器中输入 `http://qnap-nas-ip:port` 查看登录界面

![](https://img.17121203.xyz/i/2024/09/14/p8tgjm-0.webp)

首次使用需要创建账户，按照要求创建账户之后，会发现创建失败，并弹出警告；此并不是部署的有问题，而是因安全方面，需要以更安全的 HTTPS 协议方可访问操作。

!!! Tip "反向代理"
    如使用家庭网，可自行映射端口，使用 `Nginx Proxy Manager` 或 `Lucky`

因自身 Nas 拥有公网及阿里云服务器，目前采用映射端口和阿里云通过 Certbot 自动续签 `SSL 泛证书` & 反向代理使用；

```yml
services:
  nginx:
    image: nginx:1.27.0-alpine3.19-perl
    container_name: proxy
    restart: always
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./conf.d:/etc/nginx/conf.d
      # certbot生成的证书路径
      - /opt/app/certbot:/etc/nginx/certs
      - ./log/nginx:/var/log/nginx
      - ./html:/usr/share/nginx/html:rw
    networks:
      - ngproxy
networks:
  ngproxy:
    external: true
    name: proxy_net
```

```sh
cat conf.d/vaultwarden.conf 
server {
    listen 443 ssl;
    server_name vw.example.com;

    ssl_certificate     /etc/nginx/certs/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/nginx/certs/live/example.com/privkey.pem;

    location / {
        proxy_pass http://ip:port;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_redirect off;
    }
}
```
