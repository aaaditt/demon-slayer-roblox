local Content = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Content"))
local Rig = {}

function Rig.draw(model, drawn)
    model:SetAttribute("WeaponDrawn", drawn)
    model:SetAttribute("WeaponChanged", workspace:GetServerTimeNow())
    -- Exactly one sword joint holds the katana: the hip mount when sheathed, the right hand when drawn.
    local hip = model:FindFirstChild("LowerTorso") and model.LowerTorso:FindFirstChild("SwordHip")
    local hand = model:FindFirstChild("RightHand") and model.RightHand:FindFirstChild("SwordHand")
    if hip and hand then hip.Enabled = not drawn; hand.Enabled = drawn end
end

local function part(parent, name, size, color, cf, collide)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.Color = color
    p.CFrame = cf or CFrame.identity
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.CanCollide = collide == true
    p.CanTouch = false
    p.Massless = true
    p.Parent = parent
    return p
end

local function weld(a, b, offset)
    b.CFrame = a.CFrame * offset
    local w = Instance.new("WeldConstraint")
    w.Part0 = a; w.Part1 = b; w.Parent = b
end

local function motor(parent, name, a, b, c0, c1)
    local m = Instance.new("Motor6D")
    m.Name = name; m.Part0 = a; m.Part1 = b
    m.C0 = c0; m.C1 = c1; m.Parent = parent
    return m
end

-- Cosmetic offsets are authored in the classic frame: origin at the old 2x2 torso centre, or the old 2-stud arm centre.
local TORSO_SPLIT, UPPER_Y, LOWER_Y, HAND_Y = -0.4, 0.3, -0.7, -0.825

-- Returns the torso part covering a classic-frame offset and the offset converted into that part's space.
function Rig.torsoFrame(model, offset)
    local lower = offset.Position.Y < TORSO_SPLIT
    return lower and model.LowerTorso or model.UpperTorso, CFrame.new(0, -(lower and LOWER_Y or UPPER_Y), 0)*offset
end

local function torsoWeld(model, item, offset)
    local body, converted = Rig.torsoFrame(model, offset)
    weld(body, item, converted)
end

local function handWeld(hand, item, offset)
    weld(hand, item, CFrame.new(0, -HAND_Y, 0)*offset)
end

local function paintTorso(model, color)
    model.UpperTorso.Color = color; model.LowerTorso.Color = color
end

local function rgb(value) return Color3.fromRGB(value[1], value[2], value[3]) end

-- Classic Weld with a fixed C0. WeldConstraint re-captures its offset when a part is moved directly, which
-- desynchronises sword pieces whenever the SwordHip/SwordHand joints relocate the tsuka.
local function rigid(a, b, offset)
    b.CFrame = a.CFrame*offset
    local w = Instance.new("Weld")
    w.Part0 = a; w.Part1 = b; w.C0 = offset; w.Parent = b
end

-- Sword space: origin at the tsuba centre, blade along -Z, edge toward -Y. The right hand grips at GRIP_Z,
-- the scabbard mouth sits at MOUTH_Z and the tsuka part (Part1 of both sword joints) is centred at TSUKA_Z.
local GRIP_Z, MOUTH_Z, TSUKA_Z, BLADE_Z = 0.3, -0.2, 0.57, -0.12
local MOUTH = Vector3.new(-1.15, 0.05, -0.45)
-- Worn on the left hip in LowerTorso space: edge up, tip angled back and down.
local SHEATH = CFrame.lookAt(MOUTH, MOUTH+Vector3.new(-0.08, -0.45, 1))*CFrame.Angles(0, 0, math.pi)
local WORN = SHEATH*CFrame.new(0, 0, -MOUTH_Z)

-- The catalog preset plus a character's sourced overrides; the weapon family adjusts the silhouette.
function Rig.swordSpec(definition)
    local override = definition.sword or {}
    local spec = table.clone(Content.swordPresets[override.preset or "nichirin_base"])
    for key, value in pairs(override) do spec[key] = value end
    if definition.weapon == "needle" then spec.curve = 0; spec.bladeDepth = 0.1
    elseif definition.weapon == "serpent" then spec.curve = 0.09 end
    return spec
end

