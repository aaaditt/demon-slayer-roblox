local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Rules = require(Shared.Rules)
local Content = require(Shared.Content)
local Rig = require(script.Parent.Rig)
local MeleeRules = require(Shared.MeleeRules)
local Melee = require(script.Parent.Melee)
local M = Config.Melee
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
        self:stopMotion(actor)
        model:SetAttribute("Dead", true)
        if actor.onDeath then actor.onDeath(actor, actor.lastAttacker) end
    end)
    return actor
end

function Combat:remove(actor)
    self:stopMotion(actor)
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

function Combat:stopMotion(actor, reason)
    local motion = actor.motion
    if not motion then return end
    actor.lastMotion = {distance=(actor.root.Position-motion.origin).Magnitude,reason=reason or "cancelled"}
    actor.motion = nil
    motion.velocity:Destroy(); motion.attachment:Destroy()
    if actor.root.Parent then
        local v = actor.root.AssemblyLinearVelocity
        actor.root.AssemblyLinearVelocity = Vector3.new(0, v.Y, 0)
        actor.humanoid.AutoRotate = true
        if actor.player then
            -- Let the final server physics position replicate before giving control back.
            -- Immediate handoff lets the client's older position shorten the visible dash.
            local releaseAt=workspace:GetServerTimeNow()+0.15
            actor.motionReleaseAt=releaseAt
            task.delay(0.15,function()
                if actor.alive and actor.root.Parent and not actor.root.Anchored and not actor.motion and actor.motionReleaseAt==releaseAt then
                    pcall(function() actor.root:SetNetworkOwner(actor.player) end)
                    actor.motionReleaseAt=nil
                end
            end)
        end
    end
end

-- forced motion (knockback, clash push) is not cancelled by the mover being stunned.
function Combat:move(actor, direction, distance, duration, forced)
    if distance <= 0 then return 0 end
    self:stopMotion(actor)
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
    travel = (destination-origin).Magnitude
    if travel < 0.1 then
        actor.lastMotion = {distance=0,reason="blocked: "..(hit and hit.Instance.Name or "room bound"),height=origin.Y}
        return 0
    end
    direction = (destination-origin).Unit
    duration = duration or math.clamp(travel/65, 0.16, 0.36)
    local attachment = Instance.new("Attachment"); attachment.Name = "DashAttachment"; attachment.Parent = actor.root
    local velocity = Instance.new("LinearVelocity")
    velocity.Name = "DashVelocity"; velocity.Attachment0 = attachment
    velocity.RelativeTo = Enum.ActuatorRelativeTo.World
    velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
    velocity.PrimaryTangentAxis = Vector3.xAxis; velocity.SecondaryTangentAxis = Vector3.zAxis
    velocity.ForceLimitsEnabled = false
    velocity.PlaneVelocity = Vector2.new(direction.X, direction.Z)*(travel/duration)
    velocity.Parent = actor.root
    actor.humanoid.AutoRotate = false
    actor.root.CFrame = CFrame.lookAt(origin, origin+direction)
    pcall(function() actor.root:SetNetworkOwner(nil) end)
    actor.motion = {attachment=attachment,velocity=velocity,origin=origin,direction=direction,distance=travel,
        ends=workspace:GetServerTimeNow()+duration,speed=travel/duration,parameters=parameters,token=actor.castToken,forced=forced}
    return duration
end

