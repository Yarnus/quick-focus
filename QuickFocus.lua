local ADDON_NAME, ns = ...

local addon = CreateFrame("Frame")
ns.addon = addon

local FOCUS_MACRO = "QF_Focus"
local MACRO_ICON = 134400
local DB_VERSION = 2
local BUTTON_NAME = ADDON_NAME .. "ClickButton"

local locale = GetLocale()
local isChinese = locale == "zhCN" or locale == "zhTW"
local L = isChinese and {
    DEFAULT_MESSAGE = "我打断{markName}{mark} {focusName}",
    MARKS = { "星星", "圆圈", "菱形", "三角", "月亮", "方块", "红叉", "骷髅" },
    MODIFIERS = { "Shift + 左键", "Alt + 左键", "Ctrl + 左键" },
    CHANNELS = {
        "关闭",
        "队伍 (/p)",
        "团队 (/ra)",
        "副本 (/i)",
        "团队警告 (/rw)",
        "说 (/s)",
        "喊 (/y)",
        "自定义",
    },
    MESSAGE_TOO_LONG = "喊话内容过长，宏超过 255 字节，已保留旧设置。",
    MACRO_FULL = "宏栏已满，无法创建 %s。",
    MACRO_CREATE_FAILED = "无法创建或更新 %s，请打开宏界面检查宏名称和可用宏槽。",
    ENABLED = "已启用。",
    DISABLED = "已停用。",
    RUNNING = "运行中",
    NOT_RUNNING = "未运行",
    KEY = "按键",
    MACRO_LENGTH = "宏长度",
    TOO_LONG = "（过长）",
    COMMAND_HELP = "命令：/qf、/qf on、/qf off、/qf status",
} or {
    DEFAULT_MESSAGE = "I interrupt {markName}{mark} {focusName}",
    MARKS = { "Star", "Circle", "Diamond", "Triangle", "Moon", "Square", "Cross", "Skull" },
    MODIFIERS = { "Shift + Left Click", "Alt + Left Click", "Ctrl + Left Click" },
    CHANNELS = {
        "Disabled",
        "Party (/p)",
        "Raid (/ra)",
        "Instance (/i)",
        "Raid Warning (/rw)",
        "Say (/s)",
        "Yell (/y)",
        "Custom",
    },
    MESSAGE_TOO_LONG = "The callout is too long and exceeds the 255-byte macro limit. The previous settings were kept.",
    MACRO_FULL = "The macro slots are full. Unable to create %s.",
    MACRO_CREATE_FAILED = "Unable to create or update %s. Open the macro UI and check the macro name and available slots.",
    ENABLED = "Enabled.",
    DISABLED = "Disabled.",
    RUNNING = "Running",
    NOT_RUNNING = "Not running",
    KEY = "Key",
    MACRO_LENGTH = "Macro length",
    TOO_LONG = " (too long)",
    COMMAND_HELP = "Commands: /qf, /qf on, /qf off, /qf status",
}
ns.L = L
ns.isChinese = isChinese

local DEFAULTS = {
    enabled = true,
    modifier = "SHIFT",
    mark = 8,
    clearOnBlank = true,
    chatMode = "PARTY",
    customCommand = "",
    message = L.DEFAULT_MESSAGE,
    version = DB_VERSION,
}

local installedFrames = {}
local frameModifiers = {}

local MARKS = {
    { 1, L.MARKS[1], "{rt1}" },
    { 2, L.MARKS[2], "{rt2}" },
    { 3, L.MARKS[3], "{rt3}" },
    { 4, L.MARKS[4], "{rt4}" },
    { 5, L.MARKS[5], "{rt5}" },
    { 6, L.MARKS[6], "{rt6}" },
    { 7, L.MARKS[7], "{rt7}" },
    { 8, L.MARKS[8], "{rt8}" },
}

local MODIFIERS = {
    { "SHIFT", L.MODIFIERS[1], "SHIFT-BUTTON1", "shift" },
    { "ALT", L.MODIFIERS[2], "ALT-BUTTON1", "alt" },
    { "CTRL", L.MODIFIERS[3], "CTRL-BUTTON1", "ctrl" },
}

local CHANNELS = {
    { "NONE", L.CHANNELS[1], nil },
    { "PARTY", L.CHANNELS[2], "p" },
    { "RAID", L.CHANNELS[3], "ra" },
    { "INSTANCE", L.CHANNELS[4], "i" },
    { "RAID_WARNING", L.CHANNELS[5], "rw" },
    { "SAY", L.CHANNELS[6], "s" },
    { "YELL", L.CHANNELS[7], "y" },
    { "CUSTOM", L.CHANNELS[8], false },
}

