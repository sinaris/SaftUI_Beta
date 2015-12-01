local st = SaftUI
local CHR = st:NewModule('CharacterFrame', 'AceHook-3.0', 'AceEvent-3.0')

local CHARACTER_SLOTS = {
	-- [0] = 'Ammo',
	[1] = 'Head',
	[2] = 'Neck',
	[3] = 'Shoulder',
	[4] = 'Shirt',
	[5] = 'Chest',
	[6] = 'Waist',
	[7] = 'Legs',
	[8] = 'Feet',
	[9] = 'Wrist',
	[10] = 'Hands',
	[11] = 'Finger0',
	[12] = 'Finger1',
	[13] = 'Trinket0',
	[14] = 'Trinket1',
	[15] = 'Back',
	[16] = 'MainHand',
	[17] = 'SecondaryHand',
	-- [18] = 'Ranged',
	[19] = 'Tabard',
}

------------------------------
-- Equiped Item Slots --------
------------------------------

function CHR:InitializeEquipSlots()
	self.EquipmentSlots = CreateFrame('frame', nil, self.Window)
	self.EquipmentSlots:SetTemplate('Transparent')
	self.EquipmentSlots:SetBackdropColor(unpack(st.Saved.profile.Colors.buttonnormal))
	self.EquipmentSlots:SetPoint('TOPLEFT', self.Window.TitleRegion, 'BOTTOMLEFT', st.UI_PANEL_PADDING, -st.UI_PANEL_PADDING)
	self.EquipmentSlots:SetSize(61, 200)

	self.EquipmentSlots.Slots = {}

	self.EquipmentSlots.flyoutSettings = {
		onClickFunc = PaperDollFrameItemFlyoutButton_OnClick,
		getItemsFunc = PaperDollFrameItemFlyout_GetItems,
		postGetItemsFunc = PaperDollFrameItemFlyout_PostGetItems, 
		hasPopouts = true,
		parent = self.EquipmentSlots,
		anchorX = -5,
		anchorY = 0,
		verticalAnchorX = 0,
		verticalAnchorY = 0,
	};

	for ID,slotName in pairs(CHARACTER_SLOTS) do
		local equipSlot = _G[format('Character%sSlot', slotName)]
	
		equipSlot.ID = ID
		equipSlot.slotName = slotName

		equipSlot:SetTemplate('Button')
		equipSlot:SetParent(self.EquipmentSlots)

		-- _G['Character'..slotName..'SlotPopoutButton']:Kill()
		_G['Character'..slotName..'SlotIconTexture']:SetPoints(st.BORDER_INSET)
		_G['Character'..slotName..'SlotIconTexture']:SetDrawLayer('OVERLAY')
		_G['Character'..slotName..'SlotIconTexture']:SetTexCoord(unpack(SaftUI.ICON_COORDS))

		equipSlot.itemLevel = equipSlot:CreateFontString(nil, 'OVERLAY')
		equipSlot.itemLevel:SetFontObject(st.pixelFont)
		equipSlot.itemLevel:SetPoint('BOTTOMRIGHT', 0, 3)

		equipSlot.slotName = slotName
		equipSlot.slotID = slotID
		equipSlot.verticalFlyout = false

		tinsert(self.EquipmentSlots.Slots, equipSlot)
	end

	CharacterHeadSlot:ClearAllPoints()
	CharacterHeadSlot:SetPoint('TOPLEFT', self.EquipmentSlots, 'TOPLEFT', 0, 0)
	
	CharacterHandsSlot:ClearAllPoints()
	CharacterHandsSlot:SetPoint('TOPLEFT', CharacterHeadSlot, 'TOPRIGHT', 4, 0)

	CharacterMainHandSlot:ClearAllPoints()
	CharacterMainHandSlot:SetPoint('TOPRIGHT', CharacterWristSlot, 'BOTTOMRIGHT', 0, -4)

	CharacterSecondaryHandSlot:ClearAllPoints()
	CharacterSecondaryHandSlot:SetPoint('TOPLEFT', CharacterMainHandSlot, 'TOPRIGHT', 4, 0)

	self:SecureHook('PaperDollItemSlotButton_Update', 'UpdateEquipSlot')
