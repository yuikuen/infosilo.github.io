> CentOS 部署 VsFtpd 服务

vsftpd 是一个 UNIX 类操作系统上运行的服务器的名字，它可以运行在诸如 Linux, BSD, Solaris, HP-UX 以及 IRIX 上面，它支持很多其他的 FTP 服务器不支持的特征

## 一. 程序安装

直接使用 Yum 安装

```sh
$ yum -y install vsftpd
$ systemctl enable --now vsftpd
```

## 二. 修改配置

```sh
$ cp /etc/vsftpd/vsftpd.conf /etc/vsftpd/vsftpd.conf.bak
$ grep -v "#" /etc/vsftpd/vsftpd.conf.bak > /etc/vsftpd/vsftpd.conf
# 注意不能有多余的空格，安全建议：把默认端口 21 端口进行修改
$ vim /etc/vsftpd/vsftpd.conf
anonymous_enable=NO                          # 是否开启匿名用户
local_enable=YES                             # 允许本机账号登录FTP
write_enable=YES                             # 允许账号都有写操作
local_umask=022                              # 文件目录权限：777-022=755，文件权限：666-022=644
dirmessage_enable=YES                        # 进入某个目录的时候，是否在客户端提示一下
xferlog_enable=YES                           # 日志记录
connect_from_port_20=YES                     # 开放port模式的20端口的连接
xferlog_std_format=YES                       # 日志成为std格式
chroot_local_user=YES                        # 限制用户只能在自己的目录活动
chroot_list_file=/etc/vsftpd/chroot_list
ls_recurse_enable=NO                         # 是否允许使用ls -R等命令
listen=YES                                   # 监听ipv4端口，开了这个就说明vsftpd可以独立运行，不用依赖其他服务
pam_service_name=vsftpd                      # pam模块的名称，放置在 /etc/pam.d/vsftpd ，认证用
userlist_enable=YES                          # 使用允许登录的名单
userlist_deny=NO                             # 限制允许登录的名单，前提是userlist_enable=YES
allow_writeable_chroot=YES                   # 允许限制在自己的目录活动的用户 拥有写权限
tcp_wrappers=YES                             # Tcp wrappers ： Transmission Control Protocol (TCP) Wrappers 为由 inetd 生成的服务提供了增强的安全性。
pasv_min_port=6661                           # 被动模式起始端口，0为随机分配
pasv_max_port=6666                           # 被动模式结束端口，0为随机分配
user_config_dir=/etc/vsftpd/userconfig       # 主目录配置，用户目录配置
```

修改后重新刷新配置

```sh
$ systemctl restart vsftpd
```

## 三. 创建用户

新建账密一般使用 `useradd -d newuser` 新建用户是可以登录系统的，这样会创建很多账密，会给系统带来安全隐患。因此需要将 `/etc/passwd` 中的用户改成 `/sbin/nologin` ，FTP 账密就无法登录了；

```sh
# 把ftp用户的shell改为/usr/bin/nologin,注意这里的bin不是sbin
$ echo /usr/bin/nologin >> /etc/shells
$ useradd -s /usr/bin/nologin newuser
$ passwd newuser
```

开放权限目录，编辑 user_list ，主要功能是允许登录 FTP 的名单，一行一个用户，不能把多个写一行；

```sh
$ vim /etc/vsftpd/user_list
# vsftpd userlist
# If userlist_deny=NO, only allow users in this file
# If userlist_deny=YES (default), never allow users in this file, and
# do not even prompt for a password.
# Note that the default vsftpd pam config also checks /etc/vsftpd/ftpusers
# for users that are denied.
root
bin
daemon
adm
lp
sync
shutdown
halt
mail
news
uucp
operator
games
nobody
newuser
```

自定义用户主目录，在创建 vsftpd 时，默认每个用户的主目录都会在 home，也就是说每个用户的主目录都是在不同的目录中，为了更好的集中管理，最好是将各用户作为子目录并且都集中在同一个主目录下；

```sh
$ ls -al
total 0
drwx------. 2 admin    admin    83 Nov 19 02:19 admin
drwx------. 2 newuser  newuser  62 Nov 22 18:39 newuser
```

**现把各用户主目录集中放到 `/home/ftp_data/username` 下集中管理**

PS：之前 **`/etc/vsftpd/vsftpd.conf`** 配置文件中，有 `user_config_dir=/etc/vsftpd/userconfig` #主目录配置，用户目录配置。就是定义用户的主目录，userconfig 默认是没的，必须新建，给每个用户定义主目录配置文件放至到哪个目录下，实现自定义主目录

```sh
$ mkdir -p /etc/vsftpd/userconfig
$ vim /etc/vsftpd/userconfig/newuser
local_root=/home/ftp_data/newuser
```

<font color=red>注意：配置文件名字必须与用户名相同</font>

```sh
$ mkdir -p /home/ftp_data/newuser
$ chmod -R 777 /home/ftp_data/newuser
$ tree /home/
/home/
├── admin
├── ftp_data
│   └── newuser
```

## 四. 附加说明

!!! info "安全说明"
    演示环境关闭了，实际生产环境根据需要进行限制/开放

    建议将监听端口改成连续，如 6660，被动模式端口范围 6661~6666

```sh
$ firewall-cmd --zone=public --add-port=6660-6666/tcp --permanent
success
$ firewall-cmd --reload
success
$ firewall-cmd --zone=public --query-port=6660-6666/tcp
yes
```

