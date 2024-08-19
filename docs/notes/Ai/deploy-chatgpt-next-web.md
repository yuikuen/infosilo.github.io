!!! Tip "实践场景"
    通过 ECS/VPS-SV(USA) 部署 NPM & ChatGPT-Next-Web

**操作步骤**

1. 安装 Docker & Docker-Compose
2. Compose 部署 NPM & ChatGPT-Next-Web
3. 配置 NPM+HTTPS 反代 ChatGPT-Next-Web

## 一. 服务部署

- OpenAPI-Key 获取，自行登录 https://platform.openai.com 获取
- ChatGPT-Next-Web 部署并容器服务仅暴露内部服务端口

示例1：单应用场景

```yaml
services:
  chatai:
    container_name: nextgpt
    image: yidadaa/chatgpt-next-web:v2.11.3
    restart: unless-stopped
    environment:
      - OPENAI_API_KEY=sk-key-01
      - CODE=Passwd01,Passwd02
      - HIDE_USER_API_KEY=1
      - ENABLE_BALANCE_QUERY=1
      - CUSTOM_MODELS=-all,+gpt-3.5-turbo,+gpt-3.5-turbo-0125,+gpt-4-turbo-preview,+gpt-4-0125-preview,+gpt-4-vision-preview
      - PORT=3000
    expose:
      - "3000"
    networks:
      - netgpt
  proxy:
    container_name: npm
    image: jc21/nginx-proxy-manager:2.11.1
    restart: unless-stopped
    ports:
      - '80:80'
      - '81:81'
      - '443:443'
    volumes:
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt
    links:
      - chatai
    depends_on:
      - chatai
    networks:
      - netgpt
networks:
  netgpt:
```

示例2：多应用场景

> 为了区分仅 3.5 和 4.0，创建多 App 应用，域名 1 仅能使用 3.5，域名 2 任意

```yaml
services:
  chatai3:
    container_name: chatai3
    image: st-chatai:v2.11.3
    restart: unless-stopped
    environment:
      - OPENAI_API_KEY=sk-key-01
      - CODE=Passwd01
      - HIDE_USER_API_KEY=1
      - DISABLE_GPT4=1
      - ENABLE_BALANCE_QUERY=1
      - CUSTOM_MODELS=-all,+gpt-3.5-turbo,+gpt-3.5-turbo-0125
      - PORT=3003
    expose:
      - "3003"
    networks:
      - netgpt

  chatai4:
    container_name: chatai4
    image: st-chatai:v2.11.3
    restart: unless-stopped
    environment:
      - OPENAI_API_KEY=sk-key-02
      - CODE=Passwd02
      - HIDE_USER_API_KEY=1
      - ENABLE_BALANCE_QUERY=1
      - CUSTOM_MODELS=-all,+gpt-3.5-turbo,+gpt-3.5-turbo-0125,+gpt-4-turbo-preview,+gpt-4-0125-preview,+gpt-4-vision-preview
      - PORT=3004
    expose:
      - "3004"
    networks:
      - netgpt

  proxy:
    container_name: npm
    image: jc21/nginx-proxy-manager:2.11.1
    restart: unless-stopped
    ports:
      - '80:80'
      - '81:81'
      - '443:443'
    volumes:
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt
    links:
      - chatai3
      - chatai4
    depends_on:
      - chatai3
      - chatai4
    networks:
      - netgpt

networks:
  netgpt:
```

## 二. 配置反代

```sh
npm 账号密码
域名：npm.example.com
账号：npm@mail.com
密码：NPM-UI_Passwd
3.5：35.example.com 密码：Passwd01
4.0：40.example.com 密码：Passwd02
```

配置 NPM，使用其通过 HTTPS 域名访问

!!! Warning "**注意事项**"
    因 NPM 会占用 80、81、443 的端口，所以本机不能占用；
    填写对应的域名、IP、Port，如 NPM 和 ChatGPT-Next-Web 是同一台服务器则填写 Docker 容器内部 IP，否则填写 ChatGPT-Next-Web 所在的服务器 IP;
    (因此处部署的 NPM 与 ChatGPT-Next-Web 是在同一服务器中，HostName 应填写容器服务 IP：`ip addr show docker0`)

