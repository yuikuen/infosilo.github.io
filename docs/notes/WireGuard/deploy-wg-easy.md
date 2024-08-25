> 通过 WireGuard Easy 快速部署 `WireGuard + Web UI`
> PS：具体参数说明及变动，请自行查阅项目

WireGuard Easy 项目地址：<https://github.com/wg-easy/wg-easy>

创建网络和 `PASSWORD_HASH`( WebUi 登录密码)

```sh
$ docker network create proxy_net
$ docker run ghcr.io/wg-easy/wg-easy:14 wgpw ${PASSWORD}
```

```yaml
services:
  wg-easy:
    image: ghcr.io/wg-easy/wg-easy:14
    container_name: relay
    restart: unless-stopped
    volumes:
      - './.wg-easy:/etc/wireguard'
    ports:
      - "51820:51820/udp"
      - "51821:51821/tcp"
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
    sysctls:
      - net.ipv4.ip_forward=1
      - net.ipv4.conf.all.src_valid_mark=1
    environment:
      - LANG=chs
      - PORT=51821
      - WG_PORT=51820
      - WG_HOST=<🚨YOUR_SERVER_IP>
      - PASSWORD_HASH=<🚨YOUR_ADMIN_PASSWORD_HASH>
      - WG_DEFAULT_ADDRESS=10.10.10.x
      - WG_DEFAULT_DNS=223.5.5.5
      - WG_ALLOWED_IPS=10.10.10.0/24
      - WG_PERSISTENT_KEEPALIVE=30
      - WG_MTU=1420
      - UI_TRAFFIC_STATS=true
      - UI_CHART_TYPE=2
    networks:
      - wgproxy
networks:
  wgproxy:
    external: true
    name: proxy_net
```

执行成功后，通过浏览器访问 `http://YOUR_SERVER_IP:51821` 进入 Web UI