local st = SaftUI

UIPARENT_PADDING = 20

POINT_DROPDOWN_CHOICES = {
	'RIGHT',
	'LEFT',
	'CENTER',
	'TOP',
	'BOTTOM',
	'TOPLEFT',
	'TOPRIGHT',
	'BOTTOMLEFT',
	'BOTTOMRIGHT',
}

TEMPLATE_CHOICES = {
	'None',
	'Black',
	'Transparent',
	'Button',
}

local settings = {}

settings.Colors = {
	textnormal			= { 0.9, 0.9, 0.8, 1.0 },
	textred				= { 220/255, 100/255, 100/255 },
	textyellow			= { 200/255, 200/255, 100/255 }, 
	textgreen			= { 240/255, 240/255,  60/255 }, 
	textgrey			= { 100/255, 240/255,  60/255 }, 

	normalborder 		= { 0.0, 0.0, 0.0, 1.0 },
	normalbackdrop 		= { 0.1, 0.1,0.11, 1.0 },
	
	transparentborder 	= { 0.0, 0.0, 0.0, 0.0 },
	transparentbackdrop	= { 0.2, 0.2,0.22, 0.8 },

	buttonborder 		= { 0.0, 0.0, 0.0, 0.0 },
	actionbuttonborder  = { 0.0, 0.0, 0.0, 1.0 },

	buttonnormal		= { 1.0, 1.0, 1.0, 0.1 },
	buttonhover 		= { 0.3, 0.5, 0.7, 0.8 },
	buttonred			= { 0.6, 0.1, 0.1, 0.8 },
	buttongreen			= { 0.1, 0.6, 0.1, 0.8 },
	buttonblue			= { 0.1, 0.1, 0.6, 0.8 },
	buttonyellow		= { 0.6, 0.6, 0.1, 0.8 },
}

settings.Inventory = {
	buttonsize = 30,
	buttonsperrow = 10,
	buttonspacing = 1,
	bankposition = { 'TOPLEFT', 'UIParent', 'TOPLEFT', UIPARENT_PADDING, -116 },
	bagposition = { 'BOTTOMRIGHT', 'UIParent', 'BOTTOMRIGHT', -UIPARENT_PADDING, UIPARENT_PADDING },
	reagentposition = { 'BOTTOMLEFT', 'SaftUI_Bank', 'BOTTOMRIGHT', 10, 0 },
	vendorgreys = true,
	autorepair = true,
}

settings.Minimap = {
	width = 160,
	height = 0,
	padding = 1,
	template = 'Black',
	position = {'TOPRIGHT', 'UIParent', 'TOPRIGHT', -UIPARENT_PADDING, -UIPARENT_PADDING}
}

settings.Experience = {
	width = settings.Minimap.width,
	height = 10,
	padding = settings.Minimap.padding,
	template = 'Black',
	position = {'TOP', 'SaftUI_Minimap', 'BOTTOM', 0, 1},
}

settings.Chat = {
	template = 'Transparent',
	padding = 5, --padding between background and messageframe
	linespacing = 4, --amount of space between chat lines
	width = 400,
	height = 126,
	position = {'BOTTOMLEFT', 'UIParent', 'BOTTOMLEFT', UIPARENT_PADDING, UIPARENT_PADDING}	
}

settings.SpellBook = {
	compact = true,
}

settings.Auras = {	
	enable = true,
	width = 30,
	height = 0,
	
	timertext = {
		enable = false,
		position = {'TOP', 'BOTTOM', 0, -4},
		framelevel = 5,
	},

	timerbar = {
		enable = false,
		vertical = false,
		reversefill = false,
		height = 3,
		width = 30,
		position = { 'TOP', 'BOTTOM', 0, 0 },
		framelevel = 4,
		backdrop = {
			enable = true,
			transparent = true,
			insets = 1,
		},
	},

	count = {
		enable = true,
		position = {'BOTTOMRIGHT', 'BOTTOMRIGHT', 0, 3},
		framelevel = 3,
	},

	buffs = {
		position = {'TOPRIGHT', 'Minimap', 'TOPLEFT', -10, 0},
		direction = 'LEFT',
		wrapafter = 20,
	},
	
	debuffs = {
		position = {'BOTTOMRIGHT', 'Minimap', 'BOTTOMLEFT', -10, 0},
		direction = 'LEFT',
		wrapafter = 20,
	},
	
	backdrop = {
		enable = true,
		transparent = true,
		inset = 1,
	},


	--[[ DEPRECATED ]]
	buffposition = {'TOPRIGHT', 'Minimap', 'TOPLEFT', -10, 0},
	buffdirection = 'LEFT',
	debuffposition = {'BOTTOMRIGHT', 'Minimap', 'BOTTOMLEFT', -10, 0},
	debuffdirection = 'LEFT',
}

