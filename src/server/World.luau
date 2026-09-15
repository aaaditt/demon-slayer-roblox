local Lighting = game:GetService("Lighting")
local World = {}
World.Rooms = {}
local wood = Color3.fromRGB(75, 47, 42)
local roof = Color3.fromRGB(34, 42, 57)
local stone = Color3.fromRGB(79, 88, 96)
local gold = Color3.fromRGB(241, 181, 88)
local random = Random.new(74019)

local function part(parent, name, size, position, color, material)
    local p = Instance.new("Part")
    p.Name = name; p.Size = size; p.Position = position
    p.Color = color; p.Material = material or Enum.Material.SmoothPlastic
    p.Anchored = true; p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
    p.CanTouch = false; p.Parent = parent
    return p
end

local function sign(parent, position, title, subtitle)
    local post = part(parent, "Wayfinding", Vector3.new(13, 5, 0.5), position, wood, Enum.Material.Wood)
    local gui = Instance.new("SurfaceGui")
    gui.Face = Enum.NormalId.Back; gui.PixelsPerStud = 45; gui.Parent = post
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(0.94, 0.9); label.Position = UDim2.fromScale(0.03, 0.05)
    label.BackgroundTransparency = 1; label.TextColor3 = Color3.fromRGB(245, 231, 203)
    label.TextScaled = true; label.TextWrapped = true; label.Font = Enum.Font.GothamMedium
    label.Text = title .. "\n" .. subtitle; label.Parent = gui
    return post
end

local function lantern(parent, position)
    part(parent, "LanternPost", Vector3.new(0.45, 8, 0.45), position + Vector3.new(0, 4, 0), wood)
    part(parent, "LanternCap", Vector3.new(2.2, 0.45, 2.2), position + Vector3.new(0, 8.4, 0), roof)
    local glow = part(parent, "PaperLantern", Vector3.new(1.4, 1.5, 1.4), position + Vector3.new(0, 7.3, 0), gold, Enum.Material.Neon)
    glow.CanCollide = false
    local light = Instance.new("PointLight")
    light.Color = gold; light.Brightness = 0.7; light.Range = 22; light.Shadows = false; light.Parent = glow
end

local function tree(parent, position, theme)
    local h = random:NextNumber(15, 24)
    local trunk = part(parent, "TreeTrunk", Vector3.new(2, h, 2), position + Vector3.new(0, h/2, 0), wood, Enum.Material.Wood)
    trunk.Orientation = Vector3.new(0, random:NextNumber(0, 180), random:NextNumber(-4, 4))
    local color = theme == "wisteria" and Color3.fromRGB(162, 122, 207) or theme == "snow" and Color3.fromRGB(206, 220, 226) or Color3.fromRGB(45, 91, 82)
    for i = 1, 3 do
        local leaf = part(parent, "Canopy", Vector3.new(13 - i * 2, 6, 13 - i * 2), position + Vector3.new(0, h - 6 + i * 3, 0), color, Enum.Material.Grass)
        leaf.CanCollide = false; leaf.Shape = Enum.PartType.Ball
    end
    if theme == "wisteria" then
        for i = 1, 5 do
            local angle = i * math.pi * 2 / 5
            local petals = part(parent, "Wisteria", Vector3.new(0.8, 5 + i % 3, 0.8), position + Vector3.new(math.cos(angle)*4, h - 3, math.sin(angle)*4), Color3.fromRGB(192, 154, 240))
            petals.CanCollide = false
        end
    end
end

local function building(parent, pos, width, depth, height, lit)
    part(parent, "Foundation", Vector3.new(width + 3, 2, depth + 3), pos + Vector3.new(0, 1, 0), stone, Enum.Material.Slate)
    part(parent, "Plaster", Vector3.new(width, height, depth), pos + Vector3.new(0, height/2+2, 0), Color3.fromRGB(206, 191, 167))
    for x = -1, 1, 2 do
        for z = -1, 1, 2 do part(parent, "Timber", Vector3.new(0.7, height+1, 0.7), pos + Vector3.new(x*width/2, height/2+2, z*depth/2), wood, Enum.Material.Wood) end
    end
    for tier = 1, 3 do
        part(parent, "Eaves", Vector3.new(width+8-tier*2, 0.8, depth+8-tier*2), pos+Vector3.new(0, height+2+tier*0.7, 0), roof, Enum.Material.Slate)
    end
    local window = part(parent, "Shoji", Vector3.new(width*0.55, height*0.6, 0.16), pos+Vector3.new(0, height/2+2, depth/2+0.1), lit and Color3.fromRGB(245, 206, 139) or Color3.fromRGB(219, 205, 181), lit and Enum.Material.Neon or Enum.Material.SmoothPlastic)
    for i = -2, 2 do part(parent, "WindowFrame", Vector3.new(0.16, window.Size.Y, 0.2), window.Position+Vector3.new(i*width*0.1, 0, 0.12), wood) end
    part(parent, "WindowFrame", Vector3.new(window.Size.X, 0.16, 0.2), window.Position+Vector3.new(0, 0, 0.12), wood)
