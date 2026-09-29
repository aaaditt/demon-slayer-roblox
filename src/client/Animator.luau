-- Client character animation. Every observing client animates every rig locally from replicated state
-- (Pose/PoseStart/PoseDuration, WeaponDrawn, Humanoid state). Output goes to Motor6D.Transform, the same
-- channel Roblox's Animator uses; C0 stays at the rig's rest pose.
--
-- Layers, per joint: base (locomotion clips cross-faded by state) -> action (clip or legacy pose, faded in
-- and out) -> additive overlay (turn lean). Poses without an authored clip fall back to the legacy procedural
-- pose table, so clips can be added one at a time (docs/ANIMATION.md).
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MotionMath = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("MotionMath"))
local Motion = require(script.Parent.Motion)
local Animator = {}
local rigs = {}
local watched = setmetatable({}, {__mode="k"})

local BODY = {"Root","Waist","Neck","RightShoulder","LeftShoulder","RightElbow","LeftElbow","RightWrist","LeftWrist",
    "RightHip","LeftHip","RightKnee","LeftKnee","RightAnkle","LeftAnkle"}
local BASE_FADE, ACTION_IN, ACTION_OUT = 0.15, 0.08, 0.12
local IDLE_MAX, WALK_MAX, HEAVY_FALL = 22*0.08, 12, 25
-- Joints a "lower" drawnMask clip may drive while the sword is out; the upper body keeps its stance.
local LOWER = {Root=true,RightHip=true,LeftHip=true,RightKnee=true,LeftKnee=true,RightAnkle=true,LeftAnkle=true}
local STRIKES = {slash=true,thrust=true,spin=true,barrage=true}

local function register(model)
    if rigs[model] or not model:IsA("Model") then return end
    local root = model:FindFirstChild("HumanoidRootPart")
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not model:FindFirstChild("LowerTorso") or not root or not humanoid then return end
    local motors = {}
    for _, item in ipairs(model:GetDescendants()) do
        if item:IsA("Motor6D") then motors[item.Name] = item end
    end
    for _, name in ipairs(BODY) do if not motors[name] then return end end
    rigs[model] = {motors=motors,root=root,humanoid=humanoid,phase=0,air=false,landed=0,landDuration=0.18,
        legacy={},legacyBase={},extras={},base={},actions={},roll=0,yaw=nil}
    model:SetAttribute("MotionReady", true) -- Client diagnostic, never trusted for gameplay.
end

-- Registers a rig without the workspace watchers and returns its animation state (engine tests/benchmarks).
function Animator.track(model)
    register(model)
    return rigs[model]
end

local function watch(model)
    if not model:IsA("Model") or watched[model] then return end
    watched[model] = true
    register(model)
    local connection
    connection = model.DescendantAdded:Connect(function(item)
        register(model)
        if rigs[model] and item:IsA("Motor6D") then rigs[model].motors[item.Name] = item end
    end)
    model.Destroying:Once(function() connection:Disconnect(); rigs[model]=nil end)
end

