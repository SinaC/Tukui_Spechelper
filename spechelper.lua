-----------------------------------------------
-- Spec Helper, by EPIC
-----------------------------------------------
local T, C, L = unpack(Tukui) -- Import: T - functions, constants, variables; C - config; L - locales

local cp = "|cff319f1b" -- +
local cm = "|cff9a1212" -- -
local dr, dg, db = unpack({ 0.4, 0.4, 0.4 })
panelcolor = ("|cff%.2x%.2x%.2x"):format(dr * 255, dg * 255, db * 255)

--functions
local function enableDPS()
	DisableAddOn("Tukui_Raid_Healing")
	EnableAddOn("Tukui_Raid")
	EnableAddOn("Tukui_Filger")
	ReloadUI()
end
local function enableHeal()
	DisableAddOn("Tukui_Raid")
	DisableAddOn("Tukui_Filger")
	EnableAddOn("Tukui_Raid_Healing")
	ReloadUI()
end
local function HasDualSpec() if GetNumTalentGroups() > 1 then return true end end

-- Spec
local spec = CreateFrame("Button", "Spec", UIParent)
spec:CreatePanel("Default", 125, 20, "TOPRIGHT", UIParent, "TOPRIGHT", -32, -212)

	if TukuiMinimap then
		spec:SetPoint("TOPLEFT", TukuiMinimap, "BOTTOMLEFT", 0, -3)	
	end
		
	if TukuiMinimapStatsLeft then
		spec:SetPoint("TOPLEFT", TukuiMinimapStatsLeft, "BOTTOMLEFT", 0, -3)
	end
	
	if RaidBuffReminder then
		spec:SetPoint("TOPLEFT", RaidBuffReminder, "BOTTOMLEFT", 0, -3)
	end	

	spec.t = spec:CreateFontString(spec, "OVERLAY")
	spec.t:SetPoint("CENTER")
	spec.t:SetFont(C["media"].uffont, C.datatext.fontsize)
	
	local function OnEvent(self)
		if not GetPrimaryTalentTree() then Text:SetText("No talents") return end
		
		local tree1 = select(5,GetTalentTabInfo(1))
		local tree2 = select(5,GetTalentTabInfo(2))
		local tree3 = select(5,GetTalentTabInfo(3))
		local Tree = GetPrimaryTalentTree(false,false,GetActiveTalentGroup())
		local Treename = select(2,GetTalentTabInfo(Tree))
		spec.t:SetText(Treename.." "..panelcolor..tree1.."/"..tree2.."/"..tree3)
	end
	
	spec:RegisterEvent("PLAYER_TALENT_UPDATE")
	spec:RegisterEvent("PLAYER_ENTERING_WORLD")
	spec:SetScript("OnEvent", OnEvent) 
		
	spec:SetScript("OnEnter", function() 
		if InCombatLockdown() then return end
			if HasDualSpec() then
				-- local secondary = GetActiveTalentGroup() --== 1 and 2 or 1
				-- local secondaryone = select(5,GetTalentTabInfo(1,false,false, secondary))
				-- local secondarytwo = select(5,GetTalentTabInfo(2,false,false, secondary))
				-- local secondarythree = select(5,GetTalentTabInfo(3,false,false, secondary))
				spec.t:SetText(cm.."Switch Specs")
			end
	end)
	
	spec:SetScript("OnLeave", function() 
		if InCombatLockdown() then return end	
			local primary = GetPrimaryTalentTree(false,false,GetActiveTalentGroup())
			local primaryone = select(5,GetTalentTabInfo(1))
			local primarytwo = select(5,GetTalentTabInfo(2))
			local primarythree = select(5,GetTalentTabInfo(3))				
		spec.t:SetText(select(2,GetTalentTabInfo(primary)).." "..panelcolor..primaryone.."/"..primarytwo.."/"..primarythree)
	end)

	spec:SetScript("OnClick", function(self) 
	local i = GetActiveTalentGroup()
		if i == 1 then SetActiveTalentGroup(2) end
		if i == 2 then SetActiveTalentGroup(1) end
	end)

-- Toggle Button
local toggle = CreateFrame("Button", "Toggle", Spec)
toggle:CreatePanel("Default", 20, 20, "TOPLEFT", Spec, "TOPRIGHT", 3, 0)

	if C.general.ali == true then
	toggle:SetBackdropColor(unpack(C.general.color))
	end

		toggle.t = toggle:CreateFontString(nil, "OVERLAY")
		toggle.t:SetPoint("CENTER")
		toggle.t:SetFont(C["media"].uffont, C.datatext.fontsize)
		toggle.t:SetText(cp.."+|r")
		toggle:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(unpack(C.datatext.color)) end)
		toggle:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(unpack(C.media.bordercolor)) end)
		
		toggle:SetScript("OnClick", function(self) 
			if DPS:IsShown() then	
				DPS:Hide()
				toggle.t:SetText(cp.."+|r")
			else
				DPS:Show()
				toggle.t:SetText(cm.."-|r")
			end
		end)
		
