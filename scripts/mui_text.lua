local mui_text = include("mui/widgets/mui_text")
local mui_defs = include("mui/mui_defs")

local oldHandleEvent = mui_text.handleEvent

local LEGAL_KEYS ='[%w%p\n ]'

function mui_text:isLegalKey( keychar )
	return keychar:match( self.legalKeys or LEGAL_KEYS ) ~= nil
end

function mui_text:handleEvent( ev )
	if ev.eventType == mui_defs.EVENT_KeyChar and not self:isLegalKey( ev.keychar ) then
		return
	end
	
	oldHandleEvent( self,ev )
end