local _, ns = ...

local addon = ns.addon
local L = ns.L
local controls = {}

local TEXT = ns.isChinese and {
    DESCRIPTION = "敌对单位上按修饰键 + 左键：设置焦点、更新团队标记并按需喊话。"
        .. "无单位处可选清除焦点。无扫描、无轮询，战斗中设置会在脱战后应用。",
    ENABLE = "启用 QuickFocus",
    RAID_MARKER = "团队标记",
    TRIGGER_KEY = "触发按键",
    CLEAR_ON_BLANK = "无单位处使用相同按键时，清除焦点及其标记",
    CALLOUT_CHANNEL = "喊话频道",
    CUSTOM_COMMAND = "自定义命令",
    CALLOUT_MESSAGE = "喊话内容",
    PLACEHOLDERS = "占位符：{focusName} 焦点名字；{markName} 标记名称；{mark} 标记图标。",
    BINDING_ENABLED = "安全绑定已启用",
    BINDING_DISABLED = "安全绑定未启用",
    MACRO_LENGTH = "宏长度",
    MACRO_PREVIEW = "当前宏预览",
    COMMANDS = "命令：/qf 打开设置 · /qf on 启用 · /qf off 停用 · /qf status 查看状态",
    UNKNOWN = "未知",
} or {
    DESCRIPTION = "Modifier + Left Click on a hostile unit sets focus, updates its raid marker, and optionally sends a callout. "
        .. "The same key can clear focus over empty space. No scanning or polling; combat changes apply after combat.",
    ENABLE = "Enable QuickFocus",
    RAID_MARKER = "Raid marker",
    TRIGGER_KEY = "Trigger key",
    CLEAR_ON_BLANK = "Clear focus and its marker with the same key over empty space",
    CALLOUT_CHANNEL = "Callout channel",
    CUSTOM_COMMAND = "Custom command",
    CALLOUT_MESSAGE = "Callout message",
    PLACEHOLDERS = "Placeholders: {focusName} focus name; {markName} marker name; {mark} marker icon.",
    BINDING_ENABLED = "Secure binding enabled",
    BINDING_DISABLED = "Secure binding disabled",
    MACRO_LENGTH = "Macro length",
    MACRO_PREVIEW = "Current macro preview",
    COMMANDS = "Commands: /qf open settings · /qf on enable · /qf off disable · /qf status show status",
    UNKNOWN = "Unknown",
}

local function Label(parent, text, x, y, width, template)
    local label = parent:CreateFontString(nil, "ARTWORK", template or "GameFontNormal")
    label:SetPoint("TOPLEFT", x, y)
    if width then
        label:SetWidth(width)
    end
    label:SetJustifyH("LEFT")
    label:SetText(text)
    return label
end

local function SetCheckText(check, text)
    local label = check.Text or check.text
    if label then
        label:SetText(text)
    end
end

local function Refresh()
    if not controls.built or not addon:GetDB() then
        return
    end

    local db = addon:GetDB()
    local mark = addon:GetMark(db.mark)
    local modifier = addon:GetModifier(db.modifier)
    local channel = addon:GetChannel(db.chatMode)
    local body, length, valid = addon:GetMacroPreview()

    controls.enabled:SetChecked(db.enabled)
    controls.clearOnBlank:SetChecked(db.clearOnBlank)
    controls.mark:SetText(mark and (mark[1] .. " - " .. mark[2]) or TEXT.UNKNOWN)
    controls.modifier:SetText(modifier and modifier[2] or TEXT.UNKNOWN)
    controls.channel:SetText(channel and channel[2] or TEXT.UNKNOWN)
    controls.custom:SetText(db.customCommand or "")
    controls.custom:SetShown(db.chatMode == "CUSTOM")
    controls.customLabel:SetShown(db.chatMode == "CUSTOM")
    controls.message:SetText(db.message or "")
    controls.preview:SetText(body)
    controls.status:SetText(
        (addon.active and TEXT.BINDING_ENABLED or TEXT.BINDING_DISABLED)
            .. " · " .. TEXT.MACRO_LENGTH .. " " .. length .. "/255"
    )
    controls.status:SetTextColor(valid and 0.4 or 1, valid and 1 or 0.25, 0.3)
end

ns.RefreshOptions = Refresh

