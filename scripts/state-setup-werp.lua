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

local stateSetupWerp = {}

local stateConnecting = {
	onUnload = function ( self )
		mui.deactivateScreen( self.screen )
		self.screen = nil
	end,
	
	onLoad = function( self )
		self.screen = mui.createScreen( "modal-dialog.lua" )
		mui.activateScreen( self.screen )
		self.result = nil

		self.screen.binder.headerTxt:setText( STRINGS.MULTI_MOD.CONNECTING )
		self.screen.binder.bodyTxt:setText( STRINGS.MULTI_MOD.CONNECTING_BODY )
		self.screen.binder.okBtn:setVisible( false )
		self.screen.binder.cancelBtn.onClick = util.makeDelegate( nil, function() self.result = modalDialog.CANCEL end )
		self.screen.binder.cancelBtn:setClickSound(cdefs.SOUND_HUD_MENU_CANCEL)
	end
}

local function togglePw( self )
	-- By default the password is hidden behind * characters
	local editbox = self.binder.password.binder.editText
	if editbox._cont._pwchar then
		editbox:setPasswordChar(nil)
	else
		editbox:setPasswordChar("*")
	end
end

---------------------------------------
--   Return to the previous screen   --
---------------------------------------

local function cancelJoinGame( self )
	self.showsConfigPanel = nil -- Hides the config panel
	self.binder.configPanel:createTransition( "deactivate_below",
		function( transition )
			self.binder.configPanel:setVisible( false )
		end,
		{ easeOut = true } )
end

local function onClickCancel( self )
	MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_GAME_WOOSHOUT )
	
	local stateGenerationOptions = include( "states/state-generation-options" )
	statemgr.activate( stateGenerationOptions(), self._diff, self._campaignOptions )
	statemgr.deactivate( self )
	
	if multiMod:getUplink() then
		statemgr.deactivate(multiMod) -- Shutdown multiplayer
	end
end

local function toMainMenu( self )
	MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_GAME_WOOSHOUT )
	
	statemgr.deactivate( self )
	local stateLoading = include( "states/state-loading" )
	stateLoading:loadFrontEnd() -- This automatically shuts down multiplayer
end

--------------------------------------------------
--   Joins an open game through the werp site   --
--------------------------------------------------

local function joinGame( self, gameData )
	local data = {
		pw = self.binder.password.binder.editText:getText()
	}
	
	local client = self.uplink
	client.joinFailed = nil
	local err = client:joinGame( gameData.gameId, data )
	
	statemgr.activate( stateConnecting )
	
	local header = stateConnecting.screen.binder.headerTxt
	local body = stateConnecting.screen.binder.bodyTxt
	
	while stateConnecting.result ~= modalDialog.CANCEL do
		if client.err or err then
			-- Unhandled error.
			header:setText( STRINGS.MULTI_MOD.CONNECTION_FAILED )
			body:setText( client.err or err )
		elseif client.joinFailed then
			header:setText( STRINGS.MULTI_MOD.CONNECTION_FAILED )
			body:setText( client.joinFailedReason )
		elseif client.passwordAccepted then
			-- We're in!
			body:setText( STRINGS.MULTI_MOD.WAITING_JOINING )
			
			-- Put some kind of lobby screen here maybe?
			if multiMod.campaign then
				if statemgr.isActive( self ) then
					statemgr.deactivate( self )
				end
				
				-- This should be where we launch into the game...
				-- ...but for now we'll just assume that the client got the info it needs from the server and figures out what to do by itself.
				return
			end
		elseif client.passwordRejected then
			body:setText( STRINGS.MULTI_MOD.PASSWORD_REJECTED )
		elseif client.connected then
			-- Connection established!
			-- Now wait for a password confirmation.
			body:setText( STRINGS.MULTI_MOD.WAITING_PASSWORD )
		end
		
		coroutine.yield()
	end
	
	client:leaveGame( gameData.gameId )

	-- It's possible for shutdown to preemptively deactivate active dialogs from under us.
	if statemgr.isActive( stateConnecting ) then
		statemgr.deactivate( stateConnecting )
	end
end

