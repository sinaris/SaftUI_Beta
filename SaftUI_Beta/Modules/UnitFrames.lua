local st = SaftUI
local UF = st:NewModule('UnitFrames', 'AceHook-3.0', 'AceEvent-3.0')
local CF = st:GetModule('Config')
local oUF = select(2,...).oUF
assert(oUF, 'st was unable to locate oUF.')
UF.oUF = oUF

local DIFFICULTY_COLORS = {
	RED			  = { 220/255, 100/255, 100/255 },
	YELLOW		  = { 200/255, 200/255, 100/255 }, 
	GREEN	 	  = { 240/255, 240/255,  60/255 }, 
	GREY	 	  = { 100/255, 240/255,  60/255 }, 
}

---------------------------------------------
-- CUSTOM TAGS --------------------------------
---------------------------------------------
-- This tag will handle all config settings for name, level, classification, etc
oUF.Tags.Events['st:name'] = 'UNIT_NAME_UPDATE UNIT_LEVEL PLAYER_LEVEL_UP'
oUF.Tags.Methods['st:name'] = function(unit)
	local level = UnitLevel(unit)
	local playerLevel = UnitLevel('player')
	local name = UnitName(unit)
	local classification = UnitClassification(unit)
	local string = ''

	local baseunit = unit == 'vehicle' and 'player' or strmatch(unit, '%D+')
	if not st.Saved.profile.UnitFrames.units[baseunit] then return '' end
	local config = st.Saved.profile.UnitFrames.units[baseunit].name
	if not config.enable then return '' end

	-- Set level coloring based on level difference between unit and player
	local levelDiff = level - playerLevel;

	local color
	if ( levelDiff >= 3 ) then
		color = st.Saved.profile.Colors.textred
	elseif ( levelDiff >= -4 ) then
		color = st.Saved.profile.Colors.textyellow
	elseif ( -levelDiff >= GetQuestGreenRange() ) then
		color = st.Saved.profile.Colors.textgreen
	else
		color = st.Saved.profile.Colors.textgrey
	end

	local levelString = ''
	if config.showlevel then
		if level < 0 then
			levelString = '??'
		elseif not (not config.showsamelevel and level == playerLevel) then
			levelString = level
		end
	end
	
	if config.showclassification then
		if(classification == 'rare') then
			levelString = levelString .. 'R'
		elseif(classification == 'eliterare') then
			levelString = levelString .. 'R+'
		elseif(classification == 'elite') then
			levelString = levelString .. '+'
		elseif(classification == 'worldboss') then
			levelString = levelString .. 'B'
		end
	end

	return st.StringFormat:ColorString(levelString, unpack(color)) .. (strlen(levelString) > 0 and ' ' or '') .. st.StringFormat:UTF8strsub(name, config.maxlength)
end

---------------------------------------------
-- UNITFRAME CONSTRUCTOR --------------------
---------------------------------------------



