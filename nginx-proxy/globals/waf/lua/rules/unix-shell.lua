-- waf/lua/rules/unix-shell.lua

local _M = {}

-- Danh sách các biến môi trường, shell, binary và file nhạy cảm trong hệ thống Unix
local suspicious_unix_patterns = {
    "${CDPATH}", "${DIRSTACK}", "${HOME}", "${HOSTNAME}", "${IFS}", "${OLDPWD}", "${OSTYPE}", "${PATH}", "${PWD}", "${SHELL}",
    "$CDPATH", "$DIRSTACK", "$HOME", "$HOSTNAME", "$IFS", "$OLDPWD", "$OSTYPE", "$PATH", "$PWD", "$SHELL",
    "bin/", "sbin/", "dev/", "etc/",
    "proc/self", "dev/fd", "dev/null", "dev/stderr", "dev/stdin", "dev/stdout", "dev/tcp", "dev/udp", "dev/zero",
    "etc/group", "etc/master.passwd", "etc/passwd", "etc/pwd.db", "etc/shadow", "etc/shells", "etc/spwd.db",
    "capsh", "bash", "sh", "zsh", "ksh", "csh", "fish", "tcsh", "dash", "ash",
    "curl", "wget", "scp", "nc", "nmap", "netcat", "telnet", "ftp", "ssh", "sudo", "chmod", "chown", "cp", "mv", "rm",
    "vi", "vim", "nano", "emacs", "less", "cat", "more", "head", "tail",
    "python", "perl", "php", "ruby", "lua", "node", "expect", "awk", "sed", "find",
    "gzip", "gunzip", "bzip2", "xz", "zip", "unzip", "tar", "7z",
    "systemctl", "service", "init", "shutdown", "reboot"
}

function _M.run()
    local uri = ngx.var.request_uri or ""
    uri = uri:lower()

    for _, pattern in ipairs(suspicious_unix_patterns) do
        if pattern:match("^bin/") or pattern:match("^sbin/") then
            if uri:find(pattern:lower(), 1, true) then
                ngx.log(ngx.ERR, "[WAF] 🛑 Suspicious Unix binary in URI: ", pattern)
                return ngx.exit(403)
            end
        end
    end
end

return _M
