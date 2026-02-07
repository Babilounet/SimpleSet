----------------------------------------------------------------------
-- SimpleSet v1.3
-- Save and load equipment sets with per-slot targeting
----------------------------------------------------------------------

local ADDON_NAME = "SimpleSet"
local MAX_SETS = 10

SimpleSetDB = SimpleSetDB or {}

-- Equipment slots
local SLOTS = {
    {name = "HeadSlot",          display = "Head"},
    {name = "NeckSlot",          display = "Neck"},
    {name = "ShoulderSlot",      display = "Shoulder"},
    {name = "BackSlot",          display = "Back"},
    {name = "ChestSlot",         display = "Chest"},
    {name = "ShirtSlot",         display = "Shirt"},
    {name = "TabardSlot",        display = "Tabard"},
    {name = "WristSlot",         display = "Wrist"},
    {name = "HandsSlot",         display = "Hands"},
    {name = "WaistSlot",         display = "Waist"},
    {name = "LegsSlot",          display = "Legs"},
    {name = "FeetSlot",          display = "Feet"},
    {name = "Finger0Slot",       display = "Ring 1"},
    {name = "Finger1Slot",       display = "Ring 2"},
    {name = "Trinket0Slot",      display = "Trinket 1"},
    {name = "Trinket1Slot",      display = "Trinket 2"},
    {name = "MainHandSlot",      display = "Main Hand"},
    {name = "SecondaryHandSlot", display = "Off Hand"},
    {name = "RangedSlot",        display = "Ranged"},
}

-- Cache slot IDs
local slotIDs = {}
for i, slot in ipairs(SLOTS) do
    slotIDs[i] = GetInventorySlotInfo(slot.name)
end

----------------------------------------------------------------------
-- Icons
----------------------------------------------------------------------

local DEFAULT_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

local PRESET_ICONS = {
    -- Gear
    "Interface\\Icons\\INV_Chest_Chain_04",
    "Interface\\Icons\\INV_Helmet_04",
    "Interface\\Icons\\INV_Shield_04",
    "Interface\\Icons\\INV_Sword_04",
    "Interface\\Icons\\INV_Axe_01",
    "Interface\\Icons\\INV_Mace_01",
    "Interface\\Icons\\INV_Staff_07",
    "Interface\\Icons\\INV_Weapon_Bow_05",
    "Interface\\Icons\\INV_Misc_Bag_07_Green",
    "Interface\\Icons\\Ability_DualWield",
    -- Warrior (Arms / Fury / Prot)
    "Interface\\Icons\\Ability_Warrior_SavageBlow",
    "Interface\\Icons\\Ability_Warrior_InnerRage",
    "Interface\\Icons\\Ability_Warrior_DefensiveStance",
    -- Paladin (Holy / Prot / Ret)
    "Interface\\Icons\\Spell_Holy_HolyBolt",
    "Interface\\Icons\\Spell_Holy_DevotionAura",
    "Interface\\Icons\\Spell_Holy_AuraOfLight",
    -- Hunter (BM / MM / Survival)
    "Interface\\Icons\\Ability_Hunter_BeastTaming",
    "Interface\\Icons\\Ability_Hunter_AimedShot",
    "Interface\\Icons\\Ability_Hunter_SwiftStrike",
    -- Rogue (Assassination / Combat / Subtlety)
    "Interface\\Icons\\Ability_Rogue_Eviscerate",
    "Interface\\Icons\\Ability_BackStab",
    "Interface\\Icons\\Ability_Stealth",
    -- Priest (Discipline / Shadow)
    "Interface\\Icons\\Spell_Holy_PowerWordShield",
    "Interface\\Icons\\Spell_Shadow_ShadowWordPain",
    -- Shaman (Elemental / Enhancement / Resto)
    "Interface\\Icons\\Spell_Nature_Lightning",
    "Interface\\Icons\\Spell_Nature_LightningShield",
    "Interface\\Icons\\Spell_Nature_MagicImmunity",
    -- Mage (Arcane / Fire / Frost)
    "Interface\\Icons\\Spell_Holy_MagicalSentry",
    "Interface\\Icons\\Spell_Fire_FireBolt02",
    "Interface\\Icons\\Spell_Frost_FrostBolt02",
    -- Warlock (Affliction / Demo / Destro)
    "Interface\\Icons\\Spell_Shadow_DeathCoil",
    "Interface\\Icons\\Spell_Shadow_ShadowBolt",
    "Interface\\Icons\\Spell_Shadow_RainOfFire",
    -- Druid (Balance / Feral / Resto)
    "Interface\\Icons\\Spell_Nature_StarFall",
    "Interface\\Icons\\Ability_Racial_BearForm",
    "Interface\\Icons\\Spell_Nature_HealingTouch",
}

