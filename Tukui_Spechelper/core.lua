-----------------------------------------------
-- Spec Helper, by EPIC rewritten by SinaC
-----------------------------------------------

--[[
	((         SPECBAR      ))((.))
	((   MOVEUI   ))(( BINDINGS  ))
((eq5))((eq4))((eq3))((eq2))((eq1))

	click on eqX button, equip this set
	right-click on eqX button, set autogear for current spec on this set
	click on . to show/hide MOVEUI/BINDINS/EQX
--]]
local ADDON_NAME, ns = ...
local T, C, L = unpack(Tukui) -- Import: T - functions, constants, variables; C - config; L - locales

-- colors
local hoverColor = {.4, .4, .4}
local plusTextColor = "|cff319f1b"
local minusTextColor = "|cff9a1212"
local secondaryTextColor = "|cff9a1212"

-- settings
local MaxSets = 10 -- TODO: find constants in Blizzard's code

-- helpers
local function HasDualSpec() -- return if player has learned dual spec
	return GetNumSpecGroups() > 1
end

local function GetAlternativeSpecIndex() -- return alternative spec index
	local active = GetActiveSpecGroup()
	if active == 1 then return 2
	elseif active == 2 then return 1
	else return 0
	end
end

local function GetCurrentSpec() -- return info about current spec
	local index = GetSpecialization(false, false, GetActiveSpecGroup())
	local name = index and select(2, GetSpecializationInfo(index))
	return index, name
end	

local function GetAlternativeSpec() -- return info about alternative spec
	local index = GetSpecialization(false, false, GetAlternativeSpecIndex())
	local name = index and select(2, GetSpecializationInfo(index))
	return index, name
end

local function GetSpec(index) -- return info about parameter spec
	local specIndex = GetSpecialization(false, false, index)
	local name = specIndex and select(2, GetSpecializationInfo(specIndex))
	return specIndex, name
end

-----------
-- Spec
-----------
local function DefaultAnchor(spec)
	-- Attach to minimap by default
	spec:ClearAllPoints()
	if TukuiMinimapStatsLeft then
		spec:Point("TOPLEFT", TukuiMinimapStatsLeft, "BOTTOMLEFT", 0, -3)
		spec:Point("TOPRIGHT", TukuiMinimapStatsRight, "BOTTOMRIGHT", -23, -3)
	elseif TukuiMinimap then
		spec:Point("TOPLEFT", TukuiMinimap, "BOTTOMLEFT", 0, -3)
		spec:Point("TOPRIGHT", TukuiMinimap, "BOTTOMRIGHT", -23, -3)
	end
end
local function AnchorSpec(spec)
	-- Get raid utility frame
	local raidUtilityFrame = _G["TukuiRaidUtility"]
	-- Default pos
	DefaultAnchor(spec)
	if raidUtilityFrame then
		local raidUtilityShowButton = _G["TukuiRaidUtilityShowButton"]
		local raidUtilityCloseButton = _G["TukuiRaidUtilityCloseButton"]
		raidUtilityShowButton:HookScript("OnShow", function(self)
			-- Attach to show button when showing raidUtilityShowButton
			spec:ClearAllPoints()
			spec:Point("TOPLEFT", raidUtilityShowButton, "BOTTOMLEFT", 0, -3)
			spec:Point("TOPRIGHT", raidUtilityShowButton, "BOTTOMRIGHT", -23, -3)
		end)
		raidUtilityShowButton:HookScript("OnHide", function(self)
			-- Attach to minimap when hiding TukuiRaidUtilityShowButton and TukuiRaidUtility is not toggled <- leave party when TukuiRaidUtility is closed
			if not TukuiRaidUtility.toggled then
				DefaultAnchor(spec)
			end
		end)
		raidUtilityFrame:HookScript("OnShow", function(self)
			-- Attach to close button when showing TukuiRaidUtility
			spec:ClearAllPoints()
			spec:Point("TOPLEFT", raidUtilityCloseButton, "BOTTOMLEFT", 0, -3)
			spec:Point("TOPRIGHT", raidUtilityCloseButton, "BOTTOMRIGHT", -23, -3)
		end)
		raidUtilityFrame:HookScript("OnHide", function(self)
			-- Attach to minimap when hiding TukuiRaidUtility and toggled <- leave party when TukuiRaidUtility is opened
			if TukuiRaidUtility.toggled then
				DefaultAnchor(spec)
			end
		end)
	end
