## 一. Nginx

```yml
# nginx版本不同，程序目录也不同，注意修正
services:
  nginx:
    image: nginx:1.24.0-alpine3.17-perl
    container_name: webui
    restart: always
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./conf.d:/etc/nginx/conf.d
      - ./certs:/etc/nginx/certs
      - ./html:/usr/share/nginx/html
      - ./log/nginx:/var/log/nginx
    networks:
      - npm
networks:
  npm:
    external: true
```

```sh
# 监听Docker-WP的expose:80端口
server {
    listen 80;
    server_name www.example.com;

    location / {
        proxy_pass http://wp_app;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## 二. WordPress

```yml
services:
  db:
     image: mysql:5.7
     container_name: "wp_mysql"
     expose:
       - "3306"
     volumes:
       - $PWD/wp-db:/var/lib/mysql
     restart: always
     environment:
       MYSQL_ROOT_PASSWORD: Sinath@90
       MYSQL_DATABASE: wordpress
       MYSQL_USER: yuen
       MYSQL_PASSWORD: Sinath90
     networks:
       - npm
  wordpress:
     depends_on:
       - db
     image: wordpress:latest
     container_name: "wp_app"
     expose:
       - "80"
       - "443"
     links:
       - db
     restart: always
     environment:
       WORDPRESS_DB_HOST: db:3306
       WORDPRESS_DB_USER: username
       WORDPRESS_DB_PASSWORD: password
       WORDPRESS_DB_NAME: wordpress
       WORDPRESS_WPLANG: zh-CN
     volumes:
       - $PWD/wp-content:/var/www/html/wp-content
     networks:
       - npm
networks:
  npm:
    external: true
```