--------------------------------------
-- ACTIONBARS ------------------------
--------------------------------------

local function CreateActionBarConfigTable(overwrite)
	return SaftUI.tablemerge({
		enable = true,
		mouseover = false,
		numbuttons = 12,
		buttonsize = 30,
		buttonspacing = 3,
		vertical = false,
		background = {
			enable = false,
			transparent = true,
			anchor = 'BOTTOM',
			width = 12,
			height = 1,
			insets = {
				left = 1,
				right = 1,
				top = 1, 
				bottom = 1,
			}
		},
		position = { 'CENTER', 'UIParent', 'CENTER', 0, 0 },
	}, overwrite or {})
end

settings.ActionBars = {
	enable = true,
	showgrid = true,
	macrotext = false,
	hotkeytext = true,
	Bars = {
		[1] = CreateActionBarConfigTable({
			position = { 'BOTTOM', 'UIParent', 'BOTTOM', 0, UIPARENT_PADDING },
			numbuttons = 9,
			background = {
				-- enable = true,
				height = 2,
			},
		}),
		[2] = CreateActionBarConfigTable({
			position = { 'BOTTOM', 'SaftUI_ActionBar1', 'TOP', 0, 3 },
			numbuttons = 9,
		}),
		[3] = CreateActionBarConfigTable({
			position = { 'BOTTOM', 'SaftUI_ActionBar2', 'TOP', 0, 3 },
			numbuttons = 9,
			-- enable = false,
		}),
		[4] = CreateActionBarConfigTable({
			position = { 'RIGHT', 'UIParent', 'RIGHT',-10,0 },
			vertical = true,
			enable = false,
			mouseover = true,
		}),
		[5] = CreateActionBarConfigTable({
			position = { 'RIGHT', 'SaftUI_ActionBar4', 'LEFT',-3,0 },
			vertical = true,
			enable = false,
		}),
		['pet'] = CreateActionBarConfigTable({
			position = { 'BOTTOM', 'SaftUI_ActionBar3', 'TOP',0,3 },
			background = {
				width = 10,
				enable = true,
			}
		})
	}
}

--------------------------------------
-- Class Bars ------------------------
--------------------------------------
local function CreateClassBarConfigTable(moduleType, overwrite)
	local defaults = {
		enable = true,
		height = 13,
		width = 200,
		orientation = 'horizontal',
		reverse = false,
		point = {'CENTER', UIParent, 'CENTER',0, -200},
	}

	if moduleType == 'stacks' then
		defaults.showEmpty = true
	elseif moduleType == 'bars' then
		defaults.fillDirection = 'right'
	end

	return SaftUI.tablemerge(defaults, overwrite or {});
end

settings.ClassBars = {
	enable = true,
	pixelfont = true,
	fulmination 	= CreateClassBarConfigTable('stacks', {enable=false}),
	totemtimers 	= CreateClassBarConfigTable('bars', {enable=false}),
	combopoints 	= CreateClassBarConfigTable('stacks', {showEmpty=false}),
	runebar 		= CreateClassBarConfigTable('bars'),
	holypower		= CreateClassBarConfigTable('stacks'),
	eclipsebar		= CreateClassBarConfigTable('bars'),
	demonicfury		= CreateClassBarConfigTable('bars'),
	soulshards		= CreateClassBarConfigTable('stacks'),
	burningembers	= CreateClassBarConfigTable('bars'),
	shadoworbs		= CreateClassBarConfigTable('stacks'),
	chi				= CreateClassBarConfigTable('stacks'),
}

--------------------------------------
-- UNITFRAMES ------------------------
--------------------------------------

