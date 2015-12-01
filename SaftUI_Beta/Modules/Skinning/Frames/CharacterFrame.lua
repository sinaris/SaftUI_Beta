local st = SaftUI

local CHARACTER_SLOTS = {
	-- [0] = "Ammo",
	[1] = "Head",
	[2] = "Neck",
	[3] = "Shoulder",
	[4] = "Shirt",
	[5] = "Chest",
	[6] = "Waist",
	[7] = "Legs",
	[8] = "Feet",
	[9] = "Wrist",
	[10] = "Hands",
	[11] = "Finger0",
	[12] = "Finger1",
	[13] = "Trinket0",
	[14] = "Trinket1",
	[15] = "Back",
	[16] = "MainHand",
	[17] = "SecondaryHand",
	-- [18] = "Ranged",
	[19] = "Tabard",
}

local tabWidths = {70, 40, 75, 65} --width of each panel tab (Bottom Left of characterframe)
local function FixTabPosition()
	local prevShown
	for i=1,4 do
		local tab =  _G['CharacterFrameTab' .. i]
		if tab:IsShown() then
			tab:ClearAllPoints()
			if not prevShown then
				tab:SetPoint("BOTTOMLEFT", CharacterFrame, 'BOTTOMLEFT', 10, 0)
			else
				tab:SetPoint('BOTTOMLEFT', prevShown, 'BOTTOMRIGHT', 1, 0)
			end
			tab:SetSize(tabWidths[i], st.TAB_HEIGHT)
			tab:SetTemplate("Button")

			local text = _G['CharacterFrameTab' .. i .. 'Text']
			text:SetFont(SaftUI.pixelFont:GetFont())
			text:SetShadowOffset(0,0)
			text:SetTextColor(1,1,1)
			text:ClearAllPoints()
			text:SetPoint('CENTER')
			tab.deselectedTextX = 0
			tab.deselectedTextY = 0
			tab.selectedTextX = 0
			tab.selectedTextY = 0

			prevShown = tab
		end
	end
end

------------------------------
-- Equiped Item Slots --------
------------------------------
local function SetItemSlotBorderColor(slotID)
	local itemID = GetInventoryItemID("player", slotID)
	local slotFrame = _G['Character'..CHARACTER_SLOTS[slotID]..'Slot']
	if not itemID then slotFrame:SetTemplate() return end

	local name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(itemID)

	if not quality then return end
	
	local r, g, b, hex = GetItemQualityColor(quality)

	slotFrame:SetBackdropBorderColor(r,g,b)
end

local function SkinEquipSlots()
	-- Reposition item slots
	CharacterHeadSlot:ClearAllPoints()
	CharacterHeadSlot:SetPoint('TOPLEFT', CharacterFrame.TitleRegion, 'BOTTOMLEFT', 10, -10)
	
	CharacterHandsSlot:ClearAllPoints()
	CharacterHandsSlot:SetPoint('TOPLEFT', CharacterHeadSlot, 'TOPRIGHT', 4, 0)

	CharacterMainHandSlot:ClearAllPoints()
	CharacterMainHandSlot:SetPoint('TOPRIGHT', CharacterWristSlot, 'BOTTOMRIGHT', 0, -4)

	CharacterSecondaryHandSlot:ClearAllPoints()
	CharacterSecondaryHandSlot:SetPoint('TOPLEFT', CharacterMainHandSlot, 'TOPRIGHT', 4, 0)

	--Now to skil the slots
	for slotID,slotName in pairs(CHARACTER_SLOTS) do
		local slot = _G['Character'..slotName..'Slot']
		
		slot.verticalFlyout = false

		slot:SetTemplate('Button')
		slot.ignoreTexture:SetTexture([[Interface\PaperDollInfoFrame\UI-GearManager-LeaveItem-Transparent]])

		_G['Character'..slotName..'SlotPopoutButton']:Kill()
		_G['Character'..slotName..'SlotIconTexture']:SetPoints(0,0,0,1)
		_G['Character'..slotName..'SlotIconTexture']:SetDrawLayer('OVERLAY')
		_G['Character'..slotName..'SlotIconTexture']:SetTexCoord(unpack(SaftUI.ICON_COORDS))

		slot.slotName = slotName
		slot.slotID = slotID

		SetItemSlotBorderColor(slotID)
	end
end

-- Character Stats Pane
------------------------------
local function FixStatPaneHeight(categoryFrame)
	local categoryInfo = PAPERDOLL_STATCATEGORIES[categoryFrame.Category]
	local i = 1
	repeat
		statFrame = _G[categoryFrame:GetName().."Stat"..i]
		statFrame:SetHeight(13)
		if statFrame.Bg then
			statFrame.Bg:SetPoint("RIGHT", categoryFrame)
			statFrame.Bg:SetPoint("LEFT", categoryFrame)
		end
		statFrame.Label:SetFontObject(SaftUI.pixelFont)
		statFrame.Label:SetShadowOffset(0,0)
		statFrame.Label:ClearAllPoints()
		statFrame.Label:SetPoint('LEFT', 0, 0)
		statFrame.Value:SetFontObject(SaftUI.pixelFont)
		statFrame.Value:SetShadowOffset(0,0)
		statFrame.Value:ClearAllPoints()
		statFrame.Value:SetPoint('RIGHT', 0, 0)
		i=i+1
	until not _G[categoryFrame:GetName().."Stat"..i]
