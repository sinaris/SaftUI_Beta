local st = SaftUI
local LSM = LibStub('LibSharedMedia-3.0')

local CB = st:NewModule('ClassBars', 'AceHook-3.0', 'AceEvent-3.0')

CB.Modules = {}

function CB:UpdateModulePosition(moduleName)
	local module = self.Modules[moduleName]
	module:ClearAllPoints()
	module:SetPoint(unpack(st.Saved.profile.ClassBars[moduleName].point))
end

function CB:UpdateModuleOrientation(moduleName)
	local module = self.Modules[moduleName]
	local config = st.Saved.profile.ClassBars[moduleName]

	local pos1,pos2

	if config.orientation == 'vertical' then
		pos1 = config.reverse == true and 'TOP' or 'BOTTOM'
		pos2 = config.reverse == true and 'BOTTOM' or 'TOP'
	else
		pos1 = config.reverse == true and 'RIGHT' or 'LEFT'
		pos2 = config.reverse == true and 'LEFT' or 'RIGHT'		
	end

	local totalSpacing = (module.ShownUnits-1)
	local totalWidth = module:GetWidth()
	local totalHeight = module:GetHeight()

	for i = 1, module.ShownUnits do

		if config.orientation == 'vertical' then
			module[i]:SetHeight((totalHeight-totalSpacing)/module.ShownUnits)
			module[i]:SetWidth(totalWidth)
		else
			module[i]:SetHeight(totalHeight)
			module[i]:SetWidth((totalWidth-totalSpacing)/module.ShownUnits)
		end

		module[i]:ClearAllPoints()
		if i == 1 then
			module[i]:SetPoint(pos1, module, pos1, 0, 0)
		else
			if config.orientation == 'vertical' then
				module[i]:SetPoint(pos1, module[i-1], pos2, 0, -1)
			else
				module[i]:SetPoint(pos1, module[i-1], pos2, 1, 0)				
			end
			if i == module.ShownUnits then 
				module[i]:SetPoint(pos2, module, pos2, 0, 0)
			end
		end
	end
end

local function SetActiveStacks(self,count)
	local showEmpty = st.Saved.profile.ClassBars[self.ModuleName].showEmpty
	for i=1, self.ShownUnits do
		if i > (count or 0) then
			if showEmpty then
				self[i].Texture:SetVertexColor(.2,.2,.2)
			else
				self[i]:Hide()
			end
		else
			if showEmpty then
				local color = self.ColorType == 'single' and self.Colors or self.Colors[i]
				self[i].Texture:SetVertexColor(unpack(color))
			else
				self[i]:Show()
			end
		end
	end
end

function CB:CreateUnit(module, ID)
	local unit = CreateFrame('Frame', nil, module)
	unit:SetTemplate('')
	local color = module.ColorType == 'single' and module.Colors or module.Colors[ID]
	unit.ID = ID

	--Create unit frames with specific type
	if module.UnitType == 'stacks' then
		unit.Texture = unit:CreateTexture(nil, 'OVERLAY')
		unit.Texture:SetPoints(unit, 1)
		unit.Texture:SetTexture(st.BLANK_TEX)
		unit.Texture:SetVertexColor(unpack(color))
	elseif module.UnitType == 'bars' then
		unit.StatusBar = CreateFrame('StatusBar', nil, module)
		unit.StatusBar:SetPoints(unit, 1)
		unit.StatusBar:SetStatusBarTexture(st.BLANK_TEX)
		unit.StatusBar:SetStatusBarColor(unpack(color))
		unit.StatusBar:SetMinMaxValues(0, 1)
		unit.Text = unit.StatusBar:CreateFontString(nil, 'OVERLAY')
		unit.Text:SetFontObject(st.pixelFont)
		unit.Text:SetPoint('CENTER')
	end

	module[ID] = unit
end

local function SetMaxUnits(self, maxUnits)
	--If no change is needed and all units are created, stop here
	if maxUnits == self.ShownUnits and self[maxUnits] then return end

	self.ShownUnits = maxUnits
	self.TotalUnits = math.max(maxUnits, self.TotalUnits)

	for i=1, self.TotalUnits do
		if i > self.ShownUnits  then
			self[i]:Hide()
		elseif self[i] then
			self[i]:Show()
		else
			CB:CreateUnit(self,i)
		end
	end

	CB:UpdateModuleOrientation(self.ModuleName)