-- info (optional): {source = "m1", finisher, swing, step} for sword-kit strikes. Returns damage, result.
function Combat:damage(actor, target, amount, status, info)
    local now = workspace:GetServerTimeNow()
    if not actor.alive or not target.alive or not Rules.canDamage(actor, target) then return end
    if actor.kind == "player" and actor.mode == "Arena" and not actor.arenaActive then return end
    if target.kind == "player" and target.mode == "Arena" and not target.arenaActive then return end
    local offset = actor.root.Position-target.root.Position
    local facing = offset.Magnitude < 0.01 and 1 or target.root.CFrame.LookVector:Dot(offset.Unit)
    local frontal = facing > 0.15
    local damage, result, energyCost
    if info and info.source == "m1" and target.invulnerableUntil <= now and target.guardUntil <= now then
        result = MeleeRules.blockOutcome(target.blocking, facing, now - target.blockStarted, info.finisher, false, M)
        damage, energyCost = result == "hit" and amount or 0, 0
    else
        -- The R15 sword kit's block only answers M1s: techniques reach a blocking sword-kit fighter.
        if Melee.isR15(target) then frontal = false end
        damage, result, energyCost = Rules.resolveDamage(amount, target, now, frontal, Config.GuardEnergyCost, Config.GuardReduction, Config.ParryWindow)
    end
    if target.healthFloor then damage = Rules.trainingDamage(target.humanoid.Health, damage, target.healthFloor) end
    target.energy = math.max(0, target.energy-energyCost)
    actor.lastCombat = now; target.lastCombat = now
    if result == "parry" or result == "counter" then
        actor.stunUntil = math.max(actor.stunUntil, now+(info and M.ParryStagger or 0.65))
        actor.castToken += 1
    elseif result == "break" then
        target.blocking = false; target.stunUntil = now+0.9; target.castToken += 1
    elseif result == "guardbreak" then
        target.blocking = false; target.stunUntil = now+M.GuardBreakStun; target.castToken += 1
    end
    if damage > 0 then
        target.lastAttacker = actor
        -- Only status-free hits receive ordinary brief stagger. Control status has an immunity window.
        if result == "hit" and not info and now >= target.controlImmuneUntil then
            target.stunUntil = math.max(target.stunUntil, now+0.12)
        end
        target.humanoid:TakeDamage(damage)
        if target.onDamaged then target.onDamaged(actor, damage, result) end
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
    local toward = offset.Magnitude > 0.01 and offset.Unit or Vector3.zero
    self:emit(target, "hit", {position = target.root.Position, amount = math.floor(damage+0.5), result = result,
        attacker = actor.model, contact = target.root.Position+toward*0.8+Vector3.new(0, 0.6, 0),
        source = info and info.source or "technique", finisher = info and info.finisher or false, swing = info and info.swing})
    return damage, result
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
    if actor.storyLocked and not (actor.storyCanBasic and move.id == "basic") then return false, "Follow the story objective" end
    if actor.model:GetAttribute("InCutscene") then return false, "Follow the story scene" end
    -- Draw first, then execute the requested strike if this actor has not been interrupted.
    if actor.model:GetAttribute("HasSheath") and not actor.model:GetAttribute("WeaponDrawn") then
        if now < actor.busyUntil or now < actor.stunUntil then return false, "Recovering" end
        self:weapon(actor, true)
        local token = actor.castToken
        task.delay(0.46, function()
            if actor.alive and actor.castToken == token then self:cast(actor, move, direction) end
        end)
        return true
    end
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
    if move.id ~= "basic" and move.damage > 0 and not field then
        actor.activeCast = {token = token, activeAt = now+move.windup, move = move, origin = origin, direction = direction}
        if self:clashCheck(actor) then return true end
    end
    if Melee.isR15(actor) then Melee.techniquePose(actor, move.pattern, now) end
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
        local travelTime = self:move(actor, direction, move.dash)
        self:emit(actor, "cast", {move = move.id, position = field or origin, destination = actor.root.Position, direction = direction, color = color, pattern = move.pattern, range = field and move.width or move.range, width = move.width})
        if travelTime > 0 then task.wait(travelTime) end
        if not actor.alive or actor.castToken ~= token then return end
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
        if actor.activeCast and actor.activeCast.token == token then actor.activeCast = nil end
    end)
    return true
end

