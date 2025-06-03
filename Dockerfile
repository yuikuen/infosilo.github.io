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
