local st = SaftUI

if true then return end

---------------------------------------------
-- SPELLTAB FUNCTIONS -----------------------
---------------------------------------------

local spellButtons = {} --Makes iteration easier when changing mode
local function SpellTab_Skin()
	local OLD_SPELLS_PER_PAGE = SPELLS_PER_PAGE
	SPELLS_PER_PAGE = 72
	SPELLS_PER_ROW = 8

	SpellBookFrame:SetSize(PANEL_DEFAULT_WIDTH, st.UI_PANEL_HEIGHT)
	SpellBookFrame:CreateHeader(SpellBookFrameCloseButton, SpellBookFrameTitleText)
	SpellBookFrame:CreateFooter()

	SpellBookFrame.Tabs = {}
	local i = 1
	while _G['SpellBookFrameTabButton'..i] do
		SpellBookFrame.Tabs[i] = _G['SpellBookFrameTabButton'..i]
		SpellBookFrame.Tabs[i].Text = _G['SpellBookFrameTabButton'..i..'Text']

		i = i + 1
	end

	SpellBookFrameInset:StripTextures()

	SpellBookPageNavigationFrame:Kill()

	local button, buttonName
	for i=1, SPELLS_PER_PAGE do
		buttonName = 'SpellButton'..i
		local button = _G[buttonName] or CreateFrame('CheckButton', buttonName, SpellBookSpellIconsFrame, 'SpellButtonTemplate')
		button:SetID(i)

		button.SeeTrainerString:Kill()
		button.TrainBook:ClearAllPoints()
		button.TrainBook:SetPoint('BOTTOMRIGHT', button, 'BOTTOMRIGHT', 0, 0)
		button.TrainBook:SetSize(20, 20)
		-- button.TrainBook:SetTemplate()
		button.TrainBook.Icon:SetAllPoints()

		button.RequiredLevelString:SetFontObject(st.pixelFont)
		button.RequiredLevelString:SetJustifyH('RIGHT')
		button.RequiredLevelString:SetJustifyV('MIDDLE')
		button.RequiredLevelString:ClearAllPoints()
		button.RequiredLevelString:SetPoint('BOTTOMLEFT', button)
		button.RequiredLevelString:SetPoint('BOTTOMRIGHT', button)
		button.RequiredLevelString:SetHeight(12)

		button:SetTemplate('ActionButton')
		_G[buttonName..'IconTexture']:TrimIcon()
		_G[buttonName..'IconTexture']:SetPoints(button, st.BORDER_INSET)
		

		spellButtons[i] = button
	end
end

local function SpellButton_OnUpdateButton(self)
	if st.Saved.profile.SpellBook.compact then
		self.SpellName:Hide()
		self.SpellSubName:Hide()
		if self.RequiredLevelString:IsShown() then
			self.RequiredLevelString:SetText(strmatch(self.RequiredLevelString:GetText(), '%d+'))
			self.RequiredLevelString:SetTextColor(unpack(st.Saved.profile.Colors.textred))
		end


	else

	end
end

local function SpellTab_SetMode(compact)
	local prev, prevRow
	for i,button in pairs(spellButtons) do
		button:ClearAllPoints()
		if st.Saved.profile.SpellBook.compact then
			if prev then
				if i%SPELLS_PER_ROW==1 then
					button:SetPoint('TOP', prevRow, 'BOTTOM', 0, -st.BORDER_INSET)
					prevRow = button
				else
					button:SetPoint('LEFT', prev, 'RIGHT', st.BORDER_INSET, 0)
				end
			else
				button:SetPoint('TOPLEFT', SpellBookFrame.TitleRegion, 'BOTTOMLEFT', st.UI_PANEL_PADDING, -st.UI_PANEL_PADDING)
				prevRow = button
			end
			prev = button
		else
		end

		-- stSpellButton_UpdateButton(button)
	end
end

---------------------------------------------
-- SPELLBOOKFRAME FUNCTIONS -----------------
---------------------------------------------

local function SpellBookFrame_OnUpdate()
	SpellBookFrame:SetTemplate('Transparent')

	local button, prev
	for i,button in pairs(SpellBookFrame.Tabs) do
		button:SetWidth(button.Text:GetStringWidth()+st.UI_PANEL_PADDING*2)
		button.Text:ClearAllPoints()
		button.Text:SetPoint('CENTER', 1, 0)
		button:SetTemplate('Button')
		button:SetHeight(st.TAB_HEIGHT)
		button:ClearAllPoints()
		if button.bookType == 'changed' then
			button:Hide()
		else
			if prev then
				button:SetPoint('LEFT', prev, 'RIGHT', st.BORDER_INSET, 0)
			else
				button:SetPoint('BOTTOMLEFT', SpellBookFrame, 'BOTTOMLEFT', 0, 0)
			end
			prev = button
		end
	end
	SpellBookFrame.Footer:SetPoint('BOTTOMLEFT', prev, 'BOTTOMRIGHT', st.BORDER_INSET, 0)
end

---------------------------------------------
-- INITIALIZE -------------------------------
---------------------------------------------

st:GetModule('Skinning').FrameSkins.SpellBookFrame = function()
	SpellTab_Skin()
	SpellTab_SetMode(true)

	hooksecurefunc('SpellBookFrame_Update', SpellBookFrame_OnUpdate)
	hooksecurefunc('SpellButton_UpdateButton', SpellButton_OnUpdateButton)
end