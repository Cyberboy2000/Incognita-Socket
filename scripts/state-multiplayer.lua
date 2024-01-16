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
	},
	GAME_MODES = {
		FREEFORALL = 0,
		BACKSTAB = 1,
	}
}

local screensToDeactivate = {
	"modal-monst3r.lua",
	"modal-story.lua",
	"modal-logs.lua"
}

local function deepCompare(t1, t2)
	if type(t1) == "table" and type(t2) == "table" then
		-- Match every value in t1 with a value in t2
		for k, v in pairs(t1) do
			if not deepCompare( v, t2[k] ) then
				return false
			end
		end
		
		-- Some keys might only exist in t2
		for k,v in pairs(t2) do
			if t1[k] == nil then
				return false
			end
		end
	
		return true
	else
		return t1 == t2
	end
end

----------------------------------------------------------------
--   Set up a TCP server and read messages from the clients   --
----------------------------------------------------------------

function stateMultiplayer:onLoad( uplink, ... )
	assert(uplink)
	assert(not self.uplink)
	self.uplink = uplink
	self.screen = mui.createScreen( "hud-multiplayer" )
	self.screen:setPriority( 1000000 )
	mui.activateScreen( self.screen )
	self:updatePlayerList()
	self.focusedPlayerIndex = 0
	self.playerCount = 1
	
	return uplink:onLoad(self, ...)
end

function stateMultiplayer:onUnload(  )
	self.uplink:onUnload(  )
	self:restoreFMOD()
	if self.screen and self.screen:isActive() then
		mui.deactivateScreen( self.screen )
	end
	self.screen = nil
	self.uplink = nil
	self.game = nil
	self.campaign = nil
	self.upgradeHistory = nil
	self.missionVotes = nil
	self.chessTimers = nil
	self.autoClose = nil
	self.showPlayerList = nil
	self.userName = nil
end

function stateMultiplayer:onUpdate(  )
	self.autoClose = nil
	self.uplink:onUpdate(  )
end

function stateMultiplayer:getUplink(  )
	return self.uplink
end

function stateMultiplayer:setUserName( name )
	self.userName = name
end

function stateMultiplayer:updatePlayerList()
	if self:isHost() and self.campaign then
		self.screen.binder.playerListHeader:setVisible(true)
		self.screen.binder.playerList:setVisible(true)
		self.screen.binder.playerList:clearItems()
		local hostWidget = self.screen.binder.playerList:addItem(  )
		hostWidget.binder.txt:setText( self.userName )
		
		if self.uplink then
			for i, client in ipairs( self.uplink.clients ) do
				local widget = self.screen.binder.playerList:addItem(  )
				widget.binder.txt:setText( client.userName )
			end
		end
		
		self.playerCount = 1 + #self.uplink.clients
		self.uplink:send({plCoun = self.playerCount})
		self:updateHudButtons()
	else
		self.screen.binder.playerListHeader:setVisible(false)
		self.screen.binder.playerList:setVisible(false)
	end
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
	self.chessTimers = {}
	self.missionVotes = nil
	self.upgradeHistory = nil
end

function stateMultiplayer:stopTrackingSimHistory()
	-- Outside mission
	log:write("Stop tracking sim history")
	self.onlineHistory = nil
	self.chessTimers = nil
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
				reqSockV = self.COMPABILITY_VERSION,
			})
end

function stateMultiplayer:loadCampaignGame(campaign)
	self:restoreFMOD()
	
	if campaign.difficultyOptions.timeAttack and campaign.difficultyOptions.timeAttack > 0 and self.COMPABILITY_VERSION < 2.1 then
		self.COMPABILITY_VERSION = 2.1
	end
	
	if self.uplink then
		if self:isHost() and campaign ~= self.campaign then
			-- For now, we simply let the host decide everything that happens outside of a mission
			
			self.campaign = campaign
			campaign.multiModName = self.uplink.campaignName
			
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
			
			self:updatePlayerList()
			self.uplink:send(self:mergeCampaign())
			
			if self.onlineHistory then
				self:focusFirstPlayer()
			end
		end
	end
end

function stateMultiplayer:onConnectionError( err )
	if not statemgr.isActive( multiMod.stateSetupWerp ) then
		local thread = MOAICoroutine.new()
		thread:run( modalDialog.show, err, STRINGS.MULTI_MOD.CONNECTION_ERROR )
		thread:resume()
	end
	
	statemgr.deactivate(self)
end

function stateMultiplayer:onClientDisconnect( client, message )
	self:updatePlayerList()
	
	if self.missionVotes then
		self.missionVotes[client.clientIndex] = nil
		self:checkVotes()
	end
	if self.chessTimers then
		self.chessTimers[client.clientIndex] = nil
		self:checkTimers()
	end
	if client.clientIndex == self.focusedPlayerIndex then
		self:yield(client.clientIndex)
	end
end

function stateMultiplayer:onClientConnect( client )
	self:updatePlayerList()
end

----------------------------------------------------------------
--				   Handle game logic here				   --
----------------------------------------------------------------

