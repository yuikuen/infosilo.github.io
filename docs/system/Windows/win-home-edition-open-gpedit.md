> Win 10 / 11 家庭版开启组策略编辑器（gpedit.msc）

**问题提示**：Windows 找不到文件 'gpedit.msc'，请确定文件名是否正确后，再试一次

**解决方法**：通过调用 dism 命令安装组策略包；复制如下代码到新建文本文档，重命名 `.bat` 文件以管理员方式执行

```cmd
@echo off
pushd "%~dp0"

rem List all relevant .mum files and save to List.txt
dir /b %SystemRoot%\servicing\Packages\Microsoft-Windows-GroupPolicy-ClientExtensions-Package~3*.mum > List.txt
dir /b %SystemRoot%\servicing\Packages\Microsoft-Windows-GroupPolicy-ClientTools-Package~3*.mum >> List.txt

rem add each package from List.txt to DISM
for /f %%i in ('findstr /i . List.txt 2^>nul') do (
    dism /online /norestart /add-package:"%SystemRoot%\servicing\Packages\%%i"
)

pause
```