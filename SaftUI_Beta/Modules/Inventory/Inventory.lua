local st = SaftUI
local INV = st:NewModule('Inventory', 'AceHook-3.0', 'AceEvent-3.0')
local LIS = LibStub('LibItemSearch-1.2')

local BACKPACK_IDS = {0, 1, 2, 3, 4}
local BANK_IDS = {-1, 5, 6, 7, 8, 9, 10, 11}

local SHOW_BAG_SLOTS = true -- TEMPORARY BOOL

local CATEGORY_TITLE_HEIGHT = 14

local CATEGORY_FILTERS = {
	['Armor & Weapons']	= function(name,link,quality,iLevel,reqLevel,class,subclass,equipSlot) return class == 'Weapon' or class == 'Armor' end,
	['Consumables']		= function(name,link,quality,iLevel,reqLevel,class,subclass,equipSlot) return class == 'Consumable' end,
	['Trade Goods']		= function(name,link,quality,iLevel,reqLevel,class,subclass,equipSlot) return class == 'Trade Goods' or class == 'Gem' end,
	['Quest']			= function(name,link,quality,iLevel,reqLevel,class,subclass,equipSlot) return class == 'Quest' end,
}

--------------------------------------
-- INFORMATION FUNCTIONS -------------
--------------------------------------
function INV:GetNumContainerSlots(containerType)
	local empty, total = 0, 0
	if strupper(containerType or '') == 'REAGENT' then
		return ReagentBankFrame.size, ReagentBankFrame.size
	else
		for _,bagID in pairs(strlower(containerType or '') == 'bank' and BANK_IDS or BACKPACK_IDS) do
			empty = empty + GetContainerNumFreeSlots(bagID)
			total = total + GetContainerNumSlots(bagID)
		end
	end

	return empty, total
end

-- local container, isBank, isReagent = INV:GetContainer(containerType)
function INV:GetContainer(containerType)
	containerType = strupper(containerType or '')
	local isBank, isReagent = containerType == 'BANK',  containerType == 'REAGENT'

	local container = isBank and self.Bank or isReagent and self.ReagentBank or self.Bags

	return container, isBank,  isReagent
end

--------------------------------------
-- SLOT FUNCTIONS --------------------
--------------------------------------

function INV:ClearSlot(slot)
	slot:Hide()
	slot.slotID = nil
	slot.bagID = nil
	slot.texture = nil
	slot.count = nil
	slot.name = nil
	slot.rarity = nil
	slot.locked = nil
	slot.link = nil
	slot.sortString = nil
end

--[[
slotInfo should contain the following:
	bagID, slotID, sortString, clink, texture, count, locked
]]--
function INV:AssignSlot(slot, slotInfo)
	local name, _, rarity, ilvl, reqlvl, category, subcategory = GetItemInfo(slotInfo.clink)

	--Don't update buttons for no reason
	if texture == slot.texture and slot.count == count and slot.rarity == rarity and slot.locked == locked then return end

	slot:SetParent(self.Containers[slotInfo.bagID])
	slot:SetID(slotInfo.slotID)
	slot.slotID = slotInfo.slotID
	slot.bagID = slotInfo.bagID
	slot.texture = texture
	slot.count = count
	slot.name = name
	slot.rarity = rarity
	slot.locked = locked
	slot.link = slotInfo.clink
	slot.sortString = name and (rarity .. (ilvl or 0) .. name .. category .. subcategory .. (count or 0)) or ''

	if not slot.locked and slot.rarity then
		if slot.rarity > 1 then
			slot:SetBackdropBorderColor(GetItemQualityColor(slot.rarity))
		else
			slot:SetBackdropBorderColor(0, 0, 0)
		end
	end

	SetItemButtonTexture(slot, slotInfo.texture)
	SetItemButtonCount(slot, slotInfo.count)
	SetItemButtonDesaturated(slot, slotInfo.locked, 0.5, 0.5, 0.5)

	slot:Show()
end

