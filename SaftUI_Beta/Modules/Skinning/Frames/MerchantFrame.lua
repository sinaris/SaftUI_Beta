local st = SaftUI

local ITEM_HEIGHT = 30
MERCHANT_ITEMS_PER_PAGE = 11

REQUIRES = ITEM_REQ_SKILL:gsub('%%s', '')

-- Used for parsing items
local tooltip = CreateFrame("GameTooltip", "SaftUI_MerchantTooltip", UIParent, "GameTooltipTemplate")
tooltip:SetOwner(UIParent, 'ANCHOR_NONE')

local function GetItemSubString(link)
	-- ITEM_REQ_REPUTATION

	tooltip:SetHyperlink(link)

	local line,linetext,r,g,b
	-- Merge the entire tooltip into one string
	for _,side in pairs({'Left', 'Right'}) do
		for i=2, tooltip:NumLines() do
			line = _G["SaftUI_MerchantTooltipText"..side..i]
			r,g,b = line:GetTextColor()
			linetext = line:GetText() or ''

			-- error is found
			if ( line and r >= 0.9 and g <= 0.2 and b <= 0.2 and left ~= RETRIEVING_ITEM_INFO ) then
				return format('|cff%s%s|r', st.DIFFICULTY_COLORS_HEX.RED, linetext:gsub(REQUIRES, ''):trim())
			end
		end
	end

	return 'nothing'

end

-- Skins and positions list items used for vendor and buyback
local function SkinListItem(self)
	local name = self:GetName()

	self.ID = tonumber(strmatch(name, '%d+'))
	self.ItemButton = _G[name..'ItemButton']
	self.ItemCount = _G[name..'ItemButtonCount']
	self.ItemName = _G[name..'Name']
	-- self.MoneyFrame = _G[name..'MoneyFrame']
	self.AltCurrencyFrame = _G[name..'AltCurrencyFrame']

	self:SetTemplate('Button')
	self:SetHeight(ITEM_HEIGHT)
	self:SetWidth(MerchantFrameInset:GetWidth()-2)

	 _G[name..'MoneyFrame']:Kill()

	self.ItemButton:SetTemplate('ActionButton')
	self.ItemButton:SetSize(ITEM_HEIGHT-4, ITEM_HEIGHT-4)
	self.ItemButton:ClearAllPoints()
	self.ItemButton:SetPoint('LEFT', self, 2, 0)
	self.ItemButton.icon:TrimIcon()
	
	self.ItemName:SetFontObject(st.pixelFont)
	self.ItemName:ClearAllPoints()
	self.ItemName:SetPoint('BOTTOMLEFT', self.ItemButton, 'RIGHT', 10, 1)
	self.ItemName:SetPoint('RIGHT', self, 'RIGHT', -10, 0)
	self.ItemName:SetJustifyV('BOTTOM')
	self.ItemName:SetHeight(ITEM_HEIGHT/2)

	self.ItemType = self:CreateFontString(nil, 'OVERLAY')
	self.ItemType:SetFontObject(SaftUI.pixelFont)
	self.ItemType:SetPoint('TOPLEFT', self.ItemButton, 'RIGHT', 10, -2)
	self.ItemType:SetJustifyV('TOP')
	self.ItemType:SetText("--")
	self.ItemType:SetTextColor(.6,.6,.6,1)
	self.ItemType:SetHeight(ITEM_HEIGHT/2)

	self.ItemCost = self:CreateFontString(nil, 'OVERLAY')
	self.ItemCost:SetFontObject(SaftUI.pixelFont)
	self.ItemCost:SetPoint('TOPRIGHT', self, 'RIGHT', -10, -2)
	self.ItemCost:SetJustifyV('TOP')
	self.ItemCost:SetText(st:GetGoldString())
	self.ItemCost:SetHeight(ITEM_HEIGHT/2)

	self.AltCurrencyFrame.Items = {}
	self.AltCurrencyFrame:SetHeight(ITEM_HEIGHT/2)
	for i=1, 3 do
		local item = _G[name..'AltCurrencyFrameItem'..i]
		item:SetNormalFontObject(st.pixelFont)
		item.Text = _G[name..'AltCurrencyFrameItem'..i..'Text']
		item.Texture = _G[name..'AltCurrencyFrameItem'..i..'Texture']

		item.Texture:TrimIcon()
		item.Texture.Backdrop = item:CreateTexture(nil, 'BACKGROUND')
		item.Texture.Backdrop:SetTexture(0, 0, 0)
		item.Texture.Backdrop:SetPoints(item.Texture, -1)

		self.AltCurrencyFrame.Items[i] = item

	end

	self.ItemCount:ClearAllPoints()
	self.ItemCount:SetPoint('BOTTOMRIGHT', -2, 2)
	self.ItemCount:SetJustifyV('BOTTOM')
	self.ItemCount:SetJustifyH('RIGHT')
	self.ItemCount:SetFontObject(st.pixelFont)
