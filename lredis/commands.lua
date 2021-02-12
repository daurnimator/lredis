local base_methods = {}

-- client methods and metatable
local client_methods = setmetatable({}, { __index = base_methods })
local client_mt = { __index = client_methods }
local new_client

-- transaction methods and metatable
local transaction_methods = setmetatable({}, { __index = base_methods })
local transaction_mt = { __index = transaction_methods }
local new_transaction

--[[
--	Base methods
--]]

function base_methods:call_no_err(...)
	local resp = self:pcall(...)
	if type(resp) ~= "table" or (not resp.ok and not resp.err) then
		resp = { data = resp }
	end
	return resp
end

function base_methods:call(...)
	local resp = self:call_no_err(...)
	if resp.err then
		error(resp.err, 2)
	end
	return (resp.ok and resp) or resp.data
end

function base_methods:call_ok_or_err(lvl, ...)
	local resp = self:call_no_err(...)

	if lvl ~= 0 then
		lvl = (lvl or 1) + 1
	end
	return resp.ok or error(resp.err or "unexpected response format", lvl)
end

function base_methods:ping()
	return self:call_ok_or_err(nil, "PING")
end

function base_methods:client_pause(delay)
	local milliseconds = string.format("%d", math.ceil(delay*1000))
	return self:call_ok_or_err(nil, "client", "pause", milliseconds)
end

function base_methods:subscribe(...)
	self:start_subscription_mode("SUBSCRIBE", ...)
end

function base_methods:unsubscribe(...)
	self:start_subscription_mode("UNSUBSCRIBE", ...)
end

function base_methods:punsubscribe(...)
	self:start_subscription_mode("PUNSUBSCRIBE", ...)
end

function base_methods:psubscribe(...)
	self:start_subscription_mode("PSUBSCRIBE", ...)
end

--[[
--	Client methods
--]]

-- execute the MULTI command and return a new transaction object if successful.
function client_methods:multi()
	if self.transaction_lock and not self:in_coroutine() then
		error("Transaction in progress and cannot wait -- not in a coroutine", 2)
	end

	while self.transaction_lock do
		self.transaction_lock:wait()
	end
	self:create_transaction_lock()

	local transaction = new_transaction(self)
	transaction:call_ok_or_err(nil, "MULTI")

	return transaction
end

function new_client(client)
	return setmetatable(client, client_mt)
end

--[[
--	Transaction methods
--]]

function transaction_methods:end_transaction()
	if self.in_transaction then
		self.client.subscribes_pending = self.subscribes_pending
		self.client.subscribed_to = self.subscribed_to

		self.in_transaction = nil
		self.client:destroy_transaction_lock()
	end
end

function transaction_methods:call(func, ...)
	if not self.in_transaction then
		error("Transaction no longer valid", 2)
	end

	local resp = self:call_no_err(func, ...)
	func = func:upper()
	if func == "EXEC" or func == "DISCARD" or resp.err then
		self:end_transaction()
	end

	if resp.err then
		error(resp.err, 2)
	end
	return (resp.ok and resp) or resp.data
end

function transaction_methods:exec()
	return self:call("EXEC")
end

function transaction_methods:discard()
	return self:call_ok_or_err(nil, "DISCARD")
end

function new_transaction(client)
	local transaction = {
		client = client,
		socket = client.socket,
		fifo = client.fifo,
		subscribes_pending = client.subscribes_pending,
		subscribed_to = client.subscribed_to,
		in_transaction = true,
	}

	return setmetatable(transaction, transaction_mt)
end

return {
	base_methods = base_methods,
	client_methods = client_methods,
	transaction_methods = transaction_methods,

	new_client = new_client,
}
