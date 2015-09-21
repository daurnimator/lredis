describe("lredis.protocol module", function()
	local protocol = require "lredis.protocol"
	local function write_to_temp_file(str)
		local file = io.tmpfile()
		assert(file:write(str))
		assert(file:flush())
		assert(file:seek("set"))
		return file
	end
	-- Docs at http://redis.io/topics/protocol
	it("composes example from docs", function()
		-- From "Sending commands to a Redis Server" section
		assert.same("*2\r\n$4\r\nLLEN\r\n$6\r\nmylist\r\n",
			protocol.encode_request{"LLEN", "mylist"})

	end)
	it("can parse examples from docs", function()
		--- From "RESP Arrays" section
		-- Empty array
		assert.same({},
			protocol.default_read_response(write_to_temp_file "*0\r\n"))
		-- an array of two RESP Bulk Strings "foo" and "bar"
		assert.same({"foo", "bar"},
			protocol.default_read_response(write_to_temp_file "*2\r\n$3\r\nfoo\r\n$3\r\nbar\r\n"))
		-- an Array of three integers
		assert.same({1, 2, 3},
			protocol.default_read_response(write_to_temp_file "*3\r\n:1\r\n:2\r\n:3\r\n"))
		-- mixed types: a list of four integers and a bulk string
		assert.same({1, 2, 3, 4, "foobar"},
			protocol.default_read_response(write_to_temp_file "*5\r\n:1\r\n:2\r\n:3\r\n:4\r\n$6\r\nfoobar\r\n"))
		-- null
		assert.same(protocol.array_null,
			protocol.default_read_response(write_to_temp_file "*-1\r\n"))
		-- array of arrays
		assert.same(
			{
				{1,2,3},
				{
					protocol.status_reply("Foo");
					protocol.error_reply("Bar");
				}
			},
			protocol.default_read_response(write_to_temp_file "*2\r\n*3\r\n:1\r\n:2\r\n:3\r\n*2\r\n+Foo\r\n-Bar\r\n")
		)

		--- From "Null elements in Arrays" section
		assert.same(
			{ "foo", protocol.string_null, "bar" },
			protocol.default_read_response(write_to_temp_file "*3\r\n$3\r\nfoo\r\n$-1\r\n$3\r\nbar\r\n")
		)
	end)
end)
