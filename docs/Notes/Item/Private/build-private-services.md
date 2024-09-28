!!! bug
    因 CentOS7 已停止维护，故将系统改为 Rocky Linux 9.4 重构相关服务；
    本文记录为重构过程，通过 Aliyun-ECS 实现远程办公及站点搭建

服务器选用的是 2核2G/3M/40g，基本远程办公使用足于满足，如有需要可点击下链购买！！

![](https://img.17121203.xyz/i/2024/08/10/ppbm7k-0.webp)

【阿里云】云服务器经济型e实例/2核2G/3M/40g，新人专享渠道特惠价只要99元！特惠热卖中。 点击【 [立即购买](https://t.aliyun.com/U/rcJL2P) 】

![](https://img.17121203.xyz/i/2024/08/10/pr5ug1-0.webp)

【阿里云】云服务器u1-实例2核4G 80G，新人专享渠道特惠价只要199元！特惠热卖中。 点击【 [立即购买](https://t.aliyun.com/U/BlaDcm) 】

## 一. 基本环境

### 1.1 创建用户

> 基于安全考虑，Rocky Linux 默认不提供 root 用户，故提前另起个人用户并删除 ECS 默认用户(ecs-user)

```sh
$ ssh user_name@ip
# 开启 root 用户
$ sudo passwd root
Changing password for user root.
New password:
Retype new password:
passwd: all authentication tokens updated successfully.
# 通过 root 创建新用户并删除默认用户
$ sudo useradd yuen
$ sudo passwd yuen
Changing password for user yuen.
New password:
Retype new password:
passwd: all authentication tokens updated successfully.
$ sudo useradd -m -s /bin/bash yuen
$ sudo userdel -r ecs-user
```

### 1.2 更改时区

> 在最新发布的公共镜像中，阿里云已把 RTC 时钟默认使用的 localtime 时间标准修改为 UTC 时间标准，且该类镜像的后续版本会保持 RTC 时钟使用 UTC 时间标准。

```sh
$ timedatectl status
               Local time: Sat 2024-08-03 11:13:10 CST
           Universal time: Sat 2024-08-03 03:13:10 UTC
                 RTC time: Sat 2024-08-03 03:13:10
                Time zone: Asia/Shanghai (CST, +0800)
System clock synchronized: yes
              NTP service: active
          RTC in local TZ: no
# 根据官方教程，默认时钟
$ timedatectl set-local-rtc 1
$ timedatectl status
               Local time: Sat 2024-08-03 11:20:41 CST
           Universal time: Sat 2024-08-03 03:20:41 UTC
                 RTC time: Sat 2024-08-03 11:20:41
                Time zone: Asia/Shanghai (CST, +0800)
System clock synchronized: yes
              NTP service: active
          RTC in local TZ: yes

Warning: The system is configured to read the RTC time in the local time zone.
         This mode cannot be fully supported. It will create various problems
         with time zone changes and daylight saving time adjustments. The RTC
         time is never updated, it relies on external facilities to maintain it.
         If at all possible, use RTC in UTC by calling
         'timedatectl set-local-rtc 0'.          
```

### 1.3 验证方式

> 基于安全考虑，采用 RSA 密钥验证并关闭密码认证
> 
> PS：为了实现统一管理，都由私人笔电作为 Master 生成密钥，再将公钥发至不同 VPS

```sh
# 笔电操作
$ ssh-keygen -t rsa -b 4096 -C "example@mail.com"
$ ssh-copy-id -i ~/.ssh/id_rsa.pub -p 22 yuen@ip
$ ssh -p 22 yuen@ip
```

注意：此时登录还是采用密码验证方式，现还需要注释掉 `sshd_config` 的密码验证

```sh
$ vim /etc/ssh/sshd_config
# 修改端口、关闭密码验证、开启密钥验证、关闭 root 远登
Port 12123
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AllowUsers yuen
$ systemctl restart sshd
```

验证配置是否成功，如出现报错则需删除旧的 `known_hosts.*` 文件

```sh
$ ssh -p 12123 yuen@ip
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
IT IS POSSIBLE THAT SOMEONE IS DOING SOMETHING NASTY!
Someone could be eavesdropping on you right now (man-in-the-middle attack)!
It is also possible that a host key has just been changed.
The fingerprint for the ED25519 key sent by the remote host is
SHA256:f1GZxNhFT7Z5Zi3GMfXdpFWX8JK7jUIw3T8OgIW5Kr0.
Please contact your system administrator.
Add correct host key in /c/Users/yuiku/.ssh/known_hosts to get rid of this message.
Offending ECDSA key in /c/Users/yuiku/.ssh/known_hosts:16
Host key for [ip]:12123 has changed and you have requested strict checking.
Host key verification failed.
```

## 二. Docker & Compose

### 2.1 Install Docker

> 因使用的是 Aliyun Linux，已默认阿里云国内源，无需另作配置

```sh
$ sudo dnf update
$ sudo dnf install -y yum-utils device-mapper-persistent-data lvm2
$ sudo yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
$ sudo dnf install docker-ce docker-ce-cli containerd.io
$ sudo systemctl start docker;sudo systemctl enable docker
$ sudo docker --version
```

```json
$ cat >> /etc/docker/daemon.json << EOF
{
    "registry-mirrors": [
        "https://reg.xxxxxxxx.tech",
        "https://eihzr0te.mirror.aliyuncs.com",
        "https://dockerhub.mirrors.nwafu.edu.cn/",
        "https://mirror.ccs.tencentyun.com",
        "https://docker.mirrors.ustc.edu.cn/",
        "https://reg-mirror.qiniu.com",
        "http://hub-mirror.c.163.com/",
        "https://registry.docker-cn.com"
    ],
    "max-concurrent-downloads": 10,
    "max-concurrent-uploads": 5,
    "log-driver": "json-file",
    "log-opts": {
        "max-file": "3",
        "max-size": "500m"
    },
    "live-restore": true
}
EOF
$ sudo systemctl daemon-reload;systemctl restart docker
```

### 2.2 Install Compose

```sh
# GitHub：https://github.com/docker/compose/releases/latest
$ curl -L "https://github.com/docker/compose/releases/download/v2.28.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
$ chmod +x /usr/local/bin/docker-compose
$ docker-compose -v
```

## 三. 链接网盘

### 3.1 Install Rclone

> Rclone 是一个命令行工具，支持在不同对象存储、网盘间同步、上传、下载数据。

直接使用官方提供的 [一键安装脚本](https://rclone.org/install/#script-installation)

```sh
$ curl https://rclone.org/install.sh | suo bash
rclone v1.67.0 has successfully installed.
Now run "rclone config" for setup. Check https://rclone.org/docs/ for more details.
```

### 3.2 获取 Token

!!! Tip
    因 ECS/VPS 都没界面/浏览器，故采用笔电获取。
    
在本地 WinPC 上 [下载 Rclone](https://rclone.org/downloads/)，然后解压出来并重命名 `Rclone`，接着 `Win+R`--> `cmd`

```cmd
cd /d D:\Tools\Rclone

D:\Tools\Rclone>rclone authorize "onedrive"
2024/08/03 17:07:03 NOTICE: Config file "C:\\Users\\yuiku\\AppData\\Roaming\\rclone\\rclone.conf" not found - using defaults
2024/08/03 17:07:03 NOTICE: If your browser doesn't open automatically go to the following link: http://127.0.0.1:53682/auth?state=uNfcmurTI9lkSV_wPZ2YDQ
2024/08/03 17:07:03 NOTICE: Log in and authorize rclone for access
2024/08/03 17:07:03 NOTICE: Waiting for code...
2024/08/03 17:07:31 NOTICE: Got code
Paste the following into your remote machine --->
{"access_token":"key1","token_type":"Bearer","refresh_token":"M.C546_BAY.0.U.-key2","expiry":"2024-08-03T18:07:31.9097112+08:00"}
<---End paste
```

PS：注意 `Token` 是 `{...}` 内的所有内容，另如本地 WinPC 已绑定了 OneDrive 账户，则自动跳出授权窗体，如未提前绑定则提示下述选择

```cmd
Choose OneDrive account type?
 * Say b for a OneDrive business account
 * Say p for a personal OneDrive account
b) Business // 商业
p) Personal // 个人
```

### 3.3 配置 Rclone

回到 ECS/VPS 输入 `rclone config` 命令，会提示下述信息，参照下述进行操作

!!! Danger
    因版本更新，菜单选项可能有略微改动，但大致思路不会变，**勿无脑照搬操作**

```sh
$ rclone config
2024/08/03 17:29:50 NOTICE: Config file "/root/.config/rclone/rclone.conf" not found - using defaults
No remotes found, make a new one?
n) New remote
s) Set configuration password
q) Quit config
n/s/q> n # 选 n 新建配置

Enter name for new remote.
name> onedrive # 输入名称，类似于标签，用于区分不同网盘

Option Storage.
Type of storage to configure.
Choose a number from below, or type in your own value.
 1 / 1Fichier
   \ (fichier)
 2 / Akamai NetStorage
   \ (netstorage)
 3 / Alias for an existing remote
   \ (alias)
 4 / Amazon S3 Compliant Storage Providers including AWS, Alibaba, ArvanCloud, Ceph, ChinaMobile, Cloudflare, DigitalOcean, Dreamhost, GCS, HuaweiOBS, IBMCOS, IDrive, IONOS, LyveCloud, Leviia, Liara, Linode, Magalu, Minio, Netease, Petabox, RackCorp, Rclone, Scaleway, SeaweedFS, StackPath, Storj, Synology, TencentCOS, Wasabi, Qiniu and others
   \ (s3)
 5 / Backblaze B2
   \ (b2)
 6 / Better checksums for other remotes
   \ (hasher)
 7 / Box
   \ (box)
 8 / Cache a remote
   \ (cache)
 9 / Citrix Sharefile
   \ (sharefile)
10 / Combine several remotes into one
   \ (combine)
11 / Compress a remote
   \ (compress)
12 / Dropbox
   \ (dropbox)
13 / Encrypt/Decrypt a remote
   \ (crypt)
14 / Enterprise File Fabric
   \ (filefabric)
15 / FTP
   \ (ftp)
16 / Google Cloud Storage (this is not Google Drive)
   \ (google cloud storage)
17 / Google Drive
   \ (drive)
18 / Google Photos
   \ (google photos)
19 / HTTP
   \ (http)
20 / Hadoop distributed file system
   \ (hdfs)
21 / HiDrive
   \ (hidrive)
22 / ImageKit.io
   \ (imagekit)
23 / In memory object storage system.
   \ (memory)
24 / Internet Archive
   \ (internetarchive)
25 / Jottacloud
   \ (jottacloud)
26 / Koofr, Digi Storage and other Koofr-compatible storage providers
   \ (koofr)
27 / Linkbox
   \ (linkbox)
28 / Local Disk
   \ (local)
29 / Mail.ru Cloud
   \ (mailru)
30 / Mega
   \ (mega)
31 / Microsoft Azure Blob Storage
   \ (azureblob)
32 / Microsoft Azure Files
   \ (azurefiles)
33 / Microsoft OneDrive
   \ (onedrive)
34 / OpenDrive
   \ (opendrive)
35 / OpenStack Swift (Rackspace Cloud Files, Blomp Cloud Storage, Memset Memstore, OVH)
   \ (swift)
36 / Oracle Cloud Infrastructure Object Storage
   \ (oracleobjectstorage)
37 / Pcloud
   \ (pcloud)
38 / PikPak
   \ (pikpak)
39 / Proton Drive
   \ (protondrive)
40 / Put.io
   \ (putio)
41 / QingCloud Object Storage
   \ (qingstor)
42 / Quatrix by Maytech
   \ (quatrix)
43 / SMB / CIFS
   \ (smb)
44 / SSH/SFTP
   \ (sftp)
45 / Sia Decentralized Cloud
   \ (sia)
46 / Storj Decentralized Cloud Storage
   \ (storj)
47 / Sugarsync
   \ (sugarsync)
48 / Transparently chunk/split large files
   \ (chunker)
49 / Uloz.to
   \ (ulozto)
50 / Union merges the contents of several upstream fs
   \ (union)
51 / Uptobox
   \ (uptobox)
52 / WebDAV
   \ (webdav)
53 / Yandex Disk
   \ (yandex)
54 / Zoho
   \ (zoho)
55 / premiumize.me
   \ (premiumizeme)
56 / seafile
   \ (seafile)
Storage> 33 # 云存储列表,勿无脑操作,版本不一,序号则不同

Option client_id.
OAuth Client Id.
Leave blank normally.
Enter a value. Press Enter to leave empty.
client_id> # 留空,回车

Option client_secret.
OAuth Client Secret.
Leave blank normally.
Enter a value. Press Enter to leave empty.
client_secret> # 留空,回车

Option region.
Choose national cloud region for OneDrive.
Choose a number from below, or type in your own value of type string.
Press Enter for the default (global).
 1 / Microsoft Cloud Global
   \ (global) # 国际版
 2 / Microsoft Cloud for US Government
   \ (us)     # 美国版
 3 / Microsoft Cloud Germany
   \ (de)     # 德国版
 4 / Azure and Office 365 operated by Vnet Group in China
   \ (cn)     # 世纪互联
region> 1 # OneDrive 类型,选 1

Edit advanced config?
y) Yes
n) No (default)
y/n> n # 跳过高级设置

Use web browser to automatically authenticate rclone with remote?
 * Say Y if the machine running rclone has a web browser you can use
 * Say N if running rclone on a (remote) machine without web browser access
If not sure try Y. If Y failed, try N.

y) Yes (default)
n) No
y/n> n # 打开 OneDrive 网页给 Rclone 授权,ECS/VPS 无浏览器,改 WinPC 获取了,跳过

Option config_token.
For this to work, you will need rclone available on a machine that has
a web browser available.
For more help and alternate methods see: https://rclone.org/remote_setup/
Execute the following on the machine with the web browser (same rclone
version recommended):
        rclone authorize "onedrive"
Then paste the result.
Enter a value. # 之前 WinPC 操作生成的 token，注意是复制 {...} 整个内容
config_token> {"access_token":"key1","token_type":"Bearer","refresh_token":"M.C546_BAY.0.U.-key2","expiry":"2024-08-03T18:07:31.9097112+08:00"}

Option config_type.
Type of connection
Choose a number from below, or type in an existing value of type string.
Press Enter for the default (onedrive).
 1 / OneDrive Personal or Business
   \ (onedrive)
 2 / Root Sharepoint site
   \ (sharepoint)
   / Sharepoint site name or URL
 3 | E.g. mysite or https://contoso.sharepoint.com/sites/mysite
   \ (url)
 4 / Search for a Sharepoint site
   \ (search)
 5 / Type in driveID (advanced)
   \ (driveid)
 6 / Type in SiteID (advanced)
   \ (siteid)
   / Sharepoint server-relative path (advanced)
 7 | E.g. /teams/hr
   \ (path)
config_type> 1 # 选择类型，选 1

Option config_driveid.
Select drive you want to use
Choose a number from below, or type in your own value of type string.
Press Enter for the default (1502dda138452af2).
 1 /  (personal)
   \ (1502dda138452af2)
config_driveid> 1 # 程序找到网盘，此处编号是 1 则选择 1

Drive OK?

Found drive "root" of type "personal"
URL: https://onedrive.live.com/?cid=1502dda138452af2

y) Yes (default)
n) No
y/n> y # 选 y 确认

Configuration complete.
Options:
- type: onedrive
- token: {"access_token":"key1","token_type":"Bearer","refresh_token":"M.C546_BAY.0.U.-key2","expiry":"2024-08-03T18:07:31.9097112+08:00"}
- drive_id: 1502dda138452af2
- drive_type: personal
Keep this "onedrive" remote?
y) Yes this is OK (default)
e) Edit this remote
d) Delete this remote
y/e/d> y # 选 y 确定配置

Current remotes:

Name                 Type
====                 ====
onedrive             onedrive

e) Edit existing remote
n) New remote
d) Delete remote
r) Rename remote
c) Copy remote
s) Set configuration password
q) Quit config
e/n/d/r/c/s/q> q # 选 q 退出配置
```

至此，Rclone 已成功链接到了 OneDrive 网盘。根据上述操作已默认在 `/root/.config/rclone` 中生成一个 `rclone.conf` 文件，可通过如下命令查看，后续也可直接编辑该文件添加其它云盘，同理生效。

```sh
$ rclone config show
[onedrive]
type = onedrive
token = {"access_token":"key1","token_type":"Bearer","refresh_token":"M.C546_BAY.0.U.-key2","expiry":"2024-08-03T18:07:31.9097112+08:00"}
drive_id = 1502dda138452af2
drive_type = personal
```

### 3.4 挂载网盘

!!! Warning "**温馨提示**"
    挂载操作并不是必须的，作为一个实验性功能它有很多局限性和问题。挂载后并不能当做一个真正的磁盘来使用，在进行文件操作时会使用本地磁盘进行缓存，即占用本地磁盘空间。使用不当还可能造成磁盘写满、VPS卡死等问题。

    此处仅做演示，后期应用建议使用 Rclone 的原生命令功能，使用方法参见 [Rclone 官方文档](https://rclone.org/docs/)

```sh
# 示例：挂载
rclone mount <网盘名称:网盘路径> <本地路径> [参数] --daemon
rclone mount DriveName:Folder LocalFolder

$ mkdir /root/{onedrive,temp}
$ rclone mount onedrive:/ /opt/onedrive --cache-dir /opt/onedrive/temp  --vfs-cache-mode writes --copy-links --no-gzip-encoding --no-check-certificate --allow-other --allow-non-empty --umask 000 &
$ df -Th
Filesystem     Type         Size  Used Avail Use% Mounted on
devtmpfs       devtmpfs     4.0M     0  4.0M   0% /dev
tmpfs          tmpfs        839M     0  839M   0% /dev/shm
tmpfs          tmpfs        336M  4.8M  331M   2% /run
/dev/vda3      xfs           40G  4.8G   36G  12% /
/dev/vda2      vfat         100M  7.1M   93M   8% /boot/efi
tmpfs          tmpfs        168M     0  168M   0% /run/user/1001
onedrive:      fuse.rclone   15G  1.7M   15G   1% /opt/onedrive

# 卸载（如无 fuse 则无卸载命令）
$ dnf install -y fuse
$ fusermount -qzu /opt/onedrive
```

- `DriveName` 为配置时填的 `name`
- `Folder` 为 `onedrive` 里的文件夹
- `LocalFolder` 为刚创建的本地文件夹

```sh
# 开机自启服务
command="rclone mount onedrive:/ /opt/onedrive --cache-dir /opt/onedrive/temp  --vfs-cache-mode writes --copy-links --no-gzip-encoding --no-check-certificate --allow-other --allow-non-empty --umask 000"
cat > /etc/systemd/system/rclone.service <<EOF
[Unit]
Description=Rclone
After=network-online.target

[Service]
Type=simple
ExecStart=$(command -v rclone) ${command}
Restart=on-abort
User=root

[Install]
WantedBy=default.target
EOF
$ systemctl enable rclone;systemctl start rclone
```

**重申说明**：Rclone 挂载 `OneDrive/GDrive` 时，会出现部分文件上传失败或挂载崩掉等问题，在进行文件操作时会使用本地磁盘进行缓存，即占用本地磁盘空间，使用不当还可能造成磁盘写满、ECS/VPS 卡死等问题，故不建议作挂载操作。

### 3.5 同步数据

> 要稳定的进行上传、下载、同步等操作建议使用 Rclone 的原生命令功能，详细操作参见 [Rclone Docs](https://rclone.org/docs/)

**命令语法**

```sh
# 本地到网盘
rclone [功能选项] <本地路径> <网盘名称:路径> [参数] [参数] ...

# 网盘到本地
rclone [功能选项] <网盘名称:路径> <本地路径> [参数] [参数] ...

# 网盘到网盘
rclone [功能选项] <网盘名称:路径> <网盘名称:路径> [参数] [参数] ...
```

**用法示例**

```sh
# 复制本地至远端 OneDrive
$ rclone copy -v /opt/app onedrive:/ECS_BAK/ --transfers=1
2024/08/03 18:00:32 INFO  : shell/clean-cache.sh: Copied (new)
2024/08/03 18:00:33 INFO  : shell/rclone-install.sh: Copied (new)
2024/08/03 18:00:35 INFO  : proxy/ngproxy.yml: Copied (new)
2024/08/03 18:00:36 INFO  : shell: Set directory modification time (using DirSetModTime)
2024/08/03 18:00:36 INFO  : proxy: Set directory modification time (using DirSetModTime)
2024/08/03 18:00:36 INFO  : 
Transferred:        6.008 KiB / 6.008 KiB, 100%, 1.001 KiB/s, ETA 0s
Transferred:            3 / 3, 100%
Elapsed time:         8.6s

# 同步本地 & 远端 OneDrive
$ rclone sync -v /opt/app onedrive:/ECS_BAK/ --transfers=1
2024/08/06 14:33:47 INFO  : certbot/credentials.ini: Copied (new)
2024/08/06 14:33:48 INFO  : certbot/Dockerfile: Copied (new)
2024/08/06 14:33:49 INFO  : certbot/ReadMe: Copied (new)
2024/08/06 14:33:49 INFO  : certbot: Set directory modification time (using DirSetModTime)
2024/08/06 14:33:49 INFO  : 
Transferred:        1.177 KiB / 1.177 KiB, 100%, 200 B/s, ETA 0s
Checks:                 3 / 3, 100%
Transferred:            3 / 3, 100%
Elapsed time:         9.4s
```

### 3.6 定时任务

链接 OneDrive 仅主要作为备份 ECS/VPS 文件，故只设置定时任务，每天晚上执行

```sh
$ crontab -l
# 每天凌晨3点执行OneDrive同步
0 3 * * * rclone sync -v /opt/app onedrive:/ECS_BAK/ --transfers=1 >> /root/.config/rclone/rclone.log 2>&1
```

```sh
$ cat rclone.log | tail -n 6
2024/09/15 03:02:17 INFO  : 
Transferred:       19.977 MiB / 19.977 MiB, 100%, 142.549 KiB/s, ETA 0s
Checks:               618 / 618, 100%
Transferred:           84 / 84, 100%
Elapsed time:      2m15.5s
```

## 四. CertBot

> 通过 `Docker + CertBot` 安装 `Aliyun Cli` 工具，实现 SSL 泛域名自动续期

### 4.1 生成 Key & Secret

操作步骤：

- 获取 Aliyun 的 Key 和 Secret
- 通过镜像容器 Certbot/Certbot 执行验证 DNS 签发证书
- 配置 Nginx 添加证书
- 配置续期证书 Crontab 任务

获取阿里云的 Key 和 Secret 过程：

1. 登录 [RAM 控制台](https://ram.console.aliyun.com/overview)
2. 在左侧导航栏，选择 **身份管理 > 用户**，创建 **用户** 会自动生成一对 key 和 secret
3. 根据界面提示完成安全验证
4. 在**创建 AccessKey** 对话框，查看 AccessKey ID 和 AccessKey Secret。另建议**下载 CSV 文件**，下载 AccessKey 信息。或单击**复制**，复制 AccessKey 信息保存下来。

PS：登录名称自定义，另访问方式选择 **OpenAPI 调用访问** 即可，另外创建完成后建议下载 CSV，后续 AccessKey ID 和 AccessKey Secret 会消失。

生成 Key 和 Secret 后，为用户添加权限，或者点击授权，给用户进行 `AliyunDNSFullAccess` 授权，完成后即可进行下一步操作；

### 4.2 签发证书

安装 `Aliyun Cli` 工具（简化安装过程，采用 Docker 镜像方式）

```sh
$ docker pull certbot/certbot:v2.11.0
$ cat Dockerfile
FROM certbot/certbot:v2.11.0
RUN pip install certbot-dns-aliyun
$ docker build -t certbot-aliyun .
```

创建和授权对应配置文件，配置 access_key 和 access_key_secret

```sh
$ touch /opt/app/certbot/credentials.ini
dns_aliyun_access_key = access_key
dns_aliyun_access_key_secret = access_key_secret
$ chmod 600 /opt/app/certbot/credentials.ini
```

最后执行验证 DNS 签发证书命令，其中签发的方式有以下三种：

- dns-aliyun：使用 DNS TXT 记录获取证书
- standalone：本地运行 HTTP 服务器（不支持通配符）
- webroot：将必要的验证文件保存到指定 webroot 目录内的 .well-known/acme-challenge/
  目录（不支持通配符）

```sh
$ docker run -it --rm \
 -v /opt/app/certbot:/etc/letsencrypt \
 certbot-aliyun certonly \
 --dns-aliyun-credentials /etc/letsencrypt/credentials.ini \
 -d 17121203.xyz -d *.17121203.xyz
Saving debug log to /var/log/letsencrypt/letsencrypt.log

How would you like to authenticate with the ACME CA?
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
1: Obtain certificates using a DNS TXT record (if you are using Aliyun DNS).
(dns-aliyun)
2: Runs an HTTP server locally which serves the necessary validation files under
the /.well-known/acme-challenge/ request path. Suitable if there is no HTTP
server already running. HTTP challenge only (wildcards not supported).
(standalone)
3: Saves the necessary validation files to a .well-known/acme-challenge/
directory within the nominated webroot path. A seperate HTTP server must be
running and serving files from the webroot path. HTTP challenge only (wildcards
not supported). (webroot)
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Select the appropriate number [1-3] then [enter] (press 'c' to cancel): 1
Enter email address (used for urgent renewal and security notices)
 (Enter 'c' to cancel): yuikuen.yuen@outlook.com

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Please read the Terms of Service at
https://letsencrypt.org/documents/LE-SA-v1.4-April-3-2024.pdf. You must agree in
order to register with the ACME server. Do you agree?
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
(Y)es/(N)o: y

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Would you be willing, once your first certificate is successfully issued, to
share your email address with the Electronic Frontier Foundation, a founding
partner of the Let's Encrypt project and the non-profit organization that
develops Certbot? We'd like to send you email about our work encrypting the web,
EFF news, campaigns, and ways to support digital freedom.
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
(Y)es/(N)o: y
Account registered.
Requesting a certificate for 17121203.xyz and *.17121203.xyz
Waiting 30 seconds for DNS changes to propagate

Successfully received certificate.
Certificate is saved at: /etc/letsencrypt/live/17121203.xyz/fullchain.pem
Key is saved at:         /etc/letsencrypt/live/17121203.xyz/privkey.pem
This certificate expires on 2024-11-04.
These files will be updated when the certificate renews.

NEXT STEPS:
- The certificate will need to be renewed before it expires. Certbot can automatically renew the certificate in the background, but you may need to take steps to enable that functionality. See https://certbot.org/renewal-setup for instructions.

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
If you like Certbot, please consider supporting our work by:
 * Donating to ISRG / Let's Encrypt:   https://letsencrypt.org/donate
 * Donating to EFF:                    https://eff.org/donate-le
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
[root@ecs-sz-2017121203 certbot]# tree live/ -l 2
live/
├── 17121203.xyz
│   ├── cert.pem -> ../../archive/17121203.xyz/cert1.pem
│   ├── chain.pem -> ../../archive/17121203.xyz/chain1.pem
│   ├── fullchain.pem -> ../../archive/17121203.xyz/fullchain1.pem
│   ├── privkey.pem -> ../../archive/17121203.xyz/privkey1.pem
│   └── README
└── README
2 [error opening dir]

1 directory, 6 files
```

PS：若是第一次配置，会要求输入一个合法邮箱提供给 Let’s Encrypt。若自动更新失效，Let’s Encrypt 会在证书失效前给你发邮件。

### 4.3 自动续签

!!! message
    根据实际部署时间，添加期限执行签发

```sh
$ crontab -l
# 每3个月的凌晨3点执行签发证书
0 3 3 */3 * docker run -it --rm -v /opt/app/certbot:/etc/letsencrypt certbot-aliyun renew
```

## 五. MkDocs Material

> Web 个人站点目前采用 Docker + MkDocs Material 进行部署
> 先行在 GitHub 上创建空项目，之后 Git Clone 至本地，再通过 mkdocs-material 进行编译构建、编写文章等，最后可通过推送 GitHub 和同步 OneDrive 作备份

### 5.1 Build & Deploy

使用 `squidfunk/mkdocs-material` 官方镜像，安装需要的插件，再进行重构建镜像

```sh
$ docker pull squidfunk/mkdocs-material:9.5.25
$ cat Dockerfile
FROM squidfunk/mkdocs-material:9.5.25
# 创建虚拟环境并安装 mkdocs-static-i18n 插件
#RUN python3 -m venv /venv
#ENV PATH="/venv/bin:$PATH"
RUN pip install mkdocs-static-i18n \
 && pip install mkdocs-rss-plugin \
 && pip install mkdocs-minify-plugin \
 && pip install mkdocs-git-revision-date-localized-plugin \
 && pip install mkdocs-git-committers-plugin-2 \
 && pip install mkdocs-git-authors-plugin \
 && pip install mkdocs-git-revision-date-localized-plugin
$ docker build -t yuikuen/mkdocs-material:9.5.25
```

之后创建空目录或下拉空项目作为站点目录（后期网站上传 GitHub 后，可直接下拉代码快速迁移站点）

```sh
$ git clone git@github.com:yuikuen/infosilo.github.io.git
$ docker run --rm -it -v ${PWD}:/docs yuikuen/mkdocs-material:9.5.25 new .
# 编辑调试 & 构建站点
$ docker run --rm -it --name docs -v ${PWD}:/docs -p 8000:8000 yuikuen/mkdocs-material:9.5.25 serve -a 0.0.0.0:8000
$ docker run --rm -it --name docs -v ${PWD}:/docs -p 8000:8000 yuikuen/mkdocs-material:9.5.25 build
```

### 5.2 Nginx Proxy

> 前置已通过 Docker + CertBot 创建了证书文件，之后通过 Nginx 代理

!!! Warning "**注意事项**"
    注意提前开启安全组的端口访问权限

```sh
$ docker network create proxy_net
$ docker network ls
NETWORK ID     NAME        DRIVER    SCOPE
4546f3c7e4a0   bridge      bridge    local
3d766c5c0c0d   host        host      local
1a7130e0b2f0   none        null      local
ac192bbc76c9   proxy_net   bridge    local
```

创建 yaml & conf 配置文件

```sh
$ cat /opt/app/proxy/ngproxy.yml
services:
  nginx:
    image: nginx:1.24.0-alpine3.17-perl
    container_name: proxy
    restart: always
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./conf.d:/etc/nginx/conf.d
      #- ./certs:/etc/nginx/certs
      # 证书改为certbot生成的证书路径
      - /opt/app/certbot:/etc/nginx/certs
      - ./log/nginx:/var/log/nginx
      - ./html:/usr/share/nginx/html:rw
      # mkdocs站点生成目录
      - /opt/app/infosilo.github.io/site:/usr/share/nginx/html/mkdocs:ro
    networks:
      - ngproxy
networks:
  ngproxy:
    external: true
    name: proxy_net
```

```sh
$ cat ./conf.d/mkdocs.conf
server {
    listen       80;
    listen       443 ssl;
    server_name  17121203.xyz;
    # ssl证书地址
    ssl_certificate     /etc/nginx/certs/live/17121203.xyz/fullchain.pem;
    ssl_certificate_key /etc/nginx/certs/live/17121203.xyz/privkey.pem;
    # ssl验证相关配置
    ssl_session_timeout 5m;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE:ECDH:AES:HIGH:!NULL:!aNULL:!MD5:!ADH:!RC4;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_prefer_server_ciphers on;
    # 强制HTTPS跳转
    if ($scheme = http) {
        return 301 https://$server_name$request_uri;
    }
    location / {
        root  /usr/share/nginx/html/mkdocs;
        index index.html index.htm;
    }
}
```

### 5.3 Build & Push

创建定时构建 & 推送脚本和任务

```sh
#!/bin/bash

# 定义路径变量
path="/opt/app/infosilo.github.io"
log_file="/var/log/web.log"

# 定义时间戳变量
timestamp="$(date +'%Y-%m-%d %H:%M:%S')"

# 进入指定路径
cd $path

# 执行构建命令
if docker run --rm --name docs -v ${PWD}:/docs yuikuen/mkdocs-material:9.5.25 build; then
    # 如果执行成功，则输出结果到日志文件，并添加时间戳
    echo "$timestamp - ok" >> $log_file

    # 添加所有文件到Git
    git add .

    # 提交更改
    git commit -m "update on $timestamp"

    # 推送到远程仓库
    git push -u origin main
else
    # 如果执行失败，则输出结果到日志文件，并添加时间戳
    echo "$timestamp - no" >> $log_file
fi
```

```sh
$ crontab -e
# 每天凌晨0点执行build&push操作
0 0 * * * /bin/bash /opt/app/shell/build-push.sh >> /dev/null 2>&1
```

## 六. EasyImage

> ECS/VPS 自建图床服务，Typora/Vs Code + PicGo 作上传使用

### 6.1 Build & Deploy

```yaml
$ cat /opt/app/easyimage/docker-compose.yml
#version: '3.3'
services:
  easyimage:
    image: ddsderek/easyimage:v2.8.5
    container_name: easyimage
    restart: unless-stopped
    #ports:
    #  - "8000:80"
    expose:
      - "80"
    environment:
      - TZ=Asia/Shanghai
      - PUID=0
      - PGID=0
      - DEBUG=false
    volumes:
      - './config:/app/web/config'
      - './i:/app/web/i'
    networks:
      - imgproxy
networks:
  imgproxy:
    external: true
    name: proxy_net
```

### 6.2 Nginx Proxy

前面已通过 CertBot 签发了泛域名，此处则同样使用 Nginx 作反向代理使用

```sh
$ cat ./conf.d/easyimage.conf
server {
    listen 443 ssl;
    server_name img.17121203.xyz;

    ssl_certificate     /etc/nginx/certs/live/17121203.xyz/fullchain.pem;
    ssl_certificate_key /etc/nginx/certs/live/17121203.xyz/privkey.pem;

    location / {
        proxy_pass http://easyimage;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_redirect off;
    }
}
```

### 6.3 Install Nodejs

> NodeJs DownLoad：<http://nodejs.cn/download>

1、双击 `.exe` 文件安装，然后自定义路径，如 `D:\Tools\Nodejs`（根据个人安装路径习惯存放）

2、在安装路径的根目录下新建两个文件夹，`node_cache` & `node_global`

3、设置环境变量

- 电脑 -> 属性 -> 系统 -> 系统信息 -> 高级系统设置 -> 高级 -> 环境变量

- 在 **系统变量** 里新建一个 `NODE_HOME`，变量值为安装路径：`D:\Tools\Nodejs`

- 然后再在 **系统变量** 的【path】中添加三个参数：

  `%NODE_HOME%`、`%NODE_HOME%\node_global`、`%NODE_HOME%\node_cache`

- 之后将用户变量默认的`C:\Users\$username\AppData\Roaming\npm` 改成 `D:\Tools\Nodejs\node_global`

4、保存确认后进行验证

- `win+r` 进入 cmd，分别输入 `node -v` 和 `npm -v` 查看所安装的版本号

- cmd 中执行如下命令，配置缓存目录和全局目录

  ```cmd
  npm config set cache "D:\Tools\Nodejs\node_cache"
  npm config set prefix "D:\Tools\Nodejs\node_global"
  ```

  PS：如出现标红报错，多是由于权限原因导致，可设置 Nodejs 文件夹将所有权限都 ✔ 即可

- 更换 npm 源为淘宝镜像

  ```cmd
  npm config set registry https://registry.npmmirror.com
  ```

  注：<https://registry.npm.taobao.org> 已废弃

- 检查配置是否成功

  ```cmd
  npm config get registry
  ```

### 6.4 Install PicGo

> PicGo DownLoad：<https://github.com/Molunerfinn/PicGo/releases>

1、双击 .exe 文件安装，然后在插件设置中搜索 `web-upload`，选择 `web-uploader 1.1.1` 安装

（安装插件提示失败错误，请重启电脑，因前置 NodeJs 环境未生效导致）

2、配置图床，点击图床设置 -> 自定义 Web 图床，然后新建一个图床配置，参考如下方式填写

```sh
图床配置名：// 自定义
API地址：<https://img.17121203.xyz> // 网站API地址
POST参数名：image
JSON路径：url
自定义请求头：// 不填写
自定义Body：{"token":"123"} // 网站生成的Token
```

PS：详细参数查看 EasyImage 中的 API 设置，另外记得开启 **图床安全** 的 **API 上传** 功能，最后在 PicGo 上传一张图片，并在 EasyImage 中查看是否有此图片；

## 七. WireGuard

> 通过 Docker + [Wg-Easy](https://github.com/wg-easy/wg-easy) 快速部署 WireGuard VPN，实现远程办公组网

```sh
# 官方示例
  docker run -d \
  --name=wg-easy \
  -e LANG=de \
  -e WG_HOST=<🚨YOUR_SERVER_IP> \
  -e PASSWORD_HASH=<🚨YOUR_ADMIN_PASSWORD_HASH> \
  -e PORT=51821 \
  -e WG_PORT=51820 \
  -v ~/.wg-easy:/etc/wireguard \
  -p 51820:51820/udp \
  -p 51821:51821/tcp \
  --cap-add=NET_ADMIN \
  --cap-add=SYS_MODULE \
  --sysctl="net.ipv4.conf.all.src_valid_mark=1" \
  --sysctl="net.ipv4.ip_forward=1" \
  --restart unless-stopped \
  ghcr.io/wg-easy/wg-easy
```

### 7.1 Build & Deploy

使用 yaml 编排服务，注意开启安全组端口

```yml
$ cat /opt/app/wg-easy/docker-compose.yml
#version: "3.8"
services:
  wg-easy:
    image: ghcr.io/wg-easy/wg-easy:13
    container_name: relay
    restart: unless-stopped
    volumes:
      - './.wg-easy:/etc/wireguard'
    ports:
      - "51820:51820/udp"
     #- "51821:51821/tcp"
    expose:
      # web-ui
      - "51821/tcp"
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
      - WG_HOST=wg.17121203.xyz
      - PASSWORD=WebUI-Password
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

### 7.2 Nginx Proxy

```sh
$ cat ./conf.d/wg-easy.conf
server {
    listen       80;
    listen       443 ssl;
    server_name  wg.17121203.xyz;

    # ssl证书地址
    ssl_certificate     /etc/nginx/certs/live/17121203.xyz/fullchain.pem;
    ssl_certificate_key /etc/nginx/certs/live/17121203.xyz/privkey.pem;

    # ssl验证相关配置
    ssl_session_timeout 5m;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE:ECDH:AES:HIGH:!NULL:!aNULL:!MD5:!ADH:!RC4;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_prefer_server_ciphers on;

    # 强制HTTPS跳转
    if ($scheme = http) {
        return 301 https://$server_name$request_uri;
    }

    location / {
        proxy_pass http://relay:51821;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_redirect off;
    }
}
```

!!! bug
    PS：如 Docker WireGuard 执行报如下错误，则需要添加内核模块

```sh
iptables v1.8.10 (legacy): can't initialize iptables table `nat': Table does not exist (do you need to insmod?)
Perhaps iptables or your kernel needs to be upgraded.

# 问题分析：
理论上来说，宿主机和容器是公用内核的，iptables 是基于 iptable_filter 这个模块的，使用 lsmod 查看内核有没有加载这个模块，发现的确没有加载，加载内核模块 iptable_filter
$ lsmod |grep -E "ip_tables|iptable_filter"
$ lsmod | grep ip
ip6_udp_tunnel         16384  1 wireguard
nf_defrag_ipv6         24576  1 nf_conntrack
nf_defrag_ipv4         16384  1 nf_conntrack

# 尝试手动加载，加载后可以看到已经加载的模块
$ modprobe iptable_filter
$ lsmod |grep -E "ip_tables|iptable_filter"
iptable_filter         16384  0
ip_tables              32768  1 iptable_filter

$ lsmod | grep ip
iptable_filter         16384  0
ip_tables              32768  1 iptable_filter
ip6_udp_tunnel         16384  1 wireguard
nf_defrag_ipv6         24576  1 nf_conntrack
nf_defrag_ipv4         16384  1 nf_conntrack
```

上述方法虽然解决了问题，但重启之后就会失效，如需永久生效则需创建模块问题

> 测试系统为 Rocky Linux release 9.4 (Blue Onyx)

```sh
$ cat > /etc/modules-load.d/iptable-filter.conf << EOF
iptable_filter
EOF
```
