> 通过 Docker 部署 MkDocs Material

使用 `squidfunk/mkdocs-material` 官方镜像，安装需要的插件，再进行重构建镜像

```sh
$ docker pull squidfunk/mkdocs-material:9.5.25
$ cat Dockerfile
FROM squidfunk/mkdocs-material:9.5.25
RUN pip install mkdocs-static-i18n \
 && pip install mkdocs-rss-plugin \
 && pip install mkdocs-minify-plugin \
 && pip install mkdocs-git-revision-date-localized-plugin \
 && pip install mkdocs-git-committers-plugin-2 \
 && pip install mkdocs-git-authors-plugin
$ docker build -t yuikuen/mkdocs-material:9.5.25
```

之后创建空目录或下拉空项目作为站点目录（后期网站上传 GitHub 后，可直接下拉代码快速迁移站点）

```sh
$ git clone git@github.com:yuikuen/infosilo.github.io.git
$ docker run --rm -it -v ${PWD}:/docs yuikuen/mkdocs-material:9.5.25 new .
# 编辑调试 & 构建站点
$ docker run --rm -it --name docs -v ${PWD}:/docs -p 8000:8000 yuikuen/mkdocs-material:9.5.25 serve -a 0.0.0.0:8000
$ docker run --rm -it --name docs -v ${PWD}:/docs -p 8000:8000 yuikuen/mkdocs-material:9.5.25 build
```