-- Legacy procedural poses as joint -> CFrame tables: `base` is locomotion only, `full` adds action overrides.
local function legacyPose(rig, model, now, dt, velocity, speed, pose, elapsed, duration, active)
    local amount=math.clamp(speed/22,0,1)
    rig.phase += math.min(dt,0.1)*(2+speed*0.46)
    local stride=math.sin(rig.phase)*amount
    local v={right=-stride*0.9,left=stride*0.9,rh=stride*0.95,lh=-stride*0.95,lean=amount*0.13,twist=0,roll=0,
        bob=math.cos(rig.phase*2)*amount*0.08+math.sin(now*2)*0.025,draw=false}
    local motion=amount>0.08 and "run" or "idle"
    if rig.air then
        local rising=velocity.Y>1
        motion=rising and "jump" or "fall"
        v.right=rising and -0.65 or -0.3;v.left=v.right
        v.rh=rising and -0.8 or 0.25;v.lh=rising and 0.45 or -0.3
        v.lean=rising and -0.1 or 0.16;v.bob=0
    elseif now-rig.landed<rig.landDuration then
        local weight=1-(now-rig.landed)/rig.landDuration
        v.bob=-0.2*weight;v.lean=0.28*weight;v.rh=-0.2*weight;v.lh=v.rh;motion="land"
    end
    local base=table.clone(v)
    if model:GetAttribute("Dead") then
        v.lean=1.2;v.right=-1;v.left=-1;motion="dead"
    elseif active then
        local p=math.clamp(elapsed/math.max(duration,0.01),0,1)
        local swing=math.sin(p*math.pi)
        motion=pose
        if pose=="draw" or pose=="sheathe" then
            v.right=-0.8;v.left=-0.35;v.twist=-0.25*swing;v.draw=pose=="draw"
        elseif pose=="guard" or pose=="heal" then v.right=-1.4;v.left=-1.2
        elseif pose=="thrust" or pose=="projectile" then v.right=-1.6*swing;v.left=-0.6;v.lean=0.2*swing
        elseif pose=="spin" or pose=="burst" then v.right=-1.4;v.left=-1.4;v.twist=p*math.pi*2
        elseif pose=="barrage" then v.right=-1.2-math.sin(p*math.pi*8)*0.5;v.left=-1.2+math.sin(p*math.pi*8)*0.5
        elseif pose=="dash" or pose=="evade" or string.sub(pose,1,5)=="dash_" then v.right=0.85;v.left=0.75;v.lean=0.65;v.rh=-0.8;v.lh=0.8;v.bob=-0.2
        elseif pose=="kneel" then v.lean=0.45;v.rh=-0.95;v.lh=-0.8;v.right=-0.6;v.left=-0.6;v.bob=-0.5
        elseif pose=="embrace" then v.right=-1.35;v.left=-1.35;v.lean=0.08
        elseif pose=="kick" then v.rh=-1.8*swing;v.lh=0.3;v.lean=-0.25*swing;v.right=-0.9;v.left=-1.2;v.twist=0.3*swing
        elseif pose=="recoil" then v.lean=-0.45*swing;v.right=-0.6;v.left=-0.8;v.rh=0.3
        elseif pose=="emerge" then v.lean=0.4*(1-p);v.right=-1.1;v.left=-1.1;v.rh=-0.5*(1-p);v.lh=-0.5*(1-p)
        else v.right=-2.1+swing*2.5;v.left=-0.5;v.twist=-0.65+swing*1.3 end
    elseif model:GetAttribute("Blocking") then v.right=-1.5;v.left=-1.4;v.lean=0.13;motion="guard" end
    if model:GetAttribute("Carrying") then v.right=-1.2;v.left=-1.2;v.lean+=0.12 end
    local function joints(x)
        return {
            RightShoulder=CFrame.Angles(x.right,0,x.draw and -0.65 or 0.08),LeftShoulder=CFrame.Angles(x.left,0,-0.08),
            RightHip=CFrame.Angles(x.rh,0,0),LeftHip=CFrame.Angles(x.lh,0,0),
            RightKnee=CFrame.Angles(math.max(0,x.rh)*-1.1,0,0),LeftKnee=CFrame.Angles(math.max(0,x.lh)*-1.1,0,0),
            RightElbow=CFrame.Angles(0.3,0,0),LeftElbow=CFrame.Angles(0.3,0,0),
            Root=CFrame.new(0,x.bob,0)*CFrame.Angles(x.lean,x.twist,x.roll),Neck=CFrame.Angles(-x.lean*0.6,-x.twist*0.2,0),
        }
    end
    return joints(base), joints(v), motion
end

-- Exponentially smooths procedural targets; clip layers blend by weight instead.
local function smooth(store, targets, alpha)
    for _, name in ipairs(BODY) do
        local target=targets[name] or CFrame.identity
        store[name]=store[name] and store[name]:Lerp(target,alpha) or target
    end
end

-- Most specific authored clip for a locomotion state: drawn variant, then sheathed, then shared.
local function baseClip(state, drawn)
    return (drawn and Motion.clip("base/"..state.."_drawn")) or Motion.clip("base/"..state.."_sheathed") or Motion.clip("base/"..state)
end

local function actionClip(model, pose)
    local variant=model:GetAttribute("PoseVariant")
    return (variant and Motion.clip("base/"..variant)) or Motion.clip("base/"..pose)
end