end

function CHR:UpdateEquipSlot(equipSlot)
	local itemID = GetInventoryItemID('player', equipSlot:GetID())
	
	if not itemID then
		equipSlot:SetBackdropBorderColor(0, 0, 0)
		equipSlot.itemLevel:SetText('')
	else
		local _, _, quality, iLevel = GetItemInfo(itemID)

		if quality then 
			local r, g, b, hex = GetItemQualityColor(quality)
			equipSlot:SetBackdropBorderColor(r,g,b)
		else
			equipSlot:SetBackdropBorderColor(0, 0, 0)
		end

		if equipSlot.itemLevel then --container slots also use PaperDollItemSlotButton_Update, but don't have itemLevel text
			equipSlot.itemLevel:SetText(iLevel)
		end
	end	
end

------------------------------
-- Right Pane ----------------
------------------------------

function CHR:InitializeRightPane()
	local tabFrame = CreateFrame('frame', nil, self.Window)
	tabFrame:SetTemplate()
	tabFrame:SetPoint('TOPLEFT', CharacterHandsSlot, 'TOPRIGHT', st.UI_PANEL_PADDING, 0)
	tabFrame:SetPoint('RIGHT', self.Window, 'RIGHT', -st.UI_PANEL_PADDING, 0)
	tabFrame:SetHeight(st.TAB_HEIGHT)
	local width = floor(tabFrame:GetRight() - tabFrame:GetLeft()+0.5)
	tabFrame:SetWidth(width)

	tabFrame.Tabs = {}
	local prev
	for i=1,3 do
		local tab = CreateFrame('Button', nil, tabFrame)
		tab:SetTemplate('Button')
		tab:SetHeight(tabFrame:GetHeight()-2)
		tab:SetWidth((width-2)/3)
		if prev then
			tab:SetPoint('LEFT', prev, 'RIGHT', 1, 0)
		else
			tab:SetPoint('LEFT', tabFrame, 0, 0)
		end
		tab:SetText(({'Stats', 'Titles', 'Gear Sets'})[i])
		prev = tab
	end

	rightPane = CreateFrame('frame', nil, self.Window)
	rightPane:SetTemplate()
	rightPane:SetPoint('TOPRIGHT', tabFrame, 'BOTTOMRIGHT', 0, -4)
	rightPane:SetPoint('BOTTOMLEFT', CharacterSecondaryHandSlot, 'BOTTOMRIGHT', st.UI_PANEL_PADDING, 0)
	

	tabFrame:SetParent(rightPane)
	rightPane.TabFrame = tabFrame

	self.RightPane = rightPane
end

------------------------------
-- Stats Pane ----------------
------------------------------

function ColorizeStat(stat, offset)
	if ( offset < 0 ) then
		return RED_FONT_COLOR_CODE..stat..FONT_COLOR_CODE_CLOSE;
	elseif offset > 0 then
		return GREEN_FONT_COLOR_CODE..stat..FONT_COLOR_CODE_CLOSE;
	else
		return stat
	end
end

RIGHT_PANE_NUM_ROWS = 18
RIGHT_PANE_ROW_HEIGHT = 18

function GetPlayerHealth()
	return {
		label = HEALTH,
		stat  = BreakUpLargeNumbers(UnitHealthMax('player') or 0),
	}
end

function GetPlayerPower()
	local powerType, powerToken = UnitPowerType('player')
	if (powerToken and _G[powerToken]) then
		return {
			label = _G[powerToken],
			stat  = BreakUpLargeNumbers(UnitPowerMax('player') or 0),
		}
	end
end

function GetPlayerAlternatePower()
	if (st.MY_CLASS == 'DRUID') or (st.MY_CLASS == 'MONK' and GetSpecialization() ~= SPEC_MONK_MISTWEAVER) then
		local powerType, powerToken = UnitPowerType('player')
		if powerToken ~= 'MANA' then
			return {
				label = MANA,
				stat  = BreakUpLargeNumbers(UnitPowerMax('player', 0) or 0),
			}
		end
	end
end

