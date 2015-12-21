local lrc = require "lredis.cqueues"
local cqueues = require "cqueues"
-- Make a new cqueues scheduler
local cq = cqueues.new()
-- Make a thread that prints published messages to stdout
cq:wrap(function()
    local r = lrc.connect_tcp()
    r:subscribe("quit")
    r:psubscribe("b*")
    while true do
        local item = r:get_next()
        if item == nil then break end
        -- Can write `for item in r.get_next, r do` instead
        -- but that doesn't work in lua5.1/luajit
        local message_type = item[1]
        if message_type == "message" then
            print("Channel:", item[2], "Message:", item[3])
            if item[2] == "quit" then break end
        elseif message_type == "pmessage" then
            print("Channel:", item[3], "Message:", item[4])
        end
    end
end)
-- Make a second thread that publishes events on an interval
cq:wrap(function()
    local r = lrc.connect_tcp()
    for i=1, 10 do
        cqueues.sleep(0.2)
        r:call("publish", "bar", tostring(i))
    end
    r:call("publish", "quit", "")
end)
-- Start 'main' loop
assert(cq:loop())
