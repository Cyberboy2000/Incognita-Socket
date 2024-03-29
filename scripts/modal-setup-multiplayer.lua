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
			name = [[menu_btn]],
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
					name = [[btn]],
					isVisible = true,
					noInput = false,
					anchor = 1,
					rotation = 0,
					x = 0,
					xpx = true,
					y = 0,
					ypx = true,
					w = 200,
					wpx = true,
					h = 38,
					hpx = true,
					sx = 1,
					sy = 1,
					ctor = [[button]],
					clickSound = [[SpySociety/HUD/menu/click]],
					hoverSound = [[SpySociety/HUD/menu/rollover]],
					hoverScale = 1,
					str = [[STR_2338805762]],
					halign = MOAITextBox.CENTER_JUSTIFY,
					valign = MOAITextBox.CENTER_JUSTIFY,
					text_style = [[font1_14_r]],
					offset =
					{
						x = -20,
						xpx = true,
						y = 0,
						ypx = true,
					},
					images =
					{
						{
							file = [[white.png]],
							name = [[inactive]],
							color =
							{
								0.30588236451149,
								0.533333361148834,
								0.533333361148834,
								0.705882370471954,
							},
						},
						{
							file = [[white.png]],
							name = [[hover]],
							color =
							{
								0.47843137383461,
								0.843137264251709,
								0.843137264251709,
								0.705882370471954,
							},
						},
						{
							file = [[white.png]],
							name = [[active]],
							color =
							{
								0.47843137383461,
								0.843137264251709,
								0.843137264251709,
								0.705882370471954,
							},
						},
					},
				},
			},
		},
		{
			name = [[SectionHeader]],
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
					name = [[line]],
					isVisible = false,
					noInput = false,
					anchor = 1,
					rotation = 0,
					x = -16,
					xpx = true,
					y = -10,
					ypx = true,
					w = 495,
					wpx = true,
					h = 2,
					hpx = true,
					sx = 1,
					sy = 1,
					ctor = [[image]],
					color =
					{
						1,
						1,
						1,
						1,
					},
					images =
					{
						{
							file = [[white.png]],
							name = [[]],
						},
					},
				},
				{
					name = [[btn]],
					isVisible = true,
					noInput = false,
					anchor = 1,
					rotation = 0,
					x = 0,
					xpx = true,
					y = 0,
					ypx = true,
					w = 495,
					wpx = true,
					h = 28,
					hpx = true,
					sx = 1,
					sy = 1,
					ctor = [[button]],
					clickSound = [[SpySociety/HUD/menu/click]],
					hoverSound = [[SpySociety/HUD/menu/rollover]],
					hoverScale = 1,
					str = [[STR_2338805762]],
					halign = MOAITextBox.RIGHT_JUSTIFY,
					valign = MOAITextBox.CENTER_JUSTIFY,
					text_style = [[font1_14_r]],
					offset =
					{
						x = -20,
						xpx = true,
						y = 0,
						ypx = true,
					},
					images =
					{
						{
							file = [[white.png]],
							name = [[inactive]],
							color =
							{
								0,
								0,
								0,
								0,
							},
						},
						{
							file = [[white.png]],
							name = [[hover]],
							color =
							{
								0.3,
								0.5,
								0.5,
								1,
							},
						},
						{
							file = [[white.png]],
							name = [[active]],
							color =
							{
								0.3,
								0.5,
								0.5,
								1,
							},
						},
					},
				},
			},
		},
		{
			name = [[InputField]],
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
					x = 52,
					xpx = true,
					y = 0,
					ypx = true,
					w = 322,
					wpx = true,
					h = 20,
					hpx = true,
					sx = 1,
					sy = 1,
					ctor = [[image]],
					color =
					{
						0.152941182255745,
						0.152941182255745,
						0.152941182255745,
						0.470588237047195,
					},
					images =
					{
						{
							file = [[white.png]],
							name = [[]],
							color =
							{
								0.152941182255745,
								0.152941182255745,
								0.152941182255745,
								0.470588237047195,
							},
						},
					},
				},
				{
					name = [[editText]],
					isVisible = true,
					noInput = false,
					anchor = 1,
					rotation = 0,
					x = 52,
					xpx = true,
					y = 0,
					ypx = true,
					w = 318,
					wpx = true,
					h = 20,
					hpx = true,
					sx = 1,
					sy = 1,
					ctor = [[editbox]],
					halign = MOAITextBox.RIGHT_JUSTIFY,
					valign = MOAITextBox.CENTER_JUSTIFY,
					text_style = [[font1_16_r]],
					isMultiline = false,
					maxEditChars = 40,
				},
				{
					name = [[label]],
					isVisible = true,
					noInput = true,
					anchor = 1,
					rotation = 0,
					x = -204,
					xpx = true,
					y = -12,
					ypx = true,
					w = 164,
					wpx = true,
					h = 43,
					hpx = true,
					sx = 1,
					sy = 1,
					ctor = [[label]],
					halign = MOAITextBox.RIGHT_JUSTIFY,
					valign = MOAITextBox.LEFT_JUSTIFY,
					text_style = [[font1_16_r]],
					color =
					{
						0.549019634723663,
						1,
						1,
						1,
					},
				},
			}
		},
	},
	widgets =
	{
		{
			name = [[werp]],
			isVisible = true,
			noInput = true,
			anchor = 1,
			rotation = 0,
			x = 0.5,
			y = 0.5,
			w = 0,
			h = 0,
			sx = 1,
			sy = 1,
			ctor = [[group]],
			children =
			{
				{
					name = [[pnl_1]],
					isVisible = true,
					noInput = true,
					anchor = 1,
					rotation = 0,
					x = 0,
					xpx = true,
					y = 153,
					ypx = true,
					w = 1024,
					wpx = true,
					h = 512,
					hpx = true,
					sx = 1,
					sy = 1,
					ctor = [[image]],
					color =
					{
						1,
						1,
						1,
						0.666666686534882,
					},
					images =
					{
						{
							file = [[gui/menu pages/generation_options/mainscreen_generation_options_window1.png]],
							name = [[]],
							color =
							{
								1,
								1,
								1,
								0.666666686534882,
							},
						},
					},
				},
				{
					name = [[refreshBtn]],
					isVisible = true,
					noInput = false,
					anchor = 1,
					rotation = 0,
					x = -150,
					xpx = true,
					y = 50,
					ypx = true,
					w = 0,
					h = 0,
					sx = 1,
					sy = 1,
					skin = [[menu_btn]],
				},
				{
					name = [[hostBtn]],
					isVisible = true,
					noInput = false,
					anchor = 1,
					rotation = 0,
					x = 150,
					xpx = true,
					y = 50,
					ypx = true,
					w = 0,
					h = 0,
					sx = 1,
					sy = 1,
					skin = [[menu_btn]],
				},
				{
					name = [[offlineBtn]],
					isVisible = true,
					noInput = false,
					anchor = 1,
					rotation = 0,
					x = 0,
					xpx = true,
					y = 100,
					ypx = true,
					w = 0,
					h = 0,
					sx = 1,
					sy = 1,
					skin = [[menu_btn]],
				},
				{
					name = [[cancelBtn]],
					isVisible = true,
					noInput = false,
					anchor = 1,
					rotation = 0,
					x = -420,
					xpx = true,
					y = -295,
					ypx = true,
					w = 0,
					h = 0,
					sx = 1,
					sy = 1,
					halign = MOAITextBox.RIGHT_JUSTIFY,
					skin = [[menu_btn]],
				},
				{
					name = [[pnl_options]],
					isVisible = true,
					noInput = false,
					anchor = 1,
					rotation = 0,
					x = 0,
					xpx = true,
					y = -153,
					ypx = true,
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
							w = 1025,
							wpx = true,
							h = 512,
							hpx = true,
							sx = 1,
							sy = 1,
							ctor = [[image]],
							color =
							{
								1,
								1,
								1,
								0.666666686534882,
							},
							images =
							{
								{
									file = [[gui/menu pages/generation_options/mainscreen_generation_options_window2.png]],
									name = [[]],
									color =
									{
										1,
										1,
										1,
										0.666666686534882,
									},
								},
							},
						},
						{
							name = [[list]],
							isVisible = true,
							noInput = false,
							anchor = 1,
							rotation = 0,
							x = 0,
							xpx = true,
							y = -11,
							ypx = true,
							w = 520,
							wpx = true,
							h = 300,
							hpx = true,
							sx = 1,
							sy = 1,
							ctor = [[listbox]],
							item_template = [[SectionHeader]],
							scrollbar_template = [[listbox_vscroll]],
							orientation = 2,
							item_spacing = 28,
							no_hitbox = true,
						},
					},
				},
				{
					name = [[configPanel]],
					isVisible = true,
					noInput = true,
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
							name = [[New Widget]],
							isVisible = true,
							noInput = false,
							anchor = 0,
							rotation = 0,
							x = 0,
							y = 0,
							w = 1,
							h = 1,
							sx = 2,
							sy = 2,
							ctor = [[image]],
							color =
							{
								0,
								0,
								0,
								0.705882370471954,
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
										0.705882370471954,
									},
								},
							},
						},
						{
							name = [[bg]],
							isVisible = true,
							noInput = true,
							anchor = 1,
							rotation = 0,
							x = 0,
							xpx = true,
							y = 53,
							ypx = true,
							w = 1024,
							wpx = true,
							h = 512,
							hpx = true,
							sx = 1,
							sy = 0.9,
							ctor = [[image]],
							color =
							{
								1,
								1,
								1,
								1,
							},
							images =
							{
								{
									file = [[gui/popup_dialog.png]],
									name = [[]],
								},
							},
						},
						{
							name = [[userName]],
							isVisible = true,
							noInput = false,
							anchor = 1,
							rotation = 0,
							x = 0,
							xpx = true,
							y = 47,
							ypx = true,
							w = 0,
							h = 0,
							sx = 1,
							sy = 1,
							skin = [[InputField]]
						},
						{
							name = [[gameTitle]],
							isVisible = true,
							noInput = false,
							anchor = 1,
							rotation = 0,
							x = 0,
							xpx = true,
							y = 7,
							ypx = true,
							w = 0,
							h = 0,
							sx = 1,
							sy = 1,
							skin = [[InputField]]
						},
						{
							name = [[password]],
							isVisible = true,
							noInput = false,
							anchor = 1,
							rotation = 0,
							x = 0,
							xpx = true,
							y = -33,
							ypx = true,
							w = 0,
							h = 0,
							sx = 1,
							sy = 1,
							skin = [[InputField]]
						},
						{
							name = [[okBtn]],
							isVisible = true,
							noInput = false,
							anchor = 1,
							rotation = 0,
							x = 100,
							xpx = true,
							y = -82,
							ypx = true,
							w = 0,
							h = 0,
							sx = 1,
							sy = 1,
							skin = [[screen_button]],
						},
						{
							name = [[backToList]],
							isVisible = true,
							noInput = false,
							anchor = 1,
							rotation = 0,
							x = -100,
							xpx = true,
							y = -82,
							ypx = true,
							w = 0,
							h = 0,
							sx = 1,
							sy = 1,
							skin = [[screen_button]],
						},
						{
							name = [[showPwButton]],
							isVisible = true,
							noInput = false,
							anchor = 1,
							rotation = 0,
							x = 228,
							y = -33,
							xpx = true,
							ypx = true,
							w = 0,
							h = 0,
							sx = 1,
							sy = 1,
							ctor = [[group]],
							children =
							{
								{
									name = [[img]],
									isVisible = true,
									noInput = true,
									anchor = 1,
									rotation = 0,
									x = 0,
									xpx = true,
									y = 0,
									ypx = true,
									w = 20,
									wpx = true,
									h = 20,
									hpx = true,
									sx = 1,
									sy = 1,
									ctor = [[image]],
									color =
									{
										0.109803922474384,
										0.200000002980232,
										0.184313729405403,
										0.800000011920929,
									},
									images =
									{
										{
											file = [[gui/hud3/hud_icon_button_BG.png]],
											name = [[]],
											color =
											{
												0.109803922474384,
												0.200000002980232,
												0.184313729405403,
												0.800000011920929,
											},
										},
									},
								},
								{
									name = [[btn]],
									isVisible = true,
									noInput = false,
									anchor = 1,
									rotation = 0,
									x = 0,
									xpx = true,
									y = 0,
									ypx = true,
									w = 20,
									wpx = true,
									h = 20,
									hpx = true,
									sx = 1,
									sy = 1,
									ctor = [[button]],
									clickSound = [[SpySociety/HUD/gameplay/click]],
									hoverSound = [[SpySociety/HUD/menu/rollover]],
									hoverScale = 1,
									str = [[STR_3601423954]],
									halign = MOAITextBox.CENTER_JUSTIFY,
									valign = MOAITextBox.CENTER_JUSTIFY,
									text_style = [[]],
									images =
									{
										{
											file = "gui/icons/action_icons/Action_icon_Small/icon-action_peek_around.png",
											name = [[inactive]],
											color =
											{
												140/255,
												1,
												1,
												1,
											},
										},
										{
											file = "gui/icons/action_icons/Action_icon_Small/icon-action_peek_around.png",
											name = [[hover]],
											color =
											{
												240/255,
												1,
												1,
												1,
											},
										},
										{
											file = "gui/icons/action_icons/Action_icon_Small/icon-action_peek_around.png",
											name = [[active]],
											color =
											{
												240/255,
												1,
												1,
												0.800000011920929,
											},
										},
									},
								},
							},
						},
					}
				},
				
			}
		},
		{
			name = [[panel]],
			isVisible = true,
			noInput = true,
			anchor = 1,
			rotation = 0,
			x = 0.5,
			y = 0.4583333,
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
					y = 53,
					ypx = true,
					w = 1024,
					wpx = true,
					h = 512,
					hpx = true,
					sx = 1,
					sy = 0.9,
					ctor = [[image]],
					color =
					{
						1,
						1,
						1,
						1,
					},
					images =
					{
						{
							file = [[gui/popup_dialog.png]],
							name = [[]],
						},
					},
				},
				{
					name = [[headerTxt]],
					isVisible = true,
					noInput = true,
					anchor = 1,
					rotation = 0,
					x = 0,
					xpx = true,
					y = 131,
					ypx = true,
					w = 500,
					wpx = true,
					h = 43,
					hpx = true,
					sx = 1,
					sy = 1,
					ctor = [[label]],
					halign = MOAITextBox.CENTER_JUSTIFY,
					valign = MOAITextBox.LEFT_JUSTIFY,
					text_style = [[font1_36_r]],
					color =
					{
						0.549019634723663,
						1,
						1,
						1,
					},
					rawstr = "MULTIPLAYER SETUP",
				},
				{
					name = [[headerTxt2]],
					isVisible = true,
					noInput = false,
					anchor = 1,
					rotation = 0,
					x = 0,
					xpx = true,
					y = 73,
					ypx = true,
					w = 350,
					wpx = true,
					h = 70,
					hpx = true,
					sx = 1,
					sy = 1,
					ctor = [[label]],
					halign = MOAITextBox.CENTER_JUSTIFY,
					valign = MOAITextBox.CENTER_JUSTIFY,
					text_style = [[font1_16_r]],
					rawstr = "",
				},
				{
					name = [[configPanel]],
					isVisible = true,
					noInput = true,
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
							name = [[ipAdressBG]],
							isVisible = true,
							noInput = true,
							anchor = 1,
							rotation = 0,
							x = 52,
							xpx = true,
							y = 20,
							ypx = true,
							w = 322,
							wpx = true,
							h = 20,
							hpx = true,
							sx = 1,
							sy = 1,
							ctor = [[image]],
							color =
							{
								0.152941182255745,
								0.152941182255745,
								0.152941182255745,
								0.470588237047195,
							},
							images =
							{
								{
									file = [[white.png]],
									name = [[]],
									color =
									{
										0.152941182255745,
										0.152941182255745,
										0.152941182255745,
										0.470588237047195,
									},
								},
							},
						},
						{
							name = [[portBG]],
							isVisible = true,
							noInput = true,
							anchor = 1,
							rotation = 0,
							x = 52,
							xpx = true,
							y = -7,
							ypx = true,
							w = 322,
							wpx = true,
							h = 20,
							hpx = true,
							sx = 1,
							sy = 1,
							ctor = [[image]],
							color =
							{
								0.152941182255745,
								0.152941182255745,
								0.152941182255745,
								0.470588237047195,
							},
							images =
							{
								{
									file = [[white.png]],
									name = [[]],
									color =
									{
										0.152941182255745,
										0.152941182255745,
										0.152941182255745,
										0.470588237047195,
									},
								},
							},
						},
						{
							name = [[pwBg]],
							isVisible = true,
							noInput = true,
							anchor = 1,
							rotation = 0,
							x = 52,
							xpx = true,
							y = -35,
							ypx = true,
							w = 322,
							wpx = true,
							h = 20,
							hpx = true,
							sx = 1,
							sy = 1,
							ctor = [[image]],
							color =
							{
								0.152941182255745,
								0.152941182255745,
								0.152941182255745,
								0.470588237047195,
							},
							images =
							{
								{
									file = [[white.png]],
									name = [[]],
									color =
									{
										0.152941182255745,
										0.152941182255745,
										0.152941182255745,
										0.470588237047195,
									},
								},
							},
						},
						{
							name = [[ipAdress]],
							isVisible = true,
							noInput = false,
							anchor = 1,
							rotation = 0,
							x = 52,
							xpx = true,
							y = 20,
							ypx = true,
							w = 322,
							wpx = true,
							h = 20,
							hpx = true,
							sx = 1,
							sy = 1,
							ctor = [[editbox]],
							halign = MOAITextBox.RIGHT_JUSTIFY,
							valign = MOAITextBox.CENTER_JUSTIFY,
							text_style = [[font1_16_r]],
							isMultiline = false,
							maxEditChars = 40,
						},
						{
							name = [[port]],
							isVisible = true,
							noInput = false,
							anchor = 1,
							rotation = 0,
							x = 52,
							xpx = true,
							y = -7,
							ypx = true,
							w = 322,
							wpx = true,
							h = 20,
							hpx = true,
							sx = 1,
							sy = 1,
							ctor = [[editbox]],
							halign = MOAITextBox.RIGHT_JUSTIFY,
							valign = MOAITextBox.CENTER_JUSTIFY,
							text_style = [[font1_16_r]],
							isMultiline = false,
							maxEditChars = 8,
						},
						{
							name = [[pw]],
							isVisible = true,
							noInput = false,
							anchor = 1,
							rotation = 0,
							x = 30,
							xpx = true,
							y = -35,
							ypx = true,
							w = 322,
							wpx = true,
							h = 20,
							hpx = true,
							sx = 1,
							sy = 1,
							ctor = [[editbox]],
							halign = MOAITextBox.RIGHT_JUSTIFY,
							valign = MOAITextBox.CENTER_JUSTIFY,
							text_style = [[font1_16_r]],
							isMultiline = false,
							maxEditChars = 40,
						},
						{
							name = [[showPwButton]],
							isVisible = true,
							noInput = false,
							anchor = 1,
							rotation = 0,
							x = 203,
							y = -35,
							xpx = true,
							ypx = true,
							w = 0,
							h = 0,
							sx = 1,
							sy = 1,
							ctor = [[group]],
							children =
							{
								{
									name = [[img]],
									isVisible = true,
									noInput = true,
									anchor = 1,
									rotation = 0,
									x = 0,
									xpx = true,
									y = 0,
									ypx = true,
									w = 20,
									wpx = true,
									h = 20,
									hpx = true,
									sx = 1,
									sy = 1,
									ctor = [[image]],
									color =
									{
										0.109803922474384,
										0.200000002980232,
										0.184313729405403,
										0.800000011920929,
									},
									images =
									{
										{
											file = [[gui/hud3/hud_icon_button_BG.png]],
											name = [[]],
											color =
											{
												0.109803922474384,
												0.200000002980232,
												0.184313729405403,
												0.800000011920929,
											},
										},
									},
								},
								{
									name = [[btn]],
									isVisible = true,
									noInput = false,
									anchor = 1,
									rotation = 0,
									x = 0,
									xpx = true,
									y = 0,
									ypx = true,
									w = 20,
									wpx = true,
									h = 20,
									hpx = true,
									sx = 1,
									sy = 1,
									ctor = [[button]],
									clickSound = [[SpySociety/HUD/gameplay/click]],
									hoverSound = [[SpySociety/HUD/menu/rollover]],
									hoverScale = 1,
									str = [[STR_3601423954]],
									halign = MOAITextBox.CENTER_JUSTIFY,
									valign = MOAITextBox.CENTER_JUSTIFY,
									text_style = [[]],
									images =
									{
										{
											file = "gui/icons/action_icons/Action_icon_Small/icon-action_peek_around.png",
											name = [[inactive]],
											color =
											{
												140/255,
												1,
												1,
												1,
											},
										},
										{
											file = "gui/icons/action_icons/Action_icon_Small/icon-action_peek_around.png",
											name = [[hover]],
											color =
											{
												240/255,
												1,
												1,
												1,
											},
										},
										{
											file = "gui/icons/action_icons/Action_icon_Small/icon-action_peek_around.png",
											name = [[active]],
											color =
											{
												240/255,
												1,
												1,
												0.800000011920929,
											},
										},
									},
								},
							},
						},
						{
							name = [[ipTxt]],
							isVisible = true,
							noInput = true,
							anchor = 1,
							rotation = 0,
							x = -204,
							xpx = true,
							y = 8,
							ypx = true,
							w = 164,
							wpx = true,
							h = 43,
							hpx = true,
							sx = 1,
							sy = 1,
							ctor = [[label]],
							halign = MOAITextBox.RIGHT_JUSTIFY,
							valign = MOAITextBox.LEFT_JUSTIFY,
							text_style = [[font1_16_r]],
							color =
							{
								0.549019634723663,
								1,
								1,
								1,
							},
							rawstr = "IP Adress",
						},
						{
							name = [[portTxt]],
							isVisible = true,
							noInput = true,
							anchor = 1,
							rotation = 0,
							x = -204,
							xpx = true,
							y = -18,
							ypx = true,
							w = 164,
							wpx = true,
							h = 43,
							hpx = true,
							sx = 1,
							sy = 1,
							ctor = [[label]],
							halign = MOAITextBox.RIGHT_JUSTIFY,
							valign = MOAITextBox.LEFT_JUSTIFY,
							text_style = [[font1_16_r]],
							color =
							{
								0.549019634723663,
								1,
								1,
								1,
							},
							rawstr = "Port",
						},
						{
							name = [[pwTxt]],
							isVisible = true,
							noInput = true,
							anchor = 1,
							rotation = 0,
							x = -205,
							xpx = true,
							y = -46,
							ypx = true,
							w = 164,
							wpx = true,
							h = 43,
							hpx = true,
							sx = 1,
							sy = 1,
							ctor = [[label]],
							halign = MOAITextBox.RIGHT_JUSTIFY,
							valign = MOAITextBox.LEFT_JUSTIFY,
							text_style = [[font1_16_r]],
							color =
							{
								0.549019634723663,
								1,
								1,
								1,
							},
							rawstr = "Password",
						},
						{
							name = [[okBtn]],
							isVisible = true,
							isVisible = true,
							noInput = false,
							anchor = 1,
							rotation = 0,
							x = 100,
							xpx = true,
							y = -82,
							ypx = true,
							w = 0,
							h = 0,
							sx = 1,
							sy = 1,
							skin = [[screen_button]],
						},
						{
							name = [[backToModeBtn]],
							isVisible = true,
							noInput = false,
							anchor = 1,
							rotation = 0,
							x = -100,
							xpx = true,
							y = -82,
							ypx = true,
							w = 0,
							h = 0,
							sx = 1,
							sy = 1,
							skin = [[screen_button]],
						},
					}
				},
				{
					name = [[modePanel]],
					isVisible = true,
					noInput = true,
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
							name = [[hostBtn]],
							isVisible = true,
							noInput = false,
							anchor = 1,
							rotation = 0,
							x = 0,
							xpx = true,
							y = 8,
							ypx = true,
							w = 0,
							h = 0,
							sx = 1,
							sy = 1,
							skin = [[screen_button]],
						},
						{
							name = [[joinBtn]],
							isVisible = true,
							noInput = false,
							anchor = 1,
							rotation = 0,
							x = 0,
							xpx = true,
							y = -37,
							ypx = true,
							w = 0,
							h = 0,
							sx = 1,
							sy = 1,
							skin = [[screen_button]],
						},
						{
							name = [[singlePlayerBtn]],
							isVisible = true,
							noInput = false,
							anchor = 1,
							rotation = 0,
							x = 0,
							xpx = true,
							y = -82,
							ypx = true,
							w = 0,
							h = 0,
							sx = 1,
							sy = 1,
							skin = [[screen_button]],
						},
						{
							name = [[cancelBtn]],
							isVisible = true,
							noInput = false,
							anchor = 1,
							rotation = 0,
							x = 0,
							xpx = true,
							y = -137,
							ypx = true,
							w = 0,
							h = 0,
							sx = 1,
							sy = 1,
							skin = [[screen_button]],
						},
					}
				}
			},
		},
	},
	transitions =
	{
	},
	properties =
	{
		sinksInput = true,
		activateTransition = [[activate_below]],
		deactivateTransition = [[deactivate_below]],
	}
}