-- waf/lua/rules/php-variables.lua

local _M = {}

-- Danh sách các biến PHP đặc biệt (superglobals, deprecated, reserved,...) cần hạn chế xuất hiện trong request
local php_variables = {
    "$GLOBALS", "$_COOKIE", "$_ENV", "$_FILES", "$_GET", "$_POST", "$_REQUEST", "$_SERVER", "$_SESSION",
    "$argc", "$argv", "$http_response_header", "$php_errormsg",
    "$HTTP_COOKIE_VARS", "$HTTP_ENV_VARS", "$HTTP_GET_VARS", "$HTTP_POST_FILES",
    "$HTTP_POST_VARS", "$HTTP_RAW_POST_DATA", "$HTTP_REQUEST_VARS", "$HTTP_SERVER_VARS"
}

function _M.run()
    local uri = ngx.var.request_uri or ""
    local args = ngx.req.get_uri_args()
    local method = ngx.req.get_method()

    -- Check query string
    for key, val in pairs(args) do
        for _, variable in ipairs(php_variables) do
            if tostring(key):find(variable, 1, true) or tostring(val):find(variable, 1, true) then
                ngx.log(ngx.ERR, "[WAF] ${WARNING} PHP variable detected in query: ", variable)
                return ngx.exit(403)
            end
        end
    end

    -- Check URI directly
    for _, variable in ipairs(php_variables) do
        if uri:find(variable, 1, true) then
            ngx.log(ngx.ERR, "[WAF] ${WARNING} PHP variable detected in URI: ", variable)
            return ngx.exit(403)
        end
    end
end

return _M