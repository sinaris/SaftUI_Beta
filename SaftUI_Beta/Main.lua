local ADDON_NAME = ...
SaftUI = LibStub('AceAddon-3.0'):NewAddon(ADDON_NAME, 'AceEvent-3.0', 'AceHook-3.0');
local st = SaftUI

---------------------------------------------
-- CONSTANTS --------------------------------
---------------------------------------------
st.StringFormat = LibStub('LibStringFormat-1.0')
st.GAME_VERSION = tonumber(GetAddOnMetadata(..., 'Version'))
st.ADDON_NAME = ADDON_NAME
st.ADDON_TITLE = GetAddOnMetadata(..., 'Title')
st.BUILD_INFO = GetBuildInfo()

BINDING_NAME_SUMMONRANDOMFAVORITEMOUNT = 'Summon Random Mount'

st.MY_NAME = select(1, UnitName('player'))
st.MY_CLASS = select(2, UnitClass('player'))
st.MY_RACE = select(2, UnitRace('player'))
st.MY_FACTION = UnitFactionGroup('player')
st.MY_REALM = GetRealmName()

st.BLANK_TEX = [[Interface\BUTTONS\WHITE8X8]]
st.MEDIA_PATH = format('Interface\\AddOns\\%s\\Media\\', ADDON_NAME)
st.ICON_COORDS = {.08, .92, .08, .92}
st.BORDER_INSET = 1
st.UI_PANEL_PADDING = 10
st.TAB_HEIGHT = 19 --Generally should be an odd number to perfectly center font
st.UI_PANEL_HEIGHT = 424 --used for blizzard panels such as Character Frame, Spell Book, Friends List, etc.
st.CLOSE_BUTTON_SIZE = {30,10}

st.BACKDROP = {
	bgFile = st.BLANK_TEX, 
	edgeFile = st.BLANK_TEX,
	tile = false, tileSize = 0, edgeSize = 1, 
	insets = { left = 0, right = 0, top = 0, bottom = 0}
}

--Create an always hidden frame to use as a parent for 'killed' objects
st.HiddenFrame = CreateFrame('frame')
st.HiddenFrame:Hide()

--store global namespace

st.pixelFont = CreateFont('SaftUI_FontPixel')
st.pixelFont:SetShadowOffset(0, 0)
st.pixelFont:SetFont(st.MEDIA_PATH..'Fonts\\Semplice_Reg.ttf', 8, 'MONOCHROMEOUTLINE')
st.pixelFont:SetSpacing(4)

st.normalFont = CreateFont('SaftUI_FontNormal')
st.normalFont:SetShadowOffset(0, 0)
st.normalFont:SetFont(st.MEDIA_PATH..'Fonts\\HelveticaNeueLTStd-Cn.otf', 12)

st.TEXTURE_PATHS = {
	['mail'] = st.MEDIA_PATH..'Textures\\mail.tga',
	['cornerbr'] = st.MEDIA_PATH..'Textures\\cornerarrowbottomright.tga',
	['goldstring'] = st.MEDIA_PATH..'Textures\\goldstring.tga',
	['search'] = st.MEDIA_PATH..'Textures\\search.tga'
}

st.DIFFICULTY_COLORS = {
	RED			  = { 220/255, 100/255, 100/255 },
	YELLOW		  = { 200/255, 200/255, 100/255 }, 
	GREEN	 	  = { 240/255, 240/255,  60/255 }, 
	GREY	 	  = { 100/255, 240/255,  60/255 }, 
}
st.DIFFICULTY_COLORS_HEX = {}
for color,rgb in pairs(st.DIFFICULTY_COLORS) do
	st.DIFFICULTY_COLORS_HEX[color] = st.StringFormat:ToHex(unpack(rgb))
end

---------------------------------------------
-- INITIALIZE -------------------------------
---------------------------------------------