function INV:CreateSlot(containerType, category)
	local container, isBank, isReagent = INV:GetContainer(containerType)
	local slotID = getn(isReagent and container.Slots or container.Categories[category].Slots)+1
	local slot
	local config = st.Saved.profile.Inventory
	if isReagent then
		if slotID == 1 then
			slot:SetPoint('TOPLEFT', container, 'TOPLEFT', 0, -CATEGORY_TITLE_HEIGHT)
		elseif slotID % config.buttonsperrow==1 then
			slot:SetPoint('TOP', container.Slots[slotID-config.buttonsperrow], 'BOTTOM', 0, -config.buttonspacing)
		else
			slot:SetPoint('LEFT', container.Slots[slotID-1], 'RIGHT', config.buttonspacing, 0)
		end
	else
		assert(container.Categories[category], 'Category "'..category..'" does not exist')
		slot = CreateFrame('Button', 'SaftUI_'..(isBank and 'Bank' or 'Bags')..(gsub(category, '(%A)', ''))..'Slot'..slotID, self[isBank and 'Bank' or 'Bags'].Categories[category], 'ContainerFrameItemButtonTemplate')
		
		if slotID == 1 then
			slot:SetPoint('TOPLEFT', container.Categories[category], 'TOPLEFT', 0, -CATEGORY_TITLE_HEIGHT)
		elseif slotID % config.buttonsperrow==1 then
			slot:SetPoint('TOP', container.Categories[category].Slots[slotID-config.buttonsperrow], 'BOTTOM', 0, -config.buttonspacing)
		else
			slot:SetPoint('LEFT', container.Categories[category].Slots[slotID-1], 'RIGHT', config.buttonspacing, 0)
		end
	end
	
	slot:SetSize(config.buttonsize,config.buttonsize)


	slot.count = _G[slot:GetName() .. "Count"]
	slot.icon = _G[slot:GetName() .. "IconTexture"]
	slot.border = _G[slot:GetName() .. "NormalTexture"]
	slot.cooldown = _G[slot:GetName() .. "Cooldown"]

	slot.icon:SetTexCoord(.08, .92, .08, .92)
	slot.icon:SetPoints(1)

	slot.count:SetFontObject(st.pixelFont)
	slot.count:ClearAllPoints()
	slot.count:SetPoint('BOTTOMRIGHT', -2, 1)

	slot.cooldown:SetAllPoints(slot)

	slot:SetTemplate('ActionButton')
	slot:SetNormalTexture("")
	slot:SetPushedTexture("")
	slot:Show()

	tinsert(self.AllSlots, slot)

	container.Categories[category].Slots[slotID] = slot

	return slot
end

--------------------------------------
-- CATEGORY FUNCTIONS ----------------
--------------------------------------

function INV:CreateCategory(category, bank) 
	local categoryFrame = CreateFrame('frame', nil, self[bank and 'Bank' or 'Bags'])
	categoryFrame:SetWidth(self.Bags:GetWidth()-st.UI_PANEL_PADDING*2)
	categoryFrame:SetBackdropColor(unpack(st.Saved.profile.Colors.buttonnormal))
	categoryFrame.Slots = {}

	categoryFrame.Label = categoryFrame:CreateFontString()
	categoryFrame.Label:SetFontObject(st.pixelFont)
	categoryFrame.Label:SetText(category)
	categoryFrame.Label:SetPoint('TOPLEFT', categoryFrame, 'TOPLEFT', 5, -2)

	self[bank and 'Bank' or 'Bags'].Categories[category] = categoryFrame
end

--tests an item against all categories and returns the first one that meets the criteria.
function INV:GetItemCategory(name,link,quality,iLevel,reqLevel,class,subclass,equipSlot)
	for categoryName,testFunc in pairs(CATEGORY_FILTERS) do
		if testFunc(name,link,quality,iLevel,reqLevel,class,subclass,equipSlot) then
			return categoryName
		end
	end

	-- not all items will fit a category, place those items in Miscellaneous
	return "Miscellaneous"
end

local function sortCategory(a,b) return a.sortString > b.sortString end

-- This function goes through all inventory slots, paring each item for specific properities and
-- then places them into specific categories based on those properties.
-- It then sorts each category individually, and returns the sorted and organized table of items.
function INV:GetSortedInventory(bank)
	local items = {}

	-- If your accessing the bank remotely, get the bank listing from SavedVariables
	if bank and not BankFrame:IsShown() then
		return st.Saved.realm.bankcache[st.MY_NAME]
	end

	for _,bagID in pairs(bank and BANK_IDS or BACKPACK_IDS) do
		for slotID=1, GetContainerNumSlots(bagID) do
			local texture, count, locked, _, _, _, clink = GetContainerItemInfo(bagID,slotID)
			if clink then
				local name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(clink)
				--Create custom categories here to replace actual category value
				category = self:GetItemCategory(name,link,quality,iLevel,reqLevel,class,subclass,equipSlot)

				if not items[category] then items[category] = {} end

				tinsert(items[category], {
					bagID = bagID,
					slotID = slotID,
					sortString = name and (quality .. (iLevel or 0) .. class .. subclass .. (count or 0)) or '',
					clink = clink,
					texture = texture,
					count = count,
					locked = locked
				})
			end
		end
	end

	for category,categoryItems in pairs(items) do
		if #categoryItems > 1 then
			table.sort(categoryItems, sortCategory)
		end
	end

	if bank then st.Saved.realm.bankcache[st.MY_NAME] = items end

	return items
