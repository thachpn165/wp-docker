local _M = {}

function _M.run()
    require("rules.block_user_agents").run()
    require("rules.block_upload_malicious").run()
    require("rules.filter_request_uri").run()
    require("rules.block_php_in_uploads").run()
    require("rules.protect_wp_config").run()
    require("rules.protect_sensitive_files").run()
    require("rules.scanner-detection").run()
    require("rules.restricted-upload").run()
    require("rules.unix-shell").run()
    require("rules.php-variables").run()

end

return _M
