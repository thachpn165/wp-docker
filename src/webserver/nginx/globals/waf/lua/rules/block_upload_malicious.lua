local _M = {}

function _M.run()
    local uri = ngx.var.request_uri or ""
    if uri:match("%.ph(p[0-9]?|ar|tml)$") then
        ngx.log(ngx.ERR, "[WAF] Blocked malicious upload: " .. uri)
        return ngx.exit(403)
    end
end

return _M
