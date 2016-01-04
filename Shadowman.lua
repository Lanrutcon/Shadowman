local Addon = CreateFrame("FRAME", "Shadowman");

local frameAnchor;

local frameBar;

local numApparitions = 0;                           -- Number of Shadowy Apparitions available
local apparitionsTable = {};

local modifiersTable = {                            -- Stuff that modifies damage of Apparitions
    ["TwistedFate"] = 1,
    ["TwinDisciplines"] = 1,
    ["Shadowform"] = 1,
    ["T114PBonus"] = 1
}

-------------------------------------
--
-- Returns the damage when a Shadowy Apparitions strikes.
-- @return #double : damage
--
-------------------------------------
local function getApparitionDamage()
    --(516.19+SP* 0.515)* 1.15 = (SHADOWPOWER) * 1.15 = (SHADOWFORM) * 1.3 = (T11P4) * 1.06 = (TWINDISCIPLINES) * 1.02 = (TWISTEDFATE)
    local dmg = 516.19 + GetSpellBonusDamage(6) * 0.515;
    dmg = dmg * 1.15
        * modifiersTable.Shadowform
        * modifiersTable.T114PBonus
        * modifiersTable.TwistedFate
        * modifiersTable.TwinDisciplines;
    return math.floor(dmg/100 + 0.5) / 10;
end

-------------------------------------
--
-- Initialize the anchor frame (frameAnchor). Used when the addon loads up.
--
-------------------------------------
local function initFrameAnchor()
    frameAnchor = CreateFrame("FRAME", "SMAnchor", UIParent);
    frameAnchor:SetSize(200, 15);
    frameAnchor:SetPoint("CENTER", UIParent, "CENTER");

    frameAnchor:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16,
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 6,
        insets = { left = 2, right = 2, top = 2, bottom = 2, },
    });

    frameAnchor:EnableMouse(true);
    frameAnchor:SetMovable(true);

    frameAnchor:SetScript("OnMouseDown", function(self, button)
        if(button == "LeftButton") then
            self:StartMoving();
        end
    end)
    frameAnchor:SetScript("OnMouseUp", function(self, button)
        self:StopMovingOrSizing();
        local point,_,relativePoint,x,y = self:GetPoint();
        ShadowmanSV[UnitName("player")] = { point, relativePoint, x, y };
    end)

    frameAnchor:Hide();
end

-------------------------------------
--
-- Initializes the frame (frameBar).
--
-------------------------------------
local function initFrameBar()
    frameBar = CreateFrame("FRAME", nil, UIParent)
    frameBar:SetSize(200, 15);
    frameBar:SetPoint("TOPLEFT", frameAnchor);
    frameBar:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16,
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 6,
        insets = { left = 2, right = 2, top = 2, bottom = 2, },
    });

    frameBar.statusBar = CreateFrame("StatusBar", nil, frameBar)
    frameBar.statusBar:SetPoint("TOPLEFT", 3, -3)
    frameBar.statusBar:SetPoint("TOPRIGHT", -3, -3)
    frameBar.statusBar:SetHeight(9)
    frameBar.statusBar:SetWidth(193)
    frameBar.statusBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    frameBar.statusBar:GetStatusBarTexture():SetHorizTile(false)
    frameBar.statusBar:GetStatusBarTexture():SetVertTile(false)

    frameBar.statusBar:SetMinMaxValues(0, 4)
    frameBar.statusBar:SetStatusBarColor(0.57, 0, 0.9)
    frameBar.statusBar:SetValue(0);

    frameBar.statusBar.bg = frameBar.statusBar:CreateTexture(nil, "BACKGROUND")
    frameBar.statusBar.bg:SetTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
    frameBar.statusBar.bg:SetAllPoints(true)
    frameBar.statusBar.bg:SetVertexColor(0.28, 0, 0.45)

    frameBar.statusBar.damage = frameBar.statusBar:CreateFontString(nil, "OVERLAY")
    frameBar.statusBar.damage:SetPoint("LEFT", frameBar, "LEFT", 4, 0)
    frameBar.statusBar.damage:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    frameBar.statusBar.damage:SetJustifyH("LEFT")
    frameBar.statusBar.damage:SetShadowOffset(1, -1)
    frameBar.statusBar.damage:SetTextColor(0, 1, 0);

    frameBar:Hide();
end

-------------------------------------
--
-- Updates the icon frame. It's used when the player gets a new buff (maybe more Spell Power) or he/she spawns a apparition.
--
-------------------------------------
local function updateFrameIcon()
    if(numApparitions > 0) then
        frameBar.statusBar:SetValue(numApparitions);
        frameBar.statusBar.damage:SetText(getApparitionDamage() .. "k");
        frameBar:Show();
    else
        frameBar:SetScript("OnUpdate", nil);
        frameBar:Hide();
    end
end

