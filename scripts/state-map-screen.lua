local mui = include( "mui/mui" )
local simdefs = include("sim/simdefs")
local agentdefs = include("sim/unitdefs/agentdefs")
local array = include("modules/array")
local util = include("modules/util")

local mapScreen = include("states/state-map-screen")

local oldClosePreview = mapScreen.closePreview
local oldOnLoad = mapScreen.onLoad
local oldOnUnLoad = mapScreen.onUnload

function mapScreen:closePreview(preview_screen, situation, go_to_there, ...)
	local campaign = self._campaign
	if go_to_there and multiMod:getUplink() and not multiMod.startingMission then
		local situationIndex = array.find( campaign.situations, situation )
		go_to_there = multiMod:voteMission( situationIndex )
	end
	
	oldClosePreview(self, preview_screen, situation, go_to_there, ...)
end

local function Kill(thing)
	if thing and not thing:IsDone() then
		thing:Hide()
	end
end

function mapScreen:onUnload()
	Kill(self.talkinghead)
	Kill(self.storytalkinghead)
	Kill(self.agentsadded)
	Kill(self.map_moodal)
	
	if self.loadThread then
		self.loadThread:stop()
		self.loadThread = nil
	end

	oldOnUnLoad( self )
end

function mapScreen:onLoad(...)
	local args = {...}
	
	if not self.loadThread and not multiMod.startingMission then
		self.loadThread = MOAICoroutine.new()
		self.loadThread:run( function() 
			oldOnLoad(self, unpack(args))
			self.loadThread = nil
		end)
		
		while self.loadThread do
			coroutine.yield()
		end
	else
		return oldOnLoad(self,...)
	end
end