-- DPS layout
local dps = CreateFrame("Button", "DPS", Toggle)
dps:CreatePanel("Default", 28, 19, "TOPRIGHT", Toggle, "BOTTOMRIGHT", 0, -3)
		dps:Hide()		
		dps.t = dps:CreateFontString(nil, "OVERLAY")
		dps.t:SetPoint("CENTER")
		dps.t:SetFont(C["media"].uffont, C.datatext.fontsize)
		dps.t:SetText("DPS")
		
		dps:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(unpack(C.datatext.color)) end)
		dps:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(unpack(C.media.bordercolor)) end)
		dps:SetScript("OnClick", function(self) 
			enableDPS()
		end)
-- Heal layout
local heal = CreateFrame("Button", "HEAL", DPS)
heal:CreatePanel("Default", 29, 19, "RIGHT", DPS, "LEFT", -3, 0)
		
		heal.t = heal:CreateFontString(nil, "OVERLAY")
		heal.t:SetPoint("CENTER")
		heal.t:SetFont(C["media"].uffont, C.datatext.fontsize)
		heal.t:SetText("HEAL")
		
		heal:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(unpack(C.datatext.color)) end)
		heal:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(unpack(C.media.bordercolor)) end)
		
		heal:SetScript("OnClick", function(self) 
			enableHeal()
		end)
		
-- Gear switching
local gearSets = CreateFrame("Frame", "gearSets", HEAL)	
for i = 1, 10 do
		gearSets[i] = CreateFrame("Button", "gearSets"..i, HEAL)
		gearSets[i]:CreatePanel("Default", 19, 19, "CENTER", HEAL, "CENTER", 0, 0)

		if i == 1 then
			gearSets[i]:Point("BOTTOMRIGHT", HEAL, "BOTTOMLEFT", -3, 0)
		else
			gearSets[i]:SetPoint("BOTTOMRIGHT", gearSets[i-1], "BOTTOMLEFT", -3, 0)
		end
		gearSets[i].texture = gearSets[i]:CreateTexture(nil, "BORDER")
		gearSets[i].texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		gearSets[i].texture:SetPoint("TOPLEFT", gearSets[i] ,"TOPLEFT", 2, -2)
		gearSets[i].texture:SetPoint("BOTTOMRIGHT", gearSets[i] ,"BOTTOMRIGHT", -2, 2)
		gearSets[i].texture:SetTexture(select(2, GetEquipmentSetInfo(i)))
		gearSets[i]:Hide()
	
	gearSets[i]:RegisterEvent("PLAYER_ENTERING_WORLD")
	gearSets[i]:RegisterEvent("EQUIPMENT_SETS_CHANGED")
	gearSets[i]:SetScript("OnEvent", function(self, event)
	local points, pt = 0, GetNumEquipmentSets()
	local frames = { gearSets[1]:IsShown(), gearSets[2]:IsShown(), gearSets[3]:IsShown(), gearSets[4]:IsShown(), 
					 gearSets[5]:IsShown(), gearSets[6]:IsShown(), gearSets[7]:IsShown(), gearSets[8]:IsShown(), --I can't believe this works
					 gearSets[9]:IsShown(), gearSets[10]:IsShown() }
		if pt > points then
			for i = points + 1, pt do
				gearSets[i]:Show()
			end
		end
		if frames[pt+1] == 1 then
			gearSets[pt+1]:Hide()
		end
		
		gearSets[i].texture = gearSets[i]:CreateTexture(nil, "BORDER")
		gearSets[i].texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		gearSets[i].texture:SetPoint("TOPLEFT", gearSets[i] ,"TOPLEFT", 2, -2)
		gearSets[i].texture:SetPoint("BOTTOMRIGHT", gearSets[i] ,"BOTTOMRIGHT", -2, 2)
		gearSets[i].texture:SetTexture(select(2, GetEquipmentSetInfo(i)))

		gearSets[i]:SetScript("OnClick", function(self) UseEquipmentSet(GetEquipmentSetInfo(i)) end)
		gearSets[i]:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(unpack(C.datatext.color)) end)
		gearSets[i]:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(unpack(C.media.bordercolor)) end)
	end)
end	


		
		
		
		
		
		
		
		
		
		
		
		