local function reaches(cast, position)
    local localPoint = CFrame.lookAt(cast.origin, cast.origin+cast.direction):PointToObjectSpace(position)
    return math.abs(localPoint.Y) < 10 and Rules.inShape(cast.move.pattern, -localPoint.Z, localPoint.X, cast.move.range+cast.move.dash, cast.move.width)
end

-- Two opposing techniques that can reach each other and go active within Config.Melee.ClashWindow clash.
function Combat:clashCheck(actor)
    local mine = actor.activeCast
    for _, other in pairs(self.actors) do
        local theirs = other.activeCast
        if other ~= actor and other.alive and theirs and theirs.token == other.castToken and Rules.canDamage(actor, other)
            and reaches(mine, other.root.Position) and reaches(theirs, actor.root.Position) then
            local outcome = MeleeRules.clash(mine.activeAt, theirs.activeAt, MeleeRules.tier(mine.move), MeleeRules.tier(theirs.move), M.ClashWindow)
            if outcome then self:resolveClash(actor, other, outcome); return true end
        end
    end
    return false
end

function Combat:resolveClash(a, b, outcome)
    local now = workspace:GetServerTimeNow()
    local aMove, bMove = a.activeCast.move, b.activeCast.move
    a.activeCast = nil; b.activeCast = nil
    a.castToken += 1; b.castToken += 1
    a.busyUntil = math.max(a.busyUntil, now+0.45); b.busyUntil = math.max(b.busyUntil, now+0.45)
    local apart = Vector3.new(b.root.Position.X-a.root.Position.X, 0, b.root.Position.Z-a.root.Position.Z)
    apart = apart.Magnitude > 0.1 and apart.Unit or a.root.CFrame.LookVector
    local winner, loser, winnerMove
    if outcome == "a" then winner, loser, winnerMove = a, b, aMove elseif outcome == "b" then winner, loser, winnerMove = b, a, bMove end
    for _, fighter in ipairs({a, b}) do
        if fighter ~= winner then
            self:move(fighter, fighter == a and -apart or apart, M.ClashPush, 0.25, true)
            if Melee.isR15(fighter) then Melee.play(fighter, "clash_recoil", now) end
        end
    end
    self:emit(a, "clash", {position = (a.root.Position+b.root.Position)/2, outcome = outcome, a = a.model, b = b.model,
        color = Content.styles[(winnerMove or aMove).style].color})
    if winner then self:damage(winner, loser, winnerMove.damage*M.ClashLoserScale*(winner.damageScale or 1), "none") end
end

function Combat:basic(actor, direction)
    if Melee.isR15(actor) then return Melee.basic(self, actor, direction) end
    local now = workspace:GetServerTimeNow()
    local combo = now-actor.comboTime < 1.2 and actor.combo%3+1 or 1
    local style = actor.basicStyle or Content.characters[actor.characterId].styles[1] or "demon"
    local move = {id = "basic", style = style, pattern = combo==3 and "thrust" or "slash", status = "none", damage = combo==3 and 15 or 10,
        cost = 0, cooldown = 0.42, windup = 0.12, recovery = 0.3, range = 9, width = 8, dash = 0, hits = 1}
    local ok, reason = self:cast(actor, move, direction)
    if ok then actor.combo = combo; actor.comboTime = now end
    return ok, reason
end

function Combat:guard(actor, enabled)
    if Melee.isR15(actor) then return Melee.guard(self, actor, enabled) end
    local now = workspace:GetServerTimeNow()
    if not enabled then actor.blocking = false; return end
    if not actor.alive or (actor.storyLocked and not actor.storyCanBasic) or actor.model:GetAttribute("InCutscene") or actor.blocking or now < actor.busyUntil or now < actor.stunUntil then return end
    if now-(actor.lastGuard or 0) < 0.45 then return end
    actor.lastGuard = now; actor.blockStarted = now; actor.blocking = true
end

