local st = SaftUI
local AB = st:NewModule('ActionBars', 'AceHook-3.0', 'AceEvent-3.0')
local LAB = LibStub('LibActionButton-1.0')

---------------------------------------------
-- CONSTANTS --------------------------------
---------------------------------------------

--Settings specific to each bar, do not touch this table
local BAR_SETTINGS = {
	[1] = { bind = "ACTIONBUTTON", 			page = 1, visibility = '[petbattle] hide; show' },
	[2] = { bind = "MULTIACTIONBAR1BUTTON", page = 6, visibility = '[vehicleui] hide; [overridebar] hide; [petbattle] hide; show' },
	[3] = { bind = "MULTIACTIONBAR2BUTTON", page = 5, visibility = '[vehicleui] hide; [overridebar] hide; [petbattle] hide; show' },
	[4] = { bind = "MULTIACTIONBAR4BUTTON", page = 4, visibility = '[vehicleui] hide; [overridebar] hide; [petbattle] hide; show' },
	[5] = { bind = "MULTIACTIONBAR3BUTTON", page = 3, visibility = '[vehicleui] hide; [overridebar] hide; [petbattle] hide; show' }
}

--Page settings, don't touch this either
local BAR_PAGES = {
	['DEFAULT']	 = format("[vehicleui] %d; [possessbar] %d; [overridebar] %d; [bar:2] 2; [bar:3] 3; [bar:4] 4; [bar:5] 5; [bar:6] 6;", GetVehicleBarIndex(), GetVehicleBarIndex(), GetOverrideBarIndex()),
	['DRUID']	 = "[bonusbar:1,nostealth] 7; [bonusbar:1,stealth] 8; [bonusbar:2] 8; [bonusbar:3] 9; [bonusbar:4] 10;",
	-- ['WARRIOR']	 = "[stance:1] 7; [stance:2] 8; [stance:3] 9;",
	['PRIEST']	 = "[bonusbar:1] 7;",
	['ROGUE']	 = "[bonusbar:1] 7; [stance:3] 10;",
	['MONK']	 = "[bonusbar:1] 7; [bonusbar:2] 8; [bonusbar:3] 9;",
	['WARLOCK']	 = "[stance:1] 10;",
}

-- http://www.wowace.com/addons/libactionbutton-1-0/pages/button-configuration/
local BUTTON_CONFIG = {
	outOfRangeColoring = "button",
	tooltip = "enabled",
	showGrid = true,
	colors = {
		range = { 0.8, 0.1, 0.1 },
		hp 	  = { 0.3, 0.8, 0.3 },
		mana  = { 0.5, 0.5, 1.0 }
	},
	hideElements = {
		macro = true,
		hotkey = false,
		equipped = false,
	},
	keyBoundTarget = false,
	clickOnDown = false,
	flyoutDirection = "UP",
}

AB.Hotkeys = {
	['SHIFT%-']			= 'S',
	['CTRL%-']			= 'C',
	['ALT%-']			= 'A',
	['MOUSEBUTTON']		= 'M',
	['BUTTON']			= 'M',
	['MIDDLEMOUSE']		= 'M3',
	['MOUSEWHEELUP']	= 'MU',
	['MOUSEWHEELDOWN']	= 'MD',
	['NUMPAD']			= 'N',
	['PAGEUP']			= 'PU',
	['PAGEDOWN']		= 'PD',
	['SPACEBAR']		= 'SpB',
	['INSERT']			= 'Ins',
	['HOME']			= 'Hm',
	['DELETE']			= 'Del',
	['NMULTIPLY']		= "*",
	['NMINUS']			= "N-",
	['NPLUS']			= "N+",
}

---------------------------------------------
-- DISABLE BLIZZARD BARS --------------------
---------------------------------------------

