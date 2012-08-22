-----------------------------------------------
-- Spec Helper, by EPIC edited by SinaC
-----------------------------------------------
local T, C, L = unpack(Tukui) -- Import: T - functions, constants, variables; C - config; L - locales

-- colors
local hoverovercolor = {.4, .4, .4}
local cp = "|cff319f1b"
local cm = "|cff9a1212"
local dr, dg, db = unpack({ 0.4, 0.4, 0.4 })
local panelcolor = ("|cff%.2x%.2x%.2x"):format(dr * 255, dg * 255, db * 255)

-- settings
local EnableGear = true -- herp
local AutoGearSwap = false -- derp
local SpecSwitchCastbar = false -- show a castbar for spec switching
local set1 = 1 -- this is the gear set that gets equiped with your primary spec. (must be the NUMBER from 1-10)
local set2 = 2 -- this is the gear set that gets equiped with your secondary spec.(must be the NUMBER from 1-10)

-- constants
local ActivatePrimarySpecSpellID = 63645
local ActivateSecondarySpecSpellID = 63644
local ActivatePrimarySpecSpellName = GetSpellInfo(ActivatePrimarySpecSpellID)
local ActivateSecondarySpecSpellName = GetSpellInfo(ActivateSecondarySpecSpellID)
local MaxSets = 10

-- functions
local function HasDualSpec()
	if GetNumSpecGroups() > 1 then
		return true
	else
		return false
	end
end

local function GetSecondarySpecIndex()
	return 3 - (GetActiveSpecGroup() or 1) --  2->1  1->2
end

local function GetCurrentSpec()
	local index = GetSpecialization(false, false, GetActiveSpecGroup())
	local name = index and select(2, GetSpecializationInfo(index))
	return index, name
end	

local function GetSecondarySpec()
	local index = GetSpecialization(false, false, GetSecondarySpecIndex())
	local name = index and select(2, GetSpecializationInfo(index))
	return index, name
end

local function AutoGear(set1, set2)
	if GetActiveSpecGroup() == 1 then
		local name1 = GetEquipmentSetInfo(set1)
		if name1 then UseEquipmentSet(name1) end
	else
		local name2 = GetEquipmentSetInfo(set2)
		if name2 then UseEquipmentSet(name2) end
	end
end

local function SpecChangeCastbar(self)
	local specbar = CreateFrame("StatusBar", nil, UIParent)
	specbar:Point("TOPLEFT", self, "BOTTOMLEFT", 0, -3)
	specbar:Point("TOPRIGHT", self, "BOTTOMRIGHT", 23, -3)
	specbar:Height(19)
	local border = CreateFrame("Frame", specbar:GetName() and specbar:GetName() .. "InnerBorder" or nil, specbar)
	border:Point("TOPLEFT", -T.mult, T.mult)
	border:Point("BOTTOMRIGHT", T.mult, -T.mult)
	border:SetBackdrop({
		edgeFile = C["media"].blank,
		edgeSize = T.mult,
		insets = { left = T.mult, right = T.mult, top = T.mult, bottom = T.mult }
	})
	border:SetBackdropBorderColor(unpack(C["media"].backdropcolor))
	specbar.iborder = border

	specbar:SetStatusBarTexture(C.media.normTex)
	specbar:GetStatusBarTexture():SetHorizTile(false)
	specbar:SetBackdrop({bgFile = C.media.blank})
	specbar:SetBackdropColor(.2, .2, .2, 1)
	specbar:SetMinMaxValues(0, 5)
	specbar:SetValue(0)

	specbar.t = specbar:CreateFontString(specbar, "OVERLAY")
	specbar.t:Point("CENTER", specbar, "CENTER", 0, 0)
	specbar.t:SetFont(C["media"].uffont, C.datatext.fontsize)

	specbar:SetAlpha(0)

	specbar:RegisterEvent("UNIT_SPELLCAST_SENT")
	specbar:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	specbar:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
	specbar:SetScript("OnEvent", function(self, event, unit, spellName)
		--print("EVENT: "..event.."   "..tostring(unit).."  "..tostring(spellName))
		if unit ~= "player" then return end
		if spellName ~= ActivatePrimarySpecSpellName and spellName ~= ActivateSecondarySpecSpellName then return end
		if event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_SUCCEEDED" then
			if TukuiPlayerCastBar then TukuiPlayerCastBar:SetAlpha(1) end
			self:SetAlpha(0)
			self:SetScript("OnUpdate", nil)
		elseif event == "UNIT_SPELLCAST_SENT" then
			if TukuiPlayerCastBar then TukuiPlayerCastBar:SetAlpha(0) end
			self:SetAlpha(1)
			self:SetValue(0)
			self.t:SetText(spellName)
			self:SetScript("OnUpdate", function(self)
				local _, _, _, _, startTime, _, _, _, _ = UnitCastingInfo("player")
				if startTime == nil then return end
				local val = GetTime() - startTime/1000
				--print(val.." "..startTime)
				self:SetValue(val)
			end)
		end
	end)
