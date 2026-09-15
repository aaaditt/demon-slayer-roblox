local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Rules = require(Shared.Rules)
local Content = require(Shared.Content)
local Combat = {}
Combat.__index = Combat

function Combat.new(effectRemote)
    return setmetatable({actors = {}, effect = effectRemote}, Combat)
end

function Combat:register(model, humanoid, root, options)
    local now = workspace:GetServerTimeNow()
    local actor = {
        model = model, humanoid = humanoid, root = root,
        energy = Config.MaxEnergy, busyUntil = 0, stunUntil = 0, cooldowns = {},
        invulnerableUntil = now+Config.SpawnProtection, guardUntil = 0,
        blocking = false, blockStarted = 0, lastCombat = 0, combo = 0, comboTime = 0,
        status = {}, controlImmuneUntil = 0, castToken = 0, alive = true,
        lastPosition = root.Position, motionTime = now, nextAI = now+1.5, nextAction = now+1.5,
    }
    for k, v in pairs(options) do actor[k] = v end
    humanoid.MaxHealth = options.maxHealth or Config.MaxHealth
    humanoid.Health = humanoid.MaxHealth
    humanoid.WalkSpeed = Config.WalkSpeed
    humanoid.JumpPower = Config.JumpPower
    model:SetAttribute("Mode", actor.mode)
    model:SetAttribute("Zone", actor.zone)
    model:SetAttribute("ActorKind", actor.kind)
    self.actors[model] = actor
    humanoid.Died:Connect(function()
        if not actor.alive then return end
        actor.alive = false; actor.castToken += 1; actor.blocking = false
        model:SetAttribute("Dead", true)
        if actor.onDeath then actor.onDeath(actor, actor.lastAttacker) end
    end)
    return actor
end

function Combat:remove(actor)
    actor.alive = false; actor.castToken += 1
    self.actors[actor.model] = nil
    if actor.model.Parent then actor.model:Destroy() end
end

function Combat:emit(actor, kind, payload)
    payload = payload or {}
    payload.kind = kind; payload.actor = actor.model; payload.zone = actor.zone
    payload.time = workspace:GetServerTimeNow()
    self.effect:FireAllClients(payload)
end

function Combat:lineOfSight(actor, target, from)
    local parameters = RaycastParams.new()
    parameters.FilterType = Enum.RaycastFilterType.Exclude
    parameters.FilterDescendantsInstances = {actor.model, target.model}
    parameters.RespectCanCollide = true
    local delta = target.root.Position-from
    local hit = workspace:Raycast(from, delta, parameters)
    return hit == nil
end

function Combat:move(actor, direction, distance)
    if distance <= 0 then return end
    local parameters = RaycastParams.new()
    parameters.FilterType = Enum.RaycastFilterType.Exclude
    parameters.FilterDescendantsInstances = {actor.model}
    parameters.RespectCanCollide = true
    local origin = actor.root.Position
    local hit = workspace:Blockcast(CFrame.new(origin), Vector3.new(3, 4, 2), direction*distance, parameters)
    local travel = hit and math.max(0, hit.Distance-1.5) or distance
    local destination = origin+direction*travel
    if actor.room then
        local bound = actor.room.size/2-5
        destination = Vector3.new(math.clamp(destination.X, actor.room.center.X-bound, actor.room.center.X+bound), destination.Y, math.clamp(destination.Z, actor.room.center.Z-bound, actor.room.center.Z+bound))
    end
    actor.model:PivotTo(CFrame.lookAt(destination, destination+direction))
    actor.root.AssemblyLinearVelocity = Vector3.zero
    actor.lastPosition = destination
    actor.motionTime = workspace:GetServerTimeNow()
end

function Combat:damage(actor, target, amount, status)
    local now = workspace:GetServerTimeNow()
    if not actor.alive or not target.alive or not Rules.canDamage(actor, target) then return end
    if actor.kind == "player" and actor.mode == "Arena" and not actor.arenaActive then return end
    if target.kind == "player" and target.mode == "Arena" and not target.arenaActive then return end
    local offset = actor.root.Position-target.root.Position
    local frontal = offset.Magnitude < 0.01 or target.root.CFrame.LookVector:Dot(offset.Unit) > 0.15
    local damage, result, energyCost = Rules.resolveDamage(amount, target, now, frontal, Config.GuardEnergyCost, Config.GuardReduction, Config.ParryWindow)
    target.energy = math.max(0, target.energy-energyCost)
    actor.lastCombat = now; target.lastCombat = now
    if result == "parry" or result == "counter" then
        actor.stunUntil = math.max(actor.stunUntil, now+0.65)
        actor.castToken += 1
    elseif result == "break" then
        target.blocking = false; target.stunUntil = now+0.9; target.castToken += 1
    end
    if damage > 0 then
        target.lastAttacker = actor
        -- Only status-free hits receive ordinary brief stagger. Control status has an immunity window.
        if result == "hit" and now >= target.controlImmuneUntil then
            target.stunUntil = math.max(target.stunUntil, now+0.12)
        end
        target.humanoid:TakeDamage(damage)
        if target.alive and result ~= "block" and status ~= "none" and status ~= "cleanse" then
            if status == "poison" or status == "burn" then
                target.status[status] = {untilTime = now+3, nextTick = now+0.75, source = actor}
            elseif status == "chill" then
                target.status.chill = {untilTime = now+2}
            elseif now >= target.controlImmuneUntil then
                local duration = status == "sleep" and 0.8 or status == "root" and 0.65 or 0.35
                target.stunUntil = math.max(target.stunUntil, now+duration)
                target.controlImmuneUntil = now+duration+2
                target.status[status] = {untilTime = now+duration}
                target.castToken += 1
                target.blocking = false
            end
        end
    end
    self:emit(target, "hit", {position = target.root.Position, amount = math.floor(damage+0.5), result = result})