function st:OnInitialize()
	
	self.Saved = LibStub('AceDB-3.0'):New("SaftUISaved", {
		char = {},
		realm = {},
		class = {}, 
		race = {},
		faction = {},
		factionrealm = {},
		global = {},
		profile = self.Defaults,
	})

	st.pixelFont:SetTextColor(unpack(st.Saved.profile.Colors.textnormal))
	st.normalFont:SetTextColor(unpack(st.Saved.profile.Colors.textnormal))

	for _,font in pairs({
		-- GameFontNormal,
		-- GameFontDisable,
		-- GameFontHighlight,
		-- GameFontNormalHuge,
		-- GameFontHighlightHuge,
		-- GameFontNormalSmall,
		-- GameFontWhiteTiny,
		-- GameFontNormalMed2,
		-- GameFontNormalLarge,
		-- GameFontDisableSmall,
		-- GameFontNormalHugeOutline2,
		-- GameFontNormalOutline,
		-- GameFontHighlightOutline,
		-- QuestFontHighlight,
		-- GameFontHighlightMedium,
		-- GameFontBlackMedium,
		-- GameFontRed,
		-- GameFontBlack,
		-- GameFontHighlightMed2,
		-- GameFontHighlightLarge,
		-- GameFontNormalMed3,
		-- GameFontNormalMed2,
		-- GameFontDisableLarge,
		-- GameFontHighlightSmall,
		-- GameFontHighlightSmallLeft,
		-- GameFontDisableSmallLeft,
		-- GameFontHighlightSmall2,
		-- GameFontNormalSmall2,
		-- GameFontNormalLarge2,
		-- GameFontNormalWTF2,
		-- GameFontNormalShadowHuge2,
		-- GameFontNormalHugeOutline,
		-- GameFontNormalHuge3,
		-- GameTooltipHeaderText,
		-- ChatFontNormal,
		-- GameFontNormalLeft,
		-- GameFontNormalLeftBottom,
		-- GameFontNormalLeftGreen,
		-- GameFontNormalLeftYellow,
		-- GameFontNormalLeftOrange,
		-- GameFontNormalLeftLightGreen,
		-- GameFontNormalLeftGrey,
		-- GameFontNormalLeftRed,
		-- GameFontDisableMed3,
		-- GameFontNormalRight,
		-- GameFontNormalCenter,
		-- GameFontHighlightLeft,
		-- GameFontHighlightCenter,
		-- GameFontHighlightRight,
		-- GameFontHighlightLarge2,
		-- GameFontDisableTiny,
		-- GameFontDisableLeft,
		-- GameFontGreen,
		-- GameFontBlackSmall,
		-- GameFontBlackTiny,
		-- GameFontWhiteSmall,
		-- GameFontWhite,
		-- GameFontNormalSmallLeft,
		-- GameFontHighlightSmallLeftTop,
		-- GameFontHighlightSmallRight,
		-- GameFontHighlightExtraSmall,
		-- GameFontHighlightExtraSmallLeft,
		-- GameFontHighlightExtraSmallLeftTop,
		-- GameFontDarkGraySmall,
		-- GameFontNormalGraySmall,
		-- GameFontGreenSmall,
		-- GameFontRedSmall,
		-- GameFontHighlightSmallOutline,
		-- GameFontNormalLargeOutline,
		-- GameFontNormalLargeLeft,
		-- GameFontNormalLargeLeftTop,
		-- GameFontGreenLarge,
		-- GameFontRedLarge,
		-- GameFontNormalHugeBlack,
		-- BossEmoteNormalHuge,
		-- NumberFontNormal,
		-- NumberFontNormalRight,
		-- NumberFontNormalRightRed,
		-- NumberFontNormalRightYellow,
		-- NumberFontNormalYellow,
		-- NumberFontNormalSmall,
		-- NumberFontNormalSmallGray,
		-- NumberFontNormalGray,
		-- NumberFontNormalLarge,
		-- NumberFontNormalLargeRight,
		-- NumberFontNormalLargeRightRed,
		-- NumberFontNormalLargeRightYellow,
		-- NumberFontNormalLargeYellow,
		-- NumberFontNormalHuge,
		ChatFontNormal,
		-- ChatFontSmall,
		-- QuestTitleFont,
		-- QuestTitleFontBlackShadow,
		-- QuestFont,
		-- QuestFontLeft,
		-- QuestFontNormalSmall,
		-- QuestDifficulty_Impossible,
		-- QuestDifficulty_VeryDifficult,
		-- QuestDifficulty_Difficult,
		-- QuestDifficulty_Standard,
		-- QuestDifficulty_Trivial,
		-- QuestDifficulty_Header,
		-- ItemTextFontNormal,
		-- MailTextFontNormal,
		-- SubSpellFont,
		-- NewSubSpellFont,
		-- DialogButtonNormalText,
		-- DialogButtonHighlightText,
		-- ZoneTextFont,
		-- SubZoneTextFont,
		-- PVPInfoTextFont,
		-- ErrorFont,
		-- TextStatusBarText,
		-- TextStatusBarTextLarge,
		-- CombatLogFont,
		-- GameTooltipText,
		-- GameTooltipTextSmall,
		-- WorldMapTextFont,
		-- InvoiceTextFontNormal,
		-- InvoiceTextFontSmall,
		-- CombatTextFont,
		-- MovieSubtitleFont,
		-- AchievementPointsFont,
		-- AchievementPointsFontSmall,
		-- AchievementDescriptionFont,
		-- AchievementCriteriaFont,
		-- AchievementDateFont,
		-- VehicleMenuBarStatusBarText,
		-- FocusFontSmall,
		-- ObjectiveFont,
	}) do
		font:SetFontObject(st.pixelFont)
		font:SetTextColor(unpack(st.Saved.profile.Colors.textnormal))
		font:SetShadowOffset(0, 0)
		-- font:SetSpacing(4)
	end
