-- hooks/pre_install.lua
function PLUGIN:PreInstall(ctx)
    local version = ctx.version
    local os_type = RUNTIME.osType
    local arch_type = RUNTIME.archType

    local url = ""
    if os_type == "windows" then
        if arch_type == "amd64" or arch_type == "x86_64" then
            url = "https://ftp.gnu.org/gnu/emacs/windows/emacs-" .. version .. "/emacs-" .. version .. "-x86_64.zip"
        else
            error("Error: Windows pre-compiled binaries are only provided by GNU for amd64/x86_64 architecture.")
        end
    else
        -- Linux and Darwin (macOS)
        url = "https://ftp.gnu.org/gnu/emacs/emacs-" .. version .. ".tar.gz"
    end

    return {
        version = version,
        url = url
    }
end
