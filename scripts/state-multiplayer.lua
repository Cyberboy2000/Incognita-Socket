local util = include( "client_util" )
local version = include( "modules/version" )
local mui = include("mui/mui")
local mui_defs = include("mui/mui_defs")
local mui_util = include("mui/mui_util")
local cdefs = include( "client_defs" )
local modalDialog = include( "states/state-modal-dialog" )
local cheatmenu = include( "fe/cheatmenu" )
local simactions = include("sim/simactions")
local serializer = include( "modules/serialize" )
local boardrig = include( "gameplay/boardrig" )
local gameobj = include( "modules/game" )
local serverdefs = include( "modules/serverdefs" )
local hud = include( "hud/hud" )
local simguard = include( "modules/simguard" )
local simdefs = include( "sim/simdefs" )
local simquery = include( "sim/simquery" )
local viz_manager = include( "gameplay/viz_manager" )
local level = include( "sim/level" )

local stateMultiplayer = {}

----------------------------------------------------------------
--   Set up a TCP server and read messages from the clients   --
----------------------------------------------------------------

function stateMultiplayer:onLoad( uplink, ... )
	assert(uplink)
	assert(not self.uplink)
	self.uplink = uplink
	return uplink:onLoad(self, ...)
end

function stateMultiplayer:onUnload(  )
	self.uplink:onUnload(  )
	self.uplink = nil
	self.game = nil
	self.campaign = nil
end

function stateMultiplayer:onUpdate(  )
	self.uplink:onUpdate(  )
end

function stateMultiplayer:getUplink(  )
	return self.uplink
end

function stateMultiplayer:startGame( game )
	assert(game and game.simCore and game.simHistory)
	assert(self.game == nil)
	assert(self:getUplink())
	self.game = game
	game:fromOnlineHistory(self.onlineHistory)
	game.debugstep = nil
end

function stateMultiplayer:endGame( )
	assert(self.game)
	self.game = nil
	self.onlineHistory = nil
end

function stateMultiplayer:getCurrentGame( )
    return self.game
end

function stateMultiplayer:isHost()
	return self.uplink and self.uplink:isHost()
end

function stateMultiplayer:isClient()
	return self.uplink and not self.uplink:isHost()
end

function stateMultiplayer:mergeCampaign(tmerge)
	return util.tmerge(tmerge or {},self.campaign,{
				onlineHistory = self.onlineHistory,
				reqSockV = multiMod.COMPABILITY_VERSION,
			})
end

function stateMultiplayer:loadCampaignGame(campaign)
	if self.uplink then
		if self:isHost() then
			-- For now, we simply let the host decide everything that happens outside of a mission
			
			self.campaign = campaign
			self.onlineHistory = {}
			
			if campaign.sim_history then
				local serializer = include( "modules/serialize" )
				local simHistory = serializer.deserialize( campaign.sim_history )
				
				for i, action in ipairs(simHistory) do
					table.insert(self.onlineHistory,action)
				end
			end
			
			self.uplink:send(self:mergeCampaign())
		end
	end
end

----------------------------------------------------------------
--                   Handle game logic here                   --
----------------------------------------------------------------

