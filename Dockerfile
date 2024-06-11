FROM squidfunk/mkdocs-material:9.5.24

# 官方镜像默认未安装相关插件
RUN pip install mkdocs-static-i18n \
 && pip install mkdocs-rss-plugin \
 && pip install mkdocs-minify-plugin \
 && pip install mkdocs-git-revision-date-localized-plugin \
 && pip install mkdocs-git-committers-plugin-2 \
 && pip install mkdocs-git-authors-plugin \
 ## 图片缩放功能
 && pip install mkdocs-glightbox