end

local function SkinCharacterStatsPane()
	CharacterStatsPane:ClearAllPoints()
	CharacterStatsPane:SetPoint('TOPLEFT', CharacterHandsSlot, 'TOPRIGHT', 11, 0)

	CharacterStatsPane:SetSize(230,365)
	CharacterStatsPane:SetTemplate()

	CharacterStatsPane:SetParent(PaperDollFrame) --Make sure to hide it when the tab changes

	for i=1, 6 do
		_G['CharacterStatsPaneCategory'..i]:StripTextures()
		_G['CharacterStatsPaneCategory'..i]:SetWidth(210)
		_G['CharacterStatsPaneCategory'..i]:Hide()
	end
	hooksecurefunc('PaperDollFrame_UpdateStatCategory', FixStatPaneHeight)
	CharacterStatsPaneScrollBar:Skin(true)
end

------------------------------
-- Reputation Pane -----------
------------------------------
FACTION_BAR_COLORS = {
	[1] = {r = 0.6, g = 0.3, b = 0.2},
	[2] = {r = 0.6, g = 0.3, b = 0.2},
	[3] = {r = 0.4, g = 0.2, b = 0.1},
	[4] = {r = 0.5, g = 0.5, b = 0.2},
	[5] = {r = 0.0, g = 0.6, b = 0.2},
	[6] = {r = 0.0, g = 0.6, b = 0.2},
	[7] = {r = 0.0, g = 0.6, b = 0.2},
	[8] = {r = 0.2, g = 0.4, b = 0.3},
};

local function UpdateReputationFrame()
	for i=1, NUM_FACTIONS_DISPLAYED do
		local factionIndex = FauxScrollFrame_GetOffset(ReputationListScrollFrame) + i
		local collapseButton = _G["ReputationBar"..i.."ExpandOrCollapseButton"]
	    local factionRow = _G["ReputationBar"..i]
		local factionBar = _G["ReputationBar"..i.."ReputationBar"]
		local factionLFGBonusButton = factionRow.LFGBonusRepButton
        local factionTitle = _G["ReputationBar"..i.."FactionName"]

		local name, description, standingID, barMin, barMax, barValue, atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild, factionID, hasBonusRepGain, canBeLFGBonus = GetFactionInfo(factionIndex)

		factionBar:SetAllPoints(factionRow)
		factionLFGBonusButton:SetPoint("RIGHT", factionBar, "LEFT", -3, 0);

		factionTitle:ClearAllPoints()
		
        if isHeader then
        	factionTitle:SetPoint('LEFT', collapseButton, 'RIGHT', 6, 0)
        	factionRow:SetPoint('LEFT', ReputationListScrollFrame, isChild and 20 or 0, 0)
        else
        	factionTitle:SetPoint('LEFT', factionBar, 'LEFT', 6, 0)
        	factionRow:SetPoint('LEFT', ReputationListScrollFrame, isChild and 40 or 20, 0)
        end

		factionTitle:SetParent(factionBar:IsShown() and factionBar or factionRow) -- bar is hidden for most headers
		
		if factionRow.isCollapsed then
			collapseButton.text:SetText('+')
		else
			collapseButton.text:SetText('-')
		end
	end
end

local function SkinReputationBar(i)
	local factionIndex = FauxScrollFrame_GetOffset(ReputationListScrollFrame) + i
	local factionRow = _G["ReputationBar"..i]
	local factionTitle = _G["ReputationBar"..i.."FactionName"]
	local collapseButton = _G["ReputationBar"..i.."ExpandOrCollapseButton"]
	-- local factionLeftLine = _G["ReputationBar"..i.."LeftLine"]
	-- local factionBottomLine = _G["ReputationBar"..i.."BottomLine"]
	local factionStanding = _G["ReputationBar"..i.."ReputationBarFactionStanding"]
	local factionBackground = _G["ReputationBar"..i.."Background"]
	local factionBar = _G["ReputationBar"..i.."ReputationBar"]
	local factionBonusIcon = factionBar.BonusIcon
	local factionLFGBonusButton = factionRow.LFGBonusRepButton

	factionBonusIcon:ClearAllPoints()
	factionBonusIcon:SetPoint('LEFT', factionTitle, 'RIGHT', 5, 0)

	-- factionLFGBonusButton:SkinCheckBox()
	-- factionLFGBonusButton.Display:SetBackdropBorderColor(.3, .3, .3)

	factionTitle:SetFont(SaftUI.pixelFont:GetFont())
	factionTitle:SetShadowOffset(0,0)
	factionTitle:SetParent(factionBar)
	factionStanding:SetFont(SaftUI.pixelFont:GetFont())
	factionStanding:SetShadowOffset(0,0)

	factionRow:SetTemplate()
	factionRow:SetWidth(ReputationFrame:GetWidth())

	collapseButton:SetNormalTexture('')
	collapseButton.SetNormalTexture = SaftUI.dummy
	collapseButton:SetTemplate('Button')
	collapseButton:ClearAllPoints()
	collapseButton:SetPoint('LEFT', factionRow, 'LEFT', 0, 0)
	collapseButton:SetSize(factionRow:GetHeight(), factionRow:GetHeight())

	collapseButton.text = collapseButton:CreateFontString(nil, 'OVERLAY')
	collapseButton.text:SetFontObject(SaftUI.pixelFont)
	collapseButton.text:SetPoint('CENTER')

	factionStanding:ClearAllPoints()
	factionStanding:SetPoint('RIGHT', -6, 0)

	factionBar:StripTextures()
	factionBar:SetStatusBarTexture(SaftUI.BLANK_TEX)

	factionBackground:Kill()
