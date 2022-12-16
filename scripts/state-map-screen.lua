local simdefs = include("sim/simdefs")
local agentdefs = include("sim/unitdefs/agentdefs")
local array = include("modules/array")

local mapScreen = include("states/state-map-screen")

local oldClosePreview = mapScreen.closePreview
local oldOnLoad = mapScreen.onLoad

function mapScreen:closePreview(preview_screen, situation, go_to_there, ...)
	local campaign = self._campaign
	if go_to_there and multiMod:getUplink() and not multiMod.startingMission then
		local situationIndex = array.find( campaign.situations, situation )
		go_to_there = multiMod:voteMission( situationIndex )
	end
	
	oldClosePreview(self, preview_screen, situation, go_to_there, ...)
end