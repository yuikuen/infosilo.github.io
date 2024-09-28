> 笔电及平板设备电池健康状况，Win 系统中提供了可查看设备电池详细使用报告的方法
>
> 参考链接：[新式待机 SleepStudy | Microsoft Learn](https://learn.microsoft.com/zh-cn/windows-hardware/design/device-experiences/overview-of-modern-standby-validation)

**操作步骤**：

1. 鼠标右键单击开始菜单，然后选择 "命令提示符（管理员）"

2. 命令行窗口，输入命令后回车，系统就会在指定的路径生成设备电池使用报告

```cmd
powercfg /batteryreport /output "C:\battery_report.html"
```

3. 双击 `C:\battery_report.html` 会用默认浏览器打开该报告，可看到系统以及电池基本信息，包括电池设计容量、完全充电容量、充电周期、设备电池完全充电容量变化、最近三日电池使用情况记录，包括何时处理于活动状态以及何时进入待机状态等详细信息

PS：报告会详细记录自系统安装后电池的使用详情，根据这些数据可掌握电池续航变化情况

4. 另外同理可通过 PowerShell 生成 SleepStudy 待机状态报告

```cmd
powercfg /sleepstudy /output "C:\sleepstudy-report.html"
```