----------------------------------------------------------------------
-- Forward declarations
----------------------------------------------------------------------

local settingsFrame, iconPicker, currentPickerIndex
local editBoxes, iconBtns, specBtns = {}, {}, {}
local minimapIcon

----------------------------------------------------------------------
-- Database
----------------------------------------------------------------------

local function initDB()
    if not SimpleSetDB.sets or #SimpleSetDB.sets == 0 then
        SimpleSetDB.sets = {
            {name = "Set 1", items = {}},
            {name = "Set 2", items = {}},
        }
    end
    SimpleSetDB.minimapAngle = SimpleSetDB.minimapAngle or 220
end

----------------------------------------------------------------------
-- Bag overlay helpers
----------------------------------------------------------------------

local function getSetItemNames()
    local names = {}
    if not SimpleSetDB.sets then return names end
    for _, set in ipairs(SimpleSetDB.sets) do
        if set.items then
            for _, itemName in pairs(set.items) do
                if itemName and itemName ~= false then
                    names[itemName] = true
                end
            end
        end
    end
    return names
end

----------------------------------------------------------------------
-- Core Functions
----------------------------------------------------------------------

local function saveSet(index)
    local set = SimpleSetDB.sets[index]
    if not set then return end
    set.items = {}
    for i = 1, #SLOTS do
        local link = GetInventoryItemLink("player", slotIDs[i])
        set.items[i] = link and GetItemInfo(link) or false
    end
    -- Auto-detect icon from main hand on first save
    if not set.icon then
        local tex = GetInventoryItemTexture("player", slotIDs[17])
        if tex then set.icon = tex end
    end
    print("|cff00ff00SimpleSet:|r \"" .. set.name .. "\" saved.")
end

local function loadSet(index)
    local set = SimpleSetDB.sets[index]
    if not set then return end
    if not set.items or #set.items == 0 then
        print("|cffff0000SimpleSet:|r \"" .. set.name .. "\" is empty.")
        return
    end

    local seen = {}
    local delay = 0

    for i = 1, #SLOTS do
        local itemName = set.items[i]
        if itemName and itemName ~= false then
            local currentLink = GetInventoryItemLink("player", slotIDs[i])
            local currentName = currentLink and GetItemInfo(currentLink)

            if currentName ~= itemName then
                if seen[itemName] then
                    delay = delay + 0.3
                end
                seen[itemName] = true

                local sid = slotIDs[i]
                local name = itemName
                if delay > 0 then
                    C_Timer.After(delay, function()
                        EquipItemByName(name, sid)
                    end)
                else
                    EquipItemByName(name, sid)
                end
            end
        end
    end
    print("|cff00ff00SimpleSet:|r \"" .. set.name .. "\" loaded.")
end