end

local function torii(parent, position)
    local red = Color3.fromRGB(133, 54, 61)
    for x = -1, 1, 2 do part(parent, "GatePillar", Vector3.new(1.5, 17, 1.5), position+Vector3.new(x*8, 8.5, 0), red) end
    part(parent, "GateBeam", Vector3.new(23, 1.5, 2), position+Vector3.new(0, 17, 0), roof)
    part(parent, "GateBeam", Vector3.new(20, 1, 1), position+Vector3.new(0, 13.5, 0), red)
end

function World.room(name, center, theme, size)
    local folder = Instance.new("Model"); folder.Name = name; folder.Parent = World.Root
    size = size or 190
    local ground = (theme == "snow" and Color3.fromRGB(205, 219, 227)) or ((theme == "castle" or theme == "mansion") and Color3.fromRGB(109, 75, 56)) or Color3.fromRGB(48, 66, 66)
    part(folder, "Ground", Vector3.new(size, 3, size), center+Vector3.new(0, -1.5, 0), ground, (theme == "castle" or theme == "mansion") and Enum.Material.WoodPlanks or Enum.Material.Grass)
    part(folder, "Path", Vector3.new(26, 0.18, size-8), center+Vector3.new(0, 0.08, 0), stone, Enum.Material.Slate)
    part(folder, "Path", Vector3.new(size-8, 0.17, 20), center+Vector3.new(0, 0.07, 0), stone, Enum.Material.Slate)
    local room = {folder = folder, center = center, size = size, spawn = center+Vector3.new(0, 4, size*0.32), bossSpawn = center+Vector3.new(0, 4, -size*0.18)}
    for axis = 1, 2 do
        for side = -1, 1, 2 do
            local wall = part(folder, "Boundary", axis==1 and Vector3.new(2, 70, size) or Vector3.new(size, 70, 2), center+(axis==1 and Vector3.new(side*size/2, 30, 0) or Vector3.new(0, 30, side*size/2)), roof)
            wall.Transparency = 1
            part(folder, "BoundaryRail", axis==1 and Vector3.new(1, 2, size) or Vector3.new(size, 2, 1), center+(axis==1 and Vector3.new(side*(size/2-2), 1, 0) or Vector3.new(0, 1, side*(size/2-2))), wood)
        end
    end
    for side = -1, 1, 2 do
        for z = -1, 1 do lantern(folder, center+Vector3.new(side*20, 0, z*45)) end
    end
    if theme == "castle" or theme == "mansion" or theme == "ice" then
        for side = -1, 1, 2 do
            for row = -1, 1 do
                part(folder, "GrandPillar", Vector3.new(4, 40, 4), center+Vector3.new(side*65, 20, row*55), wood, Enum.Material.Wood)
                part(folder, "CrossBeam", Vector3.new(136, 2, 3), center+Vector3.new(0, 40, row*55), wood)
            end
        end
        for i = 1, 6 do
            local angle = i*math.pi/3
            local p = center+Vector3.new(math.cos(angle)*160, 35+i*6, math.sin(angle)*160)
            building(folder, p, 24, 18, 12, true)
        end
        if theme == "ice" then
            local pond = part(folder, "LotusPond", Vector3.new(48, 0.25, 25), center+Vector3.new(48, 0.22, 0), Color3.fromRGB(126, 197, 223), Enum.Material.Ice)
            pond.Transparency = 0.2
            for i = 1, 7 do
                local lotus = part(folder, "IceLotus", Vector3.new(4, 1, 4), pond.Position+Vector3.new(random:NextNumber(-20,20), 0.7, random:NextNumber(-9,9)), Color3.fromRGB(201, 234, 246), Enum.Material.Glass)
                lotus.Shape = Enum.PartType.Ball; lotus.CanCollide = false
            end
        end
    elseif theme == "train" then
        for x = -1, 1, 2 do
            for z = -1, 1 do
                local pos = center+Vector3.new(x*51, 0, z*36)
                building(folder, pos, 17, 31, 11, true)
                for wheel = -1, 1, 2 do
                    local w = part(folder, "TrainWheel", Vector3.new(19, 4, 4), pos+Vector3.new(0, 1, wheel*10), roof, Enum.Material.Metal)
                    w.Shape = Enum.PartType.Cylinder
                end
            end
            part(folder, "Rail", Vector3.new(1, 0.4, size), center+Vector3.new(x*43, 0.2, 0), roof, Enum.Material.Metal)
        end
    else
        local forest = theme == "forest" or theme == "snow" or theme == "spider" or theme == "wisteria" or theme == "arena"
        for side = -1, 1, 2 do
            for row = -1, 1 do
                local p = center+Vector3.new(side*62, 0, row*55)
                if forest then tree(folder, p, theme == "arena" and "wisteria" or theme)
                else building(folder, p, 23, 22, theme=="city" and 23 or 12, true) end
            end
        end
        if forest then
            for i = 1, 9 do
                local angle = i*math.pi*2/9
                tree(folder, center+Vector3.new(math.cos(angle)*(size/2-14), 0, math.sin(angle)*(size/2-14)), theme)
            end
        end
        if theme == "spider" then
            for i = 1, 8 do
                local thread = part(folder, "Web", Vector3.new(0.09, 0.09, 80), center+Vector3.new((i%2==0 and -1 or 1)*48, 10+i, 0), Color3.fromRGB(187, 189, 209))
                thread.Orientation = Vector3.new(0, i*18, i*4); thread.CanCollide = false
            end
        end
        torii(folder, center+Vector3.new(0, 0, size*0.39))
    end
    return room