end

---------------------------------------------
-- UTILITY FUNCTIONS ------------------------
---------------------------------------------

st.HideGameTooltip = function() GameTooltip:Hide() end
st.dummy = function() end

local coppericon = '|T'..st.TEXTURE_PATHS.goldstring .. ':8:16:0:0:16:32:2:16:00:08|t'
local silvericon = '|T'..st.TEXTURE_PATHS.goldstring .. ':8:16:0:0:16:32:2:16:12:20|t'
local goldicon   = '|T'..st.TEXTURE_PATHS.goldstring .. ':8:16:0:0:16:32:2:16:24:32|t'
function st:GetGoldString(money)

	return self.StringFormat:GoldFormat(money or GetMoney())


	-- local money = money or GetMoney()
	-- local gold = floor(abs(money / 10000))
	-- local silver = floor(abs(mod(money / 100, 100)))
	-- local copper = floor(abs(mod(money, 100)))

	-- return (gold>0 and (gold .. goldicon) or '') .. (silver>0 and (silver .. silvericon) or '') .. (copper>0 and (copper .. coppericon) or '')
end

function st.CreateEditBox(name, parent, width, height, point)
	local editbox = CreateFrame('EditBox', name or nil, parent or UIParent)

	if point then editbox:SetPoint(unpack(point)) end
	editbox:SetAutoFocus(false)
	editbox:SetTextInsets(5, 5, 0, 0)

	editbox:Skin(height, width)

	editbox:SetFontObject(SaftUI.pixelFont)
	editbox:SetTextColor(1, 1, 1)

	--Just some basic scripts to make sure your cursor doesn't get stuck in the edit box
	editbox:HookScript('OnEnterPressed',  function(self) self:ClearFocus() end)
	editbox:HookScript('OnEscapePressed', function(self) self:ClearFocus() end)

	return editbox
end


--Make a copy of a table
function st.tablecopy(t, deep, seen)
	seen = seen or {}
	if t == nil then return nil end
	if seen[t] then return seen[t] end

	local nt = {}
	for k, v in pairs(t) do
		if deep and type(v) == 'table' then
			nt[k] = st.tablecopy(v, deep, seen)
		else
			nt[k] = v
		end
	end
	setmetatable(nt, st.tablecopy(getmetatable(t), deep, seen))
	seen[t] = nt
	return nt
end

--Merge two tables, with variables from t2 overwriting t1 when a duplicate is found
function st.tablemerge(t1, t2)
	for k, v in pairs(t2) do
		if (type(v) == 'table') and (type(t1[k] or false) == 'table') then
		   st.tablemerge(t1[k], t2[k])
		else
			t1[k] = v
		end
	end
	return t1
end

--Purge any variable of t1 who's value is set to the same as t2
function st.tablepurge(t1, t2)
	for k, v in pairs(t2) do
		if (type(v) == 'table') and (type(t1[k] or false) == 'table') then
			st.tablepurge(t1[k], t2[k])
		else
			if t1[k] == v then
				t1[k] = nil
			end
		end
	end
	return t1
end

function st.tableprint(table)
	for key, val in pairs(table) do
		print(key, '=>', val)
	end
end


---------------------------------------------
-- API FUNCTIONS ----------------------------
---------------------------------------------

--Effectively remove the object without breaking any calls that might be made to access the object
local function Kill(self)
	if self.UnregisterAllEvents then
		self:UnregisterAllEvents()
		self:SetParent(st.HiddenFrame)
	end
	self._Show = self.Show
	self.Show = self.Hide
	
	self:Hide()
