local st = SaftUI
local CF = st:NewModule('Config', 'AceHook-3.0', 'AceEvent-3.0')

local ROW_HEIGHT = 20
local WINDOW_WIDTH = 400
local ITEM_PADDING = 10
local INSET_WIDTH = WINDOW_WIDTH-ITEM_PADDING
CF.Modules = {}
CF.Frames = {}
CF.Groups = { General = {} }

-----------------------------------------
-- GENERAL FUNCTIONS --------------------
-----------------------------------------

function CF:AddConfigFrame(options)
	-- assert key, label, parent, and args

	local panel = CreateFrame('Button', nil, UIParent)
	panel:SetAllPoints(options.parent)
	panel:SetTemplate('Transparent')
	panel:SetFrameStrata('DIALOG')
	
	local hover = panel:CreateTexture(nil, 'OVERLAY')
	hover:SetTexture(1, 1, 1, .1)
	hover:SetAllPoints(panel)
	panel.hover = hover
	panel:SetHighlightTexture(hover)

	panel:SetScript('OnClick', function(self)
		for _,module in pairs(CF.Modules) do if not module.panel:IsShown() then module.panel:Show() end end
		self:Hide()
		CF:SetConfig(options.key)
	end)

	panel.label = panel:CreateFontString(nil, 'OVERLAY')
	panel.label:SetFontObject(st.pixelFont)
	panel.label:SetPoint('CENTER')
	panel.label:SetText(options.label)

	if not options.group then
		tinsert(CF.Groups.General, panel)
	else
		if not CF.Groups[options.group] then CF.Groups[options.group] = {} end
		tinsert(CF.Groups[options.group], panel)
	end

	panel:Hide()

	options.parent.ConfigPanel = panel

	options.panel = panel
	self.Modules[options.key] = { ['panel'] = panel, ['options'] = options }
end

local function round(num)
	return floor(num+.5)
end

function CF:SetConfigObject(module, optionTable, group)
	-- local info = group.info or {}
	
	local object

	if optionTable.type == 'group' then
		object = self:GetNext('Group')
		object.isGroup = true

		object.get = optionTable.get or group.get or module.get

	elseif optionTable.type == 'input' then
		object = self:GetNext('EditBox')
	
		local key, subkey = strmatch(optionTable.key, '(%w+)%[(%w+)%]')
		object.subkey = tonumber(subkey) or subkey
		object.key = key or optionTable.key
		
		object.get = optionTable.get or group.get or module.get
		
		object:SetTextInsets(0, 10, 0, 0)
		object:SetText(tostring(object.get(object.key, object.subkey)))
		
	elseif optionTable.type == 'dropdown' then
		object = self:GetNext('DropDown')

		local key, subkey = strmatch(optionTable.key, '(%w+)%[(%w+)%]')
		object.subkey = tonumber(subkey) or subkey
		object.key = key or optionTable.key
		object.get = optionTable.get or group.get or module.get

		object.choices = optionTable.choices
		object:initialize()
		UIDropDownMenu_SetSelectedValue(object, object.get(object.key, object.subkey))
	elseif optionTable.type == 'toggle' then
		object = self:GetNext('Toggle')
	
		local key, subkey = strmatch(optionTable.key, '(%w+)%[(%w+)%]')
		object.subkey = tonumber(subkey) or subkey
		object.key = key or optionTable.key
		
		object.get = optionTable.get or group.get or module.get
		object:SetChecked(object.get(object.key, object.subkey))
	end

	if optionTable.type ~= 'menubutton' then
		object.set		  = optionTable.set			or group.set			or module.set
		object.sanitation = optionTable.sanitation	or group.sanitation	or module.sanitation
		object.validation = optionTable.validation	or group.validation	or module.validation
	end
	object.note 	  = optionTable.note

	object.label:SetText(optionTable.label)
	object:SetWidth(INSET_WIDTH*(optionTable.width or 1) - ITEM_PADDING)

	local objectWidth, fullRow
	if group ~= self.ConfigWindow then
		objectWidth = (group:GetWidth()-ITEM_PADDING)*(optionTable.width or 1) - ITEM_PADDING
		fullRow = group.prev and group:GetWidth() >= round(group.prev:GetRight()-group:GetLeft()+object:GetWidth())
		tinsert(group.childFrames, object)
	else
		objectWidth = INSET_WIDTH*(optionTable.width or 1) - ITEM_PADDING
		fullRow = group.prev and WINDOW_WIDTH >= round((group.prev:GetRight())-self.ConfigWindow:GetLeft()+object:GetWidth())
	end

	object:SetWidth(objectWidth)
	object:SetFrameLevel(group:GetFrameLevel()+1)
	object:SetParent(group)
	if group.prev then 
		if fullRow and not optionTable.newRow then
			object:SetPoint('LEFT', group.prev, 'RIGHT', ITEM_PADDING, 0)
		else
			object:SetPoint('TOPLEFT', group.prevRow, 'BOTTOMLEFT', 0, -ITEM_PADDING)
			group.prevRow = object
		end
	else
		if group.isGroup then
			object:SetPoint('TOPLEFT', group or group, 'TOPLEFT', ITEM_PADDING, -ITEM_PADDING-5)
		else
			object:SetPoint('TOPLEFT', self.ConfigWindow.TitleRegion or group, 'BOTTOMLEFT', ITEM_PADDING, -ITEM_PADDING)
		end
		group.prevRow = object
	end
	group.prev = object

	if object.isGroup then
		object.childFrames = {}
		for _,subOptionTable in pairs(optionTable.args) do
			self:SetConfigObject(module, subOptionTable, object)
		end
		object:SetHeight(round(object:GetTop()-object.prev:GetBottom()+ITEM_PADDING))
	end
