> 解决火绒误杀 explorer.exe 文件导致开机黑屏问题

## 一. 方法一

`ctrl+shift+del` 调出任务管理器，【运行新任务】 -> 【浏览】，进入火绒安装路径，双击 `HRUpdate.exe`；

可能会弹出火绒升级界面，若没有弹出，则需要 `Alt+Tab` 切换到升级窗口，点击升级

- 个人版默认安装路径：`C:\Program Files (x86)\Huorong\Sysdiag\bin`

- 企业版默认安装路径：`C:\Program Files (x86)\Huorong\ESEndpoint\bin`

升级后，再点击任务管理器的文件 -> 运行新任务 -> 输入 cmd（勾选"以系统管理权限创建此任务"），窗口输入命令回车执行

```cmd
sfc /scanfile=c:\windows\explorer.exe
```

## 二. 方法二

`ctrl+shift+del` 调出任务管理器，从任务管理器中找到火绒进程，右键属性查看火绒目录，执行 `HipsMain.exe` 打开火绒，从隔离区把 `explorer.exe` 恢复到信任区

## 三. 方法三

进入 **PE** 或 **系统恢复模式**，卸载火绒并将同系统下的 `explorer.exe` 复制到异常电脑的 Windows 目录下