end

function INV:CreateBagCategory(bank)
	local bagorbank = self[bank and 'Bank' or 'Bags']
	self:CreateCategory('Bags', bank)

	for slotID=1, (bank and 7 or 4) do
		local slot = bank and (_G['BankFrameBag'..slotID] or BankSlotsFrame['Bag'..slotID]) or _G[format('CharacterBag%dSlot', slotID-1)]

		slot:SetSize(st.Saved.profile.Inventory.buttonsize,st.Saved.profile.Inventory.buttonsize)
		slot:SetParent(bagorbank.Categories.Bags)
		slot:SetTemplate('ActionButton')

		slot:ClearAllPoints()
		if slotID == 1 then
			slot:SetPoint('TOPLEFT', bagorbank.Categories.Bags, 'TOPLEFT', 0, -CATEGORY_TITLE_HEIGHT)
		elseif slotID % st.Saved.profile.Inventory.buttonsperrow==1 then
			slot:SetPoint('TOP', bagorbank.Categories.Bags.Slots[slotID-st.Saved.profile.Inventory.buttonsperrow], 'BOTTOM', 0, -st.Saved.profile.Inventory.buttonspacing)
		else
			slot:SetPoint('LEFT', bagorbank.Categories.Bags.Slots[slotID-1], 'RIGHT', st.Saved.profile.Inventory.buttonspacing, 0)
		end

		bagorbank.Categories.Bags.Slots[slotID] = slot
	end
end

--------------------------------------
-- FOOTER FUNCTIONS ------------------
--------------------------------------

function INV:InitializeFooter(containerType)
	local container,isBank,isReagent = INV:GetContainer(containerType)

	local slottext = container.Footer:CreateFontString(nil, 'OVERLAY')
	slottext:SetFontObject(st.pixelFont)
	slottext:SetPoint('LEFT', 10, 0)
	slottext:SetText('#/# Slots Used')
	container.Footer.SlotText = slottext

	if isBank then
		-- Opens reagent bank window
		local reagentbutton = CreateFrame('Button', nil, container.Footer)
		reagentbutton:SetPoint('RIGHT', 0, 0)
		reagentbutton:SetTemplate('Button')
		reagentbutton:SetSize(100, container.Footer:GetHeight())
		reagentbutton.Label = reagentbutton:CreateFontString(nil, 'OVERLAY')
		reagentbutton.Label:SetPoint('CENTER')
		reagentbutton.Label:SetFontObject(st.pixelFont)
		reagentbutton.Label:SetText('Reagents')
		self:HookScript(reagentbutton, 'OnClick', 'OpenReagentBank')
		container.Footer.ReagentButton = reagentbutton
	elseif isReagent then
		ReagentBankFrame.DespositButton:SetParent(container)
		ReagentBankFrame.DespositButton:ClearAllPoints()
		ReagentBankFrame.DespositButton:SetPoint('BOTTOMRIGHT', container.Footer, 0, 0)
		ReagentBankFrame.DespositButton:SetTemplate('Button')
		ReagentBankFrame.DespositButton:SetSize(150, 20)
	else
		self:CreateGoldString()
		self:CreateSearchBar()
	end

end

--------------------------------------
-- GOLDSTRING FUNCTIONS --------------
--------------------------------------

--display all currencies and realm wide gold
function INV:DisplayCurrenciesTooltip()
	GameTooltip:SetOwner(self.Bags, "ANCHOR_BOTTOMLEFT", 1, self.Bags:GetHeight())
	GameTooltip:ClearLines()
	
	GameTooltip:AddLine('Currencies')

	--List your characters currencies
	for i = 1, GetCurrencyListSize() do
		local name, isHeader, isExpanded, isUnused, isWatched, count, extraCurrencyType, icon, itemID = GetCurrencyListInfo(i)
		if isHeader then
			--stop when you get to the unused header
			if select(4, GetCurrencyListInfo(i+1)) then break end

			GameTooltip:AddLine(name)
		elseif count > 0 and not isUnused then
			GameTooltip:AddDoubleLine(name, count, 1,1,1, 1,1,1)
		end
	end

	GameTooltip:AddLine(' ')
	GameTooltip:AddLine('Account Gold')
	
	-- List server wide gold
	local totalGold = 0
	for toonName, gold in pairs(st.Saved.realm.gold) do 
		GameTooltip:AddDoubleLine(toonName, st.StringFormat:GoldFormat(gold), 1,1,1)
		totalGold = totalGold + gold
	end
	GameTooltip:AddLine(' ')
	GameTooltip:AddDoubleLine('Total', st.StringFormat:GoldFormat(totalGold))

	GameTooltip:Show()
