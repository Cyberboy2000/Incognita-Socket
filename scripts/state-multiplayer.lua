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

local stateMultiplayer = {
	MISSION_VOTING = {
		FREEFORALL = 0,
		MAJORITY = 1,
		WEIGHTEDRAND = 2,
		HOSTDECIDES = 3,
	}
}

----------------------------------------------------------------
--   Set up a TCP server and read messages from the clients   --
----------------------------------------------------------------

function stateMultiplayer:onLoad( uplink, ... )
	assert(uplink)
	assert(not self.uplink)
	self.uplink = uplink
	self.votingMode = self.MISSION_VOTING.HOSTDECIDES
	return uplink:onLoad(self, ...)
end

function stateMultiplayer:onUnload(  )
	self.uplink:onUnload(  )
	self:restoreFMOD()
	self.uplink = nil
	self.game = nil
	self.campaign = nil
	self.upgradeHistory = nil
	self.missionVotes = nil
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
	self.game = nil
	self:stopTrackingSimHistory()
end

function stateMultiplayer:trackSimHistory()
	-- Launching mission
	log:write("Start tracking sim history")
	self.onlineHistory = {}
	self.missionVotes = nil
	self.upgradeHistory = nil 
end

function stateMultiplayer:stopTrackingSimHistory()
	-- Outside mission
	log:write("Stop tracking sim history")
	self.onlineHistory = nil
	self.upgradeHistory = {} 
	self.missionVotes = {}
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
	return util.tmerge(tmerge or {},self.campaign or {},{
				onlineHistory = self.onlineHistory,
				upgradeHistory = self.upgradeHistory,
				missionVotes = self.missionVotes,
				reqSockV = multiMod.COMPABILITY_VERSION,
			})
end

function stateMultiplayer:loadCampaignGame(campaign)
	self:restoreFMOD()
	
	if self.uplink then
		if self:isHost() and campaign ~= self.campaign then
			-- For now, we simply let the host decide everything that happens outside of a mission
			
			self.campaign = campaign
			
			if campaign.situation then
				self:trackSimHistory()
				
				if campaign.sim_history then
					local serializer = include( "modules/serialize" )
					local simHistory = serializer.deserialize( campaign.sim_history )
					
					for i, action in ipairs(simHistory) do
						table.insert(self.onlineHistory,action)
					end
				end
			else
				self:stopTrackingSimHistory()
			end
			
			self.uplink:send(self:mergeCampaign())
		end
	end
end

function stateMultiplayer:onClientDisconnect( client, message )
	if self.missionVotes then
		local i = client.clientIndex
		repeat
			self.missionVotes[i] = self.missionVotes[i + 1]
			i = i + 1
		until i > #self.uplink.set
		
		self:checkVotes()
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
			elseif data.startM then
				self:startMissionImmediately( data.startM )
			end
		elseif data.reqOh then
			self.uplink:sendTo({onlineHistory = self.onlineHistory},client)
		elseif type(data.voteM) == "number" then
			self:voteMission( data.voteM, client.clientIndex )
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
		self.missionVotes = campaign.missionVotes
		self.upgradeHistory = campaign.upgradeHistory
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

function stateMultiplayer:voteMission( situationIndex, playerIndex )
	if self.votingMode == self.MISSION_VOTING.HOSTDECIDES then
		if self:isHost() and not playerIndex then
			self:trackSimHistory()
			local action = {startM = situationIndex}
			self.uplink:send(action)
			return true
		else
			return false
		end
	end

	if self:isHost() then
		if playerIndex then
			self.missionVotes[playerIndex] = situationIndex
			self:checkVotes()
		else
			self:voteMission( situationIndex, 0 )
		end
	else
		local action = {voteM = situationIndex}
		self.uplink:send(action)
	end
	
	return false
end

