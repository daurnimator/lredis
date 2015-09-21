describe("lredis.cqueues module", function()
	local lc = require "lredis.cqueues"
	local cs = require "cqueues.socket"
	it(":close closes the socket", function()
		local c, s = cs.pair()
		local r = lc.new(c)
		r:close()
		assert.same(nil, s:read())
		s:close()
	end)
end)
