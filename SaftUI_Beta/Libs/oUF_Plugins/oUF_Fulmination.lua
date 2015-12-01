local _, ns = ...
local oUF = ns.oUF or oUF
assert(oUF, 'oUF_Fulmination was unable to locate oUF install.')

local function Update(self, event, unit)
	local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId = UnitBuff('player', 'Lightning Shield')
 
	for i=1, 6 do
		if i >= (count or 0) then
			self.Fulmination[i]:Hide()
		else
			self.Fulmination[i]:Show()
		end
	end
end

local function Enable(self)
	if not (select(2, UnitClass('player')) == 'SHAMAN' and self.Fulmination) then return end

	Update(self, 'UNIT_AURA', self.unit)
	self:RegisterEvent('UNIT_AURA', Update)
end

local function Disable(self)
    self:UnregisterEvent('UNIT_AURA', Update)
end

oUF:AddElement('Fulmination', Update, Enable, Disable)