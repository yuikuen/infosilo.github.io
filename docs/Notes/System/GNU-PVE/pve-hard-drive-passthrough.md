> PVE 虚拟主机硬盘直通

PVE 系统从 5.3 版本之后，可以直接图形化直通，而直通硬盘的方式有两种：

1. 命令操作，直通单块硬盘(一般建议此方法)；
2. 添加 PCI 设备，直通 SATA Controller(SATA 控制器)

## 方法一

1）查看磁盘 ID，输入命令列出 PVE 系统下所有磁盘存储设备并查看磁盘 ID 序列号

```sh
root@pve:~# ls -l /dev/disk/by-id/
total 0
lrwxrwxrwx 1 root root  9 Mar 16 13:59 ata-ST1000DM010-2EP102_Z9ADYSNV -> ../../sdd
lrwxrwxrwx 1 root root  9 Mar 20 16:12 ata-ST1000DM010-2EP102_Z9AE1VGT -> ../../sdc
lrwxrwxrwx 1 root root  9 Mar 16 13:59 ata-ST2000DM008-2FR102_WFL0JJVB -> ../../sde
lrwxrwxrwx 1 root root  9 Mar 20 17:13 ata-TOSHIBA-TR200_Y9IB8268K5QL -> ../../sdb
lrwxrwxrwx 1 root root 10 Mar 20 17:14 ata-TOSHIBA-TR200_Y9IB8268K5QL-part1 -> ../../sdb1
lrwxrwxrwx 1 root root  9 Mar 16 11:11 ata-WDC_WDS120G2G0A-00JH30_180287806911 -> ../../sda
lrwxrwxrwx 1 root root 10 Mar 16 11:11 ata-WDC_WDS120G2G0A-00JH30_180287806911-part1 -> ../../sda1
lrwxrwxrwx 1 root root 10 Mar 16 11:11 ata-WDC_WDS120G2G0A-00JH30_180287806911-part2 -> ../../sda2
lrwxrwxrwx 1 root root 10 Mar 17 14:41 ata-WDC_WDS120G2G0A-00JH30_180287806911-part3 -> ../../sda3
lrwxrwxrwx 1 root root 10 Mar 17 14:41 dm-name-pve-root -> ../../dm-1
lrwxrwxrwx 1 root root 10 Mar 16 11:11 dm-name-pve-swap -> ../../dm-0
lrwxrwxrwx 1 root root 10 Mar 16 11:11 dm-uuid-LVM-p9KgeGETTA7lYKJg589nggvZCDWMEtdJ2lm42P6lesNDPIc53ciCXRp19F18D1b8 -> ../../dm-0
lrwxrwxrwx 1 root root 10 Mar 17 14:41 dm-uuid-LVM-p9KgeGETTA7lYKJg589nggvZCDWMEtdJygNILyjKmXCHbf0vUK2CTTsxQ7FUZS75 -> ../../dm-1
lrwxrwxrwx 1 root root 10 Mar 17 14:41 lvm-pv-uuid-Cj4Pvp-AyoO-2mvP-uxF5-n1QS-W1Ln-98z63B -> ../../sda3
lrwxrwxrwx 1 root root 13 Mar 16 13:58 nvme-eui.6479a74de0c00604 -> ../../nvme0n1
lrwxrwxrwx 1 root root 13 Mar 16 13:58 nvme-PCIe_SSD_7D6207151F3D00001243 -> ../../nvme0n1
lrwxrwxrwx 1 root root  9 Mar 16 13:59 wwn-0x5000c500a32034e3 -> ../../sdd
lrwxrwxrwx 1 root root  9 Mar 20 16:12 wwn-0x5000c500a3290735 -> ../../sdc
lrwxrwxrwx 1 root root  9 Mar 16 13:59 wwn-0x5000c500ba631685 -> ../../sde
lrwxrwxrwx 1 root root  9 Mar 16 11:11 wwn-0x5001b448b61fb217 -> ../../sda
lrwxrwxrwx 1 root root 10 Mar 16 11:11 wwn-0x5001b448b61fb217-part1 -> ../../sda1
lrwxrwxrwx 1 root root 10 Mar 16 11:11 wwn-0x5001b448b61fb217-part2 -> ../../sda2
lrwxrwxrwx 1 root root 10 Mar 17 14:41 wwn-0x5001b448b61fb217-part3 -> ../../sda3
lrwxrwxrwx 1 root root  9 Mar 20 17:13 wwn-0x58ce38ec0155cb46 -> ../../sdb
lrwxrwxrwx 1 root root 10 Mar 20 17:14 wwn-0x58ce38ec0155cb46-part1 -> ../../sdb1
```

