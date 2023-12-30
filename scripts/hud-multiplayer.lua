return {
	dependents =
	{
		"skins.lua",
	},
	text_styles =
	{
	},
	skins =
	{
		{
			name = [[DebugLine]],
			isVisible = true,
			noInput = false,
			anchor = 1,
			rotation = 0,
			x = 0,
			y = 0,
			w = 0,
			h = 0,
			sx = 1,
			sy = 1,
			ctor = [[group]],
			children =
			{
				{
					name = [[bg]],
					isVisible = true,
					noInput = true,
					anchor = 1,
					rotation = 0,
					x = 0,
					xpx = true,
					y = 0,
					ypx = true,
					w = 254,
					wpx = true,
					h = 24,
					hpx = true,
					sx = 1,
					sy = 1,
					ctor = [[image]],
					color =
					{
						0,
						0,
						0,
						0.313725501298904,
					},
					images =
					{
						{
							file = [[white.png]],
							name = [[]],
							color =
							{
								0,
								0,
								0,
								0.313725501298904,
							},
						},
					},
				},
				{
					name = [[txt]],
					isVisible = true,
					noInput = false,
					anchor = 1,
					rotation = 0,
					x = 0,
					xpx = true,
					y = 0,
					ypx = true,
					w = 254,
					wpx = true,
					h = 24,
					hpx = true,
					sx = 1,
					sy = 1,
					ctor = [[label]],
					halign = MOAITextBox.LEFT_JUSTIFY,
					valign = MOAITextBox.CENTER_JUSTIFY,
					text_style = [[font1_14_r]],
				},
			},
		},
	},
	
	widgets =
	{
		{
			name = [[playerListHeader]],
			isVisible = true,
			noInput = false,
			anchor = 5,
			rotation = 0,
			x = 310,
			xpx = true,
			y = 50,
			ypx = true,
			w = 254,
			wpx = true,
			h = 24,
			hpx = true,
			sx = 1,
			sy = 1,
			ctor = [[label]],
			rawstr = "Connected Players",
			halign = MOAITextBox.LEFT_JUSTIFY,
			valign = MOAITextBox.CENTER_JUSTIFY,
			text_style = [[ttheader]],
			color =
			{
				165/255,
				1,
				1,
				1,
			},
		},
		{
			name = [[playerList]],
			isVisible = true,
			noInput = true,
			anchor = 5,
			rotation = 0,
			x = 310,
			xpx = true,
			y = 320,
			ypx = true,
			w = 254,
			wpx = true,
			h = 512,
			hpx = true,
			sx = 1,
			sy = 1,
			ctor = [[listbox]],
			item_template = [[DebugLine]],
			scrollbar_template = [[listbox_vscroll]],
			item_spacing = 24,
			images =
			{
				{
					file = [[]],
					name = [[inactive]],
				},
				{
					--file = [[dbgred.png]],
					file = [[]],
					name = [[active]],
				},
				{
					file = [[]],
					name = [[hover]],
				},
			},
		},
	},
	transitions =
	{
	},
	properties =
	{
		sinksInput = false,
		activateTransition = [[activate_below]],
		deactivateTransition = [[deactivate_below]],
	}
}