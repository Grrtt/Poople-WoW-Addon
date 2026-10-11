local addonName, addon = ...
local Game = addon.Game
local window, input, customInput, history, historyText, historyContent, board, status, subtitle, stats
local undoButton, hintButton, lockButton, lockSymbol, dragHint, session, db

local function applyAppearance()
    if not window then return end
    window:SetBackdropColor(0.075, 0.08, 0.10, db.settings.backgroundOpacity)
    window:SetMovable(not db.settings.lockWindow)
    if lockSymbol then
        local texture = db.settings.lockWindow and "LockButton-Locked-Up" or "LockButton-Unlocked-Up"
        lockSymbol:SetTexture("Interface\\Buttons\\" .. texture)
    end
    if dragHint then dragHint:SetText(db.settings.lockWindow and "Position locked" or "Drag to move") end
    if db.settings.lockWindow then window:StopMovingOrSizing() end
    if window.result then
        window.result:SetBackdropColor(0.06, 0.06, 0.08, db.settings.backgroundOpacity)
    end
end

local function resetPosition()
    db.position = nil
    if not window then return end
    window:StopMovingOrSizing()
    window:ClearAllPoints()
    window:SetPoint("CENTER")
end

local function startMoving()
    if not db.settings.lockWindow then window:StartMoving() end
end

local function stopMoving()
    window:StopMovingOrSizing()
    local point, _, relativePoint, x, y = window:GetPoint()
    db.position = { point, relativePoint, x, y }
end

local function today()
    return math.floor(GetServerTime() / 86400)
end

local function save()
    db[session.mode] = session
    db.activeMode = session.mode
end

local function setStatus(message)
    status:SetText(message or "")
end

local function historyLine(index, word, previous)
    local letters = {}
    for i = 1, 4 do
        local letter = word:sub(i, i)
        if previous and letter ~= previous:sub(i, i) then
            letter = "|cffffcc66" .. letter .. "|r"
        end
        letters[i] = letter
    end
    return string.format("%2d.  %s", index - 1, table.concat(letters, "  "))
end