function AB:DisableBlizzardActionBars()
	MultiBarBottomLeft:SetParent(st.HiddenFrame)
	MultiBarBottomRight:SetParent(st.HiddenFrame)
	MultiBarLeft:SetParent(st.HiddenFrame)
	MultiBarRight:SetParent(st.HiddenFrame)

	-- Hide MultiBar Buttons, but keep the bars alive
	for _,barName in pairs({
		'ActionButton',
		'MultiBarBottomLeftButton',
		'MultiBarBottomRightButton',
		'MultiBarRightButton',
		'MultiBarLeftButton',
		'VehicleMenuBarActionButton',
		'OverrideActionBarButton',
		'MultiCastActionButton',
	}) do
		for i=1,12 do
			if  _G[barName..i] then
				_G[barName..i]:Hide()
				_G[barName..i]:UnregisterAllEvents()
				_G[barName..i]:SetAttribute("statehidden", true)
			end
		end
	end

	for _,frame in pairs({
		StanceBarFrame,
		OverrideActionBar,
		PossessBarFrame,
		MultiCastActionBarFrame,
		ReputationWatchBar,
		MainMenuExpBar,
		-- PetActionBarFrame,
		IconIntroTracker,
	}) do
		frame:UnregisterAllEvents()
		frame:Hide()
		frame:SetParent(st.HiddenFrame)
	end

	ActionBarController:UnregisterAllEvents()
	ActionBarController:RegisterEvent('UPDATE_EXTRA_ACTIONBAR')
	
	MainMenuBar:EnableMouse(false)
	MainMenuBar:SetAlpha(0)
	for i=1, MainMenuBar:GetNumChildren() do
		local child = select(i, MainMenuBar:GetChildren())
		if child then
			child:UnregisterAllEvents()
			child:Hide()
			child:SetParent(st.HiddenFrame)
		end
	end

	MainMenuExpBar:SetScript('OnShow', function(self) self:Hide() end)

	ReputationWatchBar:SetScript('OnShow', function(self) self:Hide() end)

	MainMenuBarArtFrame:UnregisterEvent("ACTIONBAR_PAGE_CHANGED")
	MainMenuBarArtFrame:UnregisterEvent("ADDON_LOADED")
	MainMenuBarArtFrame:Hide()
	MainMenuBarArtFrame:SetParent(st.HiddenFrame)

	if PlayerTalentFrame then
		PlayerTalentFrame:UnregisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
	else
		hooksecurefunc("TalentFrame_LoadUI", function() PlayerTalentFrame:UnregisterEvent("ACTIVE_TALENT_GROUP_CHANGED") end)
	end
end

---------------------------------------------
-- BUTTON FUNCTIONS -------------------------
---------------------------------------------

function AB:SkinActionButton(self)
	local name = self:GetName()

	local shine = _G[name..'Shine']
	local float = _G[name..'FloatingBG']

	-- self.cooldown:SetSwipeTexture(st.BLANK_TEX, 0, 0, 0, 1)

	if self.count then
		self.count:SetFontObject(st.pixelFont)
		self.count:ClearAllPoints()
		self.count:SetPoint('BOTTOMRIGHT', self, 'BOTTOMRIGHT', 1, 1)
	end

	if self.hotkey then
		self.hotkey:SetFontObject(st.pixelFont)
		self.hotkey:ClearAllPoints()
		self.hotkey:SetPoint('TOPRIGHT', self, 'TOPRIGHT', 1, 0)
	end
	
	if self.macro then 
		self.macro:SetFontObject(st.pixelFont)
		self.macro:ClearAllPoints()
		self.macro:SetPoint('BOTTOM', 0, 2)
	end

	if self.icon then self.icon:SetPoints(1) end

	if not self.isSkinned then
		self:SetNormalTexture('')
		if self.normalTexture then self.normalTexture:SetTexture(nil); self.normalTexture:Kill(); self.normalTexture:SetAlpha(0) end
		if self.border then self.border:Kill() end
		if self.flash then self.flash:SetTexture(nil) end
		if float then float:SetTexture(nil) end
		if shine then shine:SetAllPoints() end

		
		if self.icon then self.icon:SetTexCoord(.08,.92,.08,.92); self.icon:SetDrawLayer('BACKGROUND', 1) end

		self:SetTemplate('ActionButton')
		
		self.isSkinned = true
	end
end

-- Used to abreviate keybind strings (ex. Shift-2 to S2)
function AB.FixKeybind(self)
	local hotkey = self.hotkey
	local text = hotkey:GetText();
	
	if not text then return end
	
	for key,val in pairs(AB.Hotkeys) do
		text = gsub(text, key, val)
	end
	hotkey:SetFont(st.pixelFont:GetFont())
	hotkey:SetText(text)
end

-- Update the LAB button configuration 
function AB:UpdateButtonConfig(barID)
	if not barID then for id,bar in pairs(self.Bars) do self:UpdateButtonConfig(id) end return end

	local bar = self.Bars[barID]

	-- if InCombatLockdown() then self:RegisterEvent('PLAYER_REGEN_ENABLED'); return; end
	if not bar.buttonConfig then bar.buttonConfig = { hideElements = {}, colors = {} } end
	-- bar.buttonConfig.hideElements.macro = true
	-- bar.buttonConfig.hideElements.hotkey = true
	-- bar.buttonConfig.showGrid = true
	-- bar.buttonConfig.clickOnDown = false
	SetModifiedClick("PICKUPACTION", "Shift")
	-- bar.buttonConfig.colors.range = {1, 0, 0}
	-- bar.buttonConfig.colors.mana = {0, 0, 1}
	-- bar.buttonConfig.colors.hp = {0, 1, 0}
	
	for i, button in pairs(bar.buttons) do
		bar.buttonConfig.keyBoundTarget = BAR_SETTINGS[barID].bind .. i
		button.keyBoundTarget = bar.buttonConfig.keyBoundTarget
		button.postKeybind = AB.FixKeybind
		button:SetAttribute("buttonlock", true)
		button:SetAttribute("checkselfcast", true)
		button:SetAttribute("checkfocuscast", true)
		
		button:UpdateConfig(bar.buttonConfig)
	end