end

function CF:SetConfig(key)
	local module = self.Modules[key].options
	assert(module, 'Module does not exist for '..key)

	self:CleanseConfig()

	self.ConfigWindow.Title:SetText(module.label)

	for _,optionTable in pairs(module.args) do
		self:SetConfigObject(module, optionTable, self.ConfigWindow)
	end
end

function CF:CleanseConfig()
	self.ConfigWindow.Title:SetText('SaftUI Config')
	self.ConfigWindow.prev = nil
	self.ConfigWindow.prevRow = nil
	for _,frameTables in pairs(self.Frames) do 
		for _,frame in pairs(frameTables) do
			frame.prev = nil
			frame.prevRow = nil
			frame:ClearAllPoints()
			frame:Hide()
			frame.key = nil
			frame.get = nil
			frame.set = nil
			frame.sanitation = nil
			frame.note = nil
			frame.validation = nil
			frame.label:SetText('')
			frame.childFrames = {}
			if frame.SetText then frame:SetText('') end
		end
	end
end

function CF:GetNext(frameType)
	if self['Create'..frameType] and not CF.Frames[frameType] then
		CF.Frames[frameType] = {}
	end

	for _,frame in pairs(CF.Frames[frameType]) do
		if not frame:IsShown() then
			frame:Show()
			return frame
		end
	end

	return self['Create'..frameType](self)
end

-----------------------------------------
-- MODULE TYPES -------------------------
-----------------------------------------


function CF:CreateMenuButton()
	local ID = #CF.Frames.MenuButton

	local button = CreateFrame('Button', 'SaftUI_ConfigMenuButton'..ID, self.ConfigWindow)
	button:SetTemplate('Button')
	button:Setheight(ROW_HEIGHT)

	button.label = group:CreateFontString(nil, 'OVERLAY')
	button.label:SetFontObject(st.pixelFont)
	button.label:SetPoint('CENTER')

	button:SetScript('OnClick', function(self)

		CF:SetMenu(self.key)
	end)

	CF.Frames.MenuButton[ID] = button

	return button
end

