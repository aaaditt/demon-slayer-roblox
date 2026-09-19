-- Hit confirmation for the sword kit: white body flash, hit-stop, camera shake, slash sparks and sounds.
-- Everything is bounded (one Highlight per model, short-lived parts) and respects Effects.reduced / muted.
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Assets = require(ReplicatedStorage:WaitForChild("Shared").Assets)
local KeyframePlayer = require(script.Parent.KeyframePlayer)
local HitFeedback = {}
local folder = Instance.new("Folder"); folder.Name = "LocalHitFeedback"; folder.Parent = workspace
local active = 0
local shake = {untilTime = 0, strength = 0, bound = false}

-- Built-in fallbacks (Roblox ships no sword sounds): {file, pitch, volume}. Asset IDs in data/assets.json win.
local FALLBACK = {
    swing = {"action_jump.mp3", 1.9, 0.12}, hit = {"action_jump_land.mp3", 1.7, 0.35},
    finisher = {"impact_explosion_03.mp3", 1.5, 0.22}, block = {"action_jump_land.mp3", 2.6, 0.3},
    clash = {"impact_explosion_03.mp3", 2.1, 0.3},
}

function HitFeedback.sound(kind, position, effects)
    if effects.muted then return end
    local character = Players.LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local distance = root and (root.Position - position).Magnitude or 0
    local custom = Assets.sounds[kind]
    local fallback = FALLBACK[kind]
    if not fallback then return end
    local audio = Instance.new("Sound")
    audio.SoundId = custom ~= "" and ("rbxassetid://" .. custom) or ("rbxasset://sounds/" .. fallback[1])
    audio.PlaybackSpeed = custom ~= "" and 1 or fallback[2]
    audio.Volume = fallback[3] * 2 * math.clamp(1 - distance / 140, 0, 1)
    audio.Parent = SoundService; audio:Play(); Debris:AddItem(audio, 3)
end

local function flash(model, strength)
    if not model or not model.Parent then return end
    local highlight = model:FindFirstChild("HitFlash")
    if not highlight then
        highlight = Instance.new("Highlight"); highlight.Name = "HitFlash"
        highlight.FillColor = Color3.new(1, 1, 1); highlight.OutlineColor = Color3.new(1, 1, 1)
        highlight.OutlineTransparency = 1; highlight.FillTransparency = 1
        highlight.DepthMode = Enum.HighlightDepthMode.Occluded
        highlight.Adornee = model; highlight.Parent = model
    end
    highlight.FillTransparency = 1 - strength
    highlight.OutlineTransparency = 1 - strength * 0.6
    TweenService:Create(highlight, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {FillTransparency = 1, OutlineTransparency = 1}):Play()
end

local function shard(cf, size, color, life, grow)
    if active >= 60 then return end
    active += 1
    local p = Instance.new("Part")
    p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = false
    p.Material = Enum.Material.Neon; p.Color = color; p.Size = size; p.CFrame = cf; p.Parent = folder
    TweenService:Create(p, TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 1, Size = size * grow}):Play()
    Debris:AddItem(p, life)
    task.delay(life, function() active -= 1 end)
end

-- A bright slash streak across the contact point along the swing's path, plus radial sparks.
local function spark(position, facing, swing, color, big, reduced)
    local tilt = swing == "down" and math.rad(90) or swing == "left" and math.rad(-35) or math.rad(35)
    local base = CFrame.lookAt(position, position + facing) * CFrame.Angles(0, 0, tilt)
    shard(base * CFrame.Angles(0, math.rad(90), 0), Vector3.new(0.08, 0.08, big and 5 or 3.4), Color3.new(1, 1, 1), 0.16, 1.4)
    local count = reduced and 3 or (big and 9 or 6)
    for i = 1, count do
        local angle = (i / count) * math.pi * 2 + math.random() * 0.4
        local dir = base:VectorToWorldSpace(Vector3.new(math.cos(angle), math.sin(angle), -0.3))
        shard(CFrame.lookAt(position, position + dir) * CFrame.new(0, 0, -0.6), Vector3.new(0.06, 0.06, big and 1.4 or 0.9), color, 0.14, 1.8)
    end
