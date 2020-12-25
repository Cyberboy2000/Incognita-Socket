local stateLoading = include("states/state-loading")
local oldLoadFrontEnd = stateLoading.loadFrontEnd
local oldLoadCampaign = stateLoading.loadCampaign

stateLoading.loadFrontEnd = function(...)
	if multiMod:getUplink() then
		statemgr.deactivate(multiMod)
	end
	oldLoadFrontEnd(...)
end

stateLoading.loadCampaign = function( self, campaign, ... )
	multiMod:loadCampaignGame( campaign )
	oldLoadCampaign( self, campaign, ... )
end