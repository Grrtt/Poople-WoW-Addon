-- Run from the addon repository root: luajit tests/run.lua
local root = arg[0]:match("^(.*)tests/[^/]+$") or "./"
local addon = {}
assert(loadfile(root .. "Words.lua"))("Poople", addon)
assert(loadfile(root .. "Game.lua"))("Poople", addon)
local Game = addon.Game
local checks = 0
local function check(condition, message)
    checks = checks + 1
    assert(condition, message)
end

-- Independently calculate graph distances by substituting alphabet letters.
local dictionary, count = {}, 0
for word in addon.WordData:gmatch("%u+") do
    check(#word == 4 and not dictionary[word], "Dictionary entries must be unique four-letter words")
    dictionary[word], count = true, count + 1
end
check(count == 3903, "Unexpected dictionary size")
local distances, queue, head = { POOP = 0 }, { "POOP" }, 1
while head <= #queue do
    local word = queue[head]
    for i = 1, 4 do
        for letter = 65, 90 do
            local neighbor = word:sub(1, i - 1) .. string.char(letter) .. word:sub(i + 1)
            if dictionary[neighbor] and distances[neighbor] == nil then
                distances[neighbor] = distances[word] + 1
                queue[#queue + 1] = neighbor
            end
        end
    end
    head = head + 1
end
for word in pairs(dictionary) do
    check(Game.Distance(word) == distances[word], "Incorrect shortest distance for " .. word)
end

local session = assert(Game.New(" cold "))
check(session.start == "COLD", "Normalize custom words")
for _, word in ipairs({ "COLD", "WARM", "ZZZZ", "TOOLONG", "C0LD", "" }) do
    local size = #session.path
    check(not Game.Submit(session, word), "Reject invalid move " .. word)
    check(#session.path == size, "Invalid moves must preserve progress")
end
check(Game.Submit(session, "cord"), "Accept lowercase valid moves")
check(Game.Undo(session) and #session.path == 1, "Undo one move")
check(not Game.Undo(session), "Do not undo the start")
check(not Game.New("ZZZZ"), "Reject unknown starts")
check(not Game.New("POOP"), "Reject already completed starts")
for word in pairs(dictionary) do
    if not distances[word] then
        check(not Game.New(word), "Reject disconnected starts")
        break
    end
end

local stats = {}
for day = 20000, 20364 do
    local start = Game.DailyStart(day)
    check(start == Game.DailyStart(day), "Daily puzzle must be deterministic")
    local daily = assert(Game.New(start, "daily", day))
    local par = distances[start]
    check(par >= 3, "Daily puzzles must require at least three moves")
    while not daily.won do
        local previous = daily.path[#daily.path]
        local hint = Game.Hint(daily)
        check(hint and Game.OneLetterApart(previous, hint), "Hints must change exactly one letter")
        check(distances[hint] == distances[previous] - 1, "Hints must follow a shortest path")
        check(Game.Submit(daily, hint), "Hints must be playable")
    end
    check(#daily.path - 1 == par, "Hint route must meet par")
    check(not Game.Undo(daily) and not Game.Submit(daily, "POOL"), "Completed games must be final")
    local restored = Game.Restore(daily, "daily", day)
    check(restored and restored.won and restored.hints == daily.hints, "Restore completed daily game")
    check(not Game.Restore(daily, "daily", day + 1), "Reject stale daily game")
    Game.RecordWin(stats, daily)
    Game.RecordWin(stats, daily)
end
check(stats.wins == 365 and stats.streak == 365 and stats.bestStreak == 365, "Count each daily win once")
local later = assert(Game.New(Game.DailyStart(20366), "daily", 20366))
while not later.won do assert(Game.Submit(later, Game.Hint(later))) end
Game.RecordWin(stats, later)
check(stats.streak == 1 and stats.bestStreak == 365, "Reset streak after a missed day")
local wins = stats.wins
session = assert(Game.New("POOL"))
assert(Game.Submit(session, "POOP"))
Game.RecordWin(stats, session)
check(stats.wins == wins, "Practice must not affect daily stats")
check(Game.Result(session):find("POOL > POOP", 1, true), "Results include the played ladder")
check(not Game.Restore({ mode = "practice", start = "COLD", path = { "COLD", "POOP" } }, "practice"), "Reject invalid saved moves")
check(not Game.Restore({ mode = "practice", start = {}, path = {} }, "practice"), "Reject malformed saves")
check(Game.Restore({ mode = "practice", start = "COLD", path = { "COLD" }, hints = "bad" }, "practice").hints == 0, "Validate saved hint counts")

-- Exercise startup, controls, persistence, and UTC rollover with a WoW UI stub.
local controls, named = {}, {}
local methods = {}
for _, name in ipairs({ "SetPoint", "ClearAllPoints", "SetClampedToScreen", "SetFrameStrata", "SetMovable", "EnableMouse", "RegisterForDrag", "StartMoving", "StopMovingOrSizing", "SetBackdrop", "SetBackdropColor", "SetBackdropBorderColor", "SetAutoFocus", "SetMaxLetters", "SetMultiLine", "SetFontObject", "HighlightText", "SetJustifyH", "SetJustifyV", "SetSpacing", "RegisterEvent", "UnregisterEvent" }) do
    methods[name] = function() end
end
function methods:SetSize(w, h) self.width, self.height = w, h end
function methods:SetWidth(w) self.width = w end
function methods:SetHeight(h) self.height = h end
function methods:GetHeight() return self.height end
function methods:GetStringHeight() local _, lines = (self.value or ""):gsub("\n", ""); return (lines + 1) * 20 end
function methods:SetText(value) self.value = value end
function methods:GetText() return self.value or "" end
function methods:SetEnabled(value) self.enabled = value end
function methods:SetNormalTexture(value) self.normalTexture = value end
function methods:SetPushedTexture(value) self.pushedTexture = value end
function methods:GetNormalTexture() return { SetTexCoord = function() end } end
function methods:GetPushedTexture() return { SetTexCoord = function() end } end
function methods:SetScript(name, callback) self.scripts[name] = callback end
function methods:Show() self.shown = true; if self.scripts.OnShow then self.scripts.OnShow(self) end end
function methods:SetShown(value) if value then self:Show() else self:Hide() end end
function methods:SetBackdropColor(r, g, b, a) self.backdropAlpha = a end
function methods:SetMovable(value) self.movable = value end
function methods:StartMoving() self.moving = true end
function methods:StopMovingOrSizing() self.moving = false end
function methods:SetPoint(point, relative, relativePoint, x, y)
    self.anchor = { point, relative, relativePoint, x, y }
end
function methods:GetPoint() return unpack(self.anchor) end
function methods:GetWidth() return self.width end
function methods:GetName() return self.name end
function methods:GetFrameLevel() return 1 end
function methods:GetCenter() return 100, 100 end
function methods:GetEffectiveScale() return 1 end
function methods:SetChecked(value) self.checked = value end
function methods:GetChecked() return self.checked end
function methods:SetValue(value)
    self.value = value
    if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self, value) end
end
for _, name in ipairs({ "SetFrameLevel", "RegisterForClicks", "SetHighlightTexture", "SetTexture", "SetColorTexture", "SetTexCoord", "SetMinMaxValues", "SetValueStep", "SetObeyStepOnDrag" }) do
    methods[name] = function() end
end
function methods:Hide() self.shown = false; if self.scripts.OnHide then self.scripts.OnHide(self) end end
function methods:IsShown() return self.shown end
function methods:SetFocus() self.focus = true end
function methods:ClearFocus() self.focus = false end
function methods:SetScrollChild(child) self.child = child end
function methods:SetVerticalScroll(offset) self.offset = offset end
local function control(kind, name)
    local value = setmetatable({ kind = kind, name = name, scripts = {}, shown = true }, { __index = methods })
    controls[#controls + 1] = value
    if name then named[name] = value end
    return value
end
function methods:CreateFontString() return control("FontString") end
function methods:CreateTexture() return control("Texture") end
function CreateFrame(kind, name, _, template)
    local frame = control(kind, name)
    if template == "UIPanelCloseButton" then frame:SetSize(32, 32) end
    if template == "OptionsSliderTemplate" then
        _G[name .. "Low"] = control("FontString")
        _G[name .. "High"] = control("FontString")
    end
    return frame
end
UIParent, UISpecialFrames, SlashCmdList = {}, {}, {}
Minimap = control("Frame")
Minimap:SetSize(140, 140)
GameTooltip = { Hide = function() end }
function GetCursorPosition() return 180, 100 end
local day = 21000
function GetServerTime() return day * 86400 end
date = os.date
assert(loadfile(root .. "Preferences.lua"))("Poople", addon)
assert(loadfile(root .. "Poople.lua"))("Poople", addon)
local events = controls[#controls]
events.scripts.OnEvent(events, "ADDON_LOADED", "OtherAddon")
check(not SlashCmdList.POOPLE, "Wait for this addon's saved variables")
events.scripts.OnEvent(events, "ADDON_LOADED", "Poople")
SlashCmdList.POOPLE("")
check(named.PoopleWindow:IsShown() and PoopleDB.daily.day == day, "Open daily puzzle")
SlashCmdList.POOPLE("")
check(not named.PoopleWindow:IsShown(), "Toggle window closed")
SlashCmdList.POOPLE("start POOL")
local function click(label)
    for _, widget in ipairs(controls) do
        if widget.kind == "Button" and widget.value == label then widget.scripts.OnClick(widget); return end
    end
    error("Missing button: " .. label)
end
local guess
for _, widget in ipairs(controls) do
    if widget.kind == "EditBox" and widget.width == 138 then guess = widget end
end
guess:SetText("POOP")
guess.scripts.OnEnterPressed(guess)
check(PoopleDB.practice.won and not guess.enabled, "Complete puzzle through text input")
click("Copy result")
check(named.PoopleWindow.result:IsShown(), "Show copyable result")
named.PoopleWindow:Hide()
check(not named.PoopleWindow.result:IsShown(), "Close result with the main window")
SlashCmdList.POOPLE("daily")
day = day + 1
guess:SetText("POOP")
guess.scripts.OnEnterPressed(guess)
check(PoopleDB.daily.day == day and #PoopleDB.daily.path == 1, "Rollover must not submit a stale guess")
click("New practice")
check(PoopleDB.activeMode == "practice" and Game.Distance(PoopleDB.practice.start), "Practice button creates a solvable puzzle")
click("Hint")
check(PoopleDB.practice.hints == 1, "Hint button persists hint use")
local minimap = named.PoopleMinimapButton
check(minimap:IsShown(), "Minimap button must be visible by default")
minimap.scripts.OnClick(minimap, "LeftButton")
check(not named.PoopleWindow:IsShown(), "Minimap left-click closes the game")
minimap.scripts.OnClick(minimap, "LeftButton")
check(named.PoopleWindow:IsShown(), "Minimap left-click opens the game")
minimap.scripts.OnClick(minimap, "RightButton")
check(named.PoopleSettingsWindow:IsShown(), "Minimap right-click opens settings")
named.PoopleBackgroundOpacity:SetValue(35)
check(PoopleDB.settings.backgroundOpacity == 0.35 and named.PoopleWindow.backdropAlpha == 0.35,
    "Opacity changes must apply immediately and persist")
click("Copy result")
check(named.PoopleWindow.result.backdropAlpha == 0.35, "Result background uses the saved opacity")
named.PoopleBackgroundOpacity:SetValue(0)
check(named.PoopleWindow.backdropAlpha == 0, "Allow a fully transparent background")
named.PoopleBackgroundOpacity:SetValue(100)
check(named.PoopleWindow.backdropAlpha == 1, "Allow a fully opaque background")
local title = named.PoopleTitleBar
title.scripts.OnDragStart(title)
check(named.PoopleWindow.moving, "Drag the title bar to move the game")
named.PoopleWindow:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 25, -40)
title.scripts.OnDragStop(title)
check(not named.PoopleWindow.moving and PoopleDB.position[3] == 25 and PoopleDB.position[4] == -40,
    "Stopping a drag must save the position")
local lock = named.PoopleLockWindow
lock:SetChecked(true)
lock.scripts.OnClick(lock)
title.scripts.OnDragStart(title)
check(PoopleDB.settings.lockWindow and not named.PoopleWindow.moving and not named.PoopleWindow.movable,
    "Lock prevents window dragging")
lock:SetChecked(false)
lock.scripts.OnClick(lock)
check(named.PoopleWindow.movable, "Unlock restores window dragging")
local titleLock = named.PoopleWindowLockButton
titleLock.scripts.OnClick(titleLock)
check(PoopleDB.settings.lockWindow and lock:GetChecked() and not named.PoopleWindow.movable,
    "Title lock button synchronizes the settings checkbox and prevents moving")
titleLock.scripts.OnClick(titleLock)
check(not PoopleDB.settings.lockWindow and not lock:GetChecked() and named.PoopleWindow.movable,
    "Title unlock button synchronizes the settings checkbox and restores moving")
click("Reset window position")
check(not PoopleDB.position and named.PoopleWindow.anchor[1] == "CENTER", "Reset recenters the window")
local show = named.PoopleShowMinimap
show:SetChecked(false)
show.scripts.OnClick(show)
check(not minimap:IsShown() and not PoopleDB.settings.showMinimap, "Hide the minimap button")
named.PoopleSettingsWindow:Hide()
SlashCmdList.POOPLE("settings")
check(named.PoopleSettingsWindow:IsShown(), "Slash command opens settings when the minimap button is hidden")
show:SetChecked(true)
show.scripts.OnClick(show)
minimap.scripts.OnDragStart(minimap)
minimap.scripts.OnUpdate(minimap)
minimap.scripts.OnDragStop(minimap)
check(PoopleDB.settings.minimapAngle == 0 and not minimap.scripts.OnUpdate, "Minimap drag persists the angle and stops updating")
-- Simulate reloading Lua files with the same saved variables.
named.PoopleBackgroundOpacity:SetValue(35)
show:SetChecked(false)
show.scripts.OnClick(show)
assert(loadfile(root .. "Preferences.lua"))("Poople", addon)
assert(loadfile(root .. "Poople.lua"))("Poople", addon)
events = controls[#controls]
events.scripts.OnEvent(events, "ADDON_LOADED", "Poople")
SlashCmdList.POOPLE("")
check(named.PoopleWindow.backdropAlpha == 0.35 and not named.PoopleMinimapButton:IsShown(),
    "Opacity and minimap visibility survive reload")
print(string.format("Passed %d checks (%d dictionary words, 365 daily puzzles, UI smoke test).", checks, count))