local function onClickGame( self, gameData )
	if self.showsConfigPanel then return end

	local panel = self.binder.configPanel
	panel:setVisible(true)
	panel:createTransition( "activate_below" )
	
	self.showsConfigPanel = true
	self.binder.gameTitle.binder.editText:setText(gameData.name)
	self.binder.gameTitle.binder.editText:setDisabled(true)
	self.binder.password.binder.editText:setText("")
	self.binder.password.binder.editText:setPasswordChar("*")
	self.binder.password:setVisible( gameData.hasPw )
	self.binder.showPwButton:setVisible( gameData.hasPw )
	
	self.binder.okBtn.binder.btn.onClick = util.makeDelegate( nil, joinGame, self, gameData )
	self.binder.backToList.binder.btn.onClick = util.makeDelegate( nil, cancelJoinGame, self )
end

----------------------------------------------------------
--   Requests a list of open games from the werp site   --
----------------------------------------------------------

local function checkConnectionReset( self )
	if self.uplink.err or not self.uplink.connected then
		if multiMod:getUplink() then
			statemgr.deactivate( multiMod )
		end
		statemgr.activate( multiMod, self.uplink, multiMod.WERP_ADRESS, multiMod.WERP_PORT )
	end
end

local function refreshGames( self )
	if self.showsConfigPanel then return end
	checkConnectionReset( self )

	local client = self.uplink
	client.open_games = nil
	statemgr.activate( stateConnecting )
	
	local header = stateConnecting.screen.binder.headerTxt
	local body = stateConnecting.screen.binder.bodyTxt
	local list = self.binder.list
	list:clearItems()
	list._scrollbar:setVisible( false )
	
	client:listGames()
	
	while stateConnecting.result ~= modalDialog.CANCEL do
		if client.err then
			-- Unhandled error.
			header:setText( STRINGS.MULTI_MOD.CONNECTION_FAILED )
			body:setText( client.err )
		elseif client.open_games then
			for i, gameData in ipairs(client.open_games) do
				local widget = list:addItem( gameData.gameId )
				widget.binder.btn.onClick = util.makeDelegate( nil, onClickGame, self, gameData )
				widget.binder.btn:setText( gameData.name )
			end
			
			break
		elseif client.connected then
			body:setText( STRINGS.MULTI_MOD.WAIT_GAMES_LIST )
		end
		
		coroutine.yield()
	end

	-- It's possible for shutdown to preemptively deactivate active dialogs from under us.
	if statemgr.isActive( stateConnecting ) then
		statemgr.deactivate( stateConnecting )
	end
end

-----------------------------------------------
--   Tell the werp site to list a new game   --
-----------------------------------------------

local function startOrResumeCampaign( self, campaign )
	if campaign then
		-- We are resuming an existing campaign.
		multiMod:loadCampaignGame( campaign )
		
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
		-- We are launching a new campaign.
		local stateTeamPreview = include( "states/state-team-preview" )
		
		statemgr.activate( stateTeamPreview( self._diff, self._campaignOptions ) )
	end
	
	statemgr.deactivate( self )
end

local function createGame( self, campaign )
	checkConnectionReset( self )
	
	local host = self.uplink
	local password = self.binder.password.binder.editText:getText()
	local data = {
		name = self.binder.gameTitle.binder.editText:getText(),
		hasPw = password and string.len(password) > 0
	}
	
	local err = host:createGame( data, password )
	
	statemgr.activate( stateConnecting )
	
	local header = stateConnecting.screen.binder.headerTxt
	local body = stateConnecting.screen.binder.bodyTxt
	
	while stateConnecting.result ~= modalDialog.CANCEL do
		if host.err or err then
			-- Unhandled error.
			header:setText( STRINGS.MULTI_MOD.CONNECTION_FAILED )
			body:setText( host.err or err )
		elseif host.gameId then
			-- Success!
			startOrResumeCampaign( self, campaign )
			return
		elseif host.connected then
			-- Connection established!
			-- Now wait for a password confirmation.
			body:setText( STRINGS.MULTI_MOD.WAITING_CREATE )
		end
		
		coroutine.yield()
	end
	
	host:leaveGame( )

	-- It's possible for shutdown to preemptively deactivate active dialogs from under us.
	if statemgr.isActive( stateConnecting ) then
		statemgr.deactivate( stateConnecting )
	end
end
	
