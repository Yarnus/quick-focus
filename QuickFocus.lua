local ADDON_NAME, ns = ...

local addon = CreateFrame("Frame")
ns.addon = addon

local FOCUS_MACRO = "QF_Focus"
local CLEAR_MACRO = "QF_Clear"
local MACRO_ICON = "INV_Misc_QuestionMark"
local STATE_NAME = "quickfocus"

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
    CLEAR_MACRO_FULL = "宏栏已满，空白处清除功能暂不可用。",
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
    CLEAR_MACRO_FULL = "The macro slots are full. Clear-on-blank is temporarily unavailable.",
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
    clearOnBlank = false,
    chatMode = "PARTY",
    customCommand = "",
    message = L.DEFAULT_MESSAGE,
}

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
    { "SHIFT", L.MODIFIERS[1], "SHIFT-BUTTON1" },
    { "ALT", L.MODIFIERS[2], "ALT-BUTTON1" },
    { "CTRL", L.MODIFIERS[3], "CTRL-BUTTON1" },
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
        "/focus [@mouseover,harm,nodead]",
        "/tm [@focus,exists,harm,nodead] 0",
    }
    local command = self:GetChatCommand()
    if command then
        lines[#lines + 1] = "/" .. command .. " " .. self:GetMessage()
    end
    lines[#lines + 1] = "/tm [@focus,exists,harm,nodead] " .. self.db.mark
    return table.concat(lines, "\n")
end

function addon:BuildClearMacro()
    return "/tm [@focus,exists] 0\n/clearfocus [@focus,exists]"
end

function addon:GetMacroPreview()
    local body = self:BuildFocusMacro()
    return body, #body, #body <= 255
end

function addon:EnsureMacro(name, body)
    if #body > 255 then
        return nil, "TOO_LONG"
    end

    local index = GetMacroIndexByName(name)
    if index and index > 0 then
        local _, _, currentBody = GetMacroInfo(index)
        if currentBody ~= body then
            local ok
            ok, index = pcall(EditMacro, index, name, MACRO_ICON, body)
            if not ok or not index or index == 0 then
                return nil, "CREATE_FAILED"
            end
        end
        return name
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

function addon:GetStateCondition()
    if self.db.clearOnBlank and self.clearMacroReady then
        return "[@mouseover,harm,nodead] focus; [@mouseover,noexists] clear; none"
    end
    return "[@mouseover,harm,nodead] focus; none"
end

function addon:CreateDriver()
    if self.driver then
        return self.driver
    end

    local driver = CreateFrame(
        "Frame",
        ADDON_NAME .. "BindingDriver",
        UIParent,
        "SecureHandlerStateTemplate"
    )
    driver:SetAttribute("_onstate-" .. STATE_NAME, [[
        self:ClearBindings()
        local macro
        if newstate == "focus" then
            macro = self:GetAttribute("focusMacro")
        elseif newstate == "clear" then
            macro = self:GetAttribute("clearMacro")
        end
        local chord = self:GetAttribute("chord")
        if macro and chord then
            self:SetBindingMacro(true, chord, macro)
        end
    ]])
    self.driver = driver
    return driver
end

function addon:Disable()
    if self.driver then
        UnregisterStateDriver(self.driver, STATE_NAME)
        ClearOverrideBindings(self.driver)
    end
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

    self.clearMacroReady = false
    if self.db.clearOnBlank then
        local clearName, clearReason = self:EnsureMacro(CLEAR_MACRO, self:BuildClearMacro())
        self.clearMacroReady = clearName ~= nil
        if not clearName and not self.clearWarningShown then
            self.clearWarningShown = true
            if clearReason == "NO_SLOT" then
                Print(L.CLEAR_MACRO_FULL)
            else
                Print(L.MACRO_CREATE_FAILED:format(CLEAR_MACRO))
            end
        end
    else
        self.clearWarningShown = nil
    end

    local driver = self:CreateDriver()
    driver:SetAttribute("focusMacro", FOCUS_MACRO)
    driver:SetAttribute("clearMacro", self.clearMacroReady and CLEAR_MACRO or nil)
    driver:SetAttribute("chord", self:GetBindingChord())
    UnregisterStateDriver(driver, STATE_NAME)
    ClearOverrideBindings(driver)
    RegisterStateDriver(driver, STATE_NAME, self:GetStateCondition())
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
    elseif event == "PLAYER_REGEN_ENABLED" and self.pendingRefresh then
        self:Refresh()
    end
end)

addon:RegisterEvent("ADDON_LOADED")
addon:RegisterEvent("PLAYER_LOGIN")
addon:RegisterEvent("PLAYER_REGEN_ENABLED")