function CF:CreateGroup()
	local ID = #CF.Frames.Group + 1

	local group = CreateFrame('Frame', 'SaftUI_ConfigGroupFrame'..ID, self.ConfigWindow)
	group:SetTemplate('Transparent')
	group:SetBackdropBorderColor(1, 1, 1, .1)
	group:SetHeight(ROW_HEIGHT)
	group:SetWidth(INSET_WIDTH)

	group.childFrames = {}

	group.label = group:CreateFontString(nil, 'OVERLAY')
	group.label:SetFontObject(st.pixelFont)
	group.label:SetPoint('LEFT', group, 'TOPLEFT', 5, 0)

	group.minimize = CreateFrame('CheckButton', nil, group)
	group.minimize:SetPoint('RIGHT', group, 'TOPRIGHT', -5, 0)
	group.minimize:SetSize(15, 15)
	group.minimize:SetChecked(false)
	group.minimize.text = group.minimize:CreateFontString(nil, 'OVERLAY')
	group.minimize.text:SetFontObject(st.pixelFont)
	group.minimize.text:SetPoint('CENTER')
	group.minimize.text:SetText('-')
	
	group.minimize:HookScript('OnClick', function(self)
		if self:GetChecked() then
			for _,frame in pairs(group.childFrames) do
				frame:Hide()
			end
			group:SetHeight(ROW_HEIGHT)
			self.text:SetText('+')
		else
			local last
			for _,frame in pairs(group.childFrames) do
				frame:Show()
			end
			group:SetHeight(round(group:GetTop()-group.prev:GetBottom()+ITEM_PADDING))
			self.text:SetText('-')
		end
	end)

	CF.Frames.Group[ID] = group

	return group
end

function CF:CreateEditBox()
	local ID = #CF.Frames.EditBox + 1

	local editbox = CreateFrame('EditBox', 'SaftUI_ConfigEditBox'..ID, self.ConfigWindow)
	editbox:Skin()
	editbox:SetHeight(ROW_HEIGHT)
	editbox:SetWidth(INSET_WIDTH)
	editbox:SetJustifyH('RIGHT')
	editbox:SetTextInsets(3, 3, 0, 0)
	editbox:SetFontObject(st.pixelFont)

	editbox.label = editbox:CreateFontString(nil, 'OVERLAY')
	editbox.label:SetFontObject(st.pixelFont)
	editbox.label:SetPoint('LEFT', editbox, 'TOPLEFT', 5, 0)

	editbox:HookScript('OnEnterPressed', function(self)
		local input = self:GetText()

		if self.sanitation then
			input = self.sanitation(input)
		end
		
		local error = self.validation and self.validation(input)
		if error then
			CF:SetNote(error, true)
		else
			self.set(self.key, self.subkey, input)
		end
	end)

	editbox:HookScript('OnEnter', function(self)
		if self.note then 
			CF:SetNote(self.note)
		end
	end)
	editbox:HookScript('OnLeave', function(self) CF:SetNote() end)

	CF.Frames.EditBox[ID] = editbox

	return editbox
end

function CF:CreateToggle()
	local ID = #CF.Frames.Toggle + 1

	local toggle = CreateFrame('CheckButton', 'SaftUI_ConfigToggle'..ID, self.ConfigWindow)
	toggle:Skin()
	toggle:SetHeight(ROW_HEIGHT)
	toggle:SetWidth(INSET_WIDTH)

	toggle.label = toggle:CreateFontString(nil, 'OVERLAY')
	toggle.label:SetFontObject(st.pixelFont)
	toggle.label:SetPoint('LEFT', toggle, 'TOPLEFT', 5, 0)

	toggle:HookScript('OnClick', function(self)
		self.set(self.key, self.subkey, self:GetChecked())
	end)
	toggle:HookScript('OnEnter', function(self)
		if self.note then 
			CF:SetNote(self.note)
		end
	end)
	toggle:HookScript('OnLeave', function(self) CF:SetNote() end)

	CF.Frames.Toggle[ID] = toggle

	return toggle
end

