> ArchLinux 安装 i3 桌面及配置

首先通过安装介质启动到 live 环境，选第一个，以 root 身份进入一个虚拟控制台，默认 shell 为 zsh

`Arch Linux install medium (x86_64,UEFI)`

1）判断无线网卡是否被锁

```bash
$ rfkill list  
--------------
0: phy0: Wireless LAN
    Soft blocked: yes
    Hard blocked: yes
//如果出现以上内容，可以调节网卡开关打开它。如果没有开关，那就使用以下命令：
$ rfkill unblock wifi
```

2）连接网络

方法一：

```bash
$ ip add
$ ip link set wlan0 up
$ iwctl 
[iwd]device list                    // 列出无线设备名称
[iwd]station wlan0(<device>) scan   // 扫描当前环境下的网络
[iwd]station <device> get-networks  // 会显示扫描到的所有网络
[iwd]station <device> connect <network name>
password
[iwd]exit
$ ping www.baidu.com
```

方法二：

```bash
$ ip link set wlan0 up
$ iwlist wlan0 scan | grep ESSID
$ wpa_passphrase ESSID passwd > internet.conf
$ wpa_supplicant -c internet.conf -i wlan0 &
$ dhcpcd &
$ ping www.baidu.com
```

3）停止 reflector 服务，禁止自动更新

```bash
$ systemctl stop reflector.service
```

4）同步网络时间

```bash
$ timedatectl set-ntp true
$ timedatectl status
```

5）更新为国内镜像源

方法一：

将中国源排在前列，中科大、清华

```bash
$ vim /etc/pacman.d/mirrorlist
```

方法二：

```bash
$ reflector --country China --age 72 --sort rate --protocol https --save /etc/pacman.d/mirrorlist
```

6）通过ssh链接当前主机进行(可选)

1. 在当前安装环境下输入 `passwd`  为当前环境设置一个密码，不用太长，两三位就可以了。输入时不会显示。
2. 执行 `ip -brief address` 查看当前ip地址，一般是 192.168.<...>.<...> IP 地址后面斜杠之后的掩码位不用哦
3. 准备另外一台设备，应当使该设备与安装主机在同一局域网内，就是俩设备都连着同一个 WiFi

几种设备的连接方式：

 Windows：在终端输入：`ssh -o StrictHostKeyChecking=no root@<刚刚查看的 IP 地址>`

 Linux&macOS：在终端输入：`ssh -o StrictHostKeyChecking=no root@<刚刚查看的 IP 地址>`

7）磁盘分区【仅供参考】

方法一：

```bash
$ cfdisk /dev/sda
EFI  分区      300 MB
swap 分区      4GB
root 分区      剩余空间
```

方法二：

```bash
$ fdisk /dev/sda
g // 创建 gpt 格式
n // 创建分区
p // 显示分区情况
w // 保存并退出
EFI  分区      300 MB
swap 分区      4GB
root 分区      剩余空间
```

8）格式化

```bash
$ mkfs.vfat /dev/sda1
$ mkswap /dev/sda2
$ swapon /dev/sda2
$ mkfs.ext4 /dev/sda3
```

9）安装系统

```bash
# 挂载
$ mount /dev/sda3 /mnt
$ mkdir /mnt/boot
$ mount /dev/sda1 /mnt/boot

$ pacstrap /mnt linux linux-firmware linux-headers base base-devel vi vim git bash-completion 
 dhcpcd e2fsprogs iwd
```

10）生成系统表文件

```bash
$ genfstab -U /mnt >> /mnt/etc/fstab
$ cat /mnt/etc/fstab
```

11）进入新系统配置

```bash
$ arch-chroot /mnt

// 时区
$ ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
$ hwclock --systohc

// 系统语言
$ vim /etc/locale.gen
# 将以下两行取消注释
en_US.UTF-8 UTF-8
zh_CN.UTF-8 UTF-8

// 生成本地语言信息
$ locale-gen
// 设置语言环境变量
$ vim /etc/locale.conf
LANG=en_US.UTF-8

// 主机名
$ vim /etc/hostname
archlinux

// hosts
$ vim /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   archlinux.localdomain archlinux

// 安装相关包
$ pacman -S grub efibootmgr efivar networkmanager intel-ucode
$ pacman -S neovim dhcpcd zsh zsh-completions wpa_supplicant iwd sudo netctl
```

