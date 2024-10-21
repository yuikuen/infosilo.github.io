> 使用 Hugo 搭建个人博客

## 一. 安装说明

Hugo 作为搭建个人博客的框架，维护成本较低，因为是静态页面，对于环境的要求并不高，部署及运行也快.

选用 Hugo 作为搭建个人博客的框架，主要是站点都为静态页面，对于环境的要求并不高，部署运行也快.

而主题选用的是 `Stack`，因为主题是卡片式主题，并无太多的 `CSS` 和 `JavaScript framework`，可以保持站点轻便快捷.

- 服务环境：境外 VPS(SV-1Core-2G 5M Cloud) 云主机
- 博客主题：[Hugo](https://github.com/gohugoio/hugo) + [Stack](https://themes.gohugo.io/themes/hugo-theme-stack)

> PS: 注意版本的更新,执行命令和配置文件都有所不一，如报错请自行到 [官网](https://gohugo.io/documentation) 查阅版本变更

## 二. 安装程序

VPS 选择的是 `Ubuntu` 系统，可直接解压调用 [Hugo](https://github.com/gohugoio/hugo/releases) 程序命令，因惯用的 `CentOS` 内核过旧，需要更新相应的组件方可使用，具体看个人选择;

```sh
$ wget https://github.com/gohugoio/hugo/releases/download/v0.110.0/hugo_extended_0.110.0_Linux-64bit.tar.gz
$ tar -xf hugo_extended_0.110.0_Linux-64bit.tar.gz
$ \cp hugo /usr/local/bin/
$ hugo version
hugo v0.110.0-e32a493b7826d02763c3b79623952e625402b168+extended linux/amd64 BuildDate=2023-01-17T12:16:09Z VendorInfo=gohugoio
```

创建博客的目录并下载自己挑选的主题

```sh
$ cd /opt && hugo new site myblog
$ cd myblog && git clone https://github.com/CaiJimmy/hugo-theme-stack/ themes/hugo-theme-stack

$ tree /opt/myblog -L 2
/opt/myblog
├── archetypes
│   └── default.md
├── assets           # 静态资源
├── config.toml      # 配置文件：主题选择、名称、链接、页面分析、markdown解析引擎
├── content          # 站点内容：顶层导航，左侧树形章节
├── data
├── layouts          # 可覆盖主题的默认布局，添加自定义页面布局
├── public           # 网站文件(hugo执行后生成的文件=Web服务器的html目录)
├── static           # 静态文件
└── themes           # 主题目录
    └── hugo-theme-stack
```

添加主题至配置文件，直接调用执行

```sh
$ echo 'theme = "hugo-theme-stack"' >> config.toml
$ hugo server -b=blog.info-silo.com --bind=0.0.0.0 --port=80
# 最后添加新文章，后台执后测试
$ hugo new post/my-first-page.md
$ nohup hugo server -b=blog.info-silo.com --bind=0.0.0.0 --port=80 >/dev/null 2>&1 &
```

此处我提前配置了域名解析，所以可直接调用，打开浏览器输入 `http://blog.info-silo.com` 预览效果

## 三. 更换主题

> 上述步骤操作完成后，博客已基本可以使用了，后面只需要通过自定义配置就可以投入使用。

一般主题目录内都含有类似 `exampleSite` 的模版文件，只需要把主题文件夹内的一些静态文件和配置文件复制到站点目录下，就可生效使用。
其目的为了可以自定义博客的样式，而不会改动文件夹内的样式，这样主题要更新的时候，直接在主题目录下 `git pull` 就可以了，注意以下事项即可：

- 站点目录的修改会优先覆盖主题里的配置
- 大部分内容可通过修改根目录的 `config.toml` 文件实现
- 如不能通过上述实现的，也不建议直接修改 `themes` 目录下的内容，可 `copy` 到根目录同样的相对路径再修改

**简单示例**: 将主题的静态文件及配置文件直接复制到站点根目录，然后 `hugo -D` 即可生成

```sh
$ cd /opt/myblog
$ \cp -r themes/hugo-theme-stack/{archetypes,assets,i18n,layouts} .
# 因为熟悉yaml方式,所以将toml改成yaml,自行选择
$ rm -rf config.toml
$ \cp -r themes/hugo-theme-stack/exampleSite/config.yaml .
```

*附加说明*: 主题一般都具有多语种切换,可参考 [官方文档](https://gohugo.io/content-management/multilingual/#translation-by-content-directory) 进行配置