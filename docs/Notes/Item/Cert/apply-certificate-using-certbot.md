[Let’s Encrypt](https://letsencrypt.org/zh-cn/) 是免费、开放和自动化的证书颁发机构，由非盈利组织互联网安全研究小组（ISRG）运营。Let’s Encrypt 支持 ACME 协议，可以自动化的完成SSL证书的申请、更新、吊销等操作，并且可以免费从 Let’s Encrypt 申请到有效期 90天的 SSL 证书

**环境说明**

- 网络服务：国外 VPS + NameSilo 域名
- 系统服务：Ubuntu + Certbot

## 一. Certbot 安装

安装方法可参考 [官方指引](https://certbot.eff.org/instructions)，目前官方推荐使用 [Snap](https://eff-certbot.readthedocs.io/en/stable/install.html#installation)

根据指引选择 Web 和 System 后，会有 `default` 和 `wildcard`，其 `wildcard` 方式需要域名服务商有相应的 `Certbot DNS` 插件，本文以 `default` 进行说明

1）安装 Snap

```sh
# 删除旧版本
$ sudo apt-get remove certbot

# 确保安装最新版本
$ sudo apt update
$ sudo snap install core; sudo snap refresh coresudo

# 测试Snap是否正常
$ sudo snap install hello-world
hello-world 6.4 from Canonical✓ installed
$ hello-world
Hello World!
```

2）使用 Snap 安装 Certbot

```sh
$ sudo snap install --classic certbot
certbot 2.6.0 from Certbot Project (certbot-eff✓) installed
$ sudo ln -s /snap/bin/certbot /usr/bin/certbot
```

## 二. 证书管理

### 2.1 申请证书

1）**注册账号**：使用前注册账号，否则第一次交互式使用时会提示输入邮箱来注册

```sh
$ sudo certbot register -m yuikuen.yuen@mail.com --agree-tos
```

2）生成证书并指定程序模块

```sh
# 示例：sudo certbot certonly --apache -d 你的域名,也可以有多个域名 -d 或者多次 -d 指定
$ sudo certbot certonly --nginx -d blog.info-silo.com --nginx-ctl /opt/nginx/sbin/nginx --nginx-server-root /opt/nginx/conf
Saving debug log to /var/log/letsencrypt/letsencrypt.log
Requesting a certificate for blog.info-silo.com

Successfully received certificate.
# [这里告诉我们生成的文件路径和有效期]
Certificate is saved at: /etc/letsencrypt/live/blog.info-silo.com/fullchain.pem
Key is saved at:         /etc/letsencrypt/live/blog.info-silo.com/privkey.pem
This certificate expires on 2023-09-12.
These files will be updated when the certificate renews.
Certbot has set up a scheduled task to automatically renew this certificate in the background.

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
If you like Certbot, please consider supporting our work by:
 * Donating to ISRG / Let's Encrypt:   https://letsencrypt.org/donate
 * Donating to EFF:                    https://eff.org/donate-le
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
```

注意：此certonly操作只是根据 `Apache/Nginx` 程序配置下载对应文件，非配置 `Apache/Nginx`，另外 `ssl_module` 模块需要确保安装，详细问题可查看下述

```sh
# ssl_module模块开启
$ nginx -V
nginx version: nginx/1.24.0
built by gcc 11.3.0 (Ubuntu 11.3.0-1ubuntu1~22.04.1) 
built with OpenSSL 3.0.2 15 Mar 2022
TLS SNI support enabled
configure arguments: --prefix=/opt/nginx --user=yuen --group=yuen --with-http_gzip_static_module --with-http_gunzip_module --with-http_ssl_module --with-http_stub_status_module --with-http_realip_module

# 另外说明：因我的Nginx安装目录非默认目录，导致生成失败
$ sudo certbot certonly --nginx -d blog.info-silo.com
Saving debug log to /var/log/letsencrypt/letsencrypt.log
Error while running nginx -c /etc/nginx/nginx.conf -t.

nginx: [emerg] open() "/etc/nginx/nginx.conf" failed (2: No such file or directory)
nginx: configuration file /etc/nginx/nginx.conf test failed

The nginx plugin is not working; there may be problems with your existing configuration.
The error was: MisconfigurationError('Error while running nginx -c /etc/nginx/nginx.conf -t.\n\nnginx: [emerg] open() "/etc/nginx/nginx.conf" failed (2: No such file or directory)\nnginx: configuration file /etc/nginx/nginx.conf test failed\n')
```

**附加说明**：如未提前注册，那生成步骤如下示例

```sh
$ certbot certonly --nginx --nginx-ctl /usr/local/nginx/sbin/nginx --nginx-server-root /usr/local/nginx/conf
Saving debug log to /var/log/letsencrypt/letsencrypt.log
Enter email address (used for urgent renewal and security notices)
 (Enter 'c' to cancel): [这里输入你的邮箱]

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Please read the Terms of Service at
https://letsencrypt.org/documents/LE-SA-v1.3-September-21-2022.pdf. You must
agree in order to register with the ACME server. Do you agree?
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
(Y)es/(N)o: Y

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Would you be willing, once your first certificate is successfully issued, to
share your email address with the Electronic Frontier Foundation, a founding
partner of the Let's Encrypt project and the non-profit organization that
develops Certbot? We'd like to send you email about our work encrypting the web,
EFF news, campaigns, and ways to support digital freedom.
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
(Y)es/(N)o: Y [选Y 继续]
Account registered.

Which names would you like to activate HTTPS for?
We recommend selecting either all domains, or all domains in a VirtualHost/server block.
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
1: blog.info-silo.com
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Select the appropriate numbers separated by commas and/or spaces, or leave input
blank to select all options shown (Enter 'c' to cancel):  [这里不需要输入，回车选所有]
Requesting a certificate for blog.info-silo.com

Successfully received certificate.
Certificate is saved at: 
# [这里告诉我们生成的文件路径和有效期]
/etc/letsencrypt/live/blog.info-silo.com/fullchain.pem
Key is saved at:         /etc/letsencrypt/live/blog.info-silo.com/privkey.pem
This certificate expires on 2023-03-02.
These files will be updated when the certificate renews.
Certbot has set up a scheduled task to automatically renew this certificate in the background.

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
If you like Certbot, please consider supporting our work by:
 * Donating to ISRG / Let's Encrypt:   https://letsencrypt.org/donate
 * Donating to EFF:                    https://eff.org/donate-le
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
```

### 2.2 更新证书

可以把此做成定时任务，实现证书的自动更新

```sh
$ sudo certbot renew

# 更新测试
$ sudo certbot renew --dry-run
Saving debug log to /var/log/letsencrypt/letsencrypt.log

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Processing /etc/letsencrypt/renewal/blog.info-silo.com.conf
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Account registered.
Simulating renewal of an existing certificate for blog.info-silo.com

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Congratulations, all simulated renewals succeeded: 
  /etc/letsencrypt/live/blog.info-silo.com/fullchain.pem (success)
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
```

**注意**：这只会更新证书，而不会重启 Web 服务使证书生效，需要重启或使用 `Certbot install` 命令安装证书以间接重启 Web 服务

### 2.3 吊销证书

```sh
$ sudo certbot revoke --cert-name 你的域名
```

## 三. Nginx 配置

```sh
#server {
#    listen 80;
#    server_name blog.info-silo.com;
#    return 301 https://$server_name$request_uri;
#}
server {
    listen 80;
    listen 443 ssl;
    server_name blog.info-silo.com;
    # 310 跳转HTTP流量到HTTPS
    if ($scheme = http) {
            return 301 https://$server_name$request_uri;
    }

    ssl_certificate     /etc/letsencrypt/live/blog.info-silo.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/blog.info-silo.com/privkey.pem;

    ssl_session_timeout 5m;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:HIGH:!aNULL:!MD5:!RC4:!DHE;
    ssl_prefer_server_ciphers on;

    client_max_body_size 1024m;
    # HSTS 证书缓存，务必确认能正常访问后再开启 (15768000 seconds = 6 months)
    add_header Strict-Transport-Security "max-age=15768000; includeSubDomains; preload" always;

    location / {
        root /opt/myblog/public;
        index index.html index.htm;
        #proxy_pass http://127.0.0.1;
        proxy_set_header Host $host:443;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Via "nginx";
    }
}
```

## 四. 自动续签

```sh
$ cat auto_certbot.sh 
#!/bin/bash

sudo certbot renew
/opt/nginx/sbin/nginx -s reload
```

```sh
$ crontab -l
# Edit this file to introduce tasks to be run by cron.
...
# m h  dom mon dow   command
# 0 0 11 9,12,3,6 * 第三个月执行一次
0 0 11 9,12,3,6 * /bin/bash -x /opt/shell/auto_certbot.sh > /dev/null 2>&1
```

**参考链接**

- [Let’s Encrypt SSL 证书的申请与使用](https://blog.csdn.net/doushi/article/details/128762885)
- [最新版 Let’s Encrypt免费证书申请步骤，保姆级教程](https://blog.csdn.net/w_monster/article/details/128191273)
- [免费 Let's Encrypt 证书申请、部署全攻略与自动续期教程](https://cloud.tencent.com/developer/article/2203944)