> [GitLab](https://docs.gitlab.com/) 是一个仓库管理系统的开源项目，使用 Git 作为代码管理工具，并在此基础上搭建起来的 Web 服务

1）创建 Yaml 文件

```yaml
version: '3.6'
services:
  gitlab-ce:
    image: 'gitlab/gitlab-ce:15.11.0-ce.0'
    container_name: gitlab-ce
    restart: always
    hostname: '188.xx.xx.xx'
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        external_url 'http://188.xx.xx.xx'
        gitlab_rails['gitlab_shell_ssh_port'] = 22
        gitlab_rails['backup_keep_time'] = 604800        
    ports:
      - '8000:80'
      - '22:22'
      - '8443:443'
    volumes:
      - '/etc/localtime:/etc/localtime:ro'
      - './config:/etc/gitlab'
      - './logs:/var/log/gitlab'
      - './data:/var/opt/gitlab'
    shm_size: '256m'
```

2）启动部署并查看状态，查看默认密码

> 默认密码保留时间为 24小时，首次登录后请自行修改

```sh
$ docker-compose -f gitlab.yml up -d
$ docker exec -it gitlab-ce cat /etc/gitlab/initial_root_password
# WARNING: This value is valid only in the following conditions
#          1. If provided manually (either via `GITLAB_ROOT_PASSWORD` environment variable or via `gitlab_rails['initial_root_password']` setting in `gitlab.rb`, it was provided before database was seeded for the first time (usually, the first reconfigure run).
#          2. Password hasn't been changed manually, either via UI or via command line.
#
#          If the password shown here doesn't work, you must reset the admin password following https://docs.gitlab.com/ee/security/reset_user_password.html#reset-your-root-password.

Password: lHofJFxdYKw+9rZdtLbyNbZb/+uQsMWjPus3lI5KWB4=

# NOTE: This file will be automatically deleted in the first reconfigure run after 24 hours.

```