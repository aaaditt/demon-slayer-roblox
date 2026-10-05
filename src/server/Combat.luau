local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Rules = require(Shared.Rules)
local Content = require(Shared.Content)
local MotionMath = require(Shared.MotionMath)
local AnimationIndex = require(Shared.AnimationIndex)
local Profiles = require(Shared.MotionProfile).new(Content, AnimationIndex)
local Rig = require(script.Parent.Rig)
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
        blocking = false, blockStarted = 0, lastCombat = 0, weaponSince = now, combo = 0, comboTime = 0,
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
    if motion.extendedBusy and actor.busyUntil==motion.extendedBusy then
        actor.busyUntil=math.max(workspace:GetServerTimeNow(),motion.originalBusy)
    end
    motion.velocity:Destroy(); motion.attachment:Destroy()
    if actor.root.Parent then
        local v = actor.root.AssemblyLinearVelocity
        actor.root.AssemblyLinearVelocity = Vector3.new(0, v.Y, 0)
        actor.humanoid.AutoRotate = true
        if actor.player then
            -- Settle after completion/correction. Client-driven movement normally retains ownership;
            -- rejected movement and server-simulated movement release it only after this interval.
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

function Combat:validateMotion(actor)
    local m=actor.motion
    if not m or not m.clientDriven then return true end
    local now=workspace:GetServerTimeNow()
    local offset=actor.root.Position-m.origin
    local elapsed=math.max(0,now-m.started)
    local forward=offset:Dot(m.direction)
    local lateral=offset:Dot(Vector3.new(-m.direction.Z,0,m.direction.X))
    local gravity=math.max(1,workspace.Gravity)
    local highest=math.max(0,m.verticalSpeed)^2/(2*gravity)+3
    local lowest=math.min(0,m.verticalSpeed)*elapsed-0.5*gravity*elapsed^2-3
    local valid=Rules.motionEnvelope(forward,lateral,elapsed,m.speed,m.distance,Config.MotionPositionSlack)
        and Rules.finite(offset.Y) and offset.Y>=lowest and offset.Y<=highest
    local delta=actor.root.Position-m.verifiedPosition
    local hit=valid and delta.Magnitude>0.01 and workspace:Blockcast(CFrame.new(m.verifiedPosition),Vector3.new(3,4,2),delta,m.parameters)
    if not valid or hit then
        -- Take control before correcting a forged/obstructed position; ordinary completion retains
        -- client ownership and therefore has no ownership-transfer interpolation stall.
        pcall(function() actor.root:SetNetworkOwner(nil) end)
        actor.model:PivotTo(CFrame.new(m.verifiedPosition)*m.rotation)
        actor.castToken+=1
        actor.invulnerableUntil=math.min(actor.invulnerableUntil,now)
        self:stopMotion(actor,hit and ("rejected collision: "..hit.Instance.Name) or "rejected motion envelope")
        actor.lastPosition=actor.root.Position;actor.motionTime=now
        return false
    end
    m.verifiedPosition=actor.root.Position
    return true
end

-- keepFacing: travel without turning toward the direction (side and back dashes).
function Combat:move(actor, direction, distance, duration, keepFacing)
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
    local clientDriven=actor.player~=nil and not actor.root.Anchored
    local started=workspace:GetServerTimeNow()
    local expires=started+duration+(clientDriven and Config.MotionReplicationGrace or 0)
    if clientDriven then
        velocity:SetAttribute("ClientDriven",true)
        velocity:SetAttribute("Origin",origin);velocity:SetAttribute("Direction",direction)
        velocity:SetAttribute("Distance",travel);velocity:SetAttribute("Speed",travel/duration)
        velocity:SetAttribute("Expires",expires)
    end
    velocity.Parent = actor.root
    actor.humanoid.AutoRotate = false
    if not keepFacing then actor.root.CFrame = CFrame.lookAt(origin, origin+direction) end
    pcall(function() actor.root:SetNetworkOwner(clientDriven and actor.player or nil) end)
    actor.motion = {attachment=attachment,velocity=velocity,origin=origin,direction=direction,distance=travel,
        ends=expires,started=started,speed=travel/duration,parameters=parameters,token=actor.castToken,
        clientDriven=clientDriven,verifiedPosition=origin,rotation=actor.root.CFrame.Rotation,
        verticalSpeed=math.clamp(actor.root.AssemblyLinearVelocity.Y,-250,Config.JumpPower)}
    if clientDriven and actor.busyUntil<expires then
        actor.motion.originalBusy=actor.busyUntil;actor.motion.extendedBusy=expires;actor.busyUntil=expires
    end
    return duration