end

function INV:CreateGoldString()
	--Displays gold amount and displays tooltip with other currencies and server wide gold
	local goldstring = CreateFrame('frame', nil, self.Bags.Footer)
	goldstring:EnableMouse(true)
	goldstring:SetPoint('TOPRIGHT', self.Bags.Footer, 'TOPRIGHT', 0, 0)
	goldstring:SetPoint('BOTTOMRIGHT', self.Bags.Footer, 'BOTTOMRIGHT', 0, 0)
	goldstring:SetWidth(110)

	goldstring.text = goldstring:CreateFontString(nil, 'OVERLAY')
	goldstring.text:SetFontObject(st.pixelFont)
	goldstring.text:SetPoint('RIGHT', goldstring, 'RIGHT', -st.UI_PANEL_PADDING, 0)

	goldstring:SetScript('OnEnter', function() INV:DisplayCurrenciesTooltip() end)
	goldstring:SetScript('OnLeave', st.HideGameTooltip)

	self.Bags.GoldString = goldstring
	self:UpdateGoldString()
end

function INV:UpdateGoldString()
	self.Bags.GoldString.text:SetText(st:GetGoldString())
	st.Saved.realm.gold[st.MY_NAME] = GetMoney()
end

--------------------------------------
-- SEARCH FUNCTIONS ------------------
--------------------------------------

function INV:GetQueryMatched(slot, query)
	name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(GetContainerItemLink(slot.bagID,slot:GetID()))
	if not query then return false end

	for q, t in pairs(QUERY_TRANSLATIONS) do query = query:gsub(q, t) end
	query = strlower(query)

	if name and strfind(strlower(name), query) then return true end
	
	--loadstring creates a function formatted with the items itemLevel, and the operand and number found within the query, and returns the inequality
	local operand, number = strmatch(query:gsub(' ',''), '(=?<?>?=?)(%d+)')
	if iLevel and (operand and strlen(operand) > 0) and number then 
		if operand == '=' then operand = '==' end
		if operand == '=>' then operand = '>=' end
		if operand == '=<' then operand = '<=' end
		if loadstring(format("return %d %s %d", iLevel, operand, number))() then return true end
	end

	if strfind(query, strlower(class)) or strfind(query, strlower(subclass)) then return true end

	return false
end

function INV:ResetSearch(editbox)
	editbox:SetText('')
	for i,slot in pairs(self.AllSlots) do
		slot:SetAlpha(1)
	end
end

function INV:FilterSearch(editbox, userInput)
	if not userInput then return end
	local query = editbox:GetText()
	local empty = strlen(query:gsub(' ', '')) == 0

	for i,slot in pairs(self.AllSlots) do
		if not slot:IsShown() then return end
		if empty or LIS:Matches(slot.link, query) then
			slot:SetAlpha(1)
		else
			slot:SetAlpha(.3)
		end
	end
end

function INV:CreateSearchBar()
	local search = st.CreateEditBox('SaftUI_BagsSearch', self.Bags)
	search:SetBackdropColor(0, 0, 0, 0)
	search:SetBackdropBorderColor(0, 0, 0, 0)

	search:SetPoint('TOPLEFT', self.Bags.Footer, 'TOPLEFT', 50, 0)
	search:SetPoint('BOTTOMRIGHT', self.Bags.GoldString, 'BOTTOMLEFT', 0, 0)
	search:SetScript('OnTextChanged', function(self, userInput) INV:FilterSearch(self, userInput) end)
	search:HookScript('OnEscapePressed', function(self, userInput) INV:ResetSearch(self) end)
	search:HookScript('OnEditFocusGained', function(self) self:SetBackdropColor(unpack(st.Saved.profile.Colors.buttonnormal)) end)
	search:HookScript('OnEditFocusLost', function(self) self:SetBackdropColor(0,0,0,0) end)
	search:SetTextInsets(27, 5, 0, 0)
	
	search.icon = search:CreateTexture(nil, 'OVERLAY')
	search.icon:SetSize(12, 12)
	search.icon:SetTexture(st.TEXTURE_PATHS.search)
	search.icon:SetPoint('LEFT', search, 'LEFT', 5, 0)
	search.icon:SetVertexColor(.6, .7,.85, .7)

	self.Bags.Search = search