end

-----------
-- Spec
-----------
local spec = CreateFrame("Button", "Tukui_Spechelper", UIParent)
--spec:CreatePanel("Default", 10, 20, "TOPRIGHT", UIParent, "TOPRIGHT", -32, -212)
spec:SetTemplate()
spec:Size(10, 20)
spec:Point("TOPRIGHT", UIParent, "TOPRIGHT", -32, -212)

-- Anchoring
-- if TukuiRaidUtilityShowButton is shown, anchor it
-- else if TukuiRaidUtilityClose is shown, anchor it
-- else if TukuiMinimapStatsLeft, anchor it
-- else if TukuiMinimap, anchor it
-- else, anchor to center of screen

local function AnchorSpec()
	-- Get raid utility frame
	local raidUtilityFrame = _G["TukuiRaidUtility"]
	-- default pos
	if TukuiMinimapStatsLeft then
		spec:ClearAllPoints()
		spec:Point("TOPLEFT", TukuiMinimapStatsLeft, "BOTTOMLEFT", 0, -3)
		spec:Point("TOPRIGHT", TukuiMinimapStatsRight, "BOTTOMRIGHT", -23, -3)
	elseif TukuiMinimap then
		spec:ClearAllPoints()
		spec:Point("TOPLEFT", TukuiMinimap, "BOTTOMLEFT", 0, -3)
		spec:Point("TOPRIGHT", TukuiMinimap, "BOTTOMRIGHT", -23, -3)
	end
	if raidUtilityFrame then
		local raidUtilityShowButton = _G["TukuiRaidUtilityShowButton"]
		local raidUtilityCloseButton = _G["TukuiRaidUtilityCloseButton"]

		if raidUtilityShowButton and raidUtilityCloseButton then
			-- Anchoring function
			local function SetAnchor(self)
				if raidUtilityShowButton:IsShown() then
					spec:ClearAllPoints()
					spec:Point("TOPLEFT", raidUtilityShowButton, "BOTTOMLEFT", 0, -3)
					spec:Point("TOPRIGHT", raidUtilityShowButton, "BOTTOMRIGHT", -23, -3)
				elseif raidUtilityCloseButton:IsShown() then
					spec:ClearAllPoints()
					spec:Point("TOPLEFT", raidUtilityCloseButton, "BOTTOMLEFT", 0, -3)
					spec:Point("TOPRIGHT", raidUtilityCloseButton, "BOTTOMRIGHT", -23, -3)
				end
			end

			raidUtilityShowButton:HookScript("OnShow", SetAnchor)
			raidUtilityShowButton:HookScript("OnHide", SetAnchor)
			--SetAnchor(raidUtilityShowButton)
		end
	end
end

-- Text
spec.t = spec:CreateFontString(spec, "OVERLAY")
spec.t:SetPoint("CENTER")
spec.t:SetFont(C["media"].uffont, C.datatext.fontsize)
-- events
spec:RegisterEvent("PLAYER_TALENT_UPDATE")
spec:RegisterEvent("PLAYER_ENTERING_WORLD")
spec:RegisterEvent("CHARACTER_POINTS_CHANGED")
spec:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
spec:RegisterEvent("PLAYER_ENTERING_WORLD")
spec:RegisterEvent("PLAYER_ENTERING_WORLD")
spec:SetScript("OnEvent", function(self, event)
	if event == "PLAYER_ENTERING_WORLD" then
		AnchorSpec()
		spec:UnregisterEvent("PLAYER_ENTERING_WORLD")
		return
	end
	if not GetSpecialization() then spec.t:SetText("No talents") return end
	local specIndex, name = GetCurrentSpec()
	if not name then return end
	spec.t:SetText(name)

	if HasDualSpec() then
		local secondarySpecIndex, secondarySpecName = GetSecondarySpec()
		if secondarySpecIndex ~= nil then
			spec:SetScript("OnEnter", function() spec.t:SetText(cm..secondarySpecName) end)
			spec:SetScript("OnLeave", function() spec.t:SetText(name) end)
		else
			spec:SetScript("OnEnter", function() spec.t:SetText(cm.."No talents") end)
			spec:SetScript("OnLeave", function() spec.t:SetText(name) end)
		end
	end
	--end
end)

