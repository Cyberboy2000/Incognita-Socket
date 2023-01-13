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

local tcpClient = {}

local tcpSelect = multiMod.socketCore.select

----------------------------------------------------------------
--   Sets up a TCP client and read messages from the server   --
----------------------------------------------------------------

function tcpClient:onLoad( receiver, address, port, password )
	assert(receiver)
	assert(type(receiver.receiveData) == "function")
	assert(self.receiver == nil)
	assert(receiver:getUplink(  ) == self)
	assert(self.receiver == nil)
	assert(type(address) == "string")
	assert(type(port) == "number")
	assert(self.tcp == nil)
	
	self.receivingBuffer = ""
	self.sendingBuffer = ""
	self.passwordAccepted = nil
	self.passwordRejected = nil
	self.targetAddress = address
	self.targetPort = port
	self.err = nil
	
	local tcp, err, ok = multiMod.socketCore.tcp()
	
    if tcp then
		tcp:settimeout(0)
		ok, err = tcp:connect(address, port)
		self.receiver = receiver
		self.connected = ok
		
		local localAddress, localPort = tcp:getsockname()
		local peerAddress, peerPort = tcp:getpeername()
		
		log:write("Established a tcp connection to "..tostring(address).." on port "..tostring(port))
		log:write("Local socket "..tostring(localAddress).." : "..tostring(localPort))
		log:write("Peer name "..tostring(peerAddress).." : "..tostring(peerPort))
	end
	if err and err ~= "timeout" then
		log:write("Failed to create client object: "..err)
		self:onError(err,true)
	end
	
	self.tcp = tcp
	return self.err
end

----------------------------------------------------------------
function tcpClient:onUnload(  )
	if self.tcp then
		log:write("TCP client shutting down...")
		self.tcp:close()
	end
	self.tcp = nil
	self.receiver = nil
	self.connected = nil
	self.receivingBuffer = ""
	self.sendingBuffer = ""
end

----------------------------------------------------------------
function tcpClient:onUpdate(  )
	if self.connected then
		-- Receive data from the server.
		local readable, writeable = tcpSelect({self.tcp},{self.tcp},0)
		
		if readable[self.tcp] then
			local line, err, partial = self.tcp:receive()
			
			if err == "timeout" then
				-- We received only a partial result due to timeout, buffer it.
				self.receivingBuffer = self.receivingBuffer..partial
			elseif err then
				-- Unhandled error: Shutdown.
				log:write("tcp:receive for client failed: "..err)
				self:onError(err,true)
			else
				-- The stream of data reached a newline.
				-- Combine it with the buffered data.
				local fullLine = self.receivingBuffer..line
				self.receivingBuffer = ""
				
				if multiMod.VERBOSE then
					log:write("Received "..tostring(fullLine))
				end
				
				self:receiveLine(fullLine)
			end
		end
		
		-- If we have scheduled sending data to the server, do so.
		-- Note that we may have terminated due to errors during the receiving process.
		if self.tcp and writeable[self.tcp] and #self.sendingBuffer > 0 then
			local bytesSent, err, errBytesSent = self.tcp:send( self.sendingBuffer )
			self.sendingBuffer = string.sub(self.sendingBuffer, (bytesSent or errBytesSent) + 1) -- Remove the sent data from the buffer.
			if err and err ~= "timeout" then
				log:write("tcp:send for client returned "..err)
				self:onError(err,true)
			end
		end
	elseif self.tcp then
		------ Connect ------ 
		local readable, writeable = tcpSelect({},{self.tcp},0)
		if writeable[self.tcp] then
			local ok, err = self.tcp:connect(self.targetAddress, self.targetPort)
			if ok or err == "already connected" then
				self.connected = true
		
				local localAddress, localPort = self.tcp:getsockname()
				local peerAddress, peerPort = self.tcp:getpeername()
				
				log:write("Confirmed tcp connection")
				log:write("Local socket "..tostring(localAddress).." : "..tostring(localPort))
				log:write("Peer name "..tostring(peerAddress).." : "..tostring(peerPort))
			else
				log:write("tcp:connect for client failed: "..err)
				self:onError(err,true)
			end
		end
	end
end

function tcpClient:receiveLine(fullLine)
	local data, err = multiMod.serializer.deserializeAction(fullLine)
	-- Check if the password was accepted.
	if type(data) == "table" then
		if data.pwA then
			self.passwordAccepted = true
		elseif data.pwR then
			self.passwordRejected = true
		end
	end
	-- Pass the received data along to the game logic.
	self.receiver:receiveData(nil,data,fullLine)
end

function tcpClient:onError( err, isTcpError )
	self.err = err
	if isTcpError then
		self.receiver:onConnectionError(err)
	end
end

function tcpClient:send( data )
	local line, err = multiMod.serializer.serializeAction( data )
	
	if line then
		if multiMod.VERBOSE then
			log:write("client sending "..line)
		end
		self.sendingBuffer = self.sendingBuffer..line.."\n"
		self:onUpdate()
	else
		self:onError(err)
	end
	
	return err
end

function tcpClient:sendTo( ... )
	return self:send( ... )
end

function tcpClient:isHost()
	return false
end

return tcpClient