local modal_thread = include( "gameplay/modal_thread" )
local modalDialog = include( "states/state-modal-dialog" )

function modal_thread.checkAutoClose( modal, game, ignoreMultiMod )
    if game.chessTimer and game.chessTimer >= game.params.difficultyOptions.timeAttack then
        -- Time has expired.
        return modalDialog.CANCEL

    elseif game.chessTimer == 0 then
        -- NPC's turn; modals shouldnt be allowed to last forever, so time them out.
        modal.autoCloseTimer = (modal.autoCloseTimer or (3 * cdefs.SECONDS)) - 1
        if modal.autoCloseTimer <= 0 then
            modal.autoCloseTimer = nil
            return modalDialog.CANCEL
        end
    end
	
	if multiMod.autoClose and not ignoreMultiMod then
		return modalDialog.CANCEL
	end

    return nil
end

function modal_thread:yield()
    coroutine.yield()
    self.result = self.result or modal_thread.checkAutoClose( self, self.viz.game )
end

for k, v in pairs( modal_thread ) do
	if type(v) == "table" and v.yield and k ~= "rewindSuggestDialog" then
		v.yield = modal_thread.yield
	end
end