end

--------------------------------------
-- BANK SPECIFIC FUNCTIONS -----------
--------------------------------------

--Make sure original bank frame stays out of the way
function INV:DisableBlizzardBank()
	BankFrame:ClearAllPoints()
	BankFrame:SetPoint('BOTTOMRIGHT', UIParent, 'TOPLEFT', -100, 100)
	BankFrame.SetPoint = st.dummy
end

function INV:SetBankItemTooltip(slot)

	if not BankFrame:IsShown() and slot.link then
		-- print(slot.slotID, slot.bagID, slot.link)
		GameTooltip:SetHyperlink(slot.link)
	elseif slot.bagID == -1 then
		GameTooltip:SetOwner(slot, "ANCHOR_RIGHT");

		local hasItem, hasCooldown, repairCost, speciesID, level, breedQuality, maxHealth, power, speed, name = GameTooltip:SetInventoryItem("player", BankButtonIDToInvSlotID(slot.slotID));
		if(speciesID and speciesID > 0) then
			BattlePetToolTip_Show(speciesID, level, breedQuality, maxHealth, power, speed, name);
			CursorUpdate(slot);
			return;
		end

		if ( not hasItem ) then
			if ( slot.isBag ) then
				GameTooltip:SetText(slot.tooltipText);
			end
		end
		CursorUpdate(slot);
	end	
end

function INV:OpenBank()
	--If this is the first time opening bank during this session, run setup
	if not self.Bank then
		self:CreateContainer('BANK')
		self:DisableBlizzardBank()
		self:SecureHook('ContainerFrameItemButton_OnEnter', 'SetBankItemTooltip')
	end
	self:UpdateBags('BANK')
	self.Bank:Show()
end

function INV:CloseBank()
	self.Bank:Hide()
end

function INV:ToggleBank()
	if self.Bank:IsShown() then
		self:CloseBank()
	else
		self:OpenBank()
	end
end


--------------------------------------
-- REAGENT BANK FUNCTIONS ------------
--------------------------------------

function INV:OpenReagentBank()
	if not self.ReagentBank then
		ReagentBankFrame_OnShow(ReagentBankFrame)
		self:CreateContainer('REAGENT')
	end
	self:UpdateBags('REAGENT')
	self.ReagentBank:Show()
end

--------------------------------------
-- UPDATE FUNCTIONS ------------------
--------------------------------------

--Update cooldown spirals on usable items
function INV:UpdateCooldowns()
	for _,category in pairs(self.Bags.Categories) do
		for _,slot in pairs(category.Slots) do
		    if slot.bagID and slot.slotID and ( GetContainerItemInfo(slot.bagID, slot.slotID) ) then
			    local start, duration, enable = GetContainerItemCooldown(slot.bagID, slot.slotID);
			    CooldownFrame_SetTimer(slot.cooldown, start, duration, enable);
			    if ( duration > 0 and enable == 0 ) then
			        SetItemButtonTextureVertexColor(slot, 0.4, 0.4, 0.4);
			    else
			        SetItemButtonTextureVertexColor(slot, 1, 1, 1);
			    end
	        elseif slot.cooldown then
	            slot.cooldown:Hide()
	        end
	    end
    end
end

