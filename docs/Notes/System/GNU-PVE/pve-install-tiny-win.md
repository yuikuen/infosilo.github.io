> PVE 安装 Tiny-Win 系统

PVE 安装 Win10/Win11 时都需要 [Virtual io Win 驱动](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/)，并且原版的系统过于臃肿，所以选择安装精简版 Tiny-Win10/11(经测试，两个系统都无需驱动即可安装)

> 安装方式与常规的一样，只是安装过程不用选择磁盘驱动

硬件选择如图所示，有条件的话硬件可选择 SSD,安装时注意启动顺序即可，网络后面改成 `Intel E1000`，否则无网卡可用

![](https://img.17121203.xyz/i/2024/10/24/panszc-0.webp)

基础信息自定义，之后选择 Win ISO 映像和其余选项，首先系统显卡选择 `VirtIO-GPU`，SCSI 控制器选择 `VirtIO SCSI`，其余默认

![](https://img.17121203.xyz/i/2024/10/24/pcqtv4-0.webp)

根据自身选择磁盘，IDE 兼容性稍好，而 SATA 性能稍好些，具体取决于基础硬件

![](https://img.17121203.xyz/i/2024/10/24/pcusl4-0.webp)

CPU 选择根据实际需求，Win11 至少需要 4个 CPU 内核，类别选择 `host`

![](https://img.17121203.xyz/i/2024/10/24/pe71f6-0.webp)

最后内存至少需要 4GB，而网络则需要选择 `Intel E1000`，一开始选择 `VirtIO` 最后会无法识别网卡