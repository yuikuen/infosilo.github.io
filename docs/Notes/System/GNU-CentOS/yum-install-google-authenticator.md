> **场景**：一般服务器远程 ssh 都是采用明文密码或密钥的方式，而给服务器配置远程 ssh 登录的二次验证是一个非常必要的安全措施，即使知道了访问密码也无法登录机器。采用 Google Authenticator 作动态密钥做为二次验证，也解决了密钥无需常备身上的不便

**Google Authenticator** 是基于时间的动态密钥，其产生原理可以大概描述如下，服务器端和客户端都通过一段相同的key，加上当前时间，经过某种相同的算法产生动态密钥，**每30秒进行一次计算**。当进行登录时，如果输入的客户端的密钥和服务端当前维护的密钥一致则通过验证。

**想要进行成功验证，必须要同时满足两个条件**

- 服务端和手机端的key相同
- 服务端和手机端的时间要同步到分钟级别

## 一. 服务端

1）安装依赖

```bash
$ yum install -y epel-* mercurial autoconf automake libtool pam-devel
```

2）安装 Google Authenticator

```bash
$ yum list | grep authenticator
google-authenticator.x86_64              1.04-1.el7                    @epel 

$ yum install google-authenticator
```

3）配置 Google Authenticator

- 添加 google_authenticator 认证模块

```bash
$ find / -name 'pam_google_authenticator.so'
/usr/lib64/security/pam_google_authenticator.so
```

- sshd 添加 Google Authenticator 认证

```bash
$ vim /etc/pam.d/sshd
# 第一行添加
auth required pam_google_authenticator.so
# 一旦所有用户都有OATH-TOTP令牌，可以从此行中删除nullok ，以使MFA成为强制性
auth required pam_google_authenticator.so nullok
```

如果你希望没有开启两步验证的账号还可以登录，则在此文件后面添加 nullok

- sshd 添加 pam 认证

```bash
$ vim /etc/ssh/sshd_config
ChallengeResponseAuthentication yes
UsePAM yes
```

- 重启 SSH 服务

```bash
$ systemctl restart sshd.service
```

4）切到需要使用 Google 身份验证器的账号，执行命令并且需要确认几点信息

```bash
$ google-authenticator
#这里会有一个二维码，需要在手机上下载 googleauthenticator APP扫码绑定
#安卓 IOS手机都可以在应用商店搜索安装
...
Your new secret key is: XQ2WB526GLPJ7SI64Z3RZISOEE
Your verification code is 917990
Your emergency scratch codes are:
  42623319
  72314571
  14476695
  95764389
  38976136
```

- 是否配置基于时间的动态密钥，选择`y`，之后会出现超级大一个二维码，下面还会有一些小字

> Do you want authentication tokens to be time-based (y/n) y

- 是否将配置信息更新到自己家目录，选择`y`进行更新，这个文件里面就保存着上面的key信息，以防后续还有新的手机设备需要用到key

> Do you want me to update your "/root/.google_authenticator" file? (y/n) y

- 是否禁止同一密钥在30秒内被多次使用，如果想要更安全就选择`y`，如果想要更方便就选择`n`

> Do you want to disallow multiple uses of the same authentication
> token? This restricts you to one login about every 30s, but it increases
> your chances to notice or even prevent man-in-the-middle attacks (y/n) y

- 是否允许前8次和后8次的动态密钥也有效，如果客户端和手机端都是基于网络的时间同步，选择`n`提高安全性

> By default, a new token is generated every 30 seconds by the mobile app.
> In order to compensate for possible time-skew between the client and the server,
> we allow an extra token before and after the current time. This allows for a
> time skew of up to 30 seconds between authentication server and client. If you
> experience problems with poor time synchronization, you can increase the window
> from its default size of 3 permitted codes (one previous code, the current
> code, the next code) to 17 permitted codes (the 8 previous codes, the current
> code, and the 8 next codes). This will permit for a time skew of up to 4 minutes
> between client and server.
> Do you want to do so? (y/n) y

- 是否限制30秒内最多3次尝试，为了防止恶意试错，选择`y`

> If the computer that you are logging into isn't hardened against brute-force
> login attempts, you can enable rate-limiting for the authentication module.
> By default, this limits attackers to no more than 3 login attempts every 30s.
> Do you want to enable rate-limiting? (y/n) y

至此，服务端配置全部完毕，回到 root 重启服务

```bash
$ systemctl restart sshd
```

## 二. 手机端

手机端的配置就简单得多，打开 app，点击右下角的加号，选择密钥方式输入 `key(XQ2WB526GLPJ7SI64Z3RZISOEE)` 或直接扫描二维码

## 三. PC 端

正常 ssh 登陆服务器，不过输入完用户名以后在这里选择交互键盘，以 XShell 为例

- 这里是用的密码登录，如果是密钥验证的话这里会有点不同

![](https://img.17121203.xyz/i/2024/09/30/h25ng1-0.webp)

- 点击下一步就会要求你输入动态密钥(查看下手机，输入6位数密钥)，之后输入密码即可成功登录服务器

![](https://img.17121203.xyz/i/2024/09/30/h2iix9-0.webp)

![](https://img.17121203.xyz/i/2024/09/30/h2llj0-0.webp)

## 四. 疑难杂症

> 无法成功登录的一些常见问题，首先关于登录的一些报错都在 `/var/log/secure` 这个日志文件中，不管是什么场景登陆失败都可以先查看下失败日志，对症下药

- 时间不同步

建议安装时间同步服务器或者安装一个自动同步时间的软件(例如：chrony)

```bash
$ yum install -y chrony
$ systemctl enable --now chronyd
```