end

-- Hit reactions are visual poses only. An idle target flinches; control effects override whatever is playing,
-- since they interrupt it anyway. A light flinch never replaces a pose that is still running.
function Combat:react(target, pose, duration)
    local now = workspace:GetServerTimeNow()
    local model = target.model
    if not model.Parent or model:GetAttribute("InCutscene") then return end
    if pose == "hit_light" and now < (model:GetAttribute("PoseStart") or 0)+(model:GetAttribute("PoseDuration") or 0) then return end
    model:SetAttribute("PoseVariant", nil); model:SetAttribute("PoseWindup", nil)
    model:SetAttribute("Pose", pose); model:SetAttribute("PoseStart", now); model:SetAttribute("PoseDuration", duration)
end

function Combat:damage(actor, target, amount, status)
    local now = workspace:GetServerTimeNow()
    if not self:validateMotion(actor) then return end
    self:validateMotion(target)
    if not actor.alive or not target.alive or not Rules.canDamage(actor, target) then return end
    if actor.kind == "player" and actor.mode == "Arena" and not actor.arenaActive then return end
    if target.kind == "player" and target.mode == "Arena" and not target.arenaActive then return end
    local offset = actor.root.Position-target.root.Position
    local frontal = offset.Magnitude < 0.01 or target.root.CFrame.LookVector:Dot(offset.Unit) > 0.15
    amount *= target.damageMultiplier or 1
    local damage, result, energyCost = Rules.resolveDamage(amount, target, now, frontal, Config.GuardEnergyCost, Config.GuardReduction, Config.ParryWindow)
    if target.damageMultiplier==0 then result="guarded" end
    if target.healthFloor then damage = Rules.trainingDamage(target.humanoid.Health, damage, target.healthFloor) end
    target.energy = math.max(0, target.energy-energyCost)
    actor.lastCombat = now; target.lastCombat = now
    if result == "parry" or result == "counter" then
        actor.stunUntil = math.max(actor.stunUntil, now+0.65)
        actor.castToken += 1
        self:react(target, "parry", 0.3)
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
                self:react(target, "hit_heavy", math.max(duration, 0.6))
            end
        end
        if target.alive and result == "hit" and now >= target.busyUntil then self:react(target, "hit_light", 0.3) end
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
    if not self:validateMotion(actor) then return false,"Invalid movement" end
    if not actor.alive then return false, "Respawning" end
    if not Rules.storyMoveAllowed(actor,move.id) then return false, "Follow the story objective" end
    if actor.model:GetAttribute("InCutscene") then return false, "Follow the story scene" end
    -- Draw first, then execute the requested strike if this actor has not been interrupted.
    if actor.model:GetAttribute("HasSheath") and not actor.model:GetAttribute("WeaponDrawn") then
        if now < actor.busyUntil or now < actor.stunUntil then return false, "Recovering" end
        local drawn, duration = self:weapon(actor, true, "iai")
        if not drawn then return false, "Recovering" end
        local token = actor.castToken
        task.delay(duration+0.01, function()
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
    -- Clients time-warp attack clips so their Hit marker lands on this windup; basics pick combo clips.
    actor.model:SetAttribute("PoseWindup", move.windup)
    actor.model:SetAttribute("PoseVariant", move.variant)
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
        local movement=actor.motion
        self:emit(actor, "cast", {move = move.id, position = field or origin, destination = actor.root.Position, direction = direction, color = color, pattern = move.pattern, range = field and move.width or move.range, width = move.width})
        if travelTime > 0 then
            if movement and movement.clientDriven then
                repeat task.wait() until actor.motion~=movement or workspace:GetServerTimeNow()>=movement.ends
            else task.wait(travelTime) end
        end
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
    end)
    return true
