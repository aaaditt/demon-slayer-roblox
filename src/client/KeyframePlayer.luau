-- Plays the server-announced sword-kit animation (attributes Anim/AnimStart) on R15 bodies.
-- Published Roblox animations are used when data/animations.json has an ID; otherwise the authored keyframes
-- are sampled onto Motor6D.Transform after Roblox's own Animate step, so default locomotion still shows through.
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local AnimData = require(Shared.AnimData)
local AnimSets = require(Shared.AnimSets)
local AnimIds = require(Shared.AnimIds)
local KeyframePlayer = {}
local rigs = {}
local watched = setmetatable({}, {__mode = "k"})
local rad = math.rad
local BLEND_IN, BLEND_OUT, FOLLOW = 1 / 0.06, 1 / 0.1, 34

local function register(model)
    if rigs[model] or model:GetAttribute("RigKind") ~= "R15" then return end
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local motors = {}
    for _, item in ipairs(model:GetDescendants()) do
        if item:IsA("Motor6D") and AnimData.PARENT[item.Name] then motors[item.Name] = item end
    end
    if not humanoid or not motors.Root or not motors.RightShoulder then return end
    rigs[model] = {model = model, humanoid = humanoid, motors = motors, current = {}, weights = {}, tracks = {},
        clipKey = nil, freezeUntil = 0, frozen = 0}
end

local function watch(model)
    if not model:IsA("Model") or watched[model] then return end
    watched[model] = true
    register(model)
    local added = model.DescendantAdded:Connect(function() register(model) end)
    local changed = model:GetAttributeChangedSignal("RigKind"):Connect(function() register(model) end)
    model.Destroying:Once(function() added:Disconnect(); changed:Disconnect(); rigs[model] = nil end)
end

-- Hit-stop: the clip clock stops advancing for `seconds` on this model.
function KeyframePlayer.freeze(model, seconds)
    local rig = model and rigs[model]
    if not rig then return end
    rig.freezeUntil = math.max(rig.freezeUntil, os.clock() + seconds)
    for _, track in pairs(rig.tracks) do if track and track.IsPlaying then track:AdjustSpeed(0) end end
end

local function publishedTrack(rig, setName, id)
    local assetId = AnimIds[setName] and AnimIds[setName][id]
    if not assetId or assetId == "" then return nil end
    local track = rig.tracks[id]
    if track == nil then
        local animator = rig.humanoid:FindFirstChildOfClass("Animator")
        local ok, loaded = pcall(function()
            local animation = Instance.new("Animation")
            animation.AnimationId = "rbxassetid://" .. assetId
            return animator:LoadAnimation(animation)
        end)
        track = ok and loaded or false
        rig.tracks[id] = track
    end
    return track or nil
end

-- Returns the clip to show and its local time, or nil for plain Roblox locomotion.
local function activeClip(rig, set, now)
    local model = rig.model
    local id = model:GetAttribute("Anim")
    local start = model:GetAttribute("AnimStart") or 0
    local key = tostring(id) .. "@" .. tostring(start)
    if key ~= rig.clipKey then rig.clipKey = key; rig.frozen = 0 end
    local anim = id and id ~= "" and set[id]
    if anim then
        local elapsed = now - start - rig.frozen
        if elapsed >= 0 and (anim.loop or elapsed < anim.duration) then return anim, elapsed end
    end
    if model:GetAttribute("WeaponDrawn") and set.idle_drawn then return set.idle_drawn, now end
    return nil
end

local function step(rig, dt, now)
    local model = rig.model
    local setName = model:GetAttribute("AnimSet")
    local set = AnimSets[setName]
    if not set then return end
    if os.clock() < rig.freezeUntil then
        rig.frozen += dt
    else
        for _, track in pairs(rig.tracks) do if track and track.IsPlaying and track.Speed == 0 then track:AdjustSpeed(1) end end
    end
    local anim, t = activeClip(rig, set, now)
    -- Published animation: hand playback to Roblox and keep our own weights at zero.
    local track = anim and publishedTrack(rig, setName, anim.id)
    for _, other in pairs(rig.tracks) do
        if other and other ~= track and other.IsPlaying then other:Stop(0.1) end
    end
    if track then
        if not track.IsPlaying then track:Play(0.05); track.TimePosition = math.min(t, track.Length) end
        anim = nil
    end
    local controlled = {}
    local pose = anim and AnimData.sample(anim, t)
    if anim then
        for _, joint in ipairs(anim.priority == "Action" and anim.joints or anim.mask or anim.joints) do controlled[joint] = true end
    end
    local follow = 1 - math.exp(-FOLLOW * dt)
    for joint, motor in pairs(rig.motors) do
        local weight = rig.weights[joint] or 0
        if controlled[joint] then
            local v = pose[joint]
            local target = CFrame.new(v[4], v[5], v[6]) * CFrame.Angles(rad(v[1]), rad(v[2]), rad(v[3]))
            rig.current[joint] = rig.current[joint] and rig.current[joint]:Lerp(target, follow) or target
            weight = math.min(1, weight + dt * BLEND_IN)
        else
            weight = math.max(0, weight - dt * BLEND_OUT)
        end
        rig.weights[joint] = weight
        if weight > 0 and rig.current[joint] then
            motor.Transform = motor.Transform:Lerp(rig.current[joint], weight)
        elseif weight == 0 then
            rig.current[joint] = nil
        end
    end
    -- Sword trail only through the cutting part of each swing.
    local sword = model:FindFirstChild("Sword")
    local blade = sword and sword:FindFirstChild("Blade")
    local trail = blade and blade:FindFirstChild("SwordTrail")
    if trail then
        local hit = anim and anim.markers.Hit
        trail.Enabled = hit ~= nil and t >= hit - 0.1 and t <= hit + 0.12
    end
end

function KeyframePlayer.start()
    local actors = workspace:WaitForChild("Actors")
    actors.ChildAdded:Connect(watch)
    for _, model in ipairs(actors:GetChildren()) do watch(model) end
    -- PreSimulation runs after Roblox steps its animators, so these Transforms layer over Animate's locomotion.
    RunService.PreSimulation:Connect(function(dt)
        local now = workspace:GetServerTimeNow()
        local character = Players.LocalPlayer.Character
        local localRoot = character and character:FindFirstChild("HumanoidRootPart")
        for model, rig in pairs(rigs) do
            local root = model:FindFirstChild("HumanoidRootPart")
            if not root or not root:IsDescendantOf(workspace) then continue end
            if localRoot and (root.Position - localRoot.Position).Magnitude > 250 then continue end
            step(rig, math.min(dt, 0.1), now)
        end
    end)
end

return KeyframePlayer
