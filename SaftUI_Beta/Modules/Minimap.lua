WorldMapPlayerUpper:EnableMouse(fale)

local st = SaftUI
local MM = st:NewModule('Minimap', 'AceHook-3.0', 'AceEvent-3.0')

WorldMapPlayerLower:EnableMouse(false)

local SIZE = 160
local PADDING = 5
local ICON_SIZE = 22

--------------------------------------
-- ICON TRAY -------------------------
--------------------------------------

--Icons to ignore when looping through minimap children
local BLACKLIST = {
	MinimapMailFrame = true,
	MinimapBackdrop = true,
	GameTimeFrame = true,
	MiniMapVoiceChatFrame = true,
	MiniMapInstanceDifficulty = true,
	GuildInstanceDifficulty = true,
	TimeManagerClockButton = true,
}

--Certain icons need to have their textures changed, add then here with texture paths
local NewIconTextures = {
	['DBMMinimapButton']		= "Interface\\Icons\\INV_Helmet_30",
	['SmartBuff_MiniMapButton'] = select(3, GetSpellInfo(12051)),
}

--Contains names of all icons that have been skinned
local SkinnedIcons = {}

--Special stuff for mail icon
function MM:SkinMailIcon()
	local mail = MiniMapMailFrame
	mail:ClearAllPoints()
	mail:SetPoint('TOPRIGHT', Minimap, 'TOPRIGHT', -5, -2)
	mail:SetSize(16, 16)
	MiniMapMailIcon:SetAllPoints(mail)
	MiniMapMailIcon:SetTexture(st.TEXTURE_PATHS.mail)
	MiniMapMailBorder:SetTexture(nil)
end

function MM:SkinTrackingIcon()
	local track = MiniMapTracking
	track.button = MiniMapTrackingButton
	track.icon = MiniMapTrackingIcon

	local name = track:GetName()

	track.button:SetTemplate('Button', true)
	track.button:SetPushedTexture(nil)
	track.button:SetHighlightTexture(nil)
	track.button:SetDisabledTexture(nil)
	track.button:SetAllPoints(track)

	track.icon:SetAllPoints(track)
	track.icon:SetDrawLayer('OVERLAY')
	track.icon:SetParent(track.button)
	track.button:HookScript('Onclick', function() track.icon:SetAllPoints() end)

	track:SetSize(ICON_SIZE, ICON_SIZE)
	track:SetParent(MM.IconTray)
	track:SetTemplate('TS')

	for _,region in pairs({track.button:GetRegions()}) do
		if region:GetObjectType() == 'Texture' then
			local texture = region:GetTexture()
			if not texture then return end

			if texture:find('Background') or texture:find('Border') or texture:find('AlphaMask') then
					region:SetTexture(nil)
			else
				-- region:ClearAllPoints()
				-- region:SetInside(track.button)
				-- region:SetTexCoord(unpack(S.iconcoords))
				-- region:SetDrawLayer('OVERLAY')
				-- track.button:SetTemplate("TS")
			end
		end
	end

	SkinnedIcons[name] = true
end

function MM:SkinQueueIcon()
	local button  = QueueStatusMinimapButton
	local icon    = QueueStatusMinimapButtonIcon
	local texture = QueueStatusMinimapButtonIconTexture

	button:Show()
	icon:Show()

	button:SetSize(20,20)
	button:ClearAllPoints()
	button:SetPoint('TOPRIGHT', Minimap, 'TOPRIGHT', -7, -7)
	button:StripTextures()
end

function MM:SkinGarrisonIcon()
	GarrisonLandingPageMinimapButton:GetNormalTexture():TrimIcon()
	GarrisonLandingPageMinimapButton:GetPushedTexture():TrimIcon()
	GarrisonLandingPageMinimapButton:SetTemplate('Button', true)

	GarrisonLandingPageMinimapButton:SetSize(ICON_SIZE, ICON_SIZE)
	GarrisonLandingPageMinimapButton:SetParent(self.IconTray)
	SkinnedIcons['GarrisonLandingPageMinimapButton'] = true