-- Walks three segments bent by the sori (tip curving toward the spine); returns the frame at the far end.
local function curvedChain(start, length, curve, visit)
    local segment = length/3
    local frame = CFrame.new(0, 0, start)
    for i = 1, 3 do
        frame *= CFrame.Angles(curve, 0, 0)
        visit(i, frame*CFrame.new(0, 0, -segment/2), segment)
        frame *= CFrame.new(0, 0, -segment)
    end
    return frame
end

local function buildTsuba(fit, spec)
    local color, shape, metal = rgb(spec.tsubaColor), spec.tsuba, Enum.Material.Metal
    -- Overlapping plates get different thicknesses so their faces never share a plane (no z-fighting).
    local function disc(name, diameter, thickness, offset)
        local p = fit(name, Vector3.new(thickness, diameter, diameter), color, offset*CFrame.Angles(0, math.pi/2, 0), metal)
        p.Shape = Enum.PartType.Cylinder
        return p
    end
    if shape == "square" then fit("Tsuba", Vector3.new(0.56, 0.56, 0.08), color, CFrame.identity, metal)
    elseif shape == "bar" then fit("Tsuba", Vector3.new(0.7, 0.2, 0.08), color, CFrame.identity, metal)
    elseif shape == "hex" then
        for k = 0, 2 do fit("Tsuba", Vector3.new(0.32, 0.56, 0.08+k*0.006), color, CFrame.Angles(0, 0, k*math.pi/3), metal) end
    elseif shape == "wheel" then
        disc("Tsuba", 0.5, 0.08, CFrame.identity)
        fit("TsubaPoints", Vector3.new(0.44, 0.44, 0.09), color, CFrame.Angles(0, 0, math.pi/4), metal)
    elseif shape == "flame" then
        disc("Tsuba", 0.46, 0.09, CFrame.identity)
        for k = 0, 5 do
            fit("TsubaFlame", Vector3.new(0.13, 0.26, 0.07), k%2 == 0 and color or Color3.fromRGB(246, 170, 64),
                CFrame.Angles(0, 0, k*math.pi/3)*CFrame.new(0, 0.27, 0)*CFrame.Angles(0, 0, -0.45), metal)
        end
    elseif shape == "flower" then
        disc("Tsuba", 0.24, 0.1, CFrame.identity)
        for k = 0, 3 do disc("TsubaPetal", 0.3, 0.08+k*0.004, CFrame.Angles(0, 0, k*math.pi/2+math.pi/4)*CFrame.new(0, 0.17, 0)) end
    else disc("Tsuba", 0.62, 0.08, CFrame.identity) end
end

