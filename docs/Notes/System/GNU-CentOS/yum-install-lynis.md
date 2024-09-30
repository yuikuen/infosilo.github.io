> [Lynis](https://cisofy.com/lynis/) 是一款 Linux 系统的安全审计以及加固工具，能够进行深层次的安全扫描，其目的是检测潜在的时间并对未来的系统加固提供建议，扫描一般系统信息，脆弱软件包以及潜在的错误配置,执行全面的运行状况扫描，以支持系统强化和合规性测试

1）配置 **Lynis** 源，并安装

```bash
$ vim /etc/yum.repos.d/cisofy-lynis.repo
[lynis]
name=CISOfy Software - Lynis package
baseurl=https://packages.cisofy.com/community/lynis/rpm/
enabled=1
gpgkey=https://packages.cisofy.com/keys/cisofy-software-rpms-public.key
gpgcheck=1
priority=2

$ yum install lynis -y
$ lynis --version
3.0.7
```

2）**Lynis** 功能 & 命令

```bash
# 查看帮忙命令及显示可以使用的命令
$ lynis -h

$ lynis show commands
Commands:
lynis audit
lynis configure
lynis generate
lynis show
lynis update
lynis upload-only

# 审计配置文件，内有说明如何执行安全审计
$ lynis show profiles
/etc/lynis/default.prf

$ lynis show settings
```

![](https://img.17121203.xyz/i/2024/09/30/h6r8x6-0.webp)

3）执行安全审计，对系统执行基本安全审计，请运行以下命令：

```bash
$ lynis audit system
```

![](https://img.17121203.xyz/i/2024/09/30/h6vzai-0.webp)

执行此命令时，Lynis 会探测系统和软件配置是否存在任何潜在弱点或漏洞，然后将审计信息记录在 `/var/log/lynis.log` 文件中，并将审计报告存储在 `/var/log/lynis-report.dat` 文件中

4）执行系统检查的关键领域：

1. 引导文件
2. 软件包
3. 配置文件
4. 与日志记录和审计相关的目录

在系统审计过程中，你很可能会遇到不同的审计结果，关键字有 Found、OK、Not Found、Suggestion、Warning 等，应特别注意产生 `Warning` 的系统检查。应采取措施解决所描述的问题，因为这可能会破坏系统的安全性，在扫描结束时，将收到一份审计摘要，其中包括可以用来加强系统安全性的警告和建议。每条建议都会有一个 URL连接，里面记录着如何解决问题

5）查看特定审计的详细信息

每个系统检查都与一个唯一的测试 ID 相关联，例如，查看我们在摘要部分收到的警告和建议详细信息，请运行命令，其中 `SSH-7408` 是测试 ID

```bash
$ lynis show details SSH-7408

# 运行以下命令可以查看各种测试 ID
$ lynis show tests
```

![](https://img.17121203.xyz/i/2024/09/30/h78vg1-0.webp)