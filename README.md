# QuickFocus

English | [简体中文](README.zh-CN.md)

QuickFocus is a lightweight WoW Retail addon that reimplements the core features of EasyFocus.

## Features

- Set a hostile unit as your focus with `Shift / Alt / Ctrl + Left Click`
- Automatically remove the previous focus marker and apply the configured raid marker to the new focus
- Optionally announce to party, raid, instance, raid warning, say, yell, or a custom channel
- Support the `{focusName}`, `{markName}`, and `{mark}` placeholders
- Optionally clear the focus and its marker with the same key combination when clicking an empty area
- Automatically defer setting changes made during combat until combat ends
- Automatically use Chinese on `zhCN`/`zhTW` clients and English on all other clients

On third-party unit frames and nameplates, QuickFocus uses the frame's native secure focus action for reliability. Marker and callout behavior still depends on the generated macro when a valid mouseover unit is available.

## Lightweight Design

- Installs secure click attributes on unit frames and nameplates
- Does not use `OnUpdate`
- Does not poll continuously
- Listens only for addon loading, login, macro changes, nameplates, roster changes, and leaving combat events
- Creates settings controls only when the settings page is opened for the first time
- Uses one character macro slot

Newer WoW clients restrict addons from dynamically executing `macrotext`. QuickFocus therefore uses one real macro with secure click attributes so protected actions continue to work during combat.

## Installation and Usage

Place the `QuickFocus` folder in `_retail_/Interface/AddOns/`, then enter one of the following commands in game:

- `/qf`: Open settings
- `/qf on`: Enable QuickFocus
- `/qf off`: Disable QuickFocus
- `/qf status`: Show the current status

The addon reserves the macro name `QF_Focus`.