end

--Removes any textures that the object might have
local function StripTextures(self)
	if self.SetNormalTexture    then self:SetNormalTexture('')    end	
	if self.SetHighlightTexture then self:SetHighlightTexture('') end
	if self.SetPushedTexture    then self:SetPushedTexture('')    end	
	if self.SetDisabledTexture  then self:SetDisabledTexture('')  end	

	local name = self.GetName and self:GetName()
	if name then 
		if _G[name..'Left'] then _G[name..'Left']:SetAlpha(0) end
		if _G[name..'Middle'] then _G[name..'Middle']:SetAlpha(0) end
		if _G[name..'Right'] then _G[name..'Right']:SetAlpha(0) end	
	end

	if self.Left then self.Left:SetAlpha(0) end
	if self.Right then self.Right:SetAlpha(0) end	
	if self.Middle then self.Middle:SetAlpha(0) end

	for i=1, self:GetNumRegions() do
		local region = select(i, self:GetRegions())
		if region:GetObjectType() == 'Texture' then
			if kill then
				region:Kill()
			else
				region:SetTexture(nil)
			end
		end
	end	 
end

local function TrimIcon(self, customTrim)
	if self.SetTexCoord then
		local trim = customTrim or .08
		self:SetTexCoord(trim, 1-trim, trim, 1-trim)
	else
		S:print('function SetTexCoord does not exist for',self:GetName() or self)
	end
end

--General function used to style frames
local function SetTemplate(self, template, preserveTextures)
	if not template then template = '' end

	if not preserveTextures then self:StripTextures(true) end
	
	if template == 'None' then self:SetBackdrop(nil) return end

	self:SetBackdrop(st.BACKDROP)

	local backdropcolor, bordercolor	
	if strmatch(template, 'Black') then
		backdropcolor = {0, 0, 0, 1}
		bordercolor = {0, 0, 0, 0}
	elseif strmatch(template, 'Button') then
		backdropcolor = st.Saved.profile.Colors[strmatch(template, 'Close') and 'buttonred' or strmatch(template, 'Help') and 'buttonyellow' or 'buttonnormal']
		bordercolor = st.Saved.profile.Colors[strmatch(template, 'Action') and 'actionbuttonborder' or 'buttonborder']

		if strmatch(template, 'Action') then
			local cooldown = self:GetName() and _G[self:GetName()..'Cooldown'] or self.cooldown
			if cooldown then
				cooldown:SetAllPoints()
				if not self.cooldown then self.cooldown = cooldown end
			end

			if self.icon then
				self.icon:TrimIcon()
				self.icon:SetDrawLayer('BACKGROUND', 1)
			end
		end

		if self.SetNormalTexture then self:SetNormalTexture('') end

		if self.SetHighlightTexture and not self.hover then
			local hover = self:CreateTexture(nil, 'OVERLAY')
			hover:SetTexture(1, 1, 1, .1)
			hover:SetAllPoints(self)
			self.hover = hover
			self:SetHighlightTexture(hover)
		end

		if self.SetPushedTexture and not self.pushed then
			local pushed = self:CreateTexture(nil, 'OVERLAY')
			pushed:SetTexture(0, 0, 0, .1)
			pushed:SetAllPoints(self)
			self.pushed = pushed
			self:SetPushedTexture(pushed)
		end

		if self.SetNormalFontObject then
			self:SetNormalFontObject(st.pixelFont)
			self:SetHighlightFontObject(st.pixelFont)
			self:SetDisabledFontObject(st.pixelFont)
			self:SetPushedTextOffset(0, 0)
		end
	elseif template == 'Transparent' then
		backdropcolor = st.Saved.profile.Colors.transparentbackdrop
		bordercolor = st.Saved.profile.Colors.transparentborder
	else
		backdropcolor = st.Saved.profile.Colors.normalbackdrop
		bordercolor = st.Saved.profile.Colors.normalborder
	end

	if backdropcolor and bordercolor then
		self:SetBackdropColor(unpack(backdropcolor))
		self:SetBackdropBorderColor(unpack(bordercolor))
	else
		self:SetBackdrop(nil)
	end
end