function INV:UpdateContainerSize(containerType)
	local config = st.Saved.profile.Inventory
	local container, isBank, isReagent = INV:GetContainer(containerType)
	local height = container.TitleRegion:GetHeight() + container.Footer:GetHeight()

	if container.Footer then
		height = height + container.Footer:GetHeight()
	end

	
	if isReagent then
		for slotID, slot in pairs(container.Slots) do
			slot:SetSize(config.buttonsize,config.buttonsize)
			slot:ClearAllPoints()
			if slotID == 1 then
				slot:SetPoint('TOPLEFT', container.TitleRegion, 'BOTTOMLEFT', st.UI_PANEL_PADDING, -st.UI_PANEL_PADDING)
			elseif slotID % config.buttonsperrow==1 then
				slot:SetPoint('TOP', container.Slots[slotID-config.buttonsperrow], 'BOTTOM', 0, -config.buttonspacing)
			else
				slot:SetPoint('LEFT', container.Slots[slotID-1], 'RIGHT', config.buttonspacing, 0)
			end
		end	

		local numRows = ceil(getn(container.Slots)/config.buttonsperrow)
		height = height + numRows * config.buttonsize + (numRows-1)*config.buttonspacing + st.UI_PANEL_PADDING
	else
		local prev
		for categoryName,categoryFrame in pairs(container.Categories) do
			if categoryFrame:IsShown() then
				local numSlots = 0
				for slotID,slot in pairs(categoryFrame.Slots) do
					if slot:IsShown() then
						numSlots = numSlots + 1

						slot:SetSize(config.buttonsize,config.buttonsize)

						slot:ClearAllPoints()
						if slotID == 1 then
							slot:SetPoint('TOPLEFT', container.Categories[categoryName], 'TOPLEFT', 0, -CATEGORY_TITLE_HEIGHT)
						elseif slotID % config.buttonsperrow==1 then
							slot:SetPoint('TOP', container.Categories[categoryName].Slots[slotID-config.buttonsperrow], 'BOTTOM', 0, -config.buttonspacing)
						else
							slot:SetPoint('LEFT', container.Categories[categoryName].Slots[slotID-1], 'RIGHT', config.buttonspacing, 0)
						end
					end

				end

				local numRows = math.ceil(numSlots/config.buttonsperrow)
				
				categoryHeight = numRows*config.buttonsize + (numRows-1)*config.buttonspacing + CATEGORY_TITLE_HEIGHT
				categoryFrame:SetHeight(categoryHeight)

				height = height + st.UI_PANEL_PADDING + categoryHeight

				categoryFrame:ClearAllPoints()

				if categoryName ~= 'Bags' then --We're gonna position these at the bottom after
					if prev then 
						categoryFrame:SetPoint('TOPLEFT', prev, 'BOTTOMLEFT', 0, -st.UI_PANEL_PADDING)
					else
						categoryFrame:SetPoint('TOPLEFT', container.TitleRegion, 'BOTTOMLEFT', st.UI_PANEL_PADDING, -st.UI_PANEL_PADDING)
					end
					prev = categoryFrame
				end

			end
		end

		container.Categories.Bags:SetPoint('TOPLEFT', prev, 'BOTTOMLEFT', 0, -st.UI_PANEL_PADDING)
	end

	container:SetWidth(st.UI_PANEL_PADDING*2 + config.buttonsize*config.buttonsperrow + config.buttonspacing*(config.buttonsperrow-1))
	container:SetHeight(height)
end


function INV:UpdateHandler()
	self:UpdateBags()

	if not bank and self.Bank and self.Bank:IsShown() then
		self:UpdateBags('BANK')
	end
end

function INV:UpdateBags(containerType)
	local container, isBank, isReagent = self:GetContainer(containerType)


	if not isReagent then
		local sortedInventory = self:GetSortedInventory(isBank)
		if not sortedInventory then return end
		for category,items in pairs(sortedInventory) do
			for i,slotInfo in pairs(items) do
				if not container.Categories[category] then self:CreateCategory(category, isBank) end
				if not container.Categories[category]:IsShown() then container.Categories[category]:Show() end

				self:AssignSlot(container.Categories[category].Slots[i] or self:CreateSlot(containerType, category), slotInfo)
			end

			-- Hide any visible icons that are no longer in use
			local i = #items + 1
			while container.Categories[category].Slots[i] do
				self:ClearSlot(container.Categories[category].Slots[i])
				i = i + 1
			end
		end

		--If a category was emptied it wouldn't be in the above loop. This finds those categories and hides them properly
		for categoryName,category in pairs(container.Categories) do
			if not (sortedInventory[categoryName] or categoryName == 'Bags') then
				for _,slot in pairs(category.Slots) do self:ClearSlot(slot) end
				category:Hide()
			end
		end

		-- check if we should display bag slots
		if SHOW_BAG_SLOTS then
			container.Categories.Bags:Show()
		else
			container.Categories.Bags:Hide()
		end
	end

	local empty, total = self:GetNumContainerSlots(containerType)
	container.Footer.SlotText:SetFormattedText('%d/%d',total-empty, total)

	self:UpdateContainerSize(containerType)

	if not isBank then self:UpdateGoldString() end
end

