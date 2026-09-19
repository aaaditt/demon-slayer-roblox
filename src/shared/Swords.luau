-- Sword definitions (pure data): built into parts by src/server/SwordBuilder.luau.
-- Sizes are studs for an R15 body (~5.2 studs tall); lengths are slightly exaggerated for readability.
-- Colours are {r, g, b}. Canon notes and verification status live in docs/RESEARCH.md.
local Swords = {}

local STEEL, EDGE = {196, 204, 212}, {236, 242, 247}
local BLACK_STEEL, BLACK_EDGE = {30, 31, 36}, {150, 156, 166}

Swords.definitions = {
    -- Urokodaki's plain sword, used through training and Final Selection.
    urokodaki_steel = {
        id = "urokodaki_steel",
        blade = {length = 2.8, width = 0.2, thickness = 0.06, color = STEEL, edge = EDGE},
        tsuba = {shape = "round", color = {58, 50, 44}, accent = {92, 80, 66}},
        tsuka = {length = 0.9, wrap = {40, 36, 52}, diamond = {226, 220, 204}},
        saya = {length = 3.0, color = {42, 30, 26}},
    },
    -- Tanjiro's own Nichirin blade: turned black when he first drew it.
    tanjiro_black = {
        id = "tanjiro_black",
        blade = {length = 2.8, width = 0.2, thickness = 0.06, color = BLACK_STEEL, edge = BLACK_EDGE},
        tsuba = {shape = "wheel", color = {22, 22, 26}, accent = {48, 48, 54}},
        tsuka = {length = 0.9, wrap = {20, 20, 24}, diamond = {150, 36, 40}},
        saya = {length = 3.0, color = {18, 18, 22}},
    },
    -- Yoriichi's ~300-year-old blade restored by Haganezuka after the Swordsmith Village,
    -- delivered fitted with Rengoku's flame tsuba.
    tanjiro_yoriichi = {
        id = "tanjiro_yoriichi",
        blade = {length = 2.9, width = 0.21, thickness = 0.06, color = BLACK_STEEL, edge = BLACK_EDGE, engraving = "滅"},
        tsuba = {shape = "flame", color = {214, 72, 34}, accent = {252, 176, 58}},
        tsuka = {length = 0.9, wrap = {20, 20, 24}, diamond = {150, 36, 40}},
        saya = {length = 3.1, color = {18, 18, 22}},
    },
}

-- Chapter indices from data/catalog.json: 3 = Final Selection, 13-14 = Swordsmith Village.
Swords.TanjiroThresholds = {black = 4, yoriichi = 15}

function Swords.variantFor(characterId, chapter)
    if characterId ~= "tanjiro" then return nil end
    chapter = chapter or 1
    if chapter >= Swords.TanjiroThresholds.yoriichi then return "tanjiro_yoriichi" end
    if chapter >= Swords.TanjiroThresholds.black then return "tanjiro_black" end
    return "urokodaki_steel"
end

return Swords
