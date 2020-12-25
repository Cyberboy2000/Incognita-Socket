local util = include( "client_util" )
local mathutil = include( "modules/mathutil" )
local cdefs = include( "client_defs" )
local array = include( "modules/array" )
local mui_defs = include( "mui/mui_defs")
local world_hud = include( "hud/hud-inworld" )
local hudtarget = include( "hud/targeting")
local rig_util = include( "gameplay/rig_util" )
local level = include( "sim/level" )
local mainframe = include( "sim/mainframe" )
local simquery = include( "sim/simquery" )
local simdefs = include( "sim/simdefs" )

--------------------------------------------------
--                     TODO                     --
-- Use this to check whether an action is legal --
--------------------------------------------------

return {
	debugAction = function( sim )
		return false
	end,

	useDoorAction = function( sim, exitOp, unitID, x, y, dir )
		if not unitID or not exitOp or not x or not y or not dir then
			return false
		end
	
		local unit = sim:getUnit(unitID)
		local cell = sim:getCellByID(x,y)
		
		if not unit or not cell then
			return false
		end
	
		if not simquery.canReachDoor( unit, cell, dir ) then
			return false
		end

		local exit = cell.exits[dir]
		if not exit or not exit.door then
			return false
		end
		
		if exitOp == simdefs.EXITOP_CLOSE and exit.no_close then 
			return false 
		end

		return simquery.canModifyExit( unit, exitOp, cell, dir )
	end,
	
	abilityAction = function( sim, ownerID, userID, abilityIdx, ... )
		if not ownerID or not userID or not abilityIdx then
			return false
		end
	
		local player = sim:getCurrentPlayer()
		local abilityOwner = sim:getUnit( ownerID ) or array.findIf( sim:getPlayers(), function( p ) return p:getID() == ownerID end )
		local abilityUser = sim:getUnit( userID ) or array.findIf( sim:getPlayers(), function( p ) return p:getID() == userID end )
		
		if not abilityOwner or not abilityUser then
			return false
		end

		local ability = abilityOwner:getAbilities()[ abilityIdx ]
		if not ability then
			return false
		end
		
		if ability:getDef().equip_program then
			return true
		else
			return abilityUser:canUseAbility( sim, ability, abilityOwner, ... )
		end
	end,
	
	mainframeAction = function( sim, updates )
		if type(updates) == "table" then
			if updates.action == "breakIce" then
				if updates.unitID then
					local unit = sim:getUnit(updates.unitID)
					if unit and unit:isValid() and mainframe.canBreakIce( sim, unit, program ) then
						return true
					end
				end
			elseif updates.action == "targetUnit" then
				if updates.unitID then
					local unit = sim:getUnit(updates.unitID)
					local canUse, reason = mainframe.canTargetUnit( sim, unit )
				end
			elseif updates.action == "use" then
				if updates.unitID then
					local unit = sim:getUnit(updates.unitID)
					
					if unit and unit:getUnitData().uses_mainframe and unitRaw:getTraits().mainframe_status ~= "off" then
						for useName, useData in pairs(unit:getUnitData().uses_mainframe) do
							if useData.fn == updates.fn and useData.canToggle(unit) then
								return true
							end
						end
					end
				end
			end
		end
		
		return false
	end,
	
	--search = function ( sim, cellUnit )
		--if simquery.canLoot( sim, unit, cellUnit ) then
		
	moveAction = function( sim, unitID, moveTable )
		local MAX_PATH = 15
	
		if unitID and type(moveTable) == "table" then
			local player = sim:getCurrentPlayer()
			local unit = sim:getUnit( unitID )
			
			local endcell = moveTable[#moveTable]
			if unit and type(endcell) == "table" then
				local cellx, celly = endcell.x, endcell.y
				
				if cellx and celly then
					local endcell = sim:getCell( cellx, celly )
					local startcell = sim:getCell( unit:getLocation() )

					if endcell and startcell ~= endcell then
						if sim:getTags().blockMoveCentral then 
							if not unit:getTraits().central then
								if simquery.cellHasTag( sim, endcell, "interruptNonCentral" ) then 
									return false
								end 
							end 
						end 

						if unit:getPlayerOwner() == player and unit:hasTrait("mp") and unit:canAct() then
							local moveTable, pathCost = simquery.findPath( sim, unit, startcell, endcell, unit:getMP() )
							if moveTable and pathCost <= unit:getMP() then
								return true
							end
						end
					end
				end
			end
		end
	end,
	
	tradeItem = function( sim, unitID, shopUnitID, itemIndex, discount, itemType, buyback )
		local unit = sim:getUnit( unitID ) or sim:getPlayerByID(unitID)
		local shopUnit = sim:getUnit( shopUnitID )
		local player = sim:getCurrentPlayer()
		assert( unit )
		assert( unit == player or unit:getPlayerOwner() == player )

		-- Remove the option from the store.
		local item = nil
		if buyback then 
			if itemType == "item" then 
				item = table.remove( shopUnit.buyback.items, itemIndex )
			elseif itemType == "weapon" then 
				item = table.remove( shopUnit.buyback.weapons, itemIndex )
			elseif itemType == "augment" then 
				item = table.remove( shopUnit.buyback.augments, itemIndex )
			end 
		else 
			if itemType == "item" then 
				item = table.remove( shopUnit.items, itemIndex )
			elseif itemType == "weapon" then 
				item = table.remove( shopUnit.weapons, itemIndex )
			elseif itemType == "augment" then 
				item = table.remove( shopUnit.augments, itemIndex )
			end 
		end 

		sim:getStats():incStat( "items_earned" )
		
			-- Items with 'def' are mainframe programs, not simunits. Gross!
		if item:getTraits().mainframe_program then
			table.insert(sim._resultTable.new_programs, item:getTraits().mainframe_program)
			assert( not player:hasMainframeAbility( item:getTraits().mainframe_program ) )
			sim:getStats():incStat( "programs_earned" )
			
			sim:dispatchEvent( simdefs.EV_PLAY_SOUND, "SpySociety/VoiceOver/Incognita/Pickups/NewProgram" )

			player:addMainframeAbility( sim, item:getTraits().mainframe_program )
			local mainframeDef = abilitydefs.lookupAbility(item:getTraits().mainframe_program)
			local dialogParams =
			{
				STRINGS.PROGRAMS.INSTALLED,
				item:getName(),
				string.format( STRINGS.PROGRAMS.INSTALLED_DESC, mainframeDef.desc),
				mainframeDef.icon_100,
				color = {r=1,g=0,b=0,a=1}
			}
			sim:dispatchEvent( simdefs.EV_SHOW_DIALOG, { dialog = "programDialog", dialogParams = dialogParams } )

		else
			if buyback then 
				unit:addChild( item )
				inventory.autoEquip( unit )
			else 
				sim:spawnUnit( item )
				unit:addChild( item )
				inventory.autoEquip( unit )
			end 

			if itemType == "augment" then 
								
				local result = mission_util.showAugmentInstallDialog( sim, item, unit )
				if result == 2 then
					local abilityDef = unit:ownsAbility( "installAugment" )
					if abilityDef:canUseAbility( sim, item, unit ) then 
						abilityDef:executeAbility( sim, item, unit )
					else 
						mission_util.showDialog( sim, STRINGS.UI.INSTALL_AUGMENT, STRINGS.UI.PUTTING_AUGMENT_IN_INVENTORY )
					end 
				end 
			end
			unit:checkOverload( sim )
		end

		sim:triggerEvent( simdefs.TRG_BUY_ITEM, {shopUnit = shopUnit, unit = unit, item = item} )

		sim:dispatchEvent( simdefs.EV_ITEMS_PANEL ) -- Triggers refresh.
	end,

	buyItem = function( sim, unitID, shopUnitID, itemIndex, discount, itemType, buyback )
		local unit = sim:getUnit( unitID ) or sim:getPlayerByID(unitID)
		local shopUnit = sim:getUnit( shopUnitID )
		local player = sim:getCurrentPlayer()
		assert( unit )
		assert( unit == player or unit:getPlayerOwner() == player )

		-- Remove the option from the store.
		local item = nil
		if buyback then 
			if itemType == "item" then 
				item = table.remove( shopUnit.buyback.items, itemIndex )
			elseif itemType == "weapon" then 
				item = table.remove( shopUnit.buyback.weapons, itemIndex )
			elseif itemType == "augment" then 
				item = table.remove( shopUnit.buyback.augments, itemIndex )
			end 
		else 
			if itemType == "item" then 
				item = table.remove( shopUnit.items, itemIndex )
			elseif itemType == "weapon" then 
				item = table.remove( shopUnit.weapons, itemIndex )
			elseif itemType == "augment" then 
				item = table.remove( shopUnit.augments, itemIndex )
			end 
		end 

		sim:getStats():incStat( "items_earned" )
		
		-- Pay up.
		local credits = item:getUnitData().value * discount
		assert( player:getCredits() >= credits )
		player:addCredits( -credits )
		sim._resultTable.credits_lost.buying = sim._resultTable.credits_lost.buying and sim._resultTable.credits_lost.buying + credits or credits

		
		sim:getStats():sumStat( itemType .. "_purchases", -credits )

		-- Items with 'def' are mainframe programs, not simunits. Gross!
		if item:getTraits().mainframe_program then
			table.insert(sim._resultTable.new_programs, item:getTraits().mainframe_program)
			assert( not player:hasMainframeAbility( item:getTraits().mainframe_program ) )
			sim:getStats():incStat( "programs_earned" )
			
			sim:dispatchEvent( simdefs.EV_PLAY_SOUND, "SpySociety/VoiceOver/Incognita/Pickups/NewProgram" )

			player:addMainframeAbility( sim, item:getTraits().mainframe_program )
			local mainframeDef = abilitydefs.lookupAbility(item:getTraits().mainframe_program)
			local dialogParams =
			{
				STRINGS.PROGRAMS.PURCHASED,
				item:getName(),
				string.format( STRINGS.PROGRAMS.PURCHASED_DESC, mainframeDef.desc),
				mainframeDef.icon_100,
				color = {r=1,g=0,b=0,a=1}
			}
			sim:dispatchEvent( simdefs.EV_SHOW_DIALOG, { dialog = "programDialog", dialogParams = dialogParams } )

		else
			if buyback then 
				unit:addChild( item )
				inventory.autoEquip( unit )
			else 
				sim:spawnUnit( item )
				unit:addChild( item )
				inventory.autoEquip( unit )
			end 

			if itemType == "augment" then 
								
				local result = mission_util.showAugmentInstallDialog( sim, item, unit )
				if result == 2 then
					local abilityDef = unit:ownsAbility( "installAugment" )
					if abilityDef:canUseAbility( sim, item, unit ) then 
						abilityDef:executeAbility( sim, item, unit )
					else 
						mission_util.showDialog( sim, STRINGS.UI.INSTALL_AUGMENT, STRINGS.UI.PUTTING_AUGMENT_IN_INVENTORY )
					end 
				end 
			end
			unit:checkOverload( sim )
		end

		sim:triggerEvent( simdefs.TRG_BUY_ITEM, {shopUnit = shopUnit, unit = unit, item = item} )

		sim:dispatchEvent( simdefs.EV_ITEMS_PANEL ) -- Triggers refresh.
	end,

	sellItem = function( sim, unitID, shopUnitID, itemIndex )
		local unit = sim:getUnit( unitID )
		local shopUnit = sim:getUnit( shopUnitID )
		local player = sim:getCurrentPlayer()

		assert( unit:getPlayerOwner() == player )

		local item = unit:getChildren()[ itemIndex ]

		if item:hasAbility("equippable") then 
			table.insert( shopUnit.buyback.weapons, item )
		elseif item:hasTrait("augment") then
			table.insert( shopUnit.buyback.augments, item )
		else
			table.insert( shopUnit.buyback.items, item )
		end 

		if item:getTraits().equipped then
			inventory.unequipItem( unit, item )
		end
		unit:removeChild( item )

		local credits = math.ceil( item:getUnitData().value * 0.5 )
		player:addCredits( credits )
		sim._resultTable.credits_gained.selling = sim._resultTable.credits_gained.selling and sim._resultTable.credits_gained.selling + credits or credits

		sim:dispatchEvent( simdefs.EV_ITEMS_PANEL )
	end,

	tradeAbility = function( sim, index, unitID)
		local player = sim:getCurrentPlayer()
		local ability = player:getAbilities()[index]
		assert(ability)
	 
		local unit = sim:getUnit(unitID)

		local abilityDef = ability
		local abilityName = ability._abilityID

		assert( abilityDef )
		assert( sim )

		if abilityDef.abilityOverride then
			if sim:isVersion( abilityDef.abilityOverride[2]) then    
				abilityDef =  mainframe_abilities[abilityDef.abilityOverride[1] ]
			end
		end

		local program = {
			type = "simunit", 
			name = abilityDef.name,
			program = true,
			traits = 
			{
				mainframe_program = abilityName, 
			},
			onTooltip = function( tooltip, unit )

				-- FIXME: should delegate to ability, but the parameters are different! (No hud access here)
				tooltip:addLine( abilityDef.name, util.sformat( STRINGS.PROPS.STORE_PROGRAM_TOOLTIP, abilityDef:getCpuCost() ))
				if abilityDef.maxCooldown and abilityDef.maxCooldown > 0  then
					tooltip:addLine( util.sformat( STRINGS.PROGRAMS.COOLDOWN, abilityDef.maxCooldown )  )
				end					
				tooltip:addAbility( abilityDef.shortdesc, abilityDef.desc, "gui/icons/action_icons/Action_icon_Small/icon-item_shoot_small.png" )
		
			end,

			profile_icon_100 = abilityDef.icon_100,
			value = abilityDef.value
		}

		program = simfactory.createUnit( program, sim )

		table.insert(unit.items,program)

		player:removeAbility( sim, ability )
		sim:dispatchEvent( simdefs.EV_ITEMS_PANEL )
	end,


	sellAbility = function( sim, index )
		local player = sim:getCurrentPlayer()
		local ability = player:getAbilities()[index]
		assert(ability)

		player:removeAbility( sim, ability )

		if ability.value then
			local credits = math.ceil( ability.value * 0.5 )
			player:addCredits( credits )
		end
		sim:dispatchEvent( simdefs.EV_ITEMS_PANEL )
	end,

	transferItem = function( sim, unitID, targetID, itemIndex )
		local unit = sim:getUnit( unitID )
		local targetUnit = sim:getUnit( targetID )
		local player = sim:getCurrentPlayer()
		assert( unit:getPlayerOwner() == player )

		local item = unit:getChildren()[ itemIndex ]
		if targetUnit then
			inventory.giveItem( unit, targetUnit, item )
			targetUnit:checkOverload( sim )
		else
			inventory.dropItem( sim, unit, item )
			unit:checkOverload( sim )
		end

		sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = unit } )
		sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = targetUnit } )

		sim:dispatchEvent( simdefs.EV_ITEMS_PANEL )
	end,

	lootItem = function( sim, unitID, itemID )
		local unit = sim:getUnit( unitID )
		local item = sim:getUnit( itemID )
		assert( unit:getPlayerOwner() == sim:getCurrentPlayer() )

		local cell = sim:getCell( item:getLocation() )
		if cell then
			if item:hasAbility( "carryable" ) then
				inventory.pickupItem( sim, unit, item )
				sim:emitSound( simdefs.SOUND_ITEM_PICKUP, cell.x, cell.y, unit )				
			
			elseif item:getTraits().cashOnHand then 
				
				local credits = math.floor( simquery.calculateCashOnHand( sim, item ) * (1 + (unit:getTraits().stealBonus or 0)) )
				sim._resultTable.credits_gained.pickpocket = sim._resultTable.credits_gained.pickpocket and sim._resultTable.credits_gained.pickpocket + credits or credits
				unit:getPlayerOwner():addCredits( credits, sim, cell.x, cell.y )
				item:getTraits().cashOnHand = nil
				sim:dispatchEvent( simdefs.EV_PLAY_SOUND, simdefs.SOUND_CREDITS_PICKUP.path )

			elseif item:getTraits().credits then

				local credits = item:getTraits().credits
				sim._resultTable.credits_gained.safes = sim._resultTable.credits_gained.safes and sim._resultTable.credits_gained.safes + credits or credits
				unit:getPlayerOwner():addCredits( credits, sim, cell.x, cell.y )
				item:getTraits().credits = nil
				sim:dispatchEvent( simdefs.EV_PLAY_SOUND, simdefs.SOUND_CREDITS_PICKUP.path )

			elseif item:getTraits().PWROnHand then
				local PWR = simquery.calculatePWROnHand( sim, item )  
				unit:getPlayerOwner():addCPUs( PWR, sim, cell.x, cell.y)
				item:getTraits().PWROnHand = nil	
				sim:dispatchEvent( simdefs.EV_PLAY_SOUND, "SpySociety/Actions/item_pickup" )		
			end
		else
			local itemOwner = item:getUnitOwner()
			inventory.giveItem( itemOwner, unit, item)

			local itemDef = item:getUnitData()
			if itemDef.traits.showOnce then
				local dialogParams =
				{
					STRINGS.UI.ITEM_ACQUIRED, itemDef.name, itemDef.desc, itemDef.profile_icon_100,
				}
				sim:dispatchEvent( simdefs.EV_SHOW_DIALOG, { showOnce = itemDef.traits.showOnce, dialog = "programDialog", dialogParams = dialogParams } )
			end
		end

		item:getTraits().anarchySpecialItem = nil
		item:getTraits().largeSafeMapIntel = nil

		inventory.autoEquip( unit )
		unit:resetAllAiming()
		unit:checkOverload( sim )

		sim:dispatchEvent( simdefs.EV_ITEMS_PANEL ) -- Triggers refresh.
	end,

	abortMission = function( sim )
		return false
	end,

	resignMission = function( sim )
		return false
	end,
	
	rewindAction = function( sim )
		return false
	end,
	
	triggerAction = function( sim, eventType, eventData )
		--if eventType == simdefs.TRG_UI_ACTION then
		--	return true
		--end
		return false
	end,
	
	local_triggerAction = function( sim, eventType, eventData )
		return true
	end,
	
	local_abortMission = function( sim, eventType, eventData )
		return true
	end,
	
	local_resignMission = function( sim, eventType, eventData )
		return true
	end,
	
	local_rewindAction = function( sim )
		return true
	end,
}

