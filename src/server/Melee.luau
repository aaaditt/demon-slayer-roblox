-- Server-authoritative R15 sword kit: M1 string, block, draw/sheathe, dashes and technique poses.
-- Timings come from the shared keyframe markers (AnimData), so every client path hits on the same frame.
-- Clients learn what to play from model attributes Anim/AnimStart (server clock).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Rules = require(Shared.Rules)
local MeleeRules = require(Shared.MeleeRules)
local AnimSets = require(Shared.AnimSets)
local Content = require(Shared.Content)
local SwordBuilder = require(script.Parent.SwordBuilder)
local M = Config.Melee
local Melee = {}

local DASH_ANIM = {front = "dash_f", back = "dash_b", left = "dash_l", right = "dash_r"}
-- Stand-in poses for breathing techniques until their authored choreography exists (docs/VFX_STANDARD.md).
local TECHNIQUE_POSE = {slash = "m1_1", barrage = "m1_3", spin = "m1_3", thrust = "m1_4", dash = "dash_f", burst = "m1_4", projectile = "m1_2"}

local function clock() return workspace:GetServerTimeNow() end
local function flat(v) return Vector3.new(v.X, 0, v.Z) end

function Melee.isR15(actor)
    return actor.model:GetAttribute("RigKind") == "R15"
end

function Melee.anims(actor)
    return AnimSets[actor.model:GetAttribute("AnimSet")]
end

function Melee.play(actor, id, t)
    actor.model:SetAttribute("Anim", id)
    actor.model:SetAttribute("AnimStart", t or clock())
end

local function ready(actor, t)
    if not actor.alive then return false, "Respawning" end
    if actor.model:GetAttribute("InCutscene") then return false, "Follow the story scene" end
    if actor.storyLocked and not actor.storyCanBasic then return false, "Follow the story objective" end
    if actor.mode == "Arena" and not actor.arenaActive then return false, "Waiting for an opponent" end
    if t < actor.stunUntil then return false, "Recovering" end
    return true
end

function Melee.weapon(combat, actor, drawn)
    local t = clock()
    if not actor.alive or actor.storyLocked or actor.model:GetAttribute("InCutscene") or t < actor.busyUntil or t < actor.stunUntil then return false end
    if drawn == nil then drawn = not actor.model:GetAttribute("WeaponDrawn") end
    local id = drawn and "draw" or "sheathe"
    local anim = Melee.anims(actor)[id]
    actor.castToken += 1; actor.blocking = false
    local token = actor.castToken
    actor.busyUntil = t + anim.markers.End
    actor.chain = nil
    Melee.play(actor, id, t)
    task.delay(anim.markers[drawn and "Grip" or "Release"], function()
        if actor.alive and actor.castToken == token then SwordBuilder.setDrawn(actor.model, drawn) end
    end)
    return true
end

function Melee.guard(combat, actor, enabled)
    local t = clock()
    if not enabled then
        if actor.blocking and actor.model:GetAttribute("Anim") == "block" then Melee.play(actor, "", t) end
        actor.blocking = false
        return
    end
    if not ready(actor, t) or actor.blocking or t < actor.busyUntil then return end
    if t - (actor.lastGuard or 0) < 0.45 then return end
    -- Blocking needs the blade out; snap it into the hands rather than delaying the guard.
    if not actor.model:GetAttribute("WeaponDrawn") then SwordBuilder.setDrawn(actor.model, true) end
    actor.castToken += 1
    actor.lastGuard = t; actor.blockStarted = t; actor.blocking = true
    Melee.play(actor, "block", t)
end

local function targetsInSwing(combat, actor, anim)
    local cf = actor.root.CFrame
    local box = anim.hitbox
    local reach = box.length + box.tolerance
    local center = cf * CFrame.new(0, 0, -(box.forwardOffset + box.tolerance / 2))
    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {actor.model}
    local found, list = {}, {}
    for _, part in ipairs(workspace:GetPartBoundsInBox(center, Vector3.new(box.width, box.height, reach), params)) do
        local model = part:FindFirstAncestorOfClass("Model")
        while model and not combat.actors[model] do model = model:FindFirstAncestorOfClass("Model") end
        local target = model and combat.actors[model]
        if target and not found[target] and target.alive and Rules.canDamage(actor, target) then
            found[target] = true
            local offset = cf:PointToObjectSpace(target.root.Position)
            if MeleeRules.inHitbox(-offset.Z, offset.X, offset.Y, box) then table.insert(list, target) end
        end
    end
    return list
end

local function knockback(combat, actor, target, t)
    local dir = flat(target.root.Position - actor.root.Position)
    dir = dir.Magnitude > 0.1 and dir.Unit or actor.root.CFrame.LookVector
    target.castToken += 1; target.blocking = false
    target.stunUntil = math.max(target.stunUntil, t + 0.8 + 0.5)
    combat:move(target, dir, M.KnockbackDistance, 0.35, true)
    if target.root.Parent then
        local position = target.root.Position
        target.root.CFrame = CFrame.lookAt(position, position - dir)
        target.root.AssemblyLinearVelocity += Vector3.new(0, M.KnockbackLift, 0)
    end
    if Melee.isR15(target) then
        Melee.play(target, "knockback", t)
        task.delay(M.Knockdown, function()
            if target.alive and target.model:GetAttribute("AnimStart") == t then Melee.play(target, "getup") end
        end)
    end
