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

local stateSetupMultiplayer = {}

local function togglePw( self )
	if self.screen.binder.configPanel.binder.pw._cont._pwchar then
		self.screen.binder.configPanel.binder.pw:setPasswordChar(nil)
	else
		self.screen.binder.configPanel.binder.pw:setPasswordChar("*")
	end
end
		
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
		--self.screen.binder.okBtn:setText( STRINGS.MULTI_MOD.RETRY )
		--self.screen.binder.okBtn.onClick = util.makeDelegate( nil, function() self.result = modalDialog.OK end )
		self.screen.binder.okBtn:setVisible( false )
		self.screen.binder.cancelBtn.onClick = util.makeDelegate( nil, function() self.result = modalDialog.CANCEL end )
		self.screen.binder.cancelBtn:setClickSound(cdefs.SOUND_HUD_MENU_CANCEL)
	end
}

local function onClickOk( self )
	if self.isHosting then
		-- Signal the server to start listening to clients, then launch the multiplayer campaign.
		local campaign = self._campaign
		local diff = self._diff
		local options = self._campaignOptions
		
		statemgr.activate( multiMod, self.host, self.screen.binder.configPanel.binder.pw:getText() )
		statemgr.deactivate( self )
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
			
			statemgr.activate( stateTeamPreview( diff, options ) )
		end
	else
		local client = multiMod.client
		local ip = self.screen.binder.configPanel.binder.ipAdress:getText()
		local port = tonumber(self.screen.binder.configPanel.binder.port:getText())
		local pw = self.screen.binder.configPanel.binder.pw:getText()
		
		-- Create a client object and attempt to connect to the server
		MOAIFmodDesigner.playSound(  cdefs.SOUND_HUD_MENU_POPUP )
		statemgr.activate( multiMod, client, ip, port, pw )
		statemgr.activate( stateConnecting )
		
		local header = stateConnecting.screen.binder.headerTxt
		local body = stateConnecting.screen.binder.bodyTxt
		
		while stateConnecting.result ~= modalDialog.CANCEL do
			if client.err then
				-- Unhandled error.
				header:setText( STRINGS.MULTI_MOD.CONNECTION_FAILED )
				body:setText( client.err )
			elseif client.passwordAccepted then
				-- We're in!
				body:setText( STRINGS.MULTI_MOD.WAITING_JOINING )
				
				-- Put some kind of lobby screen here maybe?
				if multiMod.campaign then
					if statemgr.isActive( stateConnecting ) then
						statemgr.deactivate( stateConnecting )
					end
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

		-- It's possible for shutdown to preemptively deactivate active dialogs from under us.
		if statemgr.isActive( stateConnecting ) then
			statemgr.deactivate( stateConnecting )
		end
		if statemgr.isActive( multiMod ) then
			statemgr.deactivate( multiMod )
		end
	end
end

local function onClickMode( self )
	self.isHosting = false
	self.isJoining = false
	self.screen.binder.headerTxt:spoolText(STRINGS.MULTI_MOD.TITLE_SETUP)
	self.screen.binder.headerTxt2:spoolText(STRINGS.MULTI_MOD.BODY_SETUP)
	
	self.screen.binder.modePanel:setVisible(true)
	self.screen.binder.modePanel:createTransition( "activate_below" )
	self.screen.binder.configPanel:createTransition( "deactivate_below",
					function( transition )
						self.screen.binder.configPanel:setVisible( false )
					end,
				 { easeOut = true } )
end