-- Markers of the live action clip. Grip/Seat start the procedural sword path (the blocky hand cannot reach
-- the left hip, so the sword slides out of or into the saya along its own axis and is carried between hip
-- and hand); Release returns it to the hip joint. Joint changes here are local until the server swap arrives.
local function markerHandler(model, rig, action)
    return function(marker)
        local hip=model:FindFirstChild("LowerTorso") and model.LowerTorso:FindFirstChild("SwordHip")
        local hand=model:FindFirstChild("RightHand") and model.RightHand:FindFirstChild("SwordHand")
        local tsuka=model:FindFirstChild("Katana") and model.Katana:FindFirstChild("Tsuka")
        local clip=action.clip
        if marker.name=="Grip" and hip and hand and tsuka then
            local from=model.LowerTorso.CFrame:ToObjectSpace(tsuka.CFrame)
            hip.Enabled=false;hand.Enabled=true
            rig.swordPath={kind="draw",key=action.key,from=from,t0=marker.t,clear=clip.markerAt.Clear or marker.t,t1=clip.length}
        elseif marker.name=="Seat" and hip and hand then
            hip.Enabled=false;hand.Enabled=true
            rig.swordPath={kind="sheathe",key=action.key,t0=marker.t,t1=clip.markerAt.Release or clip.length}
        elseif marker.name=="Release" and hip and hand then
            hand.Transform=CFrame.identity;hand.Enabled=false;hip.Enabled=true
            rig.swordPath=nil;rig.swordHold={inHand=false,untilTime=workspace:GetServerTimeNow()+0.8}
        elseif marker.name=="TrailOn" then rig.trail=true
        elseif marker.name=="TrailOff" then rig.trail=false end
    end
end

