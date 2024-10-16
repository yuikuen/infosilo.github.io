> 设置脚本定期推送代码更新

创建过滤目录，设置定时构建 & 推送脚本和任务

```sh
# 排除生成的站点文件
$ cat > /opt/app/infosilo.github.io/.gitignore <<EOF
# Ignore site directory and all its contents
site/
EOF
```

```sh
#!/bin/bash

# 定义路径变量
path="/opt/app/infosilo.github.io"
log_file="/var/log/web.log"

# 定义时间戳变量
timestamp="$(date +'%Y-%m-%d %H:%M:%S')"

# 进入指定路径
cd $path

# 执行构建命令
if docker run --rm --name docs -v ${PWD}:/docs yuikuen/mkdocs-material:9.5.25 build; then
    # 如果执行成功，则输出结果到日志文件，并添加时间戳
    echo "$timestamp - ok" >> $log_file
    
    # 移除被跟踪的目录（如果存在），上传时过滤站点目录
    git rm -r --cached $path/site/ 2>/dev/null

    # 添加所有文件到Git
    git add .

    # 提交更改
    git commit -m "update on $timestamp"

    # 推送到远程仓库
    git push -u origin main
else
    # 如果执行失败，则输出结果到日志文件，并添加时间戳
    echo "$timestamp - no" >> $log_file
fi
```

```sh
$ crontab -e
# 每天凌晨0点执行build&push操作
0 0 * * * /bin/bash /opt/app/shell/build-push.sh >> /dev/null 2>&1
```