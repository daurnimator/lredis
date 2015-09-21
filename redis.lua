local pack = table.pack or function(...) return {n = select("#", ...), ...} end

-- Encode a redis bulk string
local function encode_bulk_string(str)
	return string.format("$%d\r\n%s\r\n", #str, str)
end

-- Encode a redis request
-- Requests are always just an array of bulk strings
local function encode_request(...)
	local arg = pack(...)
	local str = {
		[0] = string.format("*%d\r\n", arg.n);
	}
	for i=1, arg.n do
		str[i] = encode_bulk_string(arg[i])
	end
	return table.concat(str, nil, 0, arg.n)
end

-- Parse a redis request
local function read_response(file, new_status, new_error, string_null, array_null)
	local line = assert(file:read("*L"))
	assert(line:sub(-2, -1) == "\r\n", "invalid line ending")
	local status, data = line:sub(1, 1), line:sub(2, -3)
	if status == "+" then
		return new_status(data)
	elseif status == "-" then
		return new_error(data)
	elseif status == ":" then
		return assert(tonumber(data, 10), "invalid integer")
	elseif status == "$" then
		local len = assert(tonumber(data, 10), "invalid bulk string length")
		if len == -1 then
			return string_null
		elseif len > 512*1024*1024 then -- max 512 MB
			error("bulk string too large")
		else
			local str = assert(file:read(len))
			-- should be followed by CRLF
			local crlf = assert(file:read(2))
			assert(crlf == "\r\n", "invalid bulk reply")
			return str
		end
	elseif status == "*" then
		local len = assert(tonumber(data, 10), "invalid array length")
		if len == -1 then
			return array_null
		else
			local arr = {}
			for i=1, len do
				arr[i] = read_response(file, new_status, new_error, string_null, array_null)
			end
			return arr
		end
	else
		error("invalid redis status")
	end
end

-- The way lua embedded into redis encodes things:
local function error_reply(message)
	return {err = message}
end
local function status_reply(message)
	return {ok = message}
end
local string_null = false
local array_null = false
local function default_read_response(file)
	return read_response(file, error_reply, status_reply, string_null, array_null)
end

return {
	encode_bulk_string = encode_bulk_string;
	encode_request = encode_request;

	read_response = read_response;

	error_reply = error_reply;
	status_reply = status_reply;
	default_read_response = default_read_response;
}
