local SK = SaftUI:GetModule('Skinning')

---------------------------------------------
-- GarrisonBuildingFrame --------------------
---------------------------------------------

local buildingListIndex = 1 --Keeps a counter of which BuildingList Item was last skinned
local function GarrisonBuildlingList_FixTabs(selectedTab)
	for i=1, GARRISON_NUM_BUILDING_SIZES do
		local tab = GarrisonBuildingFrame.BuildingList['Tab'..i]
		tab:SetNormalTexture('')
	end

	local list_width = GarrisonBuildingFrame.BuildingList:GetWidth()-2

	while GarrisonBuildingFrame.BuildingList.Buttons[buildingListIndex] do
		local button = GarrisonBuildingFrame.BuildingList.Buttons[buildingListIndex]

		button:ClearAllPoints()
		if buildingListIndex == 1 then
			button:SetPoint('TOPLEFT', GarrisonBuildingFrame.BuildingList.Tab1, 'BOTTOMLEFT', 0, -1)
		else
			button:SetPoint('TOPLEFT', GarrisonBuildingFrame.BuildingList.Buttons[buildingListIndex-1], 'BOTTOMLEFT', 0, -1)
		end

		button:SetSize(list_width, 40)

		button.BG:SetTexture(nil)
		button.SelectedBG:SetTexture(nil)
		button.Plans:SetDesaturated(true)

		button:SetTemplate('Button', true)

		local id, name, texPrefix, icon, description, rank, currencyID, currencyQty, buildTime, needsPlan, possSpecs, upgrades, canUpgrade, isMaxLevel, hasFollowerSlot = C_Garrison.GetBuildingInfo(button.info.buildingID)

		button.Icon:TrimIcon()
		button.Icon.Backdrop = button:CreateTexture(nil, 'BACKGROUND')
		button.Icon.Backdrop:SetPoints(button.Icon, -1)
		button.Icon.Backdrop:SetTexture(0, 0, 0)
		button.Icon:SetSize(30, 30)
		button.Icon:ClearAllPoints()
		button.Icon:SetPoint('LEFT', 5, 0)
		
		button.Name:SetFontObject(SaftUI.pixelFont)
		button.Name:ClearAllPoints()
		button.Name:SetPoint('LEFT', button.Icon, 'RIGHT', 10, 0)

		buildingListIndex = buildingListIndex + 1
	end
end

local function SkinGarrisonBuildingFrame()
	local self = GarrisonBuildingFrame

	self:SetTemplate('Transparent')
	self.TitleRegion = self:CreateHeader()

	self.BuildingList:SetTemplate()
	self.BuildingList:ClearAllPoints()
	self.BuildingList:SetPoint('TOPLEFT', self.TitleRegion, 'BOTTOMLEFT', 10, -10)

	self.BuildingList.MaterialFrame:Kill() -- There's no need for this since your garrison material count is always displayed at the top of your screen
	
	self.TownHallBox:SetTemplate('Button', true)

	-- Skin BuildingList Tabs
	for i=1, GARRISON_NUM_BUILDING_SIZES do
		local tab = self.BuildingList['Tab'..i]

		tab:SetTemplate('Button')
		tab:SetHeight(20)
		tab:SetWidth((self.BuildingList:GetWidth()-4)/3)

		tab:ClearAllPoints()
		if i == 1 then
			tab:SetPoint('TOPLEFT', self.BuildingList, 'TOPLEFT', 1, -1)
		else
			tab:SetPoint('BOTTOMLEFT', self.BuildingList['Tab'..(i-1)], 'BOTTOMRIGHT', 1, 0)
		end

		tab.Text:ClearAllPoints()
		tab.Text:SetPoint('CENTER')
		tab.Text:SetFontObject(SaftUI.pixelFont)
	end

	for i,region in pairs({self.BuildingList.MaterialFrame:GetRegions()}) do
		if region:GetObjectType() == 'FontString' and region ~= self.BuildingList.MaterialFrame.Materials then
			print(i)
		end
	end

	hooksecurefunc('GarrisonBuildingList_SelectTab', GarrisonBuildlingList_FixTabs)
end

---------------------------------------------
-- INITIALIZE -------------------------------
---------------------------------------------

SK.AddonSkins.Blizzard_GarrisonUI = function()
	SkinGarrisonBuildingFrame()
end