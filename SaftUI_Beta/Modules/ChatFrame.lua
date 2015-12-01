local st = SaftUI
local CHT = st:NewModule('Chat', 'AceHook-3.0', 'AceEvent-3.0')

function CHT:GetNumDockedFrames()
	local count = 0;
	local chatFrame;
	for i=1, NUM_CHAT_WINDOWS do
		chatFrame = _G["ChatFrame"..i];
		if chatFrame and chatFrame.isDocked then
			count = count + 1;
		end
	end
	return count;
end

function CHT:SkinChatFrame(frame)
	local name = frame:GetName()
	frame:StripTextures()
	frame:CreateBackdrop()
	frame:SetMinResize(170, 40)
	frame:SetMaxResize(1000, 1000)
	frame:SetBackdropBorderColor(0, 0, 0, 0)
	frame:SetFading(false)
	
	-- Handle editbox
	frame.EditBox = _G[name..'EditBox']
	frame.EditBox.Header = _G[name..'EditBoxHeader']
	frame.EditBox.HeaderSuffix = _G[name..'EditBoxHeaderSuffix']

	local a, b, c = select(6, frame.EditBox:GetRegions()); a:Kill(); b:Kill(); c:Kill()
	_G[name..'EditBoxFocusLeft']:Kill()
	_G[name..'EditBoxFocusMid']:Kill()
	_G[name..'EditBoxFocusRight']:Kill()

	frame:SetFont(st.pixelFont:GetFont())

	frame.EditBox:SetHeight(st.TAB_HEIGHT)
	frame.EditBox:SetFrameLevel(frame:GetFrameLevel()+2)
	frame.EditBox:SetAltArrowKeyMode(false)
	frame.EditBox:Skin()
	frame.EditBox:ClearAllPoints()
	frame.EditBox:SetPoint('BOTTOMLEFT', frame.Backdrop, 'BOTTOMLEFT', 0, 0)
	frame.EditBox:SetPoint('BOTTOMRIGHT', frame.Backdrop, 'BOTTOMRIGHT', 0, 0)

	_G[name..'ButtonFrameUpButton']:Kill()
	_G[name..'ButtonFrameDownButton']:Kill()
	_G[name..'ButtonFrameBottomButton']:Kill()
	_G[name..'ButtonFrameMinimizeButton']:Kill()
	_G[name..'ButtonFrame']:Kill()

	-- Handle tabs
	frame.Tab = _G[name..'Tab']
	frame.Tab.Text = _G[name..'TabText']

	frame.Tab:SetTemplate('Button')
	frame.Tab:SetHeight(st.TAB_HEIGHT)
	frame.Tab.Text:ClearAllPoints()
	frame.Tab.Text:SetPoint('CENTER')
	frame.Tab.Text:SetFont(st.pixelFont:GetFont())
	frame.Tab.Text:SetShadowOffset(0, 0)

	frame.Tab:SetAlpha(1)
	frame.Tab.SetAlpha = UIFrameFadeRemoveFrame

	frame.ResizeButton = _G[name..'ResizeButton']
	frame.ResizeButton:ClearAllPoints()
	frame.ResizeButton:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', 0, 0)

	frame.ResizeButton:SetNormalTexture(st.TEXTURE_PATHS.cornerbr)
	
	frame.ResizeButton:SetPushedTexture(st.TEXTURE_PATHS.cornerbr)
	frame.ResizeButton:GetPushedTexture():SetVertexColor(unpack(st.Saved.profile.Colors.buttonhover))

	frame.ResizeButton:SetHighlightTexture(st.TEXTURE_PATHS.cornerbr)
	frame.ResizeButton:GetHighlightTexture():SetVertexColor(unpack(st.Saved.profile.Colors.buttonhover))
	frame.ResizeButton:GetHighlightTexture():SetBlendMode('BLEND')

	frame.ResizeButton:SetFrameStrata('LOW')
	frame.ResizeButton:SetFrameLevel(4)




	self:UpdateChatFrameDisplay(frame)
end

function CHT:UpdateChatFrameDisplay(frame)
	local config = st.Saved.profile.Chat

	frame.Backdrop:SetTemplate(config.template)
	frame.Backdrop:SetPoints(-st.TAB_HEIGHT-st.Saved.profile.Chat.padding, -st.Saved.profile.Chat.padding)
	
	if config.template == 'None' then
		frame.Tab:SetBackdrop(nil)
	else
		frame.Tab:SetTemplate('Button')
	end
end



-------------------------------------
-- SECURE HOOKS ---------------------
-------------------------------------

