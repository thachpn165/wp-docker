local _M = {}

function _M.run()
    local uri = ngx.var.request_uri or ""
    if uri:match("[\"'`;]+") or uri:lower():match("(%W)(union|select|eval|base64_decode)(%W)") then
        ngx.log(ngx.ERR, "[WAF] Suspicious URI: " .. uri)
        return ngx.exit(403)
    end
end

return _M