-- Creates a textured backdrop anchored to a frame, varargs parameter is used for passing insets to SetPoints function
local function CreateBackdrop(self, template, ...)
	local backdrop = CreateFrame('frame', nil, self)
	backdrop:SetPoints(...)
	backdrop:SetTemplate(template)
	backdrop:SetFrameLevel(max(self:GetFrameLevel()-1, 0))

	self.Backdrop = backdrop

end

-- More advanced version of SetAllPoints, this allows you to pass up to 4 additional arguments that dictate the offsets:
--  One single value applies to all four sides.
--  Two values apply first to top and bottom, the second one to left and right.
--  Three values apply first to top, second to left and right and third to bottom.
--  Four values apply to top, right, bottom and left in that order (clockwise).
local function SetPoints(self, ...)
	local offsets, parent
	if ... and type(select(1,...)) ~= 'number' then
		offsets = {select(2,...)}
		parent = ...
	else
		offsets = {...}
		parent = self:GetParent()
	end

	self:ClearAllPoints()
	if #offsets == 0 then
		self:SetAllPoints()
	elseif #offsets == 1 then
		self:SetPoint('TOPLEFT', parent, offsets[1], -offsets[1])
		self:SetPoint('BOTTOMRIGHT', parent, -offsets[1], offsets[1])
	elseif #offsets == 2 then
		self:SetPoint('TOPLEFT', parent, offsets[2], -offsets[1])
		self:SetPoint('BOTTOMRIGHT', parent, -offsets[2], offsets[1])
	elseif #offsets == 3 then
		self:SetPoint('TOPLEFT', parent, offsets[2], -offsets[1])
		self:SetPoint('BOTTOMRIGHT', parent, -offsets[2], offsets[3])
	else
		self:SetPoint('TOPLEFT', parent, offsets[4], -offsets[1])
		self:SetPoint('BOTTOMRIGHT', parent, -offsets[2], offsets[3])
	end
end


--Creates a dragable header for a frame
local function CreateHeader(self, closeButton, title, mainHelpButton)
	self:EnableMouse(true)
	self:SetMovable(true)

	local region = self:CreateTitleRegion()

	region:SetPoint('TOPLEFT')
	region:SetPoint('TOPRIGHT')
	region:SetHeight(st.TAB_HEIGHT-7)

	region.backdrop = self:CreateTexture(nil, 'OVERLAY')
	region.backdrop:SetAllPoints(region)
	region.backdrop:SetTexture(unpack(st.Saved.profile.Colors.buttonnormal))
	
	if title then self.Title = title end
	if self.Title then
		self.Title:SetParent(self)
		self.Title:ClearAllPoints()
		self.Title:SetPoint('CENTER', region)
		self.Title:SetFontObject(st.pixelFont)
	end

	if closeButton then self.CloseButton = closeButton end
	if self.CloseButton then
		self.CloseButton:SetParent(self)
		self.CloseButton:SetTemplate('CloseButton')
		self.CloseButton:ClearAllPoints()
		self.CloseButton:SetPoint('TOPRIGHT', -10, 0)
		self.CloseButton:SetSize(unpack(SaftUI.CLOSE_BUTTON_SIZE))
	end

	if mainHelpButton then self.MainHelpButton = mainHelpButton end
	if self.MainHelpButton then
		self.MainHelpButton:SetParent(self)
		self.MainHelpButton:SetTemplate('HelpButton')
		self.MainHelpButton:ClearAllPoints()
		if self.CloseButton then
			self.MainHelpButton:SetPoint('TOPRIGHT', self.CloseButton, 'TOPLEFT', -st.UI_PANEL_PADDING, 0)
		else
			self.MainHelpButton:SetPoint('TOPRIGHT', -st.UI_PANEL_PADDING, 0)
		end
		self.MainHelpButton:SetSize(unpack(SaftUI.CLOSE_BUTTON_SIZE))
	end
	
	self.TitleRegion = region

	return region
end

local function CreateFooter(self)
	local footer = CreateFrame('Frame', nil, self)
	footer:SetPoint('BOTTOMLEFT')
	footer:SetPoint('BOTTOMRIGHT')
	footer:SetHeight(st.TAB_HEIGHT)
	footer:SetTemplate('Button')
	self.Footer = footer
end

local function CreateCloseButton(self)
	local close = CreateFrame('Button', nil, self)
	close:SetTemplate('CloseButton')
	close:SetPoint('TOPRIGHT', -st.UI_PANEL_PADDING, 0)
	close:SetSize(unpack(SaftUI.CLOSE_BUTTON_SIZE))
	close:SetScript('OnClick', function() self:Hide() end)

	return close
