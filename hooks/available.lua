-- hooks/available.lua
function PLUGIN:Available(ctx)
    local http = require("http")

    local resp, err = http.get({
        url = "https://ftp.gnu.org/gnu/emacs/"
    })

    if err then
        error("Network error while fetching available Emacs versions: " .. err)
    end

    if resp.status_code ~= 200 then
        error("GNU FTP returned status: " .. tostring(resp.status_code))
    end

    local versions = {}
    local seen = {}

    for ver in string.gmatch(resp.body, 'href="emacs%-([%d%.]+)%.tar%.gz"') do
        if not seen[ver] then
            table.insert(versions, {
                version = ver,
                note = "Source (Unix) / Pre-compiled (Windows)"
            })
            seen[ver] = true
        end
    end

    -- Função auxiliar para quebrar "29.4.1" em {29, 4, 1}
    local function parse_version(v)
        local major, minor, patch = v:match("^(%d+)%.?(%d*)%.?(%d*)")
        return tonumber(major) or 0, tonumber(minor) or 0, tonumber(patch) or 0
    end

    -- Ordenação Semântica Decrescente (Latest primeiro)
    table.sort(versions, function(a, b)
        local a_maj, a_min, a_pat = parse_version(a.version)
        local b_maj, b_min, b_pat = parse_version(b.version)

        if a_maj ~= b_maj then
            return a_maj > b_maj
        elseif a_min ~= b_min then
            return a_min > b_min
        else
            return a_pat > b_pat
        end
    end)

    return versions
end