end
-- frame
local spec = CreateFrame("Button", "Tukui_Spechelper", TukuiPetBattleHider)
spec:SetTemplate()
spec:Size(10, 20) -- overwritten while anchoring
DefaultAnchor(spec) -- anchor will be reset when entering world
-- text
spec.text = spec:CreateFontString(spec, "OVERLAY")
spec.text:SetPoint("CENTER")
spec.text:SetFont(C["media"].uffont, C.datatext.fontsize)
-- events
spec:RegisterEvent("PLAYER_ENTERING_WORLD")
spec:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", "player")
spec:SetScript("OnEvent", function(self, event)
	if event == "PLAYER_ENTERING_WORLD" then
		AnchorSpec(self)
		self:UnregisterEvent("PLAYER_ENTERING_WORLD") -- fire only once
	end
	if not GetSpecialization() then
		spec.text:SetText(L.spechelper_NOTALENTS)
		return
	end
	local _, specName = GetCurrentSpec()
	if not specName then return end
	spec.specName = specName
	spec.text:SetText(specName)

	if HasDualSpec() then
		local _, secondarySpecName = GetAlternativeSpec()
		spec.secondarySpecName = secondarySpecName
	else
		spec.secondarySpecName = nil
	end
end)
spec:SetScript("OnEnter", function(self)
	if self.secondarySpecName then
		spec.text:SetText(secondaryTextColor..self.secondarySpecName)
	else
		spec.text:SetText(secondaryTextColor..L.spechelper_NOTALENTS)
	end
end)
spec:SetScript("OnLeave", function(self)
	if spec.specName then
		spec.text:SetText(spec.specName)
	else
		spec.text:SetText(L.spechelper_NOTALENTS)
	end
end)
spec:SetScript("OnClick", function(self)
	if IsModifierKeyDown() then
		ToggleTalentFrame()
	else
		local secondarySpec = GetAlternativeSpecIndex()
		if 0 ~= secondarySpec then
			SetActiveSpecGroup(secondarySpec)
		end
	end
end)

------------
-- Move UI
------------
local mui = CreateFrame("Button", nil, spec, "SecureActionButtonTemplate")
mui:SetTemplate()
mui:Size(48+29+3, 19)
mui:Point("TOPLEFT", spec, "BOTTOMLEFT", 0, -3)
mui:Hide()
mui.text = mui:CreateFontString(nil, "OVERLAY")
mui.text:SetPoint("CENTER")
mui.text:SetFont(C["media"].uffont, C.datatext.fontsize)
mui.text:SetText(L.spechelper_MOVEUI)

mui:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(unpack(hoverColor)) end)
mui:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(unpack(C.media.bordercolor)) end)
mui:SetAttribute("type", "macro")
mui:SetAttribute("macrotext", "/moveui")

------------
-- Key Binds
------------
local binds = CreateFrame("Button", nil, mui, "SecureActionButtonTemplate")
binds:SetTemplate()
binds:Size(30+28+3, 19)
binds:Point("LEFT", mui, "RIGHT", 3, 0)

binds.text = binds:CreateFontString(nil, "OVERLAY")
binds.text:SetPoint("CENTER")
binds.text:SetFont(C["media"].uffont, C.datatext.fontsize)
binds.text:SetText(L.spechelper_BIND)

binds:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(unpack(hoverColor)) end)
binds:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(unpack(C.media.bordercolor)) end)
binds:SetAttribute("type", "macro")
binds:SetAttribute("macrotext", "/bindkey")

------------------
-- Gear switching
------------------
-- tooltip
local inToolTip = false
local function UpdateGearSetTooltip(self)
	if inToolTip then
		if self.setName then
			self:SetBackdropBorderColor(unpack(hoverColor))
			GameTooltip:SetOwner(self, "ANCHOR_LEFT")
			GameTooltip:ClearLines()
			GameTooltip:AddDoubleLine(self.setName, L.spechelper_CLICKTOEQUIP, 1, 1, 1, 1, 1, 1)
			local found = false
			for autoGearIndex, autoGearSetName in pairs(TukuiSpecHelperDataPerCharacter.autoGearSet) do
				if autoGearSetName == self.setName then
					local _, specName = GetSpec(autoGearIndex)
					GameTooltip:AddDoubleLine(L.spechelper_AUTOGEAR, specName, 1, 1, 1, 1, 1, 1)
					found = true
					break
				end
			end
			if not found then
				local _, specName = GetCurrentSpec()
				GameTooltip:AddDoubleLine(L.spechelper_CLICKTOAUTOGEAR, specName, 1, 1, 1, 1, 1, 1)
			end
			GameTooltip:Show()
		end
	end