end

---------------------------------------------
-- BAR FUNCTIONS ----------------------------
---------------------------------------------

-- Bar 1 has complex bar states due to class and vehicle bars, so concatenate them here before sending them out
function AB:GetActionBarPage(barID)
	if barID == 1 then
		local conditions = BAR_PAGES['DEFAULT']
		if BAR_PAGES[st.MY_CLASS] then 
			conditions = conditions .. ' ' .. BAR_PAGES[st.MY_CLASS]
		end
		return conditions .. BAR_SETTINGS[barID]['page']
	end
	
	return BAR_SETTINGS[barID]['page']
end

function AB:CreateActionBar(barID, numButtons)
	local barname = "SaftUI_ActionBar"..barID
	local bar = CreateFrame('frame', barname, UIParent, 'SecureHandlerStateTemplate')

	bar.BarID = barID
	bar.buttons = {}
	bar.config = BAR_SETTINGS[BarID]
	bar.buttonConfig = st.tablecopy(BUTTON_CONFIG)

	bar:CreateBackdrop()

	-- Create buttons
	for i=1, (numButtons or 12) do
		local button = LAB:CreateButton(i, barname..'Button'..i, bar)

		button:SetState(0, "action", i)
		for k = 1, 14 do
			button:SetState(k, "action", (k - 1) * 12 + i)
		end

		self:SkinActionButton(button)

		button.PostUpdateHotkey = AB.FixKeybind
		bar.buttons[i] = button
	end

	bar:SetAttribute('hasTempBar', barID == 1)
	bar:SetAttribute("_onstate-page", [[ 
		self:SetAttribute("state", newstate)
		control:ChildUpdate("state", newstate)
	]])

	RegisterStateDriver(bar, 'page', self:GetActionBarPage(barID))
	RegisterStateDriver(bar, "visibility", BAR_SETTINGS[barID].visibility);

	self.Bars[barID] = bar
	self:UpdateActionBar(barID)
end

-- Update the position, display, and config of the actionbar(s)
function AB:UpdateActionBar(barID)
	if not barID then for id,bar in pairs(self.Bars) do self:UpdateActionBar(id) end return end

	local bar = self.Bars[barID]
	local conf = st.Saved.profile.ActionBars
	local bconf = conf.Bars[barID]

	--If bar is disabled, just hide it and stop there
	if not bconf.enable then bar:Hide() return end

	bar:Show()
	bar:ClearAllPoints()
	bar:SetPoint(unpack(bconf.position))

	if bconf.background.enable then 
		bar.Backdrop:SetTemplate(bconf.background.transparent and 'T' or '')
	else
		bar.Backdrop:SetBackdrop(nil)
	end

	local long = bconf.buttonsize * (bconf.numbuttons) + bconf.buttonspacing * (bconf.numbuttons-1)

	if bconf.vertical then bar:SetSize(bconf.buttonsize, long)
	else bar:SetSize(long, bconf.buttonsize) end

	for i, button in pairs(bar.buttons) do
		button:SetSize(bconf.buttonsize, bconf.buttonsize)
		
		button:ClearAllPoints()

		if i == 1 then --first one's always anchored topleft
			button:SetPoint('TOPLEFT', bar, 'TOPLEFT', 0, 0)
		elseif i > bconf.numbuttons then --cram the button off of the screen
			button:SetPoint('BOTTOM', UIParent, 'TOP', 500, 0)
		else
			if bconf.vertical then
				button:SetPoint('TOP', bar.buttons[i-1], 'BOTTOM', 0, -bconf.buttonspacing)
			else
				button:SetPoint('LEFT', bar.buttons[i-1], 'RIGHT', bconf.buttonspacing, 0)
			end
		end
	end

	AB:UpdateButtonConfig(barID)
end

---------------------------------------------
-- HOVERBIND --------------------------------
---------------------------------------------


---------------------------------------------
-- INITIALIZATION ---------------------------
---------------------------------------------

function AB:UPDATE_BINDINGS(event)
	if InCombatLockdown() then return end	

	for barID = 1, 5 do
		local bar = self.Bars[barID]
		if not bar then return end

		ClearOverrideBindings(bar)
		for buttonID, button in pairs(bar.buttons) do
		
			local name = button:GetName()
			local bindingKey = GetBindingKey(BAR_SETTINGS[barID].bind..buttonID)
			for k=1, select('#', bindingKey) do
				local key = select(k, bindingKey)
				if key and key ~= "" then
					SetOverrideBindingClick(bar, false, key, name)
				end
			end
		end
	end
end


function AB:OnInitialize()

	-- All action bars will be stored here
	self.Bars = {}

	-- Create the 5 main action bars
	for barID=1, 5 do
		self:CreateActionBar(barID)
	end
	
	self:DisableBlizzardActionBars()
	self:RegisterEvent("UPDATE_BINDINGS")

	-- Create the pet bar
	self:CreateActionBar('pet', 10)
end