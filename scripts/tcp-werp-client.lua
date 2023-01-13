local util = include( "client_util" )
local version = include( "modules/version" )
local mui = include("mui/mui")
local mui_defs = include("mui/mui_defs")
local mui_util = include("mui/mui_util")
local cdefs = include( "client_defs" )
local modalDialog = include( "states/state-modal-dialog" )
local cheatmenu = include( "fe/cheatmenu" )
local simactions = include("sim/simactions")
local array = include( "modules/array" )

local base = multiMod.client

local werpClient = util.tcopy( base )

----------------------------------------------------------------
--   Set up a TCP connection tunneling though the werp site   --
----------------------------------------------------------------

local MODE = {
	NONE = 0,
	CLIENT = 1,
	HOST = 2
}

local tcpSelect = multiMod.socketCore.select

function werpClient:onLoad( receiver, address, port, password )
	self.open_games = nil
	self.userIdToClient = {}
	self.clients = {}
	self.nextClientIndex = 1
	self.mode = MODE.NONE

	return base.onLoad( self, receiver, address, port, password )
end

function werpClient:onUnload(  )
	if self.tcp and self.gameId then
		self:werpCommand( "LEAVE_GAME", self.gameId )
	end
	
	self.gameId = nil
	self.clients = nil
	self.userIdToClient = nil
	self.mode = MODE.NONE

	return base.onUnload( self )
end

function werpClient:shutdownClient( client, err, message )
	log:write( string.format( "Client %s left the game", client.userId) )
	array.removeElement( self.clients, client )
	self.userIdToClient[client.userId] = nil
	self.receiver:onClientDisconnect( client, message )
end

function werpClient:receiveLine( fullLine )
	-- Received line from werp: Split it into a command with parameters
	local params = {}
	
	for param in string.gmatch( fullLine, "([^|]+)") do
		table.insert(params, param)
	end
	
	local command = params[1] or fullLine
	
	if multiMod.VERBOSE then
		log:write("Received werp command "..fullLine)
	end
	
	if command == "RECEIVED" then -- Normal gameplay message (used by both clients and host)
		local gameId = params[2]
		local userId = params[3]
		local line = params[4]
		
		if self.mode == MODE.CLIENT then
			line = userId
		end
		
		if line and userId and gameId == self.gameId then
			if self.mode == MODE.HOST then
				local client = userId and self.userIdToClient[userId]
				
				if client then
					multiMod.host.receiveLine( self, client, line )
				end
			elseif self.mode == MODE.CLIENT then
				multiMod.client.receiveLine( self, line )
			end
		end
	elseif command == "PLAYER_JOINED" then -- Remote client joined game (used by host)
		if self.mode == MODE.HOST then
			local gameId = params[2]
			local userId = params[3]
			local line = params[4]
			
			local data, err = multiMod.serializer.deserializeAction(line)
			
			if userId and data and gameId and gameId == self.gameId then
				if type(data) == "table" and (data.pw == self.password or not self.hasPassword) then
					log:write( string.format( "Client %s joined the game", userId) )
					local client = {
						userId = userId,
						clientIndex = self.nextClientIndex,
						hasPassword = true
					}
					
					self.nextClientIndex = self.nextClientIndex + 1
					self.userIdToClient[userId] = client
					self:werpCommand( "ACCEPT_JOIN", gameId, userId )
					self:sendTo( self.receiver:mergeCampaign( {pwA = true} ), client )
					table.insert(self.clients,client)
				else
					self:werpCommand( "REJECT_JOIN", gameId, userId, "Password Incorrect" )
				end
			else
				self:werpCommand( "REJECT_JOIN", gameId, userId, "Error: "..tostring(err) )
			end
		end
	elseif command == "PLAYER_LEFT" then -- Remote client disconnected (used by host)
		local gameId = params[2]
		local userId = params[3]
		local client = self.userIdToClient[userId]
		
		if client then
			self:shutdownClient( client, nil, "Disconnected from game" )
		end
	elseif command == "OPEN_GAMES" then -- List of open games (return from LIST_OPEN_GAMES query)
		self.open_games = {}
	
		for i = 3, #params, 2 do
			local game = {
				gameId = params[i - 1],
				name = params[i - 1],
				message = multiMod.serializer.deserializeAction( params[i] ),
				hasPw = false
			}
			
			if type( game.message ) == "table" then
				if game.message.name then
					game.name = game.message.name
				end
				if game.message.hasPw then
					game.hasPw = true
				end
			end
			
			table.insert( self.open_games, game )
		end
	elseif command == "NO_OPEN_GAMES" then -- No open games (return from LIST_OPEN_GAMES query)
		self.open_games = {}
	elseif command == "CREATED_GAME" then -- List of open games (return from LIST_OPEN_GAMES query)
		if self.mode == MODE.HOST then
			self.gameId = params[2]
		end
	elseif command == "JOINED" then -- Successfully joined (used by clients)
		if self.mode == MODE.CLIENT and self.gameId == params[2] then
			self.passwordAccepted = true
		end
	elseif command == "JOIN_FAILED" then -- Werp site rejected our join attempt (used by clients)
		self.joinFailed = true
		self.joinFailedReason = STRINGS.MULTI_MOD.JOIN_FAILED_CLOSED
	elseif command == "REJECTED" then -- Host rejected our join attempt (used by clients)
		self.joinFailed = true
		self.joinFailedReason = params[2]
	elseif command == "WELCOME" then -- Initial message from werp
		self.userId = params[2]
	elseif command == "GAME_OVER" then -- Host closed game (used by clients)
		self.receiver:onConnectionError( STRINGS.MULTI_MOD.GAME_OVER )
	elseif command == "LEFT" or command == "LEAVE_FAILED" then -- Unused
	elseif command == "ERROR" then
		log:write("Server error: "..params[2])
	else
		log:write("Unknown command: "..fullLine)
	end
