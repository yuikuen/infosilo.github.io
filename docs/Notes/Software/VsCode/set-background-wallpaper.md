1）首先在应用商店找到 `background` 插件

2）安装后打开扩展设置，修改 `settings.json` 文件，或通过命令 `ctrl+shift+p` 输入 `Preferences: Open User Settings(JSON)`

```json
    "background.customImages": [
        "file:///home/yuen/Pictures/background01.png",
        "file:///home/yuen/Pictures/background02.png"
    ],
    "background.styles": [
    	//第一张图片属性
        {
            "content":"''",
            "pointer-events":"none",
            "position":"absolute",//图片位置属性
            "bottom":"-60px",
            "width":"100%",
            "height":"100%",
            "z-index":"99999",
            "background.repeat":"no-repeat",
            "background-size":"40%,40%",//图片大小，可以根据自己需要修改
            "opacity":0.3
        },
        //第二张图片属性
        {
            "content":"''",
            "pointer-events":"none",
            "position":"absolute",
            "width":"100%",
            "height":"100%",
            "z-index":"99999",
            "background.repeat":"no-repeat",
            "background-size":"120%,120%",
            "opacity":0.1
        }
        
    ],
    "background.useFront": true,
    "background.useDefault": false,
```

PS：两张背景图只有分屏的情况下才会显示第二张，图片最好添加png格式透明背景图，这样效果更好

如需要全屏壁纸可按如下示例进行配置，另外其它配置可参考 [vscode-background 插件说明](https://marketplace.visualstudio.com/items?itemName=shalldie.background)

**示例1**：调用网络图片

```json
"background.fullscreen": {
    // "image": "https://img9.doubanio.com/view/activity_page/raw/public/4944.jpg", // url of your image
    "image": [
        "https://img9.doubanio.com/view/activity_page/raw/public/4944.jpg",
        "https://img1.doubanio.com/view/activity_page/raw/public/4897.jpg",
        "https://img9.doubanio.com/view/activity_page/raw/public/4945.jpg"
    ], // An array may be useful when set interval for carousel
    "opacity": 0.9, // 0.85 ~ 0.95 recommended
    "size": "cover", // also css, `cover` to self-adaption (recommended)，or `contain`、`200px 200px`
    "position": "center", // alias to `background-position`, default `center`
    "interval": 60 // seconds of interval for carousel, default `0` to disabled.
}
```

**示例2**：调用本地图片

```json
"background.fullscreen": {
        "image": "file:///home/yuen/Pictures/wallhaven-3z1kx6.png",
        "opacity": 0.91,
        "size": "cover",
        "position": "center",
        "interval": 0
    }
```

**插件异常问题**

1. 在 ubuntu vscode 安装 background 插件后不显示壁纸，可在终端输入以下命令个性 vscode 拥有者权限

```sh
$ sudo chown -R $(whoami) /usr/share/code
```

2. 如修改参数后提示"Code 安装损坏，请重新安装或不受支持等"，可安装 `Fix VSCode Checksums` 的扩展进行修复，`ctrl+shift+p` 打开命令面板，输入 `Fix Checksums: Apply`，重启警告即消失