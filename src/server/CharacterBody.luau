-- R15 fighter bodies (Tanjiro template). Returns nil when a character has no R15 kit yet or the engine
-- cannot build the body; callers then fall back to Rig.create so play never depends on this path.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Assets = require(Shared.Assets)
local Rig = require(script.Parent.Rig)
local SwordBuilder = require(script.Parent.SwordBuilder)
local CharacterBody = {}

-- Characters with a finished R15 kit: animation set name + default sword.
CharacterBody.KITS = {tanjiro = {animSet = "Tanjiro", sword = "tanjiro_black"}}

local UNIFORM = Color3.fromRGB(22, 22, 28)
local GREEN, CHECK_BLACK = Color3.fromRGB(27, 118, 86), Color3.fromRGB(18, 18, 20)

local function id(value) return value ~= "" and tonumber(value) or nil end

local function describe(appearance)
    local d = Instance.new("HumanoidDescription")
    local skin = Color3.fromRGB(table.unpack(appearance.bodyColors.skin))
    d.HeadColor = skin; d.LeftArmColor = skin; d.RightArmColor = skin
    d.TorsoColor = UNIFORM; d.LeftLegColor = UNIFORM; d.RightLegColor = UNIFORM
    d.Shirt = id(appearance.shirt) or 0
    d.Pants = id(appearance.pants) or 0
    d.Face = id(appearance.face) or 0
    d.HairAccessory = table.concat(appearance.accessories, ",")
    return d
end

local function checker(parent, anchor, name, columns, rows, cell, origin, facing)
    for r = 0, rows - 1 do
        for c = 0, columns - 1 do
            local offset = origin * CFrame.new(c * cell, -r * cell, 0) * facing
            local p = Rig.part(parent, name, Vector3.new(cell, cell, 0.04), (r + c) % 2 == 0 and GREEN or CHECK_BLACK, anchor.CFrame * offset)
            p.CanQuery = false; p.CastShadow = false
            Rig.weld(anchor, p, offset)
        end
    end
end

-- Part-built stand-ins for uploaded clothing/hair so an unconfigured place still reads as Tanjiro.
local function fallback(model, appearance)
    local folder = Instance.new("Folder"); folder.Name = "FallbackLook"; folder.Parent = model
    local upper, head = model.UpperTorso, model.Head
    local w, h, depth = upper.Size.X, upper.Size.Y, upper.Size.Z
    local cell = w / 6
    if appearance.shirt == "" then
        for _, name in ipairs({"RightUpperArm", "RightLowerArm", "LeftUpperArm", "LeftLowerArm"}) do model[name].Color = UNIFORM end
        -- Haori: checkered back and open front panels over the black uniform; checkered sleeves.
        checker(folder, upper, "HaoriBack", 6, math.floor(h / cell), cell, CFrame.new(-w / 2 + cell / 2, h / 2 - cell / 2, depth / 2 + 0.03), CFrame.identity)
        for _, side in ipairs({-1, 1}) do
            local x = side * (w / 2 - cell)
            checker(folder, upper, "HaoriFront", 2, math.floor(h / cell), cell, CFrame.new(x - cell / 2, h / 2 - cell / 2, -depth / 2 - 0.03), CFrame.identity)
            local arm = model[side == 1 and "RightUpperArm" or "LeftUpperArm"]
            local sleeve = Rig.part(folder, "HaoriSleeve", arm.Size + Vector3.new(0.06, -0.1, 0.06), GREEN, arm.CFrame)
            sleeve.CanQuery = false
            Rig.weld(arm, sleeve, CFrame.new(0, 0.05, 0))
        end
    end
    if #appearance.accessories == 0 then
        local hair = Rig.part(folder, "Hair", Vector3.new(head.Size.X * 1.08, head.Size.Y * 0.42, head.Size.Z * 1.08), Color3.fromRGB(44, 22, 22), head.CFrame)
        hair.CanQuery = false; hair.Material = Enum.Material.SmoothPlastic
        Rig.weld(head, hair, CFrame.new(0, head.Size.Y * 0.42, 0.04))
        for _, side in ipairs({-1, 1}) do
            -- Hanafuda earrings: white cards with a red sun.
            local card = Rig.part(folder, "HanafudaEarring", Vector3.new(0.05, 0.36, 0.2), Color3.fromRGB(238, 232, 214), head.CFrame)
            card.CanQuery = false
            Rig.weld(head, card, CFrame.new(side * (head.Size.X / 2 + 0.04), -0.34, -0.05))
            local sun = Rig.part(folder, "EarringSun", Vector3.new(0.06, 0.12, 0.12), Color3.fromRGB(196, 44, 40), head.CFrame)
            sun.CanQuery = false; sun.Shape = Enum.PartType.Cylinder
            Rig.weld(head, sun, CFrame.new(side * (head.Size.X / 2 + 0.05), -0.3, -0.05))
        end
    end
    if appearance.face == "" then
        local scar = Rig.part(folder, "ForeheadScar", Vector3.new(0.34, 0.12, 0.03), Color3.fromRGB(150, 52, 44), head.CFrame)
        scar.CanQuery = false
        Rig.weld(head, scar, CFrame.new(-0.18, head.Size.Y * 0.28, -head.Size.Z / 2 - 0.01) * CFrame.Angles(0, 0, math.rad(-18)))
    end
end

function CharacterBody.create(parent, position, definition, actorName, options)
    local kit = CharacterBody.KITS[definition.id]
    local appearance = Assets.characters[definition.id]
    if not kit or not appearance then return nil end
    local ok, model = pcall(function()
        return Players:CreateHumanoidModelFromDescription(describe(appearance), Enum.HumanoidRigType.R15)
    end)
    if not ok or not model then
        warn("[Wisteria] R15 body unavailable, using fallback rig: " .. tostring(model))
        return nil
    end
    model.Name = actorName or definition.name
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local root = model:FindFirstChild("HumanoidRootPart")
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    humanoid.BreakJointsOnDeath = false
    humanoid.UseJumpPower = true
    if not humanoid:FindFirstChildOfClass("Animator") then Instance.new("Animator", humanoid) end
    model.PrimaryPart = root
    model:SetAttribute("CharacterId", definition.id)
    model:SetAttribute("RigKind", "R15")
    model:SetAttribute("AnimSet", kit.animSet)
    model:SetAttribute("HasSheath", true)
    fallback(model, appearance)
    local swordId = options and options.swordVariant or kit.sword
    model:SetAttribute("SwordVariant", swordId)
    SwordBuilder.build(model, swordId)
    Rig.nameplate(model.Head, humanoid, definition.name, Color3.fromRGB(table.unpack(definition.color)))
    model:PivotTo(CFrame.new(position))
    model.Parent = parent
    return model, humanoid, root
end

return CharacterBody
