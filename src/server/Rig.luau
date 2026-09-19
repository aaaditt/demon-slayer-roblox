local Rig = {}

function Rig.draw(model, drawn)
    model:SetAttribute("WeaponDrawn", drawn)
    model:SetAttribute("WeaponChanged", workspace:GetServerTimeNow())
end

function Rig.part(parent, name, size, color, cf, collide)
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

function Rig.weld(a, b, offset)
    b.CFrame = a.CFrame * offset
    local w = Instance.new("WeldConstraint")
    w.Part0 = a; w.Part1 = b; w.Parent = b
end

function Rig.motor(parent, name, a, b, c0, c1)
    local m = Instance.new("Motor6D")
    m.Name = name; m.Part0 = a; m.Part1 = b
    m.C0 = c0; m.C1 = c1; m.Parent = parent
    return m
end
local part, weld, motor = Rig.part, Rig.weld, Rig.motor

function Rig.storyWeapon(model, kind)
    local previous = model:FindFirstChild("StoryWeapon")
    if previous then previous:Destroy() end
    model:SetAttribute("HasSheath", false)
    for _, name in ipairs({"Blade", "Hilt", "Guard", "Scabbard"}) do
        local item = model:FindFirstChild(name)
        if item then item.Transparency = 1 end
    end
    if not kind then return end
    local weapon = Instance.new("Model"); weapon.Name = "StoryWeapon"; weapon.Parent = model
    local hand = model["Right Arm"]
    local function piece(name, size, offset, color)
        local item = part(weapon, name, size, color)
        weld(hand, item, offset)
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

-- Overhead name and health bar shared by R6 rigs and R15 bodies.
function Rig.nameplate(head, humanoid, name, color)
    local board = Instance.new("BillboardGui")
    board.Name = "Nameplate"; board.Size = UDim2.fromOffset(190, 48)
    board.StudsOffset = Vector3.new(0, 3.2, 0); board.MaxDistance = 95
    board.AlwaysOnTop = false; board.Adornee = head; board.Parent = head
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 0.6); label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamMedium; label.TextSize = 13
    label.TextColor3 = Color3.fromRGB(242, 234, 219); label.TextStrokeTransparency = 0.4
    label.Text = name; label.Parent = board
    local hp = Instance.new("Frame")
    hp.Position = UDim2.fromScale(0.15, 0.72); hp.Size = UDim2.fromScale(0.7, 0.08)
    hp.BorderSizePixel = 0; hp.BackgroundColor3 = color; hp.Name = "Health"; hp.Parent = board
    humanoid.HealthChanged:Connect(function(health) hp.Size = UDim2.fromScale(0.7 * math.max(0, health / humanoid.MaxHealth), 0.08) end)
    return board
end

