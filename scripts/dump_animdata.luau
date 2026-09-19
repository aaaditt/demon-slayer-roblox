-- Prints an animation set as JSON for scripts/build_keyframes.py (plain luau; no Roblox APIs).
local sets = {Tanjiro = require("../src/shared/Anims/Tanjiro")}
local function encode(v)
    local t = type(v)
    if t == "number" then return string.format("%.6g", v) end
    if t == "string" then return string.format("%q", v) end
    if t == "boolean" then return tostring(v) end
    if next(v) == nil then return "{}" end
    if #v > 0 then
        local out = {}
        for _, item in ipairs(v) do table.insert(out, encode(item)) end
        return "[" .. table.concat(out, ",") .. "]"
    end
    local keys = {}
    for key in pairs(v) do table.insert(keys, key) end
    table.sort(keys)
    local out = {}
    for _, key in ipairs(keys) do table.insert(out, string.format("%q", key) .. ":" .. encode(v[key])) end
    return "{" .. table.concat(out, ",") .. "}"
end
print(encode(sets))