-- Drives SwordHand.Transform along the active sword path, or reconciles the joints with the server's
-- SwordInHand once no path is active. Part1 = Part0*C0*Transform*C1^-1, so any desired sword frame is
-- reachable through the hand joint.
local function swordPath(model, rig, now)
    local hip=model.LowerTorso:FindFirstChild("SwordHip")
    local grip=model:FindFirstChild("RightHand") and model.RightHand:FindFirstChild("SwordHand")
    if not hip or not grip or not hip.Part0 or not grip.Part0 then return end
    local path=rig.swordPath
    local top=rig.actions[#rig.actions]
    if path and (not top or top.key~=path.key) then
        -- Superseded (a dash, another action): hold the state the path was heading to until the server agrees.
        rig.swordHold={inHand=path.kind=="draw",untilTime=now+0.8}
        rig.swordPath=nil;path=nil
    end
    if path then
        local t=top.time
        local held=grip.Part0.CFrame*grip.C0*grip.C1:Inverse()
        local length=model:GetAttribute("SwordDrawLength") or 3.5
        local desired
        if path.kind=="draw" then
            -- Slide out along the blade axis from the grip, then sweep into the hand after the blade clears.
            local u=math.clamp((t-path.t0)/math.max(path.t1-path.t0,1e-3),0,1)
            local b=math.clamp((t-path.clear)/math.max(path.t1-path.clear,1e-3),0,1)
            local slid=model.LowerTorso.CFrame*path.from*CFrame.new(0,0,length*MotionMath.ease("CubicV2","Out",u))
            desired=slid:Lerp(held,MotionMath.ease("CubicV2","InOut",b))
        else
            -- First half: carry the blade from the hand to the saya line; second half: slide it in and seat it.
            local mid=(path.t0+path.t1)/2
            local b=math.clamp((t-path.t0)/math.max(mid-path.t0,1e-3),0,1)
            local s=math.clamp((t-mid)/math.max(path.t1-mid,1e-3),0,1)
            local seat=hip.Part0.CFrame*hip.C0*hip.C1:Inverse()
            desired=held:Lerp(seat*CFrame.new(0,0,length*(1-MotionMath.ease("CubicV2","In",s))),MotionMath.ease("CubicV2","InOut",b))
        end
        grip.Transform=(grip.Part0.CFrame*grip.C0):Inverse()*desired*grip.C1
        return
    end
    grip.Transform=CFrame.identity
    local inHand=model:GetAttribute("SwordInHand")
    local hold=rig.swordHold
    if hold and now<hold.untilTime and inHand~=hold.inHand then inHand=hold.inHand else rig.swordHold=nil end
    if inHand~=nil then hip.Enabled=not inHand;grip.Enabled=inHand end
end

-- Per-joint weighted blend of the base sources (clips, or the smoothed legacy locomotion pose).
local function blendBase(rig, partOf, out)
    local samples={}
    for _, source in ipairs(rig.base) do
        if source.weight>0 and source.clip then samples[source]=Motion.sample(source.clip,source.time,{}) end
    end
    for _, joint in ipairs(BODY) do
        local acc, total = nil, 0
        for _, source in ipairs(rig.base) do
            if source.weight>0 then
                local cf=samples[source] and samples[source][partOf[joint]] or rig.legacyBase[joint]
                total+=source.weight
                acc=acc and acc:Lerp(cf,source.weight/total) or cf
            end
        end
        out[joint]=acc or rig.legacyBase[joint]
    end
end

function Animator.step(model, rig, now, dt)
    local velocity=rig.root.AssemblyLinearVelocity
    local speed=Vector3.new(velocity.X,0,velocity.Z).Magnitude
    local state=rig.humanoid:GetState()
    local air=state==Enum.HumanoidStateType.Jumping or state==Enum.HumanoidStateType.Freefall
    local height=rig.root.Position.Y
    if air then rig.peak=math.max(rig.peak or height,height) end
    if rig.air and not air then
        -- Falls from higher than HEAVY_FALL studs land in the deeper, longer crouch.
        rig.landHeavy=(rig.peak or height)-height>HEAVY_FALL
        rig.landed=now;rig.landDuration=rig.landHeavy and 0.35 or 0.18;rig.peak=nil
    end
    rig.air=air
    local pose=model:GetAttribute("Pose")
    local elapsed=now-(model:GetAttribute("PoseStart") or 0)
    local duration=model:GetAttribute("PoseDuration") or 0
    local active=pose~=nil and elapsed>=0 and elapsed<duration
    local drawn=model:GetAttribute("HasSheath") and model:GetAttribute("WeaponDrawn") or false
    local legacyBase, legacyFull=legacyPose(rig,model,now,dt,velocity,speed,pose,elapsed,duration,active)
    local alpha=1-math.exp(-20*math.min(dt,0.1))
    smooth(rig.legacyBase,legacyBase,alpha);smooth(rig.legacy,legacyFull,alpha)
    local partOf={}
    for _, joint in ipairs(BODY) do partOf[joint]=rig.motors[joint].Part1 and rig.motors[joint].Part1.Name or joint end

    -- Base layer: the locomotion state's clip if authored, otherwise legacy; cross-faded on change.
    local landing=now-rig.landed<rig.landDuration
    local locomotion=air and (velocity.Y>1 and "jump" or "fall") or landing and (rig.landHeavy and "land_heavy" or "land_light")
        or speed>WALK_MAX and "run" or speed>IDLE_MAX and "walk" or "idle"
    local clip=baseClip(locomotion,drawn)
    local key=clip and clip.name or "legacy"
    if key~=rig.baseKey then
        -- One-shot clips (jump, landings) restart when they become current again.
        for _, source in ipairs(rig.base) do
            if source.key==key and source.clip and not source.clip.entry.loop then source.time=0 end
        end
        rig.baseKey=key
    end
    local found=false
    for i=#rig.base,1,-1 do
        local source=rig.base[i]
        source.weight=MotionMath.approach(source.weight,source.key==key and 1 or 0,dt,BASE_FADE)
        if source.key==key then found=true elseif source.weight<=0 then table.remove(rig.base,i) end
    end
    if not found then table.insert(rig.base,{key=key,clip=clip,time=0,weight=#rig.base==0 and 1 or 0}) end
    for _, source in ipairs(rig.base) do
        if source.clip then
            local entry=source.clip.entry
            -- Stride matching: playback follows ground speed relative to the speed the cycle was authored at.
            local rate=entry.speed>0 and math.clamp(speed/entry.speed,0.4,1.6) or 1
            source.time+=dt*rate
            if entry.loop and source.clip.length>0 then source.time%=source.clip.length else source.time=math.min(source.time,source.clip.length) end
        end
    end
    local result={}
    blendBase(rig,partOf,result)

    -- Action layer: server poses, blocking, carrying and death. Clip joints only, or the full legacy pose.
    local dead=model:GetAttribute("Dead")
    local wanting=dead or active or model:GetAttribute("Blocking") or model:GetAttribute("Carrying")
    -- A stack: a new action fades in over the previous one while that fades out, so clip-to-clip chains
    -- (combo 1 -> combo 2) blend instead of popping.
    local blocking=not active and not dead and model:GetAttribute("Blocking")
    local wantClip=active and not dead and actionClip(model,pose) or blocking and Motion.clip("base/guard_hold") or nil
    local wantKey=wanting and (wantClip and wantClip.name.."@"..(blocking and "block" or tostring(model:GetAttribute("PoseStart"))) or "legacy") or nil
    local top=rig.actions[#rig.actions]
    if wantKey and (not top or top.key~=wantKey) then
        top={key=wantKey,clip=wantClip,weight=0,time=0}
        table.insert(rig.actions,top);rig.trail=false
    end
    for i=#rig.actions,1,-1 do
        local action=rig.actions[i]
        local live=action.key==wantKey
        action.weight=MotionMath.approach(action.weight,live and 1 or 0,dt,live and ACTION_IN or ACTION_OUT)
        if action.weight<=0 and not live then table.remove(rig.actions,i) end
    end
    for _, action in ipairs(rig.actions) do
        if action.clip and action.key==wantKey then
            local previous=action.time
            if blocking then
                -- Held guard is not a timed server pose: loop on local time.
                action.time=(action.time+dt)%math.max(action.clip.length,1e-3)
            else
                action.time=MotionMath.actionTime(action.clip.entry,elapsed,duration,model:GetAttribute("PoseWindup"))
            end
            Motion.markers(action.clip,previous,action.time,markerHandler(model,rig,action))
        end
        local sample=action.clip and Motion.sample(action.clip,action.time,{})
        local lowerOnly=drawn and action.clip and action.clip.entry.drawnMask=="lower"
        for _, joint in ipairs(BODY) do
            local cf
            if sample then cf=sample[partOf[joint]] else cf=rig.legacy[joint] end
            if cf and (not lowerOnly or LOWER[joint]) then result[joint]=result[joint]:Lerp(cf,action.weight) end
        end
    end
    local action=rig.actions[#rig.actions]

    -- Additive overlay: lean into turns while moving on foot.
    local look=rig.root.CFrame.LookVector
    local yaw=math.atan2(-look.X,-look.Z)
    local rate=rig.yaw and math.clamp(((yaw-rig.yaw+math.pi)%(2*math.pi)-math.pi)/math.max(dt,1/240),-12,12) or 0
    rig.yaw=yaw
    local target=(not air and not wanting) and math.clamp(rate*0.04,-0.21,0.21)*math.clamp(speed/22,0,1) or 0
    rig.roll+=(target-rig.roll)*alpha
    result.Root=result.Root*CFrame.Angles(0,0,rig.roll)

    for _, joint in ipairs(BODY) do rig.motors[joint].Transform=result[joint] end
    -- Both landing clips report "land" for diagnostics and tests.
    local motionState=string.sub(locomotion,1,5)=="land_" and "land" or locomotion
    model:SetAttribute("MotionState",dead and "dead" or active and pose or (model:GetAttribute("Blocking") and "guard") or motionState)
    model:SetAttribute("MotionClip",key)

    -- Non-humanoid joints keep small procedural drivers.
    local function extra(name,cf)
        local m=rig.motors[name]
        if m then rig.extras[name]=rig.extras[name] and rig.extras[name]:Lerp(cf,alpha) or cf;m.Transform=rig.extras[name] end
    end
    if model:GetAttribute("HandDemon") then
        local bossPhase=model:GetAttribute("BossPhase")
        for i=1,6 do
            local side=i%2==0 and 1 or -1
            local reach=bossPhase=="windup" and -1.5 or bossPhase=="exposed" and 0.3 or -0.6
            extra("HandArm"..i,CFrame.Angles(reach+math.sin(now*3+i)*0.07,side*0.2,bossPhase=="exposed" and side*0.65 or 0))
        end
    end
    extra("CrowLeft",CFrame.Angles(0,0,math.sin(now*3)*0.12))
    extra("CrowRight",CFrame.Angles(0,0,-math.sin(now*3)*0.12))

    if model:FindFirstChild("LowerTorso") then swordPath(model,rig,now) end

    -- Clips with TrailOn/TrailOff markers drive the trail; otherwise it shows during drawn legacy strikes.
    local katana=model:FindFirstChild("Katana")
    local trail=katana and katana:FindFirstChild("Blade") and katana.Blade:FindFirstChild("SwordTrail")
    if trail then
        local marked=action and action.clip and #action.clip.markers>0
        trail.Enabled=drawn and active and (marked and rig.trail==true or not marked and STRIKES[pose]==true) or false
    end
end

function Animator.start()
    local actors=workspace:WaitForChild("Actors")
    actors.ChildAdded:Connect(watch)
    for _,model in ipairs(actors:GetChildren()) do watch(model) end
    local function playerAdded(player)
        player.CharacterAdded:Connect(watch)
        if player.Character then watch(player.Character) end
    end
    Players.PlayerAdded:Connect(playerAdded)
    for _,player in ipairs(Players:GetPlayers()) do playerAdded(player) end
    -- PreSimulation runs after Roblox's own animation step, so these Transforms are what physics renders.
    RunService.PreSimulation:Connect(function(dt)
        local now=workspace:GetServerTimeNow()
        local character=Players.LocalPlayer.Character
        local localRoot=character and character:FindFirstChild("HumanoidRootPart")
        for model,rig in pairs(rigs) do
            if not rig.root:IsDescendantOf(workspace) then continue end
            if localRoot and (rig.root.Position-localRoot.Position).Magnitude>250 then continue end
            Animator.step(model,rig,now,dt)
        end
    end)
end

return Animator
