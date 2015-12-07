-- Connect to local redis
local r = require "lredis.cqueues".connect_tcp()

-- Create new scheduler
local cqueues = require "cqueues"
local cq = cqueues.new()

-- Create two coroutines
cq:wrap(function()
	-- Tell server to pause for half a second
	print("PAUSE", r:client_pause(0.5))
end)
cq:wrap(function()
	-- Sleep a small amount of time so that this thread goes second
	cqueues.sleep(0.01)
	-- Pipeline a PING command
	-- i.e. write it to the socket (and redis will start processing it)
	-- but this coroutine will be blocked from reading the reply until previous commands have fully returned
	print("PING", r:ping())
end)

-- Run scheduler until there is nothing more to do (or an error)
assert(cq:loop())