-- Builds the katana (Model "Katana") and its scabbard (Model "Saya"); sheathed, the blade rests inside the saya.
function Rig.buildSword(model, definition)
    local spec = Rig.swordSpec(definition)
    local lower, hand = model.LowerTorso, model.RightHand
    local katana = Instance.new("Model"); katana.Name = "Katana"; katana.Parent = model
    local saya = Instance.new("Model"); saya.Name = "Saya"; saya.Parent = model
    local function piece(parent, name, size, color, material, class)
        local p = Instance.new(class or "Part")
        p.Name = name; p.Size = size; p.Color = color; p.Material = material or Enum.Material.SmoothPlastic
        p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
        p.CanCollide = false; p.CanTouch = false; p.CanQuery = false; p.Massless = true
        p.Parent = parent
        return p
    end
    local tsuka = piece(katana, "Tsuka", Vector3.new(0.2, 0.26, 0.9), Color3.fromRGB(226, 222, 210))
    tsuka.CFrame = lower.CFrame*WORN*CFrame.new(0, 0, TSUKA_Z)
    local function fit(name, size, color, offset, material, class)
        local p = piece(katana, name, size, color, material, class)
        rigid(tsuka, p, CFrame.new(0, 0, -TSUKA_Z)*offset)
        return p
    end
    local fitting, dark = rgb(spec.fittingColor), Color3.fromRGB(38, 36, 34)
    for i = 0, 4 do fit("TsukaWrap", Vector3.new(0.22, 0.17, 0.17), rgb(spec.wrapColor), CFrame.new(0, 0, 0.22+i*0.18)*CFrame.Angles(math.pi/4, 0, 0)) end
    for _, x in ipairs({-1, 1}) do fit("Menuki", Vector3.new(0.05, 0.09, 0.2), fitting, CFrame.new(x*0.115, 0, 0.55)) end
    fit("Kashira", Vector3.new(0.24, 0.3, 0.1), dark, CFrame.new(0, 0, 1.07), Enum.Material.Metal)
    fit("Fuchi", Vector3.new(0.24, 0.3, 0.08), dark, CFrame.new(0, 0, 0.08), Enum.Material.Metal)
    fit("Habaki", Vector3.new(0.12, 0.26, 0.12), fitting, CFrame.new(0, 0, -0.1), Enum.Material.Metal)
    buildTsuba(fit, spec)
    local depth = spec.bladeDepth
    local tip = curvedChain(BLADE_Z, spec.length, spec.curve, function(i, centre, segment)
        -- Spine in the nichirin colour over a lighter hamon edge strip.
        local spine = fit(i == 1 and "Blade" or "Blade"..i, Vector3.new(0.08, depth*0.6, segment+0.02), rgb(spec.bladeColor), centre*CFrame.new(0, depth*0.2, 0), Enum.Material.Metal)
        spine.Reflectance = 0.15
        fit("Hamon"..i, Vector3.new(0.06, depth*0.4, segment+0.02), rgb(spec.edgeColor), centre*CFrame.new(0, -depth*0.3, 0))
    end)
    -- A wedge rolled 180 degrees: the kissaki point meets the spine line and the edge sweeps up to it.
    local kissaki = fit("Kissaki", Vector3.new(0.07, depth, 0.32), rgb(spec.edgeColor), tip*CFrame.new(0, 0, -0.16)*CFrame.Angles(0, 0, math.pi), Enum.Material.Metal, "WedgePart")
    local blade = katana.Blade
    local base = Instance.new("Attachment"); base.Name = "TrailBase"; base.Position = Vector3.new(0, 0, blade.Size.Z/2); base.Parent = blade
    local point = Instance.new("Attachment"); point.Name = "TrailTip"; point.Parent = kissaki
    local trail = Instance.new("Trail"); trail.Name = "SwordTrail"; trail.Attachment0 = base; trail.Attachment1 = point
    trail.Lifetime = 0.13; trail.MinLength = 0.1; trail.Enabled = false
    trail.Color = ColorSequence.new(rgb(spec.bladeColor):Lerp(Color3.new(1, 1, 1), 0.35))
    trail.Transparency = NumberSequence.new(0.45, 1); trail.Parent = blade

    local function sheathPiece(name, size, color, offset, material)
        local p = piece(saya, name, size, color, material)
        rigid(lower, p, WORN*offset)
        return p
    end
    -- Covers the blade (from BLADE_Z) plus the 0.32 kissaki and a small kojiri margin.
    local sayaEnd = curvedChain(MOUTH_Z+0.05, spec.length+0.38, spec.curve, function(i, centre, segment)
        sheathPiece("SayaBody"..i, Vector3.new(0.2, depth+0.12, segment+0.03), rgb(spec.sayaColor), centre)
    end)
    sheathPiece("Koiguchi", Vector3.new(0.24, depth+0.16, 0.08), dark, CFrame.new(0, 0, MOUTH_Z+0.03))
    sheathPiece("Kojiri", Vector3.new(0.22, depth+0.14, 0.08), fitting, sayaEnd*CFrame.new(0, 0, 0.02), Enum.Material.Metal)
    sheathPiece("Kurikata", Vector3.new(0.08, 0.12, 0.14), dark, CFrame.new(-0.13, 0, MOUTH_Z-0.45))
    sheathPiece("Sageo", Vector3.new(0.05, 0.05, 0.9), rgb(spec.cordColor), CFrame.new(-0.14, 0.04, MOUTH_Z-0.95))

    local hip = motor(lower, "SwordHip", lower, tsuka, SHEATH, CFrame.new(0, 0, MOUTH_Z-TSUKA_Z))
    local grip = motor(hand, "SwordHand", hand, tsuka, CFrame.new(0, -0.05, 0), CFrame.new(0, 0, GRIP_Z-TSUKA_Z))
    hip.Enabled = true; grip.Enabled = false
    model:SetAttribute("HasSheath", true)
    return spec