![](https://img.17121203.xyz/i/2024/08/13/j4uwjg-0.webp)

![](https://img.17121203.xyz/i/2024/08/13/j50le0-0.webp)

![](https://img.17121203.xyz/i/2024/08/13/j54x0g-0.webp)

![](https://img.17121203.xyz/i/2024/08/13/j5gez2-0.webp)

通过上面的反代，虽然是成功代理了，但无法显示内容或报错，因为使用容器+仅暴露内部端口的方式，造成了内部跳转无法找到页面，所以需要在高级配置里添加 Nginx 反代参数

![](https://img.17121203.xyz/i/2024/08/13/j5m1j2-0.webp)

```conf
location / {
  # 将请求转发到指定的后端服务
  proxy_pass http://172.18.0.2:3000/;
  # 重写请求 URI，保持原有路径
  rewrite ^/(.*)$ /\$1 break;
  # 禁用 Nginx 的代理重定向
  proxy_redirect off;
  # 设置请求头，传递主机名
  proxy_set_header Host $host;
  # 设置请求头，传递请求协议（http 或 https）
  proxy_set_header X-Forwarded-Proto $scheme;
  # 设置请求头，传递真实的客户端 IP 地址
  proxy_set_header X-Real-IP $remote_addr;
  # 设置请求头，传递经过的 IP 地址链
  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  # 设置请求头，指示浏览器升级不安全请求
  proxy_set_header Upgrade-Insecure-Requests 1;
  # 强制设置 X-Forwarded-Proto 为 https（可以根据实际情况调整）
  proxy_set_header X-Forwarded-Proto https;
}
```

注：可使用 `docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' {CONTAINER ID}` 来获取指定容器的 IP

```conf
location / {
   # 将请求转发到指定的后端服务
   proxy_pass http://172.18.0.2:3000/;
   # 设置请求头，传递主机名
   proxy_set_header Host $http_host;
   # 将 HTTP 重定向转换为 HTTPS
   proxy_redirect http:// https://;
   # 设置请求头，传递原始主机名
   proxy_set_header X-Forwarded-Host $http_host;
   # 设置请求头，传递原始端口号
   proxy_set_header X-Forwarded-Port $server_port;
   # 设置请求头，传递请求协议（http 或 https）
   proxy_set_header X-Forwarded-Proto $scheme;
   # 设置请求头，传递请求协议（用于某些代理场景）
   proxy_set_header X-Forwarded-Scheme $scheme;
   # 设置请求头，传递真实的客户端 IP 地址
   proxy_set_header X-Real-IP $remote_addr;
   # 设置请求头，传递经过的 IP 地址链
   proxy_set_header X-Forwarded-For $remote_addr;
   # 设置请求头，传递升级请求的信息（用于 WebSocket 等）
   proxy_set_header Upgrade $http_upgrade;
   # 设置请求头，传递连接类型（如 Upgrade）
   proxy_set_header Connection $http_connection;
   # 设置 HTTP 版本为 1.1，确保支持长连接和其他特性
   proxy_http_version 1.1;   
}
```

## 三. 配置区别

> 下述测试内容由 ChatGPT-Ai 生成

这两段 Nginx 配置代码的原理相似，都是将客户端请求代理到后端服务，但它们在功能和效果上有一些关键的区别。下面是对这两段代码的比较和分析：

### 3.1 第一段代码

- **功能**: 主要用于将请求直接代理到后端服务（如应用服务器）。
- **请求处理**: 只处理请求的转发，设置了一些请求头以传递客户端信息。
- **重定向**: 不涉及 HTTP 到 HTTPS 的重定向。

### 3.2 第二段代码

- **功能**: 除了将请求代理到后端服务，还包括 HTTP 到 HTTPS 的重定向。
- **请求处理**: 除了设置请求头以传递客户端信息外，还确保了所有的 HTTP 请求都被重定向到 HTTPS。
- **重定向**: 明确处理了 HTTP 到 HTTPS 的重定向，这对于安全性非常重要。

### 3.3 主要区别

1. **重定向功能**:
   - 第一段代码没有处理 HTTP 到 HTTPS 的重定向。
   - 第二段代码通过 `proxy_redirect http:// https://;` 实现了 HTTP 到 HTTPS 的重定向。

2. **安全性**:
   - 第一段代码在处理 HTTP 请求时，可能会将请求以不安全的方式传递到后端。
   - 第二段代码确保所有请求都是通过 HTTPS 进行的，提高了安全性。

3. **请求头设置**:
   - 两段代码都设置了请求头，但第二段代码可能会更频繁地使用 HTTPS 相关的头信息（如 `X-Forwarded-Proto` 和 `X-Forwarded-Scheme`），以确保后端服务能够正确识别请求的协议。

### 3.4 生效效果

- **第一段代码**:
  - 对于不需要 HTTPS 的应用场景，可能足够，但在安全性上存在风险。
  
- **第二段代码**:
  - 提供了更高的安全性，适合处理敏感数据或需要保护用户隐私的应用。

### 3.5 总结

虽然两段代码的基本原理相似，都是通过 Nginx 进行请求代理，但第二段代码在安全性和请求处理上更为完善，适用于需要 HTTPS 的场景。选择哪段代码取决于你的应用需求和安全考虑。