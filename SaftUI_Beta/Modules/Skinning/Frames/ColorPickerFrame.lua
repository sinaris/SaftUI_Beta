local st = SaftUI

local function ColorPickerUpdateFields()
	local r, g, b = ColorPickerFrame:GetColorRGB()
	local a = OpacitySliderFrame:GetValue()
	ColorPickerFrame.Red:SetText(r*255)
	ColorPickerFrame.Green:SetText(g*255)
	ColorPickerFrame.Blue:SetText(b*255)
	ColorPickerFrame.Hex:SetText(st.StringFormat:ToHex(r,g,b))

	if a then
		ColorPickerFrame.Alpha:SetText(floor(a*100+0.5))
		ColorSwatch:SetAlpha(a)
	end


	ColorPickerFrame:SetSize(280, 187)
end

st:GetModule('Skinning').FrameSkins.ColorPickerFrame = function(self)
	self.hasOpacity = true
	self.opacity = 1
	self:SetTemplate('Transparent', true)
	self:EnableKeyboard(false) -- Why the hell is this even enabled?
	self:CreateHeader()
	ColorPickerFrameHeader:SetTexture(nil)

	ColorPickerCancelButton:SetTemplate('Button')
	ColorPickerCancelButton:SetHeight(20)
	ColorPickerCancelButton:SetBackdropColor(unpack(st.Saved.profile.Colors.buttonred))
	ColorPickerCancelButton:SetPoint('BOTTOMRIGHT', 0, 0)
	ColorPickerCancelButton:SetPoint('BOTTOMLEFT', self, 'BOTTOM', 0, 0)

	ColorPickerOkayButton:SetTemplate('Button')
	ColorPickerOkayButton:SetHeight(20)
	ColorPickerOkayButton:SetBackdropColor(unpack(st.Saved.profile.Colors.buttongreen))
	ColorPickerOkayButton:SetPoint('BOTTOMLEFT', 0, 0)
	ColorPickerOkayButton:SetPoint('BOTTOMRIGHT', self, 'BOTTOM', 0, 0)


	ColorPickerWheel:ClearAllPoints()
	ColorPickerWheel:SetPoint('TOPLEFT', self.TitleRegion, 'BOTTOMLEFT', 10, -10)

	-- For some reason blizzard decided not to name this, so we have to get access in a sketchy way
	local colorValue, colorValueThumb = select(6, ColorPickerFrame:GetRegions())
	colorValue:ClearAllPoints()
	colorValue:SetPoint('TOPLEFT', ColorPickerWheel, 'TOPRIGHT', 20, 0)

	ColorSwatch:SetSize(60, 23)
	ColorSwatch:ClearAllPoints()
	ColorSwatch:SetPoint('TOPLEFT', colorValue, 'TOPRIGHT', 20, 0)


	local prev
	for i,color in pairs({'Red', 'Green', 'Blue', 'Alpha', 'Hex'}) do
		local editbox = CreateFrame('EditBox', nil, self)
		editbox:SetPoint('TOP', prev or ColorSwatch, 'BOTTOM', 0, -1)
		editbox:Skin()
		editbox:SetSize(60, 20)
		editbox:SetTextInsets(20, 3, 0, 0)
		editbox:SetFontObject(st.pixelFont)
		editbox:SetJustifyH('RIGHT')
		editbox:SetNumeric(i ~= 5) --set true for all except hex

		editbox.Label = editbox:CreateFontString(nil, 'OVERLAY')
		editbox.Label:SetPoint('LEFT', 5, 0)
		editbox.Label:SetFontObject(st.pixelFont)
		editbox.Label:SetText(strsub(color,1,1))

		editbox:HookScript('OnEnterPressed', function(self)

			if i == 5 then
				local r,g,b = st.StringFormat:ToRGB(self:GetText())
				ColorPickerFrame:SetColorRGB(r/255,g/255,b/255)
			elseif i == 4 then
				OpacitySliderFrame:SetValue(self:GetNumber()/100)
			else
				local colors = {ColorPickerFrame:GetColorRGB()}
				colors[i] = self:GetNumber()/255
				ColorPickerFrame:SetColorRGB(unpack(colors))
			end
		end)

		editbox:EnableMouseWheel(true)
		editbox:HookScript('OnMouseWheel', function(self, delta)
			local newValue = self:GetNumber() + (IsShiftKeyDown() and 10 or 1)*delta

			if i == 4 then
				OpacitySliderFrame:SetValue(newValue/100)
			elseif i ~= 5 then
				local colors = { ColorPickerFrame:GetColorRGB() }
				colors[i] = newValue/255
				ColorPickerFrame:SetColorRGB(unpack(colors))
			end

		end)

		editbox:HookScript('OnEscapePressed', function(self)

		end)

		self[color] = editbox
		prev = editbox
	end

	-- Hide this since we have edit boxes, but don't kill it to keep scripts functioning properly
	OpacitySliderFrame:SetAlpha(0)
	OpacitySliderFrame:SetWidth(0)
	OpacitySliderFrame:SetValueStep(0.01)

	self:HookScript('OnColorSelect', ColorPickerUpdateFields)
	self:HookScript('OnShow', ColorPickerUpdateFields)
	OpacitySliderFrame:HookScript('OnShow', ColorPickerUpdateFields)
	OpacitySliderFrame:HookScript('OnValueChanged', ColorPickerUpdateFields)

	-- self:Show()
end