local _M = {}

function _M.run()
    local uri = ngx.var.request_uri or ""
    if uri:match("%.(htaccess|git|env|log|sql|bak|old|backup)$") then
        ngx.log(ngx.ERR, "[WAF] Blocked sensitive file: " .. uri)
        return ngx.exit(403)
    end
end

return _M
