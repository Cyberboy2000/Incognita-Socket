local util = include( "client_util" )
local serverdefs = include( "modules/serverdefs" )
local cdefs = include("client_defs")

----------------------------------------------------------------
-- Local functions
local STATE_SELECT_SAVE = 1
local STATE_CONTINUE_GAME = 2
local STATE_NEW_GAME = 3

local function onClickHost( dialog, campaign )
    MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_GAME_WOOSHOUT )

    mod_manager:resetContent()
    mod_manager:loadModContent( campaign.difficultyOptions.enabledDLC )
	
    MOAIFmodDesigner.stopSound("theme")
	
	dialog:hide()
	statemgr.deactivate( dialog._mainMenu )
	statemgr.activate( multiMod.stateSetupWerp, campaign )
end

----------------------------------------------------------------
-- Interface functions

local dialog = include("fe/saveslots-dialog")
local oldShowState = dialog.showState

function dialog:showState( state, campaign )
	oldShowState( self, state, campaign )
	
	self._screen.binder.optionsBG.binder["optionsBG small"]:setVisible( state == STATE_NEW_GAME )
	self._screen.binder.optionsBG.binder["optionsBG small 2"]:setVisible( state == STATE_NEW_GAME )
	self._screen.binder.optionsBG.binder["multiOptionsBG"]:setVisible( state == STATE_CONTINUE_GAME )
	self._screen.binder.optionsBG.binder["multiOptionsBG 2"]:setVisible( state == STATE_CONTINUE_GAME )

	if state == STATE_CONTINUE_GAME then
		self._screen.binder.hostBtn:setDisabled( not multiMod:canContinueCampaign( campaign ))
		self._screen.binder.hostBtn.onClick = util.makeDelegate( nil, onClickHost, self, campaign )
	end
end