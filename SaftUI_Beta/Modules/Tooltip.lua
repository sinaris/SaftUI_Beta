local st = SaftUI
local TT = st:NewModule('Tooltip', 'AceHook-3.0', 'AceEvent-3.0')

function TT:UpdateGameTooltipPosition()
	if GameTooltip:GetAnchorType() == 'ANCHOR_NONE' then
		GameTooltip:ClearAllPoints()
		GameTooltip:SetPoint('BOTTOMRIGHT', UIParent, 'BOTTOMRIGHT', -10, 10)
	end
end

function TT:UpdateTooltipDisplay(tooltip)
	local font,size,outline = st.normalFont:GetFont()

	tooltip:SetTemplate('Transparent')

	local name = tooltip:GetName()
	
	for i=1, tooltip:NumLines() do
		local left = _G[format('%sTextLeft%d', name, i)]
		if left then
			left:SetFont(font,size,outline)
		end

		local right = _G[format('%sTextRight%d', name, i)]
		if right then
			right:SetFont(font,size,outline)
		end
	end
end

function TT:OnInitialize()
	GameTooltip._SetHeight = GameTooltip.SetHeight
	GameTooltip.SetHeight = st.dummy

	self:HookScript(GameTooltip, 'OnUpdate', 'UpdateGameTooltipPosition')

	self.AllTooltips = {
		GameTooltip,
		ItemRefTooltip,
		ItemRefShoppingTooltip1,
		ItemRefShoppingTooltip2,
		ItemRefShoppingTooltip3,
		ShoppingTooltip1,
		ShoppingTooltip2,
		ShoppingTooltip3,
		WorldMapTooltip,
		WorldMapCompareTooltip1,
		WorldMapCompareTooltip2,
		WorldMapCompareTooltip3,
	}
	for _,tooltip in pairs(self.AllTooltips) do
		tooltip:SetTemplate('Transparent')
		self:HookScript(tooltip, 'OnShow', 'UpdateTooltipDisplay')
	end
end