function CF:CreateDropDown()
	local ID = #CF.Frames.DropDown + 1

	local dropdown = CreateFrame('Button', 'SaftUI_ConfigDropDown'..ID, self.ConfigWindow, 'UIDropDownMenuTemplate')
	dropdown:SkinDropDown()
	dropdown:SetHeight(ROW_HEIGHT)
	dropdown.SetHeight = st.dummy

	dropdown.label = dropdown:CreateFontString(nil, 'OVERLAY')
	dropdown.label:SetFontObject(st.pixelFont)
	dropdown.label:SetPoint('LEFT', dropdown, 'TOPLEFT', 5, 0)

	dropdown.initialize = function(self, level)
		assert(self.choices, 'No dropdown choices')
		for i, value in ipairs(self.choices) do
			UIDropDownMenu_AddButton({
				['text'] = self.choices[value] or value,
				['value'] = value,
				['func'] =	function(listButton, key, subkey, checked)
					self.set(key, subkey, listButton.value) --self here still refers to the dropdown frame
					UIDropDownMenu_SetSelectedValue(self, listButton.value)
				end,
				['arg1'] = self.key,
				['arg2'] = self.subkey,
			}, 1)
		end
		UIDropDownMenu_SetSelectedValue(self, self.get(self.key, self.subkey))
	end

	CF.Frames.DropDown[ID] = dropdown

	return dropdown
end

-----------------------------------------
-- OPTION TEMPLATE GENERATORS -----------
-----------------------------------------
CF.OptionTemplates = {
	['width'] = {
		key = 'width',
		type = 'input',
		sanitation = function(input) return tonumber(strmatch(input,'-?%d+')) end,
		label = 'Width',
		width = 0.2,
	},
	['height'] = {
		key = 'height',
		type = 'input',
		sanitation = function(input) return tonumber(strmatch(input,'-?%d+')) end,
		label = 'Height',
		width = 0.2,
	},
	['enable'] = {
		key = 'enable',
		type = 'toggle',
		label = 'Enable',
		width = 0.2,
	},
}

function CF:GetOptionTemplate(type, overwrite)
	local option = self.OptionTemplates[strlower(type)]

	assert(option, 'No option template found for ' .. type)

	return overwrite and st.tablemerge(st.tablecopy(option), overwrite) or st.tablecopy(option)
end

-----------------------------------------
-- INITIALIZE ---------------------------
-----------------------------------------

function CF:CreateConfigWindow()
	local window = CreateFrame('frame', 'SaftUI_ConfigWindow', UIParent)
	window:SetPoint('LEFT', UIPARENT_PADDING, 0)
	window:SetTemplate('Transparent')
	
	window.TitleRegion = window:CreateHeader()
	window.CloseButton = window:CreateCloseButton()
	self:HookScript(window.CloseButton, 'OnClick', 'ToggleConfig')
	
	window.Title = window:CreateFontString(nil, 'OVERLAY')
	window.Title:SetFontObject(st.pixelFont)
	window.Title:SetText('SaftUI Config')
	window.Title:SetPoint('TOP', 0, -3)

	window:SetSize(WINDOW_WIDTH, 500)
	self.ConfigWindow = window

	local footer = CreateFrame('frame', 'SaftUI_Footer', window)
	footer:SetTemplate('Button')
	footer:SetPoint('BOTTOMLEFT')
	footer:SetPoint('BOTTOMRIGHT')
	footer:SetHeight(20)
	footer.Text = footer:CreateFontString(nil, 'OVERLAY')
	footer.Text:SetFontObject(st.pixelFont)
	footer.Text:SetPoint('LEFT', 7, 0)
	window.Footer = footer

	self.ConfigWindow:Hide()
end

function CF:SetNote(note, error)
	self.ConfigWindow.Footer.Text:SetTextColor(unpack(st.Saved.profile.Colors[error and 'textred' or 'textnormal']))
	self.ConfigWindow.Footer.Text:SetText(note or '')
end

function CF:ToggleConfig()
	if self.ConfigWindow:IsShown() then
		self.ConfigWindow:Hide()
		for _,module in pairs(self.Modules) do
			module.panel:Hide()
		end
	else
		self.ConfigWindow:Show()
		for _,module in pairs(self.Modules) do
			module.panel:Show()
		end
	end
end

SLASH_SAFTUICONFIG1, SLASH_SAFTUICONFIG2 = '/sui', '/saftui'
SlashCmdList.SAFTUICONFIG = function() CF:ToggleConfig() end

function CF:OnInitialize()
	self:CreateConfigWindow()
end