local function onClickHost( self, campaign )
	if self.showsConfigPanel then return end
	
	self.showsConfigPanel = true
	local panel = self.binder.configPanel
	panel:setVisible(true)
	panel:createTransition( "activate_below" )
	
	local name = campaign and campaign.multiModName or ""
	self.binder.gameTitle.binder.editText:setText(name)
	self.binder.gameTitle.binder.editText:setDisabled(false)
	self.binder.password.binder.editText:setText("")
	self.binder.password.binder.editText:setPasswordChar("*")
	self.binder.password:setVisible( true )
	
	self.binder.okBtn.binder.btn.onClick = util.makeDelegate( nil, createGame, self, campaign )
	if campaign then
		self.binder.backToList.binder.btn.onClick = util.makeDelegate( nil, toMainMenu, self )
	else
		self.binder.backToList.binder.btn.onClick = util.makeDelegate( nil, cancelJoinGame, self )
	end
end

------------------------------------------------------------------
--   Connect to the werp site to list, create, and join games   --
------------------------------------------------------------------

function stateSetupWerp:onLoad( campaign, difficulty, params )
	self.screen = mui.createScreen( "modal-setup-multiplayer" )
	mui.activateScreen( self.screen )
	self._diff = difficulty
	self._campaignOptions = params
	self._campaign = campaign
	self.isHosting = false
	
	if multiMod:getUplink() then
		statemgr.deactivate(multiMod)
	end
	
	if not MOAIFmodDesigner.isPlaying("theme") then
		MOAIFmodDesigner.playSound("SpySociety/Music/music_map_AMB","theme")
	end
	
	self.screen.binder.panel:setVisible(false) -- Legacy config panel
	
	self.binder = self.screen.binder.werp.binder
	self.binder.refreshBtn.binder.btn.onClick = util.makeDelegate(nil, refreshGames, self)
	self.binder.refreshBtn.binder.btn:setClickSound( cdefs.SOUND_HUD_MENU_CONFIRM )
	self.binder.refreshBtn.binder.btn:setText( STRINGS.MULTI_MOD.BUTTON_REFRESH )
	
	self.binder.hostBtn.binder.btn.onClick = util.makeDelegate(nil, onClickHost, self, false)
	self.binder.hostBtn.binder.btn:setClickSound( cdefs.SOUND_HUD_MENU_CONFIRM )
	self.binder.hostBtn.binder.btn:setText( STRINGS.MULTI_MOD.BUTTON_HOST )
	
	self.binder.cancelBtn.binder.btn.onClick = util.makeDelegate(nil, onClickCancel, self)
	self.binder.cancelBtn.binder.btn:setClickSound( cdefs.SOUND_HUD_MENU_CANCEL )
	self.binder.cancelBtn.binder.btn:setText( STRINGS.UI.BUTTON_CANCEL )
	--self.binder.cancelBtn.binder.btn:setHotkey( "pause" )
	
	self.binder.okBtn.binder.btn:setClickSound( cdefs.SOUND_HUD_MENU_CONFIRM )
	self.binder.okBtn.binder.btn:setText( STRINGS.UI.BUTTON_OK )
	
	self.binder.gameTitle.binder.label:setText( STRINGS.MULTI_MOD.PANEL.TITLE )
	self.binder.password.binder.label:setText( STRINGS.MULTI_MOD.PANEL.PASSWORD )
	
	self.binder.backToList.binder.btn:setClickSound( cdefs.SOUND_HUD_MENU_CANCEL )
	self.binder.backToList.binder.btn:setText( STRINGS.UI.BUTTON_CANCEL )
	
	self.binder.showPwButton.binder.btn.onClick = util.makeDelegate(nil, togglePw, self)
	self.binder.showPwButton.binder.btn:setTooltip( STRINGS.MULTI_MOD.PANEL.TOGGLE_PASSWORD )
	self.binder.configPanel:setVisible( false )
	
	self.binder.list._scrollbar:setVisible( false )
	
	-- CONNECT
	self.uplink = multiMod.werpClient
	
	-- Are we hosting an existing game from a savefile?
	if campaign then
		self.binder.cancelBtn.binder.btn.onClick = util.makeDelegate(nil, toMainMenu, self)
		onClickHost( self, campaign )
	else
		refreshGames( self )
	end
end

function stateSetupWerp:onUnload(  )
	if self.screen and self.screen:isActive() then
		mui.deactivateScreen( self.screen )
	end
	if statemgr.isActive( stateConnecting ) then
		statemgr.deactivate( stateConnecting )
	end
	
	self.screen = nil
	self.showsConfigPanel = nil
	self._campaign = nil
	self._diff = nil
	self._campaignOptions = nil
end

return stateSetupWerp