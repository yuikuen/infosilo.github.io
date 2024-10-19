**问题：Crontab 计划任务不能运行 Docker 命令**

**描述：**crontab 在执行含有 Docker 命令的脚本时，Docker 命令都执行失败

```sh
#!/bin/bash
docker exec -it 4b11 python test.py
```

**原因：**exec 加了 -it 参数就开启了一个终端，计划任务无法进入任务终端

**解决：**只需要将 exec 后的 -it 参数去掉即可