function GetPlayerItemLevel()
	return {
		label = STAT_AVERAGE_ITEM_LEVEL,
		stat  = format('%.f (%.f)', GetAverageItemLevel()),
	}
end

function GetPlayerMoveSpeed()
	local _, runSpeed, flightSpeed, swimSpeed = GetUnitSpeed('player');
	runSpeed = runSpeed/BASE_MOVEMENT_SPEED*100;
	flightSpeed = flightSpeed/BASE_MOVEMENT_SPEED*100;
	swimSpeed = swimSpeed/BASE_MOVEMENT_SPEED*100;

	return {
		label = STAT_MOVEMENT_SPEED,
		stat  = format('%d%%', runSpeed + 0.5)
	}

end

function GetPlayerStat(statID)
	local base, stat, posBuff, negBuff = UnitStat('player', statID);
	local statString = BreakUpLargeNumbers(stat);

	return {
		label = _G['SPELL_STAT'..statID..'_NAME'],
		stat  = ColorizeStat(statString, posBuff+negBuff),
	}
end

function GetPlayerStrength() return GetPlayerStat(LE_UNIT_STAT_STRENGTH) end
function GetPlayerAgility() return GetPlayerStat(LE_UNIT_STAT_AGILITY) end
function GetPlayerIntellect() return GetPlayerStat(LE_UNIT_STAT_INTELLECT) end
function GetPlayerStamina() return GetPlayerStat(LE_UNIT_STAT_STAMINA) end
function GetPlayerSpirit() return GetPlayerStat(LE_UNIT_STAT_SPIRIT) end

function GetPlayerCrit()

	local rangedCrit = GetRangedCritChance()
	local meleeCrit = GetCritChance()
	local spellCrit = GetSpellCritChance(SCHOOL_MASK_HOLY)
	for i=SCHOOL_MASK_HOLY+1, MAX_SPELL_SCHOOLS do
		spellCrit = min(spellCrit, GetSpellCritChance(i))
	end

	local critChance = max(spellCrit, meleeCrit, rangedCrit)

	return {
		label = STAT_CRITICAL_STRIKE,
		stat  = format('%.2f%%', critChance),
	}
end

function GetPlayerHaste()
	local haste = GetHaste()
	if (haste < 0) then
		haste = RED_FONT_COLOR_CODE..format('-%.2F%%', haste)..FONT_COLOR_CODE_CLOSE;
	else
		haste = format('%.2f%%', haste);
	end

	return {
		label = STAT_HASTE,
		stat  = haste,
	}
end

function GetPlayerMastery()
	if UnitLevel('player') < SHOW_MASTERY_LEVEL then return end

	return {
		label = STAT_MASTERY,
		stat  = format('%.2f%%', GetMasteryEffect()),
	}
end


function GetPlayerBonusArmor()

	return {
		label = BONUS_ARMOR,
		stat  = UnitBonusArmor('player'),
	}
end

function GetPlayerMultistrike()

	return {
		label = STAT_MULTISTRIKE,
		stat  = format('%.2f%%',GetMultistrike()),
	}
end

function GetPlayerLifesteal()
	return {
		label = STAT_LIFESTEAL,
		stat  = format('%.2f%%', GetLifesteal()),
	}
end

function GetPlayerVersatility()
	local versatility = GetCombatRating(CR_VERSATILITY_DAMAGE_DONE)
	local versatilityDamageBonus = 
		GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE) +
		GetVersatilityBonus(CR_VERSATILITY_DAMAGE_DONE)
	local versatilityDamageTakenReduction =
		GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_TAKEN) +
		GetVersatilityBonus(CR_VERSATILITY_DAMAGE_TAKEN)

	return {
		label = STAT_VERSATILITY,
		stat  = format('%.2f%%', versatilityDamageBonus),
	}
end

function GetPlayerAvoidance()
	return {
		label = STAT_AVOIDANCE,
		stat  = format('%.2f%%', GetAvoidance()),
	}
end