end

function Combat:basic(actor, direction)
    local now = workspace:GetServerTimeNow()
    local combo = now-actor.comboTime < 1.2 and actor.combo%3+1 or 1
    local style = actor.basicStyle or Content.characters[actor.characterId].styles[1] or "demon"
    local move = {id = "basic", style = style, pattern = combo==3 and "thrust" or "slash", status = "none", damage = combo==3 and 15 or 10,
        cost = 0, cooldown = 0.42, windup = 0.12, recovery = 0.3, range = 9, width = 8, dash = 0, hits = 1, variant = "combo_"..combo}
    local ok, reason = self:cast(actor, move, direction)
    if ok then actor.combo = combo; actor.comboTime = now end
    return ok, reason
end

function Combat:guard(actor, enabled)
    local now = workspace:GetServerTimeNow()
    if not enabled then actor.blocking = false; return end
    if not actor.alive or (actor.storyLocked and not actor.storyCanBasic) or actor.model:GetAttribute("InCutscene") or actor.blocking or now < actor.busyUntil or now < actor.stunUntil then return end
    if now-(actor.lastGuard or 0) < 0.45 then return end
    actor.lastGuard = now; actor.blockStarted = now; actor.blocking = true
end

-- Draws or sheathes with the clip timing in AnimationIndex (generated from data/animations):
--   draw / draw_iai: busy for the whole clip; the sword joint moves to the hand when it ends.
--   sheathe_noto (out of combat) / sheathe_fast (within FastSheatheWindow of combat): busy only until Seat
--   (after the chiburi), so attacking or drawing again cancels the rest; the joint returns to the hip at
--   Release unless a newer weapon change superseded it.
-- style: "iai" for a draw chained into an attack, "noto"/"fast" to force a sheathe style.
-- Returns true and the clip duration when admitted.
function Combat:weapon(actor, drawn, style)
    local now = workspace:GetServerTimeNow()
    local model = actor.model
    if not actor.alive or (actor.storyLocked and not actor.storyCanWeapon) or model:GetAttribute("InCutscene") or not model:GetAttribute("HasSheath") or now < actor.busyUntil or now < actor.stunUntil then return false end
    if drawn == nil then drawn = not model:GetAttribute("WeaponDrawn") end
    local clip
    if drawn then clip = style == "iai" and "draw_iai" or "draw"
    else clip = "sheathe_"..(style or (now-actor.lastCombat < Config.FastSheatheWindow and "fast" or "noto")) end
    local entry = AnimationIndex[Profiles.clip(model:GetAttribute("CharacterId"), clip)]
    local duration = entry.length
    local swapAt = drawn and duration or entry.markers.Release
    actor.castToken += 1; actor.blocking = false
    actor.busyUntil = now+(drawn and duration or entry.markers.Seat)
    if drawn then actor.weaponSince = now end
    local token = Rig.setWeapon(model, drawn, drawn and "drawing" or "sheathing")
    model:SetAttribute("PoseVariant", nil); model:SetAttribute("PoseWindup", nil)
    model:SetAttribute("Pose", clip)
    model:SetAttribute("PoseStart", now); model:SetAttribute("PoseDuration", duration)
    task.delay(swapAt, function()
        if model.Parent and model:GetAttribute("WeaponChanged") == token then Rig.swapSword(model, drawn) end
    end)
    task.delay(duration, function()
        if model.Parent and model:GetAttribute("WeaponChanged") == token then model:SetAttribute("WeaponState", drawn and "drawn" or "sheathed") end
    end)
    return true, duration
