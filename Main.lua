----------------------------------------------------------------------
-- SimpleSet v1.1
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
-- Database
----------------------------------------------------------------------

local function initDB()
    if not SimpleSetDB.sets or #SimpleSetDB.sets == 0 then
        SimpleSetDB.sets = {
            {name = "Set 1", items = {}},
            {name = "Set 2", items = {}},
        }
    end
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
    print("|cff00ff00SimpleSet:|r \"" .. set.name .. "\" saved.")
end

local function loadSet(index)
    local set = SimpleSetDB.sets[index]
    if not set then return end
    if not set.items or #set.items == 0 then
        print("|cffff0000SimpleSet:|r \"" .. set.name .. "\" is empty.")
        return
    end

    -- Track names already queued to detect duplicates (rings/trinkets)
    local seen = {}
    local delay = 0

    for i = 1, #SLOTS do
        local itemName = set.items[i]
        if itemName and itemName ~= false then
            -- Skip if this exact item is already in the correct slot
            local currentLink = GetInventoryItemLink("player", slotIDs[i])
            local currentName = currentLink and GetItemInfo(currentLink)

            if currentName ~= itemName then
                -- Duplicate name (e.g. two identical rings): delay so the
                -- first equip finishes before the second one fires
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
-- UI: Settings Frame
----------------------------------------------------------------------

local settingsFrame
local editBoxes = {}
local settingsLabels = {}

local function refreshSettingsUI()
    local count = #SimpleSetDB.sets
    for i = 1, MAX_SETS do
        if i <= count then
            settingsLabels[i]:Show()
            editBoxes[i]:SetText(SimpleSetDB.sets[i].name)
            editBoxes[i]:Show()
        else
            settingsLabels[i]:Hide()
            editBoxes[i]:Hide()
        end
    end
    settingsFrame:SetHeight(65 + count * 30)
end

local function createSettingsFrame()
    settingsFrame = CreateFrame("Frame", "SimpleSet_Settings", UIParent, "BasicFrameTemplateWithInset")
    settingsFrame:SetFrameStrata("DIALOG")
    settingsFrame:SetSize(250, 130)
    settingsFrame:SetPoint("CENTER", 0, 50)
    settingsFrame:Hide()
    settingsFrame:SetMovable(true)
    settingsFrame:EnableMouse(true)
    settingsFrame:RegisterForDrag("LeftButton")
    settingsFrame:SetScript("OnDragStart", settingsFrame.StartMoving)
    settingsFrame:SetScript("OnDragStop", settingsFrame.StopMovingOrSizing)

    settingsFrame.title = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    settingsFrame.title:SetPoint("CENTER", settingsFrame.TitleBg, "CENTER", 5, 0)
    settingsFrame.title:SetText("SimpleSet")

    for i = 1, MAX_SETS do
        settingsLabels[i] = settingsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        settingsLabels[i]:SetPoint("TOPLEFT", 15, -28 - (i - 1) * 30)
        settingsLabels[i]:SetText(i .. ".")
        settingsLabels[i]:Hide()

        editBoxes[i] = CreateFrame("EditBox", "SimpleSet_EB" .. i, settingsFrame, "InputBoxTemplate")
        editBoxes[i]:SetSize(170, 20)
        editBoxes[i]:SetPoint("LEFT", settingsLabels[i], "RIGHT", 6, 0)
        editBoxes[i]:SetAutoFocus(false)
        editBoxes[i]:SetScript("OnEscapePressed", function(s) s:ClearFocus() end)
        editBoxes[i]:SetScript("OnEnterPressed", function(s) s:ClearFocus() end)
        editBoxes[i]:Hide()
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
            info.text = set.name
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
            info.text = set.name
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
-- Baganator integration (corner widget)
----------------------------------------------------------------------

local function registerBaganatorWidget()
    if not Baganator or not Baganator.API or not Baganator.API.RegisterCornerWidget then
        return
    end

    Baganator.API.RegisterCornerWidget(
        "SimpleSet",            -- label shown in Baganator settings
        "simpleset_lock",       -- unique ID
        function(tex, details)  -- onUpdate: called per item each refresh
            if not details or not details.itemLink then return false end
            local name = GetItemInfo(details.itemLink)
            if not name then return nil end -- data not ready, re-queue
            return getSetItemNames()[name] == true
        end,
        function(itemButton)    -- onInit: create the overlay texture once
            local tex = itemButton:CreateTexture(nil, "OVERLAY")
            tex:SetSize(25, 25)
            tex:SetTexture("Interface\\Buttons\\LockButton-Locked-Up")
            tex.padding = -2
            return tex
        end,
        {corner = "top_left", priority = 1}, -- default position
        true                                  -- isFast
    )
end

----------------------------------------------------------------------
-- Init
----------------------------------------------------------------------

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, event, addon)
    if addon == ADDON_NAME then
        initDB()
        createSettingsFrame()
        createUI()
        -- Default bags fallback (for when Baganator is not used)
        hooksecurefunc("ContainerFrame_Update", updateContainerLocks)
        -- Baganator corner widget
        registerBaganatorWidget()
        self:UnregisterEvent("ADDON_LOADED")
    end
end)