local function CreateUnitFrameConfigTable(overwrite)
	return SaftUI.tablemerge({
		enable = true,
		position = { 'CENTER', 'UIParent', 'CENTER', 0, 0 },
		framelevel = 1,
		width = 220,
		height = 25,
		backdrop = {
			template = "Transparent",
			-- enable = true,
			insets = { 0 },
		},
		health = {
			enable = true,
			framelevel = 3,
			backdrop = {
				template = "",
				enable = true,
				insets = { -1 },
			},
			text = {
				enable = true,
				position = { 'RIGHT', -5, 0 },
				hidefull = false,
			},
			position = { 'TOP', 0, -1 },
			width = -2, -- width of zero will fallback to unitframe width, negative width will remove that width from the unitframe width
			height = -2, -- height of zero will fallback to unitframe height, negative width will remove that width from the unitframe width
			colorTapping		= true,
			colorDisconnected	= true,
			colorPower			= false,
			colorClass			= false,
			colorClassNPC		= false,
			colorClassPet		= false,
			colorReaction		= false,
			colorSmooth			= true,
			colorCustom			= true,
			customColor			= { 0.3, 0.3, 0.3 },
		},
		power = {
			enable = false,
			framelevel = 5,
			backdrop = {
				template = "",
				enable = true,
				insets = { -1 },
			},
			text = {
				enable = false,
				position = { 'LEFT', 5, 0 },
				hidefull = true,
			},
			position = { 'TOP', 0, -1 },
			width = -2,
			height = 4,
			colorTapping		= false,
			colorDisconnected	= false,
			colorPower			= false,
			colorClass			= true,
			colorClassNPC		= false,
			colorClassPet		= false,
			colorReaction		= true,
			colorSmooth			= true,
			colorCustom			= false,
			customColor			= { 0.3, 0.3, 0.3 },
		},
		name = {
			enable = true,
			position = { 'LEFT', 7, 0 },
			maxlength = 16,
			showlevel = true,
			showclassification = true,
			showsamelevel = false,
			colorClass = true,
			colorReaction = true,
		},
		castbar = {
			enable = false,
			position = {'TOP', 'BOTTOM', 0, 0},
			width = -2,
			height = 1,
			framelevel = 2,
			backdrop = {
				template = "",
				enable = true,
				insets = { -1 },
			},
			text = {
				enable = true,
				position = {'LEFT', 5, -8}
			},
			time = {
				enable = true,
				position = {'RIGHT', -5, -8}
			}
		},
	}, overwrite or {})
end

settings.UnitFrames = {
	units = {
		player = CreateUnitFrameConfigTable( {
			position = { 'TOP', 'UIParent', 'CENTER', 0, -200 },
			name = { enable = false },
			health = { text = { hidefull = true } },
			power = { position = { 'BOTTOM', 0, 1 }, text = { enable = true } },
			castbar = { enable = true },
		} ),
		target = CreateUnitFrameConfigTable( {
			position = { 'TOPLEFT', 'UIParent', 'CENTER', 150, -200 },
			castbar = { enable = true },
		} ),
		pet = CreateUnitFrameConfigTable( {
			position = { 'TOPRIGHT', 'UIParent', 'CENTER', -150, -200 },
			width = 100,
		} ),

		party = CreateUnitFrameConfigTable( {
			width = 220,
			-- height = 19,
			-- name = { maxlength = 4, showlevel = false, position = {'CENTER', 0, 0} },
			backdrop = { enable = false },
			-- health = { text = { enable = false } },
			position = { 'TOP', 'UIParent', 'CENTER', 0, -250 },
			power = { height = 1 },
		} ),

		raid = CreateUnitFrameConfigTable( {
			width = 39,
			height = 23,
			name = { maxlength = 4, showlevel = false, position = {'CENTER', 0, -1} },
			backdrop = { enable = false },
			health = { text = { enable = false } },
			position = { 'TOP', 'UIParent', 'CENTER', 0, -300 },
			power = { height = 1 },
		} ),

		boss = CreateUnitFrameConfigTable( {
			position = { 'BOTTOMLEFT', 'UIParent', 'CENTER', 150, 0 },
			castbar = { enable = true },
		} ),
	}
}
st.Defaults = settings