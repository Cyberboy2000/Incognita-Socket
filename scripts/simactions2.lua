local simactions = include( "sim/simactions" )

simactions.yieldTurnAction = function( sim, clientName, previousFocusedPlayerIndex, focusedPlayerIndex )
	sim.currentClientName = clientName
	sim:dispatchEvent( "BACKSTAB_TURN_YIELD", {name = clientName} )
end