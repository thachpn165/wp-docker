local _M = {}

function _M.run()
    local uri = ngx.var.request_uri or ""
    if uri:match("/wp%-content/uploads/.*%.php$") then
        ngx.log(ngx.ERR, "[WAF] Blocked PHP in uploads: " .. uri)
        return ngx.exit(403)
    end
end

return _M
