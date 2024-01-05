local simactions = include( "sim/simactions" )

simactions.yieldTurnAction = function( sim, clientName, previousFocusedPlayerIndex, focusedPlayerIndex, isFocusedPlayer )
	sim.currentClientName = clientName
	sim:dispatchEvent( "BACKSTAB_TURN_YIELD", {name = clientName, isFocusedPlayer = isFocusedPlayer} )
end