function UF.ConstructUnit(self, unit)
	self:CreateBackdrop()

	--Use this as parent for text to force it to always be on top
	local textoverlay = CreateFrame('frame', nil, self)
	textoverlay:SetFrameLevel(99)
	textoverlay:SetAllPoints(self)
	self.TextOverlay = textoverlay

	local health = CreateFrame('StatusBar', nil, self)
	health:SetStatusBarTexture(st.BLANK_TEX)
	health.colorTapped = true
	-- health.colorDisconnected = true
	health.Smooth = true
	health:CreateBackdrop()
	health.Text = textoverlay:CreateFontString(nil, 'OVERLAY')
	health.Text:SetFontObject(st.pixelFont)
	health.PostUpdate = UF.PostUpdateHealth
	self.Health = health

	local power = CreateFrame('StatusBar', nil, self)
	power:SetStatusBarTexture(st.BLANK_TEX)
	power.colorClass = true
	power.colorReaction = true
	power.Smooth = true
	power:CreateBackdrop()
	power.Text = textoverlay:CreateFontString(nil, 'OVERLAY')
	power.Text:SetFontObject(st.pixelFont)
	power.PostUpdate = UF.PostUpdatePower
	self.Power = power

	local name = textoverlay:CreateFontString(nil, 'OVERLAY')
	name:SetFontObject(st.pixelFont)
	self:Tag(name, '[st:name]')
	self.Name = name

	local castbar = CreateFrame('StatusBar', nil, self)
	castbar:SetStatusBarTexture(st.BLANK_TEX)
	castbar:CreateBackdrop()
	castbar.Text = castbar:CreateFontString(nil, 'OVERLAY')
	castbar.Text:SetFontObject(st.pixelFont)
	castbar.Time = castbar:CreateFontString(nil, 'OVERLAY')
	castbar.Time:SetFontObject(st.pixelFont)

	 self.Castbar = castbar

	local baseunit = self:GetParent():GetAttribute('baseunit')
	if baseunit then
		self.IsGroupUnit = true
		self.BaseUnit = baseunit
	else
		self.BaseUnit = strmatch(unit, '(%D+)')
	end

	self.ID = tonumber(strmatch(unit, '(%d+)'))

	CF:AddConfigFrame({
		key = self.BaseUnit,
		label = self.BaseUnit,
		parent = self,
		group = 'Unitframes',
		get = function(key, subkey) return subkey and st.Saved.profile.UnitFrames.units[self.BaseUnit][key][subkey] or st.Saved.profile.UnitFrames.units[self.BaseUnit][key]  end,
		set = function(key, subkey, value)
			if subkey then
				st.Saved.profile.UnitFrames.units[self.BaseUnit][key][subkey] = value;
			else
				st.Saved.profile.UnitFrames.units[self.BaseUnit][key] = value
			end
			UF:UpdateUnit(unit)
		end,
		args = {
			CF:GetOptionTemplate('enable'),
			CF:GetOptionTemplate('width'),
			CF:GetOptionTemplate('height'),
			{
				key = 'position[4]',
				type = 'input',
				label = 'X-Offset',
				width = 0.2,
			},
			{
				key = 'position[5]',
				type = 'input',
				label = 'Y-Offset',
				width = 0.2,
			},
			{
				newRow = true,
				key = 'position[1]',
				type = 'dropdown',
				label = 'Point',
				width = 0.3,
				choices = POINT_DROPDOWN_CHOICES,
			},
			{
				key = 'position[2]',
				type = 'input',
				label = 'Parent',
				width = 0.4,
			},
			{
				key = 'position[3]',
				type = 'dropdown',
				label = 'Anchor',
				width = 0.3,
				choices = POINT_DROPDOWN_CHOICES,
			},
			{
				type = 'group',
				label = 'Power',
				get = function(key, subkey) return subkey and st.Saved.profile.UnitFrames.units[self.BaseUnit].power[key][subkey] or st.Saved.profile.UnitFrames.units[self.BaseUnit].power[key] end,
				set = function(key, subkey, value) 
					if subkey then
						st.Saved.profile.UnitFrames.units[self.BaseUnit].power[key][subkey] = value;
					else
						st.Saved.profile.UnitFrames.units[self.BaseUnit].power[key] = value
					end
					UF:UpdatePowerDisplay(unit) end,
				args = {
					CF:GetOptionTemplate('enable'),
					CF:GetOptionTemplate('width'),
					CF:GetOptionTemplate('height'),
					{
						newRow = true,
						key = 'position[1]',
						type = 'dropdown',
						label = 'Point',
						width = 0.3,
						choices = POINT_DROPDOWN_CHOICES,
					},
					{
						key = 'position[2]',
						type = 'input',
						label = 'X-Offset',
						width = 0.2,
					},
					{
						key = 'position[3]',
						type = 'input',
						label = 'Y-Offset',
						width = 0.2,
					},
				},
			},
			{
				type = 'group',
				label = 'Health',
				get = function(key, subkey) return st.Saved.profile.UnitFrames.units[self.BaseUnit].health[key] end,
				set = function(key, subkey, value) st.Saved.profile.UnitFrames.units[self.BaseUnit].health[key] = value; print(unit) UF:UpdateHealthDisplay(unit) end,
				args = {
					CF:GetOptionTemplate('enable'),
					CF:GetOptionTemplate('width'),
					CF:GetOptionTemplate('height'),
				},
			},
		}
	})


	UF.Units[unit] = self
	UF:UpdateUnit(unit)
end
---------------------------------------------
-- UNITFRAME DISPLAY UPDATE FUNCTIONS -------
---------------------------------------------

