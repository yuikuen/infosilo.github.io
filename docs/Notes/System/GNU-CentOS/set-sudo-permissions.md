> sudo 是 Linux 系统管理指令，是允许系统管理员让普通用户执行一些或者全部的root命令的一个工具，如 halt，reboot，su 等等。

**应用场景**：root 用户作为超级管理员一般不会直接在生产中使用，此也是为了安全考虑。但日常安装软件、启动某个服务等需求，又不可能永远只由一个 root 用户来操作。此时可以通过给某普通用户添加安装管理软件的权限(sudo 的用户)，使用户执行权限提升并且能执行某些命令。

1）使用 root 用户打开 `/etc/sudoers` 配置文件，找到以下配置

```sh
## Allow root to run any commands anywhere
root    ALL=(ALL)       ALL
```

2）将上述配置复制，并将用户修改成普通用户，保存即可

```sh
## Allow root to run any commands anywhere
root    ALL=(ALL)       ALL
admin   ALL=(ALL)       ALL
```

注：建议使用 `visudo` 命令去编辑配置文件，因有语法校验，如配置不正确则无法保存成功

**简单测试效果**

在未添加 sudo 配置之前，普通用户执行某些命令会报如下错误

```sh
$ sudo visudo
[sudo] password for admin: 
admin is not in the sudoers file.  This incident will be reported.
```

添加完配置之后，再次使用

```sh
$ sudo visudo
[sudo] password for admin: 
visudo: /etc/sudoers.tmp unchanged
$ sudo su - root
[sudo] password for admin: 
Last login: Thu Feb 16 17:47:07 CST 2023 on pts/0
```

可以看到，输入 admin 的密码，就可以正常切换到 root 用户，也可以使用 sudo 去执行相关命令

**进阶配置**

每一次执行命令都需要输入 admin 的用户密码，如何做到不输入密码直接执行？让运维变得更简捷

```sh
## Allow root to run any commands anywhere
root    ALL=(ALL)       ALL
admin   ALL=(ALL)       ALL
%admin  ALL=(ALL)       ALL
admin   ALL=(ALL)       NOPASSWD: ALL
%admin  ALL=(ALL)       NOPASSWD: ALL
```

上述配置的功能简要说明：

- 允许用户 admin 执行 sudo 命令（需输入密码）
- 允许用户组 admin 里面的用户执行 sudo 命令（需输入密码）
- 允许用户 admin 执行 sudo 命令，并且在执行的时候不需要输入密码
- 允许用户组 admin 里面的用户执行 sudo 命令，并且在执行的时候不需要输入密码

**扩展知识**

让普通用户可以 sudo 执行 root 用户的权限，而不需要切换至 root 用户

```sh
## Allow root to run any commands anywhere
root    ALL=(ALL)       ALL
admin   ALL=(ALL)       ALL,!/bin/su
```

```sh
$ sudo su - root
[sudo] password for admin: 
Sorry, user admin is not allowed to execute '/bin/su - root' as root on pbe.4044-public.
```

可以看到 admin 用户已无法切换到 root 用户，但是可以用 sudo 去执行 root 才能执行的命令