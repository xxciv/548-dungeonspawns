-- ZRProfessions: lets the 5.4.8 trainer UI teach more than 2 primary professions,
-- and lists every primary profession you know (/profs), since the Professions tab only has 2 slots.
--
-- The server stays the real limit (worldserver.conf MaxPrimaryTradeSkill). This addon only removes the
-- client's own "you already know 2" check in Blizzard_TrainerUI.

-- Keep this equal to MaxPrimaryTradeSkill in worldserver.conf.
local MAX_PRIMARY_PROFESSIONS = 4

-- Rank spell IDs per primary profession, Apprentice -> Zen Master (same table the core uses in
-- ServiceMgr.cpp). Knowing any of them means the profession is learned; the highest known one is the rank.
-- open: spell that opens the profession window (nil = gathering, nothing to open).
local PROFESSIONS = {
    { skillLine = 171, ranks = { 2259, 3101, 3464, 11611, 28596, 51304, 80731, 105206 } },  -- Alchemy
    { skillLine = 164, ranks = { 2018, 3100, 3538, 9785, 29844, 51300, 76666, 110396 } },   -- Blacksmithing
    { skillLine = 333, ranks = { 7411, 7412, 7413, 13920, 28029, 51313, 74258, 110400 } },  -- Enchanting
    { skillLine = 202, ranks = { 4036, 4037, 4038, 12656, 30350, 51306, 82774, 110403 } },  -- Engineering
    { skillLine = 773, ranks = { 45357, 45358, 45359, 45360, 45361, 45363, 86008, 110417 } }, -- Inscription
    { skillLine = 755, ranks = { 25229, 25230, 28894, 28895, 28897, 51311, 73318, 110420 } }, -- Jewelcrafting
    { skillLine = 165, ranks = { 2108, 3104, 3811, 10662, 32549, 51302, 81199, 110423 } },  -- Leatherworking
    { skillLine = 197, ranks = { 3908, 3909, 3910, 12180, 26790, 51309, 75156, 110426 } },  -- Tailoring
    { skillLine = 182, ranks = { 2366, 2368, 3570, 11993, 28695, 50300, 74519, 110413 }, gathering = true },  -- Herbalism
    { skillLine = 186, ranks = { 2575, 2576, 3564, 10248, 29354, 50310, 74517, 102161 }, open = 2656 },       -- Mining (opens Smelting)
    { skillLine = 393, ranks = { 8613, 8617, 8618, 10768, 32678, 50305, 74522, 102216 }, gathering = true },  -- Skinning
}

local RANK_NAMES = { "Apprentice", "Journeyman", "Expert", "Artisan", "Master", "Grand Master", "Illustrious", "Zen Master" }

local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99ZRProfessions:|r " .. msg)
end

-- Highest known rank (1-8) of a profession, or nil if not learned.
local function KnownRank(prof)
    for i = #prof.ranks, 1, -1 do
        if IsPlayerSpell(prof.ranks[i]) then
            return i
        end
    end
end

local function CountKnownPrimaries()
    local count = 0
    for _, prof in ipairs(PROFESSIONS) do
        if KnownRank(prof) then
            count = count + 1
        end
    end
    return count
end

-- Current/max skill for a skill line, if the client will tell us. GetProfessionInfo is meant for the
-- indexes GetProfessions() returns; we try the others too and only trust a result whose skill line matches.
local function SkillValues(skillLine)
    for index = 1, 256 do
        local ok, name, _, rank, maxRank, _, _, line = pcall(GetProfessionInfo, index)
        if not ok then
            return
        end
        if name and line == skillLine then
            return rank, maxRank
        end
    end
end

---------------------------------------------------------------------------------------------------
-- Trainer: re-enable "Train" for a new primary profession while under the limit
---------------------------------------------------------------------------------------------------

-- Runs after Blizzard's ClassTrainerFrame_SetServiceButton, which disables Train for any new profession
-- once GetProfessions() reports a second one.
local function AfterSetServiceButton(skillButton, skillIndex, playerMoney, selected, isTradeSkill)
    if not (ClassTrainerFrame.selectedService and selected == skillIndex) then
        return
    end
    local _, _, serviceType = GetTrainerServiceInfo(skillIndex)
    local moneyCost, isProfession = GetTrainerServiceCost(skillIndex)
    if serviceType ~= "available" or not isProfession then
        return
    end
    if moneyCost and moneyCost > (playerMoney or GetMoney()) then
        return
    end
    if CountKnownPrimaries() < MAX_PRIMARY_PROFESSIONS then
        ClassTrainerTrainButton:Enable()
    end
end

-- Blizzard's confirmation popup only has text for 0 or 1 known professions.
local function PatchConfirmPopup()
    local dialog = StaticPopupDialogs["CONFIRM_PROFESSION"]
    if not dialog then
        return
    end
    local originalOnShow = dialog.OnShow
    dialog.OnShow = function(self, ...)
        if originalOnShow then
            originalOnShow(self, ...)
        end
        local _, prof2 = GetProfessions()
        if prof2 then
            local skill = GetTrainerServiceSkillLine(ClassTrainerFrame.selectedService) or "this profession"
            self.text:SetFormattedText("Learn %s? You will know %d of %d primary professions.",
                skill, CountKnownPrimaries() + 1, MAX_PRIMARY_PROFESSIONS)
        end
    end
end

