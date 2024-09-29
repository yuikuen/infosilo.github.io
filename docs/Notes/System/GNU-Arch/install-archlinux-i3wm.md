之前已介绍过 ArchLinux 系统的基本安装，Arch 系统默认是没有配置桌面环境的，本文介绍的是 i3wm 的简单美化和基本配置，并附加常用的软件安装，仅供参考！

## 一. 安装驱动

1）确认显卡型号，并安装对应驱动

```sh
$ lspci | grep -e VGA -e 3D
```

2）根据型号规格，安装 [官方仓库](https://wiki.archlinux.org/title/Xorg) 提供的驱动包（此处我安装的是通用版本）

```sh
$ sudo pacman -S xf86-video-vesa
```

提示：`Nvidia` 的独显驱动如非必要，建议只装集成显卡的驱动（省电，如果同时装也会默认使用集成显卡），不容易出现冲突问题。相反，如果集成显卡驱动有问题无法装上，可以装独显驱动，具体的版本请自行参考

## 二. 安装视窗

### 2.1 安装 Xorg

`Xorg` 是 Linux 下一个著名的开源图形服务，桌面环境需要 `Xorg` 的支持

```sh
$ sudo pacman -S xorg xorg-server xorg-xprop
```

`Linux` 下有很多著名的桌面环境如 `Xfce`、`KDE(Plasma)`、`Gnome`、`Unity`、`Deepin` 等等，它们的外观、操作、设计理念等各方面都有所不同， 在它们之间的比较与选择网上有很多的资料可以去查

### 2.2 安装 Startx

1）启动登陆器可选择 gdm / sddm / lightdm，也可使用 xorg-xinit 启动，这里选择后者

```sh
$ sudo pacman -S xorg-xinit
```

2）使用普通用户创建配置文件 `~/.xinitrc`

```sh
$ sudo cp /etc/X11/xinit/xinitrc ~/.xinitrc
# 从twm &开始，以下全注释或删除处理，并添加启动项
- twm &
- ...
+ exec i3
```

### 2.3 安装 i3-gaps

> i3wm 有好几个软件包，这里使用的是 i3-gaps，属于 i3wm 的一个分支，提供了更多的特性

```sh
$ sudo pacman -S i3-gaps i3lock
```

### 2.4 安装 Libinput

> 触摸板设置，具体可参考 [官方 Wiki](https://wiki.archlinux.org/title/Libinput)

1）安装依赖，如已安装 **Xorg** 或 **Wayland**，则无需要额外安装

```sh
# 选一即可
$ sudo pacman -S xf86-input-libinput
$ sudo pacman -S libinput
```

2）获取触摸板 id

```sh
$ xinput list | grep -i touchpad
```

3）编写简单配置文件

```sh
$ sudo vim /etc/X11/xorg.conf.d/30-touchpad.conf
Section "InputClass"
    Identifier "touchpad"
    Driver "libinput"
    MatchIsTouchpad "on"
    Option "Tapping" "on"
    Option "TappingButtonMap" "lmr"
EndSection
```

提示：如需更多自定制设置可参考如下例子

```sh
$ sudo vim /etc/X11/xorg.conf.d/40-libinput.conf
Section "InputClass"
        Identifier "touchpad"
        MatchIsTouchpad "on"
        MatchDevicePath "/dev/input/event*"
        Driver "libinput"
        Option "Tapping" "True"
        Option "TappingButtonMap" "lrm"
        Option "DisableWhileTyping" "True"
        Option "TappingDrag" "True"
        Option "NaturalScrolling" "True"
        Option "SendEventsMode" "disabled-on-external-mouse"
EndSection
```

**常用选项：**

1. 当检测到 USB 鼠标时，它将禁用触摸板

   Option "SendEventsMode" "disabled-on-external-mouse"

2. 允许单指和双指触击分别调用鼠标左右键，而不用按触控板的物理按键

   Option "Tapping" "True"

3. 防止打字时误触触控板

   Option "DisableWhileTyping" "True"

4. 触摸板不再拥有区域的区分，与之代替的是双指代表右键，三指代表中键

   Option "ClickMethod" "clickfinger"

5. 轻击后手指按住会使单个按钮关闭，此手指的所有动作都将转换为拖动动作

   Option "TappingDrag" "True"

6. 自然滚动（反方向滚动）

   Option "NaturalScrolling" "True"

7. 启用鼠标加速配置文件。这有助于使鼠标手指的速度更自然一些，迟钝感更小。建议使用 Adaptive，因为其会根据您的输入更改。您也可以尝试 “flat” 选项

   Option "AccelProfile" "adaptive"

8. 更改鼠标指针的加速速度。使用 -1 到 1 之间的值。数值越大，指针移动的速度越高。大多数人倾向于使用 0.2 以获得较慢的响应速度，使用 0.5 获得较快的响应速度

   Option "AccelSpeed" "0.3"


### 2.5 启动服务

1）上述配置后，即可启动 `Xorg` 服务

```sh
$ startx
```

提示：根据提示信息进行设置 Mod 默认键位是否为 Win(Super) 或 Alt，确认后回车自动生成配置文件

2）配置登录后自启动脚本

```sh
$ vim ~/.bash_profile
if [ -z "${DISPLAY}" ] && [ "${XDG_VTNR}" -eq 1 ]; then
	exec startx
fi
```

可重启电脑进行测试是否登录自启动，此时右下角可能会提示报错，因为状态栏信息未正常显示，可忽略待后面解决。

## 三. 快捷按键

> 常用快捷键如下，详细请自行参考 [官方介绍](https://i3wm.org/docs/userguide.html)

| 快捷键          | 功能                  |
| --------------- | --------------------- |
| Alt+Shift+E     | 退出 i3wm 桌面        |
| Alt+Shift+C     | 重新加载配置          |
| Alt+Shift+R     | 重启 i3wm 桌面        |
| Alt+Shift+Q     | 退出当前窗体          |
| Alt+Shift+Blank | 浮动/排列切换         |
| Alt+Num         | 切换 workspace 工作区 |
| Alt+Enter       | 打开终端 Terminal     |
| Alt+F           | 当前窗体全屏          |
| Alt+D           | 打开管理程序          |
| Alt+E           | 横向纵向切换          |
| Alt+W           | 标签形式              |
| Alt+R           | Resize                |
| Alt+JKL;        | 光标移动（左下上右）  |

## 四. 基本美化

> Arch i3wm 已安装完毕，简单美化和基本配置可参考下述操作，仅供参考

首先安装一些基本的工具，后期美化可自行定制

```sh
$ sudo pacman -S alacritty rofi feh picom firefox polybar
```

### 4.1 安装字体

安装中文字体，确保不会出现乱码的情况

```sh
$ sudo pacman -S ttf-dejavu wqy-zenhei adobe-source-code-pro-fonts
```

### 4.2 配置终端

1）将终端服务的启动项改为 **alacritty**，关闭窗体快捷键改为 `$mod+q` (可略)

```sh
$ sudo vim ~/.config/i3/config
# start a terminal
bindsym $mod+Return exec alacritty

# kill focused window
bindsym $mod+q kill
```

2）根据 `alacritty` 版本，下载对应的配置文件

```sh
$ alacritty --version
alacritty 0.10.1 ()

$ sudo mkdir ~/.config/alacritty 
$ cd ~/.config/alacritty 
$ wget https://github.com/alacritty/alacritty/releases/download/v0.10.1/alacritty.yml
```

3）修改配置文件，自行定制终端样式

```yaml
$ vim ~/.config/alacritty/alacritty.yml
# 窗体配置
window:
  # 窗口比例 16:9
  dimensions:
    columns: 120
    lines: 30
  # 窗体边缘空白
  padding:
    x: 10
    y: 10
  dynamic_padding: false
  # 窗口修饰
  decorations: none
  # 背景透明度
  opacity: 0.8
  # 启动窗体样式
  startup_mode: Windowed
scrolling:
  # 历史保留行数
  history: 2000
  # 每次滚动行数
  multiplier: 20
# 实时重载配置，不用重启
live_config_reload: true
shell:
  program: /bin/bash
  args:
    - -l
```

提示：还可以修改字体、主题颜色等，都可自行定制

### 4.3 快捷启动

将默认的程序启动器进行注释，添加 rofi 的快捷启动方式

```sh
$ sudo vim ~/.config/i3/config
# start dmenu (a program launcher)
# bindsym $mod+d exec --no-startup-id dmenu_run
bindsym $mod+d exec rofi -show run 
```

注：主题修改直接 `$mod+d` 输入 rofi 选择 `rofi-theme-selector`，上下选择可预览主题，按提示 `Alt+a` 确认设置

### 4.4 背景壁纸

配置 feh 自动读取指定目录文件

```sh
$ sudo mkdir Wallpaper
$ sudo vim ~/.config/i3/config
# 额外添加wallpaper
exec_always feh --randomize --bg-fill $HOME/Wallpaper/
```

提示：上面虽然已设置背景切换功能，但只有登录或刷新 i3 配置方可切换壁纸，可使用脚本实现定时切换壁纸

```sh
$ sudo mkdir ~/.config/feh/wallpic.sh
$ sudo vim ~/.config/feh/wallpic.sh
#!/bin/sh
while true; do
    find $HOME/Wallpaper/ -type f \( -name '*.jpg' -o -name '*.png' \) -print0 |
        shuf -n1 -z | xargs -0 feh --bg-scale
    sleep 15m
done
$ sudo chmod +x ~/.config/feh/wallpic.sh
```

```sh
$ sudo vim ~/.config/i3/config
exec_always --no-startup-id $HOME/.config/feh/wallpic.sh
```

### 4.5 窗口透明

通过 Picom 修改窗口透明度 & 模糊效果，更多配置可参考 [官方 Wiki](https://wiki.archlinux.org/title/Picom)

```sh
$ sudo cp /etc/xdg/picom.conf ~/.config

$ sudo vim ~/.config/i3/config
# 额外添加opacity
exec_always picom -f -b

$ vim ~/.config/picom.conf
inactive-opacity = 0.7;
active-opacity = 0.9;
```

### 4.6 服务状态

之前未安装/配置 i3status，所以导致报错，此处使用 [Polybar](https://wiki.archlinux.org/title/Polybar) 进行定制

```sh
$ sudo mkdir -p ~/.config/polybar

# 根据官方教程进行配置，复制模版文件并创建启动脚本
$ sudo cp /usr/share/doc/polybar/examples/config.ini $HOME/.config/polybar/
$ sudo vim ~/.config/polybar/launch.sh
#!/bin/bash

# Terminate already running bar instances
killall -q polybar
# If all your bars have ipc enabled, you can also use
# polybar-msg cmd quit

# Launch Polybar, using default config location ~/.config/polybar/config.ini
polybar mybar 2>&1 | tee -a /tmp/polybar.log & disown

echo "Polybar launched..."
```

授权脚本文件，将原 i3status 配置注释并添加 polybar 启动项

```sh
$ chomd +x ~/.config/polybar/launch.sh

$ sudo vim ~/.config/i3/config
# 注释原i3status,额外添加polybar
# bar {
#     status_command i3status
# }
exec_always ~/.config/polybar/launch.sh
```

提示：脚本文件中的 `polybar mybar` 需要与 `~/.config/polybar/config.ini` 中的 `[bar/example]` 配置一样

```sh
$ sudo vim ~/.config/polybar/config.ini
# 将example改为脚本的mybar
[bar/mybar]
```

至此 ArchLinux 安装及基本美化已完成，后续优化请自行度娘。

## 五. 额外配置

> 此为进行一步定制，请根据个人需求安装，无须盲从

### 5.1 电源管理

```sh
$ sudo pacman -S acpi acpid
$ sudo vim ~/.config/polybar
# 增加
```

### 5.2 音量管理

```sh
$ sudo pacman -S alsa alsa-utils kmix
$ sudo vim ~/.config/i3/config
# amixer音量调整
bindsym $mod+F1 exec amixer set Master toggle
bindsym $mod+F2 exec amixer set Master 1%-
bindsym $mod+F3 exec amixer set Master 1%+
```

### 5.3 蓝牙配置

```sh
# 蓝牙协议
$ sudo pacman -S bluez bluez-utils
$ sudo pacman -S enable bluetooth
# 蓝牙音频
$ sudo pacman -S pulseaudio-bluetooth
# 蓝牙图形管理工具
$ sudo pacman -S blueman
```

## 六. 常用软件

软件工具请根据自身使用进行安装，无须全部安装

### 6.1 输入法

> 输入法工具：五笔拼音 & 拼音

1）安装中文输入法及管理工具

```sh
$ sudo pacman -S fcitx5-im fcitx5-chinese-addons fcitx5-rime fcitx5-configtool
```

2）配置环境变量，使其开机自启服务

```sh
$ sudo vim ~/.bash_profile
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
export INPUT_METHOD=fcitx
export SDL_IM_MODULE=fcitx

$ sudo vim ~/.pam_environment
INPUT_METHOD  DEFAULT=fcitx5
GTK_IM_MODULE DEFAULT=fcitx5
QT_IM_MODULE  DEFAULT=fcitx5
XMODIFIERS    DEFAULT="@im=fcitx5"

$ sudo vim ~/.xinitrc
# 在 exec 上面添加 fcitx5 启动项
fcitx5 -d &
exec i3
```

注：安装后需自行 `Alt+D` 打开 `fcitx5-configtool` 进行设置，将输入法添加到列表当中，并启用配置；

### 6.2 远程服务

**sshd命令** 是 OpenSSH 软件套件中的服务器守护进程

```sh
$ sudo pacman -S net-tools openssh
$ sudo systemctl start sshd
$ sudo systemctl enable sshd
```

### 6.3 内网互联

> **WireGuard** 服务端请自行搭建，此为 Laptop(home-pc) 配置

```sh
$ sudo modprobe wireguard
$ sudo pacman -S wireguard-tools

$ sudo touch /etc/wireguard/wg0.conf
$ sudo vim /etc/wireguard/wg0.conf
[Interface]
Address = 6.6.3/24
PrivateKey = home-pc_PrivateKey

[Peer]
PubicKey = WireGuard_Server-PubicKey
AllowedIPs = 6.6.6.0/24,192.168.1.0/24
Endpoint = Public network ip:port
PersistentKeepalive = 15

$ sudo systemctl start wg-quick@wg0
$ sudo systemctl enable wg-quick@wg0
$ sudo systemctl status wg-quick@wg0
$ sudo wg
```

## 七. 安装工具

```sh
$ sudo pacman -S yay
```

### 7.1 浏览冲浪

```sh
$ yay -S google-chrome
$ sudo pacman -S firefox
$ sudo vim ~/.config/i3/config
# Web
bindsym $mod+F1 exec google-chrome-stable
bindsym $mod+F2 exec firefox
```

### 7.2 压缩工具

```sh
$ sudo pacman -S unrar unzip p7zip
```

### 7.3 文件管理

```sh
$ sudo pacman -S pcmanfm  //图形文件管理器
$ sudo pacman -S ranger   //命令行文件管理器
```

`ranger` 是一个在终端中使用的文件管理器，具备搜索、查找、文件预览、文件编辑、标签页、鼠标点击等操作，快捷键和 `vim` 类似

1）启动之后 ranger 会创建一个目录 `~/.config/ranger`

```sh
$ cd ~/.config/ranger
# 使用以下命令复制默认配置文件到这个目录
$ ranger --copy-config=all
```

- `rc.conf`-选项设置和快捷键
- `commands.py`-能通过`:`执行的命令
- `commands_full.py`-全套命令
- `rifle.conf`-指定不同类型的文件的默认打开程序
- `scope.conf`-负责各种文件预览

注意：如果要使用 `~/.config/ranger` 目录下的配置生效，需要把 `RANGER_LOAD_DEFAULT_RC` 变量设置为 `false`

```sh
bash
$ echo "export RANGER_LOAD_DEFAULT_RC=false" >> ~/.bashrc

zsh
$ echo "export RANGER_LOAD_DEFAULT_RC=false" >> ~/.zshrc
```

修改配置文件`~/.config/ranger/rc.conf`

- 显示边框 `set draw_borders both`
- 显示序号 `set line_numbers true`
- 序号从1开始 `set one_indexed true`

### 7.4 编程工具

```sh
$ yay -S visual-studio-code-bin
```