function UF:GetUnitFrame(unit)
	local unitframe = self.Units[unit]
	assert(unitframe, 'Unitframe for '..unit..' does not exist.')

	local unitconfig = st.Saved.profile.UnitFrames.units[unitframe.BaseUnit]
	assert(unitconfig, 'Config for '..unit..' does not exist.')

	return unitframe, unitconfig
end

function UF:UpdateUnit(unit)
	local unitframe, config = UF:GetUnitFrame(unit)
	self:UpdateUnitSizeAndPosition(unitframe, config)
	self:UpdateHealthDisplay(unitframe, config)
	self:UpdatePowerDisplay(unitframe, config)
	self:UpdateNameDisplay(unitframe, config)
	self:UpdateCastbarDisplay(unitframe, config)
end

function UF:UpdateUnitSizeAndPosition(unitframe, config)
	if InCombatLockdown() then return end
	
	-- If a unit's name is passed instead, reassign the proper parameter values
	if type(unitframe) == 'string' then
		unitframe,config = self:GetUnitFrame(unitframe)
	end

	if not unitframe.IsGroupUnit then
		unitframe:ClearAllPoints()

		if unitframe.ID and unitframe.ID > 1 then
			local prev = self.Units[unitframe.BaseUnit .. (unitframe.ID-1)]

			unitframe:SetPoint('BOTTOM', prev, 'TOP', 0, 10)
		else
			unitframe:SetPoint(unpack(config.position))
		end

	end
	unitframe:SetSize(config.width, config.height)
	unitframe:SetFrameLevel(config.framelevel)

	if config.backdrop.enable then
		unitframe.Backdrop:Show()
		unitframe.Backdrop:SetTemplate(config.backdrop.template)
		unitframe.Backdrop:SetPoints(unpack(config.backdrop.insets))
		unitframe:SetFrameLevel(max(config.framelevel-1, 0))
	else
		unitframe.Backdrop:Hide()
	end
end

function UF:UpdateHealthDisplay(unitframe, config)
	-- If a unit's name is passed instead, reassign the proper parameter values
	if type(unitframe) == 'string' then
		unitframe,config = self:GetUnitFrame(unitframe)
	end

	if not config.health.enable then health:Hide() return end
	local health = unitframe.Health

	health:Show()
	health:ClearAllPoints()
	health:SetPoint(unpack(config.health.position))
	health:SetFrameLevel(config.health.framelevel)

	health.hideFull = config.health.text.hidefull

	-- If a positive value is given for width or height, health will be set to that value
	-- If 0 is given, health will be set to unitframe's value
	-- if a negative value is given, that amount will be removed from the unitframe's width
	health:SetWidth((config.health.width > 0 and config.health.width) or (config.health.width < 0 and (config.width+config.health.width)) or config.width)
	health:SetHeight((config.health.height > 0 and config.health.height) or (config.health.height < 0 and (config.height+config.health.height)) or config.height)

	health.colorTapping			= config.health.colorTapping
	health.colorDisconnected	= config.health.colorDisconnected
	health.colorHealth			= config.health.colorHealth
	health.colorClass			= config.health.colorClass
	health.colorClassNPC		= config.health.colorClassNPC
	health.colorClassPet		= config.health.colorClassPet
	health.colorReaction		= config.health.colorReaction
	health.colorCustom			= config.health.colorCustom
	health.colorSmooth			= config.health.colorSmooth

	health.customColor 			= config.health.customColor

	if config.health.backdrop.enable then
		health.Backdrop:Show()
		health.Backdrop:SetTemplate(config.health.backdrop.template)
		health.Backdrop:SetPoints(unpack(config.health.backdrop.insets))
		health.Backdrop:SetFrameLevel(max(config.health.framelevel-1, 0))
	else
		health.Backdrop:Hide()
	end

	if config.health.text.enable then
		health.Text:ClearAllPoints()
		health.Text:SetPoint(unpack(config.health.text.position))
	else
		health.Text:Hide()
	end
end