------------------------------------------------
-- MERCHANT AUTOMATION -------------------------
------------------------------------------------
--Handles all vendor things such as automatic repairs and vendoring trash items
function INV:HandleMerchant()
	local config = st.Saved.profile.Inventory
	
	-- Vendor greys and other selected items
	if config.vendorgreys then
		local profit = 0
		for _,bagID in pairs(BACKPACK_IDS) do
			for slotID=1, GetContainerNumSlots(bagID) do
				local link = GetContainerItemLink(bagID, slotID)
				if link and select(11, GetItemInfo(link)) then
					local _,_,quality,_,_,_,_,_,_,_,price = GetItemInfo(link)
					local count = select(2, GetContainerItemInfo(bagID, slotID))
					local stackPrice = price*count

					if quality == 0 and stackPrice > 0 then
						UseContainerItem(bagID, slotID)
						PickupMerchantItem()

						profit = profit + stackPrice
					end
				end
			end
		end

		if profit > 0 then
			print('Total gold gained from vendoring greys: ' .. st:GetGoldString(profit))
		end
	end

	-- Auto repair gear
	if config.autorepair and CanMerchantRepair() then
		local repairAllCost, canRepair = GetRepairAllCost()

		if canRepair and CanGuildBankRepair() then
			RepairAllItems(1)
		end

		repairAllCost, canRepair = GetRepairAllCost()

		if canRepair and repairAllCost < GetMoney() then
			RepairAllItems()
			print('Repaired all items for ' .. st:GetGoldString(repairAllCost))
		else
			print('Insufficient funds for gear repair.')
		end

	end
end


--------------------------------------
-- INITIALIZE ------------------------
--------------------------------------

function INV:CreateContainer(containerType)
	local _, isBank, isReagent = INV:GetContainer(containerType)

	local container = CreateFrame('Frame', (isBank and 'SaftUI_Bank' or isReagent and 'SaftUI_ReagentBank' or 'SaftUI_Bags'), UIParent)

	container:SetTemplate('Transparent')
	container:SetFrameStrata('HIGH')
	container:SetWidth(st.UI_PANEL_PADDING*2 + st.Saved.profile.Inventory.buttonsize*st.Saved.profile.Inventory.buttonsperrow + st.Saved.profile.Inventory.buttonspacing*(st.Saved.profile.Inventory.buttonsperrow-1))
	container:SetHeight(200)
	container:Hide()
	
	container.Title = container:CreateFontString(nil, 'OVERLAY')
	container.Title:SetFontObject(st.pixelFont)
	container.Title:SetText(isBank and 'Bank' or isReagent and 'Reagents' or 'Bags')

	container.CloseButton = container:CreateCloseButton()
	if not isReagent then
		container.CloseButton:HookScript("OnClick", CloseAllBags)
	end
	
	container:CreateHeader()
	container:CreateFooter()

	if not containerType then
		local remoteBank = CreateFrame('Button', nil, container)
		remoteBank:SetPoint('TOPLEFT', container.TitleRegion, 'TOPLEFT', 0, 0)
		remoteBank:SetTemplate('Button')
		remoteBank:SetText('Bank')
		remoteBank:SetSize(60, 20)
		self:HookScript(remoteBank, 'OnClick', 'OpenBank')
	end

	if isReagent then
		local reagentUnlockName = ReagentBankFrame.UnlockInfo:GetName()
		ReagentBankFrame.UnlockInfo:SetParent(container)
		ReagentBankFrame.UnlockInfo:ClearAllPoints()
		ReagentBankFrame.UnlockInfo:SetPoint('TOPLEFT', container.TitleRegion, 'BOTTOMLEFT', 10, -10)
		ReagentBankFrame.UnlockInfo:SetPoint('BOTTOMRIGHT', container.Footer, 'TOPRIGHT', -10, 10)
		ReagentBankFrame.UnlockInfo:StripTextures()
		_G[reagentUnlockName..'Title']:Kill()
		_G[reagentUnlockName..'Text']:SetPoint('TOPLEFT', container.TitleRegion, 'BOTTOMLEFT', 10, -10)
		_G[reagentUnlockName..'Text']:SetPoint('TOPRIGHT', container.TitleRegion, 'BOTTOMRIGHT', -10, -10)
		_G[reagentUnlockName..'PurchaseButton']:SetTemplate('Button')

		container.Slots = {}

		for ID=1, ReagentBankFrame.size do
			local slot = ReagentBankFrame['Item'..ID]
			slot:SetParent(container)
			container.Slots[ID] = slot

			slot.count = _G[slot:GetName() .. "Count"]
			slot.icon = _G[slot:GetName() .. "IconTexture"]
			slot.border = _G[slot:GetName() .. "NormalTexture"]
			slot.cooldown = _G[slot:GetName() .. "Cooldown"]

			slot.icon:SetTexCoord(.08, .92, .08, .92)
			slot.icon:SetPoints(1)

			slot.count:SetFontObject(st.pixelFont)
			slot.count:ClearAllPoints()
			slot.count:SetPoint('BOTTOMRIGHT', -2, 1)

			slot.cooldown:SetAllPoints(slot)

			slot:SetTemplate('ActionButton', true)
			slot.IconBorder:Kill()
			slot:SetNormalTexture("")
			slot:SetPushedTexture("")
		end
	else
		container.Categories = {}
		for _,bagID in pairs(isBank and BANK_IDS or BACKPACK_IDS) do
			local bag = CreateFrame('Frame', 'SaftUI_Bag'..bagID, container)
			bag:SetID(bagID)
			self.Containers[bagID] = bag
		end
	end

	self[isBank and 'Bank' or isReagent and 'ReagentBank' or 'Bags'] = container
	container:SetPoint(unpack(st.Saved.profile.Inventory[isBank and 'bankposition' or isReagent and 'reagentposition' or 'bagposition']))

	self:InitializeFooter(containerType)

	if not isReagent then
		self:CreateBagCategory(isBank)
	end
