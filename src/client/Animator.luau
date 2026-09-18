local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Animator = {}
local rigs = {}
local watched = setmetatable({}, {__mode="k"})

local function register(model)
    if rigs[model] or not model:IsA("Model") then return end
    local torso = model:FindFirstChild("Torso")
    local root = model:FindFirstChild("HumanoidRootPart")
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not torso or not root or not humanoid then return end
    local motors = {}
    for _, item in ipairs(model:GetDescendants()) do
        if item:IsA("Motor6D") then motors[item.Name] = item end
    end
    if not motors["Right Shoulder"] or not motors["Left Hip"] or not motors.RootJoint then return end
    rigs[model] = {motors=motors,root=root,torso=torso,humanoid=humanoid,phase=0,air=false,landed=0}
    model:SetAttribute("MotionReady", true) -- Client diagnostic, never trusted for gameplay.
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
    RunService.PreSimulation:Connect(function(dt)
        local now=workspace:GetServerTimeNow()
        local character=Players.LocalPlayer.Character
        local localRoot=character and character:FindFirstChild("HumanoidRootPart")
        for model,rig in pairs(rigs) do
            if not rig.root:IsDescendantOf(workspace) then continue end
            if localRoot and (rig.root.Position-localRoot.Position).Magnitude>250 then continue end
            local velocity=rig.root.AssemblyLinearVelocity
            local speed=Vector3.new(velocity.X,0,velocity.Z).Magnitude
            local amount=math.clamp(speed/22,0,1)
            rig.phase += math.min(dt,0.1)*(2+speed*0.46)
            local stride=math.sin(rig.phase)*amount
            local right,left=-stride*0.9,stride*0.9
            local rh,lh=stride*0.95,-stride*0.95
            local lean,twist,roll=amount*0.13,0,0
            local bob=math.cos(rig.phase*2)*amount*0.08+math.sin(now*2)*0.025
            local state=rig.humanoid:GetState()
            local air=state==Enum.HumanoidStateType.Jumping or state==Enum.HumanoidStateType.Freefall
            if rig.air and not air then rig.landed=now end
            rig.air=air
            local motion=amount>0.08 and "run" or "idle"
            if air then
                local rising=velocity.Y>1
                motion=rising and "jump" or "fall"
                right=rising and -0.65 or -0.3;left=right
                rh=rising and -0.8 or 0.25;lh=rising and 0.45 or -0.3
                lean=rising and -0.1 or 0.16;bob=0
            elseif now-rig.landed<0.18 then
                local weight=1-(now-rig.landed)/0.18
                bob=-0.2*weight;lean=0.28*weight;rh=-0.2*weight;lh=rh;motion="land"
            end
            local pose=model:GetAttribute("Pose")
            local elapsed=now-(model:GetAttribute("PoseStart") or 0)
            local duration=model:GetAttribute("PoseDuration") or 0
            local active=elapsed>=0 and elapsed<duration
            if model:GetAttribute("Dead") then
                lean=1.2;right=-1;left=-1;motion="dead"
            elseif active then
                local p=math.clamp(elapsed/math.max(duration,0.01),0,1)
                local swing=math.sin(p*math.pi)
                motion=pose
                if pose=="draw" or pose=="sheathe" then
                    right=-0.8;left=-0.35;twist=-0.25*swing
                elseif pose=="guard" or pose=="heal" then right=-1.4;left=-1.2
                elseif pose=="thrust" or pose=="projectile" then right=-1.6*swing;left=-0.6;lean=0.2*swing
                elseif pose=="spin" or pose=="burst" then right=-1.4;left=-1.4;twist=p*math.pi*2
                elseif pose=="barrage" then right=-1.2-math.sin(p*math.pi*8)*0.5;left=-1.2+math.sin(p*math.pi*8)*0.5
                elseif pose=="dash" or pose=="evade" then right=0.85;left=0.75;lean=0.65;rh=-0.8;lh=0.8;bob=-0.2
                elseif pose=="kneel" then lean=0.45;rh=-0.95;lh=-0.8;right=-0.6;left=-0.6;bob=-0.5
                else right=-2.1+swing*2.5;left=-0.5;twist=-0.65+swing*1.3 end
            elseif model:GetAttribute("Blocking") then right=-1.5;left=-1.4;lean=0.13;motion="guard" end
            if model:GetAttribute("Carrying") then right=-1.2;left=-1.2;lean+=0.12 end
            local blend=1-math.exp(-20*math.min(dt,0.1))
            local function set(name,cf)
                local m=rig.motors[name]
                if m then
                    -- C0 is intentional: default Animate/Animator cannot overwrite these custom rigs.
                    if not rig[name] then rig[name]=m.C0 end
                    m.C0=m.C0:Lerp(rig[name]*cf,blend)
                end
            end
            set("Right Shoulder",CFrame.Angles(right,0,pose=="draw" and active and -0.65 or 0.08))
            set("Left Shoulder",CFrame.Angles(left,0,-0.08))
            set("Right Hip",CFrame.Angles(rh,0,0));set("Left Hip",CFrame.Angles(lh,0,0))
            set("RootJoint",CFrame.new(0,bob,0)*CFrame.Angles(lean,twist,roll))
            set("Neck",CFrame.Angles(-lean*0.6,-twist*0.2,0))
            local grip=rig.motors.WeaponGrip
            if grip and model:FindFirstChild("Right Arm") then
                local drawn=model:GetAttribute("HasSheath") and model:GetAttribute("WeaponDrawn")
                local sheath=CFrame.new(-1.05,-0.8,0.3)*CFrame.Angles(0,math.pi, -0.18)
                local hand=rig.torso.CFrame:ToObjectSpace(model["Right Arm"].CFrame*CFrame.new(0,-0.9,-0.15))
                grip.C0=grip.C0:Lerp(drawn and hand or sheath,1-math.exp(-14*math.min(dt,0.1)))
                local blade=model:FindFirstChild("Blade")
                if blade then
                    blade.LocalTransparencyModifier=drawn and 0 or 1
                    local trail=blade:FindFirstChild("SwordTrail")
                    if trail then trail.Enabled=drawn and active and (pose=="slash" or pose=="thrust" or pose=="spin" or pose=="barrage") end
                end
            end
            model:SetAttribute("MotionState",motion)
        end
    end)
end

return Animator