end

function Rig.swordVisible(model, visible)
    for _, name in ipairs({"Katana", "Saya"}) do
        local group = model:FindFirstChild(name)
        if group then
            for _, item in ipairs(group:GetDescendants()) do
                if item:IsA("BasePart") then item.Transparency = visible and 0 or 1 end
            end
        end
    end
end

function Rig.tintBlade(model, color)
    local katana = model:FindFirstChild("Katana")
    if not katana then return end
    for _, name in ipairs({"Blade", "Blade2", "Blade3"}) do
        local item = katana:FindFirstChild(name)
        if item then item.Color = color end
    end
end

function Rig.storyWeapon(model, kind)
    local previous = model:FindFirstChild("StoryWeapon")
    if previous then previous:Destroy() end
    model:SetAttribute("HasSheath", false)
    Rig.swordVisible(model, false)
    if not kind then return end
    local weapon = Instance.new("Model"); weapon.Name = "StoryWeapon"; weapon.Parent = model
    local hand = model.RightHand
    local function piece(name, size, offset, color)
        local item = part(weapon, name, size, color)
        handWeld(hand, item, offset)
    end
    local brown = Color3.fromRGB(163, 119, 71)
    if kind == "axe" then
        piece("AxeHandle", Vector3.new(0.22,0.22,2.8), CFrame.new(0,-0.9,-1), brown)
        piece("AxeHead", Vector3.new(1.15,0.18,0.8), CFrame.new(0.35,-0.9,-2.3), Color3.fromRGB(147,157,158))
    else
        piece("PracticeBlade", Vector3.new(0.23,0.2,4.1), CFrame.new(0,-0.9,-1.5), brown)
        piece("WoodGuard", Vector3.new(0.6,0.5,0.14), CFrame.new(0,-0.9,-0.6), Color3.fromRGB(107,76,45))
    end
end

function Rig.storySword(model, black)
    local old=model:FindFirstChild("StoryWeapon");if old then old:Destroy() end
    Rig.swordVisible(model,true)
    -- Plain steel before the colour change; afterwards the character's nichirin colour.
    local spec=Rig.swordSpec(Content.characters[model:GetAttribute("CharacterId")] or {})
    Rig.tintBlade(model,rgb(black and spec.bladeColor or Content.swordPresets.nichirin_base.bladeColor))
    model:SetAttribute("HasSheath",true);Rig.draw(model,black==true)
end

function Rig.swampBody(model, index)
    if model:FindFirstChild("SwampHorn") then return end
    paintTorso(model,Color3.fromRGB(49,58,64))
    for i=1,math.clamp(index,1,3) do
        local horn=part(model,"SwampHorn",Vector3.new(0.24,0.75,0.25),Color3.fromRGB(219,214,177))
        weld(model.Head,horn,CFrame.new((i-(index+1)/2)*0.5,0.65,-0.2)*CFrame.Angles(-0.3,0,0))
    end
end

function Rig.foxMask(model, enabled)
    local old=model:FindFirstChild("ProtectiveMask");if old then old:Destroy() end
    if not enabled then return end
    local mask=part(model,"ProtectiveMask",Vector3.new(1,1.2,0.3),Color3.fromRGB(231,228,214))
    weld(model.Head,mask,CFrame.new(0.8,0.35,-0.6)*CFrame.Angles(0,0,-0.3))
end

function Rig.uniform(model)
    if model:FindFirstChild("CorpsBelt") then return end
    paintTorso(model,Color3.fromRGB(29,33,40))
    local belt=part(model,"CorpsBelt",Vector3.new(2.06,0.2,1.08),Color3.fromRGB(226,220,204))
    torsoWeld(model,belt,CFrame.new(0,-0.8,0))
    for i=1,3 do
        local button=part(model,"UniformButton",Vector3.new(0.12,0.12,0.08),Color3.fromRGB(198,170,91))
        torsoWeld(model,button,CFrame.new(0,0.6-i*0.3,-0.56))
    end
end

