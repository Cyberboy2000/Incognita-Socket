local inserts = {
	{
		"modal-saveslots.lua",
		{"widgets", 2, "children", 5, "children"},
		{
			name = [[multiOptionsBG]],
			isVisible = true,
			noInput = false,
			anchor = 1,
			rotation = 0,
			x = 0,
			xpx = true,
			y = 26,
			ypx = true,
			w = 384,
			wpx = true,
			h = 213,
			hpx = true,
			sx = 1,
			sy = 1,
			ctor = [[image]],
			color =
			{
				0.0784313753247261,
				0.0784313753247261,
				0.0784313753247261,
				0.901960790157318,
			},
			images =
			{
				{
					file = [[white.png]],
					name = [[]],
					color =
					{
						0.0784313753247261,
						0.0784313753247261,
						0.0784313753247261,
						0.901960790157318,
					},
				},
			},
		}
	},
	
	{
		"modal-saveslots.lua",
		{"widgets", 2, "children", 5, "children"},
		{
			name = [[multiOptionsBG 2]],
			isVisible = true,
			noInput = false,
			anchor = 1,
			rotation = 0,
			x = 0,
			xpx = true,
			y = 138,
			ypx = true,
			w = 384,
			wpx = true,
			h = 12,
			hpx = true,
			sx = 1,
			sy = 1,
			ctor = [[image]],
			color =
			{
				0.549019634723663,
				1,
				1,
				0.39215686917305,
			},
			images =
			{
				{
					file = [[white.png]],
					name = [[]],
					color =
					{
						0.549019634723663,
						1,
						1,
						0.39215686917305,
					},
				},
			},
		},
	},
	
	{
		"modal-saveslots.lua",
		{"widgets", 2, "children", 7, "children"},
		{
			name = [[hostBtn]],
			isVisible = true,
			noInput = false,
			anchor = 1,
			rotation = 0,
			x = 0,
			xpx = true,
			y = 74,
			ypx = true,
			w = 300,
			wpx = true,
			h = 38,
			hpx = true,
			sx = 1,
			sy = 1,
			ctor = [[button]],
			clickSound = [[SpySociety/HUD/menu/click]],
			hoverSound = [[SpySociety/HUD/menu/rollover]],
			hoverScale = 1,
			rawstr = STRINGS.MULTI_MOD.CONTINUE_HOST,
			halign = MOAITextBox.CENTER_JUSTIFY,
			valign = MOAITextBox.CENTER_JUSTIFY,
			text_style = [[font1_16_r]],
			images =
			{
				{
					file = [[white.png]],
					name = [[inactive]],
					color =
					{
						0.219607844948769,
						0.376470595598221,
						0.376470595598221,
						1,
					},
				},
				{
					file = [[white.png]],
					name = [[hover]],
					color =
					{
						0.39215686917305,
						0.690196096897125,
						0.690196096897125,
						1,
					},
				},
				{
					file = [[white.png]],
					name = [[active]],
					color =
					{
						0.39215686917305,
						0.690196096897125,
						0.690196096897125,
						1,
					},
				},
			},
		}
	},
}

return inserts