end

function Combat:fieldCenter(actor, origin, direction, range)
    local best, bestDistance = nil, range
    for _, target in pairs(self.actors) do
        local delta = target.root.Position-origin
        if target.alive and Rules.canDamage(actor, target) and delta.Magnitude > 0.1 and delta.Magnitude < bestDistance and direction:Dot(delta.Unit) > 0.55 then
            if self:lineOfSight(actor, target, origin) then best = target.root.Position; bestDistance = delta.Magnitude end
        end
    end
    return best or origin+direction*math.min(range, 24)
end

function Combat:cast(actor, move, direction)
    local now = workspace:GetServerTimeNow()
    if not actor.alive then return false, "Respawning" end
    if actor.blocking then return false, "Release guard first" end
    if actor.mode == "Arena" and not actor.arenaActive then return false, "Waiting for an opponent" end
    local accepted, reason = Rules.spend(actor, move, now)
    if not accepted then return false, reason end
    if move.damage > 0 then actor.lastCombat = now end
    direction = Vector3.new(direction.X, 0, direction.Z)
    if direction.Magnitude < 0.1 then direction = Vector3.new(0, 0, -1) else direction = direction.Unit end
    local origin = actor.root.Position
    local field = (move.pattern == "trap" or move.pattern == "summon") and self:fieldCenter(actor, origin, direction, move.range) or nil
    actor.root.CFrame = CFrame.lookAt(origin, origin+direction)
    actor.castToken += 1
    local token = actor.castToken
    actor.model:SetAttribute("Pose", move.pattern)
    actor.model:SetAttribute("PoseStart", now)
    actor.model:SetAttribute("PoseDuration", actor.busyUntil-now)
    local color = Content.styles[move.style].color
    self:emit(actor, "telegraph", {move = move.id, position = field or origin, direction = direction, color = color, duration = move.windup, pattern = move.pattern, range = field and move.width or move.range, width = move.width})
    task.spawn(function()
        task.wait(move.windup)
        if not actor.alive or actor.castToken ~= token or actor.stunUntil > workspace:GetServerTimeNow() then return end
        local activeTime = workspace:GetServerTimeNow()
        if move.pattern == "guard" then actor.guardUntil = activeTime+1.2
        elseif move.pattern == "evade" then actor.invulnerableUntil = activeTime+0.45
        elseif move.pattern == "heal" then
            actor.humanoid.Health = math.min(actor.humanoid.MaxHealth, actor.humanoid.Health+28)
            if move.status == "cleanse" then actor.status = {} end
        end
        self:move(actor, direction, move.dash)
        self:emit(actor, "cast", {move = move.id, position = field or origin, destination = actor.root.Position, direction = direction, color = color, pattern = move.pattern, range = field and move.width or move.range, width = move.width})
        if move.damage <= 0 then return end
        local reference = CFrame.lookAt(origin, origin+direction)
        for hitIndex = 1, move.hits do
            if not actor.alive or actor.castToken ~= token then return end
            for _, target in pairs(self.actors) do
                if target.alive and Rules.canDamage(actor, target) then
                    local position = target.root.Position
                    local localPoint = reference:PointToObjectSpace(position)
                    local hitShape
                    if field then
                        local difference = position-field
                        hitShape = Vector2.new(difference.X, difference.Z).Magnitude <= move.width and math.abs(difference.Y) <= 10
                    else
                        hitShape = math.abs(localPoint.Y) < 10 and Rules.inShape(move.pattern, -localPoint.Z, localPoint.X, move.range+move.dash, move.width)
                    end
                    if hitShape and self:lineOfSight(actor, target, field or origin) then
                        self:damage(actor, target, move.damage/move.hits*(actor.damageScale or 1), move.status)
                    end
                end
            end
            if hitIndex < move.hits then task.wait(0.09) end
        end
    end)
    return true
end