end

function CB:InitializeModule(moduleName)
	local module = self.Modules[moduleName]
	local config = st.Saved.profile.ClassBars[moduleName]

	
	module:SetSize(config.width, config.height)
	-- module:SetTemplate()
	module:SetMaxUnits(module.ShownUnits)
	self:UpdateModulePosition(moduleName)

	module:EnableMoving(true)
	hooksecurefunc(module, 'StopMovingOrSizing', function(self)
		local point, relativeTo, relativePoint, xOffset, yOffset = self:GetPoint()
		st.Saved.profile.ClassBars[moduleName].point = {
			point, relativeTo, relativePoint, floor(xOffset+0.5), floor(yOffset+0.5) }

		CB:UpdateModulePosition(moduleName)		
	end)
end

function CB:RegisterModule(moduleName, Trigger, Enable, Disable, UnitType, NumUnits, Colors)
	assert(not self.Modules[strlower(moduleName)], 'The '..moduleName..' module is already registered.')

	local module = CreateFrame('frame', "SaftUIClassBar"..moduleName, UIParent)

	module.Colors = Colors or {1,1,1}
	module.ColorType = type(module.Colors[1]) == 'table' and 'multiple' or 'single'
	module.UnitType = strlower(UnitType)
	module.ShownUnits = NumUnits --Amount of units to show
	module.TotalUnits = NumUnits --Total units created
	module.ModuleName = strlower(moduleName)

	module:Hide()

	function module:Enable()
		if not self.Initialized then
			CB:InitializeModule(self.ModuleName)
		end

		if not self.Enabled then
			self:Show()
			self.Enabled = true
			Enable(self)
		end
	end

	function module:Disable()
		if self.Enabled then
			self:Hide()
			self.Enabled = false
			Disable(self)
		end
	end
	
	function module:IsEnabled()
		return self.Enabled
	end

	module.SetActiveStacks = SetActiveStacks
	module.Trigger = Trigger
	module.SetMaxUnits = SetMaxUnits

	self.Modules[module.ModuleName] = module
end

function CB:OnInitialize()
	for moduleName,module in pairs(self.Modules) do
		local config = st.Saved.profile.ClassBars[moduleName]
		assert(config, 'Default config missing for ' .. moduleName .. ' module.')
		if module:Trigger() and config.enable then
			module:Enable()
		end
	end
end
---------------------------------------------
-- MODULES ----------------------------------
---------------------------------------------


-- ComboPoints ------------------------------
---------------------------------------------
do
	local Colors = {
		[1] = {.8, .3, .3},
		[2] = {.8, .8, .3},
		[3] = {.8, .8, .3},
		[4] = {.3, .8, .3},
		[5] = {.3, .8, .3},
	}

	local function Update(self)
		self:SetActiveStacks(GetComboPoints('player', 'target'))
	end

	local function Trigger(self)
		return true
	end

	local function Enable(self)
		self:RegisterEvent('UNIT_COMBO_POINTS')
		self:SetScript('OnEvent', Update)
		Update(self)
	end

	local function Disable(self)
		self:UnregisterAllEvents()
		self:SetScript('OnEvent', nil)
	end

	CB:RegisterModule('ComboPoints', Trigger, Enable, Disable, 'stacks', 5, Colors)
end