local function CycleButton(parent, x, y, direction, callback)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetPoint("TOPLEFT", x, y)
    button:SetSize(28, 24)
    button:SetText(direction < 0 and "<" or ">")
    button:SetScript("OnClick", function()
        callback(direction)
    end)
    return button
end

local function Build(panel)
    if controls.built then
        return
    end
    controls.built = true

    Label(panel, "QuickFocus", 16, -16, nil, "GameFontNormalLarge")
    Label(
        panel,
        TEXT.DESCRIPTION,
        16, -48, 760, "GameFontHighlight"
    )

    local enabled = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    enabled:SetPoint("TOPLEFT", 16, -90)
    SetCheckText(enabled, TEXT.ENABLE)
    enabled:SetScript("OnClick", function(self)
        addon:GetDB().enabled = self:GetChecked() == true
        addon:ApplySettings()
    end)
    controls.enabled = enabled

    Label(panel, TEXT.RAID_MARKER, 16, -140)
    CycleButton(panel, 120, -133, -1, function(offset)
        addon:Cycle(ns.MARKS, "mark", offset)
    end)
    controls.mark = Label(panel, "", 160, -140, 130)
    CycleButton(panel, 290, -133, 1, function(offset)
        addon:Cycle(ns.MARKS, "mark", offset)
    end)

    Label(panel, TEXT.TRIGGER_KEY, 16, -182)
    CycleButton(panel, 120, -175, -1, function(offset)
        addon:Cycle(ns.MODIFIERS, "modifier", offset)
    end)
    controls.modifier = Label(panel, "", 160, -182, 180)
    CycleButton(panel, 350, -175, 1, function(offset)
        addon:Cycle(ns.MODIFIERS, "modifier", offset)
    end)

    local clear = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    clear:SetPoint("TOPLEFT", 16, -218)
    SetCheckText(clear, TEXT.CLEAR_ON_BLANK)
    clear:SetScript("OnClick", function(self)
        addon:GetDB().clearOnBlank = self:GetChecked() == true
        addon:ApplySettings()
    end)
    controls.clearOnBlank = clear

    Label(panel, TEXT.CALLOUT_CHANNEL, 16, -270)
    CycleButton(panel, 120, -263, -1, function(offset)
        addon:Cycle(ns.CHANNELS, "chatMode", offset)
    end)
    controls.channel = Label(panel, "", 160, -270, 180)
    CycleButton(panel, 350, -263, 1, function(offset)
        addon:Cycle(ns.CHANNELS, "chatMode", offset)
    end)

    controls.customLabel = Label(panel, TEXT.CUSTOM_COMMAND, 16, -312)
    local custom = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    custom:SetPoint("TOPLEFT", 120, -305)
    custom:SetSize(220, 24)
    custom:SetAutoFocus(false)
    custom:SetMaxLetters(32)
    custom:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)
    custom:SetScript("OnEditFocusLost", function(self)
        addon:GetDB().customCommand = self:GetText() or ""
        addon:ApplySettings()
    end)
    controls.custom = custom

    Label(panel, TEXT.CALLOUT_MESSAGE, 16, -354)
    local message = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    message:SetPoint("TOPLEFT", 120, -347)
    message:SetSize(360, 24)
    message:SetAutoFocus(false)
    message:SetMaxLetters(160)
    message:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)
    message:SetScript("OnEditFocusLost", function(self)
        addon:GetDB().message = self:GetText() or ""
        addon:ApplySettings()
    end)
    controls.message = message

    Label(
        panel,
        TEXT.PLACEHOLDERS,
        120, -380, 620, "GameFontHighlightSmall"
    )

    controls.status = Label(panel, "", 16, -428, 760, "GameFontHighlight")
    Label(panel, TEXT.MACRO_PREVIEW, 16, -464)
    controls.preview = Label(panel, "", 16, -490, 760, "GameFontHighlightSmall")
    Label(
        panel,
        TEXT.COMMANDS,
        16, -610, 760, "GameFontHighlightSmall"
    )

    Refresh()
end

local panel = CreateFrame("Frame")
panel.name = "QuickFocus"
panel:SetScript("OnShow", function(self)
    Build(self)
    Refresh()
end)

local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name, panel.name)
Settings.RegisterAddOnCategory(category)

ns.OpenOptions = function()
    Settings.OpenToCategory(category:GetID())
end
