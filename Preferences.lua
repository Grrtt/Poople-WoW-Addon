local _, addon = ...
local panel, minimapButton, options, callbacks

local function label(parent, value, x, y)
    local text = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("TOPLEFT", x, y)
    text:SetText(value)
    return text
end

local function finite(value)
    return type(value) == "number" and value == value and math.abs(value) < math.huge
end

local function positionMinimapButton()
    local radians = math.rad(options.minimapAngle)
    local x = math.cos(radians) * (Minimap:GetWidth() / 2 + 8)
    local y = math.sin(radians) * (Minimap:GetHeight() / 2 + 8)
    minimapButton:ClearAllPoints()
    minimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function updateMinimapButton()
    positionMinimapButton()
    minimapButton:SetShown(options.showMinimap)
end

local function checkbox(parent, name, title, y, key)
    local control = CreateFrame("CheckButton", name, parent, "UICheckButtonTemplate")
    control:SetPoint("TOPLEFT", 18, y)
    control:SetChecked(options[key])
    label(parent, title, 54, y - 8)
    control:SetScript("OnClick", function(self)
        options[key] = self:GetChecked() and true or false
        updateMinimapButton()
        callbacks.changed()
    end)
    control:SetScript("OnShow", function(self) self:SetChecked(options[key]) end)
    return control
end

local function createPanel()
    panel = CreateFrame("Frame", "PoopleSettingsWindow", UIParent, "BackdropTemplate")
    panel:SetSize(360, 320)
    panel:SetPoint("CENTER", UIParent, "CENTER", 260, 0)
    panel:SetFrameStrata("DIALOG")
    panel:SetClampedToScreen(true)
    panel:EnableMouse(true)
    panel:SetMovable(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", function(self) self:StartMoving() end)
    panel:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    panel:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16 })
    panel:SetBackdropColor(0.075, 0.08, 0.10, 1)
    label(panel, "Poople settings", 22, -22)
    local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)
    close:SetScript("OnClick", function() panel:Hide() end)
    local opacityLabel = label(panel, "", 22, -65)
    local slider = CreateFrame("Slider", "PoopleBackgroundOpacity", panel, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", 26, -97)
    slider:SetWidth(304)
    slider:SetMinMaxValues(0, 100)
    slider:SetValueStep(1)
    slider:SetObeyStepOnDrag(true)
    _G[slider:GetName() .. "Low"]:SetText("0%")
    _G[slider:GetName() .. "High"]:SetText("100%")
    slider:SetScript("OnValueChanged", function(_, value)
        local percent = math.floor(value + 0.5)
        options.backgroundOpacity = percent / 100
        opacityLabel:SetText("Background opacity: " .. percent .. "%")
        callbacks.changed()
    end)
    panel:SetScript("OnShow", function()
        local percent = math.floor(options.backgroundOpacity * 100 + 0.5)
        slider:SetValue(percent)
        opacityLabel:SetText("Background opacity: " .. percent .. "%")
    end)
    checkbox(panel, "PoopleShowMinimap", "Show minimap button", -145, "showMinimap")
    panel.lockWindow = checkbox(panel, "PoopleLockWindow", "Lock game window position", -185, "lockWindow")
    local reset = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    reset:SetPoint("TOPLEFT", 22, -237)
    reset:SetSize(200, 26)
    reset:SetText("Reset window position")
    reset:SetScript("OnClick", callbacks.resetPosition)
    label(panel, "Changes are saved automatically.", 22, -284)
    table.insert(UISpecialFrames, "PoopleSettingsWindow")
    panel:Hide()
end

function addon.ShowSettings()
    if not panel then createPanel() end
    panel:Show()
end

function addon.SetWindowLocked(locked)
    options.lockWindow = locked
    if panel then panel.lockWindow:SetChecked(locked) end
    callbacks.changed()
end

local function createMinimapButton()
    minimapButton = CreateFrame("Button", "PoopleMinimapButton", Minimap)
    minimapButton:SetSize(32, 32)
    minimapButton:SetFrameStrata("MEDIUM")
    minimapButton:SetFrameLevel(Minimap:GetFrameLevel() + 8)
    minimapButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    minimapButton:RegisterForDrag("LeftButton")
    minimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    local icon = minimapButton:CreateTexture(nil, "BACKGROUND")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER")
    icon:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
    local border = minimapButton:CreateTexture(nil, "OVERLAY")
    border:SetSize(54, 54)
    border:SetPoint("TOPLEFT")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    minimapButton:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "RightButton" then addon.ShowSettings() else callbacks.toggle() end
    end)
    minimapButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("Poople")
        GameTooltip:AddLine("Left-click: open or close the game", 1, 1, 1)
        GameTooltip:AddLine("Right-click: settings", 1, 1, 1)
        GameTooltip:AddLine("Drag: move around the minimap", 1, 1, 1)
        GameTooltip:Show()
    end)
    minimapButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
    minimapButton:SetScript("OnDragStart", function(self)
        GameTooltip:Hide()
        self:SetScript("OnUpdate", function()
            local x, y = GetCursorPosition()
            local centerX, centerY = Minimap:GetCenter()
            local scale = Minimap:GetEffectiveScale()
            options.minimapAngle = math.deg(math.atan2(y / scale - centerY, x / scale - centerX))
            positionMinimapButton()
        end)
    end)
    minimapButton:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
    minimapButton:SetScript("OnHide", function(self) self:SetScript("OnUpdate", nil) end)
    updateMinimapButton()
end

function addon.InitializePreferences(db, handlers)
    callbacks = handlers
    db.settings = type(db.settings) == "table" and db.settings or {}
    options = db.settings
    if not finite(options.backgroundOpacity) then options.backgroundOpacity = 0.98 end
    options.backgroundOpacity = math.max(0, math.min(1, options.backgroundOpacity))
    if type(options.showMinimap) ~= "boolean" then options.showMinimap = true end
    if type(options.lockWindow) ~= "boolean" then options.lockWindow = false end
    if not finite(options.minimapAngle) then options.minimapAngle = 225 end
    createMinimapButton()
end