end

local function EnableMoving(self)
	self:EnableMouse(true)
	self:SetMovable(true)
	self:SetClampedToScreen(true)
	self:HookScript('OnMouseDown', function(self)
		if (not onShift) or IsShiftKeyDown() then
			self:StartMoving()
		end
	end)
	self:HookScript('OnMouseUp', function(self) self:StopMovingOrSizing() end)
end

-- Handles both blizzard slider templates, used as scrollbar:Skin() 
local function SkinScrollBar(self, inside, customWidth)
	local parent = self:GetParent()
	local name = self:GetName()


	if _G[name..'ScrollUpButton'] then _G[name..'ScrollUpButton']:Kill() end
	if _G[name..'ScrollDownButton'] then _G[name..'ScrollDownButton']:Kill() end

	-- for _,tex in pairs({
	-- 	_G[name..'BG'],
	-- 	_G[name..'Track'],
	-- 	_G[name..'Top'],
	-- 	_G[name..'Middle'],
	-- 	_G[name..'Bottom'],
	-- }) do
	-- 	if tex then tex:SetTexture(nil) end
	-- end


	self:StripTextures()

	local width = customWidth or 20

	local thumb = _G[name..'ThumbTexture']
	-- thumb:SetTexture(unpack(st.Saved.profile.Colors.buttonnormal))
	thumb:SetTexture(nil)
	thumb.BG = CreateFrame('Frame', nil, self)
	thumb.BG:SetTemplate('Button')
	thumb.BG:SetPoint('TOPLEFT', thumb, 'TOPLEFT', 0, 0)
	thumb.BG:SetPoint('BOTTOMRIGHT', thumb, 'BOTTOMRIGHT', 0, 0)


	-- Standardized positioning for all scrollbars
	self:ClearAllPoints()
	if inside then
		self:SetPoint('TOPRIGHT', parent, 'TOPRIGHT', 1, 0)
		self:SetPoint('BOTTOMRIGHT', parent, 'BOTTOMRIGHT', 1, 0)
	else
		self:SetPoint('TOPLEFT', parent, 'TOPRIGHT', 0, 0)
		self:SetPoint('BOTTOMLEFT', parent, 'BOTTOMRIGHT', 0, 0)
	end
	self:SetWidth(width)

	self.SetPoint = st.dummy

end

local function SkinEditBox(editbox, height, width)
	local name = editbox:GetName()

	if name then
		if _G[name..'Left'] then Kill(_G[name..'Left']) end
		if _G[name..'Middle'] then Kill(_G[name..'Middle']) end
		if _G[name..'Right'] then Kill(_G[name..'Right']) end
		if _G[name..'Mid'] then Kill(_G[name..'Mid']) end
	end

	editbox:SetTemplate('Button', true)

	editbox:SetAutoFocus(false)
	
	-- Get the highlight and blinking pointer textures to modify them a bit
	local fontstring, highlight, _, _, pointer = editbox:GetRegions()

	fontstring:SetFontObject(st.pixelFont)
	editbox.highlight = highlight
	editbox.pointer = pointer

	editbox.highlight:SetTexture(st.BLANK_TEX)
	editbox.highlight:SetVertexColor(1,1,1, 0.3)

	editbox:HookScript('OnEditFocusGained', function(self)
		self.pointer:SetWidth(1)
	end)
	
	editbox:HookScript('OnCursorChanged', function(self, x, y, width, height)
		self.highlight:SetHeight(height + 6)
	end)


	editbox:HookScript('OnEnterPressed',  function(self) self:ClearFocus() end)
	editbox:HookScript('OnEscapePressed', function(self) self:ClearFocus() end)
	editbox:HookScript('OnEditFocusGained', function(self) self:HighlightText() end)
	editbox:HookScript('OnEditFocusLost', function(self) self:HighlightText(0,0) end)

	editbox:SetHeight(height or 20)
	if width then editbox:SetWidth(width) end
end