function Combat:basic(actor, direction)
    local now = workspace:GetServerTimeNow()
    local combo = now-actor.comboTime < 1.2 and actor.combo%3+1 or 1
    local style = Content.characters[actor.characterId].styles[1] or "demon"
    local move = {id = "basic", style = style, pattern = combo==3 and "thrust" or "slash", status = "none", damage = combo==3 and 15 or 10,
        cost = 0, cooldown = 0.42, windup = 0.12, recovery = 0.3, range = 9, width = 8, dash = 0, hits = 1}
    local ok, reason = self:cast(actor, move, direction)
    if ok then actor.combo = combo; actor.comboTime = now end
    return ok, reason
end

function Combat:guard(actor, enabled)
    local now = workspace:GetServerTimeNow()
    if not enabled then actor.blocking = false; return end
    if not actor.alive or actor.blocking or now < actor.busyUntil or now < actor.stunUntil then return end
    if now-(actor.lastGuard or 0) < 0.45 then return end
    actor.lastGuard = now; actor.blockStarted = now; actor.blocking = true
end

function Combat:dodge(actor, direction)
    local now = workspace:GetServerTimeNow()
    if not actor.alive or now < actor.stunUntil or now < actor.busyUntil or (actor.cooldowns.dodge or 0)>now or actor.energy<Config.DodgeCost then return end
    actor.energy -= Config.DodgeCost; actor.cooldowns.dodge = now+Config.DodgeCooldown
    actor.busyUntil = now+0.32; actor.invulnerableUntil = now+0.28; actor.blocking = false; actor.castToken += 1
    self:move(actor, direction, Config.DodgeDistance)
    self:emit(actor, "dodge", {position = actor.root.Position, color = Content.characters[actor.characterId].color})
end

function Combat:tick(dt)
    local now = workspace:GetServerTimeNow()
    for _, actor in pairs(self.actors) do
        if not actor.alive or not actor.model.Parent then continue end
        if now > actor.busyUntil and not actor.blocking then actor.energy = math.min(Config.MaxEnergy, actor.energy+Config.EnergyRegen*dt) end
        for status, effect in pairs(actor.status) do
            if effect.untilTime <= now then actor.status[status] = nil
            elseif effect.nextTick and effect.nextTick <= now then
                effect.nextTick = now+0.75
                if effect.source and effect.source.alive and Rules.canDamage(effect.source, actor) then
                    actor.lastAttacker = effect.source; actor.lastCombat = now; actor.humanoid:TakeDamage(2)
                end
            end
        end
        if not actor.alive then continue end
        local stunned = now<actor.stunUntil
        actor.humanoid.WalkSpeed = stunned and 0 or actor.blocking and Config.GuardSpeed or actor.status.chill and 14 or Config.WalkSpeed
        actor.humanoid.JumpPower = (stunned or actor.blocking) and 0 or Config.JumpPower
        actor.model:SetAttribute("Blocking", actor.blocking)
        actor.model:SetAttribute("Invulnerable", now<actor.invulnerableUntil or now<actor.guardUntil)
        if actor.kind == "player" and now-actor.motionTime>=0.25 then
            local elapsed = now-actor.motionTime
            local offset = actor.root.Position-actor.lastPosition
            local flat = Vector2.new(offset.X, offset.Z).Magnitude
            local outside = actor.room and (math.abs(actor.root.Position.X-actor.room.center.X)>actor.room.size/2 or math.abs(actor.root.Position.Z-actor.room.center.Z)>actor.room.size/2 or actor.root.Position.Y>actor.room.center.Y+65)
            if flat>80*elapsed+6 or outside then
                actor.model:PivotTo(CFrame.new(actor.lastPosition))
                actor.root.AssemblyLinearVelocity = Vector3.zero
            end
            actor.lastPosition = actor.root.Position; actor.motionTime = now
        end
        if actor.root.Position.Y < -15 then actor.humanoid.Health = 0 end
        if actor.kind == "npc" and actor.target and actor.target.alive and now>=actor.nextAI then
            local target = actor.target
            local delta = target.root.Position-actor.root.Position
            local flat = Vector3.new(delta.X, 0, delta.Z)
            local distance = flat.Magnitude
            actor.nextAI = now+0.15
            if stunned then actor.humanoid:Move(Vector3.zero)
            elseif distance > 11 then actor.humanoid:MoveTo(target.root.Position)
            else actor.humanoid:Move(Vector3.zero) end
            if distance>0.1 and now>=actor.nextAction and now>=actor.busyUntil then
                actor.root.CFrame = CFrame.lookAt(actor.root.Position, actor.root.Position+flat.Unit)
                local list = Content.characters[actor.characterId].moves
                local choices = {}
                for _, id in ipairs(list) do
                    local move = Content.moves[id]
                    if move.damage>0 and (actor.cooldowns[id] or 0)<=now and actor.energy>=move.cost then table.insert(choices, move) end
                end
                local move = #choices>0 and choices[math.random(#choices)] or nil
                if distance < 10 and math.random()<0.4 then self:basic(actor, flat.Unit); actor.nextAction = now+0.9
                elseif move and distance < math.max(move.range+move.dash, 16) then self:cast(actor, move, flat.Unit); actor.nextAction = now+1.5
                end
            end
        end
    end
end

return Combat
