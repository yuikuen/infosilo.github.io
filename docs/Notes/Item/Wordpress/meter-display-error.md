> 修复 WordPress 仪表板显示错误

问题描述：LNMP 部署 WordPress 后，前端显示正常，但后台登录后仪表显示错乱

![](https://img.17121203.xyz/i/2024/10/19/nad5fm-0.webp)

解决方法：

> 参考链接：<https://manovotny.com/fix-wordpress-admin-styles-not-loading>
>
> A user suggested, non-WordPress core hack that might work for some is to add the following code to your `wp-config.php` file, *before* any `require_once` calls.

```sh
define( 'CONCATENATE_SCRIPTS', false );
```

注意：需要在声明的顶部、注释之后添加

```php
<?php
/**
 * The base configuration for WordPress
 *
 * The wp-config.php creation script uses this file during the installation.
 * You don't have to use the web site, you can copy this file to "wp-config.php"
 * and fill in the values.
 *
 * This file contains the following configurations:
 *
 * * Database settings
 * * Secret keys
 * * Database table prefix
 * * ABSPATH
 *
 * @link https://wordpress.org/documentation/article/editing-wp-config-php/
 *
 * @package WordPress
 */

// ** Database settings - You can get this info from your web host ** //
/** The name of the database for WordPress */

define( 'CONCATENATE_SCRIPTS', false );
```