end
-- frames
local gearSets = CreateFrame("Frame", nil, binds)
for i = 1, MaxSets do
	gearSets[i] = CreateFrame("Button", nil, binds)
	gearSets[i]:SetTemplate()
	gearSets[i]:Size(19, 19)
	if i == 1 then
		gearSets[i]:Point("TOPRIGHT", binds, "BOTTOMRIGHT", 0, -3)
	else
		gearSets[i]:Point("BOTTOMRIGHT", gearSets[i-1], "BOTTOMLEFT", -3, 0)
	end
	gearSets[i].texture = gearSets[i]:CreateTexture(nil, "BORDER")
	gearSets[i].texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	gearSets[i].texture:SetPoint("TOPLEFT", gearSets[i], "TOPLEFT", 2, -2)
	gearSets[i].texture:SetPoint("BOTTOMRIGHT", gearSets[i], "BOTTOMRIGHT", -2, 2)
	gearSets[i]:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	gearSets[i]:SetScript("OnEnter", function(self)
		inToolTip = true
		UpdateGearSetTooltip(self)
	end)
	gearSets[i]:SetScript("OnLeave", function(self)
		inToolTip = false
		self:SetBackdropBorderColor(unpack(C.media.bordercolor))
		GameTooltip:Hide()
	end)
	gearSets[i]:SetScript("OnClick", function(self, button, down)
		if not self.setName then return end
		if button == "RightButton" then -- right-click -> set as autogear
			local currentSpec = GetActiveSpecGroup()
			TukuiSpecHelperDataPerCharacter.autoGearSet[currentSpec] = self.setName
			UpdateGearSetTooltip(self)
		end
		UseEquipmentSet(self.setName)
	end)
end
-- events
gearSets:RegisterEvent("ADDON_LOADED")
gearSets:RegisterEvent("PLAYER_ENTERING_WORLD")
gearSets:RegisterEvent("EQUIPMENT_SETS_CHANGED")
gearSets:SetScript("OnEvent", function(self, event, arg1)
	if event == "ADDON_LOADED" then
		if arg1 == ADDON_NAME then
			if not TukuiSpecHelperDataPerCharacter then
				TukuiSpecHelperDataPerCharacter = {} -- create saved variables
				TukuiSpecHelperDataPerCharacter.autoGearSet = {}
			end
		end
		return -- stop here
	end
	if event == "PLAYER_ENTERING_WORLD" then
		self:UnregisterEvent("PLAYER_ENTERING_WORLD") -- fire only once
	end
	-- update gearSet visibility
	local numSets = math.min(GetNumEquipmentSets(), MaxSets)
	for i = 1, numSets, 1 do
		local name, icon = GetEquipmentSetInfo(i)
		gearSets[i].setName = name
		gearSets[i].texture:SetTexture(icon)
		gearSets[i]:Show()
	end
	for i = numSets+1, MaxSets, 1 do
		gearSets[i]:Hide()
	end
	-- update autoGearSet
	if TukuiSpecHelperDataPerCharacter.autoGearSet then
		for index, autoGearSetName in pairs(TukuiSpecHelperDataPerCharacter.autoGearSet) do
			local found = false
			for i = 1, numSets, 1 do
				local name = GetEquipmentSetInfo(i)
				if name == autoGearSetName then
					found = true
					break
				end
			end
			if not found then
				TukuiSpecHelperDataPerCharacter.autoGearSet[index] = nil
			end
		end
	end
end)
-- autogear
local autoGearSwapHandler = CreateFrame("Frame")
autoGearSwapHandler:RegisterEvent("PLAYER_ENTERING_WORLD")
autoGearSwapHandler:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", "player")
autoGearSwapHandler:SetScript("OnEvent", function(self, event)
	if event == "PLAYER_ENTERING_WORLD" then
		self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	end
	local activeSpec = GetActiveSpecGroup()
	if TukuiSpecHelperDataPerCharacter.autoGearSet[activeSpec] then -- autogear for active spec
		UseEquipmentSet(TukuiSpecHelperDataPerCharacter.autoGearSet[activeSpec])
	end
end)

----------------
-- Toggle Button
----------------
local toggle = CreateFrame("Button", nil, spec)
toggle:SetTemplate()
toggle:Size(20, 20)
toggle:Point("TOPLEFT", spec, "TOPRIGHT", 3, 0)

toggle.text = toggle:CreateFontString(nil, "OVERLAY")
toggle.text:SetPoint("CENTER")
toggle.text:SetFont(C["media"].uffont, C.datatext.fontsize)
toggle.text:SetText(plusTextColor.."+|r")
toggle:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(unpack(hoverColor)) end)
toggle:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(unpack(C.media.bordercolor)) end)

toggle:SetScript("OnClick", function(self)
	if mui:IsShown() then
		mui:Hide()
		toggle.text:SetText(plusTextColor.."+")
	else
		mui:Show()
		toggle.text:SetText(minusTextColor.."-")
	end
end)