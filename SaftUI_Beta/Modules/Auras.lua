local st = SaftUI
local AU = st:NewModule('Auras', 'AceEvent-3.0', 'AceHook-3.0')

BUFF_MAX_DISPLAY = 32
DEBUFF_MAX_DISPLAY = 32
BUFFS_PER_ROW = 16

function AU:SkinAuraButton(button)
	local buttonName = button:GetName()
	button.icon = _G[buttonName..'Icon']
	button.border = _G[buttonName..'Border']

	if button.border then
		button.border:Kill()
	end

	button:CreateBackdrop()
	button.icon:TrimIcon()
	button.icon:SetPoints(button, 1)

	button.count:SetFontObject(st.pixelFont)

	button.duration:SetFontObject(st.pixelFont)
end

function AU:SkinAuras()
	local button

	for i = (#self.Buffs+1), BUFF_MAX_DISPLAY do
		button = _G['BuffButton'..i]
		if not button then break end
		self:SkinAuraButton(button)
		self.Buffs[i] = button
	end

	for i = (#self.Debuffs+1), DEBUFF_MAX_DISPLAY do
		button = _G['BuffButton'..i]
		if not button then break end
		self:SkinAuraButton(button)
		self.Debuffs[i] = button
	end
end

function AU:OnInitialize()
	self.Buffs = {}
	self.Debuffs = {}

	self:SecureHook('AuraButton_Update', 'SkinAuras')	
end