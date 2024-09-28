**Arch Linux** 是一款基于 x86-64 架构的 Linux 发行版，系统安装、删除和更新软件的软件包管理器叫做 **pacman**。系统安装映像只简单地包含系统主要组件，采用滚动发行模式来获取系统更新和软件的最新版本，以社区 Wiki 的形式提供文档，简称为 [Arch Wiki](https://wiki.archlinux.org/)

## 一. 前期准备

1）**镜像下载** 主要有两个途径，一个是 Arch 官方提供的 [下载地址](https://archlinux.org/download/)，另外的是其它镜像站提供的下载地址，如 [阿里云镜像站](https://mirrors.aliyun.com/archlinux/)

2）**镜像烧录** 建议使用 Rufus 进行，过程自行度娘，镜像烧录步骤较为简单，在此不详细说明；

注：根据 Arch Wiki 介绍，Arch 是不支持安全启动的，而一般电脑默认开启安全启动，所以需要先到 BIOS 里面关闭安全启动( Secure Boot )，同时需要先关闭 Windows 的快速启动

## 二. 网络设置

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

## 三. 更新时间

更新系统时间是有必要的，因为下载软件是服务器会验证系统时间，如果时间不正确，可能出现下载失败的情况

```sh
$ timedatectl set-ntp true
$ timedatectl status
```

## 四. 换镜像源

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

## 五. 磁盘分区

分区就是为了上面讲到的挂载，不同分区有不同的大小，呈现在文件系统里面就是不同目录有不同大小

| 分区 | 容量 | 挂载目录 | 作用                                       |
| ---- | ---- | -------- | ------------------------------------------ |
| EFI  | 300M | /boot    | 引导文件存放                            |
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
