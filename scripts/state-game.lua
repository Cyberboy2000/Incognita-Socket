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
local game = include("states/state-game")
local level = include( "sim/level" )

local oldDoAction = game.doAction
local oldOnLoad = game.onLoad
local oldOnUnload = game.onUnload
local oldRewindTurns = game.rewindTurns
local oldOnPlaybackDone = game.onPlaybackDone

local function event_error_handler( err )
	moai.traceback( "sim:goto() failed with err:\n" ..err )
	return err
end

function game:doAction( actionName, ... )
	-- log:write("Received action: "..actionName)
	local canTakeAction = multiMod:canTakeAction( actionName, ... )
	local canLocallyTakeAction = multiMod:canTakeLocalAction( actionName, ... )
	
	if multiMod:hasYielded() and actionName ~= "mapPinAction" then
		return
	end
	
	if multiMod.gameMode == multiMod.GAME_MODES.BACKSTAB and actionName == "endTurnAction" and not multiMod:hasYielded() then
		return multiMod:yield(0)
	end
	
	if multiMod:getUplink() and self.syncedChessTimer then
		return
	end

	if not canTakeAction and not canLocallyTakeAction then
		return
	end
	
	if self.chessTimer and actionName == "endTurnAction" then
		self.chessTimeTotal = self.chessTimeTotal + self.chessTimer
		self.chessTimer = 0
	end

	local oldTop = self.simHistory[#self.simHistory]

    oldDoAction( self, actionName, ... )
	
	local addedAction = self.simHistory[#self.simHistory]

	if canTakeAction and addedAction ~= oldTop then
		multiMod:sendAction(addedAction)
	end
end

function game:onPlaybackDone(...)
	oldOnPlaybackDone(self,...)
	multiMod:updateEndTurnButton()
end

function game:doRemoteAction(action)
	if action.rwnd then
		self.isRemoteRewinding = true
		oldRewindTurns(self)
		self.isRemoteRewinding = nil
	elseif type(action.rChoice) == "table" then
		for i, choice in pairs( action.rChoice ) do
			self.simCore._choices[ i ] = choice
		end
	else
		local actionName = action.name
		
		if actionName == "endTurnAction" then
			if self.hud then
				self.hud:abortChoiceDialog()
				self.hud:hideItemsPanel()
				self.hud:hideRegenLevel()
			end
			
			self.syncedChessTimer = nil
			
			if self.chessTimer then
				self.chessTimeTotal = self.chessTimeTotal + self.chessTimer
				self.chessTimer = 0
			end
		end

		-- Queue it in the rewind history.
		table.insert( self.simHistory, action )
		
		-- Play!
		if self.debugStep ~= nil then
			self.debugStep = false
		end
		if not self.simThread then
			self:play()
		end
	end
	
	multiMod.autoClose = true
end

----------------------------------------------------------------

function game:fromOnlineHistory(onlineHistory)
	if #onlineHistory > 0 or self.simHistoryIdx > 0 then
		self:skip()

		self.modalControl = self.modalControl:abort()
		self.viz:destroy()
		self.fxmgr:destroy()
		self.hud:destroyHud()
		self.hud = nil
		self.boardRig:destroy()
		self.boardRig = nil

		self.simCore, self.levelData = gameobj.constructSim( self.params, self.levelData )
		self.simHistoryIdx = 0
		self.simHistory = {}
		local focusAction
		
		for i, action in ipairs(onlineHistory) do
			if action.name == "yieldTurnAction" then
				focusAction = action
			elseif action.name and simactions[action.name] then
				table.insert(self.simHistory,action)
			elseif action.rwnd then
				local numTurns = 2
				while #self.simHistory > 0 do
					local removeAction = table.remove( self.simHistory )
					if removeAction.name == "endTurnAction" then
						numTurns = numTurns - 1
						if numTurns <= 0 then
							table.insert( self.simHistory, removeAction )
							break
						end
					end
				end
			elseif type(action.rChoice) == "table" then
				local topAction = self.simHistory[#self.simHistory]
				if topAction then
					topAction.choices = topAction.choices or {}
					for i, choice in pairs( action.rChoice ) do
						topAction.choices[i] = choice
					end
				end
			end
		end
		
		if 1 < #self.simHistory then
			-- We are goto'ing some action in the future.
			local errCount = 0
			simguard.start()
			while self.simHistoryIdx < #self.simHistory do
				self.simHistoryIdx = self.simHistoryIdx + 1
				local errHandler = errCount == 0 and event_error_handler
				local res, err = xpcall( function() self.simCore:applyAction( self.simHistory[self.simHistoryIdx] ) end, errHandler )
				if not res then
					log:write( "[%d/%d] %s returned %s:\n",
						self.simHistoryIdx, #self.simHistory, self.simHistory[self.simHistoryIdx].name, err )
					errCount = errCount + 1 
				end
			end
			simguard.finish()
		end
		
		if focusAction then
			table.insert( self.simHistory, focusAction )
		end

		if multiMod.gameMode == multiMod.GAME_MODES.BACKSTAB and self.simHistoryIdx == 0 then
        	local level = include( "sim/level" )
            self:dispatchScriptEvent( level.EV_UI_INITIALIZED )
        end

		self.boardRig = boardrig( self.layers, self.levelData, self )
		self.hud = hud.createHud( self )

		self:onPlaybackDone()

		self.simCore:getLevelScript():queue( { type="fadeIn" } )

		util.fullGC()
	else
		multiMod:updateEndTurnButton()
	end
end

----------------------------------------------------------------

--[[
function game:dispatchScriptEvent( eventType, eventData )
	if self.captureDispatchEvents then
		
	else
		if self.simCore:getLevelScript() then
			self.simCore:getLevelScript():queueScriptEvent( eventType, eventData )
		end
	end
end
]]

----------------------------------------------------------------
function game:onLoad( ... )
	oldOnLoad( self, ... )
	
	if multiMod:getUplink() then
		multiMod:startGame(self)
		
		local oldUpdateTimeAttack = self.updateTimeAttack
		
		self.doEndTurn = game.doEndTurn
		
		self.updateTimeAttack = function(...)
			if not multiMod:getUplink() then
				return oldUpdateTimeAttack(...)
			end
		
			if multiMod:hasYielded() or self.debugStep or self.simCore:isGameOver() or self.simCore:getCurrentPlayer():isNPC() then
				return
			end

			self.chessTimer = math.min( self.params.difficultyOptions.timeAttack, self.chessTimer + 1 )
			if self.chessTimer >= self.params.difficultyOptions.timeAttack and not self:isReplaying() then
				if multiMod.gameMode == multiMod.GAME_MODES.BACKSTAB then
					-- Vs mode
					if not multiMod:hasYielded() then
						multiMod:yield(0)
					end
				elseif not self.syncedChessTimer then
					-- Co-Op Time Attack case: Prevent further actions from being taken locally, but don't actually end turn.
					-- Server will send an endTurnAction once it's received a time out message from every player.
					self.syncedChessTimer = true
					multiMod:chessTimeOut()
				end
			end
		end
	end
end

----------------------------------------------------------------
function game:onUnload(...)
	oldOnUnload( self, ... )
	if multiMod:getUplink() then
		multiMod:endGame(self)
	end
end

----------------------------------------------------------------
function game:rewindTurns()
	if multiMod:getUplink() then
		multiMod:rewindTurns()
	end
	
	oldRewindTurns(self)
end
