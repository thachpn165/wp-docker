local _M = {}

function _M.run()
    local ua = ngx.var.http_user_agent or ""
    local bad_agents = { "sqlmap", "nikto", "curl", "wget", "libwww", "python", "perl", "nmap" }

    for _, agent in ipairs(bad_agents) do
        if ua:lower():find(agent) then
            ngx.log(ngx.ERR, "[WAF] Blocked User-Agent: " .. ua)
            return ngx.exit(403)
        end
    end
end

return _M