spec:SetScript("OnClick", function(self)
	if IsModifierKeyDown() then
		ToggleTalentFrame()
	else
		local i = GetActiveSpecGroup()
		if i == 1 then
			SetActiveSpecGroup(2)
		elseif i == 2 then
			SetActiveSpecGroup(1)
		end
	end
end)

if SpecSwitchCastbar == true then
	SpecChangeCastbar(spec)
end

------------
-- Move UI
------------
local mui = CreateFrame("Button", nil, spec, "SecureActionButtonTemplate")
--mui:CreatePanel("Default", 48, 19, "TOPLEFT", spec, "BOTTOMLEFT", 0, -3)
mui:SetTemplate()
mui:Size(48+29+3, 19)
mui:Point("TOPLEFT", spec, "BOTTOMLEFT", 0, -3)
mui:Hide()
mui.t = mui:CreateFontString(nil, "OVERLAY")
mui.t:SetPoint("CENTER")
mui.t:SetFont(C["media"].uffont, C.datatext.fontsize)
mui.t:SetText("Move UI")

mui:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(unpack(hoverovercolor)) end)
mui:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(unpack(C.media.bordercolor)) end)
mui:SetAttribute("type", "macro")
mui:SetAttribute("macrotext", "/moveui")

------------
-- Key Binds
------------
local binds = CreateFrame("Button", nil, mui, "SecureActionButtonTemplate")
--binds:CreatePanel("Default", 30, 19, "LEFT", mui, "RIGHT", 3, 0)
binds:SetTemplate()
binds:Size(30+28+3, 19)
binds:Point("LEFT", mui, "RIGHT", 3, 0)

binds.t = binds:CreateFontString(nil, "OVERLAY")
binds.t:SetPoint("CENTER")
binds.t:SetFont(C["media"].uffont, C.datatext.fontsize)
binds.t:SetText("Bind")

binds:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(unpack(hoverovercolor)) end)
binds:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(unpack(C.media.bordercolor)) end)
binds:SetAttribute("type", "macro")
binds:SetAttribute("macrotext", "/bindkey")

-- ---------------
-- -- Heal layout
-- ---------------
-- local heal = CreateFrame("Button", nil, mui, "SecureActionButtonTemplate")
-- --heal:CreatePanel("Default", 29, 19, "LEFT", binds, "RIGHT", 3, 0)
-- heal:SetTemplate()
-- heal:Size(29, 19)
-- heal:Point("LEFT", binds, "RIGHT", 3, 0)

-- heal.t = heal:CreateFontString(nil, "OVERLAY")
-- heal.t:SetPoint("CENTER")
-- heal.t:SetFont(C["media"].uffont, C.datatext.fontsize)
-- heal.t:SetText("HEAL")

-- heal:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(unpack(hoverovercolor)) end)
-- heal:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(unpack(C.media.bordercolor)) end)
-- heal:SetAttribute("type", "macro")
-- heal:SetAttribute("macrotext", "/heal")

-- --------------
-- -- DPS layout
-- --------------
-- local dps = CreateFrame("Button", nil, mui, "SecureActionButtonTemplate")
-- --dps:CreatePanel("Default", 28, 19, "LEFT", heal, "RIGHT", 3, 0)
-- dps:SetTemplate()
-- dps:Size(28, 19)
-- dps:Point("LEFT", heal, "RIGHT", 3, 0)

-- dps.t = dps:CreateFontString(nil, "OVERLAY")
-- dps.t:SetPoint("CENTER")
-- dps.t:SetFont(C["media"].uffont, C.datatext.fontsize)
-- dps.t:SetText("DPS")

-- dps:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(unpack(hoverovercolor)) end)
-- dps:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(unpack(C.media.bordercolor)) end)
-- dps:SetAttribute("type", "macro")
-- dps:SetAttribute("macrotext", "/dps")

