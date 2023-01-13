local err = nil
local serz = {}
local desz = {}
local serialize
local deserialize

local FORMAT = {
	--Tables
	TBL = "{",
	TBL_END = "}",
	KEY = "[",
	VAL = "=",
	NEXT = "]",
	--Strings
	STR = "(",
	STR_END = ")",
	GSUB = "[^%w &/\\_,'?!%+%-%.]", -- The inverse (indicated by ^) of the set of characters we can represent as is (in other words, the set of characters we convert to hex)
	TO_HEX = "$%02X",
	FROM_HEX = '$%x%x',
	
	-- Other
	NUM = "#",
	NUM_END = "*",
	NIL = ":",
	TRUE = "^",
	FALSE = "~",
}


 -- Handle sim history separately, as it poses a security risk
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
	table.insert(so, FORMAT.TBL)
	for k, v in pairs(d) do
		if not FORBID[k] then
			table.insert(so, FORMAT.KEY)
			serialize(k,so)
			table.insert(so, FORMAT.VAL)
			serialize(v,so)
			table.insert(so, FORMAT.NEXT)
		end
	end
	table.insert(so, FORMAT.TBL_END)
end
serz["string"] = function(d,so)
	table.insert(so, FORMAT.STR)
	table.insert(so, (d:gsub(FORMAT.GSUB, function (c)
        return string.format(FORMAT.TO_HEX, string.byte(c))
    end)))
	table.insert(so, FORMAT.STR_END)
end
serz["nil"] = function(d,so)
	table.insert(so, FORMAT.NIL)
end
serz["function"] = function(d,so)
	table.insert(so, FORMAT.NIL) -- Don't serialize functions, as they pose a security risk
end
serz["boolean"] = function(d,so)
	if d then
		table.insert(so, FORMAT.TRUE)
	else
		table.insert(so, FORMAT.FALSE)
	end
end
serz["number"] = function(d,so)
	table.insert(so, FORMAT.NUM)
	table.insert(so, tostring(d))
	table.insert(so, FORMAT.NUM_END)
end

----------------------------------------------------------

local i = 1

desz[FORMAT.NIL] = function() return nil end
desz[FORMAT.TRUE] = function() return true end
desz[FORMAT.FALSE] = function() return false end
desz[FORMAT.STR] = function(str)
	local j = str:find(FORMAT.STR_END,i) or -1
	
	if j < i then
		err = err or string.format("Couldn't find closing symbol %s after %i", FORMAT.STR_END, i)
		return
	end
	
	local hexStr = str:sub(i,j-1)
	
	i = j + 1
	
	return (hexStr:gsub(FORMAT.FROM_HEX, function (cc)
        return string.char(tonumber(string.sub(cc,2,3), 16))
    end))
end
desz[FORMAT.NUM] = function(str)
	local j = str:find(FORMAT.NUM_END,i) or -1
	
	if j < i then
		err = err or string.format("Couldn't find closing symbol %s after %i", FORMAT.NUM_END, i)
		return
	end
	
	local num = str:sub(i,j-1)
	
	i = j + 1
	
	return tonumber(num)
end
desz[FORMAT.TBL] = function(str)
	local t = {}
	while true do
		local symbol = str:sub(i,i)
		if symbol == FORMAT.TBL_END then
			i = i + 1
			break
		elseif symbol ~= FORMAT.KEY then
			err = err or string.format("Expected %s or %s at %i got %s", FORMAT.TBL_END, FORMAT.KEY, i, symbol)
			return
		end
		i = i + 1
		
		local k = deserialize(str)
		if err or (str:sub(i,i) ~= FORMAT.VAL) then
			err = err or string.format("Expected %s at %i got %s", FORMAT.VAL, i, str:sub(i,i))
			return
		end
		i = i + 1
		
		local v = deserialize(str)
		if err or (str:sub(i,i) ~= FORMAT.NEXT) then
			err = err or string.format("Expected %s at %i got %s", FORMAT.NEXT, i, str:sub(i,i))
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
		err = "Can't deserialize, expected string and got "..type("string")
		log:write(err)
		return err
	end

	i = 1
	err = nil
	local t = deserialize(str)
	if err then
		log:write("Deserialization Failed: "..err)
		return nil, err
	end
	
	return t
end

return {
	serializeAction = serializeAction,
	deserializeAction = deserializeAction
}