function stateMultiplayer:checkVotes()
	if self.game or self.startingMission then
		return false
	end
	
	local voteCount = 0
	local usedVotes = {}
	local voteMap = {}
	local bestVote = 0
	local maxVotes = #self.uplink.set + 1

	for i = 0, #self.uplink.set do
		local vote = self.missionVotes[i]
		if vote then
			voteCount = voteCount + 1
			voteMap[vote] = (voteMap[vote] or 0) + 1
			table.insert(usedVotes, vote)
			if voteMap[vote] > bestVote then
				bestVote = voteMap[vote]
			end
		end
	end
	
	local situationIndex = nil
	
	-- Could maybe add in a timer or something to allow a partial vote to start the mission
	if self.votingMode == self.MISSION_VOTING.WEIGHTEDRAND then
		if voteCount == maxVotes then
			situationIndex = usedVotes[math.random(#usedVotes)]
		end
	elseif self.votingMode == self.MISSION_VOTING.MAJORITY then
		if voteCount == maxVotes or bestVote > 0.5 * maxVotes then
			for i = #usedVotes, 1, -1 do
				if voteMap[ usedVotes[i] ] < bestVote then
					table.remove( voteMap[ usedVotes[i] ], i )
				end
			end
			
			situationIndex = usedVotes[math.random(#usedVotes)]
		end
	elseif self.votingMode == self.MISSION_VOTING.FREEFORALL then
		situationIndex = usedVotes[1]
	end
	
	if situationIndex then
		-- Vote complete: Start mission
		local action = {startM = situationIndex}
		self.uplink:send(action)
		self:startMissionImmediately( situationIndex )
	end
end

local function goToMapAndStartMission( self, situationIndex )
	local stateMapScreen = include( "states/state-map-screen" )
	stateMapScreen = stateMapScreen()
	statemgr.activate( stateMapScreen, self.campaign, true )
	
	-- Need to look up the mission preview screen in order to pass it to closePreview :(
	local previewScreen
	local oldCreateScreen = mui.createScreen
	mui.createScreen = function( name, ... )
		local screen = oldCreateScreen( name, ... )
	
		if name == "mission_preview_dialog.lua" then
			previewScreen = screen
		end
		
		return screen
	end
	
	stateMapScreen:OnClickLocation( self.campaign.situations[situationIndex] )
	mui.createScreen = oldCreateScreen
	stateMapScreen:closePreview(previewScreen, self.campaign.situations[situationIndex], true)
end

function stateMultiplayer:startMissionImmediately( situationIndex )
	-- This isn't ideal, but we want to make sure we check things like campaign events that normally only run on the map screen
	-- Solution: Unloading everything, then load in the map screen, then skip through everything that normally happens on the map screen when selecting a mission

	self.startingMission = true

	local stateStack = statemgr.getStates()
	local state = stateStack[#stateStack]
	
	while #stateStack > 0 and not state.uplink do
		table.remove( stateStack, #stateStack )

		if type ( state.onUnload ) == "function" then
			state:onUnload ()
		end
		
		state = stateStack[#stateStack]
	end
	
	self:trackSimHistory()
	self:stopFMOD()
	
	--What happens if this coroutine fails? :/
	local thread = coroutine.create( goToMapAndStartMission )
	coroutine.resume( thread, self, situationIndex )
	
	while coroutine.status( self.loadThread ) ~= "dead" do
		coroutine.resume( thread )
	end
	
	self:restoreFMOD()
	self.startingMission = nil
end

function stateMultiplayer:restoreFMOD()
	if self.FMOD then
		MOAIFmodDesigner = self.FMOD
		self.FMOD = nil
	end
end

function stateMultiplayer:stopFMOD()
	if not self.FMOD then
		-- Need to stop sounds from playing as we skip past them
		-- Could maybe use MOAIFmodDesigner.stopAllSounds() instead?
		self.FMOD = MOAIFmodDesigner
		MOAIFmodDesigner = {
			setCameraProperties = function() end,
			playSound = function() end,
			stopSound = function() end,
		}
	end
end

return stateMultiplayer