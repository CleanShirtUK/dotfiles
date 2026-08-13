local path = os.getenv("HOME") .. "/.config/hypr/noctalia.lua"

local file = io.open(path, "r")

if not file then
    return {
        primary = "rgb(89b4fa)",
        secondary = "rgb(89b4fa)",
        surface = "rgb(1e1e2e)",
        error = "rgb(f38ba8)",
    }
end

local content = file:read("*a")
file:close()

local function get_color(name, fallback)
    return content:match(
        "local%s+" .. name .. '%s*=%s*"([^"]+)"'
    ) or fallback
end

return {
    primary = get_color("primary", "rgb(89b4fa)"),
    secondary = get_color("secondary", "rgb(89b4fa)"),
    surface = get_color("surface", "rgb(1e1e2e)"),
    error = get_color("error", "rgb(f38ba8)"),
}