function Combat:weapon(actor, drawn)
    if Melee.isR15(actor) then return Melee.weapon(self, actor, drawn) end
    local now = workspace:GetServerTimeNow()
    if not actor.alive or actor.storyLocked or not actor.model:GetAttribute("HasSheath") or now < actor.busyUntil or now < actor.stunUntil then return false end
    if drawn == nil then drawn = not actor.model:GetAttribute("WeaponDrawn") end
    actor.castToken += 1; actor.blocking = false; actor.busyUntil = now+0.45
    Rig.draw(actor.model, drawn)
    actor.model:SetAttribute("Pose", drawn and "draw" or "sheathe")
    actor.model:SetAttribute("PoseStart", now); actor.model:SetAttribute("PoseDuration", 0.45)
    return true
end

function Combat:dodge(actor, direction)
    if Melee.isR15(actor) then return Melee.dash(self, actor, direction) end
    local now = workspace:GetServerTimeNow()
    if actor.model:GetAttribute("InCutscene") then return end
    if not actor.alive or now < actor.stunUntil or now < actor.busyUntil or (actor.cooldowns.dodge or 0)>now or actor.energy<Config.DodgeCost then return end
    actor.energy -= Config.DodgeCost; actor.cooldowns.dodge = now+Config.DodgeCooldown
    actor.busyUntil = now+0.32; actor.invulnerableUntil = now+0.28; actor.blocking = false; actor.castToken += 1
    actor.model:SetAttribute("Pose", "evade")
    actor.model:SetAttribute("PoseStart", now); actor.model:SetAttribute("PoseDuration", Config.DodgeDuration)
    self:move(actor, direction, Config.DodgeDistance, Config.DodgeDuration)
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
        if actor.motion then
            local m = actor.motion
            local traveled = (actor.root.Position-m.origin):Dot(m.direction)
            local hit = workspace:Blockcast(actor.root.CFrame, Vector3.new(3, 4, 2), m.direction*(m.speed*dt+0.6), m.parameters)
            if hit then self:stopMotion(actor, "collision: "..hit.Instance.Name)
            elseif now >= m.ends or traveled >= m.distance then self:stopMotion(actor, "finished")
            elseif not m.forced and (now < actor.stunUntil or actor.castToken ~= m.token) then self:stopMotion(actor, "interrupted") end
        end
        local stunned = now<actor.stunUntil
        local frozen = stunned or actor.motion ~= nil or (actor.motionReleaseAt and now<actor.motionReleaseAt) or actor.model:GetAttribute("InCutscene")
        local swinging = actor.swingUntil and now<actor.swingUntil
        actor.humanoid.WalkSpeed = frozen and 0 or actor.blocking and Config.GuardSpeed or swinging and Config.WalkSpeed*M.SwingSpeedScale or actor.status.chill and 14 or Config.WalkSpeed
        actor.humanoid.JumpPower = (frozen or actor.blocking) and 0 or Config.JumpPower
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
            elseif distance > (actor.basicOnly and 7 or 11) then actor.humanoid:MoveTo(target.root.Position)
            else actor.humanoid:Move(Vector3.zero) end
            if distance>0.1 and now>=actor.nextAction and now>=actor.busyUntil then
                actor.root.CFrame = CFrame.lookAt(actor.root.Position, actor.root.Position+flat.Unit)
                local list = Content.characters[actor.characterId].moves
                local choices = {}
                for _, id in ipairs(actor.basicOnly and {} or list) do
                    local move = Content.moves[id]
                    if move.damage>0 and (actor.cooldowns[id] or 0)<=now and actor.energy>=move.cost then table.insert(choices, move) end
                end
                local move = #choices>0 and choices[math.random(#choices)] or nil
                if distance < 10 and (actor.basicOnly or math.random()<0.4) then self:basic(actor, flat.Unit); actor.nextAction = now+(actor.attackInterval or 0.9)
                elseif move and distance < math.max(move.range+move.dash, 16) then self:cast(actor, move, flat.Unit); actor.nextAction = now+1.5
                end
            end
        end
    end
end

return Combat