local function onClickHost( self )
	self.isHosting = true
	self.screen.binder.headerTxt:spoolText(STRINGS.MULTI_MOD.TITLE_HOST)
	self.screen.binder.headerTxt2:spoolText(STRINGS.MULTI_MOD.BODY_HOST)
	
	self.screen.binder.configPanel:setVisible(true)
	if self._campaign then
		-- If we are resuming an existing campaign then we are jumping directly into the host panel, so no need to create a transition.
		self.screen.binder.modePanel:setVisible( false )
	else
		self.screen.binder.configPanel:createTransition( "activate_below" )
		self.screen.binder.modePanel:createTransition( "deactivate_below",
						function( transition )
							self.screen.binder.modePanel:setVisible( false )
						end,
					 { easeOut = true } )
	end
	
	self.screen.binder.configPanel.binder.ipAdress:setDisabled(true)
	self.screen.binder.configPanel.binder.port:setDisabled(true)
	self.screen.binder.configPanel.binder.ipAdress._cont._isDisabled = true
	self.screen.binder.configPanel.binder.port._cont._isDisabled = true
	self.screen.binder.configPanel.binder.pw:setPasswordChar("*")
	self.screen.binder.configPanel.binder.okBtn.binder.btn:setDisabled(false)
	
	if self.host then
		self.screen.binder.configPanel.binder.ipAdress:setText(self.host.ip or self.host.localIp or "")
		self.screen.binder.configPanel.binder.port:setText(self.host.port or multiMod.DEFAULT_PORT)
	else
		-- This creates the server object, but doesn't tell it to start listening to clients yet.
		-- This allows us to retrieve information such as port.
		local host = multiMod.host
		local err = host:prepareConnection()
	
		if err then
			self.screen.binder.headerTxt2:spoolText("ERROR: "..tostring(err))
			self.screen.binder.configPanel.binder.okBtn.binder.btn:setDisabled(true)
		else
			self.host = host
		end
	
		self.screen.binder.configPanel.binder.ipAdress:setText(host.ip or host.localIp or "")
		self.screen.binder.configPanel.binder.port:setText(host.port or multiMod.DEFAULT_PORT)
	end
end

local function onClickJoin( self )
	self.isJoining = true
	self.screen.binder.headerTxt:spoolText(STRINGS.MULTI_MOD.TITLE_JOIN)
	self.screen.binder.headerTxt2:spoolText(STRINGS.MULTI_MOD.BODY_JOIN)
	
	self.screen.binder.configPanel.binder.ipAdress:setDisabled(false)
	self.screen.binder.configPanel.binder.port:setDisabled(false)
	self.screen.binder.configPanel.binder.ipAdress._cont._isDisabled = nil
	self.screen.binder.configPanel.binder.port._cont._isDisabled = nil
	self.screen.binder.configPanel.binder.ipAdress:setText("")
	self.screen.binder.configPanel.binder.port:setText(tostring(multiMod.DEFAULT_PORT))
	self.screen.binder.configPanel.binder.ipAdress._cont.legalKeys = "[%d,%.]"
	self.screen.binder.configPanel.binder.port._cont.legalKeys = "%d"
	self.screen.binder.configPanel.binder.pw:setPasswordChar("*")
	
	self.screen.binder.configPanel:setVisible(true)
	self.screen.binder.configPanel:createTransition( "activate_below" )
	self.screen.binder.modePanel:createTransition( "deactivate_below",
				    function( transition )
					    self.screen.binder.modePanel:setVisible( false )
				    end,
			     { easeOut = true } )
	
	while self.isJoining do
		local ip = self.screen.binder.configPanel.binder.ipAdress:getText()
		local port = tonumber(self.screen.binder.configPanel.binder.port:getText())
		local disableOk = string.len(ip) == 0 or port == nil or port == 0
		self.screen.binder.configPanel.binder.okBtn.binder.btn:setDisabled(disableOk)
		coroutine.yield()
	end
end

local function onClickLocal( self )
	-- Launch the singleplayer campaign
	local stateTeamPreview = include( "states/state-team-preview" )
	local endless = self._campaignOptions.maxHours == math.huge
	local diff = self._diff
	local options = self._campaignOptions
	statemgr.deactivate( self )
	
    if endless or not config.SHOW_MOVIE then
        statemgr.activate( stateTeamPreview( diff, options ) )
    else
		MOAIFmodDesigner.stopSound("theme")
		local movieScreen = include('client/fe/moviescreen')
		local SCRIPTS = include('client/story_scripts')
        movieScreen("data/movies/IntroCinematic.ogv", function()
            statemgr.activate( stateTeamPreview( diff, options ) )
        end,  SCRIPTS.SUBTITLES.INTRO )
    end
end

local function onClickCancel( self )
	MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_GAME_WOOSHOUT )
	
	local stateGenerationOptions = include( "states/state-generation-options" )
	statemgr.deactivate( self )
	statemgr.activate( stateGenerationOptions(), self._diff, self._campaignOptions )
end

local function toMainMenu()
	MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_GAME_WOOSHOUT )
	
	statemgr.deactivate( self )
	
	local stateMainMenu = include( "states/state-main-menu" )
	statemgr.activate( stateMainMenu() )
end