-- Burning Embers ---------------------------
---------------------------------------------
do
	local Color = {1.0, 0.4, 0.2}

	local function OnEvent(self, event, unit, powerType)
		if event == 'UNIT_POWER' and not (unit == 'player' and powerType == 'BURNING_EMBERS') then return end

		if event == 'PLAYER_TALENT_UPDATE' then
			if GetSpecialization() == SPEC_WARLOCK_DESTRUCTION then
				self:Enable()
			else
				return self:Disable()
			end
		end

		local power = UnitPower('player', SPELL_POWER_BURNING_EMBERS, true)
		local stacks = (power / self.maxPower) * self.maxStacks 

		for i=1, self.maxStacks do
			if stacks >= 1 then
				self[i].StatusBar:SetValue(1)
				stacks = stacks - 1
				self[i].Text:SetText('')
			elseif stacks == 0 then
				self[i].Text:SetText('')
				self[i].StatusBar:SetValue(0)
			else
				self[i].StatusBar:SetValue(stacks)

				self[i].Text:SetText(stacks*10)
				stacks = 0
			end
		end
	end


	local function Trigger(self)
		if st.MY_CLASS == 'WARLOCK' then
			self:RegisterEvent('PLAYER_TALENT_UPDATE')
			return true
		end
	end

	local function Enable(self)
		self.maxStacks = UnitPowerMax('player', SPELL_POWER_BURNING_EMBERS)
		self.maxPower = UnitPowerMax('player', SPELL_POWER_BURNING_EMBERS, true)

		--Force an initial check for Destruction spec
		OnEvent(self, 'PLAYER_TALENT_UPDATE')

		self:SetScript('OnEvent', OnEvent)
		self:RegisterEvent('UNIT_POWER')		
	end

	local function Disable(self)
		self:UnregisterEvent('UNIT_POWER')
	end

	CB:RegisterModule('BurningEmbers', Trigger, Enable, Disable, 'bars', 4, Color)
end

-- Demonic Fury -----------------------------
---------------------------------------------
do
	local Color = {0.6, 0.4, 0.8}

	local function OnEvent(self, event, unit, powerType)
		if event == 'UNIT_POWER' and not (unit == 'player' and powerType == 'DEMONIC_FURY') then return end

		if event == 'PLAYER_TALENT_UPDATE' then
			if GetSpecialization() == SPEC_WARLOCK_DEMONOLOGY then
				self:Enable()
			else
				return self:Disable()
			end
		end

		local min, max = UnitPower('player', SPELL_POWER_DEMONIC_FURY), UnitPowerMax('player', SPELL_POWER_DEMONIC_FURY)
		self[1].StatusBar:SetValue(min/max)
		self[1].Text:SetText(min)
	end

	local function Trigger(self)
		if st.MY_CLASS == 'WARLOCK' then
			self:RegisterEvent('PLAYER_TALENT_UPDATE')
			return true
		end
	end

	local function Enable(self)
		--Force an initial check for Demonology spec
		OnEvent(self, 'PLAYER_TALENT_UPDATE')

		self:RegisterEvent('UNIT_POWER')
		self:SetScript('OnEvent', OnEvent)		
	end

	local function Disable(self)
		self:UnregisterEvent('UNIT_POWER')
	end

	CB:RegisterModule('DemonicFury', Trigger, Enable, Disable, 'bars', 1, Color)
end

-- Soul Shards ------------------------------
---------------------------------------------
do
	local Color = {0.6, 0.4, 0.8}

	local function OnEvent(self, event, unit, powerType)
		if event == 'UNIT_POWER' and not (unit == 'player' and powerType == 'SOUL_SHARDS') then return end

		if event == 'PLAYER_TALENT_UPDATE' then
			if GetSpecialization() == SPEC_WARLOCK_AFFLICTION then
				self:Enable()
			else
				return self:Disable()
			end
		end

		self:SetActiveStacks(UnitPower('player', SPELL_POWER_SOUL_SHARDS))
	end


	local function Trigger(self)
		if st.MY_CLASS == 'WARLOCK' then
			self:RegisterEvent('PLAYER_TALENT_UPDATE')
			return true
		end
	end

	local function Enable(self)
		--Force an initial check for Affliction spec
		OnEvent(self, 'PLAYER_TALENT_UPDATE')

		self:SetScript('OnEvent', OnEvent)
		self:RegisterEvent('UNIT_POWER')		
	end

	local function Disable(self)
		self:UnregisterEvent('UNIT_POWER')
	end

	CB:RegisterModule('SoulShards', Trigger, Enable, Disable, 'stacks', 4, Color)
end


