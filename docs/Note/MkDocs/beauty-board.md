# Top Bulletin Board

!!! info "Reference Links"

    添加顶部公告栏：https://wcowin.work/blog/websitebeauty/header.html

> docs/overrides 下新建 main.html，树状结构如下：

```sh
tree -L 2
.
├── Dockerfile
├── docs
├── mkdocs.yml
├── overrides
│   └── main.html
```

```html
<!--左上角For updates follow-->
{#-
  This file was automatically generated - do not edit
-#}
{% extends "base.html" %}
{% block extrahead %}
  <link rel="stylesheet" href="{{ 'assets/stylesheets/custom.00c04c01.min.css' | url }}">
{% endblock %}
{% block announce %}
  For updates follow <strong>@YuiKuen.Yuen</strong> on
  <a rel="me" href="https://space.bilibili.com/271768047" target=“_blank”>
    <span class="twemoji bilibili">
      {% include ".icons/fontawesome/brands/bilibili.svg" %}
    </span>
    <strong>Bilibili</strong>
  </a>
  and
  <a href="https://twitter.com/YuikuenY" target=“_blank”>
    <span class="twemoji x-twitter">
      {% include ".icons/fontawesome/brands/x-twitter.svg" %}
    </span>
    <strong>X-Twitter</strong>
  </a>
{% endblock %}
{% block scripts %}
  {{ super() }}
  <script src="{{ 'assets/javascripts/custom.9458f965.min.js' | url }}"></script>
{% endblock %}
```