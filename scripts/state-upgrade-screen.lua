local util = include("modules/util")
local mui = include( "mui/mui" )
local simdefs = include("sim/simdefs")
local agentdefs = include("sim/unitdefs/agentdefs")
local skilldefs = include( "sim/skilldefs" )
local modalDialog = include( "states/state-modal-dialog" )

local stateUpgradeScreen = include( "states/state-upgrade-screen" )

local skillChanges = stateUpgradeScreen.skillChanges

local oldLearnSkill = skillChanges.learnSkill
local oldUndoSkill = skillChanges.undoSkill

function skillChanges:learnSkill( agentIdx, skillIdx )
	if multiMod:getUplink() then
	
	end

	local ok = oldLearnSkill( self, agentIdx, skillIdx )

	return ok
end

function skillChanges:undoSkill( agentIdx, skillIdx )
	local ok = oldUndoSkill( self, agentIdx, skillIdx )
	
	if multiMod:getUplink() then
		
	end

	return ok
end

multiMod.upgradeActions = {
	learnSkill = {
		doAction = function( agency,  agentIdx, skillIdx )
			
		end,
		
		undoAction = function( agency,  agentIdx, skillIdx )
			
		end,
	},
	undoSkill = {
	
	},
	
}

local function onClickAgentInv(self, unit, unitDef, upgrade, index, itemIndex, stash )
	if self._agency.upgrades and #self._agency.upgrades >= simdefs.agencyInventorySize then
		MOAIFmodDesigner.playSound("SpySociety/HUD/gameplay/upgrade_cancel_unit")
		modalDialog.show( STRINGS.UI.REASON.FULL_STASH )
	else
		MOAIFmodDesigner.playSound("SpySociety/HUD/gameplay/HUD_ItemStorage_PutIn")
		if not self._agency.upgrades then
			self._agency.upgrades ={}
		end
		table.insert(self._agency.upgrades,upgrade)
		table.remove(unitDef.upgrades,itemIndex)
	end
	
	self:refreshInventory(unitDef,index)
end
		
local function onClickStash(self, unit, unitDef, upgrade, index, itemIndex, stash )
	if unit:getInventoryCount( ) >= 8 then
		MOAIFmodDesigner.playSound("SpySociety/HUD/gameplay/upgrade_cancel_unit")
		modalDialog.show( STRINGS.UI.REASON.INVENTORY_FULL )
	else	
		MOAIFmodDesigner.playSound("SpySociety/HUD/gameplay/HUD_ItemStorage_TakeOut")		
		table.insert(unitDef.upgrades,upgrade)
		table.remove(self._agency.upgrades,itemIndex)
	end
	
	self:refreshInventory(unitDef,index)
end

local oldRefreshInventory = stateUpgradeScreen.refreshInventory

stateUpgradeScreen.refreshInventory = function( self, unitDef, index )
	oldRefreshInventory( self, unitDef, index )
	
	for i, widget in self.screen.binder:forEach( "inv_" ) do
		if widget.binder.btn.onClick then
			--widget.binder.btn.onClick._fn = onClickAgentInv
		end
	end
	for i, widget in self.screen.binder:forEach( "agency_inv_" ) do
		if widget.binder.btn.onClick then
			--widget.binder.btn.onClick._fn = onClickStash
		end
	end
end