-- Fulmination ------------------------------
---------------------------------------------
do
	local Colors = {
		[1] = {0,.3,1},
		[2] = {0,.4,1},
		[3] = {0,.5,1},
		[4] = {0,.6,1},
		[5] = {0,.7,1},
		[6] = {0,.8,1},
	}

	local function OnEvent(self, event, ...)
		if event == 'ACTIVE_TALENT_GROUP_CHANGED' or event == 'PLAYER_LEVEL_UP' then
			if IsSpellKnown(88766) then
				self:Enable()
			else
				return self:Disable()
			end
		end
		local stacks = select(4, UnitBuff('player', 'Lightning Shield')) or 0
		self:SetActiveStacks(stacks-1)
	end

	local function Trigger(self)
		if st.MY_CLASS == 'SHAMAN' then
			self:RegisterEvent('ACTIVE_TALENT_GROUP_CHANGED')
			self:RegisterEvent('PLAYER_LEVEL_UP')

			return true
		end
	end

	local function Enable(self)
		--Force an initial check for Fulmination
		OnEvent(self, 'ACTIVE_TALENT_GROUP_CHANGED')

		self:RegisterEvent('UNIT_AURA')
		self:SetScript('OnEvent', OnEvent)
	end

	local function Disable(self)
		self:UnregisterEvent('UNIT_AURA')
	end

	CB:RegisterModule('Fulmination', Trigger, Enable, Disable, 'stacks', 6, Colors)
end

-- Totem Timers -----------------------------
---------------------------------------------
do
	local GetTotemInfo, SetValue, GetTime = GetTotemInfo, SetValue, GetTime

	local Colors = {
		[1] = {0.8, 0.3, 0.0},
		[2] = {1.0, 0.8, 0.0},		
		[3] = {0.0, 0.4, 0.8},
		[4] = {0.6, 1.0, 1.0},
	}

	local function UpdateTimer(self, elapsed)
		self.lastUpdate = self.lastUpdate + elapsed
		if self.lastUpdate > 0.01 then
			local haveTotem, name, startTime, duration, totemIcon = GetTotemInfo(self.ID)
			local activeTime = GetTime() - startTime
			local timeLeft = startTime + duration - GetTime()

			if timeLeft > 0 then
				self.Text:SetText(st.StringFormat:ToTime(timeLeft))
				self.StatusBar:SetValue(1 - (activeTime / duration))
			else
				self.Text:SetText('')
				self.StatusBar:SetValue(0)
			end

			self.lastUpdate = 0
		end
	end

	local function UpdateSlot(self, slot)
		local haveTotem, name, startTime, duration, totemIcon = GetTotemInfo(slot)
		if haveTotem and duration >= 0 then
			self[slot].lastUpdate = 0
			UpdateTimer(self[slot], 1)
			self[slot]:SetScript('OnUpdate', UpdateTimer)
		else
			self[slot]:SetScript('OnUpdate', nil)
			self[slot].Text:SetText('')
			self[slot].StatusBar:SetValue(0)
		end
	end

	local function Trigger(self)
		return st.MY_CLASS == 'SHAMAN'
	end

	local function Enable(self)
		self:RegisterEvent('PLAYER_TOTEM_UPDATE')
		for i=1,4 do UpdateSlot(self, i) end
		self:SetScript('OnEvent', function(self, event, slot) UpdateSlot(self, slot) end)
	end

	local function Disable(self)
		self:UnregisterAllEvents()
		self:SetScript('OnEvent', nil)
	end

	CB:RegisterModule('TotemTimers', Trigger, Enable, Disable, 'bars', 4, Colors)
end

-- Chi --------------------------------------
---------------------------------------------
do
	local Color = {1.0, 0.8, 0.4}

	local function Update(self, event, unit, powerType)
		if (unit == 'player' and powerType and powerType == 'CHI') then
			local maxStacks = UnitPowerMax('player', SPELL_POWER_CHI)

			if maxStacks ~= self.ShownUnits then
				self:SetMaxUnits(maxStacks)
			end
			
			self:SetActiveStacks(UnitPower('player', SPELL_POWER_CHI))
		end
	end

	local function Trigger(self)
		return st.MY_CLASS == 'MONK'
	end

	local function Enable(self)
		self:RegisterEvent('UNIT_POWER')
		self:SetScript('OnEvent', Update)
		Update(self, 'UNIT_POWER', 'player', 'CHI')
	end

	local function Disable(self)
		self:UnregisterEvent('UNIT_POWER')
		self:SetScript('OnEvent', nil)
	end

	CB:RegisterModule('Chi', Trigger, Enable, Disable, 'stacks', 3, Color)
end

-- Eclipse Bar ------------------------------
---------------------------------------------

