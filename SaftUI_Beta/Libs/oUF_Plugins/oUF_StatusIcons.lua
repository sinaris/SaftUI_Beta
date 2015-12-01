local _, ns = ...
local oUF = ns.oUF or oUF
assert(oUF, 'oUF_AuraBars was unable to locate oUF install.')

--Defaults
local Defaults = {
	['Orientation'] = 'RIGHT',
	['Spacing'] = 6,
	['IconSize'] = 8,
	['enableLeader'] = true,
	['enableMasterLooter'] = true,
	['enableResting'] = true,
	['enableCombat'] = true,
	['enableTapped'] = true,
}
local DefaultOrientation = 'RIGHT'
local DefaultSpacing = 4

local function OppositeDirection(direction)
	return direction == 'LEFT' and 'RIGHT' or
				 direction == 'RIGHT' and 'LEFT' or
				 direction == 'TOP' and 'BOTTOM' or
				 direction == 'BOTTOM' and 'TOP'
end

local function CreateIcon(self, ...)
	local icon = CreateFrame('Frame', nil, self)
	icon:SetSize(self.IconSize, self.IconSize)

	icon.tex = icon:CreateTexture(nil, 'OVERLAY')
	icon.tex:SetAllPoints(icon)
	icon.tex:SetTexture(...)

	if self.PostCreate then	self:PostCreate()	end

	return icon
end

local function Initialize(self)
	-- Note: self refers to unitframe.StatusIcons in this function

	--Give global access to be able to add custom icons
	self.CreateIcon = CreateIcon

	self.Icons = {}

	self.Icons.Leader 			= self:CreateIcon( 1, .6, .3)
	self.Icons.MasterLooter = self:CreateIcon( 1, .9, .3)
	self.Icons.Resting 			= self:CreateIcon( 0, .6,  1)
	self.Icons.Combat  			= self:CreateIcon(.8, .3, .3)
	self.Icons.Tapped  			= self:CreateIcon(.3, .3, .3) --Also used for disconnected

	if self.PostInitialize then self:PostInitalize()	end

	self.Initialized = true
end

local function Update(self, event, ...)
	local unit = self.unit
	local statusicons = self.StatusIcons

	--Reset all icons
	for _,icon in pairs(statusicons.Icons) do
		icon:ClearAllPoints()
		icon:Hide()
	end

	statusicons.shownIcons = {}

	--Leader icon
	if UnitIsGroupLeader(unit) and statusicons.enableLeader then
		tinsert(statusicons.shownIcons, statusicons.Icons.Leader)
	end

	--Resting icon
	if unit == 'player' and IsResting() and statusicons.enableResting then
		tinsert(statusicons.shownIcons, statusicons.Icons.Resting)
	end

	--Tapped/Disconnected icon
	if ( UnitIsTapped(unit) and (not UnitIsTappedByPlayer(unit)) and statusicons.enableTapped ) or
		 ( UnitIsPlayer(unit) and (not UnitIsConnected(unit)) and statusicons.enableDisconnected ) then
			tinsert(statusicons.shownIcons, statusicons.Icons.Tapped)
	end

	--Combat icon
	if UnitAffectingCombat(unit) --[[ and statusicons.enableCombat ]] then
		tinsert(statusicons.shownIcons, statusicons.Icons.Combat)
	end

	--Allows for checking for custom icons
	if statusicons.MidUpdate then
		statusicons:MidUpdate(event, ...)
	end

	--Dont go further if there's no icons to display
	if #statusicons.shownIcons <= 0 then statusicons:Hide() return end

	statusicons:Show()

	--Locals for positioning
	local prev
	local opposite = OppositeDirection(statusicons.Orientation)
	local xOff, yOff = 0,0

	--Vertical Orientation
	if statusicons.Orientation == 'TOP' or statusicons.Orientation == 'BOTTOM' then
		statusicons:SetHeight(#statusicons.shownIcons*statusicons.IconSize + (#statusicons.shownIcons-1)*statusicons.Spacing)
		statusicons:SetWidth(statusicons.IconSize)
		yOff = statusicons.Spacing

	--Horizontal Orientation
	else
		statusicons:SetHeight(statusicons.IconSize)
		statusicons:SetWidth(#statusicons.shownIcons*statusicons.IconSize + (#statusicons.shownIcons-1)*statusicons.Spacing)
		yOff = statusicons.Spacing
	end

	for i,icon in pairs(statusicons.shownIcons) do
		icon:Show()
		if i==1 then
			icon:SetPoint(opposite, statusicons, opposite, xOff, yOff)
		else
			icon:SetPoint(opposite, statusicons, statusicons.Orientation, xOff, yOff)
		end
	end

	if statusicons.PostUpdate then
		statusicons:PostUpdate(event, ...)
	end
end

local function Enable(self)
	local statusicons = self.StatusIcons

	--Fail if StatusIcons is not created
	if not statusicons then return false end

	--Load defaults for missing values
	for key,val in pairs(Defaults) do
		if not statusicons[key] then statusicons[key] = val end
	end

	--Create everything if this is the first time it's being enabled
	if not statusicons.Initialized then Initialize(statusicons) end

	local lastUpdate = 0
	statusicons:SetScript('OnUpdate', function(_, elapsed)
		lastUpdate = lastUpdate + elapsed; 	
		while (lastUpdate > 1) do
			Update(self)
			lastUpdate = lastUpdate - 1;
		end
	end)
	Update(self)

	return true
end

--[[
	Disable function for oUF
]]--
local function Disable(self)
	local SI = self.StatusIcons

	SI:SetScript('OnUpdate', nil)
	SI:Hide()
end

oUF:AddElement('StatusIcons', Update, Enable, Disable)