function stateMultiplayer:receiveData(client,data,line)
	-- Handle game logic here
	if multiMod.VERBOSE then
		log:write("Received "..line)
	end
	
	if type(data) == "table" then
		if self.onlineHistory and type(data.ohi) == "number" then
			if multiMod.VERBOSE then
				log:write("Comparing #self.onlineHistory + 1 "..tostring(#self.onlineHistory + 1).." = "..tostring(data.ohi))
			end
			
			if #self.onlineHistory + 1 == data.ohi then
				if self:canTakeAction( data.name, unpack( data ) ) then
				
					-- Add a new action to the history
					table.insert(self.onlineHistory,data)
					
					
					--if data.crc then
						-- TODO: Could check the "crc" here, but that would require skipping the simThread.
					--end
					
					if self:isHost() then
						-- Update all of the clients with the same data, except the one we received it from
						self.uplink:echoLine(line,client)
					end
					
					local game = self:getCurrentGame()
					if game then
						if game.hud and data.name == "triggerAction" then
							game.hud:hideItemsPanel()
						end
					
						-- Actually do the action
						game:doRemoteAction(data)
					end
				end
			elseif self:isClient() and #self.onlineHistory + 1 > data.ohi then
				-- If we're the client and the index of the action doesn't match, then the host probably overruled our action
				-- Remove any history we wrote down after that point
				while #self.onlineHistory + 1 > data.ohi do
					table.remove(self.onlineHistory)
				end
				-- Then add the action we just received
				table.insert(self.onlineHistory,data)
				
				local game = self:getCurrentGame()
				if game then
					-- Restart the sim based on the new history
					game:fromOnlineHistory(self.onlineHistory)
				end
			elseif self:isClient() and #self.onlineHistory + 1 < data.ohi then
				-- Ok, I don't know how we got here, but if we're here then we must be completely desynced
				-- Request from the host that we get a complete version of the history
				-- We could attempt to fix this more subtly
				self:send({reqOh=true})
			end
		elseif self:isClient() then
			if data.agency then
				local thread = MOAICoroutine.new()
				thread:run( self.setRemoteCampaign, self, data )
				thread:resume()
			elseif data.onlineHistory then
				self.onlineHistory = data.onlineHistory
				local game = self:getCurrentGame()
				if game then
					-- Restart the sim based on the new history
					game:fromOnlineHistory(self.onlineHistory)
				end
			end
		elseif data.reqOh then
			self.uplink:sendTo({onlineHistory = self.onlineHistory},client)
		end
	end
end

function stateMultiplayer:sendAction(action)
	if not (type(action) == "table") then
		log:write("Can't send action, action is "..tostring(action))
		return
	end
	if not action.name or not simactions[action.name] then
		log:write("Can't send action, invalid action "..tostring(action.name))
		return
	end
	
	table.insert(self.onlineHistory,action)
	action.ohi = #self.onlineHistory
	
	self.uplink:send(action)
end

function stateMultiplayer:rewindTurns()
	local action = {rwnd = true}
	
	table.insert(self.onlineHistory,action)
	action.ohi = #self.onlineHistory
	
	self.uplink:send(action)
end

function stateMultiplayer:sendChoice(choiceIdx, choice)
	local action = {rChoice = {[choiceIdx] = choice}}
	
	table.insert(self.onlineHistory,action)
	action.ohi = #self.onlineHistory
	
	self.uplink:send(action)
end

function stateMultiplayer:setRemoteCampaign(campaign)
	local canContinue, reason = self:canContinueCampaign( campaign )
		
	-- Unload unwanted states.
	local stateStack = statemgr.getStates()
	local state = stateStack[#stateStack]
	
	while #stateStack > 0 and not state.uplink do
		table.remove( stateStack, #stateStack )

		if type ( state.onUnload ) == "function" then
			state:onUnload ()
		end
		
		state = stateStack[#stateStack]
	end
	
	if canContinue then
		campaign.sim_history = nil
		self.onlineHistory = campaign.onlineHistory
		self.campaign = campaign
		
		local user = savefiles.getCurrentGame()
		user.data.saveSlots[ user.data.currentSaveSlot ] = campaign
		
		mod_manager:resetContent()
		mod_manager:loadModContent( campaign.difficultyOptions.enabledDLC )

		if campaign.situation == nil then
			-- Go to map screen if the campaign currently isn't mid-mission.
			MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_GAME_WOOSHOUT )
			MOAIFmodDesigner.stopSound("theme")
			local stateMapScreen = include( "states/state-map-screen" )
			
			statemgr.activate( stateMapScreen(), campaign )
		else
			local stateLoading = include( "states/state-loading" )
			stateLoading:loadCampaign( campaign )
		end
	else
		-- Warn the player of the incompatibility
		local stateStack = statemgr.getStates()
		local state = stateStack[#stateStack]
		
		statemgr.deactivate( self )
		
		if reason then
			modalDialog.show( reason )
		end
		
        local stateLoading = include( "states/state-loading" )
        stateLoading:loadFrontEnd()
	end
end

function stateMultiplayer:canContinueCampaign( campaign )
	if not campaign then
		return false
	end

	if version.isIncompatible( campaign.version ) then
		local reason = "<ttheader>" .. STRINGS.UI.SAVE_NOT_COMPATIBLE.. "<font1_12_r>\n"
		reason = reason .. string.format( "%s v%s\n", STRINGS.UI.SAVE_GAME_VERSION, tostring(campaign.version) )
		reason = reason .. string.format( "%s v%s", STRINGS.UI.CURRENT_VERSION, version.VERSION )
		return false, reason
	end
	
	if campaign.reqSockV and campaign.reqSockV > multiMod.MULTI_MOD_VERSION then
		local reason = "<ttheader>" .. STRINGS.UI.SAVE_NOT_COMPATIBLE.. "<font1_12_r>\n"
		reason = reason .. string.format( "%s v%s\n", STRINGS.MULTI_MOD.SOCKET_VERSION_REQUIRED, tostring(campaign.reqSockV) )
		reason = reason .. string.format( "%s v%s", STRINGS.MULTI_MOD.CURRENT_SOCKET_VERSION, tostring(multiMod.MULTI_MOD_VERSION) )
		return false, reason
	end

    if campaign.difficultyOptions.enabledDLC and next(campaign.difficultyOptions.enabledDLC) then
    	--log:write("Campaign has installed mods:")
        for modID, info in pairs(campaign.difficultyOptions.enabledDLC) do
        	--log:write("    [%s] %s %s", modID, info.name, mod_manager:isInstalled( modID ) and "OK" or "(missing)")
            if info.enabled and not mod_manager:isInstalled( modID ) then
        		local reason = "<ttheader>" .. STRINGS.UI.SAVE_NOT_COMPATIBLE.. "<font1_12_r>\n"
                reason = reason .. util.sformat( STRINGS.UI.SAVE_NEEDS_DLC, info.name )
                return false, reason
            end
        end
    end

	return true
end

function stateMultiplayer:canTakeAction( actionName, ... )
	if self.uplink then
		-- TODO: Add check that the action is actually legal here
		local game = self:getCurrentGame()
		local addedAction = {...}
		
		if actionName == "rewindAction" and game.isRemoteRewinding then
			return false
		end
		
		if actionName == "debugAction" then
			return false
		end
		
		return true
	end
	
	return false
end

function stateMultiplayer:canTakeLocalAction( actionName, ... )
	-- For actions that should be taken locally, but not sent online.
	if self.uplink then
		return false
	end
	
	return true
end

return stateMultiplayer