ns.MARKS = MARKS
ns.MODIFIERS = MODIFIERS
ns.CHANNELS = CHANNELS

local function Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99QuickFocus|r " .. tostring(message))
end

local function Clean(value)
    if type(value) ~= "string" then
        return ""
    end
    return (value:gsub("[%c]+", " "):match("^%s*(.-)%s*$"))
end

local function Find(options, value)
    for index = 1, #options do
        if options[index][1] == value then
            return options[index], index
        end
    end
end

local function ApplyDefaults(db)
    for key, value in pairs(DEFAULTS) do
        if db[key] == nil then
            db[key] = value
        end
    end
end

local function SafeSetAttribute(frame, key, value)
    return pcall(frame.SetAttribute, frame, key, value)
end

local function SafeGetAttribute(frame, key)
    local ok, value = pcall(frame.GetAttribute, frame, key)
    if ok then
        return value
    end
end

local function SafeGetChildren(frame)
    local ok, children = pcall(function()
        return { frame:GetChildren() }
    end)
    return ok and children or nil
end

local function SafeGetMacroBody(index)
    local ok, _, _, body = pcall(GetMacroInfo, index)
    return ok, body
end

function addon:GetDB()
    return self.db
end

function addon:GetMark(value)
    return Find(MARKS, value)
end

function addon:GetModifier(value)
    return Find(MODIFIERS, value)
end

function addon:GetChannel(value)
    return Find(CHANNELS, value)
end

function addon:GetBindingLabel()
    local option = self:GetModifier(self.db.modifier)
    return option and option[2] or MODIFIERS[1][2]
end

function addon:GetBindingChord()
    local option = self:GetModifier(self.db.modifier)
    return option and option[3] or MODIFIERS[1][3]
end

function addon:GetModifierAttribute()
    local option = self:GetModifier(self.db.modifier)
    return option and option[4] or MODIFIERS[1][4]
end

function addon:GetChatCommand()
    local option = self:GetChannel(self.db.chatMode)
    if not option then
        return nil
    end
    if option[1] ~= "CUSTOM" then
        return option[3]
    end

    local command = Clean(self.db.customCommand):gsub("^/", "")
    return command ~= "" and command or nil
end