local function buildTooltip(index)
    local set = SimpleSetDB.sets[index]
    if not set or not set.items or #set.items == 0 then return "(empty)" end
    local lines = {}
    for i = 1, #SLOTS do
        local item = set.items[i]
        if item and item ~= false then
            lines[#lines + 1] = SLOTS[i].display .. ": " .. item
        end
    end
    return #lines > 0 and table.concat(lines, "\n") or "(empty)"
end

local function updateMinimapIcon()
    if not minimapIcon then return end
    for i, set in ipairs(SimpleSetDB.sets) do
        if set.items and #set.items > 0 then
            local match = true
            for j = 1, #SLOTS do
                local itemName = set.items[j]
                if itemName and itemName ~= false then
                    local link = GetInventoryItemLink("player", slotIDs[j])
                    local name = link and GetItemInfo(link)
                    if name ~= itemName then
                        match = false
                        break
                    end
                end
            end
            if match then
                minimapIcon:SetTexture(set.icon or DEFAULT_ICON)
                return
            end
        end
    end
    minimapIcon:SetTexture("Interface\\Icons\\INV_Helmet_04")
end

----------------------------------------------------------------------
-- Bag Lock Overlays (default bags fallback)
----------------------------------------------------------------------

local lockOverlays = {}

local function updateContainerLocks(frame)
    if not frame or not frame:IsShown() then return end
    local setItems = getSetItemNames()
    local bagID = frame:GetID()
    local frameName = frame:GetName()
    local numSlots = GetContainerNumSlots(bagID)

    for i = 1, numSlots do
        local btn = _G[frameName .. "Item" .. i]
        if btn then
            local link = GetContainerItemLink(bagID, btn:GetID())
            local name = link and GetItemInfo(link)
            local key = frameName .. "_" .. i

            if name and setItems[name] then
                if not lockOverlays[key] then
                    local tex = btn:CreateTexture(nil, "OVERLAY")
                    tex:SetSize(12, 12)
                    tex:SetPoint("TOPLEFT", 2, -2)
                    tex:SetTexture("Interface\\Buttons\\LockButton-Locked-Up")
                    lockOverlays[key] = tex
                end
                lockOverlays[key]:Show()
            elseif lockOverlays[key] then
                lockOverlays[key]:Hide()
            end
        end
    end
end

----------------------------------------------------------------------
-- Static Popups
----------------------------------------------------------------------

StaticPopupDialogs["SIMPLESET_CONFIRM_SAVE"] = {
    text = "Overwrite \"%s\"?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function(self, data)
        saveSet(data)
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

----------------------------------------------------------------------
-- Slash Commands
----------------------------------------------------------------------

SLASH_SIMPLESET1 = "/simpleset"
SLASH_SIMPLESET2 = "/ss"
SlashCmdList["SIMPLESET"] = function(msg)
    local cmd, arg = msg:match("^(%S+)%s*(.*)$")
    if not cmd then
        print("|cff00ff00SimpleSet:|r /ss save <n> | /ss load <n> | /ss list")
        return
    end
    cmd = cmd:lower()
    local n = tonumber(arg)
    if cmd == "save" and n then
        saveSet(n)
    elseif cmd == "load" and n then
        loadSet(n)
    elseif cmd == "list" then
        for i, set in ipairs(SimpleSetDB.sets) do
            local status = (set.items and #set.items > 0) and "saved" or "empty"
            print(string.format("  [%d] %s (%s)", i, set.name, status))
        end
    else
        print("|cff00ff00SimpleSet:|r /ss save <n> | /ss load <n> | /ss list")
    end
end

SLASH_UNEQUIPALL1 = "/unequipall"
SlashCmdList["UNEQUIPALL"] = function()
    for i = 1, #SLOTS do
        if GetInventoryItemLink("player", slotIDs[i]) then
            PickupInventoryItem(slotIDs[i])
            PutItemInBackpack()
            PutItemInBag(20)
            PutItemInBag(21)
            PutItemInBag(22)
            PutItemInBag(23)
        end
    end
    print("|cff00ff00SimpleSet:|r All equipment removed.")
end

----------------------------------------------------------------------
-- UI helpers
----------------------------------------------------------------------

local function refreshSettingsUI()
    local count = #SimpleSetDB.sets
    for i = 1, MAX_SETS do
        if i <= count then
            iconBtns[i]:SetNormalTexture(SimpleSetDB.sets[i].icon or DEFAULT_ICON)
            iconBtns[i]:Show()
            editBoxes[i]:SetText(SimpleSetDB.sets[i].name)
            editBoxes[i]:Show()
            local spec = SimpleSetDB.sets[i].spec
            if spec == 1 then
                specBtns[i]:SetText("|cff00ff00S1|r")
            elseif spec == 2 then
                specBtns[i]:SetText("|cffffcc00S2|r")
            else
                specBtns[i]:SetText("|cff888888--|r")
            end
            specBtns[i]:Show()
        else
            iconBtns[i]:Hide()
            editBoxes[i]:Hide()
            specBtns[i]:Hide()
        end
    end
    settingsFrame:SetHeight(65 + count * 30)
end

----------------------------------------------------------------------
-- UI: Icon Picker
----------------------------------------------------------------------

local function createIconPicker()
    local cols = 5
    local rows = math.ceil(#PRESET_ICONS / cols)

    iconPicker = CreateFrame("Frame", "SimpleSet_IconPicker", UIParent, "BackdropTemplate")
    iconPicker:SetFrameStrata("TOOLTIP")
    iconPicker:SetSize(cols * 32 + 14, rows * 32 + 14)
    iconPicker:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    iconPicker:Hide()
    iconPicker:EnableMouse(true)

    for idx, iconPath in ipairs(PRESET_ICONS) do
        local row = math.floor((idx - 1) / cols)
        local col = (idx - 1) % cols
        local btn = CreateFrame("Button", nil, iconPicker)
        btn:SetSize(28, 28)
        btn:SetPoint("TOPLEFT", 7 + col * 32, -(7 + row * 32))
        btn:SetNormalTexture(iconPath)
        btn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
        btn:SetScript("OnClick", function()
            if currentPickerIndex and SimpleSetDB.sets[currentPickerIndex] then
                SimpleSetDB.sets[currentPickerIndex].icon = iconPath
                if iconBtns[currentPickerIndex] then
                    iconBtns[currentPickerIndex]:SetNormalTexture(iconPath)
                end
            end
            iconPicker:Hide()
        end)
    end
end

----------------------------------------------------------------------
-- UI: Settings Frame
----------------------------------------------------------------------

local function createSettingsFrame()
    settingsFrame = CreateFrame("Frame", "SimpleSet_Settings", UIParent, "BasicFrameTemplateWithInset")
    settingsFrame:SetFrameStrata("DIALOG")
    settingsFrame:SetSize(280, 130)
    settingsFrame:SetPoint("CENTER", 0, 50)
    settingsFrame:Hide()
    settingsFrame:SetMovable(true)
    settingsFrame:EnableMouse(true)
    settingsFrame:RegisterForDrag("LeftButton")
    settingsFrame:SetScript("OnDragStart", settingsFrame.StartMoving)
    settingsFrame:SetScript("OnDragStop", settingsFrame.StopMovingOrSizing)
    settingsFrame:SetScript("OnHide", function() iconPicker:Hide() end)

    settingsFrame.title = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    settingsFrame.title:SetPoint("CENTER", settingsFrame.TitleBg, "CENTER", 5, 0)
    settingsFrame.title:SetText("SimpleSet")

    for i = 1, MAX_SETS do
        -- Icon button
        iconBtns[i] = CreateFrame("Button", nil, settingsFrame)
        iconBtns[i]:SetSize(22, 22)
        iconBtns[i]:SetPoint("TOPLEFT", 12, -28 - (i - 1) * 30)
        iconBtns[i]:SetNormalTexture(DEFAULT_ICON)
        iconBtns[i]:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
        iconBtns[i]:Hide()
        local idx = i
        iconBtns[i]:SetScript("OnClick", function(self)
            if currentPickerIndex == idx and iconPicker:IsShown() then
                iconPicker:Hide()
            else
                currentPickerIndex = idx
                iconPicker:ClearAllPoints()
                iconPicker:SetPoint("LEFT", self, "RIGHT", 5, 0)
                iconPicker:Show()
            end
        end)

        -- Name edit box
        editBoxes[i] = CreateFrame("EditBox", "SimpleSet_EB" .. i, settingsFrame, "InputBoxTemplate")
        editBoxes[i]:SetSize(150, 20)
        editBoxes[i]:SetPoint("LEFT", iconBtns[i], "RIGHT", 6, 0)
        editBoxes[i]:SetAutoFocus(false)
        editBoxes[i]:SetScript("OnEscapePressed", function(s) s:ClearFocus() end)
        editBoxes[i]:SetScript("OnEnterPressed", function(s) s:ClearFocus() end)
        editBoxes[i]:Hide()

        -- Spec binding button
        specBtns[i] = CreateFrame("Button", nil, settingsFrame, "UIPanelButtonTemplate")
        specBtns[i]:SetSize(28, 20)
        specBtns[i]:SetPoint("LEFT", editBoxes[i], "RIGHT", 4, 0)
        specBtns[i]:SetText("--")
        specBtns[i]:Hide()
        specBtns[i]:SetScript("OnClick", function()
            local set = SimpleSetDB.sets[idx]
            if not set then return end
            local cur = set.spec
            local nxt
            if not cur then
                nxt = 1
            elseif cur == 1 then
                nxt = 2
            else
                nxt = nil
            end
            -- Only one set per spec
            if nxt then
                for j, s in ipairs(SimpleSetDB.sets) do
                    if j ~= idx and s.spec == nxt then
                        s.spec = nil
                    end
                end
            end
            set.spec = nxt
            refreshSettingsUI()
        end)
        specBtns[i]:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Talent Spec Binding")
            GameTooltip:AddLine("Click to cycle: None / Spec 1 / Spec 2", 1, 1, 1)
            GameTooltip:AddLine("Bound sets auto-equip on spec change", 1, 1, 1)
            GameTooltip:Show()
        end)
        specBtns[i]:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end

    local confirmBtn = CreateFrame("Button", nil, settingsFrame, "UIPanelButtonTemplate")
    confirmBtn:SetSize(60, 22)
    confirmBtn:SetPoint("BOTTOMRIGHT", -8, 6)
    confirmBtn:SetText("OK")
    confirmBtn:SetScript("OnClick", function()
        for i = 1, #SimpleSetDB.sets do
            if editBoxes[i] then
                SimpleSetDB.sets[i].name = editBoxes[i]:GetText()
            end
        end
        settingsFrame:Hide()
    end)

    local addBtn = CreateFrame("Button", nil, settingsFrame, "UIPanelButtonTemplate")
    addBtn:SetSize(60, 22)
    addBtn:SetPoint("BOTTOMLEFT", 8, 6)
    addBtn:SetText("+ Add")
    addBtn:SetScript("OnClick", function()
        if #SimpleSetDB.sets >= MAX_SETS then
            print("|cffff0000SimpleSet:|r Max " .. MAX_SETS .. " sets.")
            return
        end
        for i = 1, #SimpleSetDB.sets do
            SimpleSetDB.sets[i].name = editBoxes[i]:GetText()
        end
        local n = #SimpleSetDB.sets + 1
        table.insert(SimpleSetDB.sets, {name = "Set " .. n, items = {}})
        refreshSettingsUI()
    end)

    local removeBtn = CreateFrame("Button", nil, settingsFrame, "UIPanelButtonTemplate")
    removeBtn:SetSize(70, 22)
    removeBtn:SetPoint("BOTTOM", 0, 6)
    removeBtn:SetText("- Remove")
    removeBtn:SetScript("OnClick", function()
        if #SimpleSetDB.sets <= 1 then
            print("|cffff0000SimpleSet:|r Need at least 1 set.")
            return
        end
        for i = 1, #SimpleSetDB.sets do
            SimpleSetDB.sets[i].name = editBoxes[i]:GetText()
        end
        table.remove(SimpleSetDB.sets)
        refreshSettingsUI()
    end)

    settingsFrame:SetScript("OnShow", refreshSettingsUI)
end

----------------------------------------------------------------------
-- UI: Dropdowns on Character Panel
----------------------------------------------------------------------

local function createUI()
    local loadDD = CreateFrame("Frame", "SimpleSet_LoadDD", PaperDollFrame, "UIDropDownMenuTemplate")
    loadDD:SetPoint("TOPLEFT", PaperDollFrame, "TOPLEFT", -5, -50)
    UIDropDownMenu_SetWidth(loadDD, 65)
    UIDropDownMenu_SetText(loadDD, "Load")

    UIDropDownMenu_Initialize(loadDD, function()
        for i, set in ipairs(SimpleSetDB.sets) do
            local info = UIDropDownMenu_CreateInfo()
            local label = set.name
            if set.spec then
                label = label .. " |cff888888(S" .. set.spec .. ")|r"
            end
            info.text = label
            info.icon = set.icon or DEFAULT_ICON
            info.tooltipTitle = set.name
            info.tooltipText = buildTooltip(i)
            info.tooltipOnButton = true
            info.notCheckable = true
            info.func = function()
                loadSet(i)
                UIDropDownMenu_SetText(loadDD, "Load")
                CloseDropDownMenus()
            end
            UIDropDownMenu_AddButton(info)
        end
    end)

    local saveDD = CreateFrame("Frame", "SimpleSet_SaveDD", PaperDollFrame, "UIDropDownMenuTemplate")
    saveDD:SetPoint("LEFT", loadDD, "RIGHT", -30, 0)
    UIDropDownMenu_SetWidth(saveDD, 65)
    UIDropDownMenu_SetText(saveDD, "Save")

    UIDropDownMenu_Initialize(saveDD, function()
        for i, set in ipairs(SimpleSetDB.sets) do
            local info = UIDropDownMenu_CreateInfo()
            local label = set.name
            if set.spec then
                label = label .. " |cff888888(S" .. set.spec .. ")|r"
            end
            info.text = label
            info.icon = set.icon or DEFAULT_ICON
            info.tooltipTitle = set.name
            info.tooltipText = buildTooltip(i)
            info.tooltipOnButton = true
            info.notCheckable = true
            info.func = function()
                StaticPopup_Show("SIMPLESET_CONFIRM_SAVE", set.name, nil, i)
                UIDropDownMenu_SetText(saveDD, "Save")
                CloseDropDownMenus()
            end
            UIDropDownMenu_AddButton(info)
        end
    end)

    local gearBtn = CreateFrame("Button", nil, PaperDollFrame)
    gearBtn:SetSize(18, 18)
    gearBtn:SetPoint("LEFT", saveDD, "RIGHT", -14, 2)
    gearBtn:SetNormalTexture("Interface\\Icons\\trade_engineering")
    gearBtn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    gearBtn:SetScript("OnClick", function() settingsFrame:Show() end)
    gearBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("SimpleSet Settings")
        GameTooltip:Show()
    end)
    gearBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

----------------------------------------------------------------------
-- UI: Minimap Button
----------------------------------------------------------------------

local function createMinimapButton()
    local btn = CreateFrame("Button", "SimpleSet_MinimapBtn", Minimap)
    btn:SetSize(31, 31)
    btn:SetFrameStrata("MEDIUM")
    btn:SetFrameLevel(8)
    btn:SetMovable(true)
    btn:RegisterForDrag("LeftButton")
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    minimapIcon = btn:CreateTexture(nil, "BACKGROUND")
    minimapIcon:SetSize(20, 20)
    minimapIcon:SetPoint("CENTER")
    minimapIcon:SetTexture("Interface\\Icons\\INV_Helmet_04")

    local border = btn:CreateTexture(nil, "OVERLAY")
    border:SetSize(53, 53)
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetPoint("TOPLEFT")

    btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    -- Square-compatible positioning (works with both round and square minimaps)
    local function updatePosition(angle)
        local rad = math.rad(angle or 220)
        local cos, sin = math.cos(rad), math.sin(rad)
        local q = math.max(math.abs(cos), math.abs(sin))
        local halfW = (Minimap:GetWidth() or 140) / 2 + 6
        local halfH = (Minimap:GetHeight() or 140) / 2 + 6
        btn:ClearAllPoints()
        btn:SetPoint("CENTER", Minimap, "CENTER", cos / q * halfW, sin / q * halfH)
    end

    updatePosition(SimpleSetDB.minimapAngle)

    local isDragging = false
    btn:SetScript("OnDragStart", function()
        isDragging = true
    end)
    btn:SetScript("OnDragStop", function()
        isDragging = false
    end)
    btn:SetScript("OnUpdate", function()
        if not isDragging then return end
        local mx, my = Minimap:GetCenter()
        local cx, cy = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        cx, cy = cx / scale, cy / scale
        local angle = math.deg(math.atan2(cy - my, cx - mx))
        SimpleSetDB.minimapAngle = angle
        updatePosition(angle)
    end)

    -- Minimap dropdown (MENU style, no tooltips)
    local minimapDD = CreateFrame("Frame", "SimpleSet_MinimapDD", UIParent, "UIDropDownMenuTemplate")
    UIDropDownMenu_Initialize(minimapDD, function()
        for i, set in ipairs(SimpleSetDB.sets) do
            local info = UIDropDownMenu_CreateInfo()
            local label = set.name
            if set.spec then
                label = label .. " |cff888888(S" .. set.spec .. ")|r"
            end
            info.text = label
            info.icon = set.icon or DEFAULT_ICON
            info.notCheckable = true
            info.func = function()
                loadSet(i)
                CloseDropDownMenus()
            end
            UIDropDownMenu_AddButton(info)
        end
    end, "MENU")

    btn:SetScript("OnClick", function(self, button)
        if button == "RightButton" then
            settingsFrame:Show()
        else
            ToggleDropDownMenu(1, nil, minimapDD, self, 0, 0)
        end
    end)

    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("SimpleSet")
        GameTooltip:AddLine("Left-click: Load a set", 1, 1, 1)
        GameTooltip:AddLine("Right-click: Settings", 1, 1, 1)
        GameTooltip:AddLine("Drag: Move button", 1, 1, 1)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

----------------------------------------------------------------------
-- Baganator integration (corner widget)
----------------------------------------------------------------------

local function registerBaganatorWidget()
    if not Baganator or not Baganator.API or not Baganator.API.RegisterCornerWidget then
        return
    end

    Baganator.API.RegisterCornerWidget(
        "SimpleSet",
        "simpleset_lock",
        function(tex, details)
            if not details or not details.itemLink then return false end
            local name = GetItemInfo(details.itemLink)
            if not name then return nil end
            return getSetItemNames()[name] == true
        end,
        function(itemButton)
            local tex = itemButton:CreateTexture(nil, "OVERLAY")
            tex:SetSize(25, 25)
            tex:SetTexture("Interface\\Buttons\\LockButton-Locked-Up")
            tex.padding = -2
            return tex
        end,
        {corner = "top_left", priority = 1},
        true
    )
end

----------------------------------------------------------------------
-- Init
----------------------------------------------------------------------

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        initDB()
        createIconPicker()
        createSettingsFrame()
        createUI()
        createMinimapButton()
        hooksecurefunc("ContainerFrame_Update", updateContainerLocks)
        registerBaganatorWidget()
        self:UnregisterEvent("ADDON_LOADED")
        self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
        pcall(self.RegisterEvent, self, "ACTIVE_TALENT_GROUP_CHANGED")
        updateMinimapIcon()

    elseif event == "PLAYER_EQUIPMENT_CHANGED" then
        updateMinimapIcon()

    elseif event == "ACTIVE_TALENT_GROUP_CHANGED" then
        local activeSpec = GetActiveTalentGroup and GetActiveTalentGroup()
        if activeSpec then
            for i, set in ipairs(SimpleSetDB.sets) do
                if set.spec == activeSpec and set.items and #set.items > 0 then
                    loadSet(i)
                    break
                end
            end
        end
    end
end)
