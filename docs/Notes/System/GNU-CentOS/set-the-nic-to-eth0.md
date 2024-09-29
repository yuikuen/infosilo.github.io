> Esxi/PVE 安装 Linux 虚拟机时，设置默认网卡为 Eth0

- 开机到 `install CentOS` 界面
- 按键盘 Tab 键
- 最后处输入 `net.ifnames=0 biosdevname=0`
- 回车继续安装，安装完成后网卡名称会设置为 eth0