end

-- Hook to MerchantFrame_Update to keep list items properly positioned and to hide unused list items
local function UpdateListItemPositions()
	local maxItems = MerchantFrame.selectedTab == 1 and MERCHANT_ITEMS_PER_PAGE or BUYBACK_ITEMS_PER_PAGE
	local numItems = MerchantFrame.selectedTab == 1 and GetMerchantNumItems() or GetNumBuybackItems()

	FauxScrollFrame_Update(MerchantFrame.ScrollFrame, numItems, maxItems, ITEM_HEIGHT)

	local itemWidth = MerchantFrameInset:GetWidth() - (numItems > maxItems and 20 or 2)
	for i=1,maxItems do
		local button = MerchantFrame.ListItems[i]
		if i > numItems then
			button:Hide()
		else
			button:SetWidth(itemWidth)
			button:Show()

			button:ClearAllPoints()
			if button.ID == 1 then
				button:SetPoint('TOPLEFT', MerchantFrameInset, 1, -1)
			else
				button:SetPoint('TOPLEFT', MerchantFrame.ListItems[button.ID-1], 'BOTTOMLEFT', 0, -1)
			end
		end
	end
end

-- Since we're using faux scrolling instead of pages, we need to update the items based on the scroll offset now
local function UpdateVendorItems()
		local numItems = GetMerchantNumItems()

	for i=1,MERCHANT_ITEMS_PER_PAGE do
		local listItem = MerchantFrame.ListItems[i]
		
		if numItems >= i then
			local index = i+MerchantFrame.ScrollFrame.offset
			local name, texture, price, stackCount, numAvailable, isUsable, extendedCost = GetMerchantItemInfo(index)
			local link = GetMerchantItemLink(index)
			if link then 

				if ( index <= numItems ) then
					-- local name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(GetMerchantItemLink(index)) 
					local _, _, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, _, _ = GetItemInfo(GetMerchantItemLink(index)) 
					
					_G["MerchantItem"..i.."Name"]:SetText(name);
					SetItemButtonCount(listItem.ItemButton, stackCount);
					SetItemButtonStock(listItem.ItemButton, numAvailable);
					SetItemButtonTexture(listItem.ItemButton, texture);

					listItem.ItemButton.name = name
					listItem.ItemButton.link = link
					listItem.ItemButton.texture = texture;

					listItem.ItemButton.hasItem = true;
					listItem.ItemButton:SetID(index);
					listItem.ItemButton:Show();
					
					listItem.ItemType:SetText(GetItemSubString(link))

					if price then
						listItem.ItemCost:SetText(st:GetGoldString(price))
						listItem.ItemCost:Show()
					else
						listItem.ItemCost:SetText('')
						listItem.ItemCost:Hide()
					end

					if extendedCost then
						MerchantFrame_UpdateAltCurrency(index, i);

						listItem.AltCurrencyFrame:ClearAllPoints()
						listItem.AltCurrencyFrame:SetPoint('TOPRIGHT', listItem, 'RIGHT', -5, 1)


						local prev
						for _,item in pairs(listItem.AltCurrencyFrame.Items) do
							item.Texture:ClearAllPoints()
							item.Texture:SetPoint('RIGHT', item, 0, 0)
							item.Texture:SetSize(9, 9)
							item.Text:ClearAllPoints()
							item.Text:SetPoint('LEFT', item)
							item:SetWidth(item.Text:GetStringWidth() + 9)
							item:ClearAllPoints()
							if prev then 
								item:SetPoint('RIGHT', prev, 'LEFT', -5, 0)
							else
								item:SetPoint('RIGHT', listItem.AltCurrencyFrame, 'RIGHT', 0, 0)
							end
							prev = item
						end
					end

				else
					listItem.ItemButton.price = nil;
					listItem.ItemButton.hasItem = nil;
					listItem.ItemButton.name = nil;
					listItem.ItemButton:Hide();
					SetItemButtonNameFrameVertexColor(listItem, 0.5, 0.5, 0.5);
					SetItemButtonSlotVertexColor(listItem,0.4, 0.4, 0.4);
					_G["MerchantItem"..i.."Name"]:SetText("");
				end

				listItem:SetID(index) --PickupMerchantItem uses thssssdis
			end
		else
			listItem:Hide()
		end
	end