end

local DASHES = {
    front = {distance = "DodgeDistance", iframes = "DodgeIFramesFront"},
    back = {distance = "DodgeDistanceBack", iframes = "DodgeIFramesBack"},
    left = {distance = "DodgeDistanceSide", iframes = "DodgeIFramesSide"},
    right = {distance = "DodgeDistanceSide", iframes = "DodgeIFramesSide"},
}

-- Directional dash. `facing` is where the dasher looks (the player's camera, or the actor's own look), so
-- A+Q is a sidestep even though default controls turn characters toward their movement. Front dashes turn
-- into the travel direction; side and back dashes face `facing` throughout. Returns the dash kind.
function Combat:dodge(actor, direction, facing)
    local now = workspace:GetServerTimeNow()
    if not self:validateMotion(actor) then return end
    if actor.model:GetAttribute("InCutscene") then return end
    if not actor.alive or now < actor.stunUntil or now < actor.busyUntil or (actor.cooldowns.dodge or 0)>now or actor.energy<Config.DodgeCost then return end
    local look = actor.root.CFrame.LookVector
    facing = facing or Vector3.new(look.X, 0, look.Z)
    if facing.Magnitude < 0.01 then facing = Vector3.new(0, 0, -1) end
    facing = facing.Unit
    local kind = MotionMath.dashDirection(facing.X, facing.Z, direction.X, direction.Z)
    local dash = DASHES[kind]
    actor.energy -= Config.DodgeCost; actor.cooldowns.dodge = now+Config.DodgeCooldown
    actor.busyUntil = now+Config.DodgeDuration; actor.invulnerableUntil = now+Config[dash.iframes]
    actor.blocking = false; actor.castToken += 1
    if kind ~= "front" then
        local origin = actor.root.Position
        actor.root.CFrame = CFrame.lookAt(origin, origin+facing)
    end
    actor.model:SetAttribute("Pose", "dash_"..kind)
    actor.model:SetAttribute("PoseStart", now); actor.model:SetAttribute("PoseDuration", Config.DodgeDuration)
    self:move(actor, direction, Config[dash.distance], Config.DodgeDuration, kind ~= "front")
    self:emit(actor, "dodge", {position = actor.root.Position, color = Content.characters[actor.characterId].color})
    return kind
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
        self:validateMotion(actor)
        if actor.motion then
            local m = actor.motion
            local traveled = (actor.root.Position-m.origin):Dot(m.direction)
            local hit = workspace:Blockcast(actor.root.CFrame, Vector3.new(3, 4, 2), m.direction*(m.speed*dt+0.6), m.parameters)
            if hit then self:stopMotion(actor, "collision: "..hit.Instance.Name)
            elseif now >= m.ends or traveled >= m.distance-0.05 then self:stopMotion(actor, "finished")
            elseif now < actor.stunUntil or actor.castToken ~= m.token then self:stopMotion(actor, "interrupted") end
        end
        -- Auto-sheathe: a drawn sword returns with the full noto after AutoSheatheSeconds without dealing or
        -- taking damage (Combat:weapon itself refuses during cutscenes and story weapon locks).
        if actor.model:GetAttribute("HasSheath") and actor.model:GetAttribute("WeaponDrawn") and not actor.blocking and not actor.motion
            and now >= actor.busyUntil and now >= actor.stunUntil and now-math.max(actor.lastCombat, actor.weaponSince) > Config.AutoSheatheSeconds then
            self:weapon(actor, false, "noto")
        end
        local stunned = now<actor.stunUntil
        local frozen = stunned or actor.motion ~= nil or (actor.motionReleaseAt and now<actor.motionReleaseAt) or actor.model:GetAttribute("InCutscene")
        actor.humanoid.WalkSpeed = frozen and 0 or actor.blocking and Config.GuardSpeed or actor.status.chill and 14 or Config.WalkSpeed
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
