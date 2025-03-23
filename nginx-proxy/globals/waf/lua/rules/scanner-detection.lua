-- waf/lua/rules/scanner-detection.lua

local _M = {}

-- Danh sách các User-Agent thường thấy ở scanner (dựa theo OWASP CRS)
-- Tối ưu để sử dụng với header REQUEST_HEADERS:User-Agent
local known_scanners = {
    "acunetix",
    "netsparker",
    "nikto",
    "nmap",
    "sqlmap",
    "nessus",
    "whatweb",
    "w3af",
    "arachni",
    "masscan",
    "zaproxy",
    "httprecon",
    "httprint",
    "metasploit",
    "atscan",
    "jaeles",
    "shodan",
    "netcraft",
    "qualys",
    "openvas"
}

function _M.run()
    local ua = ngx.var.http_user_agent
    if not ua then return end

    ua = ua:lower()
    for _, pattern in ipairs(known_scanners) do
        if ua:find(pattern, 1, true) then
            ngx.log(ngx.ERR, "[WAF] 🚨 Detected scanner User-Agent: ", ua)
            return ngx.exit(403)
        end
    end
end

return _M
