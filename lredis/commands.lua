local methods = {}

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
