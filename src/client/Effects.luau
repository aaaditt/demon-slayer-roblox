local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local Effects = {reduced = false, active = 0}
local folder = Instance.new("Folder"); folder.Name = "LocalCombatEffects"; folder.Parent = workspace

local function part(size, cf, color, life, transparency)
    if Effects.active >= (Effects.reduced and 45 or 160) then return nil end
    Effects.active += 1
    local p = Instance.new("Part")
    p.Size = size; p.CFrame = cf; p.Color = color; p.Anchored = true
    p.Material = Enum.Material.Neon; p.Transparency = transparency or 0.2
    p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = false; p.Parent = folder
    Debris:AddItem(p, life)
    task.delay(life, function() Effects.active = math.max(0, Effects.active-1) end)
    return p
end

local function line(a, b, thickness, color, life)
    local delta = b-a
    if delta.Magnitude<0.01 then return end
    local p = part(Vector3.new(thickness, thickness, delta.Magnitude), CFrame.lookAt((a+b)/2,b), color, life)
    if p then TweenService:Create(p, TweenInfo.new(life), {Transparency = 1}):Play() end
end

local function ring(center, radius, color, life, count)
    count = count or (Effects.reduced and 12 or 24)
    for i = 1, count do
        local a, b = (i-1)/count*math.pi*2, i/count*math.pi*2
        line(center+Vector3.new(math.cos(a)*radius,0,math.sin(a)*radius), center+Vector3.new(math.cos(b)*radius,0,math.sin(b)*radius), 0.16, color, life)
    end
end

local function arc(center, direction, radius, color, life, vertical)
    local cf = CFrame.lookAt(center,center+direction)
    local segments = Effects.reduced and 6 or 12
    for i = 1, segments do
        local a, b = -2.3+(i-1)/segments*4.6, -2.3+i/segments*4.6
        local function point(angle)
            return cf:PointToWorldSpace(vertical and Vector3.new(0, math.sin(angle)*radius, -math.cos(angle)*radius) or Vector3.new(math.sin(angle)*radius, 0.1, -math.cos(angle)*radius))
        end
        line(point(a),point(b),0.32,color,life)
    end
end

function Effects.play(event)
    local player = Players.LocalPlayer
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root or not event.position or (root.Position-event.position).Magnitude>260 then return end
    if character:GetAttribute("Zone") ~= event.zone then return end
    local color = event.color and Color3.fromRGB(table.unpack(event.color)) or Color3.fromRGB(250,220,164)
    local position, direction = event.position, event.direction or Vector3.new(0,0,-1)
    if event.kind == "telegraph" then
        if event.pattern == "guard" or event.pattern == "heal" or event.pattern == "evade" then return end
        local floor = position-Vector3.new(0,2.7,0)
        local danger = event.actor~=character and Color3.fromRGB(255,119,106) or color
        if event.pattern=="burst" or event.pattern=="spin" or event.pattern=="trap" or event.pattern=="summon" then
            ring(floor,event.range,danger,event.duration,12)
        else
            local right = direction:Cross(Vector3.yAxis)
            local half = math.max(2,event.width/2)
            line(floor+right*half,floor+right*half+direction*event.range,0.13,danger,event.duration)
            line(floor-right*half,floor-right*half+direction*event.range,0.13,danger,event.duration)
            line(floor+direction*event.range-right*half,floor+direction*event.range+right*half,0.13,danger,event.duration)
        end
    elseif event.kind == "cast" then
        local pattern = event.pattern
        if pattern=="projectile" then
            line(position,position+direction*event.range,0.65,color,0.24)
            for i=1,3 do ring(position+direction*(i*12),1.5,color,0.3,8) end
        elseif pattern=="dash" or pattern=="evade" then
            line(position,event.destination,0.9,color,0.35)
            arc(event.destination,direction,6,color,0.35,false)
        elseif pattern=="burst" or pattern=="spin" then
            ring(position-Vector3.new(0,2.5,0),event.range,color,0.45)
            arc(position,direction,math.min(event.range,13),color,0.4,true)
            if not Effects.reduced then arc(position+Vector3.new(0,1.2,0),-direction,math.min(event.range,13),color,0.4,false) end
        elseif pattern=="trap" or pattern=="summon" then
            ring(position-Vector3.new(0,2.5,0),event.range,color,0.55)
            for i=1,6 do
                local a=i*math.pi/3
                local p=position+Vector3.new(math.cos(a)*event.range*0.6,-2.5,math.sin(a)*event.range*0.6)
                line(p,p+Vector3.new(0,7,0),0.4,color,0.5)
            end
        elseif pattern=="guard" or pattern=="heal" then
            ring(position-Vector3.new(0,2.5,0),4,color,0.7)
            arc(position,direction,3,color,0.6,true)
        else
            arc(position,direction,pattern=="thrust" and 4 or 7,color,0.28,false)
            if pattern=="barrage" and not Effects.reduced then
                for i=1,2 do task.delay(i*0.09,function() arc(position+Vector3.new(0,i*0.4,0),direction,6+i,color,0.25,i%2==0) end) end
            end
        end
    elseif event.kind=="dodge" then
        ring(position-Vector3.new(0,2.5,0),3,color,0.3,10)
    elseif event.kind=="hit" then
        local anchor = part(Vector3.new(0.1,0.1,0.1),CFrame.new(position+Vector3.new(0,2.2,0)),color,0.7,1)
        if not anchor then return end
        local gui = Instance.new("BillboardGui"); gui.Size=UDim2.fromOffset(130,42); gui.AlwaysOnTop=true; gui.Parent=anchor
        local text=Instance.new("TextLabel"); text.Size=UDim2.fromScale(1,1); text.BackgroundTransparency=1
        text.Font=Enum.Font.GothamBold; text.TextSize=20; text.TextStrokeTransparency=0.5
        text.TextColor3=event.amount>0 and Color3.fromRGB(255,226,178) or Color3.fromRGB(139,227,248)
        text.Text=event.amount>0 and tostring(event.amount) or string.upper(event.result); text.Parent=gui
        TweenService:Create(anchor,TweenInfo.new(0.7),{Position=anchor.Position+Vector3.new(0,2.4,0)}):Play()
        TweenService:Create(text,TweenInfo.new(0.7),{TextTransparency=1,TextStrokeTransparency=1}):Play()
    end
end

return Effects
