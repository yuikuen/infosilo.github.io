> 使用 RPM 安装文件时，会出现 `error: Failed dependencies`
>
> 错误原因是：失败的依赖

解决方法是，在安装包的后面加上两个参数值，如：

```sh
$ rpm -ivh FileName.rpm --nodeps --force
```

参数的意义是，安装时不再分析包之间的依赖关系而直接安装

## 一. RPM 安装操作

`rpm -i` 需要安装的包文件名

```sh
$ rpm -i FileName.rpm
```

其它命令示例如下：

```sh
$ rpm -i example.rpm 安装 example.rpm 包
$ rpm -iv example.rpm 安装 example.rpm 包并在安装过程中显示正安装的文件信息
$ rpm -ivh example.rpm 安装 example.rpm 包并在安装过程中显示正在安装的文件信息及安装进度
```

## 二. RPM 查询操作

常规命令：`rpm -q ...`

- a  查询所有已安装的包以下两个附加命令用于查询安装包的信息；
- i   显示安装包的信息；
- l   显示安装包中的所有文件被安装到哪些目录下；
- s  显示安装中的所有文件状态及被安装到哪些目录下；
- p 查询的是安装包的信息；
- f  查询的是已安装的某文件信息；

```sh
$ rpm -qa | grep tomcat4 查看 tomcat4 是否被安装
$ rpm -qip example.rpm 查看 example.rpm 安装包的信息
$ rpm -qif /bin/df 查看 /bin/df 文件所在安装包的信息
$ rpm -qlf /bin/df 查看 /bin/df 文件所在安装包中的各个文件分别被安装到哪个目录下
```

## 三. RPM 卸载操作

常规命令：`rpm -e` 需要卸载的安装包，卸载前通常需要使用 `rpm -q ...` 命令查出需要卸载的安装包名称

```sh
$ rpm -e tomcat4 卸载 tomcat4 软件包
```

## 四. RPM 升级操作

常规命令：`rpm -U` 需要升级的包

```sh
$ rpm -Uvh example.rpm 升级 example.rpm 软件包
```

## 五. RPM 验证操作

常规命令：`rpm -V` 需要验证的包

```sh
$ rpm -Vf /etc/tomcat4/tomcat4.conf
输出信息类似如下：
S.5....T c /etc/tomcat4/tomcat4.conf
```

## 六. RPM 附加命令

- `--force` 强制操作，如强制安装、删除等；
- `--requires` 显示该包的依赖关系；
- `--nodeps` 忽略依赖关系并继续操作；

