local Addon = CreateFrame("FRAME", "Shadowman");


--Player stats
local spellPower;
local numApparitions = 0;
--"1" means no points
local modifiersTable = {
	["TwistedFate"] = 1,
	["TwinDisciplines"] = 1,
	["Shadowform"] = 1,
	["T114PBonus"] = 1
}


--This should trigger everytime the player changes spec
local function getStatsPlayer()
	--get player talents modifiers
	modifiersTable.TwistedFate = select(5,GetTalentInfo(3, 7))*0.01 + 1.00;
	modifiersTable.TwinDisciplines = select(5,GetTalentInfo(1, 2))*0.02 + 1.00;

	--checks if player has t11bonus
	local numT11 = 0;

	if	(IsEquippedItem(60256) or IsEquippedItem(65235)) then
		numT11 = numT11 + 1;
	end
	if	(IsEquippedItem(60253) or IsEquippedItem(65238)) then
		numT11 = numT11 + 1;
	end
	if	(IsEquippedItem(60254) or IsEquippedItem(65237)) then
		numT11 = numT11 + 1;
	end
	if	(IsEquippedItem(60255) or IsEquippedItem(65236)) then
		numT11 = numT11 + 1;
	end
	if	(IsEquippedItem(60257) or IsEquippedItem(65234)) then
		numT11 = numT11 + 1;
	end

	if(numT11 > 3) then
		modifiersTable.T114PBonus = 1.3;
	else
		modifiersTable.T114PBonus = 1;
	end
end


--This triggers when the player gains SP (trinkes/procs)
local function getSpellPower()
	spellPower = GetSpellBonusDamage(6);
end

local function getApparitionDamage()
	--(516.19+SP* 0.515)* 1.15 = (SHADOWPOWER) * 1.15 = (SHADOWFORM) * 1.3 = (T11P4) * 1.06 = (TWINDISCIPLINES) * 1.02 = (TWISTEDFATE)
	local dmg = 516.19 + spellPower*0.515;
	return dmg * 1.15 * modifiersTable.Shadowform * modifiersTable.T114PBonus * modifiersTable.TwistedFate * modifiersTable.TwinDisciplines;
end

--sets/updates frame with number of apparitions
local function updateFrameIcon()

end


Addon:SetScript("OnEvent", function(self, event, ...)
	if(event == "UNIT_AURA" and ... == "player") then
		if(UnitBuff("player", "Shadowform")) then
			modifiersTable.Shadowform = 1.15;
			print("Into the void!");
		else
			modifiersTable.Shadowform = 1;
		end
		getSpellPower();
		print("Your Spell Power is: ", getSpellPower());
	elseif(event == "COMBAT_LOG_EVENT_UNFILTERED") then
		local time, type, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName, _, auraType, numStack = ...;
		if(type == "SPELL_SUMMON" and sourceName == UnitName("player") and destName == "Shadowy Apparition") then
			numApparitions = numApparitions + 1;
			updateFrameIcon();
		end
	elseif(event == "ACTIVE_TALENT_GROUP_CHANGED") then
		getStatsPlayer();
	elseif(event == "UNIT_INVENTORY_CHANGED") then
		getStatsPlayer();
	end
end)

Addon:RegisterEvent("UNIT_AURA");
Addon:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED");
Addon:RegisterEvent("UNIT_INVENTORY_CHANGED");
Addon:RegisterEvent("VARIABLES_LOADED");
