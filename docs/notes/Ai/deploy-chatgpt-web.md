> OpenAI API 是 OpenAI 提供的一种云端服务，允许开发人员使用 OpenAI 的人工智能模型，以便执行自然语言处理和代码生成等任务

## 一. 安装说明

**实验场景**：通过国外 VPS 部署 NPM & ChatGPT-Web，调用 OpenAI 的 API，实现多人使用 ChatGPT

**环境准备**：

- VPS 国外服务器一台，配置无特殊要求，但必须具有访问 ChatGPT 的线路
- 域名一个，无特殊要求，主要用于 NPM 申请 SSL 使用

**服务器参考**：(已经过验证，有条件的可择更优配置的服务器)

> 配置：程序运行需要至少 300MB 可用内存，推荐服务器配置至少需要 1GB 内存，单跑服务的话 512M 较为勉强使用

- RAKsmart：SV-1Core-1GB RAM-25G SSD,PremiumNetwork ExtendedVPS
- RAKsmart：SV-1Core-512M-VPS RAM-20G HDD,大陆优化

拥有服务器后，可通过如下脚本命令检查 IP 是否可用 ChatGPT

```sh
$ bash <(curl -Ls https://raw.githubusercontent.com/missuo/OpenAI-Checker/main/openai.sh)
```

PS：其实使用本地服务器进行部署 ChatGPT-Web，并将其使用 Socks 代理服务也是可以的。

**操作步骤**：搭建过程并不困难，只需要理解整个操作过程即可，其中实验是通过 NPM 作访问的接口，如不需要可直接单起 ChatGPT-Web 服务使用(步骤1 可参考 NPM 快速搭建，在此略过)

1. 部署 NPM 反向代理工具(Nginx Proxy Manager)
2. 获取 API-Key 并部署 ChatGPT-Web 服务
3. 配置 NPM+HTTPS 反代 ChatGPT-Web

## 二. 服务部署