function addon:GetMessage()
    local message = Clean(self.db.message)
    if message == "" then
        message = DEFAULTS.message
    end

    local mark = self:GetMark(self.db.mark) or MARKS[#MARKS]
    message = message:gsub("{focusName}", "%%f")
    message = message:gsub("{markName}", mark[2])
    return message:gsub("{mark}", mark[3])
end

function addon:BuildFocusMacro()
    local lines = {
        "/stopmacro [@mouseover,exists,noharm][@mouseover,dead]"
    }
    if self.db.clearOnBlank then
        lines[#lines + 1] = "/tm [@focus,exists] 0"
        lines[#lines + 1] = "/clearfocus [@mouseover,noexists]"
        lines[#lines + 1] = "/stopmacro [@mouseover,noexists]"
    else
        lines[#lines + 1] = "/stopmacro [@mouseover,noexists]"
        lines[#lines + 1] = "/tm [@focus,exists] 0"
    end
    lines[#lines + 1] = "/focus [@mouseover,harm,nodead]"
    local command = self:GetChatCommand()
    if command then
        lines[#lines + 1] = "/" .. command .. " " .. self:GetMessage()
    end
    lines[#lines + 1] = "/tm [@focus,exists,harm,nodead] " .. self.db.mark
    return table.concat(lines, "\n")
end

function addon:GetMacroPreview()
    local body = self:BuildFocusMacro()
    return body, #body, #body <= 255
end

function addon:EnsureMacro(name, body)
    local index = GetMacroIndexByName(name)
    if index and index > 0 then
        local ok, currentBody = SafeGetMacroBody(index)
        if not ok then
            return nil, "CREATE_FAILED"
        end
        if currentBody ~= body then
            local ok, editedIndex = pcall(EditMacro, index, name, MACRO_ICON, body)
            if not ok or not editedIndex or editedIndex == 0 then
                return nil, "CREATE_FAILED"
            end
        end
        return name
    end

    if #body > 255 then
        return nil, "TOO_LONG"
    end

    local generalCount, characterCount = GetNumMacros()
    if characterCount < MAX_CHARACTER_MACROS then
        local ok
        ok, index = pcall(CreateMacro, name, MACRO_ICON, body, true)
        if ok and index and index > 0 then
            return name
        end
    end
    if generalCount < MAX_ACCOUNT_MACROS then
        local ok
        ok, index = pcall(CreateMacro, name, MACRO_ICON, body, false)
        if ok and index and index > 0 then
            return name
        end
    end
    if characterCount >= MAX_CHARACTER_MACROS and generalCount >= MAX_ACCOUNT_MACROS then
        return nil, "NO_SLOT"
    end
    return nil, "CREATE_FAILED"
end

function addon:CreateClickButton()
    if self.clickButton then
        return self.clickButton
    end

    local button = CreateFrame(
        "Button",
        BUTTON_NAME,
        UIParent,
        "SecureActionButtonTemplate"
    )
    local okType = SafeSetAttribute(button, "type1", "macro")
    local okMacro = SafeSetAttribute(button, "macro", FOCUS_MACRO)
    if not okType or not okMacro then
        return nil
    end
    button:RegisterForClicks("AnyDown", "AnyUp")
    self.clickButton = button
    return button
end

function addon:ClearFrameBindings(frame)
    for index = 1, #MODIFIERS do
        local prefix = MODIFIERS[index][4]
        SafeSetAttribute(frame, prefix .. "-type1", nil)
        SafeSetAttribute(frame, prefix .. "-macro1", nil)
    end
    frameModifiers[frame] = nil
end

function addon:SetupUnitFrame(frame)
    if not frame or type(frame.SetAttribute) ~= "function" then
        return
    end
    if InCombatLockdown() then
        self.pendingFrames = self.pendingFrames or {}
        self.pendingFrames[frame] = true
        return
    end

    local prefix = self:GetModifierAttribute()
    if frameModifiers[frame] ~= prefix then
        self:ClearFrameBindings(frame)
    end
    local okType = SafeSetAttribute(frame, prefix .. "-type1", "macro")
    local okMacro = SafeSetAttribute(frame, prefix .. "-macro1", FOCUS_MACRO)
    if not okType or not okMacro then
        return
    end
    frameModifiers[frame] = prefix
    installedFrames[frame] = true
    self.pendingFrames = self.pendingFrames or {}
    self.pendingFrames[frame] = nil
end

function addon:ClearUnitFrameBindings()
    if InCombatLockdown() then
        return
    end
    for frame in pairs(installedFrames) do
        self:ClearFrameBindings(frame)
        installedFrames[frame] = nil
    end
end

function addon:RefreshUnitFrameBindings()
    if InCombatLockdown() then
        return
    end
    local frames = {}
    for frame in pairs(installedFrames) do
        frames[#frames + 1] = frame
    end
    for index = 1, #frames do
        local frame = frames[index]
        self:ClearFrameBindings(frame)
        self:SetupUnitFrame(frame)
    end
end

function addon:SetupPendingFrames()
    if not self.pendingFrames then
        return
    end
    for frame in pairs(self.pendingFrames) do
        self:SetupUnitFrame(frame)
    end
end

function addon:HookUnitFrameCreation()
    if self.createFrameHooked then
        return
    end
    self.createFrameHooked = true
    hooksecurefunc("CreateFrame", function(_, name, parent, template)
        if addon.active and template and template:find("SecureUnitButtonTemplate", 1, true) then
            addon:SetupUnitFrame(name and _G[name])
        end
    end)
end

function addon:SetupFrameTree(frame)
    if not frame or type(frame.GetChildren) ~= "function" then
        return
    end
    local unit = type(frame.GetAttribute) == "function" and SafeGetAttribute(frame, "unit")
    if unit then
        self:SetupUnitFrame(frame)
    end
    local children = SafeGetChildren(frame)
    if not children then
        return
    end
    for index = 1, #children do
        self:SetupFrameTree(children[index])
    end
end

function addon:SetupNamePlateUnitFrame(unitToken)
    if not C_NamePlate or not C_NamePlate.GetNamePlateForUnit then
        return
    end
    local plate = C_NamePlate.GetNamePlateForUnit(unitToken)
    self:SetupFrameTree(plate)
end

function addon:ClearClickBindings()
    if self.clickButton then
        ClearOverrideBindings(self.clickButton)
    end
end

function addon:SetupClickBindings()
    local button = self:CreateClickButton()
    if not button then
        return false
    end
    self:ClearClickBindings()
    return pcall(SetOverrideBindingClick, button, true, self:GetBindingChord(), BUTTON_NAME)
end

function addon:Disable()
    self:ClearClickBindings()
    self:ClearUnitFrameBindings()
    self.active = false
end

function addon:Refresh()
    if not self.db then
        return
    end
    if InCombatLockdown() then
        self.pendingRefresh = true
        return
    end

    self.pendingRefresh = false
    if not self.db.enabled then
        self:Disable()
        ns.RefreshOptions()
        return
    end

    local focusName, reason = self:EnsureMacro(FOCUS_MACRO, self:BuildFocusMacro())
    if not focusName then
        self:Disable()
        if reason == "TOO_LONG" then
            Print(L.MESSAGE_TOO_LONG)
        elseif reason == "NO_SLOT" then
            Print(L.MACRO_FULL:format(FOCUS_MACRO))
        else
            Print(L.MACRO_CREATE_FAILED:format(FOCUS_MACRO))
        end
        ns.RefreshOptions()
        return
    end

    if not self:SetupClickBindings() then
        self:Disable()
        Print(L.MACRO_CREATE_FAILED:format(FOCUS_MACRO))
        ns.RefreshOptions()
        return
    end
    self:HookUnitFrameCreation()
    self:RefreshUnitFrameBindings()
    self:SetupPendingFrames()
    self.active = true
    ns.RefreshOptions()
end

function addon:ApplySettings()
    if self.refreshQueued then
        return
    end
    self.refreshQueued = true
    C_Timer.After(0, function()
        self.refreshQueued = false
        self:Refresh()
    end)
end

function addon:Cycle(options, key, offset)
    local _, index = Find(options, self.db[key])
    index = (index or 1) + offset
    if index < 1 then
        index = #options
    elseif index > #options then
        index = 1
    end
    self.db[key] = options[index][1]
    self:ApplySettings()
end

function addon:OpenOptions()
    if ns.OpenOptions then
        ns.OpenOptions()
    end
end

function addon:HandleSlash(input)
    local command = Clean(input):lower()
    if command == "" or command == "config" then
        self:OpenOptions()
    elseif command == "on" then
        self.db.enabled = true
        self:ApplySettings()
        Print(L.ENABLED)
    elseif command == "off" then
        self.db.enabled = false
        self:ApplySettings()
        Print(L.DISABLED)
    elseif command == "status" then
        local _, length, valid = self:GetMacroPreview()
        Print((self.active and L.RUNNING or L.NOT_RUNNING)
            .. "; " .. L.KEY .. ": " .. self:GetBindingLabel()
            .. "; " .. L.MACRO_LENGTH .. ": " .. length .. "/255"
            .. (valid and "" or L.TOO_LONG))
    else
        Print(L.COMMAND_HELP)
    end
end

function addon:Initialize()
    if type(QuickFocusDB) ~= "table" then
        QuickFocusDB = {}
    end
    self.db = QuickFocusDB
    local previousVersion = tonumber(self.db.version) or 0
    ApplyDefaults(self.db)

    if not self:GetMark(self.db.mark) then
        self.db.mark = DEFAULTS.mark
    end
    if not self:GetModifier(self.db.modifier) then
        self.db.modifier = DEFAULTS.modifier
    end
    if not self:GetChannel(self.db.chatMode) then
        self.db.chatMode = DEFAULTS.chatMode
    end
    self.db.enabled = self.db.enabled ~= false
    self.db.clearOnBlank = self.db.clearOnBlank == true
    if previousVersion < DB_VERSION then
        self.db.clearOnBlank = true
        self.db.version = DB_VERSION
    end
    self.db.customCommand = Clean(self.db.customCommand)
    self.db.message = Clean(self.db.message)

    SLASH_QUICKFOCUS1 = "/quickfocus"
    SLASH_QUICKFOCUS2 = "/qf"
    SlashCmdList.QUICKFOCUS = function(input)
        self:HandleSlash(input)
    end
end

ns.RefreshOptions = function() end

addon:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == ADDON_NAME then
            self:Initialize()
        end
    elseif event == "PLAYER_LOGIN" then
        self:ApplySettings()
    elseif event == "PLAYER_ENTERING_WORLD" then
        self:ApplySettings()
    elseif event == "UPDATE_MACROS" and self.db and self.db.enabled then
        if GetMacroIndexByName(FOCUS_MACRO) == 0 then
            self:ApplySettings()
        end
    elseif event == "NAME_PLATE_UNIT_ADDED" then
        if self.db and self.db.enabled and not InCombatLockdown() then
            self:SetupNamePlateUnitFrame(arg1)
        end
    elseif event == "GROUP_ROSTER_UPDATE" then
        if self.db and self.db.enabled and not InCombatLockdown() then
            self:SetupPendingFrames()
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        if self.pendingRefresh then
            self:Refresh()
        else
            self:SetupPendingFrames()
        end
    end
end)

addon:RegisterEvent("ADDON_LOADED")
addon:RegisterEvent("PLAYER_LOGIN")
addon:RegisterEvent("PLAYER_ENTERING_WORLD")
addon:RegisterEvent("UPDATE_MACROS")
addon:RegisterEvent("PLAYER_REGEN_ENABLED")
addon:RegisterEvent("GROUP_ROSTER_UPDATE")
addon:RegisterEvent("NAME_PLATE_UNIT_ADDED")