--CAST WRATH(NATURE) ON MOON, AND STARFALL(ARCANE) ON SUN
do
	local Colors = {
		[1] = {1.0, 0.8, 0.4},
		[2] = {0.4, 0.6, 0.8}
	}
	local fadeMult = 0.3

	local ECLIPSE_BAR_SOLAR_BUFF_ID = ECLIPSE_BAR_SOLAR_BUFF_ID
	local ECLIPSE_BAR_LUNAR_BUFF_ID = ECLIPSE_BAR_LUNAR_BUFF_ID
	local SPELL_POWER_ECLIPSE = SPELL_POWER_ECLIPSE
	local MOONKIN_FORM = MOONKIN_FORM

	local function UpdateVisibility(self)
		if GetShapeshiftFormID() == MOONKIN_FORM then
			self:Enable()
		else
			self:Disable()
		end
	end

	local function OnEvent(self, event, unit, powerType)
		if event == 'PLAYER_TALENT_UPDATE' or event == 'UPDATE_SHAPESHIFT_FORM' then
			UpdateVisibility(self)
		end

		if event == 'UNIT_POWER' and not (unit == 'player' and powerType == 'ECLIPSE') then return end
		
		local min = UnitPower('player', SPELL_POWER_ECLIPSE)+100
		local max = UnitPowerMax('player', SPELL_POWER_ECLIPSE)+100
		self[1].StatusBar:SetValue(min/max)

		local direction = GetEclipseDirection()
		local text = min

		self[1].StatusBar.Lunar:SetAlpha(1)
		self[1].StatusBar:GetStatusBarTexture():SetAlpha(1)

		if direction == 'moon' then
			-- self[1].StatusBar.Lunar:SetAlpha(fadeMult)
			text = '<' .. text
		elseif direction == 'sun' then
			-- self[1].StatusBar:GetStatusBarTexture():SetAlpha(fadeMult)
			text = text .. '>'
		end
		self[1].Text:SetText(text)
	end

	local function Trigger(self)
		if st.MY_CLASS == 'DRUID' then
			self:RegisterEvent('PLAYER_TALENT_UPDATE')
			return true
		end
	end

	local function Enable(self)
		self:RegisterEvent('ECLIPSE_DIRECTION_CHANGE') --ECLIPSE_DIRECTION_CHANGE
		self:RegisterEvent('UNIT_AURA') --UNIT_AURA
		self:RegisterEvent('UNIT_POWER') --UNIT_POWER
		self:RegisterEvent('PLAYER_TALENT_UPDATE') --UpdateVisibility
		self:RegisterEvent('UPDATE_SHAPESHIFT_FORM') --UpdateVisibility

		if not self[1].StatusBar.Lunar then
			local lunar = self[1].StatusBar:CreateTexture(nil, 'OVERLAY')
			lunar:SetPoint('TOPLEFT', self[1].StatusBar:GetStatusBarTexture(), 'TOPRIGHT')
			lunar:SetPoint('BOTTOMRIGHT', self[1].StatusBar, 'BOTTOMRIGHT')
			lunar:SetTexture(st.BLANK_TEX)
			lunar:SetVertexColor(unpack(Colors[2]))
			self[1].StatusBar.Lunar = lunar
		end

		OnEvent(self, 'PLAYER_TALENT_UPDATE')
		self:SetScript('OnEvent', OnEvent)		
	end

	local function Disable(self)
		self:RegisterEvent('ECLIPSE_DIRECTION_CHANGE')
		self:RegisterEvent('UNIT_AURA')
		self:RegisterEvent('UNIT_POWER')
	end

	CB:RegisterModule('EclipseBar', Trigger, Enable, Disable, 'bars', 1, Colors)
end

-- Holy Power -------------------------------
---------------------------------------------
do
	local Color = {1.0, 0.8, 0.4}

	local function Update(self, event, unit, powerType)
		if (unit == 'player' and powerType and powerType == 'HOLY_POWER') then
			local maxStacks = UnitPowerMax('player', SPELL_POWER_HOLY_POWER)

			if maxStacks ~= self.ShownUnits then
				self:SetMaxUnits(maxStacks)
			end
			
			self:SetActiveStacks(UnitPower('player', SPELL_POWER_HOLY_POWER))
		end
	end

	local function Trigger(self)
		return st.MY_CLASS == 'PALADIN'
	end

	local function Enable(self)
		self:RegisterEvent('UNIT_POWER')
		self:SetScript('OnEvent', Update)
		Update(self, 'UNIT_POWER', 'player', 'HOLY_POWER')
	end

	local function Disable(self)
		self:UnregisterEvent('UNIT_POWER')
		self:SetScript('OnEvent', nil)
	end

	CB:RegisterModule('HolyPower', Trigger, Enable, Disable, 'stacks', 3, Color)