end

local function UpdateBuybackItems()

end

st:GetModule('Skinning').FrameSkins.MerchantFrame = function()
	MerchantFrame:SetSize(PANEL_DEFAULT_WIDTH, SaftUI.UI_PANEL_HEIGHT)
	MerchantFrame:SetTemplate('Transparent')
	MerchantFrame:CreateHeader()

	MerchantFrameInset:SetTemplate()
	MerchantFrameInset:ClearAllPoints()
	MerchantFrameInset:SetPoint('TOPLEFT', MerchantFrame.TitleRegion, 'BOTTOMLEFT', st.UI_PANEL_PADDING, -st.UI_PANEL_PADDING)
	MerchantFrameInset:SetWidth(PANEL_DEFAULT_WIDTH-st.UI_PANEL_PADDING*2)
	MerchantFrameInset:SetHeight(MERCHANT_ITEMS_PER_PAGE*(ITEM_HEIGHT+1))

	MerchantFrame.ScrollFrame = CreateFrame('ScrollFrame', 'MerchantFrameFauxScrollFrame', MerchantFrame, 'FauxScrollFrameTemplate')
	MerchantFrame.ScrollFrame:SetAllPoints(MerchantFrameInset)
	MerchantFrame.ScrollFrame:SetScript('OnVerticalScroll', function(self, offset)
		-- self:SetValue(offset)
		self.offset = math.floor(offset / ITEM_HEIGHT + 0.5)
		if MerchantFrame.selectedTab == 1 then
			UpdateVendorItems()
		else
			UpdateBuybackItems()
		end
	end)
	MerchantFrame:SetScript('OnShow', function(self)
		self.ScrollFrame.offset = 0
		self.ScrollFrame:SetVerticalScroll(0)
		self.ScrollFrame.ScrollBar:SetValue(0)
		
	end)

	MerchantFrame.ScrollFrame.ScrollBar = MerchantFrameFauxScrollFrameScrollBar
	MerchantFrame.ScrollFrame.ScrollBar:Skin(true)

	MerchantFramePortrait:Kill()
	MerchantNameText:SetFontObject(st.pixelFont)

	-- Don't need these anymore since we're going to a scroll frame
	MerchantPageText:Kill()
	MerchantPrevPageButton:Kill()
	MerchantNextPageButton:Kill()
	MerchantExtraCurrencyBg:Kill()
	MerchantExtraCurrencyInset:Kill()
	MerchantMoneyBg:Kill()
	MerchantMoneyInset:Kill()
	MerchantBuyBackItem:Kill()
	MerchantBuyBackItemMoneyFrame:Kill()

	MerchantFrame.ListItems = {}
	-- Store and skin the original buttons
	for i=1,12 do
		MerchantFrame.ListItems[i] = _G['MerchantItem'..i]
		SkinListItem(MerchantFrame.ListItems[i])
	end

	MerchantFrameLootFilter:SkinDropDown()
	MerchantFrameLootFilter:SetBackdrop(nil)
	MerchantFrameLootFilter:ClearAllPoints()
	MerchantFrameLootFilter:SetPoint('TOPLEFT', MerchantFrame.TitleRegion)
	MerchantFrameLootFilter:SetPoint('BOTTOMLEFT', MerchantFrame.TitleRegion)
	MerchantFrameLootFilter:SetWidth(100)
	MerchantFrameLootFilterText:SetJustifyH('LEFT')

	-----------------------------------
	-- TEMPORARILY KILL NON-LIST ITEMS
	-----------------------------------

	MerchantRepairText:Kill()
	MerchantRepairAllButton:Kill()
	MerchantRepairItemButton:Kill()
	MerchantGuildBankRepairButton:Kill()
	MerchantMoneyFrame:Kill()
	

	-----------------------------------
	-- END TEMP CODE
	-----------------------------------

	hooksecurefunc('MerchantFrame_Update', UpdateListItemPositions)
	hooksecurefunc('MerchantFrame_UpdateMerchantInfo', UpdateVendorItems)
	hooksecurefunc('MerchantFrame_UpdateBuybackInfo', UpdateBuybackItems)
end