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

local WRAP, BUTTON, SCAR = Color3.fromRGB(236, 234, 226), Color3.fromRGB(201, 170, 96), Color3.fromRGB(150, 52, 44)
local FACES = {Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right}

-- Outfits are drawn onto the body with SurfaceGuis instead of uploaded clothing: no asset, no Robux,
-- and sharper than stacking small parts. Uploaded Shirt/Pants IDs still win when they are configured.
local function surface(part, face, base)
    local gui = Instance.new("SurfaceGui")
    gui.Name = "Weave"; gui.Face = face; gui.Adornee = part
    gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; gui.PixelsPerStud = 64
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; gui.Parent = part
    local panel = Instance.new("Frame")
    panel.Size = UDim2.fromScale(1, 1); panel.BorderSizePixel = 0
    panel.BackgroundColor3 = base or UNIFORM; panel.BackgroundTransparency = base and 0 or 1
    panel.Parent = gui
    return panel
end

local function square(parent, x, y, width, height, color, rotation)
    local frame = Instance.new("Frame")
    frame.BorderSizePixel = 0; frame.BackgroundColor3 = color
    frame.Size = UDim2.fromScale(width, height); frame.Position = UDim2.fromScale(x, y)
    frame.Rotation = rotation or 0; frame.Parent = parent
    return frame
end

-- Ichimatsu (checkerboard) weave of the haori.
local function ichimatsu(parent, columns, rows, phase)
    for row = 0, rows - 1 do
        for column = 0, columns - 1 do
            local green = (row + column + (phase or 0)) % 2 == 0
            square(parent, column / columns, row / rows, 1 / columns, 1 / rows, green and GREEN or CHECK_BLACK)
        end
    end
end

local function haoriSleeve(part)
    for _, face in ipairs(FACES) do ichimatsu(surface(part, face, CHECK_BLACK), 3, 6) end
end

-- Part-built stand-ins for uploaded clothing/hair so an unconfigured place still reads as Tanjiro.
local function fallback(model, appearance)
    local folder = Instance.new("Folder"); folder.Name = "FallbackLook"; folder.Parent = model
    local head = model.Head
    if appearance.shirt == "" then
        for _, name in ipairs({"RightUpperArm", "RightLowerArm", "LeftUpperArm", "LeftLowerArm"}) do model[name].Color = UNIFORM end
        -- Haori: checkered back and sides, open at the front over the buttoned black uniform.
        ichimatsu(surface(model.UpperTorso, Enum.NormalId.Back, CHECK_BLACK), 6, 6)
        ichimatsu(surface(model.UpperTorso, Enum.NormalId.Left, CHECK_BLACK), 3, 6)
        ichimatsu(surface(model.UpperTorso, Enum.NormalId.Right, CHECK_BLACK), 3, 6)
        local front = surface(model.UpperTorso, Enum.NormalId.Front, UNIFORM)
        ichimatsu(square(front, 0, 0, 0.26, 1, CHECK_BLACK), 2, 6)
        ichimatsu(square(front, 0.74, 0, 0.26, 1, CHECK_BLACK), 2, 6, 1)
        for i = 0, 3 do
            local button = square(front, 0.47, 0.12 + i * 0.2, 0.06, 0.05, BUTTON)
            local round = Instance.new("UICorner"); round.CornerRadius = UDim.new(1, 0); round.Parent = button
        end
        haoriSleeve(model.RightUpperArm); haoriSleeve(model.LeftUpperArm)
        -- Obi at the waist.
        for _, face in ipairs(FACES) do square(surface(model.LowerTorso, face, UNIFORM), 0, 0.1, 1, 0.55, WRAP) end
    end
    if appearance.pants == "" then
        for _, name in ipairs({"RightUpperLeg", "LeftUpperLeg", "RightLowerLeg", "LeftLowerLeg"}) do model[name].Color = UNIFORM end
        -- Kyahan wraps from the shin down, with cross-bound ties.
        for _, name in ipairs({"RightLowerLeg", "LeftLowerLeg"}) do
            for _, face in ipairs(FACES) do
                local panel = surface(model[name], face, UNIFORM)
                square(panel, 0, 0.35, 1, 0.65, WRAP)
                for i = 0, 2 do square(panel, 0, 0.45 + i * 0.16, 1, 0.03, Color3.fromRGB(196, 192, 182), 6) end
            end
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
        -- Burn scar over the left brow.
        local brow = surface(head, Enum.NormalId.Front)
        square(brow, 0.2, 0.2, 0.2, 0.05, SCAR, -20)
        square(brow, 0.26, 0.28, 0.12, 0.04, SCAR, 25)
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
