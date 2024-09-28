> 战X 2023 7840/7940hs 更新 Bios 开启更大显存

参考链接：

- [HP EliteBook 845 14 英寸 G10 笔记本电脑 软件和驱动程序下载 | HP® 支持](https://support.hp.com/cn-zh/drivers/hp-elitebook-845-14-inch-g10-notebook-pc/2101628462)

- [战X 2023锐龙版 无法修改核显显存大于512MB](https://h30471.www3.hp.com/t5/bi-ji-ben-dian-nao/zhanX-2023rui-long-ban-wu-fa-xiu-gai-he-xian-xian-cun-da-yu512MB/m-p/1238661)

- [战x 2023 7840/7940hs 更新1.3.9版本bios后可开最大4G显存](https://www.bilibili.com/read/cv28928607/)

![官网 Bios 更新内容](https://img.17121203.xyz/i/2024/08/27/h3a5r2-0.webp)

Bios 固件下载地址：https://ftp.hp.com/pub/softpaq/sp150501-151000/sp150572.exe

**操作步骤**

1. BIOS：Advanced -> Build In Device 中将 Video Memory Size 将下拉菜单改为 Gaming Optimized，保存退出，进入系统生效

2. 系统：打开 AMD 显卡控制台，依次选择【性能】->【调整】，将系统中的内存优化器右侧下拉菜单改成【游戏】，在提示窗口中选继续，重启系统后生效

![AMD 驱动界面](https://img.17121203.xyz/i/2024/08/27/iic10l-0.webp)

![任务管理器界面](https://img.17121203.xyz/i/2024/08/27/ijfpc9-0.webp)

- 当系统内存为 16G 时，更改之后显卡独立显存为 2G;
- 当系统内存为 32G 时，更改之后显卡独立显存为 4G;

PS：经其他用户测试，具有 64G 系统内存，也仅划分了 4G 给核显，证明上限仅为 4G;