![](https://img.17121203.xyz/i/2024/10/24/qy3veb-0.webp)

注意：必须选择整个硬盘(物理硬盘)而不是分区，比如 `sda/sdb/sdc` 对应的 id，而不是 `sda1/sdb1` 之类

**另外 ata、nvme 等表示接口方式，通常有 `ATA/SATA/SCS/NVME/eMMC/SASI` 等类型，IDE 和 SATA 一般为 ata，SCSI 及 SAS 一般为 scsi**

2）将物理磁盘直通给 PVE 系统下的虚拟机中

> 使用的工具为 qm(Qemu/KVM 虚拟机管理器)，通过命令 set 来设置物理磁盘到虚拟机中

```sh
$ qm set <vm_id> –<disk_type>[n] /dev/disk/by-id/<type>-$brand-$model_$serial_number
```

- `vm_id`：为创建虚拟机时指定的 VM ID
- `<disk_type>[n]`：磁盘的总线类型及其编号，总线类型可选择 IDE、SATA、VirtIO Block 和 SCSI 类型，编号从 0 开始，最大值根据总线接口类型有所不同，IDE 为3，SATA 为5，VirTIO Block 为15，SCSI 为13
- `/dev/disk/by-id/<type>-$brand-$model_$serial_number`：为磁盘 ID 的具体路径和名称

以上图所示的硬盘参数举例，将磁盘 ID 为 `ata-ST2000DM008-2FR102_WFL0JJVB` 的 2T 硬盘直通给 VIM ID 编号为 100 的虚拟机，总线类型 sata0 (请根据 PVE 虚拟机下的总线编号设置)

![](https://img.17121203.xyz/i/2024/10/24/qyp69w-0.webp)

输入挂载命令，如硬盘直通完成后返回 `update` 信息

```sh
root@pve:~# qm set 100 -sata0 /dev/disk/by-id/ata-ST2000DM008-2FR102_WFL0JJVB
update VM 100: -sata0 /dev/disk/by-id/ata-ST2000DM008-2FR102_WFL0JJVB
```

![](https://img.17121203.xyz/i/2024/10/24/qz3uk9-0.webp)

然后进入 PVE 虚拟机管理后台，查看是否真的挂载成功。如看到下述表示已添加成功，但橘黄色字体显示该设置并未生效，需要从 PVE 控制台重启后生效。

3）重启虚拟机后，还需要自行挂载目录方可使用，挂载过程在此略过

```sh
$ lsblk 
NAME                MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sdb                   8:16   0   50G  0 disk 
├─sdb2                8:18   0   49G  0 part 
│ ├─centos_pbe-swap 253:1    0    4G  0 lvm  [SWAP]
│ └─centos_pbe-root 253:0    0   45G  0 lvm  /
└─sdb1                8:17   0    1G  0 part /boot
sr0                  11:0    1  988M  0 rom  
sda                   8:0    0  1.8T  0 disk
```

## 方法二

PVE 系统直通 SATA Controller，会把整个 sata 总线全部直通过去，意思是直通会将南桥或北桥连接的 sata 总线直通，那么有些主板 sata 接口就会全部被直通

**注意：如 PVE 系统安装在 SATA 硬盘中，会导致 PVE 系统无法启动，所以在直通 SATA Controller 之前请先确认 PVE 安装位置或直接将系统安装在 NVMe 硬盘**

我的环境是 SSD SATA 并且主板是 X99 不支持，所以未进行操作实验，具体可参考 [Proxmox VE(PVE)系统开启IOMMU功能实现硬件直通](https://www.nasge.com/archives/137.html) 文件，开启 IOMMU 硬件直通功能后，执行下一步添加 SATA Controller(SATA 控制器)操作。

选择需要设置的 PVE 系统，点击 硬件 > 添加 > PCI设备 > 选择 SATA Controller（SATA 控制器），最后点击“添加”把 SATA Controller（SATA 控制器）添加给相应的系统后，完成重启，PVE 硬件直通的设置就生效了

![](https://img.17121203.xyz/i/2024/10/24/r2beg0-0.webp)