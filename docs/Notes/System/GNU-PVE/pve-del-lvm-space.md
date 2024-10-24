> PVE 删除 LVM 空间并合并至 Local

**PVE 主分区结构**

首先查看默认安装的磁盘，是一个基于 LVM 的结构

```sh
root@pve:~# fdisk -l
Disk /dev/sda: 111.8 GiB, 120040980480 bytes, 234455040 sectors
Disk model: WDC WDS120G2G0A-
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: gpt
Disk identifier: 9497030A-2F67-430E-821D-215271DB042F

Device       Start       End   Sectors   Size Type
/dev/sda1       34      2047      2014  1007K BIOS boot
/dev/sda2     2048   1050623   1048576   512M EFI System
/dev/sda3  1050624 234455006 233404383 111.3G Linux LVM
```

- pve-root      根目录
- pve-swap    虚拟内存
- pve-data     磁盘镜像储存

```sh
root@pve:~# lsblk 
NAME               MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
sda                  8:0    0 111.8G  0 disk 
├─sda1               8:1    0  1007K  0 part 
├─sda2               8:2    0   512M  0 part /boot/efi
└─sda3               8:3    0 111.3G  0 part 
  ├─pve-swap       253:0    0     8G  0 lvm  [SWAP]
  ├─pve-root       253:1    0  37.8G  0 lvm  /
  ├─pve-data_tmeta 253:2    0     1G  0 lvm  
  │ └─pve-data     253:4    0  49.6G  0 lvm  
  └─pve-data_tdata 253:3    0  49.6G  0 lvm  
    └─pve-data     253:4    0  49.6G  0 lvm
```

**LVM-Data**

LVM 中，还建了一个 thinpool，名为 data，可参考 [LVM存储虚拟化_Thin-provisioned](https://wenku.baidu.com/view/505a8d77834d2b160b4e767f5acfa1c7aa0082cb.html?_wkts_=1679033078665&bdQuery=LVM%E5%AD%98%E5%82%A8%E8%99%9A%E6%8B%9F%E5%8C%96_Thin-provisioned)

LVM-thin 可实现类似于 vSphere 的精简置备或进行快照，快速调整空间

```sh
root@pve:~# lvs
  LV   VG  Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  data pve twi-a-tz-- <49.59g             0.00   1.59                            
  root pve -wi-ao----  37.82g                                                    
  swap pve -wi-ao----   8.00g
```

**Local**

通过查看存储配置文件，Local 是作为一个 dir 类型的目录，用来存放 ISO，备份文件，而 Local-LVM 是 LVM-thin，用来存储虚拟机磁盘

```sh
root@pve:~# cat /etc/pve/storage.cfg 
dir: local
        path /var/lib/vz
        content iso,vztmpl,backup

lvmthin: local-lvm
        thinpool data
        vgname pve
        content rootdir,images
```

LVM 等同于动态调整磁盘空间，例如根目录小了，可缩小 LVM-thin 的空间，然后扩大到根目录

**删除 LVM-thin**

> 注意！先确保并没虚拟机位于 LVM-thin，若有则先移动到 Local

1）编辑 Local，勾选所有内容并确认

![](https://img.17121203.xyz/i/2024/10/24/qkatuo-0.webp)

2）使用命令删除 LVM-thin

```sh
root@pve:/dev/pve# ls /dev/pve/
data  root  swap
root@pve:/dev/pve# lvremove /dev/pve/data 
Do you really want to remove active logical volume pve/data? [y/n]: y
  Logical volume "data" successfully removed
```

再将 LVM-thin 的空间转移到 pve-root，`+100%FREE` 可指定容量大小，如 `+30G`

```sh
root@pve:/dev/pve# lvextend -rl +100%FREE /dev/pve/root
  Size of logical volume pve/root changed from 37.82 GiB (9683 extents) to 103.29 GiB (26443 extents).
  Logical volume pve/root successfully resized.
resize2fs 1.46.5 (30-Dec-2021)
Filesystem at /dev/mapper/pve-root is mounted on /; on-line resizing required
old_desc_blocks = 5, new_desc_blocks = 13
The filesystem on /dev/mapper/pve-root is now 27077632 (4k) blocks long.
```

使用命令查看，根目录已经扩大了

```sh
root@pve:/dev/pve# df -Th
Filesystem           Type      Size  Used Avail Use% Mounted on
udev                 devtmpfs  126G     0  126G   0% /dev
tmpfs                tmpfs      26G  2.0M   26G   1% /run
/dev/mapper/pve-root ext4      102G  3.7G   94G   4% /
tmpfs                tmpfs     126G   46M  126G   1% /dev/shm
tmpfs                tmpfs     5.0M     0  5.0M   0% /run/lock
/dev/sda2            vfat      511M  336K  511M   1% /boot/efi
/dev/fuse            fuse      128M   16K  128M   1% /etc/pve
/dev/sdb1            ext4      440G   28K  417G   1% /mnt/ssd-480g
tmpfs                tmpfs      26G     0   26G   0% /run/user/0
```

3）删除 LVM-thin 之后，可在网页上删除 LVM-thin(数据中心->存储->删除 local-lvm)

```sh
root@pve:~# tree /var/lib/vz
/var/lib/vz
├── dump           # 备份文件
├── images         # 虚拟机磁盘
├── private
├── snippets       # 片段
└── template
    ├── cache      # 容器模板
    └── iso        # ISO镜像目录
        └── CentOS-7-x86_64-Minimal-2207-02.iso
```

![](https://img.17121203.xyz/i/2024/10/24/qkfwlg-0.webp)