-- Builds a Swords definition from parts on an R15 body and moves it between the left-hip saya and the right hand.
-- Sword frame: the tsuka (handle) is the root part; the blade extends along its -Z axis.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Swords = require(ReplicatedStorage:WaitForChild("Shared").Swords)
local Rig = require(script.Parent.Rig)
local SwordBuilder = {}

-- Saya mouth on the left hip, tilted so the mouth faces forward-up and the tip trails back-down.
local HIP = CFrame.new(-0.95, -0.1, -0.35) * CFrame.Angles(math.rad(20), math.rad(-6), 0)
-- Handle in the right fist; the blade leaves the fist along the hand's -Z.
local GRIP = CFrame.new(0, -0.15, 0.05)

local function rgb(c) return Color3.fromRGB(c[1], c[2], c[3]) end

local function piece(sword, root, name, size, offset, color, material)
    local p = Rig.part(sword, name, size, color, root.CFrame * offset)
    p.CanQuery = false; p.CastShadow = false
    if material then p.Material = material end
    Rig.weld(root, p, offset)
    return p
end

local function tsuba(sword, root, def, z)
    local t = def.tsuba
    local color, accent = rgb(t.color), rgb(t.accent)
    local disc = piece(sword, root, "Tsuba", Vector3.new(0.08, 0.5, 0.5), CFrame.new(0, 0, z) * CFrame.Angles(0, math.rad(90), 0), color, Enum.Material.Metal)
    disc.Shape = Enum.PartType.Cylinder
    if t.shape == "wheel" then
        -- Tanjiro's black wagon-wheel guard: rim plus open spokes.
        for i = 0, 7 do
            local a = i * math.pi / 4
            piece(sword, root, "TsubaSpoke", Vector3.new(0.05, 0.2, 0.09), CFrame.new(math.cos(a) * 0.14, math.sin(a) * 0.14, z - 0.01) * CFrame.Angles(0, 0, a + math.pi / 2), accent, Enum.Material.Metal)
        end
    elseif t.shape == "flame" then
        -- Rengoku's guard: flame tongues licking outward around the rim.
        for i = 0, 9 do
            local a = i * math.pi / 5
            local tongue = piece(sword, root, "TsubaFlame", Vector3.new(0.1, 0.18, 0.06), CFrame.new(math.cos(a) * 0.27, math.sin(a) * 0.27, z) * CFrame.Angles(0, 0, a - math.pi / 2), i % 2 == 0 and color or accent, Enum.Material.Metal)
            tongue.Shape = Enum.PartType.Wedge
        end
    end
end

function SwordBuilder.build(model, swordId)
    local def = Swords.definitions[swordId]
    assert(def, "unknown sword " .. tostring(swordId))
    local lower, hand = model:WaitForChild("LowerTorso"), model:WaitForChild("RightHand")
    local sword = Instance.new("Model"); sword.Name = "Sword"; sword.Parent = model
    sword:SetAttribute("SwordId", swordId)
    local tsukaLength = def.tsuka.length
    local tsuka = Rig.part(sword, "Tsuka", Vector3.new(0.17, 0.17, tsukaLength), rgb(def.tsuka.wrap), lower.CFrame)
    tsuka.CanQuery = false; tsuka.Material = Enum.Material.Fabric
    -- Diamond gaps in the handle wrap show the ray-skin underneath.
    for i = 0, 3 do
        local z = -tsukaLength / 2 + 0.14 + i * (tsukaLength - 0.28) / 3
        for _, side in ipairs({-1, 1}) do
            piece(sword, tsuka, "TsukaDiamond", Vector3.new(0.06, 0.06, 0.02), CFrame.new(side * 0.086, 0, z) * CFrame.Angles(0, math.rad(90 * side), math.rad(45)), rgb(def.tsuka.diamond))
        end
    end
    local front = -tsukaLength / 2
    tsuba(sword, tsuka, def, front - 0.04)
    piece(sword, tsuka, "Habaki", Vector3.new(0.1, 0.24, 0.12), CFrame.new(0, 0.02, front - 0.14), Color3.fromRGB(196, 160, 86), Enum.Material.Metal)
    local b = def.blade
    local bladeCenter = front - 0.2 - b.length / 2
    local blade = piece(sword, tsuka, "Blade", Vector3.new(b.thickness, b.width, b.length), CFrame.new(0, 0, bladeCenter), rgb(b.color), Enum.Material.Metal)
    local edge = piece(sword, tsuka, "Edge", Vector3.new(b.thickness * 0.6, b.width * 0.28, b.length), CFrame.new(0, -b.width * 0.42, bladeCenter), rgb(b.edge), Enum.Material.Metal)
    blade:SetAttribute("BladePart", true); edge:SetAttribute("BladePart", true)
    if b.engraving then
        local gui = Instance.new("SurfaceGui"); gui.Face = Enum.NormalId.Right; gui.CanvasSize = Vector2.new(20, 280); gui.Parent = blade
        local text = Instance.new("TextLabel"); text.BackgroundTransparency = 1; text.Size = UDim2.fromScale(1, 0.1)
        text.Position = UDim2.fromScale(0, 0.88); text.Text = b.engraving; text.TextScaled = true
        text.TextColor3 = Color3.fromRGB(210, 214, 222); text.Parent = gui
    end
    local tip = Instance.new("Attachment"); tip.Name = "TrailTip"; tip.Position = Vector3.new(0, 0, -b.length / 2); tip.Parent = blade
    local base = Instance.new("Attachment"); base.Name = "TrailBase"; base.Position = Vector3.new(0, 0, b.length / 2 - 0.3); base.Parent = blade
    local trail = Instance.new("Trail"); trail.Name = "SwordTrail"; trail.Attachment0 = base; trail.Attachment1 = tip
    trail.Lifetime = 0.14; trail.MinLength = 0.05; trail.Enabled = false; trail.LightEmission = 0.6
    trail.Color = ColorSequence.new(Color3.fromRGB(235, 242, 250)); trail.Transparency = NumberSequence.new(0.35, 1)
    trail.Parent = blade

    local sayaOffset = HIP * CFrame.new(0, 0, def.saya.length / 2)
    local saya = Rig.part(sword, "Saya", Vector3.new(0.2, 0.26, def.saya.length), rgb(def.saya.color), lower.CFrame * sayaOffset)
    saya.CanQuery = false; saya.Material = Enum.Material.SmoothPlastic
    Rig.weld(lower, saya, sayaOffset)

    -- Sheathed, the handle sits just ahead of the saya mouth with the blade turned back into the saya.
    local sheathed = HIP * CFrame.new(0, 0, -tsukaLength / 2 - 0.12) * CFrame.Angles(0, math.pi, 0)
    sword:SetAttribute("SheathC0", sheathed)
    local grip = Rig.motor(sword, "SwordGrip", lower, tsuka, sheathed, CFrame.identity)
    SwordBuilder.setDrawn(model, false)
    return sword, grip, hand
end

function SwordBuilder.setDrawn(model, drawn)
    local sword = model:FindFirstChild("Sword")
    local grip = sword and sword:FindFirstChild("SwordGrip")
    if not grip then return end
    if drawn then
        grip.Part0 = model.RightHand; grip.C0 = GRIP
    else
        grip.Part0 = model.LowerTorso; grip.C0 = sword:GetAttribute("SheathC0")
    end
    for _, p in ipairs(sword:GetChildren()) do
        if p:GetAttribute("BladePart") then p.Transparency = drawn and 0 or 1 end
    end
    Rig.draw(model, drawn)
end

return SwordBuilder