------------------
-- Gear switching
------------------
if EnableGear == true then
	local gearSets = CreateFrame("Frame", nil, binds)
	for i = 1, MaxSets do
		gearSets[i] = CreateFrame("Button", nil, binds)
		--gearSets[i]:CreatePanel("Default", 19, 19, "CENTER", dps, "CENTER", 0, 0)
		gearSets[i]:SetTemplate()
		gearSets[i]:Size(19, 19)

		if i == 1 then
			gearSets[i]:Point("TOPRIGHT", binds, "BOTTOMRIGHT", 0, -3)
		else
			gearSets[i]:Point("BOTTOMRIGHT", gearSets[i-1], "BOTTOMLEFT", -3, 0)
		end
		gearSets[i].texture = gearSets[i]:CreateTexture(nil, "BORDER")
		gearSets[i].texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		gearSets[i].texture:SetPoint("TOPLEFT", gearSets[i] ,"TOPLEFT", 2, -2)
		gearSets[i].texture:SetPoint("BOTTOMRIGHT", gearSets[i] ,"BOTTOMRIGHT", -2, 2)

		-- gearSets[i]:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(unpack(hoverovercolor)) end)
		-- gearSets[i]:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(unpack(C.media.bordercolor)) end)
		gearSets[i]:SetScript("OnEnter", function(self) 
			self:SetBackdropBorderColor(unpack(hoverovercolor))

			local name = GetEquipmentSetInfo(i)
			GameTooltip:SetOwner(self, "ANCHOR_LEFT")
			GameTooltip:ClearLines()
			GameTooltip:AddLine(name, 1, 1, 1)
			GameTooltip:Show()
		end)
		gearSets[i]:SetScript("OnLeave", function(self)
			self:SetBackdropBorderColor(unpack(C.media.bordercolor))

			GameTooltip:Hide()
		end)
	end
	gearSets:RegisterEvent("PLAYER_ENTERING_WORLD")
	gearSets:RegisterEvent("EQUIPMENT_SETS_CHANGED")
	gearSets:SetScript("OnEvent", function(self, event)
		local numSets = math.min(GetNumEquipmentSets(), MaxSets)
		for i = 1, numSets, 1 do
			local name, icon = GetEquipmentSetInfo(i)
			gearSets[i]:SetScript("OnClick", function(self) UseEquipmentSet(name) end)
			gearSets[i].texture:SetTexture(icon)
			gearSets[i]:Show()
		end
		for i = numSets+1, MaxSets, 1 do
			gearSets[i]:Hide()
		end

		if AutoGearSwap == true then
			gearSets[set1]:SetBackdropBorderColor(0,1,0)
			gearSets[set1]:SetScript("OnEnter", nil)
			gearSets[set1]:SetScript("OnLeave", nil)
			gearSets[set2]:SetBackdropBorderColor(1,0,0)
			gearSets[set2]:SetScript("OnEnter", nil)
			gearSets[set2]:SetScript("OnLeave", nil)
		end
	end)

	if AutoGearSwap == true then
		local gearsetfunc = CreateFrame("Frame", "gearSetfunc", UIParent)

		gearsetfunc:RegisterEvent("PLAYER_ENTERING_WORLD")
		gearsetfunc:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
		gearsetfunc:SetScript("OnEvent", function(self, event)
			AutoGear(set1, set2)
		end)
	end
end

----------------
-- Toggle Button
----------------
local toggle = CreateFrame("Button", nil, spec)
--toggle:CreatePanel("Default", 20, 20, "TOPLEFT", spec, "TOPRIGHT", 3, 0)
toggle:SetTemplate()
toggle:Size(20, 20)
toggle:Point("TOPLEFT", spec, "TOPRIGHT", 3, 0)

toggle.t = toggle:CreateFontString(nil, "OVERLAY")
toggle.t:SetPoint("CENTER")
toggle.t:SetFont(C["media"].uffont, C.datatext.fontsize)
toggle.t:SetText(cp.."+|r")
toggle:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(unpack(hoverovercolor)) end)
toggle:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(unpack(C.media.bordercolor)) end)

toggle:SetScript("OnClick", function(self)
	if mui:IsShown() then
		mui:Hide()
		toggle.t:SetText(cp.."+")
	else
		mui:Show()
		toggle.t:SetText(cm.."-")
	end
end)