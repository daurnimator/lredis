local methods = {}

function methods:ping()
	local resp = self:callt("PING")
	if resp.ok then
		return resp.ok
	elseif resp.err then
		error(resp.err, 2)
	else
		error("unexpected PING reply")
	end
end

return methods
