local err = nil
local serz = {}
local desz = {}
local serialize
local deserialize

 -- Handle sim history separately, as it could be a security risk
local FORBID = {
	sim_history = true,
	simHistory = true
}
----------------------------------------------------------

serialize = function(d,so)
	local fn = serz[type(d)]
	
	if fn then
		fn(d,so)
	else
		err = err or "Can't serialize "..tostring(d)
	end
end

serz["table"] = function(d,so)
	table.insert(so,"{")
	for k, v in pairs(d) do
		if not FORBID[k] then
			table.insert(so,"[")
			serialize(k,so)
			table.insert(so,"=")
			serialize(v,so)
			table.insert(so,"]")
		end
	end
	table.insert(so,"}")
end
serz["string"] = function(d,so)
	table.insert(so,"S")
	table.insert(so,(d:gsub('.', function (c)
        return string.format('%02X', string.byte(c))
    end)))
	table.insert(so,"R")
end
serz["nil"] = function(d,so)
	table.insert(so,"N")
end
serz["function"] = function(d,so)
	table.insert(so,"N") -- Don't serialize functions, as it could be a security risk
end
serz["boolean"] = function(d,so)
	if d then
		table.insert(so,"T")
	else
		table.insert(so,"F")
	end
end
serz["number"] = function(d,so)
	table.insert(so,"Z")
	table.insert(so,tostring(d))
	table.insert(so,"Y")
end

----------------------------------------------------------

local i = 1

desz["N"] = function() return nil end
desz["T"] = function() return true end
desz["F"] = function() return false end
desz["S"] = function(str)
	local j = str:find("R",i)
	
	if j < i then
		err = err or "Couldn't find closing symbol R after "..tostring(i)
		return
	end
	
	local hexStr = str:sub(i,j-1)
	
	i = j + 1
	
	return (hexStr:gsub('..', function (cc)
        return string.char(tonumber(cc, 16))
    end))
end
desz["Z"] = function(str)
	local j = str:find("Y",i)
	
	if j < i then
		err = err or "Couldn't find closing symbol Y after "..tostring(i)
		return
	end
	
	local num = str:sub(i,j-1)
	
	i = j + 1
	
	return tonumber(num)
end
desz["{"] = function(str)
	local t = {}
	while true do
		local symbol = str:sub(i,i)
		if symbol == "}" then
			i = i + 1
			break
		elseif symbol ~= "[" then
			err = err or "Expected } or [ at "..tostring(i).." got "..symbol
			return
		end
		i = i + 1
		
		local k = deserialize(str)
		if err or (str:sub(i,i) ~= "=") then
			err = err or "Expected = at "..tostring(i).." got "..str:sub(i,i)
			return
		end
		i = i + 1
		
		local v = deserialize(str)
		if err or (str:sub(i,i) ~= "]") then
			err = err or "Expected ] at "..tostring(i).." got "..str:sub(i,i)
			return
		end
		i = i + 1
		
		if k == nil then
			err = err or "Array index is nil"
			return
		end
		
		if not FORBID[k] then
			t[k] = v
		end
	end
	
	return t
end

deserialize = function(str)
	local c = str:sub(i,i)
	local fn = desz[c]
	if not fn then
		err = err or "No way to deserialize object starting with "..tostring(c)
		return
	end
	
	i = i + 1
	
	local val = fn(str)
	
	return val
end

----------------------------------------------------------

local serializeAction = function(action)
	err = nil
	local so = {}
	serialize(action,so)
	
	if err then
		log:write("Serialization Failed: "..err)
		return nil, err
	else
		return table.concat(so)
	end
end

local deserializeAction = function(str)
	if type(str) ~= type("string") then
		log:write("Can't deserialize, expected string and got "..type("string"))
		return
	end

	i = 1
	err = nil
	local t = deserialize(str)
	if err then
		log:write("Deserialization Failed: "..err)
		return
	end
	
	return t
end

return {
	serializeAction = serializeAction,
	deserializeAction = deserializeAction
}