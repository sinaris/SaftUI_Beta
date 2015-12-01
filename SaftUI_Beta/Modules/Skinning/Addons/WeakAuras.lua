local SK = SaftUI:GetModule('Skinning')

local function SkinIcon(parent, region, data)
	if not region.backdrop then
		region:CreateBackdrop(nil, -1)
		-- hooksecurefunc(region.icon, 'SetAlpha', function(self, ...) selS.backdrop:SetAlpha(...) end)
		region.icon:TrimIcon()
		region.icon.SetTexCoord = SaftUI.dummy
		region.stacks:SetFontObject(SaftUI.pixelFont)
	end
end

---------------------------------------------
-- INITIALIZE -------------------------------
---------------------------------------------

SK.AddonSkins.WeakAuras = function()
	hooksecurefunc(WeakAuras.regionTypes.icon, 'modify', SkinIcon)	
end