end
-- Runes ------------------------------------
---------------------------------------------
do
	local Colors = {
		[1] = {.69,.31,.31}, -- blood
		[2] = {.33,.59,.33}, -- unholy
		[3] = {.31,.45,.63}, -- frost
		[4] = {.84,.75,.65}, -- death
	}
	local fadeMult = 0.6

	local function UpdateRuneTimer(self, elapsed)
		self.lastUpdate = self.lastUpdate + elapsed
		if self.lastUpdate > 0.01 then

			local startTime, duration, runeReady = GetRuneCooldown(self.ID)
			local activeTime = GetTime() - startTime
			local timeLeft = startTime + duration - GetTime()

			if timeLeft <= 0 or runeReady then
				self.Text:SetText('')
				self.StatusBar:SetValue(1)
			else
				self.Text:SetText(st.StringFormat:ToTime(timeLeft))
				self.StatusBar:SetValue((activeTime / duration))
			end

			self.lastUpdate = 0
		end
	end

	local function UpdateRune(self, event, runeID)
		local start, duration, runeReady = GetRuneCooldown(runeID)
		local runeType = GetRuneType(runeID)
		if not runeType then return end
		
		local r,g,b = unpack(Colors[runeType])

		if event == 'RUNE_POWER_UPDATE' then
			if runeReady then
				self[runeID]:SetScript('OnUpdate', nil)
				self[runeID].Text:SetText('')
				self[runeID].StatusBar:SetValue(1)
			else
				self[runeID].lastUpdate = 0
				self[runeID]:SetScript('OnUpdate', UpdateRuneTimer)
			end
		end

		if runeReady then
			self[runeID].StatusBar:SetStatusBarColor(r,g,b)
		else
			self[runeID].StatusBar:SetStatusBarColor(r*fadeMult, g*fadeMult, b*fadeMult)
		end
	end


	local function Trigger(self)
		return st.MY_CLASS == 'DEATHKNIGHT'
	end

	local function Enable(self)
		self:RegisterEvent('RUNE_POWER_UPDATE')
		self:RegisterEvent('RUNE_TYPE_UPDATE')
		self:SetScript('OnEvent', UpdateRune)
		for i=1,6 do UpdateRune(self, nil, i) end
	end

	local function Disable(self)
		self:UnregisterAllEvents()
		self:SetScript('OnEvent', nil)
	end

	CB:RegisterModule('RuneBar', Trigger, Enable, Disable, 'bars', 6)
end


-- Shadow Orbs ------------------------------
---------------------------------------------
do
	local Color = {0.6, 0.4, 0.8}

	local function OnEvent(self, event, unit, powerType)
		if event == 'UNIT_POWER' and not (unit == 'player' and powerType == 'SHADOW_ORBS') then return end

		if event == 'PLAYER_TALENT_UPDATE' then
			if GetSpecialization() == SPEC_PRIEST_SHADOW then
				self:Enable()
			else
				return self:Disable()
			end
		end

		self:SetActiveStacks(UnitPower('player', SPELL_POWER_SHADOW_ORBS))
	end


	local function Trigger(self)
		if st.MY_CLASS == 'PRIEST' then
			self:RegisterEvent('PLAYER_TALENT_UPDATE')
			return true
		end
	end

	local function Enable(self)
		--Force an initial check for Shadow spec
		OnEvent(self, 'PLAYER_TALENT_UPDATE')

		self:SetScript('OnEvent', OnEvent)
		self:RegisterEvent('UNIT_POWER')		
	end

	local function Disable(self)
		self:UnregisterEvent('UNIT_POWER')
	end

	CB:RegisterModule('ShadowOrbs', Trigger, Enable, Disable, 'stacks', 3, Color)
end