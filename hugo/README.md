# Deploy HugoMods Site

## Create Site

```bash
docker run -v ${PWD}:/src -u 1000:1000 hugomods/hugo:exts-non-root-0.145.0 hugo new site hugo
git submodule add https://github.com/CaiJimmy/hugo-theme-stack.git hugo/themes/hugo-theme-stack
```

## Set Test

```bash
echo 'theme = "hugo-theme-stack"' >> hugo.toml
docker run -u 1000:1000 --name mysite -p 8080:8080 -v ${PWD}:/src hugomods/hugo:exts-non-root-0.145.0 server -p 8080
```
