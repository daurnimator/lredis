local protocol = require "lredis.protocol"
local commands = require "lredis.commands"
local cs = require "cqueues.socket"
local cc = require "cqueues.condition"
local new_fifo = require "fifo"

local pack = table.pack or function(...) return {n = select("#", ...), ...} end

local methods = setmetatable({}, {__index = commands})
local mt = {
	__index = methods;
}

local function new(host, port)
	local socket = assert(cs.connect({
		host = host or "127.0.0.1";
		port = port or "6379";
		nodelay = true;
	}))
	socket:setmode("b", "bn")
	socket:setvbuf("full", math.huge) -- 'infinite' buffering; no write locks needed
	assert(socket:connect())
	return setmetatable({
		socket = socket;
		fifo = new_fifo();
	}, mt)
end

-- call with table arg/return
function methods:callt(arg, new_status, new_error, string_null, array_null)
	local req = protocol.encode_request(arg)
	local cond = cc.new()
	assert(self.socket:write(req))
	self.fifo:push(cond)
	if self.fifo:peek() ~= cond then
		cond:wait()
	end
	local resp = protocol.read_response(self.socket, new_status, new_error, string_null, array_null)
	assert(self.fifo:pop() == cond)
	-- signal next thing in pipeline
	local next, ok = self.fifo:peek()
	if ok then
		next:signal()
	end
	return resp
end

-- call in vararg style
function methods:call(...)
	return self:callt(pack(...), protocol.status_reply, protocol.error_reply, protocol.string_null, protocol.array_null)
end

return {
	new = new;
}