end

function World.init()
    World.Root = Instance.new("Folder"); World.Root.Name = "World"; World.Root.Parent = workspace
    World.Actors = Instance.new("Folder"); World.Actors.Name = "Actors"; World.Actors.Parent = workspace
    local atmosphere = Instance.new("Atmosphere")
    atmosphere.Density = 0.27; atmosphere.Offset = 0.1
    atmosphere.Color = Color3.fromRGB(173, 176, 207); atmosphere.Decay = Color3.fromRGB(73, 62, 91); atmosphere.Parent = Lighting
    local grade = Instance.new("ColorCorrectionEffect")
    grade.Saturation = -0.08; grade.Contrast = 0.08; grade.TintColor = Color3.fromRGB(231, 230, 255); grade.Parent = Lighting
    local bloom = Instance.new("BloomEffect")
    bloom.Intensity = 0.2; bloom.Size = 24; bloom.Threshold = 1.4; bloom.Parent = Lighting
    World.Hub = World.room("ButterflyMansion", Vector3.zero, "wisteria", 230)
    building(World.Hub.folder, Vector3.new(0, 0, -86), 52, 24, 16, true)
    sign(World.Hub.folder, Vector3.new(0, 8, -71), "WISTERIA CHRONICLES", "The night is yours to change")
    World.Arena = World.room("DuelCourtyard", Vector3.new(550, 0, 0), "arena", 200)
    sign(World.Arena.folder, Vector3.new(550, 8, -79), "DUEL COURTYARD", "Five eliminations / Three minutes")
    return World
end

function World.mission(slot, location)
    local center = Vector3.new((slot%4)*500, 0, 700+math.floor(slot/4)*500)
    local room = World.room("Mission_" .. slot .. "_" .. location.id, center, location.theme, 190)
    sign(room.folder, center+Vector3.new(0, 7, -78), location.name, "Watch the telegraph. Find your opening.")
    World.Rooms[slot] = room
    return room
end

function World.remove(slot)
    local room = World.Rooms[slot]
    if room then room.folder:Destroy(); World.Rooms[slot] = nil end
end

function World.inside(room, position, margin)
    local delta = position-room.center
    return math.abs(delta.X) < room.size/2-(margin or 3) and math.abs(delta.Z) < room.size/2-(margin or 3) and delta.Y > -10 and delta.Y < 60
end

return World
