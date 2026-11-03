# FinderSideButtons

让 macOS 访达支持鼠标侧键返回 / 前进。轻量、无 Dock 图标的原生 Swift 菜单栏工具。

A tiny native macOS menu bar app that enables mouse side-button back/forward navigation in Finder.

## 功能

- 默认鼠标第 4 键返回、第 5 键前进（系统按钮编号 3 / 4）。
- 仅当访达位于前台时生效，使用访达原生 `⌘[` / `⌘]` 导航。
- 菜单栏可暂停、交换返回与前进；交换设置会保存。
- 没有第三方依赖、网络请求、遥测或按键记录。
- macOS 13+，仅支持 Apple Silicon（M 系列芯片），不支持 Intel。

这是一款后台辅助应用。Apple 的 [Finder Sync 扩展](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/Finder.html)面向同步标记与菜单，并非通用输入扩展，所以侧键处理使用系统 CGEventTap API。

## 命令安装

在终端运行（无需 sudo，无需安装 Xcode）：

```bash
curl -fsSL https://raw.githubusercontent.com/TheShowMy/FinderSideButtons/v0.1.0/install.sh -o /tmp/FinderSideButtons-install.sh
bash /tmp/FinderSideButtons-install.sh
```

可以先阅读下载的脚本。脚本从 GitHub Release 下载 v0.1.0，核对 SHA-256 和应用签名完整性，安装至 `~/Applications/FinderSideButtons.app` 并启动。校验和用于检查下载完整性；它不是 Apple 开发者身份认证。

首次启动后：

1. 打开 **系统设置 → 隐私与安全性 → 辅助功能**。
2. 开启 **FinderSideButtons**；未出现在列表时，点击 `+`，选择 `~/Applications/FinderSideButtons.app`。
3. 菜单栏状态变为“已启用”后，在访达中打开几个文件夹，用侧键返回、前进。
4. 如果方向相反，点击菜单栏的 **交换返回 / 前进**。

应用不自动设置开机启动。如需要，在 **系统设置 → 通用 → 登录项** 中将应用加入登录时打开。

### 签名与权限

当前发行版使用 ad-hoc 签名，**没有 Developer ID 签名或 Apple 公证**。如果 macOS 阻止打开，请按系统提示在 **隐私与安全性** 中检查并允许该应用；也可以按下文自行编译。安装脚本不会关闭 Gatekeeper、清除隔离标记或代替你授予权限。

辅助功能权限用于拦截侧键并向访达发送导航快捷键。应用只订阅额外鼠标按键事件，不监听键盘输入。更新后如果授权失效，请在辅助功能列表移除旧条目，重新添加并启动应用。

### 兼容性

- 鼠标应上报普通第 4 / 5 键。如果厂商驱动把侧键改成键盘快捷键、手势或其他动作，请先恢复普通侧键设置。
- 请避免让另一个鼠标工具同时对访达侧键做映射。
- 快捷键使用美式键盘的方括号键位；非标准键盘布局或修改过访达快捷键的环境需要实际验证。
- 仅支持访达前台窗口，不会为其他应用的“打开 / 保存”对话框增加导航。
- 首版已验证事件路由测试和构建；不同鼠标、键盘布局以及实际辅助功能授权后的导航仍需实机验收。

## 从源码构建

需要 Xcode 15+（或提供 Swift 5.9+ 和 macOS SDK 的开发工具）。

```bash
git clone https://github.com/TheShowMy/FinderSideButtons.git
cd FinderSideButtons
swift test
bash scripts/build.sh
ditto dist/FinderSideButtons.app ~/Applications/FinderSideButtons.app
open ~/Applications/FinderSideButtons.app
```

构建脚本生成 arm64 `.app`、ZIP 和 `SHA256SUMS` 到 `dist/`。修改源码后重新构建可能需要重新授予辅助功能权限。

## 卸载

先从菜单栏退出，再执行：

```bash
rm -rf ~/Applications/FinderSideButtons.app
defaults delete io.github.TheShowMy.FinderSideButtons 2>/dev/null || true
```

如曾添加登录项或辅助功能授权，可在系统设置中移除对应条目。

## 开发与验收

```bash
swift test
bash -n install.sh scripts/build.sh
bash scripts/build.sh
codesign --verify --deep --strict dist/FinderSideButtons.app
lipo -archs dist/FinderSideButtons.app/Contents/MacOS/FinderSideButtons
```

手动检查：授权前显示等待；授权后侧键各导航一次；浏览器等其他应用的侧键行为不变；暂停和交换方向有效；按下侧键后切换应用再松开不会泄漏半个点击；撤销权限后显示等待。硬件验收不能用纯路由单元测试替代。

## License

[MIT](LICENSE)
