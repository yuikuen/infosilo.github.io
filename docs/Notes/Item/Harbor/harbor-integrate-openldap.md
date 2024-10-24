> Harbor 集成 OpenLDAP 账户，实现统一认证管理

1）LDAP 添加 `memberof` 模块

此处不作过多的介绍，详细操作过程可查询 [OpenLDAP 开启memberof模块](../openldap_开启memberof模块)

2）创建用户 & 组

```bash
$ cat > /etc/openldap/myldif/add_harbor-group.ldif << EOF
dn: uid=op001,ou=op,ou=People,dc=yuikuen,dc=top
uid: op001
cn: op001
sn: op001
givenName: yuen
displayName: yuikuen
objectClass: top
objectClass: posixAccount
objectClass: shadowAccount
objectClass: inetOrgPerson
uidNumber: 1000
gidNumber: 1000
gecos: System Manager
loginShell: /bin/bash
homeDirectory: /home/ldapusers
userPassword: {SHA}fEqNCco3Yq9h5ZUglD3CZJT4lBs= 
shadowLastChange: 17654
shadowMin: 0
shadowMax: 999999
shadowWarning: 7
shadowExpire: -1
employeeNumber: 10001
homePhone: 0769-xxxxxxxx
mobile: 181xxxxxxxx
mail: yuikuen.yuen@hotmail.com
postalAddress: DongGuan
initials: Sys_Engineer

dn: cn=harbor,ou=Group,dc=yuikuen,dc=top
objectClass: groupOfUniqueNames
cn: harbor
uniqueMember: uid=op001,ou=op,ou=People,dc=yuikuen,dc=top
EOF

$ ldapadd -x -w "Admin@123" -D "cn=Manager,dc=yuikuen,dc=top" -f add_harbor-group.ldif
```

![](https://img.17121203.xyz/i/2024/10/24/re4o7h-0.webp)

注：另一个同事 `op002` 是通过 Web-Ui 添加进组，主要为了验证 `memberof` 功能

3）Harbor 修改认证模式，详细可参考如下配置

> 如有不理解的配置参数，可点 `i` 查看介绍

![](https://img.17121203.xyz/i/2024/10/24/reaodw-0.webp)

最终效果如下图所示，只有 `harbor` 组内成员和原管理员可登录，其他用户无法访问

![](https://img.17121203.xyz/i/2024/10/24/rencsx-0.webp)

| 配置             | 参数                                                         | 说明                                                         |
| ---------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| LDAP URL         | ldap://188.188.4.204                                         | LDAP 服务器地址                                              |
| LDAP 搜索 DN     | cn=Manager,dc=yuikuen,dc=top                                 | LDAP_DN 管理员账号，具体搜索权限的 DN 用户                   |
| LDAP 搜索密码    | *                                                            | LDAP_DN 管理员密码                                           |
| LDAP 基础 DN     | ou=People,dc=yuikuen,dc=top                                  | LDAP/AD,用于查找人的基础 DN                                  |
| LDAP 过滤器      | (&(objectclass=posixAccount)(memberof=cn=harbor,ou=Group,dc=yuikuen,dc=top)) | memberof 用户组的过滤属性                                    |
| LDAP 用户 UID    | cn                                                           | 搜索中用来匹配的属性，如 cn,uid,email                        |
| LDAP 搜索范围    | 子树/本层/下一层                                             | 搜索的范围                                                   |
| LDAP 组基础 DN   | ou=Group,dc=yuikuen,dc=top                                   | LDAP/AD,用于查找组的基础 DN                                  |
| LDAP 组过滤器    | objectclass=groupOfUniqueNames                               | LDAP 组的过滤器                                              |
| LDAP 组 ID 属性  | cn                                                           | LDAP 组的 GID,用于匹配用户的一个属性，如 uid,cn 或其它       |
| LDAP 组管理员 DN | cn=harbor,ou=group,dc=yuikuen,dc=top                         | LDAP 组管理员 DN，所有组内用户都会有管理员权限，此属性可为空 |
| LDAP 组成员      | memberof                                                     | LDAP 组成员的 membership 属性，默认为 memberof/ismemberof    |
| LDAP 搜索范围    | 子树/本层/下一导                                             | 搜索范围                                                     |
| LDAP 检查证书    | 勾选                                                         | 检查来自LDAP 服务端的证书                                    |