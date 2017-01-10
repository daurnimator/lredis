local methods = {}
local unpack = table.unpack or unpack
local pack = table.pack or function(...) return {n=select("#", ...), ...} end

function methods:call(...)
	local resp = self:pcall(...)
	local is_table = type(resp) == "table"
	if is_table and resp.err then
		error(resp.err, 2)
	end
	return resp
end

local function handle_ok_or_err(resp, lvl)
	local is_table = type(resp) == "table"
	if is_table and resp.ok then
		return resp.ok
	else
		local err
		if is_table and resp.err then
			err = resp.err
		else
			err = "unexpected response format"
		end
		if lvl == nil then
			lvl = 2
		elseif lvl ~= 0 then
			lvl = lvl + 1
		end
		error(err, lvl)
	end
end

function methods:ping()
	local resp = self:pcall("PING")
	return handle_ok_or_err(resp)
end

function methods:client_pause(delay)
	local milliseconds = string.format("%d", math.ceil(delay*1000))
	local resp = self:pcall("client", "pause", milliseconds)
	return handle_ok_or_err(resp)
end

function methods:hmget(key, ...)
	local resp = self:call("HMGET", key, ...)
	if type(resp) == "table" then
		local ret = {}
		for i, v in ipairs(pack(...)) do
			ret[v] = resp[i]
		end
		return ret
	else
		return resp
	end
end

function methods:hmset(key, tbl)
	local data = {}
	for k,v in pairs(tbl) do
		table.insert(data, k)
		table.insert(data, v)
	end
	local resp = self:call("HMSET", key, unpack(data))
	return handle_ok_or_err(resp)
end

function methods:hgetall(key)
	local resp = self:call("HGETALL", key)
	if type(resp) == "table" then
		local ret = {}
		for i = 1, #resp, 2 do
		  ret[resp[i]] = resp[i+1]
		end
		return ret
	else
		return resp
	end
end

function methods:subscribe(...)
	self:start_subscription_mode("SUBSCRIBE", ...)
end

function methods:unsubscribe(...)
	self:start_subscription_mode("UNSUBSCRIBE", ...)
end

function methods:punsubscribe(...)
	self:start_subscription_mode("PUNSUBSCRIBE", ...)
end

function methods:psubscribe(...)
	self:start_subscription_mode("PSUBSCRIBE", ...)
end

function methods:multi()
	local resp = self:call("MULTI")
	local ret = handle_ok_or_err(resp, 2)
	self:start_transaction()
	return ret
end

function methods:exec()
	local resp = self:call("EXEC")
	self:end_transaction()
	return resp
end

function methods:discard()
	local resp = self:call("DISCARD")
	local ret = handle_ok_or_err(resp, 2)
	self:end_transaction()
	return ret
end

return methods