function Rig.crow(model)
    if model:FindFirstChild("MessengerCrow") then return end
    local crow=Instance.new("Model");crow.Name="MessengerCrow";crow.Parent=model
    local body=part(crow,"Body",Vector3.new(0.65,0.65,1.2),Color3.fromRGB(29,31,40))
    torsoWeld(model,body,CFrame.new(-1.3,1.15,0.05))
    local head=part(crow,"Head",Vector3.new(0.55,0.55,0.55),body.Color)
    weld(body,head,CFrame.new(0,0.25,-0.5))
    local beak=part(crow,"Beak",Vector3.new(0.18,0.16,0.5),Color3.fromRGB(111,101,70))
    weld(head,beak,CFrame.new(0,-0.05,-0.45))
    for _,side in ipairs({-1,1}) do
        local wing=part(crow,"Wing",Vector3.new(0.6,0.1,0.95),body.Color)
        motor(body,side<0 and "CrowLeft" or "CrowRight",body,wing,CFrame.new(side*0.5,0,0),CFrame.identity)
    end
end

function Rig.handDemon(model)
    local torso=model.UpperTorso
    for i=1,6 do
        local side=i%2==0 and 1 or -1
        local row=math.floor((i-1)/2)
        local arm=part(model,"ExtraArm"..i,Vector3.new(0.75,2,0.75),Color3.fromRGB(117,139,105))
        motor(torso,"HandArm"..i,torso,arm,CFrame.new(side*(1.3+row*0.28),0.7-row*0.7-UPPER_Y,0.1)*CFrame.Angles(-0.6,0,side*(0.45+row*0.22)),CFrame.new(0,0.8,0))
        local palm=part(model,"ExtraPalm"..i,Vector3.new(1.1,0.55,0.95),arm.Color)
        weld(arm,palm,CFrame.new(0,-1.1,-0.1))
        for finger=-1,1 do
            local digit=part(model,"Finger",Vector3.new(0.22,0.65,0.25),arm.Color)
            weld(palm,digit,CFrame.new(finger*0.32,-0.5,-0.25))
        end
    end
    model:SetAttribute("HandDemon",true)
end