function CHT:FCFDock_UpdateTabs(dock, forceUpdate)
	dock:ClearAllPoints()
	dock:SetPoint('TOPLEFT', ChatFrame1.Backdrop, 'TOPLEFT', 0, 0)
	dock:SetWidth(ChatFrame1.Backdrop:GetWidth())
	dock:SetHeight(st.TAB_HEIGHT)

	local prev
	for idx,chatFrame in pairs(dock.DOCKED_CHAT_FRAMES) do
		chatFrame.Tab:ClearAllPoints()
		if prev then
			chatFrame.Tab:SetPoint('LEFT', prev, 'RIGHT', 1, 0)
		else
			chatFrame.Tab:SetPoint('TOPLEFT', dock, 'TOPLEFT', 0, 0)
		end
		prev = chatFrame.Tab
	end

	if not dock.Filler then
		dock.Filler = dock:CreateTexture(nil, 'OVERLAY')
		dock.Filler:SetTexture(unpack(st.Saved.profile.Colors.buttonnormal))
		dock.Filler:SetPoint('TOPRIGHT', 0, 0)
	end
	dock.Filler:SetPoint('BOTTOMLEFT', prev, 'BOTTOMRIGHT', 1, 0)
end

function CHT:ChatEdit_UpdateHeader(editbox)
	local type = editbox:GetAttribute("chatType")
	
	if ( type == "CHANNEL" ) then
		local id = GetChannelName(editbox:GetAttribute("channelTarget"))
		if id == 0 then
			 editbox:SetBackdropColor(unpack(st.Saved.profile.Colors.buttonnormal))
		else
			 editbox:SetBackdropColor(ChatTypeInfo[type..id].r,ChatTypeInfo[type..id].g,ChatTypeInfo[type..id].b, 0.2)
		end
	else
		 editbox:SetBackdropColor(ChatTypeInfo[type].r,ChatTypeInfo[type].g,ChatTypeInfo[type].b, 0.2)
	end
	editbox.Header:SetTextColor(1,1,1)
	editbox.Header:SetFontObject(st.normalFont)
	editbox:SetTextColor(1,1,1)
	editbox:SetFontObject(st.normalFont)

	local headertext
	if strmatch(editbox:GetAttribute("chatType"), 'WHISPER') then
		headertext = editbox:GetAttribute('tellTarget')
	else
		headertext = editbox.Header:GetText():gsub('([a-z%s:%]%[])', '')
	end
	editbox.Header:SetFormattedText('%s', headertext)
	editbox:SetTextInsets(30 + editbox.Header:GetWidth(), 13, 0, 0);
end

-- This function will find all fonstring objects used for each chat line and resize/position them to include a customized line spacing
function CHT:ChatFrame_OnUpdate(frame)
	local frametop = frame:GetTop()

	local prev
	for i,region in pairs({frame:GetRegions()}) do
		if region:GetObjectType() == 'FontString' and not region:GetName() then
			if not region.handled then
				region:ClearAllPoints()
				region:SetSpacing(st.Saved.profile.Chat.linespacing)
				if prev then 
					region:SetPoint('BOTTOMLEFT', prev, 'TOPLEFT', 0, st.Saved.profile.Chat.linespacing)
				else
					region:SetPoint('BOTTOMLEFT', frame, 'BOTTOMLEFT', 0, st.Saved.profile.Chat.linespacing)
				end

				region.handled = true
			end
				
			if region:GetTop() and region:GetTop() > frametop-st.Saved.profile.Chat.linespacing then region:Hide() else region:Show() end
			prev = region

		end
	end

	frame:SetFont(st.normalFont:GetFont())
	frame:SetShadowOffset(0,0)
end

-------------------------------------
-- IMPROVED CHAT SCROLLING ----------
-------------------------------------
-- No modifier 		- scrolls 3 lines at a time
-- Alt 				- scrolls 1 line at a time
-- Shift 			- scrolls a page at a time
-- Ctrl 			- scrolls all the way up or down

local numlines = 3
function FloatingChatFrame_OnMouseScroll(self, delta)
	if delta < 0 then
		if IsControlKeyDown() then
			self:ScrollToBottom()
		elseif IsShiftKeyDown() then
			self:PageDown()
		elseif IsAltKeyDown() then
			self:ScrollDown()
		else
			for i=1, numlines do
				self:ScrollDown()
			end
		end
	elseif delta > 0 then
		if IsControlKeyDown() then
			self:ScrollToTop()
		elseif IsShiftKeyDown() then
			self:PageUp()
		elseif IsAltKeyDown() then
			self:ScrollUp()
		else
			for i=1, numlines do
				self:ScrollUp()
			end
		end
	end
end

-------------------------------------
-- INITIALIZATION -------------------
-------------------------------------

function CHT:OnInitialize()
	-- Kill stuff
	ChatConfigFrameDefaultButton:Kill()
	ChatFrameMenuButton:Kill()
	FriendsMicroButton:Kill()

	SetCVar('chatStyle', 'im')

	for chatID=1, NUM_CHAT_WINDOWS do
		self:SkinChatFrame(_G['ChatFrame'..chatID])

	end

	self:SecureHook('FCFDock_UpdateTabs')
	self:SecureHook('ChatEdit_UpdateHeader')
	self:SecureHook('ChatFrame_OnUpdate')
end