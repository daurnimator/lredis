-- Documentation on the redis protocol found at http://redis.io/topics/protocol


-- Encode a redis bulk string
local function encode_bulk_string(str)
	assert(type(str) == "string")
	return string.format("$%d\r\n%s\r\n", #str, str)
end

-- Encode a redis request
-- Requests are always just an array of bulk strings
local function encode_request(arg)
	local n = arg.n or #arg
	if n == 0 then
		return nil, "need at least one argument"
	end

	local str = {
		[0] = string.format("*%d\r\n", n);
	}
	for i=1, n do
		str[i] = encode_bulk_string(arg[i])
	end
	return table.concat(str, nil, 0, n)
end

-- Encode a redis inline command
-- space separated
local function encode_inline(arg)
	local n = arg.n or #arg
	assert(n > 0, "need at least one argument")
	-- inline commands can't start with "*"
	assert(arg[1]:sub(1,1) ~= "*", "invalid command for inline command")
	-- ensure the arguments do not contain a space character or newline
	for i=1, n do
		assert(arg[i]:match("^[^\r\n ]*$"), "invalid string for inline command")
	end
	arg[n+1] = "\r\n"
	return table.concat(arg, " ", 1, n+1)
end

-- Encode and send a redis command.
local function send_command(file, arg)
	local req, err_code = encode_request(arg)
	if not req then
		return nil, err_code
	end
	req, err_code = file:write(req)
	if not req then
		return nil, err_code
	end
	req, err_code = file:flush()
	if not req then
		return nil, err_code
	end

	return true
end

-- Parse a redis response
local function read_response(file, new_status, new_error, string_null, array_null)
	local line, err_code = file:read("*l")
	if not line then
		return nil, err_code or "EOF reached"
	elseif line:sub(-1, -1) ~= "\r" then
		return nil, "invalid line ending"
	end

	local status, data = line:sub(1, 1), line:sub(2, -2)
	if status == "+" then
		return new_status(data)
	elseif status == "-" then
		return new_error(data)
	elseif status == ":" then
		local n = tonumber(data, 10)
		if n then
			return n
		else
			return nil, "invalid integer"
		end
	elseif status == "$" then
		local len = tonumber(data, 10)
		if not len then
			return nil, "invalid bulk string length"
		elseif len == -1 then
			return string_null
		elseif len > 512*1024*1024 then -- max 512 MB
			return nil, "bulk string too large"
		else
			local str, err_code = file:read(len)
			if not str then
				return str, err_code
			end
			-- should be followed by CRLF
			local crlf, err_code = file:read(2)
			if not crlf then
				return nil, err_code
			elseif crlf ~= "\r\n" then
				return nil, "invalid bulk reply"
			end
			return str
		end
	elseif status == "*" then
		local len = tonumber(data, 10)
		if not len then
			return nil, "invalid array length"
		elseif len == -1 then
			return array_null
		else
			local arr, null = {}, {}
			for i=1, len do
				local resp, err_code = read_response(file, new_status, new_error, null, array_null)
				if not resp then
					return nil, err_code
				end
				arr[i] = (resp ~= null) and resp or string_null
			end
			return arr
		end
	else
		return nil, "invalid redis status"
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
	return read_response(file, status_reply, error_reply, string_null, array_null)
end

return {
	encode_bulk_string = encode_bulk_string;
	encode_request = encode_request;
	encode_inline = encode_inline;

	send_command = send_command;
	read_response = read_response;

	error_reply = error_reply;
	status_reply = status_reply;
	string_null = string_null;
	array_null = array_null;
	default_read_response = default_read_response;
}