local trainerHooked = false
local function HookTrainerUI()
    if trainerHooked then
        return
    end
    trainerHooked = true
    hooksecurefunc("ClassTrainerFrame_SetServiceButton", AfterSetServiceButton)
    PatchConfirmPopup()
end

---------------------------------------------------------------------------------------------------
-- /profs panel: every primary profession, click to open it
---------------------------------------------------------------------------------------------------

local ROW_HEIGHT = 40
local panel, rows = nil, {}
local refreshPending = false

local function CreateRow(index)
    -- Secure button: opening a profession window is a spell cast, which addons may only do this way.
    local row = CreateFrame("Button", "ZRProfessionsRow" .. index, panel, "SecureActionButtonTemplate")
    row:SetSize(260, ROW_HEIGHT - 4)
    row:SetPoint("TOPLEFT", panel, "TOPLEFT", 14, -34 - (index - 1) * ROW_HEIGHT)
    row:RegisterForClicks("LeftButtonUp")
    row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")

    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(32, 32)
    row.icon:SetPoint("LEFT", 2, 0)

    row.name = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    row.name:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 8, -2)

    row.sub = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    row.sub:SetPoint("BOTTOMLEFT", row.icon, "BOTTOMRIGHT", 8, 2)

    rows[index] = row
    return row
end

local function RefreshPanel()
    if InCombatLockdown() then
        refreshPending = true
        return
    end
    refreshPending = false

    local shown = 0
    for _, prof in ipairs(PROFESSIONS) do
        local rank = KnownRank(prof)
        if rank then
            shown = shown + 1
            local row = rows[shown] or CreateRow(shown)
            local name, _, icon = GetSpellInfo(prof.ranks[rank])
            row.icon:SetTexture(icon)
            row.name:SetText(name)

            local current, max = SkillValues(prof.skillLine)
            local sub = RANK_NAMES[rank]
            if current and max then
                sub = sub .. "  " .. current .. "/" .. max
            end
            if prof.gathering then
                sub = sub .. "  (gathering)"
            end
            row.sub:SetText(sub)

            if prof.gathering then
                row:SetAttribute("type", nil)
                row:SetAttribute("spell", nil)
            else
                row:SetAttribute("type", "spell")
                row:SetAttribute("spell", (GetSpellInfo(prof.open or prof.ranks[rank])))
            end
            row:Show()
        end
    end
    for i = shown + 1, #rows do
        rows[i]:Hide()
    end

    if shown == 0 then
        panel.empty:Show()
    else
        panel.empty:Hide()
    end
    panel.count:SetFormattedText("%d / %d primary professions", shown, MAX_PRIMARY_PROFESSIONS)
    panel:SetHeight(64 + math.max(shown, 1) * ROW_HEIGHT)
end

local function CreatePanel()
    panel = CreateFrame("Frame", "ZRProfessionsFrame", UIParent)
    panel:SetSize(290, 100)
    panel:SetPoint("CENTER")
    panel:SetFrameStrata("DIALOG")
    panel:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    panel:EnableMouse(true)
    panel:SetMovable(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", panel.StartMoving)
    panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
    panel:Hide()

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -14)
    title:SetText("Primary Professions")

    local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)

    panel.empty = panel:CreateFontString(nil, "ARTWORK", "GameFontDisable")
    panel.empty:SetPoint("TOP", 0, -46)
    panel.empty:SetText("No primary professions learned.")

    panel.count = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    panel.count:SetPoint("BOTTOM", 0, 14)

    panel:SetScript("OnShow", RefreshPanel)
end

local function TogglePanel()
    if InCombatLockdown() then
        Print("not available in combat.")
        return
    end
    if panel:IsShown() then
        panel:Hide()
    else
        panel:Show()
    end
end

-- "All professions" button on the spellbook's Professions tab, next to the bottom tabs.
local function AddSpellbookButton()
    if not SpellBookProfessionFrame then
        return
    end
    local button = CreateFrame("Button", "ZRProfessionsSpellbookButton", SpellBookProfessionFrame, "UIPanelButtonTemplate")
    button:SetSize(130, 22)
    button:SetPoint("TOPRIGHT", SpellBookFrame, "BOTTOMRIGHT", -8, 2)
    button:SetText("All professions")
    button:SetScript("OnClick", TogglePanel)
end

SLASH_ZRPROFESSIONS1 = "/profs"
SLASH_ZRPROFESSIONS2 = "/zrprofs"
SlashCmdList["ZRPROFESSIONS"] = TogglePanel

---------------------------------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------------------------------

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("SKILL_LINES_CHANGED")
events:RegisterEvent("LEARNED_SPELL_IN_TAB")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == "ZRProfessions" then
            CreatePanel()
            AddSpellbookButton()
            -- The trainer UI is load-on-demand; it may already be loaded if another addon pulled it in.
            if IsAddOnLoaded("Blizzard_TrainerUI") then
                HookTrainerUI()
            end
        elseif arg1 == "Blizzard_TrainerUI" then
            HookTrainerUI()
        end
    elseif event == "PLAYER_REGEN_DISABLED" then
        -- Hide before combat lockdown starts; the panel holds secure buttons and can't be hidden during it.
        if panel and panel:IsShown() then
            panel:Hide()
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        if refreshPending and panel and panel:IsShown() then
            RefreshPanel()
        end
    elseif panel and panel:IsShown() then
        RefreshPanel()
    end
end)
