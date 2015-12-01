local st = SaftUI
local SK = st:GetModule('Skinning')

SK.AddonSkins.Blizzard_ItemAlterationUI = function()
	EQUIPMENTFLYOUT_MAXROWS = 6
	EQUIPMENTFLYOUT_ITEMS_PER_ROW = 5
	EQUIPMENTFLYOUT_ITEMS_PER_PAGE = EQUIPMENTFLYOUT_MAXROWS * EQUIPMENTFLYOUT_ITEMS_PER_ROW
	
	local BUTTON_SIZE = 32
	local BUTTON_SPACING = 1

	TransmogrifyArtFrame:Kill()

	TransmogrifyApplyButton:SetParent(TransmogrifyFrame)
	TransmogrifyApplyButton:ClearAllPoints()
	TransmogrifyApplyButton:SetPoint('BOTTOMLEFT')
	TransmogrifyApplyButton:SetPoint('BOTTOMRIGHT')
	TransmogrifyApplyButton:SetHeight(24)
	TransmogrifyApplyButton:SetTemplate("Button")

	TransmogrifyFrameButtonFrame:Kill()
	TransmogrifyModelFrameControlFrame:Kill()

	TransmogrifyFrame:SetTemplate('Transparent')
	TransmogrifyFrame:CreateHeader(TransmogrifyArtFrameCloseButton, TransmogrifyArtFrameTitleText)
	TransmogrifyFrame:SetSize(PANEL_DEFAULT_WIDTH, SaftUI.UI_PANEL_HEIGHT)

	local buttonFrame = EquipmentFlyoutFrame.buttonFrame

	buttonFrame.CloseButton = buttonFrame:CreateCloseButton()
	buttonFrame.CloseButton:SetScript('OnClick', TransmogrifyFrame_CloseFlyout)
	buttonFrame.Title = buttonFrame:CreateFontString(nil, 'OVERLAY')
	buttonFrame:CreateHeader() -- BUG: For some reason the header texture is not showing

	local slots = { "Head", "Shoulder", "Back", "Chest", "Wrist", "Feet",
		"Legs", "Waist", "Hands", "MainHand", "SecondaryHand" }

	local prev
	for _,slotName in pairs(slots) do
		local slot = _G["TransmogrifyFrame"..slotName.."Slot"]
		slot:SetTemplate('ActionButton')
		slot:ClearAllPoints()
		slot:SetSize(BUTTON_SIZE, BUTTON_SIZE)
		slot.verticalFlyout = nil
		if not prev then
			slot:SetPoint('TOPRIGHT', TransmogrifyFrame.TitleRegion, 'BOTTOMRIGHT', -10, -10)
		else
			slot:SetPoint('TOP', prev, 'BOTTOM', 0, -BUTTON_SPACING)
		end

		slot.popoutButton:SetSize(BUTTON_SIZE/2, BUTTON_SIZE)
		slot.popoutButton:SetTemplate('Button')
		slot.popoutButton:ClearAllPoints()
		slot.popoutButton:SetPoint("RIGHT", slot, "RIGHT", 0, 0);
		
		slot.popoutButton.Text = slot.popoutButton:CreateFontString(nil, 'OVERLAY')
		slot.popoutButton.Text:SetFontObject(st.pixelFont)
		slot.popoutButton.Text:SetPoint('CENTER', 1, 0)
		slot.popoutButton.Text:SetText('>')

		prev = slot
	end
	
	TransmogrifyModelFrame:StripTextures()
	TransmogrifyModelFrame:SetTemplate('Button')
	TransmogrifyModelFrame:ClearAllPoints()
	TransmogrifyModelFrame:SetPoint('TOPLEFT', TransmogrifyFrame.TitleRegion, 'BOTTOMLEFT', 10, -10)
	TransmogrifyModelFrame:SetPoint('BOTTOMRIGHT', prev, 'BOTTOMLEFT', -10, 0)

	-- Adjust the button position and skin it when it's created
	local prev, prevRow
	hooksecurefunc('EquipmentFlyout_CreateButton', function()
		local buttons = EquipmentFlyoutFrame.buttons;
		local buttonIndex = #buttons;
		local button = buttons[buttonIndex]
		local buttonName = button:GetName()

		button.icon = _G[buttonName..'IconTexture']

		button:SetTemplate('ActionButton', true)
		button:ClearAllPoints()
		button:SetSize(BUTTON_SIZE, BUTTON_SIZE)


		if prev then
			if buttonIndex % EQUIPMENTFLYOUT_ITEMS_PER_ROW == 1 then
				button:SetPoint('TOP', prevRow, 'BOTTOM', 0, -BUTTON_SPACING)
				prevRow = button
			else
				button:SetPoint('LEFT', prev, 'RIGHT', BUTTON_SPACING, 0)
			end

		else
			button:SetPoint('TOPLEFT', EquipmentFlyoutFrame.buttonFrame.TitleRegion, 'BOTTOMLEFT', 10, -10)
			prevRow = button
		end
		prev = button
	end)

	EquipmentFlyoutFrame.buttonFrame.ScrollOverlay = CreateFrame('Frame', nil, EquipmentFlyoutFrame.buttonFrame)
	EquipmentFlyoutFrame.buttonFrame.ScrollOverlay:SetAllPoints()
	EquipmentFlyoutFrame.buttonFrame.ScrollOverlay:SetScript('OnMouseWheel', function(self, delta)
		EquipmentFlyout_ChangePage(-delta)
	end)

	EquipmentFlyoutFrame.NavigationFrame:Kill()
	-- EquipmentFlyout_UpdateItems does not need to be run every frame..
	EquipmentFlyoutFrame:SetScript('OnUpdate', nil)
	hooksecurefunc('EquipmentFlyout_UpdateItems', function()
		local flyout = EquipmentFlyoutFrame; --The button that hovers over the equipment slot
		local buttonFrame = flyout.buttonFrame -- Holds the buttons
		local itemButton = flyout.button; -- actual equipment slot

		local itemButtonName = itemButton:GetName()
		-- Only modify this position for the transmog frame
		if strfind(itemButtonName, 'Transmogrify') then
			buttonFrame:SetTemplate('Transparent')
			buttonFrame:ClearAllPoints()
			buttonFrame:SetPoint('TOPLEFT', TransmogrifyFrame, 'TOPRIGHT', 5, 0)
			buttonFrame:SetWidth(EQUIPMENTFLYOUT_ITEMS_PER_ROW * (BUTTON_SIZE+1) + 19)

			local numRows = min(ceil(EquipmentFlyoutFrame.totalItems/EQUIPMENTFLYOUT_ITEMS_PER_ROW), EQUIPMENTFLYOUT_MAXROWS)

			buttonFrame:SetHeight(numRows*BUTTON_SIZE + (numRows-1)*BUTTON_SPACING + 25 + buttonFrame.TitleRegion:GetHeight())
			
			-- This pulls the localized global string from GlobalStrings.lua
			local slotName = _G[strupper(strmatch(itemButtonName, 'TransmogrifyFrame(%a+)'))]
			buttonFrame.Title:SetText(slotName)
		end
	end)
end
