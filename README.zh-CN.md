# QuickFocus

[English](README.md) | 简体中文

QuickFocus 是参照 EasyFocus 功能重新实现的 WoW Retail 轻量插件。

## 功能

- 敌对单位上按 `Shift / Alt / Ctrl + 左键` 设置焦点
- 自动移除旧焦点标记，并给新焦点添加指定团队标记
- 可选队伍、团队、副本、团队警告、说、喊或自定义频道喊话
- 支持 `{focusName}`、`{markName}`、`{mark}` 占位符
- 可选在无单位区域使用相同按键清除焦点及标记
- 战斗中修改设置时自动延迟到脱战后应用
- 根据 WoW 客户端语言自动选择中文（`zhCN`/`zhTW`）或英文界面

## 轻量设计

- 给单位框和姓名板安装安全点击属性
- 不使用 `OnUpdate`
- 不持续轮询
- 只监听加载、登录、宏变化、姓名板、队伍变化和脱战事件
- 设置控件只在首次打开设置页时创建
- 只占用 1 个角色宏槽

新版客户端限制插件动态执行 `macrotext`，因此 QuickFocus 使用一个真实宏配合安全点击属性，
以保证受保护动作在战斗中也能正常工作。

## 安装与使用

将 `QuickFocus` 文件夹放入 `_retail_/Interface/AddOns/`，进入游戏后输入：

- `/qf`：打开设置
- `/qf on`：启用
- `/qf off`：停用
- `/qf status`：查看运行状态

插件使用保留宏名 `QF_Focus`。
