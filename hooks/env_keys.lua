-- hooks/env_keys.lua
function PLUGIN:EnvKeys(ctx)
    -- O gancho EnvKeys expõe o diretório de instalação primariamente como ctx.path
    local install_path = ctx.path or ctx.rootPath

    if not install_path then
        error("Error: Could not determine Emacs installation path in EnvKeys.")
    end

    return {
        {
            key = "PATH",
            value = install_path .. "/bin"
        }
    }
end
