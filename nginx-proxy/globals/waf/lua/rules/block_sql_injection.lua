local _M = {}

function _M.run()
    local args = ngx.req.get_uri_args()
    for key, val in pairs(args) do
        local v = type(val) == "table" and table.concat(val, ",") or val
        if v and v:lower():match("(%W)(union|select|insert|drop|delete|script|alert)(%W)") then
            ngx.log(ngx.ERR, "[WAF] SQL Injection detected: " .. key .. "=" .. v)
            return ngx.exit(403)
        end
    end
end

return _M
