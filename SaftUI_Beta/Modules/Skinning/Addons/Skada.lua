local SK = SaftUI:GetModule('Skinning')

local function SkinWindow(self, window)
	window.bargroup:SetTemplate('Transparent')
	window.bargroup.button:SetTemplate('Transparent') --Title bar
end

function SizeWindow(self, callback, bargroup)
	local height = floor(bargroup:GetHeight()+0.5)
	local remove = floor(height%(bargroup.win.db.barheight + bargroup.win.db.barspacing)+0.5)

	print(height, remove)
	bargroup:SetHeight(height-remove)

	bargroup.win.db.background.height = height-remove
	bargroup.win.db.barwidth = bargroup:GetWidth()
end

---------------------------------------------
-- INITIALIZE -------------------------------
---------------------------------------------

SK.AddonSkins.Skada = function()
	hooksecurefunc(Skada.displays.bar, 'ApplySettings', SkinWindow)
	hooksecurefunc(Skada.displays.bar, 'WindowResized', SizeWindow)
end