function GetPlayerAttackDamage()
	local minDamage, maxDamage, minOffHandDamage, maxOffHandDamage, physicalBonusPos, physicalBonusNeg, percent = UnitDamage('player')
	local minDamageString = max(floor(minDamage),1);
	local maxdamageString = max(ceil(maxDamage),1);
	local damageString = BreakUpLargeNumbers(max(1,floor(minDamage))).." - "..BreakUpLargeNumbers(max(1,ceil(maxDamage)))



	minDamage = (minDamage / percent) - physicalBonusPos - physicalBonusNeg;
	maxDamage = (maxDamage / percent) - physicalBonusPos - physicalBonusNeg;
	local baseDamage = (minDamage + maxDamage) * 0.5;
	local fullDamage = (baseDamage + physicalBonusPos + physicalBonusNeg) * percent;
	local totalBonus = (fullDamage - baseDamage);
	
	if ( totalBonus < 0.1 and totalBonus > -0.1 ) then
		totalBonus = 0.0;
	end

	return {
		label = DAMAGE,
		stat  = ColorizeStat(damageString, totalBonus),
	}
end

function GetPlayerAttackPower()
	local base, posBuff, negBuff
	if IsRangedWeapon() then
		base, posBuff, negBuff = UnitRangedAttackPower('player')
	else
		base, posBuff, negBuff = UnitAttackPower('player')
	end

	local spellPower
	if (GetOverrideAPBySpellPower() ~= nil) then
		spellPower = GetSpellBonusDamage(SCHOOL_MASK_HOLY);		
		for i=(SCHOOL_MASK_HOLY+1), MAX_SPELL_SCHOOLS do
			spellPower = min(spellPower, GetSpellBonusDamage(i));
		end
		spellPower = min(spellPower, GetSpellBonusHealing()) * GetOverrideAPBySpellPower();
	end

	return {
		label = STAT_ATTACK_POWER,
		stat  = spellPower or ColorizeStat(base, negBuff+posBuff),
	}
end

function GetPlayerAttackSpeed()
	local meleeHaste = GetMeleeHaste()
	local speed, offhandSpeed = UnitAttackSpeed('player');

	local text;	
	if ( offhandSpeed ) then
		text =  BreakUpLargeNumbers(speed).." / ".. format('%.2f', offhandSpeed);
	else
		text =  BreakUpLargeNumbers(speed);
	end

	return {
		label = WEAPON_SPEED,
		stat  = text,
	}
end

function GetPlayerEnergyRegen()
	if select(2, UnitPowerType('player')) ~= 'ENERGY' then return end

	return {
		label = STAT_ENERGY_REGEN,
		stat  = BreakUpLargeNumbers(GetPowerRegen()),
	}
end

function GetPlayerRuneRegen()
	if st.MY_CLASS ~= 'DEATHKNIGHT' then return end

	return {
		label = STAT_RUNE_REGEN,
		stat  = format(STAT_RUNE_REGEN_FORMAT, select(2, GetRuneCooldown(1))),
	}
end

function GetPlayerFocusRegen()
	if select(2, UnitPowerType('player')) ~= 'FOCUS' then return end

	return {
		label = STAT_FOCUS_REGEN,
		stat  = BreakUpLargeNumbers(GetPowerRegen()),
	}
end

function GetPlayerSpellpower()
	local minModifier = GetSpellBonusDamage(SCHOOL_MASK_HOLY)
	for i=(SCHOOL_MASK_HOLY+1), MAX_SPELL_SCHOOLS do
		minModifier = min(minModifier, GetSpellBonusDamage(i))
	end

	return {
		label = STAT_SPELLPOWER,
		stat  = minModifier,
	}
end

function GetPlayerManaRegen()
	if not UnitHasMana('player') then return end

	local base, combat = GetManaRegen();
	base = BreakUpLargeNumbers(floor( base * 5.0 ));
	combat = BreakUpLargeNumbers(floor( combat * 5.0 ));
	return {
		label = MANA_REGEN,
		stat  = combat,
	}
end

function GetPlayerArmor()
	-- local baselineArmor, effectiveArmor, armor, posBuff, negBuff = UnitArmor('player');
	return {
		label = ARMOR,
		stat  = select(2, UnitArmor('player')),
	}
end


