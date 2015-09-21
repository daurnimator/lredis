local methods = {}

function methods:ping()
	local resp = self:call("PING")
	local is_table = type(resp) == "table"
	if is_table and resp.ok then
		return resp.ok
	elseif is_table and resp.err then
		error(resp.err, 2)
	else
		error("unexpected PING response")
	end
end

return methods
