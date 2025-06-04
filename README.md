# Info-Silo

参考链接:
- https://squidfunk.github.io/mkdocs-material
- https://zhuanlan.zhihu.com/p/672743170
- https://zhuanlan.zhihu.com/c_1754218140098387968 

## Build Methods（构建方法）

使用 MkDocs-Material 官方镜像安装 Plugins，再通过 Docker 构建部署

## Dockerfile
```
FROM squidfunk/mkdocs-material:9.6.14
# 创建虚拟环境并安装 mkdocs-static-i18n 插件
#RUN python3 -m venv /venv
#ENV PATH="/venv/bin:$PATH"
RUN pip install mkdocs-static-i18n \
 && pip install mkdocs-rss-plugin \
 && pip install mkdocs-minify-plugin \
 && pip install mkdocs-git-revision-date-localized-plugin \
 && pip install mkdocs-git-committers-plugin-2 \
 && pip install mkdocs-git-authors-plugin
```

docker build -f Dockerfile -t infosilo/mkdocs-material:9.6.14 .
docker run --rm -it -v ${PWD}:/docs infosilo/mkdocs-material:9.6.14 new .

## Deploy Test & Build
docker run --rm -it --name docs -v ${PWD}:/docs -p 8000:8000 infosilo/mkdocs-material:9.6.14 serve -a 0.0.0.0:8000
docker run --rm -it --name docs -v ${PWD}:/docs -p 8000:8000 insofilo/mkdocs-material:9.6.14 build
