local methods = {}

local function handle_ok_or_err(resp)
	local is_table = type(resp) == "table"
	if is_table and resp.ok then
		return resp.ok
	elseif is_table and resp.err then
		error(resp.err, 2)
	else
		error("unexpected response format")
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

return methods
