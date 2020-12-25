local statePreview = include("states/state-team-preview")
local oldOnLoad = statePreview.onLoad
local oldOnUnload = statePreview.onUnload
local oldOnClickCampaign
local oldOnClickCancel

local function onClickCampaign(self)
	oldOnClickCampaign(self)
end

local function onClickCancel(self)
	if multiMod:getUplink() then
		statemgr.deactivate(multiMod)
	end
	oldOnClickCancel(self)
end

function statePreview:onLoad()
	oldOnLoad(self)
	oldOnClickCampaign = oldOnClickCampaign or self._panel.binder.acceptBtn.onClick._fn
	self._panel.binder.acceptBtn.onClick._fn = onClickCampaign
	
	oldOnClickCancel = oldOnClickCancel or self._panel.binder.cancelBtn.onClick._fn
	self._panel.binder.cancelBtn.onClick._fn = onClickCancel
end

function statePreview:onUnload()
	local user = savefiles.getCurrentGame()
	local campaign = user.data.saveSlots[ user.data.currentSaveSlot ]
	if campaign then
		multiMod:loadCampaignGame( campaign )
	end
	
	oldOnUnload(self)
end