end


function INV:ToggleBags() ToggleFrame(INV.Bags) end
function INV:ShowBags() INV.Bags:Show() end

function INV:HideBags() 
	INV.Bags:Hide() 
	if INV.Bank and INV.Bank:IsShown() then
		INV.Bank:Hide()
		BankFrame:Hide()
	end

	if INV.ReagentBank and INV.ReagentBank:IsShown() then
		INV.ReagentBank:Hide()
	end
end

function INV:OnInitialize()
	if not st.Saved.realm.gold then st.Saved.realm.gold = {} end
	if not st.Saved.realm.bankcache then st.Saved.realm.bankcache = {} end

	self.AllSlots = {}
	self.Containers = {} --store parent containers here, includes bank (if initialized) and bags frames

	self:CreateContainer()

	--Overwrite all blizzard bag functions
	ToggleBackpack		= INV.ToggleBags
	ToggleBag 			= INV.ToggleBags
	ToggleAllBags 		= INV.ToggleBags
	OpenAllBags 		= INV.ShowBags
	OpenBackpack 		= INV.ShowBags
	CloseAllBags 		= INV.HideBags
	CloseBackpack 		= INV.HideBags

	-- Bag events
	self:RegisterEvent('BAG_UPDATE', 'UpdateHandler')
	self:RegisterEvent('ITEM_LOCK_CHANGED', 'UpdateHandler')
	self:RegisterEvent('ITEM_UNLOCKED', 'UpdateHandler')

	-- Bank events
	self:RegisterEvent('BANKFRAME_OPENED', 'OpenBank')
	self:RegisterEvent('BANKFRAME_CLOSED', 'CloseBank')
	self:RegisterEvent('PLAYERBANKSLOTS_CHANGED', 'UpdateHandler')

	-- Misc events
	self:RegisterEvent('PLAYER_MONEY', 'UpdateGoldString')
	self:RegisterEvent('MERCHANT_SHOW', 'HandleMerchant')
	self:RegisterEvent('BAG_UPDATE_COOLDOWN', 'UpdateCooldowns')

	st:GetModule('Config'):AddConfigFrame({
		key = 'inventory',
		label = 'Inventory',
		parent = self.Bags,
		set = function(key, subkey, value) 
			if subkey then
				st.Saved.profile.Inventory[key][subkey] = value
			else
				st.Saved.profile.Inventory[key] = value;
			end

			self:UpdateContainerSize() end,
		get = function(key, subkey) return subkey and st.Saved.profile.Inventory[key][subkey] or st.Saved.profile.Inventory[key] end,
		args = {
			{
				key='buttonsperrow',
				type = 'input',
				sanitation = function(input) return tonumber(strmatch(input,'%d+')) end,
				validation = function(input) 
					if input < 0 then
						return 'Height must be zero or positive'
					end
				end,
				label = 'Buttons Per Row',
				width = 0.3,
			},
			{
				key='buttonsize',
				type = 'input',
				sanitation = function(input) return tonumber(strmatch(input,'%d+')) end,
				validation = function(input) 
					if input < 0 then
						return 'Height must be zero or positive'
					end
				end,
				label = 'Buttons Size',
				width = 0.3,
			},
			{
				key='buttonspacing',
				type = 'input',
				sanitation = function(input) return tonumber(strmatch(input,'%d+')) end,
				validation = function(input) 
					if input < 0 then
						return 'Height must be zero or positive'
					end
				end,
				label = 'Button Spacing',
				width = 0.3,
			},
		}
	})
end