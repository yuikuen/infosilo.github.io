**Arch Linux** 是一款基于 x86-64 架构的 Linux 发行版，系统安装、删除和更新软件的软件包管理器叫做 **pacman**。系统安装映像只简单地包含系统主要组件，采用滚动发行模式来获取系统更新和软件的最新版本，以社区 Wiki 的形式提供文档，简称为 [Arch Wiki](https://wiki.archlinux.org/)

## 一. 安装准备

1）**镜像下载**主要有两个途径，一个是 Arch 官方提供的 [下载地址](https://archlinux.org/download/)，另外的是其它镜像站提供的下载地址，如 [阿里云镜像站](https://mirrors.aliyun.com/archlinux/)

2）**镜像烧录**建议使用 Rufus 进行，过程自行度娘，镜像烧录步骤较为简单，在此不详细说明；

注：根据 Arch Wiki 介绍，Arch 是不支持安全启动的，而一般电脑默认开启安全启动，所以需要先到 BIOS 里面关闭安全启动( Secure Boot )，同时需要先关闭 Windows 的快速启动

### 1.1 网络设置

> 安装过程需要安装各种服务、组件，网络是必须的

1）确认网卡是否被禁用，使用以下命令解除网卡禁用

```sh
$ rfkill list
$ rfkill unblock all
```

2）连接网络，使用 iwctl 工具扫描并进行连接

```sh
$ iwctl
-------------下面为iwctl界面，不同于终端-----------
[iwd] help                                     // 输入help回车可以查看使用说明
[iwd] device list                              // 回车后可以查看当前网卡设备，一般为 wlan0
[iwd] station <device> scan                    // <device>替换为上面的网卡设备，这条命令可以让网卡扫描wifi设备
[iwd] station <device> get-networks            // 会车后可以显示当前可连接网络
[iwd] station <device> connect <wifi name>     // 连接wifi, <wifi name> 为上面获取的wifi名称
password:                                      // 如果wifi为加密wifi,输入密码回车
[iwd] quit                                     // 退出 wifi 连接界面
```

除上述方法外，也可将 SSID 和 wpa_pass 写到配置文件，进行调用

```sh
$ cd /etc/netctl/examples                      // 找示例配置文件
$ ip link set wlan0 up
$ iwlist wlan0 scan | grep ESSID               // 记下无线网卡名称和wifi匹配名称
$ cp /etc/netctl/example/wireless-wpa /etc/netctl/somedescriptivename
$ vim /etc/netctl/somedescriptivename          // 配置ssid\passwd,注意使用权限chmod 600禁止非root用户访问
$ systemctl enable netctl-auto@wlan0.service   // 注意wifi名称
$ dhcpcd &
```

### 1.2 更新时间

更新系统时间是有必要的，因为下载软件是服务器会验证系统时间，如果时间不正确，可能出现下载失败的情况

```sh
$ timedatectl set-ntp true
$ timedatectl status
```

### 1.3 换镜像源

ArchLinux 官方网站在国外，国内访问略慢，而国内有专门的镜像站，并且镜像站每天更新，软件包也是最新的

- 方法一：自动搜索并将带有 `China` 的项目保留至目标文件

```sh
$ reflector --country China --age 72 --sort rate --protocol https --save /etc/pacman.d/mirrorlist
```

- 方法二：手动修改配置文件

```sh
$ cp -a /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
# 新建镜像源文件或将中国的源地址复制粘贴置顶
$ vim /etc/pacman.d/mirrorlist
Server = https://repo.huaweicloud.com/archlinux/$repo/os/$arch
Server = http://mirrors.aliyun.com/archlinux/$repo/os/$arch
```

### 1.4 磁盘分区

分区就是为了上面讲到的挂载，不同分区有不同的大小，呈现在文件系统里面就是不同目录有不同大小

| 分区 | 容量 | 挂载目录 | 作用                                       |
| ---- | ---- | -------- | ------------------------------------------ |
| EFI  | 300M | /boot    | 引导文件存放                               |
| swap | 4G   | 无       | 系统挂起或内存不足时可能会被当作 ROM 使用  |
| root | N    | /        | 存放系统文件，根目录分区，分配剩余所有空间 |
| home | N    | /home    | 家目录，存放用户文件，可不设置             |

注：分区因人而异，请根据实际场景进行划分，仅供参考；

- 方法一：使用 `cfdisk` 工具

```sh
$ cfdisk /dev/sda
# ----------------------cfdisk界面---------------------
# cfdisk 是图形化的分区，比fdisk简单很多
# 下面有一行操作文件，通过左右方向键可以移动到不同选项。上下方向键可以选择不同分区进行操作
# [New]选项为新建分区，将方向键选择到未分配的分区，选择[New]选项，回车后会提示新分区大小，输入大小即可创建一个新的分区
# [Quit]可以退出 cfdisk ，并且不保存修改，也就是之前做的操作一律作废
# [Help]选项可以查看 cfdisk 帮助
# [Write]选项才是真的执行写入操作，使用后会对操作的磁盘执行写入，以前做的修改会生效
# [Type]选项可以改变分区类型，boot分区选择EFI分区类型，根分区和home分区选ext4类型，swap分区选择Linux swap类型
```

- 方法二：使用 `fdisk` 命令工具

```sh
$ fdisk /dev/sda
g //创建gpt格式
n //创建分区
p //显示分区情况
w //保存并退出
```

上面的操作只是分区，还需要进行格式化，不同分区需要不同的格式

1）**boot 分区**，引导分区采用 FAT 格式

```sh
$ mkfs.vfat /dev/sda1
```

2）**swap 分区**，交换分区无需挂载，采用特定格式

```sh
$ mkswap /dev/sda2
$ swapon /dev/sda2
```

3）**根 & 家分区**，都是 Linux 常见的 ext4 格式

```sh
$ mkfs.ext4 /dev/sda3
$ mkfs.ext4 /dev/sda4
```

4）挂载目录，进行安装系统

```sh
# Linux分区由根分区开始，所以先挂载根分区
$ mount /dev/sda3 /mnt
$ mkdir /mnt/boot
$ mount /dev/sda1 /mnt/boot
```

## 二. 安装系统

### 2.1 基础软件

> 前置工作完成后，现开始正式安装系统

1）安装基本系统和必要的工具

```sh
$ pacstrap /mnt base base-devel bash-completion linux linux-firmware linux-headers vim git dhcpcd e2fsprogs iwd
```

2）生成文件系统表，主要用于系统启动时自动挂载分区，不然系统无法正常启动

```sh
$ genfstab -U /mnt >> /mnt/etc/fstab
$ cat /mnt/etc/fstab
```

到这一步基本系统安装已经完成，但是还没有对系统进行配置，所以现在还没到关机重启的时候

```sh
# 执行以下命令进入安装的系统进行配置
$ arch-chroot /mnt
```

### 2.2 设置时区

> 设置时区为上海，并同步硬件时钟

```sh
$ ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
$ hwclock --systohc
```

### 2.3 本地设置

本地化设置：明确规定地域、货币、时区日期的格式、字符排列方式和其他本地化标准

1）生成 Local 信息

```sh
# 取消注释 /etc/locale.gen,其中 en_US.UTF-8 表示英文，zh_CN.UTF-8 表示中文
$ sed -i 's/^#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
$ sed -i 's/^#zh_CN.UTF-8/zh_CN.UTF-8/' /etc/locale.gen
# 生成 Local
$ locale-gen
```

2）创建 `locale.conf` 文件，并编辑设定 `LANG` 变量

```sh
# 这里不建议将 en_US.UTF-8 改为zh_CN.UTF-8 ，这样会导致终端乱码
$ echo "LANG=en_US.UTF-8" >> /etc/locale.conf
```

3）配置主机名(hostname)，主机名可自定义

```sh
$ echo "ArchLinux" >> /etc/hostname
$ echo -e "127.0.0.1 localhost\n::1 localhost\n127.0.1.1 hostname.localdomain ArchLinux" >> /etc/hosts
$ cat /etc/hosts
127.0.0.1 localhost
::1       localhost
127.0.0.1 hostname.localdomain ArchLinux
```

4）设置管理员密码，根据提示二次验证即可

```sh
$ passwd root
```

### 2.4 安装引导

> 安装 Linux 引导加载程序，才能在安装后启动系统

1）安装微码，根据自身 CPU 规格进行安装

```sh
# amd 电脑安装
$ pacman -S amd-ucode
# intel 电脑安装
$ pacman -S intel-ucode
```

2）安装引导，配置 grub

```sh
$ pacman -S grub efibootmgr efivar os-prober
$ grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Arch --recheck
$ grub-mkconfig -o /boot/grub/grub.cfg
```

注：grub2 默认禁用了 os-prober ，如果你是选择的双系统或多系统安装，需要手动开启该选项，os-prober 可以检查其他硬盘上的其他系统引导，如果不开启，可能无法识别其他系统，如果你是全盘单系统安装，可以忽略这个选项

```sh
# 需要开启 os-prober 执行下面命令
echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub
```

### 2.5 开机服务

ArchLinux 使用 systemd 管理后台服务，需要提前下载联网程序并设置开机自启动

```sh
$ pacman -S dhcpcd iwd networkmanager
$ systemctl enable NetworkManager dhcpcd iwd
```

至此，ArchLinux 安装已基本完成，之后退出安装程序，取消挂载分区，重启选择 Arch 系统即可进入

```sh
$ exit
$ umount -R /mnt ; reboot
```

## 三. 基础设置

### 3.1 用户创建

开机后会显示一个终端的登陆界面，默认只有一个 root 用户，可直接使用，为了安全起见，一般会建立普通用户

```sh
$ useradd -m -G wheel -s /bin/bash <username>
# <username> 为用户名，注意用户名必须全小写

# 设置用户密码并赋予用户sudo权限
$ passwd <usrname>
$ vim /etc/sudoers +85
# Uncomment to allow members of group wheel to execute any command
# 删除下行注释
%wheel ALL=(ALL) ALL
```

注：这里的 `%wheel` 就是代表 `wheel` 组，意味着 `wheel` 组中的所有用户都可以使用 `sudo` 命令

### 3.2 联网设置

为了保证之后的操作，需要提前确保网络是否正常，具体方法如下：

- 方法一：使用 `iwctl` 工具扫描并进行连接

```sh
$ iwctl
-------------下面为iwctl界面，不同于终端-----------
[iwd] help                                     // 输入help回车可以查看使用说明
[iwd] device list                              // 回车后可以查看当前网卡设备，一般为 wlan0
[iwd] station <device> scan                    // <device>替换为上面的网卡设备，这条命令可以让网卡扫描wifi设备
[iwd] station <device> get-networks            // 会车后可以显示当前可连接网络
[iwd] station <device> connect <wifi name>     // 连接wifi, <wifi name> 为上面获取的wifi名称
[iwd] station <device> connect-hidden <wifi name> // 连接隐藏SSID可用
password:                                      // 如果wifi为加密wifi,输入密码回车
[iwd] quit                                     // 退出 wifi 连接界面
```

- 方法二：将 `SSID` 和 `wpa_pass` 写到配置文件并进行调用

```sh
$ cd /etc/netctl/examples                      // 找示例配置文件
$ ip link set wlan0 up
$ iwlist wlan0 scan | grep ESSID               // 记下无线网卡名称和wifi匹配名称
$ cp /etc/netctl/example/wireless-wpa /etc/netctl/somedescriptivename
$ vim /etc/netctl/somedescriptivename          // 配置ssid\passwd,注意使用权限chmod 600禁止非root用户访问
$ systemctl enable netctl-auto@wlan0.service   // 注意wifi名称
$ dhcpcd &
```

- 方法三：使用 `nmtui` 工具

```sh
$ nmtui
-------------下面为nmtui界面，不同于终端-----------
# 1、选择‘Activate a connection’
# 2、回车后进入，选择需要连接的网络
# 3、输入密码连接成功后，back返回退出即可
```

- 方法四：使用 `nmcli` 命令连接

```sh
$ sudo nmcli device wifi list
$ sudo nmcli device wifi connect SSID passwd Passwd
$ sudo nmcli device disconnect
$ sudo nmcli connect del SSID
```

### 3.3 修改库源

1）如之前已配置了 `mirrorlist`，可直接取消注释即可使用中国库源

```sh
$ vim /etc/pacman.conf
# 将[multilib]配置取消注释，如下
[multilib]
Include = /etc/pacman.d/mirrorlist
```

2）设置中文社区软件源，可按需要配置

> `archlinuxcn`里头有许多中文用户常用的软件包

```sh
$ sudo vim /etc/pacman.conf
# 文末添加
[archlinuxcn]
Server = https://repo.archlinuxcn.org/$arch
Server = https://mirrors.ustc.edu.cn/archlinuxcn/$arch 
Server = https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/$arch

# 刷新数据库后，导入GPG key
sudo pacman -Sy && sudo pacman -S archlinuxcn-keyring
```

如报错并提示一串 ERROR 代码，可重置后再执行上述操作

```sh
$ sudo timedatectl set-ntp 1
$ sudo timedatectl status

$ sudo rm -rf /etc/pacman.gnupg
$ pacman-key --init
$ pacman-key --populate
```