local function SkinDropDown(self)
	local button = _G[self:GetName().."Button"]
	local text = _G[self:GetName().."Text"]

	self:SetTemplate('Button')

	if not self.skinned then
		local framelevel = self:GetFrameLevel()
		self:EnableMouse(false)

		text:ClearAllPoints()
		text:SetPoint("RIGHT", self, "RIGHT", -10, 0)
		text:SetPoint("LEFT", self, "LEFT", 10, 0)
		text:SetJustifyH('RIGHT')
		text:SetFontObject(st.pixelFont)
		text.SetPoint = st.dummy

		if not button.normal then
			local normal = button:CreateTexture(nil, 'OVERLAY')
			normal:SetTexture(st.TEXTURE_PATHS.cornerbr)
			normal:SetVertexColor(1, 1, 1, 0.3)
			normal:SetSize(16, 16)
			normal:SetPoint('BOTTOMRIGHT', 0, 0)
			button.normal = normal
			button:SetNormalTexture(hover)
		end

		if not button.hover then
			local hover = button:CreateTexture(nil, 'OVERLAY')
			hover:SetTexture(st.TEXTURE_PATHS.cornerbr)
			hover:SetVertexColor(unpack(st.Saved.profile.Colors.buttonhover))
			hover:SetSize(16, 16)
			hover:SetPoint('BOTTOMRIGHT', 0, 0)
			button.hover = hover
			button:SetHighlightTexture(hover)
		end

		button:SetPushedTexture(nil)
		button:SetAllPoints()
	end

	self.skinned = true
end

local function SkinCheckButton(self)
	self:StripTextures()

	self:SetSize(12, 12)
	self.Display = CreateFrame('Frame', nil, self)
	self.Display:SetAllPoints()
	self.Display:SetTemplate()
	self.Display:SetPoint('CENTER')
	
	self.Display:SetFrameLevel(self:GetFrameLevel())
	self:SetFrameLevel(self:GetFrameLevel()+1)

	--Time to sexify these textures
	local checked = self.Display:CreateTexture(nil, 'OVERLAY')
	checked:SetTexture(st.BLANK_TEX)
	checked:SetVertexColor(unpack(st.Saved.profile.Colors.buttonhover))
	checked:SetPoints(self.Display, 1)
	self:SetCheckedTexture(checked)

	local hover = self.Display:CreateTexture(nil, 'OVERLAY')
	hover:SetTexture(st.BLANK_TEX)
	hover:SetVertexColor(unpack(st.Saved.profile.Colors.buttonnormal))
	hover:SetPoints(self.Display, 1)
	self:SetHighlightTexture(hover)

	local name = self:GetName()
	local text = self.Text or name and _G[name..'Text']
	if text then
		text:SetFontTemplate()
	end
end

---------------------------------------------
-- API INJECTION ----------------------------
---------------------------------------------
local function addapi(object)
	local mt = getmetatable(object).__index
	if not object.SetTemplate		then mt.SetTemplate			= SetTemplate		end
	if not object.CreateBackdrop	then mt.CreateBackdrop		= CreateBackdrop	end
	if not object.StripTextures		then mt.StripTextures		= StripTextures 	end
	if not object.TrimIcon			then mt.TrimIcon			= TrimIcon			end
	if not object.Kill				then mt.Kill				= Kill				end
	if not object.SetPoints			then mt.SetPoints			= SetPoints			end
	if not object.CreateHeader		then mt.CreateHeader		= CreateHeader		end
	if not object.CreateFooter		then mt.CreateFooter		= CreateFooter		end
	if not object.CreateCloseButton	then mt.CreateCloseButton	= CreateCloseButton	end
	if not object.EnableMoving		then mt.EnableMoving		= EnableMoving		end
	if not object.SkinDropDown		then mt.SkinDropDown		= SkinDropDown		end
end

local handled = {['Frame'] = true}
local object = CreateFrame('Frame')
addapi(object)
addapi(object:CreateTexture())
addapi(object:CreateFontString())

getmetatable(CreateFrame('Slider')).__index.Skin = SkinScrollBar
getmetatable(CreateFrame('ScrollFrame')).__index.Skin = SkinScrollBar
getmetatable(CreateFrame('CheckButton')).__index.Skin = SkinCheckButton
local editbox = CreateFrame('EditBox')
editbox:SetAutoFocus(false) --WHY IS THIS NOT DISABLED BY DEFAULT WHAT THE HELL
getmetatable(editbox).__index.Skin = SkinEditBox

object = EnumerateFrames()
while object do
	if not handled[object:GetObjectType()] then
		addapi(object)
		handled[object:GetObjectType()] = true
	end
	
	object = EnumerateFrames(object)
end