function UF:UpdatePowerDisplay(unitframe, config)
	-- If a unit's name is passed instead, reassign the proper parameter values
	if type(unitframe) == 'string' then
		unitframe,config = self:GetUnitFrame(unitframe)
	end

	local power = unitframe.Power

	if config.power.text.enable then
		power.Text:ClearAllPoints()
		power.Text:SetPoint(unpack(config.power.text.position))
	else
		power.Text:Hide()
	end

	if not config.power.enable then power:Hide() return end
	
	power:Show()	
	power:ClearAllPoints()
	power:SetPoint(unpack(config.power.position))
	power:SetFrameLevel(config.power.framelevel)

	power.hideFull = config.power.text.hidefull

	power:SetWidth(config.power.width > 0 and config.power.width or config.power.width < 0 and config.width+config.power.width or config.width)
	power:SetHeight(config.power.height > 0 and config.power.height or config.power.height < 0 and config.height+config.power.height or config.height)

	power.colorTapping		= config.power.colorTapping
	power.colorDisconnected	= config.power.colorDisconnected
	power.colorPower		= config.power.colorPower
	power.colorClass		= config.power.colorClass
	power.colorClassNPC		= config.power.colorClassNPC
	power.colorClassPet		= config.power.colorClassPet
	power.colorReaction		= config.power.colorReaction
	power.colorCustom		= config.power.colorCustom
	power.colorSmooth		= config.power.colorSmooth

	power.customColor 		= config.power.customColor

	if config.power.backdrop.enable then
		power.Backdrop:Show()
		power.Backdrop:SetTemplate(config.power.backdrop.template)
		power.Backdrop:SetPoints(unpack(config.power.backdrop.insets))
		power.Backdrop:SetFrameLevel(max(config.power.framelevel-1, 0))
	else
		power.Backdrop:Hide()
	end
end

function UF:UpdateNameDisplay(unitframe, config)
	-- If a unit's name is passed instead, reassign the proper parameter values
	if type(unitframe) == 'string' then
		unitframe,config = self:GetUnitFrame(unitframe)
	end

	if not config.name.enable then unitframe.Name:Hide() return end
	local name = unitframe.Name

	name:ClearAllPoints()
	name:SetPoint(unpack(config.name.position))
	unitframe:UpdateAllElements('PLAYER_TARGET_CHANGED') --force an update to show new tagunitframe:Tag(name, format('[geniuslevel][name:%d]', config.name.maxlength))
end

function UF:UpdateCastbarDisplay(unitframe, config)
	-- If a unit's name is passed instead, reassign the proper parameter values
	if type(unitframe) == 'string' then
		unitframe,config = self:GetUnitFrame(unitframe)
	end

	if config.castbar.enable then

		-- if not unitframe:IsElementEnabled('Castbar') then unitframe:EnableElement('Castbar', unitframe.unit) end

		local castbar = unitframe.Castbar
		local point, relativePoint, xoffset, yoffset = unpack(config.castbar.position)
		castbar:ClearAllPoints()
		castbar:SetPoint(point, unitframe, relativePoint, xoffset, yoffset)	

		castbar:SetWidth(config.castbar.width > 0 and config.castbar.width or config.castbar.width < 0 and config.width+config.castbar.width or config.width)
		castbar:SetHeight(config.castbar.height > 0 and config.castbar.height or config.castbar.height < 0 and config.height+config.castbar.height or config.height)

		if config.castbar.backdrop.enable then
			castbar.Backdrop:Show()
			castbar.Backdrop:SetTemplate(config.castbar.backdrop.template)
			castbar.Backdrop:SetPoints(unpack(config.castbar.backdrop.insets))
			castbar.Backdrop:SetFrameLevel(max(config.castbar.framelevel-1, 0))
		else
			castbar.Backdrop:Hide()
		end

		if config.castbar.text.enable then
			castbar.Text:ClearAllPoints()
			castbar.Text:SetPoint(unpack(config.castbar.text.position))
		end

		if config.castbar.time.enable then
			castbar.Time:ClearAllPoints()
			castbar.Time:SetPoint(unpack(config.castbar.time.position))
		end
	elseif unitframe:IsElementEnabled('Castbar') then
		unitframe:DisableElement('Castbar')
	end
end

---------------------------------------------
-- UNITFRAME VALUE UPDATE FUNCTIONS ---------
---------------------------------------------

function UF.PostUpdateHealth(health, unit, min, max)
	
	if health.colorCustom then
		health:SetStatusBarColor(unpack(health.customColor))
	end

	if min == max and health.hideFull then
		health.Text:SetText('')
	else
		health.Text:SetFormattedText(st.StringFormat:ShortFormat(min, 1))
	end