end

--Takes care of the actual icon skinning
function MM:SkinIcon(frame)
	if not frame then return end
	local name = frame:GetName()

	frame:SetTemplate('Button', true)
	-- frame:SetPushedTexture(nil)
	-- frame:SetHighlightTexture(nil)
	-- frame:SetDisabledTexture(nil)
	
	frame:SetSize(ICON_SIZE, ICON_SIZE)
	frame:SetParent(self.IconTray)

	for _,region in pairs({frame:GetRegions()}) do
		if region:GetObjectType() == 'Texture' then
			local texture = region:GetTexture()
			if not texture then return end

			if texture:find('Background') or texture:find('Border') or texture:find('AlphaMask') then
					region:SetTexture(nil)
			else
				region:ClearAllPoints()
				region:SetAllPoints(frame)
				region:TrimIcon()
				region:SetDrawLayer('ARTWORK')
				if NewIconTextures[name] then region:SetTexture(NewIconTextures[name]) end
				frame:SetTemplate("TS")
			end
		end
	end
	SkinnedIcons[name] = true
end

--Loops through minimap children to check for icons that need to be skinned, then organizes icons
function MM:SkinIcons()
	for _,child in pairs({Minimap:GetChildren()}) do
		local name = child:GetName()
		if name and child:GetObjectType() == 'Button' and not (BLACKLIST[name] or SkinnedIcons[name]) then
			self:SkinIcon(child)
		end
	end

	self:OrganizeIcons()
end

--Anchors icons to the tray
function MM:OrganizeIcons()
	local prev
	for name,_ in pairs(SkinnedIcons) do
		local frame = _G[name]
		if frame:IsShown() then
			frame:ClearAllPoints()
			if not prev then
				frame:SetPoint('TOP', self.IconTray, 'TOP', 0, 0)
			else
				frame:SetPoint('TOP', prev, 'BOTTOM', 0, 0)
			end
			prev = frame
		end
	end
end

--Create the tray
function MM:InitializeIconTray()
	local iconTray = CreateFrame('frame', 'SaftUI_IconTray', Minimap)
	iconTray:SetPoint('TOPRIGHT', self.Container, 'BOTTOMRIGHT', 0, 0)
	iconTray:SetSize(ICON_SIZE, 1)
	iconTray:Hide()

	local open = CreateFrame('frame', 'SaftUI_IconTrayButton', Minimap)
	iconTray.open = open

	local r, g, b = unpack(st.Saved.profile.Colors.buttonnormal)

	open.icon = open:CreateTexture(nil, 'OVERLAY')
	open.icon:SetTexture(st.TEXTURE_PATHS.cornerbr)
	open.icon:SetVertexColor(r, g, b)
	open.icon:SetAllPoints()

	open:SetSize(16, 16)
	open:SetPoint('BOTTOMRIGHT', Minimap, 'BOTTOMRIGHT', 0, 0)

	open:EnableMouse(true)
	open:SetScript('OnEnter', function(self) self.icon:SetVertexColor(0, 170/255, 1) end)
	open:SetScript('OnLeave', function(self) self.icon:SetVertexColor(r, g, b) end)
	open:SetScript('OnMouseDown', function() ToggleFrame(iconTray) end)

	self.IconTray = iconTray
end

--------------------------------------
--------------------------------------
--------------------------------------


