local pack = table.pack or function(...) return {n = select("#", ...), ...} end

-- Encode a redis request
local function prep_request(...)
    local arg = pack(...)
    local str = {
        [0] = string.format("*%d\r\n", arg.n);
    }
    for i=1, arg.n do
        local v = arg[i]
        str[i] = string.format("$%d\r\n%s\r\n", #v, v)
    end
    return table.concat(str, nil, 0, arg.n)
end