end

function UF.PostUpdatePower(power, unit, min, max)
	if power.colorCustom then
		power:SetStatusBarColor(unpack(power.customColor))
	end

	if min == max and power.hideFull then
		power.Text:SetText('')
	elseif UnitPowerType(unit) ~= 0 then
		power.Text:SetText(min)
	else
		power.Text:SetFormattedText(st.StringFormat:ShortFormat(min, 1))
	end

	if max == 0 then max = 1 power:SetMinMaxValues(0, max) end
	if min == 0 then power:SetValue(max) end
end

---------------------------------------------
-- GROUP HEADERS ----------------------------
---------------------------------------------
function UF:CreateGroupHeaders()
	local config = st.Saved.profile.UnitFrames.units['party']
	local party = oUF:SpawnHeader('SaftUI_PartyHeader', nil, 'custom [@raid6,exists][nogroup] hide;show',
		"initial-width", config.width,
		"initial-height", config.height,
		"showParty", true,
		"showRaid", true,
		"xOffset", 3,
		"yOffset", -3,
		"point", "LEFT",
		"groupFilter", "1,2,3,4,5,6,7,8",
		"groupingOrder", "1,2,3,4,5,6,7,8",
		"groupBy", "GROUP",
		"maxColumns", 5,
		"unitsPerColumn", 1,
		"columnSpacing", 3,
		"columnAnchorPoint", "TOP",
		"baseunit", "party"
	)

	party:SetPoint(unpack(config.position))
	-- party:CreateBackdrop('Transparent')
	-- party.Backdrop:SetPoints(-5)

	local config = st.Saved.profile.UnitFrames.units['raid']
	local raid = oUF:SpawnHeader('SaftUI_RaidHeader', nil, 'custom [@raid6,exists] show;hide',
		"initial-width", config.width,
		"initial-height", config.height,
		"showParty", true,
		"showRaid", true,
		"showPlayer", true,
		"xOffset", 3,
		"yOffset", -3,
		"point", "LEFT",
		"groupFilter", "1,2,3,4,5,6,7,8",
		"groupingOrder", "1,2,3,4,5,6,7,8",
		"groupBy", "GROUP",
		"maxColumns", 5,
		"unitsPerColumn", 5,
		"columnSpacing", 3,
		"columnAnchorPoint", "TOP",
		"baseunit", "raid"
	)

	raid:SetPoint(unpack(config.position))
	-- raid:CreateBackdrop('Transparent')
	-- raid.Backdrop:SetPoints(-5)
end
---------------------------------------------
-- INITIALIZATION ---------------------------
---------------------------------------------

function UF:OnInitialize()
	oUF:RegisterStyle('st', UF.ConstructUnit)
	oUF:SetActiveStyle('st')

	self.Units = {}

	for unit,frameName in pairs({
		['player']		 = 'SaftUI_Player',
		['target']		 = 'SaftUI_Target',
		-- ['targettarget'] = 'SaftUI_TargetTarget',
		-- ['focus']		 = 'SaftUI_Focus',
		-- ['focustarget']  = 'SaftUI_FocusFarget',
		-- ['pet']			 = 'SaftUI_Pet',
		-- ['pettarget']	 = 'SaftUI_PetTarget',
	}) do self.Units[unit] = oUF:Spawn(unit, frameName) end

	self:CreateGroupHeaders()

	--Spawn arena frames
	-- for i = 1, 5 do
	-- 	local unit = format('arena%d', i)
	-- 	self.Units[unit] = oUF:Spawn(unit, format('SaftUI_Arena%d',i))
	-- end

	--Spawn boss frames
	for i = 1, 5 do
		local unit = format('boss%d', i)
		self.Units[unit] = oUF:Spawn(unit, format('SaftUI_Boss%d',i))
	end

	-- oUF:RegisterUnitEvent('UNIT_HEALTH','boss1','boss2','boss3','boss4','boss5')
	-- oUF:RegisterUnitEvent('UNIT_POWER','boss1','boss2','boss3','boss4','boss5')
	-- oUF:RegisterUnitEvent('UNIT_NAME_UPDATE','boss1','boss2','boss3','boss4','boss5')
end
