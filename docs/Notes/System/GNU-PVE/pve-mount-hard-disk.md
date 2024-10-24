> PVE 挂载硬盘

在 PVE 中除了已安装 PVE 的硬盘外，其他硬盘都是需要手动挂载，并且 Web 面板只能添加新盘，无法添加已格式化的硬盘，除非将它初始化一次，这点就不如 ESXI 方便

## 一. 挂载新盘

> 机械与固态操作方式一样

实验场景：现除了安装 PVE 的硬盘 `/dev/sda` 外，还有一个 ssd 480G 的硬盘 `/dev/sdb`，其为 NTFS 格式(原 Win 磁盘)，现需要在 PVE 下使用作为新的磁盘目录来使用；

![](https://img.17121203.xyz/i/2024/10/24/ps76yu-0.webp)

1）首先通过 Web 的 Shell 进行格式化操作

```sh
$ cd /dev ;ls 
$ fdisk /dev/sdb
```

![](https://img.17121203.xyz/i/2024/10/24/psczu8-0.webp)

fdisk 是一个 linux 下的分区工具，因要作新磁盘使用，首先按照提示，进行删除分区，并创建一个新分区

> 输入 d 删除分区，再输入 n 创建新分区，分区数根据具体需要填写数量，分区起始&终止按需分配，建好分区后，按 w 回车保存上述操作

```sh
Command (m for help): n
Partition number (1-128, default 1): 
First sector (34-937703054, default 2048): 
Last sector, +/-sectors or +/-size{K,M,G,T,P} (2048-937703054, default 937703054): 

Created a new partition 1 of type 'Linux filesystem' and of size 447.1 GiB.

Command (m for help): w
The partition table has been altered.
Calling ioctl() to re-read partition table.
Syncing disks.
```

2）分区创建后需要格式化方可使用

```sh
$ mkfs -t ext4 /dev/sdb1
Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (262144 blocks): done
Writing superblocks and filesystem accounting information: done
```

常用硬盘格式为 ext2、ext3、ext4、reiserfs、fat32、msdos 等，可 `mkfs -h` 查看具体用法

3）目录挂载，在 `/mnt` 下创建一个文件夹(可自定义)，[fstab 文件详解可参考此文](https://blog.csdn.net/carefree2005/article/details/125632867)

```sh
$ mkdir -p /mnt/ssd-480g
$ mount -t ext4 /dev/sdb1 /mnt/ssd-480g
$ echo /dev/sdb1 /mnt/ssd-480g ext4 defaults 1 2 >> /etc/fstab
```

![](https://img.17121203.xyz/i/2024/10/24/qgty8c-0.webp)

fs_spec 字段可使用设备文件名、UUID 或标签，也可是 NFS 等远程文件系统，其注意事项如下:
- 设备文件名会在当前生效，但有可能在系统重启之后出现问题，如系统存在多磁盘情况；
- Label 在系统重启后也会生效，但 Label 是在磁盘分区时设置的标签，多磁盘时会有可能会有飘移情况；
- UUID 是分区的唯一标识，建议使用此方式进行挂载，而远程文件配置方式是 <host>:<dir>，与 mount 命令挂载是一致的，UUID 和 LABEL 配置方式则是 LABEL=<label> 或 UUID=<uuid>

```sh
root@pve:~# blkid 
/dev/sdb1: UUID="b3aa2620-7c85-4b5d-82ea-a3f240e6c8f5" BLOCK_SIZE="4096" TYPE="ext4" PARTUUID="50eeeebc-01"
```

可使用 `blkid` 命令查看，或使用 `ls -l /dev/disk/by-label`，如未配置标签，`by-label` 文件可能不存在

```sh
root@pve:~# ls -l /dev/disk/by-
by-id/       by-partuuid/ by-path/     by-uuid/ 

root@pve:~# df -Th
Filesystem           Type      Size  Used Avail Use% Mounted on
udev                 devtmpfs  126G     0  126G   0% /dev
tmpfs                tmpfs      26G  2.0M   26G   1% /run
/dev/mapper/pve-root ext4      102G  5.8G   92G   6% /
tmpfs                tmpfs     126G   46M  126G   1% /dev/shm
tmpfs                tmpfs     5.0M     0  5.0M   0% /run/lock
/dev/sda2            vfat      511M  336K  511M   1% /boot/efi
/dev/fuse            fuse      128M   16K  128M   1% /etc/pve
/dev/sdb1            ext4      440G   56K  417G   1% /mnt/ssd-480g
tmpfs                tmpfs      26G     0   26G   0% /run/user/0

root@pve:~# cat /etc/fstab 
# <file system> <mount point> <type> <options> <dump> <pass>
/dev/pve/root / ext4 errors=remount-ro 0 1
UUID=7436-39E2 /boot/efi vfat defaults 0 1
/dev/pve/swap none swap sw 0 0
proc /proc proc defaults 0 0
/dev/sdb1 /mnt/ssd-480g ext4 defaults 1 2
```

4）上述设置好后，需要回到 PVE-Web 操作

> 数据中心 –> 存储 –> 添加，填写刚挂载的磁盘

![](https://img.17121203.xyz/i/2024/10/24/qhey2k-0.webp)

ID 自定义，目录则填写刚挂载的目录，内容建议全部选上，支持 PVE 所有存储内容，最后在 PVE 下会有一个新的存储。

## 二. 挂载旧盘

> 添加已有数据的硬盘为存储，PVE-Web 只能添加新盘，无法添加已格式化的硬盘，除非将其初始化一次

实验场景：有一块磁盘(多个分区)，原在 Win 系统下使用，同样为 NFS 格式，现需要将其挂载至 PVE 作存储使用并保留原数据

1）安装驱动包并挂载分区

```sh
$ lsblk -f /dev/sdb

# 因挂载nfs需要额外安装驱动包
$ apt update && apt install ntfs-3g

# 例子：挂载分区2
$ mkdir -p /mnt/hdd2
$ mount /dev/sdb2 /mnt/hdd2
```

2）如有下面提示，需要修复一下，再重新挂载

```sh
The disk contains an unclean file system (0, 0).
Metadata kept in Windows cache, refused to mount.
Falling back to read-only mount because the NTFS partition is in an
unsafe state. Please resume and shutdown Windows fully (no hibernation
or fast restarting.)
Could not mount read-write, trying read-only

$ ntfsfix /dev/sdb2
$ umount /dev/sdb2
$ mount /dev/sdb2 /mnt/hdd2
```

3）同样最后进行 PVE-Web 添加目录存储，ID随便取，目录填写硬盘的挂载路径，内容全部勾选

![](https://img.17121203.xyz/i/2024/10/24/qi0ur4-0.webp)

4）最后设置永久挂载，开机自启动

```sh
root@pve:~# blkid
/dev/sdb1: UUID="b3aa2620-7c85-4b5d-82ea-a3f240e6c8f5" BLOCK_SIZE="4096" TYPE="ext4" PARTUUID="50eeeebc-01"
```

将 PARTUUID 或 UUID 写入 fstab，另将常规 defaults 选项换成 `nofail,x-systemd.device-timeout=15s`，防止找不到硬盘

![](https://img.17121203.xyz/i/2024/10/24/qifv74-0.webp)