> PVE 每次登录都会提示：企业存储库需要有效订阅
>
> You do not have a valid subscription for this server. Please visit [www.proxmox.com](https://www.proxmox.com/proxmox-ve/pricing) to get a list of available options.

通过远程工具或内置 Shell 进行修改

```sh
$ cd /usr/share/javascript/proxmox-widget-toolkit/
# 搜索关键词Proxmox.Utils.getNoSubKeyHtml
    success: function(response, opts) {
            let res = response.result;
            // 新增下面这一行
            res.data.status = 'active'
            if (res === null || res === undefined || !res || res
            .data.status.toLowerCase() !== 'active') {
            Ext.Msg.show({
                title: gettext('No valid subscription'),
                icon: Ext.Msg.WARNING,
                message: Proxmox.Utils.getNoSubKeyHtml(res.data.url),
                buttons: Ext.Msg.OK,
                callback: function(btn) {
                if (btn !== 'ok') {
                    return;
                }
                orig_cmd();
                },
            });
            } else {
            orig_cmd();
            }
        }
```

或使用命令直接替换修改

```sh
$ sed -i.backup -z "s/res === null || res === undefined || \!res || res\n\t\t\t.data.status.toLowerCase() \!== 'active'/false/g" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js && systemctl restart pveproxy.service
```