12）配置 grub

```bash
$ grub-install /dev/sda
$ grub-mkconfig -o /boot/grub/grub.cfg
```

13）激活启用 NetworkManager

```bash
$ systemctl enable NetworkManager
```

14）设置 root 密码并重启

```bash
$ passwd
$ exit
$ umount /mnt/boot/efi
$ umount /mnt
$ reboot
```

15）联网

方法一：

> 输入 `nmtui` 选择 “Activate a connection” 回车进入，选择你需要的网络，连接后 back 返回即可

方法二：

```bash
$ pacman -Syu wpa_supplicant dhcpcd netctl   // 确保已安装
$ cd /etc/netctl/examples                    // 找示例配置文件
$ ip link set wlan0 up
$ iwlist wlan0 scan | grep ESSID             // 记下无线网卡名称和wifi匹配名称
$ cp /etc/netctl/example/wireless-wpa /etc/netctl/somedescriptivename
$ vim /etc/netctl/somedescriptivename        // 配置ssid\passwd,注意使用权限 chmod 600 禁止非 root 用户访问
$ systemctl enable netctl-auto@wlan0.service // 注意 wifi 名称
$ dhcpcd &
$ ip add
$ ping www.baidu.com
```

注意事项：
当您进入接入点范围时，netctl 将自动连接到 `/etc/netctl` 中的任何配置文件
此设置仅适用于使用 Security=wpa-configsection 和的配置文件 Security=wpa。
禁用所有以前启用的 wifi 配置文件，netctl disable profilename 否则启用 netctl-auto 后，netctl 会在启动时将它们启动两次。

16）开启 ssh 连接

```bash
$ pacman -S openssh
$ systemctl enable sshd
$ ip -brief address

$ vim /etc/ssh/sshd_config
--------------------------------------
# 将下列的语句值改为 yes
PermitRootLogin yes
```

其他终端进行连接

```bash
$ ssh -o StrictHostKeyChecking=no root@<刚刚查看的IP地址>
```

17）配置 base shell 环境变量

```bash
$ vim /etc/skel/.bashrc
-------------------------------
# 在alias行上面添加
export EDITOR=vim

# 继续添加
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'

# 在alias 之后添加脚本
[ ! -e ~/.dircolors ] && eval $(dircolors -p > ~/.dircolors)
[ -e /bin/dircolors ] && eval $(dircolors -b ~/.dircolors)
# 保存退出

$ cp /etc/skel/.bashrc ~
```

18）添加标准用户

```bash
$ useradd --create-home sinath
$ passwd sinath
$ usermod -aG wheel,users,storage,power,lp,adm,optical sinath
$ visudo
//取消注释
%wheel ALL=(ALL) ALL
```

19）添加 ArchlinuxCN 存储库

```bash
$ vim /etc/pacman.conf
--------------------------------------
# 把[multilib]这两行注释删除,再添加源
# 在最后添加
[archlinuxcn]
Server = https://mirrors.ustc.edu.cn/archlinuxcn/$arch   
Server = https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/$arch
$ pacman -Syy
$ pacman -Syu && pacman -S archlinuxcn-keyring
```

**注** ：如果以上更新密钥步骤出现错误，就是那种连着一串 ERROR 的情况，请执行以下步骤

```bash
$ rm -rf /etc/pacman.c/gnupg
$ pacman-key --init
$ pacman-key --populate archlinux archlinuxcn
$ pacman -Syy
```

20）显卡、声卡配置

```bash
# 检查显卡
$ lspci | grep -e VGA -e 3D

# 不同显卡驱动---核显不用安装(可略)
$ sudo pacman -S nvidia nvidia-utils # NVIDIA 
$ sudo pacman -S xf86-video-amdgpu   # AMD
$ sudo pacman -S xf86-video-intel    # Intel

$ pacman -S xf86-video-intel vulkan-intel mesa
$ pacman -S alsa-utils pulseaudio pulseaudio-bluetooth cups
```

21）安装字体

```bash
$ sudo pacman -S adobe-source-code-pro-fonts adobe-source-han-serif-cn-fonts wqy-zenhei wqy-microhei noto-fonts-cjk noto-fonts-emoji noto-fonts-extra
```

