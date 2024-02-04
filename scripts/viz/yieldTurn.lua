local util = include( "client_util" )
local cdefs = include( "client_defs" )
local rig_util = include( "gameplay/rig_util" )

local function stopTitleSwipe(hud)
	if not multiMod.isFocusedPlayer then
		MOAIFmodDesigner.playSound( "SpySociety/HUD/gameplay/turnswitch_out" )
	end
    rig_util.waitForAnim(  hud._screen.binder.swipe.binder.anim:getProp(), "pst" )
    hud._screen.binder.swipe:setVisible(false)
end

local function startTitleSwipe( hud, swipeText,color,sound,showCorpTurn,turn)
	
	MOAIFmodDesigner.playSound( sound )
	hud._screen.binder.swipe:setVisible(true)
	hud._screen.binder.swipe.binder.anim:setColor(color.r, color.g, color.b, color.a )	
	hud._screen.binder.swipe.binder.anim:setAnim("pre")
	if multiMod.isFocusedPlayer then
		MOAIFmodDesigner.playSound( "SpySociety/HUD/voice/level1/alarmvoice_warning" )
	else
		MOAIFmodDesigner.playSound( "SpySociety/HUD/gameplay/turnswitch_in" )
	end

	hud._screen.binder.swipe.binder.txt:spoolText(string.format(swipeText))	
	hud._screen.binder.swipe.binder.txt:setColor(color.r, color.g, color.b, color.a )	

	hud._screen.binder.swipe.binder.turnTxt:spoolText(string.format(STRINGS.UI.TURN, turn), 20)	
	hud._screen.binder.swipe.binder.turnTxt:setColor(color.r, color.g, color.b, color.a )	

	local stop = false
	hud._screen.binder.swipe.binder.anim:getProp():setPlayMode( KLEIAnim.LOOP )
	hud._screen.binder.swipe.binder.anim:getProp():setListener( KLEIAnim.EVENT_ANIM_END,
	function( anim, animname )
				if animname == "pre" then
					hud._screen.binder.swipe.binder.anim:setAnim("loop")		
					stop = true
				end					
			end )		

	while stop == false do
		coroutine.yield()		
	end

end

local function wait( event, evType, evData, boardRig, hud, vizThread )
	local txt = string.format( STRINGS.MULTI_MOD.BACKSTAB_YIELD_SWIPE, util.toupper(evData.name) )
	
	local turn = math.ceil( (boardRig:getSim():getTurnCount() + 1) / 2)

	local color
	if multiMod.isFocusedPlayer then
		color = {r=244/255, g=255/255, b=120/255, a=1}
	else
		color = {r=140/255, g=255/255, b=255/255, a=1}
	end
	startTitleSwipe( hud, txt, color, cdefs.SOUND_HUD_GAME_ACTIVITY_AGENT, false, turn )

	rig_util.wait(30)		
	stopTitleSwipe( hud )
end

return wait
