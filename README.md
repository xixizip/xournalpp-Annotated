# AnnotatedPages — Xournal++ Plugin

提取当前文档中所有**有批注页面的页码**，自动合并为范围字符串（如 `1-3,5,7-9`），并**一键写入剪贴板**。

---

## 安装方法

### Windows
将整个 `AnnotatedPages` 文件夹复制到：
```
C:\Users\<你的用户名>\AppData\Local\xournalpp\plugins\
```

### Linux
```bash
cp -r AnnotatedPages ~/.config/xournalpp/plugins/
```

### macOS
```bash
cp -r AnnotatedPages ~/Library/Application\ Support/xournalpp/plugins/
```

---

## 使用方法

1. 打开 Xournal++ 并加载你的 `.xopp` 文件
2. 点击菜单 **Plugin → Get Annotated Pages**
   （或按快捷键 `Ctrl+Shift+A`）
3. 弹出对话框显示批注页码范围，同时**自动复制到剪贴板**

---

## 剪贴板依赖（Linux）

| 环境 | 需要的工具 |
|------|-----------|
| Wayland | `wl-clipboard`（`wl-copy` 命令） |
| X11 | `xclip` 或 `xsel` |

安装示例（Ubuntu/Debian）：
```bash
sudo apt install xclip        # X11 用户
sudo apt install wl-clipboard # Wayland 用户
```

macOS 和 Windows 无需额外安装任何工具。

---

## 输出格式

| 批注页 | 输出 |
|--------|------|
| 1, 2, 3, 5, 6, 9 | `1-3,5-6,9` |
| 1, 3, 5 | `1,3,5` |
| 2, 3, 4, 5, 6 | `2-6` |

---

## 版本

- `2.0.0` — 跨平台重写：支持 Windows / Linux / macOS，输出范围格式，直接复制到剪贴板