function Rig.create(parent, position, definition, actorName)
    local model = Instance.new("Model")
    model.Name = actorName or definition.name
    model:SetAttribute("CharacterId", definition.id)
    local skin = Color3.fromRGB(table.unpack(definition.skinColor or {235,197,171}))
    local dark = Color3.fromRGB(27, 30, 43)
    local accent = Color3.fromRGB(table.unpack(definition.outfitColor or definition.color))
    local origin = CFrame.new(position)
    local root = part(model, "HumanoidRootPart", Vector3.new(2, 2, 1), dark, origin)
    root.Transparency = 1; root.Massless = false
    -- Blocky R15: same 5-stud silhouette as the classic rig, split at the waist, elbows, wrists, knees and ankles.
    local lower = part(model, "LowerTorso", Vector3.new(2, 0.6, 1), dark, origin * CFrame.new(0, LOWER_Y, 0), true)
    local upper = part(model, "UpperTorso", Vector3.new(2, 1.4, 1), dark, origin * CFrame.new(0, UPPER_Y, 0), true)
    local head = part(model, "Head", Vector3.new(2, 1, 1), skin, origin * CFrame.new(0, 1.5, 0))
    motor(root, "Root", root, lower, CFrame.new(0, LOWER_Y, 0), CFrame.identity)
    motor(lower, "Waist", lower, upper, CFrame.new(0, TORSO_SPLIT-LOWER_Y, 0), CFrame.new(0, TORSO_SPLIT-UPPER_Y, 0))
    motor(upper, "Neck", upper, head, CFrame.new(0, 1-UPPER_Y, 0), CFrame.new(0, -0.5, 0))
    local hands = {}
    for _, side in ipairs({"Right", "Left"}) do
        local x = side == "Right" and 1 or -1
        -- Arm (classic-frame y): shoulder pivot 0.6, elbow 0, wrist -0.65, hand bottom -1.
        local upperArm = part(model, side.."UpperArm", Vector3.new(1, 1, 1), accent, origin * CFrame.new(1.5*x, 0.5, 0))
        local lowerArm = part(model, side.."LowerArm", Vector3.new(1, 0.65, 1), accent, origin * CFrame.new(1.5*x, -0.325, 0))
        local hand = part(model, side.."Hand", Vector3.new(0.9, 0.35, 0.9), skin, origin * CFrame.new(1.5*x, HAND_Y, 0))
        motor(upper, side.."Shoulder", upper, upperArm, CFrame.new(1.5*x, 0.6-UPPER_Y, 0), CFrame.new(0, 0.1, 0))
        motor(upperArm, side.."Elbow", upperArm, lowerArm, CFrame.new(0, -0.5, 0), CFrame.new(0, 0.325, 0))
        motor(lowerArm, side.."Wrist", lowerArm, hand, CFrame.new(0, -0.325, 0), CFrame.new(0, 0.175, 0))
        -- Leg: hip pivot -1.1, knee -2, ankle -2.8, sole -3 (HipHeight 2 below the root's base).
        local upperLeg = part(model, side.."UpperLeg", Vector3.new(1, 1, 1), dark, origin * CFrame.new(0.5*x, -1.5, 0))
        local lowerLeg = part(model, side.."LowerLeg", Vector3.new(1, 0.8, 1), dark, origin * CFrame.new(0.5*x, -2.4, 0))
        local foot = part(model, side.."Foot", Vector3.new(1, 0.2, 1.2), Color3.fromRGB(58, 52, 48), origin * CFrame.new(0.5*x, -2.9, -0.1))
        motor(lower, side.."Hip", lower, upperLeg, CFrame.new(0.5*x, -1.1-LOWER_Y, 0), CFrame.new(0, 0.4, 0))
        motor(upperLeg, side.."Knee", upperLeg, lowerLeg, CFrame.new(0, -0.5, 0), CFrame.new(0, 0.4, 0))
        motor(lowerLeg, side.."Ankle", lowerLeg, foot, CFrame.new(0, -0.4, 0), CFrame.new(0, 0.1, 0.1))
        hands[side] = hand
    end
    local ra, la = hands.Right, hands.Left
    local humanoid = Instance.new("Humanoid")
    humanoid.RigType = Enum.HumanoidRigType.R15
    humanoid.AutomaticScalingEnabled = false
    humanoid.HipHeight = 2
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    humanoid.BreakJointsOnDeath = false
    humanoid.RequiresNeck = true
    humanoid.UseJumpPower = true
    humanoid.Parent = model
    Instance.new("Animator", humanoid)
    model.PrimaryPart = root

    local hairColor = (definition.id == "rengoku" or definition.id == "zenitsu") and Color3.fromRGB(246, 182, 64)
        or (definition.id == "gyutaro" or definition.id == "mitsuri") and accent or Color3.fromRGB(32, 27, 41)
    local hair = part(model, "Hair", Vector3.new(2.08, 0.55, 1.08), hairColor)
    weld(head, hair, CFrame.new(0, 0.45, 0))
    for side = -1, 1, 2 do
        local eye = part(model, "Eye", Vector3.new(0.16, 0.15, 0.04), accent)
        weld(head, eye, CFrame.new(side * 0.4, 0, -0.52))
        local coat = part(model, "HaoriPanel", Vector3.new(0.95, 2.5, 0.12), accent)
        torsoWeld(model, coat, CFrame.new(side * 0.54, -0.15, 0.6) * CFrame.Angles(0, 0, side * 0.05))
    end
    local belt = part(model, "Belt", Vector3.new(2.04, 0.2, 1.08), Color3.fromRGB(232, 220, 205))
    torsoWeld(model, belt, CFrame.new(0, -0.55, 0))
    if definition.id == "tanjiro" then
        for row = 0, 2 do
            for col = 0, 3 do
                if (row + col) % 2 == 0 then
                    local check = part(model, "Check", Vector3.new(0.48, 0.65, 0.05), dark)
                    torsoWeld(model, check, CFrame.new(-0.75 + col * 0.5, 0.65 - row * 0.68, 0.7))
                    local front = part(model, "HaoriCheck", Vector3.new(0.48, 0.65, 0.05), (col+row)%4==0 and dark or accent)
                    torsoWeld(model, front, CFrame.new(-0.75+col*0.5,0.65-row*0.68,-0.53))
                end
            end
        end
        for _,side in ipairs({-1,1}) do
            local earring=part(model,"HanafudaEarring",Vector3.new(0.15,0.45,0.09),Color3.fromRGB(235,225,207))
            weld(head,earring,CFrame.new(side*0.95,-0.45,-0.4))
        end
    elseif definition.id == "nezuko" then
        local bamboo = part(model, "Bamboo", Vector3.new(1.2, 0.22, 0.22), Color3.fromRGB(112, 153, 93))
        weld(head, bamboo, CFrame.new(0, -0.3, -0.6))
    elseif definition.id == "inosuke" then
        local mask = part(model, "BoarMask", Vector3.new(2.15, 1.3, 1.15), Color3.fromRGB(163, 148, 139))
        weld(head, mask, CFrame.new(0, 0.05, -0.15))
        local snout = part(model, "Snout", Vector3.new(0.75, 0.48, 0.45), Color3.fromRGB(226, 174, 169))
        weld(head, snout, CFrame.new(0, -0.15, -0.88))
    elseif definition.id == "muzan" then
        local hat = part(model, "Hat", Vector3.new(2.6, 0.15, 1.9), Color3.fromRGB(237, 231, 216))
        weld(head, hat, CFrame.new(0, 0.65, 0))
        local crown = part(model, "HatCrown", Vector3.new(1.7, 0.5, 1.2), hat.Color)
        weld(head, crown, CFrame.new(0, 0.95, 0))
    elseif definition.id == "haganezuka" then
        local hat=part(model,"SmithHat",Vector3.new(3.1,0.3,2.8),Color3.fromRGB(159,132,85));weld(head,hat,CFrame.new(0,0.9,0))
        local mask=part(model,"SmithMask",Vector3.new(1.7,1.1,0.25),Color3.fromRGB(216,168,137));weld(head,mask,CFrame.new(0,0,-0.65))
        local mouth=part(model,"MaskMouth",Vector3.new(0.4,0.3,0.35),Color3.fromRGB(158,96,80));weld(head,mouth,CFrame.new(0.3,-0.25,-0.9))
    elseif definition.id == "urokodaki" then
        local mask=part(model,"TenguMask",Vector3.new(1.75,1.05,0.25),Color3.fromRGB(153,56,43))
        weld(head,mask,CFrame.new(0,-0.05,-0.6))
        local nose=part(model,"TenguNose",Vector3.new(0.25,0.25,0.8),mask.Color)
        weld(head,nose,CFrame.new(0,-0.05,-1))
    elseif definition.id == "sabito" or definition.id == "makomo" then
        if definition.id == "sabito" then hair.Color=Color3.fromRGB(201,142,116) end
        local mask=part(model,"FoxMask",Vector3.new(0.85,1,0.25),Color3.fromRGB(236,228,207))
        weld(head,mask,CFrame.new(0.8,0.25,-0.62)*CFrame.Angles(0,0,-0.25))
        local marking=part(model,"MaskMark",Vector3.new(0.55,0.12,0.08),Color3.fromRGB(151,69,56))
        weld(head,marking,CFrame.new(0.75,0.35,-0.8)*CFrame.Angles(0,0,-0.25))
    end

    if definition.hairColor then hair.Color=Color3.fromRGB(table.unpack(definition.hairColor)) end

    local function weaponPiece(name, size, offset, hand, color)
        local p = part(model, name, size, color or Color3.fromRGB(207, 222, 231))
        if hand == "torso" then torsoWeld(model, p, offset) else handWeld(hand or ra, p, offset) end
        return p
    end
    local weapon = definition.weapon
    if weapon == "katana" or weapon == "needle" or weapon == "serpent" then
        Rig.buildSword(model, definition)
        Rig.draw(model, true)
    elseif weapon == "dual" or weapon == "sickles" then
        local hands = (weapon == "dual" or weapon == "sickles") and {ra, la} or {ra}
        for _, hand in ipairs(hands) do
            weaponPiece("Hilt", Vector3.new(0.2, 0.22, 0.9), CFrame.new(0, -0.9, -0.15), hand, dark)
            weaponPiece("Guard", Vector3.new(0.65, 0.12, 0.4), CFrame.new(0, -0.9, -0.65), hand, accent)
            local width = weapon == "needle" and 0.09 or weapon == "dual" and 0.45 or 0.19
            weaponPiece("Blade", Vector3.new(width, 0.12, 3.6), CFrame.new(0, -0.9, -2.4), hand)
            if weapon == "sickles" then weaponPiece("Hook", Vector3.new(1.3, 0.12, 0.3), CFrame.new(0.5, -0.9, -4), hand) end
        end
    elseif weapon == "gun" then
        weaponPiece("Stock", Vector3.new(0.45, 0.55, 1.7), CFrame.new(0, -0.8, -0.5), ra, Color3.fromRGB(90, 59, 46))
        for side = -1, 1, 2 do weaponPiece("Barrel", Vector3.new(0.17, 0.2, 2), CFrame.new(side * 0.1, -0.65, -2), ra, dark) end
    elseif weapon == "flail" then
        weaponPiece("AxeHandle", Vector3.new(0.16, 0.16, 3.4), CFrame.new(0, -0.9, -1.4), ra, dark)
        weaponPiece("AxeHead", Vector3.new(1.5, 0.2, 0.9), CFrame.new(0, -0.9, -3), ra)
        for i = 1, 5 do weaponPiece("Chain", Vector3.new(0.14, 0.14, 0.65), CFrame.new(0, -0.9, -i * 0.6), la, dark) end
        local ball = weaponPiece("Morningstar", Vector3.new(1.1, 1.1, 1.1), CFrame.new(0, -0.9, -3.8), la)
        ball.Shape = Enum.PartType.Ball
    elseif weapon == "fans" then
        for _, hand in ipairs({ra, la}) do
            for i = -2, 2 do weaponPiece("FanLeaf", Vector3.new(0.4, 0.09, 1.5), CFrame.new(i * 0.23, -0.95, -1.2) * CFrame.Angles(0, i * 0.2, 0), hand, Color3.fromRGB(232, 191, 81)) end
        end
    elseif weapon == "whip" or weapon == "threads" then
        for i = 1, 7 do
            weaponPiece("Ribbon", Vector3.new(0.23, 0.1, 0.8), CFrame.new(math.sin(i * 0.7) * 0.7, -0.9, -i * 0.68), ra, accent)
        end
    elseif weapon == "staff" then
        weaponPiece("Staff", Vector3.new(0.22, 4.5, 0.22), CFrame.new(0, -0.8, -0.5), ra, accent)
    elseif weapon == "biwa" or weapon == "drums" then
        weaponPiece("Instrument", Vector3.new(1.4, 1.8, 0.5), CFrame.new(0, -0.2, -0.85), "torso", Color3.fromRGB(125, 80, 46))
    elseif weapon == "temari" then
        local ball = weaponPiece("Temari", Vector3.new(1.1, 1.1, 1.1), CFrame.new(0, -1.25, -0.3), ra, accent)
        ball.Shape = Enum.PartType.Ball
    end
    local board = Instance.new("BillboardGui")
    board.Name = "Nameplate"; board.Size = UDim2.fromOffset(190, 48)
    board.StudsOffset = Vector3.new(0, 3.2, 0); board.MaxDistance = 95
    board.AlwaysOnTop = false; board.Adornee = head; board.Parent = head
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 0.6); label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamMedium; label.TextSize = 13
    label.TextColor3 = Color3.fromRGB(242, 234, 219); label.TextStrokeTransparency = 0.4
    label.Text = definition.name; label.Parent = board
    local hp = Instance.new("Frame")
    hp.Position = UDim2.fromScale(0.15, 0.72); hp.Size = UDim2.fromScale(0.7, 0.08)
    hp.BorderSizePixel = 0; hp.BackgroundColor3 = accent; hp.Name = "Health"; hp.Parent = board
    humanoid.HealthChanged:Connect(function(health) hp.Size = UDim2.fromScale(0.7 * math.max(0, health / humanoid.MaxHealth), 0.08) end)
    model.Parent = parent
    return model, humanoid, root
end

return Rig
