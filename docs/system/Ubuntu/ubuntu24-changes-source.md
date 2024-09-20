> Ubuntu 24.04 Apt 更换国内镜像站源

24.04 LTS 后，apt 源的位置替换到 `/etc/apt/sources.list.d/ubuntu.sources` 中

```sh
/etc/apt/sources.list
# Ubuntu sources have moved to the /etc/apt/sources.list.d/ubuntu.sources
# file, which uses the deb822 format. Use deb822-formatted .sources files
# to manage package sources in the /etc/apt/sources.list.d/ directory.
# See the sources.list(5) manual page for details.
```

另外，现格式同样改为 [DEB822 格式](https://repolib.readthedocs.io/en/latest/deb822-format.html?login=from_csdn)

```sh
/etc/apt/sources.list.d/ubuntu.sources
##      /etc/cloud/templates/sources.list.ubuntu.deb822.tmpl
##

# See http://help.ubuntu.com/community/UpgradeNotes for how to upgrade to
# newer versions of the distribution.

## Ubuntu distribution repository
##
## The following settings can be adjusted to configure which packages to use from Ubuntu.
## Mirror your choices (except for URIs and Suites) in the security section below to
## ensure timely security updates.
##
## Types: Append deb-src to enable the fetching of source package.
## URIs: A URL to the repository (you may add multiple URLs)
## Suites: The following additional suites can be configured
##   <name>-updates   - Major bug fix updates produced after the final release of the
##                      distribution.
##   <name>-backports - software from this repository may not have been tested as
##                      extensively as that contained in the main release, although it includes
##                      newer versions of some applications which may provide useful features.
##                      Also, please note that software in backports WILL NOT receive any review
##                      or updates from the Ubuntu security team.
## Components: Aside from main, the following components can be added to the list
##   restricted  - Software that may not be under a free license, or protected by patents.
##   universe    - Community maintained packages.
##                 Software from this repository is only maintained and supported by Canonical
##                 for machines with Ubuntu Pro subscriptions. Without Ubuntu Pro, the Ubuntu
##                 community provides best-effort security maintenance.
##   multiverse  - Community maintained of restricted. Software from this repository is
##                 ENTIRELY UNSUPPORTED by the Ubuntu team, and may not be under a free
##                 licence. Please satisfy yourself as to your rights to use the software.
##                 Also, please note that software in multiverse WILL NOT receive any
##                 review or updates from the Ubuntu security team.
##
## See the sources.list(5) manual page for further settings.
Types: deb
URIs: http://archive.ubuntu.com/ubuntu
Suites: noble noble-updates noble-backports
Components: main universe restricted multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

## Ubuntu security updates. Aside from URIs and Suites,
## this should mirror your choices in the previous section.
Types: deb
URIs: http://security.ubuntu.com/ubuntu
Suites: noble-security
Components: main universe restricted multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
```

如需使用国内镜像源，也需要使用新格式；首先备份 `sources.list.d/ubuntu.sources` 文件

```sh
$ sudo cd /etc/apt/sources.list.d
$ sudo cp ubuntu.sources ubuntu.sources.bak
```

修改或新建 `.sources` 文件，之后运行更新命令

```sh
Types: deb
URIs: https://mirrors.tuna.tsinghua.edu.cn/ubuntu/
#如果使用其他镜像站，上面这行可以改成其他镜像站的网址
Suites: noble noble-updates noble-backports
Components: main universe restricted multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

Types: deb
URIs: http://security.ubuntu.com/ubuntu
#如果安全更新需要使用镜像站，上面这行也改成 URIs: https://mirrors.tuna.tsinghua.edu.cn/ubuntu/
Suites: noble-security
Components: main universe restricted multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
```

```sh
$ sudo apt update
$ sudo apt upgrade
```