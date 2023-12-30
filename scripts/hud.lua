local hud = include( "hud/hud" )
local cdefs = include( "client_defs" )
local _refreshTimeAttack = hud.refreshTimeAttack

function hud:refreshTimeAttack()
	local chessTimeLeft = self._game.params.difficultyOptions.timeAttack - self._game.chessTimer
	if multiMod:hasYielded() and chessTimeLeft <= 10 * cdefs.SECONDS and chessTimeLeft % 60 == 0 and chessTimeLeft > 0 then
		return
	end
	
	_refreshTimeAttack(self)
end