local function render()
    local current = session.path[#session.path]
    for i = 1, 4 do board[i]:SetText(current:sub(i, i)) end
    local label = session.mode == "daily" and ("Daily · " .. date("!%Y-%m-%d", session.day * 86400)) or "Practice"
    subtitle:SetText(string.format("%s  |  %d moves  |  Par: %d", label, #session.path - 1, Game.Distance(session.start)))
    local lines = {}
    for i, word in ipairs(session.path) do
        lines[i] = historyLine(i, word, session.path[i - 1])
    end
    historyText:SetText(table.concat(lines, "\n"))
    local height = math.max(190, historyText:GetStringHeight() + 12)
    historyText:SetHeight(height)
    historyContent:SetHeight(height + 8)
    history:SetVerticalScroll(math.max(0, height - history:GetHeight()))
    undoButton:SetEnabled(not session.won and #session.path > 1)
    hintButton:SetEnabled(not session.won)
    input:SetEnabled(not session.won)
    local streak = (db.lastWonDay or -2) >= today() - 1 and (db.streak or 0) or 0
    stats:SetText(string.format("Daily wins: %d   Streak: %d   Best: %d", db.wins or 0, streak, db.bestStreak or 0))
    if session.won then
        setStatus(string.format("Reached POOP in %d moves. Par: %d. Hints: %d.",
            #session.path - 1, Game.Distance(session.start), session.hints))
        input:ClearFocus()
    end
end

local function startDaily()
    local day = today()
    session = Game.Restore(db.daily, "daily", day) or Game.New(Game.DailyStart(day), "daily", day)
    save()
    input:SetText("")
    setStatus("Change one letter per move. Your goal is POOP.")
    render()
end

local function startPractice(word)
    local nextSession, message = Game.New(word or Game.PracticeStart(), "practice")
    if not nextSession then setStatus(message); return end
    session = nextSession
    save()
    input:SetText("")
    customInput:SetText("")
    customInput:ClearFocus()
    setStatus("Practice puzzle started. Your daily progress is saved.")
    render()
    input:SetFocus()
end

local function submit()
    if session.mode == "daily" and session.day ~= today() then
        startDaily()
        setStatus("A new UTC day has started. Loaded today's puzzle.")
        return
    end
    local accepted, message = Game.Submit(session, input:GetText())
    if not accepted then setStatus(message); return end
    Game.RecordWin(db, session)
    save()
    input:SetText("")
    setStatus("Move accepted. Change one letter to continue.")
    render()
end

local function text(parent, font, x, y, width, content)
    local label = parent:CreateFontString(nil, "OVERLAY", font)
    label:SetPoint("TOPLEFT", x, y)
    label:SetWidth(width)
    label:SetJustifyH("LEFT")
    label:SetText(content or "")
    return label
end

local function button(parent, label, x, y, width, callback)
    local control = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    control:SetPoint("TOPLEFT", x, y)
    control:SetSize(width, 26)
    control:SetText(label)
    control:SetScript("OnClick", callback)
    return control
end

local function editBox(parent, x, y, width)
    local control = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    control:SetPoint("TOPLEFT", x, y)
    control:SetSize(width, 28)
    control:SetAutoFocus(false)
    control:SetMaxLetters(4)
    control:SetScript("OnEscapePressed", function(self) self:ClearFocus(); window:Hide() end)
    return control
end

local function createLockSymbol(parent)
    -- Keep the close button's frame; replace only the symbol in its center.
    local face = parent:CreateTexture(nil, "ARTWORK")
    face:SetSize(16, 16)
    face:SetPoint("CENTER")
    face:SetColorTexture(0.16, 0.025, 0.015, 1)
    lockSymbol = parent:CreateTexture(nil, "OVERLAY")
    lockSymbol:SetSize(12, 16)
    lockSymbol:SetPoint("CENTER")
    -- Crop the native 32px texture to the shaded padlock, excluding its frame.
    lockSymbol:SetTexCoord(11 / 32, 20 / 32, 10 / 32, 22 / 32)
end

local function showResult()
    local popup = window.result
    if not popup then
        popup = CreateFrame("Frame", nil, window, "BackdropTemplate")
        popup:SetSize(408, 176)
        popup:SetPoint("CENTER")
        popup:SetFrameStrata("DIALOG")
        popup:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16 })
        popup:SetBackdropColor(0.06, 0.06, 0.08, 1)
        text(popup, "GameFontNormal", 16, -16, 376, "Copy your result with Ctrl+C.")
        popup.input = CreateFrame("EditBox", nil, popup, "InputBoxTemplate")
        popup.input:SetPoint("TOPLEFT", 20, -44)
        popup.input:SetSize(368, 80)
        popup.input:SetMultiLine(true)
        popup.input:SetAutoFocus(false)
        popup.input:SetFontObject("GameFontHighlightSmall")
        popup.input:SetScript("OnEscapePressed", function() popup:Hide() end)
        popup:SetScript("OnHide", function() popup.input:ClearFocus() end)
        button(popup, "Close", 154, -138, 100, function() popup:Hide() end)
        window.result = popup
    end
    input:ClearFocus()
    customInput:ClearFocus()
    popup:Show()
    popup.input:SetText(Game.Result(session))
    popup.input:SetFocus()
    popup.input:HighlightText()
    applyAppearance()
end

local function createWindow()
    window = CreateFrame("Frame", "PoopleWindow", UIParent, "BackdropTemplate")
    window:SetSize(440, 650)
    window:SetPoint("CENTER")
    window:SetClampedToScreen(true)
    window:SetFrameStrata("DIALOG")
    window:SetMovable(true)
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", startMoving)
    window:SetScript("OnDragStop", stopMoving)
    window:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16 })
    window:SetBackdropColor(0.075, 0.08, 0.10, 0.98)
    window:SetBackdropBorderColor(0.65, 0.51, 0.30, 1)
    if type(db.position) == "table" and type(db.position[3]) == "number" and type(db.position[4]) == "number" then
        local anchors = { CENTER = true, TOP = true, BOTTOM = true, LEFT = true, RIGHT = true,
            TOPLEFT = true, TOPRIGHT = true, BOTTOMLEFT = true, BOTTOMRIGHT = true }
        if anchors[db.position[1]] and anchors[db.position[2]] then
            window:ClearAllPoints()
            window:SetPoint(db.position[1], UIParent, db.position[2], db.position[3], db.position[4])
        end
    end
    table.insert(UISpecialFrames, "PoopleWindow")
    local titleBar = CreateFrame("Frame", "PoopleTitleBar", window)
    titleBar:SetPoint("TOPLEFT", 16, -12)
    titleBar:SetSize(218, 32)
    titleBar:EnableMouse(true)
    titleBar:RegisterForDrag("LeftButton")
    titleBar:SetScript("OnDragStart", startMoving)
    titleBar:SetScript("OnDragStop", stopMoving)
    text(titleBar, "GameFontNormalLarge", 6, -10, 100, "POOPLE")
    dragHint = text(titleBar, "GameFontDisableSmall", 112, -13, 106, "Drag to move")
    button(window, "Settings", 244, -18, 84, addon.ShowSettings)
    local close = CreateFrame("Button", nil, window, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)
    close:SetScript("OnClick", function() window:Hide() end)
    lockButton = CreateFrame("Button", "PoopleWindowLockButton", window, "UIPanelCloseButton")
    lockButton:SetSize(close:GetWidth(), close:GetHeight())
    lockButton:SetPoint("RIGHT", close, "LEFT", -2, 0)
    createLockSymbol(lockButton)
    lockButton:SetScript("OnClick", function()
        addon.SetWindowLocked(not db.settings.lockWindow)
    end)
    lockButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine(db.settings.lockWindow and "Unlock window position" or "Lock window position")
        GameTooltip:Show()
    end)
    lockButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
    text(window, "GameFontHighlightSmall", 22, -50, 396, "Turn a four-letter word into POOP, one letter at a time.")
    subtitle = text(window, "GameFontNormal", 22, -77, 396)
    button(window, "Daily", 22, -102, 90, startDaily)
    button(window, "New practice", 118, -102, 130, function() startPractice() end)
    button(window, "Copy result", 254, -102, 164, showResult)

    text(window, "GameFontHighlightSmall", 22, -145, 396, "Current word")
    board = {}
    for i = 1, 4 do
        local tile = CreateFrame("Frame", nil, window, "BackdropTemplate")
        tile:SetPoint("TOPLEFT", 98 + (i - 1) * 62, -165)
        tile:SetSize(56, 56)
        tile:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
        tile:SetBackdropColor(0.20, 0.24, 0.29, 1)
        board[i] = tile:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
        board[i]:SetPoint("CENTER")
    end
    text(window, "GameFontHighlightSmall", 22, -237, 396, "Word ladder · changed letters appear in gold")
    history = CreateFrame("ScrollFrame", nil, window, "UIPanelScrollFrameTemplate")
    history:SetPoint("TOPLEFT", 22, -259)
    history:SetSize(370, 190)
    historyContent = CreateFrame("Frame", nil, history)
    historyContent:SetSize(366, 1)
    history:SetScrollChild(historyContent)
    historyText = text(historyContent, "GameFontHighlight", 4, -4, 360)
    historyText:SetSpacing(6)
    historyText:SetJustifyV("TOP")
    input = editBox(window, 28, -466, 138)
    input:SetScript("OnEnterPressed", submit)
    button(window, "Play word", 180, -466, 108, submit)
    undoButton = button(window, "Undo", 294, -466, 60, function()
        if Game.Undo(session) then
            save()
            setStatus("Last move removed.")
            render()
        end
    end)
    hintButton = button(window, "Hint", 360, -466, 58, function()
        local word = Game.Hint(session)
        save()
        if word then setStatus("Shortest-route hint: " .. word .. ". Hints used: " .. session.hints) end
    end)
    status = text(window, "GameFontHighlightSmall", 22, -505, 396)
    status:SetHeight(36)
    status:SetJustifyV("TOP")
    text(window, "GameFontHighlightSmall", 22, -549, 225, "Website start word (practice):")
    customInput = editBox(window, 258, -542, 68)
    local function customStart() startPractice(customInput:GetText()) end
    customInput:SetScript("OnEnterPressed", customStart)
    button(window, "Start", 338, -542, 80, customStart)
    stats = text(window, "GameFontNormalSmall", 22, -585, 396)
    text(window, "GameFontDisableSmall", 22, -611, 396, "Offline fan addon · independent dictionary and UTC daily puzzles")
    window:SetScript("OnHide", function()
        window:StopMovingOrSizing()
        input:ClearFocus()
        customInput:ClearFocus()
        if window.result then window.result:Hide() end
    end)
    applyAppearance()
    window:Hide()
end

local function showWindow()
    if not window then
        Game.Initialize()
        createWindow()
        session = db.activeMode == "practice" and Game.Restore(db.practice, "practice") or nil
        if session then render() else startDaily() end
    end
    if session.mode == "daily" and session.day ~= today() then startDaily() end
    window:Show()
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", function(self, _, name)
    if name ~= addonName then return end
    PoopleDB = type(PoopleDB) == "table" and PoopleDB or {}
    db = PoopleDB
    addon.InitializePreferences(db, {
        changed = applyAppearance,
        resetPosition = resetPosition,
        toggle = function()
            if window and window:IsShown() then window:Hide() else showWindow() end
        end,
    })
    self:UnregisterEvent("ADDON_LOADED")
    SLASH_POOPLE1 = "/poople"
    SlashCmdList.POOPLE = function(message)
        local command, word = message:match("^%s*(%S*)%s*(.-)%s*$")
        command = command:lower()
        if command == "settings" then addon.ShowSettings(); return end
        if command == "" and window and window:IsShown() then window:Hide(); return end
        showWindow()
        if command == "daily" then startDaily()
        elseif command == "practice" then startPractice()
        elseif command == "start" then startPractice(word)
        elseif command ~= "" then
            setStatus("Commands: /poople, /poople daily, /poople practice, /poople start WORD, /poople settings")
        end
    end
end)