-------------------------------------
--
-- Sets a timer for a certain GUID. It's used when a apparitions appears.
--
-------------------------------------
local function setLifeTimer(destGUID)
    apparitionsTable[destGUID] = CreateFrame("FRAME");
    apparitionsTable[destGUID].guid = destGUID;

    local totalElapsed = 0;
    apparitionsTable[destGUID]:SetScript("OnUpdate", function(self, elapsed)
        totalElapsed = totalElapsed + elapsed;
        if(totalElapsed > 20) then
            self:SetScript("OnUpdate", nil);
            apparitionsTable[self.guid] = nil;
            numApparitions = numApparitions - 1;
            self = nil;
            updateFrameIcon();
        end
    end);
end

-------------------------------------
--
-- Removes a timer for a certain GUID. It's used when a apparitions disappears.
--
-------------------------------------
local function removeLifeTimer(sourceGUID)
    apparitionsTable[sourceGUID]:SetScript("OnUpdate", nil);
    apparitionsTable[sourceGUID] = nil;
end

-------------------------------------
--
-- Updates the player stats, checks for talents and if the player has T11 equipped.
-- It's used when the player changes its talents or equipment.
--
-------------------------------------
local function updatePlayerStats()
    modifiersTable.TwistedFate = select(5,GetTalentInfo(3, 7))*0.01 + 1.00;
    modifiersTable.TwinDisciplines = select(5,GetTalentInfo(1, 2))*0.02 + 1.00;

    local numT11 = 0;
    if (IsEquippedItem(60256) or IsEquippedItem(65235)) then
        numT11 = numT11 + 1;
    end
    if (IsEquippedItem(60253) or IsEquippedItem(65238)) then
        numT11 = numT11 + 1;
    end
    if (IsEquippedItem(60254) or IsEquippedItem(65237)) then
        numT11 = numT11 + 1;
    end
    if (IsEquippedItem(60255) or IsEquippedItem(65236)) then
        numT11 = numT11 + 1;
    end
    if (IsEquippedItem(60257) or IsEquippedItem(65234)) then
        numT11 = numT11 + 1;
    end

    if(numT11 > 3) then
        modifiersTable.T114PBonus = 1.3;
    else
        modifiersTable.T114PBonus = 1;
    end
end

SLASH_Shadowman1, SLASH_Shadowman2 = "/shadowman", "/sm";

-------------------------------------
--
-- Slash command function. All commands that addon recognizes are here.
-- @param #string cmd: the command that player calls
--
-------------------------------------
function SlashCmd(cmd)
    if (cmd:match"unlock") then
        frameAnchor:Show();
    elseif (cmd:match"lock") then
        frameAnchor:Hide();
    end
end

SlashCmdList["Shadowman"] = SlashCmd;

-------------------------------------
--
-- "OnEvent" function.
-- Events that are treated can be found in the end of the file.
--
-------------------------------------
Addon:SetScript("OnEvent", function(self, event, ...)
    if(event == "COMBAT_LOG_EVENT_UNFILTERED") then
        local time, type, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName = ...;
        if(type == "SPELL_SUMMON" and sourceName == UnitName("player") and destName == "Shadowy Apparition") then
            setLifeTimer(destGUID);
            numApparitions = numApparitions + 1;
            updateFrameIcon();
        elseif(type == "SPELL_CAST_SUCCESS" and apparitionsTable[sourceGUID] and spellID == 87532) then
            removeLifeTimer(sourceGUID);
            numApparitions = numApparitions - 1;
            updateFrameIcon();
        end
    elseif(event == "UNIT_AURA" and ... == "player") then
        if(UnitBuff("player", "Shadowform")) then
            modifiersTable.Shadowform = 1.15;
        else
            modifiersTable.Shadowform = 1;
        end
        updateFrameIcon();
    elseif(event == "UNIT_INVENTORY_CHANGED" or event == "ACTIVE_TALENT_GROUP_CHANGED") then
        updatePlayerStats();
    elseif(event == "PLAYER_ENTERING_WORLD") then
        initFrameAnchor();
        if(type(ShadowmanSV) ~= "table") then
            ShadowmanSV = {};
            local point, relativePoint, x, y = frameAnchor:GetPoint();
            ShadowmanSV[UnitName("player")] = { point, relativePoint, x, y};
        elseif(ShadowmanSV[UnitName("player")]) then
            local point, relativePoint, x, y = ShadowmanSV[UnitName("player")][1], ShadowmanSV[UnitName("player")][2], ShadowmanSV[UnitName("player")][3], ShadowmanSV[UnitName("player")][4];
            frameAnchor:SetPoint(point, UIParent, relativePoint, x, y);
        else
            local point, relativePoint, x, y = frameAnchor:GetPoint();
            ShadowmanSV[UnitName("player")] = { point, relativePoint, x, y};
        end
        initFrameBar();
        updatePlayerStats();
    end
end)

Addon:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
Addon:RegisterEvent("UNIT_AURA");
Addon:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED");
Addon:RegisterEvent("UNIT_INVENTORY_CHANGED");
Addon:RegisterEvent("PLAYER_ENTERING_WORLD");