end

local function strike(combat, actor, anim, step)
    local t = clock()
    local finisher = anim.finisher == true
    for _, target in ipairs(targetsInSwing(combat, actor, anim)) do
        local amount = (finisher and M.FinisherDamage or M.Damage) * (actor.damageScale or 1)
        local _, result = combat:damage(actor, target, amount, "none", {source = "m1", finisher = finisher, swing = anim.swing, step = step})
        if not target.alive then continue end
        if result == "hit" then
            if finisher then
                knockback(combat, actor, target, t)
            else
                target.castToken += 1; target.blocking = false
                target.stunUntil = math.max(target.stunUntil, t + M.Hitstun)
                if Melee.isR15(target) then Melee.play(target, anim.swing == "left" and "hit_r" or "hit_l", t) end
            end
        elseif result == "guardbreak" and Melee.isR15(target) then
            Melee.play(target, "clash_recoil", t)
        elseif result == "parry" then
            Melee.play(actor, "clash_recoil", t)
        end
    end
end

function Melee.basic(combat, actor, direction)
    local t = clock()
    local ok, reason = ready(actor, t)
    if not ok then return false, reason end
    if actor.blocking then return false, "Release guard first" end
    if not actor.model:GetAttribute("WeaponDrawn") then
        if t < actor.busyUntil then return false, "Recovering" end
        Melee.weapon(combat, actor, true)
        local token = actor.castToken
        task.delay(Melee.anims(actor).draw.markers.End, function()
            if actor.alive and actor.castToken == token then Melee.basic(combat, actor, direction) end
        end)
        return true
    end
    if t < actor.busyUntil then return false, "Recovering" end
    local chain = actor.chain or {step = 0, lastEnd = 0, busyUntil = 0}
    local step = MeleeRules.nextChain(chain, t, M)
    if not step then return false, "Recovering" end
    local anim = Melee.anims(actor)["m1_" .. step]
    direction = flat(direction)
    if direction.Magnitude > 0.1 then
        local position = actor.root.Position
        actor.root.CFrame = CFrame.lookAt(position, position + direction.Unit)
    end
    actor.castToken += 1
    local token = actor.castToken
    actor.chain = {step = step, lastEnd = t + anim.markers.End, busyUntil = t + anim.markers.CanChain}
    actor.busyUntil = t + anim.markers.CanChain
    actor.swingUntil = t + anim.markers.End
    actor.lastCombat = t
    Melee.play(actor, "m1_" .. step, t)
    combat:emit(actor, "swing", {position = actor.root.Position, direction = actor.root.CFrame.LookVector, step = step, finisher = anim.finisher == true})
    task.delay(anim.markers.Hit, function()
        if actor.alive and actor.castToken == token and clock() >= actor.stunUntil then strike(combat, actor, anim, step) end
    end)
    return true
end

-- Nearest damageable enemy within lock range, for side dashes that circle a target.
local function lockTarget(combat, actor)
    local best, bestDistance = nil, M.TargetLockRange
    for _, other in pairs(combat.actors) do
        if other ~= actor and other.alive and Rules.canDamage(actor, other) then
            local distance = flat(other.root.Position - actor.root.Position).Magnitude
            if distance > 0.5 and distance < bestDistance then best, bestDistance = other, distance end
        end
    end
    return best
end

function Melee.dash(combat, actor, direction)
    local t = clock()
    if not ready(actor, t) or t < actor.busyUntil then return false end
    direction = flat(direction)
    local localDir = actor.root.CFrame:VectorToObjectSpace(direction)
    local kind = MeleeRules.dashKind(localDir.X, localDir.Z)
    local key = "dash_" .. kind
    if (actor.cooldowns[key] or 0) > t then return false end
    local cfg = M.Dash[kind]
    local facing = actor.root.CFrame.LookVector
    local travel = direction.Magnitude > 0.1 and direction.Unit or facing
    local target = (kind == "left" or kind == "right") and lockTarget(combat, actor) or nil
    if target then
        -- Circle the target: tangent around it, pulled slightly inward to keep the spacing.
        local toward = flat(target.root.Position - actor.root.Position).Unit
        local tangent = toward:Cross(Vector3.yAxis) * (kind == "right" and 1 or -1)
        travel = (tangent + toward * 0.25).Unit
    end
    actor.cooldowns[key] = t + cfg.cooldown
    actor.busyUntil = t + M.DashDuration
    actor.blocking = false; actor.castToken += 1
    Melee.play(actor, DASH_ANIM[kind], t)
    local duration = combat:move(actor, travel, cfg.distance, M.DashDuration)
    -- Dashes keep the fighter's facing (toward the locked target when circling).
    if actor.root.Parent then
        local position = actor.root.Position
        local look = target and flat(target.root.Position - position) or facing
        if look.Magnitude > 0.1 then actor.root.CFrame = CFrame.lookAt(position, position + look.Unit) end
    end
    local color = Content.characters[actor.characterId].color
    combat:emit(actor, "dodge", {position = actor.root.Position, color = color, dash = kind, direction = travel})
    return duration > 0
end

function Melee.techniquePose(actor, pattern, t)
    local id = TECHNIQUE_POSE[pattern]
    if id then Melee.play(actor, id, t) end
end

return Melee
