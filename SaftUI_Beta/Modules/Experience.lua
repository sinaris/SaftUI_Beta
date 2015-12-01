local st = SaftUI
local XP = st:NewModule('Experience', 'AceHook-3.0', 'AceEvent-3.0')
local MM = st:GetModule('Minimap')
local SF = st.StringFormat

function XP:SetupBar()
	local container = CreateFrame('frame', 'SaftUI_ExpBar', UIParent)

	local expbar = CreateFrame('StatusBar', nil, container)
	expbar:SetStatusBarTexture(st.BLANK_TEX)
	expbar:SetStatusBarColor(.6, .3, .8)
	expbar:SetFrameLevel(5)
	-- self:HookScript(expbar, 'OnEnter')
	-- self:HookScript(expbar, 'OnLeave')
	container.ExpBar = expbar

	local restbar = CreateFrame('StatusBar', nil, container)
	restbar:SetStatusBarTexture(st.BLANK_TEX)
	restbar:SetStatusBarColor(.3, .6, .8)
	restbar:SetFrameLevel(3)
	restbar:SetAlpha(0.5)
	-- self:HookScript(restbar, 'OnEnter')
	-- self:HookScript(restbar, 'OnLeave')
	container.RestBar = restbar


	self:HookScript(container, 'OnEnter')
	self:HookScript(container, 'OnLeave')

	self.Container = container
	self:UpdateDisplay()
end

function XP:UpdateDisplay()
	local config = st.Saved.profile.Experience
	self.Container:SetPoint(unpack(config.position))
	self.Container:SetSize(config.width, config.height)
	self.Container:SetTemplate(config.template)
	self.Container.ExpBar:SetPoints(config.padding)
	self.Container.RestBar:SetPoints(config.padding)
end

function XP:UpdateExp()
	local expbar = self.Container.ExpBar
	local restbar = self.Container.RestBar

	if MAX_PLAYER_LEVEL ~= UnitLevel('player') then
		if not self.Container:IsShown() then self.Container:Show() end
		
		local current, max = UnitXP('player'), UnitXPMax('player')
		local rest = GetXPExhaustion()

		expbar:SetMinMaxValues(0, max)
		expbar:SetValue(current)

		if rest then
			if not restbar:IsShown() then restbar:Show() end
			restbar:SetMinMaxValues(0, max)
			restbar:SetValue(current+rest)
		elseif restbar:IsShown() then
			restbar:Hide()
		end
	elseif GetWatchedFactionInfo() then
		if not self.Container:IsShown() then self.Container:Show() end

		local name, rank, minRep, maxRep, value = GetWatchedFactionInfo()
		local current = value - minRep
		local max = maxRep - minRep

		expbar:SetMinMaxValues(0, max)
		expbar:SetValue(current)
		
		local c = FACTION_BAR_COLORS[rank]
		expbar:SetStatusBarColor(c.r, c.g, c.b)

		if restbar:IsShown() then restbar:Hide() end
	else
		if self.Container:IsShown() then self.Container:Hide() end
	end
end

function XP:OnEnter()
	local container = self.Container
	if container:GetLeft() > GetScreenWidth()/2 then
		--Right size of screen
		GameTooltip:SetOwner(container, 'ANCHOR_LEFT', -3, -container:GetHeight())
	else
		--Left size of screen
		GameTooltip:SetOwner(container, 'ANCHOR_RIGHT', 3, -container:GetHeight())
	end
	GameTooltip:ClearLines()
	if MAX_PLAYER_LEVEL ~= UnitLevel('player') then
		local current, max = UnitXP('player'), UnitXPMax('player')
		local rest = GetXPExhaustion()

		GameTooltip:AddDoubleLine('Current XP:', format('%s/%s (%s%%)', SF:ShortFormat(current), SF:ShortFormat(max), SF:Round(current/max*100)), nil,nil,nil, 1,1,1)
		GameTooltip:AddDoubleLine('To go:', SF:CommaFormat(max-current), nil,nil,nil, 1,1,1)
		if rest then
			GameTooltip:AddDoubleLine('Rested:', format('%s (%s%%)', SF:CommaFormat(rest), SF:Round(rest/max*100)), nil,nil,nil, 0,.6,1)
		end
	end

	if GetWatchedFactionInfo() then
		--Add a space between exp and rep
		if MAX_PLAYER_LEVEL ~= UnitLevel('player') then GameTooltip:AddLine('  ') end

		local name, rank, minRep, maxRep, value = GetWatchedFactionInfo()
		local current = value - minRep
		local max = maxRep - minRep
		local c = FACTION_BAR_COLORS[rank]

		GameTooltip:AddDoubleLine(name, _G['FACTION_STANDING_LABEL'..rank], nil,nil,nil, c.r, c.g, c.b)
		GameTooltip:AddDoubleLine('Current:', format('%s/%s (%d%%)', SF:ShortFormat(current), SF:ShortFormat(max), SF:Round(current/max*100)), nil,nil,nil, 1,1,1)
		GameTooltip:AddDoubleLine('To go:', SF:CommaFormat(max-current), nil,nil,nil, 1,1,1)

	end
	GameTooltip:Show()
end

function XP:OnLeave()
	st:HideGameTooltip()
end

function XP:OnInitialize()
	self:SetupBar()
	self:UpdateExp()
	
	self:RegisterEvent('PLAYER_LEVEL_UP', 'UpdateExp')
	self:RegisterEvent('UPDATE_EXHAUSTION', 'UpdateExp')
	self:RegisterEvent('CHAT_MSG_COMBAT_FACTION_CHANGE', 'UpdateExp')
	self:RegisterEvent('UPDATE_FACTION', 'UpdateExp')
	self:RegisterEvent('PLAYER_ENTERING_WORLD', 'UpdateExp')
	self:RegisterEvent('PLAYER_XP_UPDATE', 'UpdateExp')
end