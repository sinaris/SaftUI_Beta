local SK = SaftUI:NewModule('Skinning', 'AceHook-3.0', 'AceEvent-3.0')

SK.AddonSkins = {}
SK.FrameSkins = {}

function SK:SkinAddon(event, addon)
	if self.AddonSkins[addon] then
		self.AddonSkins[addon]()
	end
end

function SK:SkinFrames()
	for frameName, func in pairs(self.FrameSkins) do func(_G[frameName]) end

	for i=1, GetNumAddOns() do
		addon = GetAddOnInfo(i)
		local loaded = IsAddOnLoaded(addon)
		if self.AddonSkins[addon] and loaded then
			self.AddonSkins[addon]()
		end
	end
	
	self:UnregisterEvent('PLAYER_ENTERING_WORLD') --Make sure this only runs once
end

function SK:OnInitialize()
	SK:RegisterEvent('ADDON_LOADED', 'SkinAddon')
	SK:RegisterEvent('PLAYER_ENTERING_WORLD', 'SkinFrames')
end