打开字体引擎

```bash
$ vim /etc/profile.d/freetype2.sh
--------------------------------------------
# 取消注释最后一句
export FREETYPE_PROPERTIES="truetype:interpreter-version=40"
```

22）桌面环境

- 安装 Display Server【开源】

```bash
$ pacman -S xorg xorg-server xorg-xinit
可选
$ cp /etc/X11/xinit/xinitrc ~/.xinitrc
// 注释 #twm & 以下内容
最后添加
exec i3
```

- 安装 Display Manager

```bash
// Gnome
$ pacman -S gdm
// KDE
$ pacman -S sddm
// Xfce|DDE
$ pacman -S lightdm lightdm-gtk-greeter
```

设置开机自启

```bash
$ systemctl enable gdm
// 使用哪个就将 gdm 替换成安装的 dm
```

- 安装i3

```bash
$ pacman -S i3
$ pacman -S i3-gaps i3blocks i3lock i3status //可选
```

修改配置文件

```bash
$ vim ~/.config/i3/config
修改默认的 mod 快捷键，默认是 windows 键，改为 Alt 键
把 set $mod Mod4 改为 set $mod Mod1

默认 i3 的快捷键冲突了，修改配置文件，搜索+d,注释掉第二个
bindsym $mod+d exec --no-startup dmenu run
bindsym $mod+d exec --no-startup-id i3-dmenu-desktop
```

23）软件

- 输入法

```bash
$ sudo pacman -S fcitx5-im fcitx5-chinese-addons fcitx5-rime fcitx5-configtool
$ sudo vim ~/.pam_environment
# 添加以下内容
INPUT_METHOD  DEFAULT=fcitx5
GTK_IM_MODULE DEFAULT=fcitx5
QT_IM_MODULE  DEFAULT=fcitx5
XMODIFIERS    DEFAULT="@im=fcitx5"
# 配置环境变量
$ sudo vim ~/.xprofile
export GTK_IM_MODULE=fcitx5
export QT_IM_MODULE=fcitx5
export XMODIFIERS=@im=fcitx
fcitx5 &

$ vim ~/.config/i3/config
# Autostart applictions
exec --no-startup-id fcitx
```

- 仿终端

```bash
$ sudo pacman -S alacritty
$ vim ~/.config/i3/config
# start a terminal 修改默认终端
bindsym $mod+Return exec alacritty

$ alacritty --version
$ sudo mkdir ~/.config/alacritty
$ cd ~/.config/alacritty
$ wget https://github.com/alacritty/alacritty/releases/download/v0.9.0/alacritty.yml
$ vim alacritty.yml
background_opacity: 0.8 // 背景透明度
```

- 窗口透明

```bash
$ sudo pacman -S picom
$ vim ~/.config/i3/config
$ exec_always --no-startup-id picom -b
$ cp /etc/xdg/picom.conf .
$ sudo vim ~/.config/picom.conf
# Opacity
inactive-opacity = 0.7;
active-opacity = 0.9;
```

- 浏览器

```bash
$ sudo pacman -S firefox 
$ yay -S google-chrome
$ vim ~/.config/i3/config
bindsym $mod+F2 exec google-chrome-stable
bindsym $mod+F3 exec firefox
```

- 压缩软件

```bash
$ sudo pacman -S unrar unzip p7zip
```

- 文件管理器

```bash
$ sudo pacman -S pcmanfm  // 图形文件管理器
$ sudo pacman -S ranger   // 命令行文件管理器
```

- 状态栏

```bash
$ sudo pacman -S polybar
$ sudo mkdir ~/.config/polybar
$ cp /usr/share/doc/polybar/config $HOME/.config/polybar/config
$ sudo touch $HOME/.config/polybar/config/launch.sh
$ sudo chmod +x launch.sh
$ vim launch.sh
#!/bin/bash

# 终端可能已经有在运行的实例
killall -q polybar
# 等待进程被终止
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done
# 运行Polybar，使用默认的配置文件路径 ~/.config/polybar/config
polybar mybar &

echo "Polybar runing..."
```

注释 i3 自带的 bar 或 i3blocks 配置使用 polybar 启动脚本启动 polybar