另下述为额外配置说明，需要可自行添加

```sh
anonymous_enable=NO            #是否开启匿名用户
local_enable=YES               #允许本机账号登录FTP
write_enable=YES               #允许账号都有写操作
local_umask=022                #文件目录权限：777-022=755，文件权限：666-022=644
#anon_upload_enable=YES        #匿名用户是否有上传文件的功能
#anon_mkdir_write_enable=YES   #匿名用户是否有创建文件夹的功能
dirmessage_enable=YES          #进入某个目录的时候，是否在客户端提示一下
xferlog_enable=YES             #日志记录
connect_from_port_20=YES       #开放port模式的20端口的连接
#chown_uploads=YES             #允许没人认领的文件上传的时候，更改掉所属用chown_uploads=YES的前提下，所属的用户
#xferlog_file=/var/log/xferlog #日志存放的地方
xferlog_std_format=YES         #日志成为std格式
#idle_session_timeout=600      #用户无操作服务器会主动断开连接，单位秒
#data_connection_timeout=120   #数据连接超时
#nopriv_user=ftpsecure         #以ftpsecure作为此一服务执行者的权限。因为ftpsecure的权限相当的低，因此即使被入侵，入侵者仅能取得nobody的权限！
#async_abor_enable=YES         #异步停用，由客户发起
#ascii_upload_enable=YES       #使用ascii格式上传文件
#ascii_download_enable=YES     #使用ascii格式下载文件
#ftpd_banner=Welcome to blah FTP service  #欢迎词
#deny_email_enable=YES         #以anonymous用户登录时候，是否禁止掉名单中的emaill密码。
#banned_email_file=/etc/vsftpd/banned_emails  #以anonymous用户登录时候，所禁止emaill密码名单。
chroot_local_user=YES          #限制用户只能在自己的目录活动
#chroot_list_enable=YES        #例外名单，如果是YES的话，上面的选项会跟这个名单反调（会被上面的选项影响）。
#chroot_list_file=/etc/vsftpd/chroot_list
ls_recurse_enable=NO           #是否允许使用ls -R等命令
listen=YES                     #监听ipv4端口，开了这个就说明vsftpd可以独立运行，不用依赖其他服务。
#listen_ipv6=YES               #监听ipv6端口
pam_service_name=vsftpd        #pam模块的名称，放置在/etc/pam.d/vsftpd，认证用
userlist_enable=YES            #使用允许登录的名单
userlist_deny=NO               #限制允许登录的名单，前提是userlist_enable=YES
allow_writeable_chroot=YES     #允许限制在自己的目录活动的用户拥有写权限
tcp_wrappers=YES               #Tcp wrappers ： Transmission Control Protocol (TCP) Wrappers 为由 inetd 生成的服务提供了增强的安全性。
user_config_dir=/etc/vsftpd/userconfig  #主目录配置，用户目录配置
 
pasv_min_port=6661 （0为随机分配）
pasv_max_port=6665（这两项定义了可以同时执行下载链接的数量。）
#被动模式端口范围：注意：linux客户端默认使用被动模式，windows客户端默认使用主动模式。在ftp客户端中执行"passive"来切换数据通道的模式。也可以使用"ftp -A ip"直接使用主动模式。主动模式、被动模式是有客户端来指定的。
```

## 五. 懒人脚本

```sh
#!/usr/bin/bash
# FTP服务器用户创建脚本

read -p "请输入要新建的用户：" newuser
 
# 判断新建用户是否存在
id $newuser &>/dev/null
if [ $? -ne 0 ]
	then
        useradd -s /usr/bin/nologin $newuser
		echo "用户$newuser成功创建"
		passwd $newuser
	else
		echo "用户$newuser已存在或者输入用户名错误，程序已终止"
		exit
fi	
 
# 判断允许登陆用户列表文件是否存在
if [ -f "/etc/vsftpd/user_list" ]
	then
		echo "正在将$newuser写入允许登陆列表配置文件"
		echo $newuser >>/etc/vsftpd/user_list    #把用户名写入到这个文件
	else
		echo "文件不存在，没有/etc/vsftpd/user_list这个文件"
		echo "程序终止"
		exit 
fi
 
# 判断用户主目录配置文件是否存在
if [ -f "/etc/vsftpd/userconfig/$newuser" ]
	then
		echo "用户主目录配置文件已存在，程序终止"
		echo "请确定此文件/etc/vsftpd/userconfig/$newuser，并查看/home/ftp_data/路径下是否存在此用户的数据"
		exit
	else
		echo "正在创建$newuser主目录配置文件"
		touch /etc/vsftpd/userconfig/$newuser  #新建用户主目录配置文件
		echo "local_root=/home/ftp_data/$newuser">>/etc/vsftpd/userconfig/$newuser	  #写入用户主目录信息
		echo "用户$newuser主目录信息文件配置完毕"
fi		
 
# 判断用户主目录是否存在
if [ ! -d "/home/ftp_data/$newuser" ];then
		mkdir -p /home/ftp_data/$newuser
		echo "用户$newuser主目录创建完毕"
		chmod -R 777 /home/ftp_data/$newuser
		echo "用户$newuser主目录权限配置完毕"
		echo "$newuser用户FTP账号配置完毕，请登陆测试"
	else
		echo "/home/ftp_data/$newuser目录已经存在,请检查此目录内是否有重要文件，防止数据被覆盖程序已终止"
		exit	
fi
```
