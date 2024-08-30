> Chrome 在打开个别网站时提示错误代码：`NET::ERR_CERT_AUTHORITY_INVALID`

原因在于，chrome 浏览器新加入了 HSTS 策略，使用 HSTS 策略是 chrome 加入的新特性，使用该策略的网站，会强制浏览器使用 HTTPS 协议与该网站通信。

HTTPS 和 HTTP 的区别在于，用 HTTPS 协议时传输的数据是加密的（TSL 和 SSL），而用 HTTP 传输时是明文传输，造成证书不受信的可能情况有：

1. 第三方证书没有及时更新
2. 第三方服务器不安全
3. 证书不是由可信第三方颁布

**解决方法**

- 首先清理缓存，清除浏览数据，如果还解决不了，因为 Chrome 是默认使用 HSTS 传输，严格的http 传输方式
- 在 Chrome 浏览框输入 `chrome://net-internals/#hsts`，查询域名的内容并删除安全证书

![](https://img.17121203.xyz/i/2024/08/27/nlsq2u-0.webp)

总结上述内容，因为 https 网站被劫持了，然后 Chrome 又默认使用 HSTS，才导致无法访问，最后通过上述方法可以解决网站被劫持现象