function GetPlayerDodge()
	return {
		label = STAT_DODGE,
		stat  = format('%.2f%%', GetDodgeChance()),
	}
end

function GetPlayerParry()
	return {
		label = STAT_PARRY,
		stat  = format('%.2f%%', GetParryChance()),
	}
end

function GetPlayerBlock()
	return {
		label = STAT_BLOCK,
		stat  = format('%.2f%%', GetBlockChance()),
	}
end

-- Modified paperdoll stat info that uses return functions instead of direct modifications
SAFTUI_PAPERDOLL_STATINFO = {
	function() return {isHeader = true, label = STAT_CATEGORY_GENERAL} end,
		GetPlayerHealth,
		GetPlayerPower,
		GetPlayerAlternatePower,
		GetPlayerItemLevel,
		GetPlayerMoveSpeed,
	
	function() return {isHeader = true, label=STAT_CATEGORY_ATTRIBUTES} end,
		GetPlayerStamina,
		GetPlayerStrength,
		GetPlayerAgility,
		GetPlayerIntellect,
	
	function() return { isHeader = true, label=STAT_CATEGORY_ENHANCEMENTS} end,
		GetPlayerCrit,
		GetPlayerHaste,
		GetPlayerMastery,
		GetPlayerSpirit,
		GetPlayerBonusArmor,
		GetPlayerMultistrike,
		GetPlayerLifesteal,
		GetPlayerVersatility,
		GetPlayerAvoidance,

	function() return {isHeader = true, label = STAT_CATEGORY_ATTACK} end,
		GetPlayerAttackDamage,
		GetPlayerAttackPower,
		GetPlayerAttackSpeed,
		GetPlayerEnergyRegen,
		GetPlayerRuneRegen,
		GetPlayerFocusRegen,

	function() return {isHeader = true, label = STAT_CATEGORY_SPELL} end,
		GetPlayerSpellpower,
		GetPlayerManaRegen,

	function() return {isHeader = true, label = STAT_CATEGORY_DEFENSE} end,
		GetPlayerArmor,
		GetPlayerDodge,
		GetPlayerParry,
		GetPlayerBlock,
}

-- This should be updated each time the stats are being updated in order to filter out any stats that aren't being used
local SAFTUI_PAPERDOLL_STATINFO_FILTERED = {}

function CHR:InitializeStatsPane()
	statsPane = CreateFrame('frame', nil, self.RightPane)
	statsPane:SetAllPoints(self.RightPane)

	-- Scroll Frame
	local scrollFrame = CreateFrame('ScrollFrame', 'SaftUI_CharacterFrame_StatsPaneFauxScrollFrame', statsPane, 'FauxScrollFrameTemplate')

	scrollFrame:SetAllPoints(statsPane)
	scrollFrame:EnableMouse(true)
	scrollFrame:EnableMouseWheel(true)
	scrollFrame:SetScript('OnVerticalScroll', function(self, offset)
		-- FauxScrollFrame_OnVerticalScroll(self, offset, RIGHT_PANE_ROW_HEIGHT, CHR.UpdateStatsPane )

		self.offset = math.floor(offset / RIGHT_PANE_ROW_HEIGHT + 0.5)
		self.ScrollBar:SetValue(offset)
		CHR:UpdateStatsPane()
	end)
	statsPane:SetScript('OnShow', function(self)
		self.ScrollFrame:SetVerticalScroll(0)
		self.ScrollFrame.offset = 0
		self.ScrollFrame.ScrollBar:SetValue(0)
		CHR:UpdateStatsPane()		
	end)
	scrollFrame.ScrollBar = SaftUI_CharacterFrame_StatsPaneFauxScrollFrameScrollBar
	scrollFrame.ScrollBar:Skin(true)
	
	statsPane.ScrollFrame = scrollFrame

	-- Row Frames
	statsPane.Rows = {}
	local prev
	for i=1,RIGHT_PANE_NUM_ROWS do
		local row = CreateFrame('frame', nil, statsPane)
		row:SetHeight(RIGHT_PANE_ROW_HEIGHT)
		row:SetPoint('RIGHT', statsPane.ScrollFrame.ScrollBar, 'LEFT')
		row:SetTemplate('Transparent')

		row.labelText = row:CreateFontString(nil, 'OVERLAY')
		row.labelText:SetFontObject(st.pixelFont)
		row.labelText:SetText('Name')
		row.labelText:SetPoint('LEFT', 5, 0)

		row.statText = row:CreateFontString(nil, 'OVERLAY')
		row.statText:SetFontObject(st.pixelFont)
		row.statText:SetText('0000')
		row.statText:SetPoint('RIGHT', -5, 0)

		if prev then
			row:SetPoint('TOPLEFT', prev, 'BOTTOMLEFT', 0, -st.BORDER_INSET)
		else
			row:SetPoint('TOPLEFT', statsPane, st.BORDER_INSET, -st.BORDER_INSET)
		end
		prev = row
		statsPane.Rows[i] = row
	end


	self.StatsPane = statsPane