function stateMultiplayer:receiveData(client,data,line)
	-- Handle game logic here
	if multiMod.VERBOSE then
		--log:write("Received "..line)
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
			elseif deepCompare( self.onlineHistory[data.ohi], data ) then
				-- Exact duplicate: No action needed
				if multiMod.VERBOSE then
					log:write("Received duplicate data for %i: Ignoring", data.ohi)
				end
			elseif self:isClient() and #self.onlineHistory + 1 > data.ohi then
				-- If we're the client and the index of the action doesn't match, then the host probably overruled our action
				-- Remove any history we wrote down after that point
				log:write("Online history mismatch: Rewinding")
				
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
				log:write("Online history mismatch: Requesting full history")
				self.uplink:send({reqOh=true})
			end
		elseif self:isClient() then
			if data.focus then
				self.isFocusedPlayer = true
				self:updateHudButtons()
			elseif data.plCoun then
				self.playerCount = data.plCoun
				self:updateHudButtons()
			elseif data.agency then
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
				if data.upAgency then
					self.campaign.agency = data.upAgency
				end
				self:startMissionImmediately( data.startM )
			end
		elseif data.yield then
			if client.clientIndex == self.focusedPlayerIndex then
				self:yield(client.clientIndex)
			end
		elseif data.chess and self.chessTimers then
			self.chessTimers[client.clientIndex] = true
			self:checkTimers()
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

function stateMultiplayer:chessTimeOut()
	if self:isHost() then
		self.chessTimers[0] = true
		self:checkTimers()
	else
		self.uplink:send( { chess = true } )
	end
end

function stateMultiplayer:checkTimers()
	local maxVotes = self.playerCount
	for playerIndex, vote in pairs( self.chessTimers ) do
		maxVotes = maxVotes - 1
	end
	
	log:write(util.stringize(self.chessTimers))
	
	if maxVotes == 0 then
		-- Weird, end turn during Time Attack is both a local and remote action
		self.chessTimers = {}
		local action = { name = "endTurnAction" }
		self:sendAction( action )
		if self:getCurrentGame() then
			self:getCurrentGame():doRemoteAction(action)
		end
	end
end