1）根据开源项目 [ChatGPT-Web](https://github.com/Chanzhaoyu/chatgpt-web) 的示例文件进行编排

```yaml
version: '3'

services:
  app:
    image: chenzhaoyu94/chatgpt-web # 总是使用 latest ,更新时重新 pull 该 tag 镜像即可
    ports:
      - 127.0.0.1:3002:3002
    environment:
      # 二选一
      OPENAI_API_KEY: sk-xxx
      # 二选一
      OPENAI_ACCESS_TOKEN: xxx
      # API接口地址，可选，设置 OPENAI_API_KEY 时可用
      OPENAI_API_BASE_URL: xxx
      # API模型，可选，设置 OPENAI_API_KEY 时可用，https://platform.openai.com/docs/models
      # gpt-4, gpt-4-0314, gpt-4-32k, gpt-4-32k-0314, gpt-3.5-turbo, gpt-3.5-turbo-0301, text-davinci-003, text-davinci-002, code-davinci-002
      OPENAI_API_MODEL: xxx
      # 反向代理，可选
      API_REVERSE_PROXY: xxx
      # 访问权限密钥，可选
      AUTH_SECRET_KEY: xxx
      # 每小时最大请求次数，可选，默认无限
      MAX_REQUEST_PER_HOUR: 0
      # 超时，单位毫秒，可选
      TIMEOUT_MS: 60000
      # Socks代理，可选，和 SOCKS_PROXY_PORT 一起时生效
      SOCKS_PROXY_HOST: xxx
      # Socks代理端口，可选，和 SOCKS_PROXY_HOST 一起时生效
      SOCKS_PROXY_PORT: xxx
      # HTTPS 代理，可选，支持 http，https，socks5
      HTTPS_PROXY: http://xxx:7890
```

```yaml
version: '3'

services:
  app:
    image: chenzhaoyu94/chatgpt-web
    ports:
      - 3002:3002
    environment:
      # 参考示例，只需要填写Api-key和设置Auth密码即可
      OPENAI_API_KEY: sk-xxx
      AUTH_SECRET_KEY: xxx
```

OpenAI Api-Key 获取可自行登录 https://platform.openai.com 获取，然后启动后通过 IP:3002 来访问

2）配置 NPM，使其通过 HTTPS+域名方式来访问

> 再次申明：非必须项，其实上述操作已实现了 GPT 的访问

- 打开 NPM 后，选择 Proxy Hosts > Add Proxy Hosts > 颁发 SSL 证书并开启强制 HTTPS 访问

![](https://img.17121203.xyz/i/2024/08/19/n8ibdp-0.webp)

![](https://img.17121203.xyz/i/2024/08/19/naaon7-0.webp)

- 开启访问列表，Access Lists > 创建策略，并填写账密 > 添加 allow 访问权限

![](https://img.17121203.xyz/i/2024/08/19/najbid-0.webp)

![](https://img.17121203.xyz/i/2024/08/19/navvmt-0.webp)

大概效果如上图所示，另外如果想自定义界面的话则请自行修改项目代码构建打包

## 三. 参考内容

> 访问前提：科学上网

- OpenAI 登录界面：https://chat.openai.com/auth/login
- Api 介绍访文档：https://platform.openai.com
- Token 收费：https://openai.com/pricing
- Token 使用查询：https://platform.openai.com/account/usage
- 接码平台：https://sms-activate.org/cn

ChatGPT 注册及 Api-Key 创建流程：

1. 申请谷歌账号 https://accounts.google.com/v3/signin/identifier
2. 使用账号登录 [OpenAI ChatGPT](https://chat.openai.com/auth/login)
3. 使用 sms-activate 接码平台接收验证码信息

   > 根据市场汇率，现大概需要 2美元，充值后在左侧 OpenAI 菜单中选择一个国家，如巴西(花费 30卢布)，收到验证码后就行了，如不行则更换其他国家尝试

4. 成功登录后，访问 [OpenAI OverView](https://platform.openai.com/overview)，在个人 `View API keys` 中创建一个 `SECRET KEY`，这就是上述所说的 Api Key(可申请多个)

   > 申请后请复制下来保存好，后期都是隐藏的，忘记的话只能删除重新申请

关于 API 费用使用情况除了登录 [Pricing](https://openai.com/pricing) 的 FQA 收费小工具链接，评估相关 Token 花费

**附加内容**：修改项目基本信息，实现自定义

1）安装 nodejs 16

```sh
$ cd /usr/local
$ wget https://npmmirror.com/mirrors/node/v16.18.1/node-v16.18.1-linux-x64.tar.xz
$ tar -xvf node-v16.18.1-linux-x64.tar.xz
$ mv node-v16.18.1-linux-x64 nodejs
$ rm -rf node-v16.18.1-linux-x64.tar.xz
$ ln -s /usr/local/nodejs/bin/node /usr/bin
$ ln -s /usr/local/nodejs/bin/npm /usr/bin
$ ln -s /usr/local/nodejs/bin/npx /usr/bin

$ node -v
v16.18.1
```

2）安装 PNPM & Docker

```sh
$ npm install pnpm -g
```

3）下载项目，填写 OpenAI API

```sh
# service/.env 文件
# OpenAI API Key - https://platform.openai.com/overview
OPENAI_API_KEY=
# change this to an `accessToken` extracted from the ChatGPT site's `https://chat.openai.com/api/auth/session` response
OPENAI_ACCESS_TOKEN=
```

4）安装依赖，运行项目

```sh
$ pnpm install
$ pnpm bootstrap

$ docker build -t chatgpt-web .
$ docker run --name chatgpt-web -d -p 127.0.0.1:3002:3002 --env OPENAI_API_KEY=your_api_key chatgpt-web
# 运行地址
http://localhost:3002/
```

左下角个人信息修改，`./chatgpt-web/src/store/modules/user/helper.ts` 文件中的 `defaultSetting()` 

```sh
export function defaultSetting(): UserState {
  return {
    userInfo: {
      avatar: 'https://xxx',
      name: 'Yourname',
      description: '备注信息 <a href="https://xxx" class="text-blue-500" target="_blank" >echeverra</a>',
    },
  }
}
```

## 四. 更新内容

!!! info
    PS：Update-2023/05 VPS 到期重购并进行重建处理，将服务改成容器+不暴露端口方式

修改 yaml 编排文件，将 ChatGPT-Web 服务以容器启动，但端口不对外开放，而是用 NPM 调用容器间的端口访问

```yaml
version: '3.8'
services:
  npm:
    image: 'jc21/nginx-proxy-manager:latest'
    container_name: npm
    restart: unless-stopped
    links:
      - app
    depends_on:
      - app
    ports:
      # These ports are in format <host-port>:<container-port>
      - '80:80'   # Public HTTP Port
      - '443:443' # Public HTTPS Port
      - '81:81'   # Admin Web Port

    volumes:
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt 

  app:
    image: 'yuikuen/robot:gpt-web' # 按上述自定义后重新构建
    container_name: robot
    restart: unless-stopped
    expose:
      - "3002"
    # 测试服务器IP正常访问GPT后，改成不暴露端口
    #ports:
    #  - 3002:3002
    environment:
      OPENAI_API_KEY: sk-xxx
      # 访问权限密钥，可选
      AUTH_SECRET_KEY: xxx
      # 每小时最大请求次数，可选，默认无限
      MAX_REQUEST_PER_HOUR: 0
      # 超时，单位毫秒，可选
      TIMEOUT_MS: 60000
```

启动正常后，使用 NPM 申请 SSL 域名证书即可使用，如申请时出现 `Internal Error`，可参考以下设置

![](https://img.17121203.xyz/i/2024/08/19/o07o7y-0.webp)

![](https://img.17121203.xyz/i/2024/08/19/o0jpuh-0.webp)

另外使用 NPM 反代的时候经常会出现一些站点代理后会出现端口丢失（自动跳转到 80端口）、502错误，或者需要加路径才能访问

因为使用容器+不暴露端口的方式，造成了内部跳转无法找到页面，所以在高级配置里面添加一些 nginx 的参数

![](https://img.17121203.xyz/i/2024/08/19/o0nw6u-0.webp)

```sh
location / {
   proxy_pass http://172.22.0.2:3002/;                  # 需要代理的内网服务
   proxy_set_header Host $http_host;
   proxy_redirect  http:// https://;                    # http强制https
   proxy_set_header X-Forwarded-Host  $http_host;       # 携带主机头
   proxy_set_header X-Forwarded-Port  $server_port;     # 携带端口
   proxy_set_header X-Forwarded-Proto $scheme;
   proxy_set_header X-Forwarded-Scheme $scheme;
   proxy_set_header X-Real-IP         $remote_addr;
   proxy_set_header X-Forwarded-For   $remote_addr;
   proxy_set_header Upgrade    $http_upgrade;
   proxy_set_header Connection $http_connection;
   proxy_http_version 1.1;   
}
```