```bash
$ vim ~/.config/i3/config
// 增加开机启动脚本
exec_always --no-startup-id $HOME/.config/polybar/launch.sh
// 注释原 bar
#bar {
#	i3bar_command i3bar --transparency
#	status_command i3blocks
#	position top
#	colors {
#		background #9370DB3F
#		separator #778899
#			# 使用RGBA颜色  #边界 背景 文本
#		focused_workspace  	#778899A5 #87CEEBA5 #FFFAFAF5
#		inactive_workspace 	#7788993F #AFEEEE3F #FFFAFAF5
#		urgent_workspace   	#80808072 #FF450072 #FFFAFAF5
#    }
#}
```

polybar 配置参考

```bash
$ vim ~/.config/polybar/config
[colors]
background = #b0222222  // 修改背景透明
[bar/mybar]             // 修改成自身 bar
modules-right = alsa eth cpu memory date bluetooth // 状态栏显示字体
[module/eth]            // 有线/无线网卡名称
interface = enp4s0f0
```

- rofi 快捷启动(dmenu)

```bash
sudo pacman -S rofi
bindsym $mod+d exec --no-startup-id rofi -show drun //(可选)
bindsym $mod+space --release exec "rofi -combi-modi drun,window,ssh -show combi -modi combi"
```

- feh 墙纸

```bash
$ sudo pacman -S feh
$ mkdir ~/Pictures/backgrounds  //壁纸保存路径
$ ls /usr/bin/feh
$ mkdir -p ~/.config/feh
$ vim ~/.config/wallpic.sh
#!/bin/sh

while true; do
    find ~/Pictures/backgrounds/ -type f \( -name '*.jpg' -o -name '*.png' \) -print0 |
        shuf -n1 -z | xargs -0 feh --bg-scale
    sleep 15m
done
$ chmod +x wallpic.sh

$ vim ~/.config/i3/config
exec --no-startup-id feh --randomize --big-fill ~/Pictures/backgrounds/*
exec_always --no-startup-id $HOME/.config/feh/wallpic.sh
```

- ohmyzsh终端

```bash
# 设置终端
$ cat /etc/shells      # 查看系统所有shell
$ chsh -s /usr/bin/zsh # 更改默认shell为zsh

# 安装ohmyzsh
wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | sh
# 安装插件
# zsh-syntax-highlighting：语法高亮
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting
# autosuggestions：记住用过的命令
git clone git://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions

# 修改主题，这里使用的主题是 powerlevel10k，详细信息可从 Github 找到
$ git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k

$ sudo vim ~/.zshrc                       # 修改配置文件
ZSH_THEME="powerlevel10k/powerlevel10k"   # 更改ZSH_THEME
plugins=(git                              # 更改plugins
       zsh-autosuggestions
       zsh-syntax-highlighting
       sudo
       extract
     )

export LC_ALL=en_US.UTF-8
export LANG=EN_US.UTF-8

$ source ~/.zshrc                         # 刷新配置,打开终端按提示进行配置即可
```

- 截图软件

```bash
$ sudo pacman -S flameshot
$ sudo vim ~/.config/i3/config
# 添加截图快捷方式
bindsym Print --release exec /usr/bin/flameshot gui
# for_window [class="flameshot"] floating enable 
exec --no-startup-id flameshot
```

- i3配置文件
```bash
# 设置窗口边框等等
new_window none
new_float normal
hide_edge_borders both

# 设置窗口间距
gaps inner 8
gaps outer 6

# screen before suspend. Use loginctl lock-session to lock your screen.
exec --no-startup-id xss-lock --transfer-sleep-lock -- i3lock --nofork

# Use pactl to adjust volume in PulseAudio.
set $refresh_i3status killall -SIGUSR1 i3status
bindsym XF86AudioRaiseVolume exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ +10% && $refresh_i3status
bindsym XF86AudioLowerVolume exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ -10% && $refresh_i3status
bindsym XF86AudioMute exec --no-startup-id pactl set-sink-mute @DEFAULT_SINK@ toggle && $refresh_i3status
bindsym XF86AudioMicMute exec --no-startup-id pactl set-source-mute @DEFAULT_SOURCE@ toggle && $refresh_i3status
```