function stateMultiplayer:unloadStates()
	-- Unload unwanted states.
	local stateStack = statemgr.getStates()
	local state = stateStack[#stateStack]
	
	while state and not state.uplink do
		table.remove( stateStack, #stateStack )

		if type ( state.onUnload ) == "function" then
			state:onUnload ()
		end
		
		state = stateStack[#stateStack]
	end
	
	for i, filename in ipairs( screensToDeactivate ) do
		log:write(filename)
		local screen = self:findScreen( filename )
		if screen then
			mui.deactivateScreen( screen ) 
		end
	end
end

function stateMultiplayer:setRemoteCampaign(campaign)
	local canContinue, reason = self:canContinueCampaign( campaign )
	
	self:unloadStates()
	
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
			--log:write("	[%s] %s %s", modID, info.name, mod_manager:isInstalled( modID ) and "OK" or "(missing)")
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

function stateMultiplayer:yield(playerIndex)
	self.isFocusedPlayer = false
	
	if self:isHost() then
		local nextClient
		local clientName
		local previousFocusedPlayerIndex = self.focusedPlayerIndex or 0
		
		for i, client in ipairs(self.uplink.clients) do
			if client.clientIndex > playerIndex and not (nextClient and client.clientIndex > nextClient.clientIndex)then
				nextClient = client
			end
		end
		
		if nextClient then
			self.focusedPlayerIndex = nextClient.clientIndex
			self.uplink:sendTo({focus = true},nextClient)
			clientName = nextClient.userName
		else
			self.focusedPlayerIndex = 0
			self.isFocusedPlayer = true
			clientName = self.userName
		end
	
		local action = { name = "yieldTurnAction", clientName, previousFocusedPlayerIndex, self.focusedPlayerIndex }
		
		if not self:shouldYield() then
			action.costly = true
			local endTurnAction = { name = "endTurnAction" }
		
			self:sendAction( endTurnAction )
			if self.game then
				self.game:doRemoteAction( endTurnAction )
			end
		end
		
		self:sendAction( action )
		if self.game then
			self.game:doRemoteAction(action)
		end
	else
		local action = { yield = true }
		self.uplink:send(action)
	end
end

function stateMultiplayer:shouldYield()
	if not self.onlineHistory or self.gameMode ~= self.GAME_MODES.BACKSTAB then
		return false
	end

	local yieldCount = self.playerCount - 1
	
	for i = #self.onlineHistory, 1, -1 do
		local pastAction = self.onlineHistory[i]
		if pastAction.name == "endTurnAction" or pastAction.name == "moveAction" or pastAction.costly then
			break
		end
		
		if pastAction.name == "yieldTurnAction" and ( pastAction[2] == 0 or self.uplink:findClient( pastAction[2] ) ) then
			yieldCount = yieldCount - 1
			if yieldCount <= 0 then
				return false
			end
		end
	end
	
	return yieldCount > 0
end

function stateMultiplayer:hasYielded()
	if self.gameMode == self.GAME_MODES.BACKSTAB then
		if self.game:isReplaying() and self.game.simHistory[#self.game.simHistory].name == "yieldTurnAction" then
			return true
		end
		
		return not self.isFocusedPlayer
	end
	
	return false
end

function stateMultiplayer:focusFirstPlayer()
	if self.gameMode ~= self.GAME_MODES.BACKSTAB then
		return
	end
	
	local r = math.random(1,self.playerCount)
	log:write(string.format("Player %d goes first",r))
	local client = self.uplink.clients[r]

	if client then
		self.isFocusedPlayer = false
		self.focusedPlayerIndex = self.uplink.clients[r].clientIndex
		self.uplink:sendTo({focus = true},client)
		clientName = client.userName
	else
		self.focusedPlayerIndex = 0
		self.isFocusedPlayer = true
		clientName = self.userName
	end
	
	local action = { name = "yieldTurnAction", costly = true, clientName, nil, self.focusedPlayerIndex }
	
	self:sendAction( action )
	if self:getCurrentGame() then
		self:getCurrentGame():doRemoteAction(action)	
	end
end

function stateMultiplayer:voteMission( situationIndex, playerIndex )
	if self.votingMode == self.MISSION_VOTING.HOSTDECIDES then
		if self:isHost() and not playerIndex then
			self:trackSimHistory()
			local action = {startM = situationIndex, upAgency = self.campaign.agency}
			self.uplink:send(action)
			self:focusFirstPlayer()
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
	local maxVotes = self.playerCount

	for playerIndex, vote in pairs( self.missionVotes ) do
		voteCount = voteCount + 1
		voteMap[vote] = (voteMap[vote] or 0) + 1
		table.insert(usedVotes, vote)
		if voteMap[vote] > bestVote then
			bestVote = voteMap[vote]
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
	--elseif self.votingMode == self.MISSION_VOTING.FREEFORALL then
	else
		situationIndex = usedVotes[1]
	end
	
	if situationIndex then
		-- Vote complete: Start mission
		local action = {startM = situationIndex}
		self.uplink:send(action)
		self:startMissionImmediately( situationIndex )
		self:focusFirstPlayer()
	end
end

function stateMultiplayer:findScreen( filename )
	local screens = mui.internals._activeScreens
	for k, screen in pairs(screens) do
		if filename == screen._filename then
			return screen
		end
	end
end

local function goToMapAndStartMission( self, situationIndex )
	self:unloadStates()
	
	local stateMapScreen = include( "states/state-map-screen" )
	stateMapScreen = stateMapScreen()
	statemgr.activate( stateMapScreen, self.campaign, true )
	
	stateMapScreen:OnClickLocation( self.campaign.situations[situationIndex] )
	local previewScreen = self:findScreen( "mission_preview_dialog.lua" )
	stateMapScreen:closePreview(previewScreen, self.campaign.situations[situationIndex], true)
end

function stateMultiplayer:startMissionImmediately( situationIndex )
	-- This isn't ideal, but we want to make sure we check things like campaign events that normally only run on the map screen
	-- Solution: Unloading everything, then load in the map screen, then skip through everything that normally happens on the map screen when selecting a mission

	self.startingMission = true
	self:trackSimHistory()
	self:stopFMOD()

	--What happens if this coroutine fails? :/
	local thread = coroutine.create( goToMapAndStartMission )
	local ok, err = coroutine.resume( thread, self, situationIndex )
	
	while coroutine.status( thread ) ~= "dead" do
		ok, err = coroutine.resume( thread )
	end
	
	if not ok then
		log:write("Coroutine returned "..util.stringize(err,1))
		log:write(debug.traceback( thread ))
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
		MOAIFmodDesigner.stopAllSounds()
		self.FMOD = MOAIFmodDesigner
		MOAIFmodDesigner = {
			setCameraProperties = function() end,
			playSound = function() end,
			stopSound = function(...) if self.FMOD then self.FMOD.stopSound(...) end end,
			isPlaying = function() return false end,
			stopAllSounds = function() end,
		}
	end
end

function stateMultiplayer:updateHudButtons()
	self:updateEndTurnButton()
	self:updateRewindButton()
end

function stateMultiplayer:updateEndTurnButton()
	if self.game and self.game.hud and self.gameMode == self.GAME_MODES.BACKSTAB then
		local btn = self.game.hud._screen.binder.endTurnBtn
		
		if self.isFocusedPlayer then
			if self:shouldYield() then
				btn:setText(STRINGS.MULTI_MOD.YIELD)
			else
				btn:setText(STRINGS.SCREENS.STR_3530899842) -- End Turn
			end
		elseif self.game.simCore and self.game.simCore.currentClientName then
			btn:setText(string.format(STRINGS.MULTI_MOD.YIELDED_TO, self.game.simCore.currentClientName))
		else
			btn:setText(STRINGS.SCREENS.STR_3530899842) -- End Turn
		end
	end
end

function stateMultiplayer:updateRewindButton()
	if self.game and self.game.hud and self.gameMode == self.GAME_MODES.BACKSTAB then
		local btn = self.game.hud._screen.binder.rewindBtn
		btn:setVisible(self.isFocusedPlayer)
	end
end

return stateMultiplayer
