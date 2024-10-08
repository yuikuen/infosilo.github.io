> 修改 Ubuntu 默认网卡名称为 Eth0

Ubuntu 虚拟机安装后，默认的以太网网卡不是 eth0，可通过修改 GRUB 配置进行修改

1）修改 GRUB 配置文件

```sh
sudo vim /etc/default/grub
# 按下添加内容
GRUB_CMDLINE_LINUX="net.ifnames=0 biosdevname=0"
```

2）配置使其生效

```sh
sudo grub-mkconfig -o /boot/grub/grub.cfg
sudo reboot
```