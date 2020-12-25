local simengine = include("sim/engine")

function simengine:setChoice( choice )
	--simlog( "CHOICE[ %d ] = %s", self._choiceCount, tostring(choice))
    if self._choices[ self._choiceCount ] ~= nil then
		log:write(string.format("ILLEGAL CHOICE OVERRIDE AT %d (WAS %s, TRIED TO SET IT TO %s)",self._choiceCount,tostring(self._choices[ self._choiceCount ]),tostring(choice)))
		return
    end
	self._choices[ self._choiceCount ] = choice
	if multiMod.uplink then
		multiMod:sendChoice( self._choiceCount, choice )
	end
end