end

function CHR:UpdateStatsPane()
	-- local statinfo = {}
	-- FauxScrollFrame_Update(self.StatsPane.ScrollFrame, #SAFTUI_PAPERDOLL_STATINFO, RIGHT_PANE_NUM_ROWS, RIGHT_PANE_ROW_HEIGHT)

	wipe(SAFTUI_PAPERDOLL_STATINFO_FILTERED)

	for i=1, #SAFTUI_PAPERDOLL_STATINFO do
		local info = SAFTUI_PAPERDOLL_STATINFO[i]()
		if info then
			tinsert(SAFTUI_PAPERDOLL_STATINFO_FILTERED, info)
		end
	end

	FauxScrollFrame_Update(self.StatsPane.ScrollFrame, #SAFTUI_PAPERDOLL_STATINFO_FILTERED, RIGHT_PANE_NUM_ROWS, RIGHT_PANE_ROW_HEIGHT)

	local row
	for i,row in pairs(self.StatsPane.Rows) do
		row = self.StatsPane.Rows[i]
		local info = SAFTUI_PAPERDOLL_STATINFO_FILTERED[i + self.StatsPane.ScrollFrame.offset]
		if info then 
			row.labelText:SetText(info.label)
			row.labelText:ClearAllPoints()
			if info.isHeader then
				row.statText:SetText('')
				row.labelText:SetPoint('CENTER')
				row:SetBackdropColor(0, 0, 0, 0)
			else
				row.statText:SetText(info.stat)
				row.labelText:SetPoint('LEFT', 5, 0)
				row:SetBackdropColor(unpack(st.Saved.profile.Colors.transparentbackdrop))
			end
		end
	end
end

------------------------------
-- Visibility functions ------
------------------------------

function CHR:Open()
	self.Window:Show()
end

function CHR:Close()
	self.Window:Hide()
end

function CHR:Toggle()
	CharacterFrame:Hide()
	if self.Window:IsShown() then
		self:Close()
	else
		self:Open()
	end
end

function CHR:OnEnable()
	local win = CreateFrame('Frame', 'SaftUI_CharacterFrame', UIParent)
	win:SetSize(PANEL_DEFAULT_WIDTH, SaftUI.UI_PANEL_HEIGHT)
	win:SetTemplate('Transparent')
	win:SetPoint('LEFT', UIParent, 'LEFT', UIPARENT_PADDING, 100)

	win.CloseButton = CreateFrame('Button', nil, win)
	self:HookScript(win.CloseButton, 'OnClick', 'Close')

	win.Title = win:CreateFontString(nil, 'OVERLAY')
	win.Title:SetFontObject(st.pixelFont)
	win.Title:SetText(UnitName('player'))

	win:CreateHeader()

	win:Hide()

	self.Window = win

	self:InitializeEquipSlots()

	self:InitializeRightPane()
	self:InitializeStatsPane()

	-- Hook into a preexisting function in order to preserve keybindings
	self:SecureHook('ToggleCharacter','Toggle') 

	-- [TEMPORARY] Kill it for now, will properly unregister events later
	UIPanelWindows.SaftUI_CharacterFrame = {area = 'left', pushable = 3, whileDead = 1}
	-- UIPanelWindows.CharacterFrame = nil
	-- CharacterFrame:Kill()
end