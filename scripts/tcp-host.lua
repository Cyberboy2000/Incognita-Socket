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

local tcpSelect = multiMod.socketCore.select

local tcpHost = {
	clientIndex = 0,
	nextClientIndex = 1,
	clients = {},
	set = {}
}

----------------------------------------------------------------
--   Set up a TCP server and read messages from the clients   --
----------------------------------------------------------------

function tcpHost:onLoad( receiver, port, password )
	assert(receiver)
	assert(type(receiver.receiveData) == "function")
	assert(self.receiver == nil)
	assert(receiver:getUplink(  ) == self)
	
	self:getIP( receiver, port, password )
	self.err = self:createServer( receiver, port, password )
	self:startListen( receiver, port, password )
end

----------------------------------------------------------------
function tcpHost:onUnload(  )
	self.receiver = nil
	
	for k, client in pairs(self.clients) do
		client.tcp:close()
	end
	
	self.nextClientIndex = 1
	self.clients = {}
	self.set = {}
	
	if self.server then
		log:write("TCP server shutting down...")
		self.server:close()
	end
	self.server = nil
end

----------------------------------------------------------------

function tcpHost:getIP( receiver, port, password )
	if self.ip then
		return self.ip
	else
		local ipTestClient, err, ok = multiMod.socketCore.tcp()
		if ipTestClient then
			ipTestClient:settimeout(1)
			ok, err = ipTestClient:connect("www.google.com", 80)
			
			if ok then
				--local line, receiveErr, partial = ipTestClient:receive()
				--if multiMod.VERBOSE then
					--log:write(string.format("Connection test returned (%s, %s, %s)", tostring(line), tostring(receiveErr), tostring(partial)))
				--end
				
				local ip, port = ipTestClient:getsockname()
				ipTestClient:close()

				log:write("This IP "..ip)
				self.ip = ip
				return ip
			elseif multiMod.VERBOSE then
				log:write("Failed connection test: "..err)
			end
			
			return nil, err
		else
			return nil, err
		end
	end
end

function tcpHost:createServer( receiver, port, password )
	if not self.server then
		-- Create a TCP socket and bind it to the local host, at any port.
		local server, tcpErr, ok = multiMod.socketCore.tcp()
		
		if server then
			-- Make sure we don't block waiting for this client's line.
			server:settimeout(0)
			server:setoption("reuseaddr", true)
			--ok, tcpErr = server:bind(self.ip or "*", multiMod.DEFAULT_PORT)
			ok, tcpErr = server:bind("*", port or multiMod.DEFAULT_PORT)
			if ok then
				-- Find out which port the OS chose for us.
				local ip, port = server:getsockname()
				-- Print a message informing what's up.
				log:write("Please telnet to " .. ip .. " on port " .. port)
				self.server = server
				self.localIp = ip
				self.port = port
			end
		end
		
		if tcpErr then
			log:write("Failed to create server object: "..tcpErr)
		end
		self.err = tcpErr
		return tcpErr
	end
end

function tcpHost:startListen( receiver, port, password )
	if self.server then
		self.receiver = receiver
		local ok, err = self.server:listen()
		self.password = password
		self.hasPassword = type(password) == "string" and string.len(password) > 0
		self.err = err
		
		if err then
			log:write("Failed to start up server object: "..err)
		end
	end
end

function tcpHost:prepareConnection()
	return self:getIP()
end

function tcpHost:shutdownClient( client, err, message )
	local clientIp, clientPort = client.tcp:getpeername()
	message = string.format(message,tostring(clientIp),tostring(clientPort),tostring(err))
	log:write(message)
	
	self.clients[client.tcp] = nil
	array.removeElement( self.set, client.tcp )
	client.tcp:close()
	client.tcp = nil
	
	self.receiver:onClientDisconnect( client, message )
end