function stateSetupMultiplayer:onLoad( campaign, difficulty, params )
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
	
	self.screen.binder.configPanel:setVisible(false)
	self.screen.binder.modePanel:setVisible(true)
	
	self.screen.binder.headerTxt:spoolText(STRINGS.MULTI_MOD.TITLE_SETUP)
	self.screen.binder.headerTxt2:spoolText(STRINGS.MULTI_MOD.BODY_SETUP)
	
	-- Configuration Panel
	self.screen.binder.configPanel.binder.okBtn.binder.btn.onClick = util.makeDelegate(nil, onClickOk, self)
	self.screen.binder.configPanel.binder.okBtn.binder.btn:setClickSound(cdefs.SOUND_HUD_MENU_CONFIRM)
	self.screen.binder.configPanel.binder.okBtn.binder.btn:setText(STRINGS.UI.BUTTON_ACCEPT)
	
	self.screen.binder.configPanel.binder.backToModeBtn.binder.btn.onClick = util.makeDelegate(nil, onClickMode, self)
	self.screen.binder.configPanel.binder.backToModeBtn.binder.btn:setClickSound(cdefs.SOUND_HUD_MENU_CANCEL)
	self.screen.binder.configPanel.binder.backToModeBtn.binder.btn:setText(STRINGS.UI.BUTTON_CANCEL)
   	--self.screen.binder.configPanel.binder.backToModeBtn.binder.btn:setHotkey( "pause" )
	
	--self.screen.binder.configPanel.binder.showPwButton.binder.btn:setClickSound(cdefs.SOUND_HUD_MENU_CANCEL)
	self.screen.binder.configPanel.binder.showPwButton.binder.btn.onClick = util.makeDelegate(nil, togglePw, self)
	
	-- Mode Panel
	self.screen.binder.modePanel.binder.hostBtn.binder.btn.onClick = util.makeDelegate(nil, onClickHost, self)
	self.screen.binder.modePanel.binder.hostBtn.binder.btn:setClickSound(cdefs.SOUND_HUD_MENU_CONFIRM)
	self.screen.binder.modePanel.binder.hostBtn.binder.btn:setText(STRINGS.MULTI_MOD.BUTTON_HOST)
	
	self.screen.binder.modePanel.binder.joinBtn.binder.btn.onClick = util.makeDelegate(nil, onClickJoin, self)
	self.screen.binder.modePanel.binder.joinBtn.binder.btn:setClickSound(cdefs.SOUND_HUD_MENU_CONFIRM)
	self.screen.binder.modePanel.binder.joinBtn.binder.btn:setText(STRINGS.MULTI_MOD.BUTTON_JOIN)
	
	self.screen.binder.modePanel.binder.singlePlayerBtn.binder.btn.onClick = util.makeDelegate(nil, onClickLocal, self)
	self.screen.binder.modePanel.binder.singlePlayerBtn.binder.btn:setClickSound(cdefs.SOUND_HUD_MENU_CONFIRM)
	self.screen.binder.modePanel.binder.singlePlayerBtn.binder.btn:setText(STRINGS.MULTI_MOD.BUTTON_LOCAL)
	
	self.screen.binder.modePanel.binder.cancelBtn.binder.btn.onClick = util.makeDelegate(nil, onClickCancel, self)
	self.screen.binder.modePanel.binder.cancelBtn.binder.btn:setClickSound(cdefs.SOUND_HUD_MENU_CANCEL)
	self.screen.binder.modePanel.binder.cancelBtn.binder.btn:setText(STRINGS.UI.BUTTON_CANCEL)
	--self.screen.binder.modePanel.binder.cancelBtn.binder.btn:setHotkey( "pause" )
	
	if campaign then
		-- Resuming an existing game is host-only.
		onClickHost( self )
		self.screen.binder.configPanel.binder.backToModeBtn.binder.btn.onClick = util.makeDelegate(nil, toMainMenu)
	end
end

function stateSetupMultiplayer:onUnload(  )
	if self.screen and self.screen:isActive() then
		mui.deactivateScreen( self.screen )
	end
	self.screen = nil
	
	if self.host and not self.isHosting then
		self.host:onUnload(  )
	end
	self.isJoining = nil
	self.host = nil
	self.game = nil
	self._campaign = nil
	self._diff = nil
	self._campaignOptions = nil
end

return stateSetupMultiplayer