end

local function SkinReputationFrame()
	ReputationFrame:ClearAllPoints()
	ReputationFrame:SetPoint('TOPLEFT', CharacterFrame.TitleRegion, 'BOTTOMLEFT', 10, -10)
	ReputationFrame:SetSize(CharacterFrame:GetWidth()-20, 365)

	--Temp debugging
	-- ReputationFrame:SetTemplate()
	-- ReputationFrame:SetBackdropColor(1, 0, 0, 0.2)
	-- ReputationListScrollFrame:SetTemplate()
	-- ReputationListScrollFrame:SetBackdropColor(0, 1, 0, 0.2)

	ReputationFrame:StripTextures()
	ReputationListScrollFrame:StripTextures()

	ReputationListScrollFrame:ClearAllPoints()
	ReputationListScrollFrame:SetPoint('TOPLEFT',ReputationFrame, 'TOPLEFT', 0, 0)
	ReputationListScrollFrame:SetSize(ReputationFrame:GetWidth()-19, ReputationFrame:GetHeight())
	ReputationListScrollFrameScrollBar:Skin()

	--These labels are pretty useless
	ReputationFrameFactionLabel:Hide()
	ReputationFrameStandingLabel:Hide()

	--Add a 16th bar now that we have the room
	CreateFrame('frame', 'ReputationBar16', ReputationFrame, 'ReputationBarTemplate'):SetID(16)
	ReputationBar16:SetPoint('TOPRIGHT', ReputationBar15, 'BOTTOMRIGHT', 0, -3)
	NUM_FACTIONS_DISPLAYED = 16

	--Make sure that the first bar is always in the topright corner, and adjust for the scrollbar when needed
	ReputationBar1:SetPoint('TOPRIGHT', ReputationListScrollFrame, 'TOPRIGHT', 0, 0)
	ReputationListScrollFrame:SetScript('OnShow', function(self)
		ReputationBar1:SetPoint('TOPRIGHT', self, 'TOPRIGHT', 0, 0)
	end)

	ReputationListScrollFrame:SetScript('OnHide', function(self)
		ReputationBar1:SetPoint('TOPRIGHT', ReputationFrame, 'TOPRIGHT', 0, 0)
	end)

	for i=1, NUM_FACTIONS_DISPLAYED do
		SkinReputationBar(i)
	end

	UpdateReputationFrame()
end

-- Currency Pane
------------------------------
local function SkinCurrencyPane()

end

-- Main skin function
------------------------------
SaftUI:GetModule('Skinning').FrameSkins.CharacterFrame = function()
	--Hide some blizzard background textures
	for _,frame in pairs({
		CharacterFrame,
		CharacterFrameInset,
		CharacterFrameInsetRight,
		PaperDollFrame,
		PaperDollItemsFrame,
		PaperDollTitlesPane,
		PaperDollEquipmentManagerPane,
		CharacterStatsPane,
	}) do frame:StripTextures() end


	CharacterFrame:SetTemplate("Transparent")
	CHARACTERFRAME_EXPANDED_WIDTH = PANEL_DEFAULT_WIDTH
	CharacterFrame:SetSize(PANEL_DEFAULT_WIDTH, SaftUI.UI_PANEL_HEIGHT)

	CharacterFramePortrait:Hide()
	CharacterLevelText:Hide()

	CharacterFrame:CreateHeader(CharacterFrameCloseButton, CharacterFrameTitleText)

	CharacterModelFrame:Kill()

	--Since portrait is becoming a tab, we're gonna have it always collapsed but showing the info as if it was expanded
	hooksecurefunc('CharacterFrame_Collapse', CharacterFrame_Expand)
	CharacterFrame_Expand() --Make sure the frame is actually expanded to begin with
	CharacterFrameExpandButton:Kill()


	SkinEquipSlots()
	hooksecurefunc('CharacterFrame_TabBoundsCheck', FixTabPosition) -- Make sure to always keep bottom tabs(character/pet/reputation/currency) positioned and skinned properly


	SkinCharacterStatsPane()
	SkinReputationFrame()
		hooksecurefunc('ReputationFrame_Update', UpdateReputationFrame)
	SkinCurrencyPane()
end