function Rig.create(parent, position, definition, actorName)
    local model = Instance.new("Model")
    model.Name = actorName or definition.name
    model:SetAttribute("CharacterId", definition.id)
    local skin = Color3.fromRGB(235, 197, 171)
    local dark = Color3.fromRGB(27, 30, 43)
    local accent = Color3.fromRGB(table.unpack(definition.outfitColor or definition.color))
    local origin = CFrame.new(position)
    local root = part(model, "HumanoidRootPart", Vector3.new(2, 2, 1), dark, origin)
    root.Transparency = 1; root.Massless = false
    local torso = part(model, "Torso", Vector3.new(2, 2, 1), dark, origin, true)
    local head = part(model, "Head", Vector3.new(2, 1, 1), skin, origin * CFrame.new(0, 1.5, 0))
    local ra = part(model, "Right Arm", Vector3.new(1, 2, 1), accent, origin * CFrame.new(1.5, 0, 0))
    local la = part(model, "Left Arm", Vector3.new(1, 2, 1), accent, origin * CFrame.new(-1.5, 0, 0))
    local rl = part(model, "Right Leg", Vector3.new(1, 2, 1), dark, origin * CFrame.new(0.5, -2, 0))
    local ll = part(model, "Left Leg", Vector3.new(1, 2, 1), dark, origin * CFrame.new(-0.5, -2, 0))
    motor(root, "RootJoint", root, torso, CFrame.identity, CFrame.identity)
    motor(torso, "Neck", torso, head, CFrame.new(0, 1, 0), CFrame.new(0, -0.5, 0))
    motor(torso, "Right Shoulder", torso, ra, CFrame.new(1, 0.5, 0), CFrame.new(-0.5, 0.5, 0))
    motor(torso, "Left Shoulder", torso, la, CFrame.new(-1, 0.5, 0), CFrame.new(0.5, 0.5, 0))
    motor(torso, "Right Hip", torso, rl, CFrame.new(1, -1, 0), CFrame.new(0.5, 1, 0))
    motor(torso, "Left Hip", torso, ll, CFrame.new(-1, -1, 0), CFrame.new(-0.5, 1, 0))
    local humanoid = Instance.new("Humanoid")
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
        weld(torso, coat, CFrame.new(side * 0.54, -0.15, 0.6) * CFrame.Angles(0, 0, side * 0.05))
        local cuff = part(model, "Cuff", Vector3.new(1.04, 0.45, 1.04), skin)
        weld(side == 1 and ra or la, cuff, CFrame.new(0, -0.78, 0))
    end
    local belt = part(model, "Belt", Vector3.new(2.04, 0.2, 1.08), Color3.fromRGB(232, 220, 205))
    weld(torso, belt, CFrame.new(0, -0.55, 0))
    if definition.id == "tanjiro" then
        for row = 0, 2 do
            for col = 0, 3 do
                if (row + col) % 2 == 0 then
                    local check = part(model, "Check", Vector3.new(0.48, 0.65, 0.05), dark)
                    weld(torso, check, CFrame.new(-0.75 + col * 0.5, 0.65 - row * 0.68, 0.7))
                    local front = part(model, "HaoriCheck", Vector3.new(0.48, 0.65, 0.05), (col+row)%4==0 and dark or accent)
                    weld(torso, front, CFrame.new(-0.75+col*0.5,0.65-row*0.68,-0.53))
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

    local function weaponPiece(name, size, offset, hand, color)
        local p = part(model, name, size, color or Color3.fromRGB(207, 222, 231))
        weld(hand or ra, p, offset)
        return p
    end
    local weapon = definition.weapon
    if weapon == "katana" or weapon == "needle" or weapon == "serpent" then
        model:SetAttribute("HasSheath", true)
        Rig.draw(model, true)
        local sheathCF = CFrame.new(-1.05, -0.8, 0.3)*CFrame.Angles(0, 0, -0.18)
        local sheath = part(model, "Scabbard", Vector3.new(0.3, 0.28, 3.8), dark)
        weld(torso, sheath, sheathCF*CFrame.new(0, 0, 1.2))
        local hilt = part(model, "Hilt", Vector3.new(0.23, 0.24, 1), dark)
        motor(torso, "WeaponGrip", torso, hilt, sheathCF, CFrame.identity)
        local guard = part(model, "Guard", Vector3.new(0.65, 0.5, 0.12), accent)
        weld(hilt, guard, CFrame.new(0, 0, -0.52))
        local blade = part(model, "Blade", Vector3.new(weapon == "needle" and 0.09 or 0.22, 0.1, 3.6), Color3.fromRGB(218, 233, 242))
        weld(hilt, blade, CFrame.new(0, 0, -2.35))
        local a = Instance.new("Attachment"); a.Position = Vector3.new(0,0,-1.7); a.Parent = blade
        local b = Instance.new("Attachment"); b.Position = Vector3.new(0,0,1.4); b.Parent = blade
        local trail = Instance.new("Trail"); trail.Name = "SwordTrail"; trail.Attachment0 = a; trail.Attachment1 = b
        trail.Lifetime = 0.13; trail.MinLength = 0.1; trail.Enabled = false
        trail.Color = ColorSequence.new(accent); trail.Transparency = NumberSequence.new(0.5,1); trail.Parent = blade
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
        weaponPiece("Instrument", Vector3.new(1.4, 1.8, 0.5), CFrame.new(0, -0.2, -0.85), torso, Color3.fromRGB(125, 80, 46))
    elseif weapon == "temari" then
        local ball = weaponPiece("Temari", Vector3.new(1.1, 1.1, 1.1), CFrame.new(0, -1.25, -0.3), ra, accent)
        ball.Shape = Enum.PartType.Ball
    end
    Rig.nameplate(head, humanoid, definition.name, accent)
    model.Parent = parent
    return model, humanoid, root
end

return Rig