end

function werpClient:listGames()
	 -- Queries the werp site for open games
	self:werpCommand( "LIST_OPEN_GAMES" )
end

function werpClient:joinGame( gameId, data )
	-- Connects to an open game on the werp site by an id returned from LIST_OPEN_GAMES
	local line, err = multiMod.serializer.serializeAction( data )

	self.gameId = gameId
	self:werpCommand( "JOIN_GAME", gameId, line )
	self.mode = MODE.CLIENT
	
	return err
end

function werpClient:leaveGame( gameId )
	self.mode = MODE.NONE
	self:werpCommand( "LEAVE_GAME", self.gameId )
end

function werpClient:createGame( data, password )
	-- Requests the werp site to open a new game listing
	log:write("Converting werp client to host")
	local line, err = multiMod.serializer.serializeAction( data )
	self.gameId = nil
	self.hasPassword = password and string.len(password) > 0
	self.campaignName = data.name
	self.password = password
	
	if line then
		self.mode = MODE.HOST
		self:werpCommand( "CREATE_GAME", line )
	end
	
	return err
end

function werpClient:send( data, targetClient, excludeClient, rawLine )
	if not self.receiver then
		return "Server Not Running"
	end

	local err 
	if not rawLine then
		data, err = multiMod.serializer.serializeAction( data )
	end
	
	if data then
		if targetClient then
			self:werpCommand( "SEND_TO", self.gameId, targetClient.userId, data ) -- Send to a specific target client
		elseif excludeClient then
			self:werpCommand( "ECHO_FROM", self.gameId, excludeClient.userId, data ) -- Send to all clients EXCEPT the specified client
		else
			self:werpCommand( "SEND", self.gameId, data ) -- Send to all clients (or the host, if we ourselves are a client)
		end
	end
	
	return err
end

function werpClient:sendTo( data, toClient )
	return self:send( data, toClient )
end

function werpClient:echoLine( line, fromClient )
	return self:send( line, nil, fromClient, true )
end

function werpClient:werpCommand( command, ... )
	local buffer = { command, ... }
	local fullLine = table.concat( buffer, "|" )
	
	if multiMod.VERBOSE then
		log:write("Sending werp command "..fullLine)
	end
	
	self.sendingBuffer = self.sendingBuffer..fullLine.."\n"
end

function werpClient:getClientCount()
	return #self.clients
end

function werpClient:isHost()
	return self.mode == MODE.HOST
end

return werpClient