end

local function startShake(strength, duration)
    shake.strength = math.max(shake.strength, strength)
    shake.untilTime = math.max(shake.untilTime, os.clock() + duration)
    shake.duration = duration
    if shake.bound then return end
    shake.bound = true
    RunService:BindToRenderStep("WisteriaHitShake", Enum.RenderPriority.Camera.Value + 1, function()
        local left = shake.untilTime - os.clock()
        if left <= 0 then
            shake.bound = false; shake.strength = 0
            RunService:UnbindFromRenderStep("WisteriaHitShake")
            return
        end
        local s = shake.strength * (left / shake.duration)
        local camera = workspace.CurrentCamera
        camera.CFrame *= CFrame.new((math.random() - 0.5) * s, (math.random() - 0.5) * s, 0) * CFrame.Angles(0, 0, (math.random() - 0.5) * s * 0.04)
    end)
end

function HitFeedback.play(event, effects)
    local character = Players.LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root or not event.position or (root.Position - event.position).Magnitude > 260 then return end
    if character:GetAttribute("Zone") ~= event.zone then return end
    local involved = event.actor == character or event.attacker == character or event.a == character or event.b == character
    if event.kind == "hit" then
        local attackerRoot = event.attacker and event.attacker:FindFirstChild("HumanoidRootPart")
        local facing = attackerRoot and (event.position - attackerRoot.Position) or Vector3.zAxis
        facing = Vector3.new(facing.X, 0, facing.Z)
        facing = facing.Magnitude > 0.01 and facing.Unit or Vector3.zAxis
        local contact = event.contact or event.position
        if event.result == "block" or event.result == "parry" or event.result == "guardbreak" then
            spark(contact, facing, event.swing, Color3.fromRGB(170, 214, 255), event.result ~= "block", effects.reduced)
            HitFeedback.sound("block", contact, effects)
            KeyframePlayer.freeze(event.attacker, 0.05); KeyframePlayer.freeze(event.actor, 0.05)
            if event.result == "guardbreak" then flash(event.actor, 0.5) end
            if involved then startShake(event.result == "block" and 0.12 or 0.35, 0.12) end
            return
        end
        if (event.amount or 0) <= 0 then return end
        local finisher = event.finisher == true
        flash(event.actor, finisher and 0.9 or 0.75)
        local stop = finisher and 0.12 or 0.06
        KeyframePlayer.freeze(event.actor, stop)
        if event.source == "m1" then KeyframePlayer.freeze(event.attacker, stop) end
        spark(contact, facing, event.swing, Color3.fromRGB(255, 244, 228), finisher, effects.reduced)
        HitFeedback.sound(finisher and "finisher" or "hit", contact, effects)
        if involved then startShake(finisher and 0.5 or 0.22, finisher and 0.2 or 0.12) end
    elseif event.kind == "clash" then
        local color = event.color and Color3.fromRGB(table.unpack(event.color)) or Color3.new(1, 1, 1)
        for i = 1, (effects.reduced and 6 or 12) do
            local angle = i / (effects.reduced and 6 or 12) * math.pi * 2
            local dir = Vector3.new(math.cos(angle), math.sin(angle) * 0.6, math.sin(angle))
            shard(CFrame.lookAt(event.position, event.position + dir) * CFrame.new(0, 0, -1), Vector3.new(0.1, 0.1, 2.2), i % 2 == 0 and color or Color3.new(1, 1, 1), 0.25, 2)
        end
        flash(event.a, 0.6); flash(event.b, 0.6)
        KeyframePlayer.freeze(event.a, 0.1); KeyframePlayer.freeze(event.b, 0.1)
        HitFeedback.sound("clash", event.position, effects)
        if involved then startShake(0.45, 0.2) end
    elseif event.kind == "swing" then
        HitFeedback.sound("swing", event.position, effects)
    end
end

return HitFeedback
