local _M = {}

function _M.run()
    local uri = ngx.var.request_uri or ""
    if uri:match("wp%-config%.php") then
        ngx.log(ngx.ERR, "[WAF] Blocked wp-config.php access: " .. uri)
        return ngx.exit(403)
    end
end

return _M
