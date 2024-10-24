> PVE 虚拟主机磁盘扩容
>
> 由于已创建的虚拟机开始磁盘空间设置得太小了，后续服务增加后导致磁盘空间不足，为了保证服务的正常使用，对虚拟机进行磁盘扩容

1）**PVE 磁盘映像扩容**：首先需要在 PVE 管理后台对目标虚拟机的磁盘映像进行扩容，操作步骤如下：

- 选中目标虚拟机 -> 硬件 -> 磁盘
- Disk Action -> Resize
- 在”调整磁盘大小”窗体中输入需要增量的大小

![](https://img.17121203.xyz/i/2024/10/24/qqgf32-0.webp)

点击“调整磁盘大小”确认后，硬盘(scsi0) 的具体参数就会变成 `size=80G`，此时只是增加了新磁盘，未挂载的话还是无法使用的；

2）通过命令行工具进行服务器进行操作，首先查看磁盘是否有增加

```sh
$ sudo fdisk -l

Disk /dev/sda: 85.9 GB, 85899345920 bytes, 167772160 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk label type: dos
Disk identifier: 0x000abd26

   Device Boot      Start         End      Blocks   Id  System
/dev/sda1   *        2048     2099199     1048576   83  Linux
/dev/sda2         2099200   104857599    51379200   8e  Linux LVM

Disk /dev/mapper/centos_pbe-root: 48.3 GB, 48318382080 bytes, 94371840 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes


Disk /dev/mapper/centos_pbe-swap: 4286 MB, 4286578688 bytes, 8372224 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes

$ sudo df -Th
Filesystem                  Type      Size  Used Avail Use% Mounted on
devtmpfs                    devtmpfs  4.9G     0  4.9G   0% /dev
tmpfs                       tmpfs     4.9G     0  4.9G   0% /dev/shm
tmpfs                       tmpfs     4.9G  9.8M  4.9G   1% /run
tmpfs                       tmpfs     4.9G     0  4.9G   0% /sys/fs/cgroup
/dev/mapper/centos_pbe-root xfs        45G   14G   32G  30% /
/dev/sda1                   xfs      1014M  147M  868M  15% /boot
tmpfs                       tmpfs     843M     0  843M   0% /run/user/1000
```

通过命令输出的信息可以看到磁盘的容量已发生变化，但分区的信息还是未改变

3）**扩容分区**：查询磁盘分区信息（如多磁盘需要根据上述输出的实际磁盘路径修改）

```sh
$ sudo parted /dev/sda
GNU Parted 3.1
Using /dev/sda
Welcome to GNU Parted! Type 'help' to view a list of commands.
(parted) print                                                            
Model: QEMU QEMU HARDDISK (scsi)
Disk /dev/sda: 85.9GB
Sector size (logical/physical): 512B/512B
Partition Table: msdos
Disk Flags: 

Number  Start   End     Size    Type     File system  Flags
 1      1049kB  1075MB  1074MB  primary  xfs          boot
 2      1075MB  53.7GB  52.6GB  primary               lvm
```

4）执行 `resizepart` 命令，将磁盘容量进行划分，此处的 `2` 为上面打印的磁盘分区(需要扩容的分区编号)

```sh
(parted) resizepart 2 100%                                               
(parted) quit                                                             
Information: You may need to update /etc/fstab.
```

5）执行 `pvresize` 命令更新磁盘信息，再查看扩容结果，可以看到 `/dev/sda2` 已变更，但磁盘目录未有变化

```sh
$ sudo pvresize /dev/sda2
  Physical volume "/dev/sda2" changed
  1 physical volume(s) resized or updated / 0 physical volume(s) not resized
$ sudo fdisk -l

Disk /dev/sda: 85.9 GB, 85899345920 bytes, 167772160 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk label type: dos
Disk identifier: 0x000abd26

   Device Boot      Start         End      Blocks   Id  System
/dev/sda1   *        2048     2099199     1048576   83  Linux
/dev/sda2         2099200   167772159    82836480   8e  Linux LVM

Disk /dev/mapper/centos_pbe-root: 48.3 GB, 48318382080 bytes, 94371840 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes


Disk /dev/mapper/centos_pbe-swap: 4286 MB, 4286578688 bytes, 8372224 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes

$ sudo df -Th
Filesystem                  Type      Size  Used Avail Use% Mounted on
devtmpfs                    devtmpfs  4.9G     0  4.9G   0% /dev
tmpfs                       tmpfs     4.9G     0  4.9G   0% /dev/shm
tmpfs                       tmpfs     4.9G  9.8M  4.9G   1% /run
tmpfs                       tmpfs     4.9G     0  4.9G   0% /sys/fs/cgroup
/dev/mapper/centos_pbe-root xfs        45G   14G   32G  30% /
/dev/sda1                   xfs      1014M  147M  868M  15% /boot
tmpfs                       tmpfs     843M     0  843M   0% /run/user/1000
```

6）之后执行 `vgdisplay` 查看逻辑卷信息

```sh
$ sudo vgdisplay
  --- Volume group ---
  VG Name               centos_pbe
  System ID             
  Format                lvm2
  Metadata Areas        1
  Metadata Sequence No  4
  VG Access             read/write
  VG Status             resizable
  MAX LV                0
  Cur LV                2
  Open LV               2
  Max PV                0
  Cur PV                1
  Act PV                1
  VG Size               <79.00 GiB
  PE Size               4.00 MiB
  Total PE              20223
  Alloc PE / Size       12542 / 48.99 GiB
  Free  PE / Size       7681 / 30.00 GiB
  VG UUID               5CEHUU-1adt-fLKt-AaL9-dg6o-JUfO-3elLgR
```

7）执行 `lvextend` 划分全部空闲分区给指定的分区，再查看目录大小情况

```sh
$ lvextend -rl +100%FREE /dev/mapper/centos_pbe-root
  Size of logical volume centos_pbe/root unchanged from 75.00 GiB (19201 extents).
  Logical volume centos_pbe/root successfully resized.
meta-data=/dev/mapper/centos_pbe-root isize=512    agcount=4, agsize=2949120 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=0 spinodes=0
data     =                       bsize=4096   blocks=11796480, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0 ftype=1
log      =internal               bsize=4096   blocks=5760, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0
data blocks changed from 11796480 to 19661824

$ df -h
Filesystem                   Size  Used Avail Use% Mounted on
devtmpfs                     4.9G     0  4.9G   0% /dev
tmpfs                        4.9G     0  4.9G   0% /dev/shm
tmpfs                        4.9G  9.8M  4.9G   1% /run
tmpfs                        4.9G     0  4.9G   0% /sys/fs/cgroup
/dev/mapper/centos_pbe-root   75G   14G   62G  18% /
/dev/sda1                   1014M  147M  868M  15% /boot
tmpfs                        995M     0  995M   0% /run/user/1000
```