----------------------------------------------------------------
function tcpHost:onUpdate(  )
	if self.receiver then
		-- Wait for a connection from any client.
		local canReceiveClient = tcpSelect({self.server},{},0)
		if canReceiveClient[self.server] then
			local clientTcp, err = self.server:accept()
		 
			if clientTcp then
				local clientIp, clientPort = clientTcp:getpeername()
				log:write("Found a client at "..clientIp.." on port " .. clientPort)
				-- Make sure we don't block waiting for this client's line.
				clientTcp:settimeout(0)
				
				local client = {
					tcp = clientTcp,
					receivingBuffer = "",
					sendingBuffer = "",
					clientIndex = self.nextClientIndex
				}
				
				self.nextClientIndex = self.nextClientIndex + 1
				if not self.hasPassword then
					--client.sendingBuffer = multiMod.serializer.serializeAction({pwA=true}).."\n"
				end
				
				self.clients[clientTcp] = client
				table.insert(self.set,clientTcp)
			elseif err ~= "timeout" then
				log:write("tcp:accept failed: "..err)
			end
		end
		
		local readable, writeable = tcpSelect(self.set,self.set,0)
		
		for k, clientTcp in ipairs(readable) do
			local client = self.clients[clientTcp]
			local line, err, partial = clientTcp:receive()
			
			if err == "timeout" then
				-- We received only a partial result due to timeout, buffer it.
				client.receivingBuffer = client.receivingBuffer..partial
				
				if multiMod.VERBOSE then
					log:write("Received "..tostring(line))
				end
			elseif err then
				self:shutdownClient( client, err, err == "closed" and "client at %s on port %s was disconnected" or "client:receive from client at %s on port %s returned: %s" )
			else
				if multiMod.VERBOSE then
					log:write("Received "..tostring(line))
				end
				
				-- The stream of data reached a newline.
				-- Combine it with the buffered data.
				local fullLine = client.receivingBuffer..line
				client.receivingBuffer = ""
				self:receiveLine( client, fullLine )
			end
		end
		
		for k, clientTcp in ipairs(writeable) do
			local client = self.clients[clientTcp]
			
			if client and #client.sendingBuffer > 0 then
				local bytesSent, err, errBytesSent = client.tcp:send( client.sendingBuffer )
				client.sendingBuffer = string.sub( client.sendingBuffer, (bytesSent or errBytesSent) + 1 )
				--log:write("Send "..tostring(bytesSent or errBytesSent))
				if err and err ~= "timeout" then
					self:shutdownClient( client, err, err == "closed" and "client at %s on port %s was disconnected" or "client:send from client at %s on port %s returned: %s" )
				end
			end
		end
	end
end

function tcpHost:receiveLine( client, fullLine )
	local data, err = multiMod.serializer.deserializeAction(fullLine)
	
	-- Note, even if we're not using a password, the client may be waiting for us to check their password and send a response.
	if client.hasPassword then
		-- Pass the received information to the receiver. They will then handle the game logic.
		self.receiver:receiveData(client,data,fullLine)
	elseif type(data) == "table" and data.pw then
		if not self.hasPassword or data.pw == self.password then
			-- Client sent us the correct password.
			client.hasPassword = true
			
			-- Respond to the client with a confirmation, plus the current campaign information.
			self:sendTo( self.receiver:mergeCampaign( {pwA = true} ), client )
			
			-- Finally, pass the information onto the receiver.
			self.receiver:receiveData(client,data,fullLine)
		else
			-- That's the wrong password. Send a rejection message.
			self:sendTo( self.receiver:mergeCampaign( {pwR = true} ), client, true )
		end
	end
end

function tcpHost:serializeData( data, rawLine )
	if rawLine then
		return data
	else
		return multiMod.serializer.serializeAction( data )
	end
end

function tcpHost:send( data, targetClient, excludeClient, noPassword, rawLine )
	if not self.receiver then
		return "Server Not Running"
	end

	local line, err = self:serializeData( data, rawLine )
	
	if line then
		if multiMod.VERBOSE then
			log:write("Host sending "..line)
		end
	
		for k, client in pairs(self.clients) do
			if client == targetClient or targetClient == nil and client ~= excludeClient then
				if client.hasPassword or noPassword then
					client.sendingBuffer = client.sendingBuffer .. line .. "\n"
				end
			end
		end
	end
	
	return err
end

function tcpHost:sendTo( data, toClient, noPassword )
	return self:send( data, toClient, nil, noPassword )
end

function tcpHost:echoLine( line, fromClient )
	return self:send( line, nil, fromClient, nil, true )
end

function tcpHost:getClientCount()
	return #self.set
end

function tcpHost:isHost()
	return true
end

return tcpHost