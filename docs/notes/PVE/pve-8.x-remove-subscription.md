登录后进入 shell 模式，查看原文件

> 亲测 PVE 8.2.2 版本有效，其它版本请自行验证

```sh
$ cd /usr/share/javascript/proxmox-widget-toolkit
ls -al
total 928
drwxr-xr-x 5 root root   4096 Aug 17 17:21 .
drwxr-xr-x 8 root root   4096 Aug 17 17:21 ..
drwxr-xr-x 2 root root   4096 Aug 17 17:21 css
drwxr-xr-x 2 root root   4096 Aug 17 17:21 images
-rw-r--r-- 1 root root 592588 Apr 24 01:25 proxmoxlib.js
-rw-r--r-- 1 root root 334770 Apr 24 01:25 proxmoxlib.min.js
drwxr-xr-x 2 root root   4096 Aug 17 17:21 themes
```

使用 sed 命令对文件进行替换操作，并创建备份文件

```sh
# 使用 sed 命令对文件进行替换操作，并创建备份文件
$ sed -i.backup -z "s/res === null || res === undefined || \!res || res\n\t\t\t.data.status.toLowerCase() \!== 'active'/false/g" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js && systemctl restart pveproxy.service

# 重启 pveproxy 服务
$ systemctl restart pveproxy.service

$ diff proxmoxlib.js proxmoxlib.js.backup 
563c563,564
<                   if (false) {
---
>                   if (res === null || res === undefined || !res || res
>                       .data.status.toLowerCase() !== 'active') {
```

重启后 `Ctrl+F5` 强刷新浏览器即可测试是否成功；