function MM:CleanseMinimap()
	for _,frame in pairs({
		MinimapBorder,
		MinimapBorderTop,
		MinimapZoomIn,
		MinimapZoomOut,
		MiniMapVoiceChatFrame,
		MinimapZoneTextButton,
		TimeManagerClockButton,
		-- MiniMapTracking,
		GameTimeFrame,
	}) do frame:Hide() end

	for _,frame in pairs({
		MinimapCluster,
		MiniMapWorldMapButton,
	}) do frame:Kill() end

	for _,frame in pairs({MiniMapInstanceDifficulty, GuildInstanceDifficulty}) do
		frame:ClearAllPoints()
		frame:SetParent(Minimap)
		frame:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 0, 0)
		frame:SetAlpha(0)
	end

	Minimap:HookScript('OnEnter', function(self)
		MiniMapInstanceDifficulty:SetAlpha(1)
		GuildInstanceDifficulty:SetAlpha(1)
	end)

	Minimap:HookScript('OnLeave', function(self)
		MiniMapInstanceDifficulty:SetAlpha(0)
		GuildInstanceDifficulty:SetAlpha(0)
	end)

	_G['MinimapNorthTag']:SetTexture(nil)
end

function MM:KillClock(event, addon)
	if addon == "Blizzard_TimeManager" then
		TimeManagerClockButton:Kill()
	elseif addon == "Blizzard_FeedbackUI" then
		FeedbackUIButton:Kill()
	end
end

function MM:ADDON_LOADED(event, addon)
	if addon == "Blizzard_TimeManager" then
		TimeManagerClockButton:Kill()
	elseif addon == "Blizzard_FeedbackUI" then
		FeedbackUIButton:Kill()
	else
		self:SkinIcons()
	end
end

function MM:UpdateMinimap()
	local config = st.Saved.profile.Minimap
	local height = st.Saved.profile.Minimap.height > 0 and st.Saved.profile.Minimap.height or config.width

	self.Container:ClearAllPoints()
	self.Container:SetPoint(unpack(config.position))
	self.Container:SetTemplate(config.template)

	self.Container:SetSize(config.width, height)
	Minimap:SetSize(config.width-config.padding*2, height-config.padding*2)
end

function MM:OnInitialize()
	self:CleanseMinimap()

	local container = CreateFrame('frame', 'SaftUI_Minimap', UIParent)
	self.Container = container

	Minimap:SetParent(container)
	Minimap:SetPoint('CENTER')
	Minimap:SetMaskTexture(st.BLANK_TEX)
	Minimap:EnableMouseWheel(true)
	Minimap:SetScript('OnMouseWheel', function(self, delta)
		if delta > 0 then
			MinimapZoomIn:Click()
		else
			MinimapZoomOut:Click()
		end
	end)
	

	-- For others mods with a minimap button, set minimap buttons position in square mode.
	function GetMinimapShape() return "SQUARE" end

	self:InitializeIconTray()
	self:UpdateMinimap()

	self:SkinIcon(GarrisonLandingPageMinimapButton)
	self:SkinMailIcon()
	self:SkinQueueIcon()
	self:SkinTrackingIcon()
	self:RegisterEvent('PLAYER_ENTERING_WORLD','SkinIcons')
	self:RegisterEvent('ADDON_LOADED')
	
	st:GetModule('Config'):AddConfigFrame({
		key = 'minimap',
		label = 'Minimap',
		parent = self.Container,
		group = 'Maps',
		set = function(key, subkey, value) 
			if subkey then
				st.Saved.profile.Minimap[key][subkey] = value
			else
				st.Saved.profile.Minimap[key] = value;
			end

			self:UpdateMinimap() end,
		get = function(key, subkey) return subkey and st.Saved.profile.Minimap[key][subkey] or st.Saved.profile.Minimap[key] end,
		args = {
			{
				key = 'width',
				type = 'input',
				sanitation = function(input) return tonumber(strmatch(input,'%d+')) end,
				label = 'Width',
				width = 0.3,
			},
			{
				key='height',
				type = 'input',
				sanitation = function(input) return tonumber(strmatch(input,'%d+')) end,
				validation = function(input) 
					if input < 0 then
						return 'Height must be zero or positive'
					elseif input > 600 then
						return 'Height must be less than 600'
					end
				end,
				label = 'Height',
				note = 'Set to zero to use width value for height',
				width = 0.3,
			},
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
		}
	})
end