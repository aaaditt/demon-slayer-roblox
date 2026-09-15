local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Animator = {}
local rigs = {}

local function register(model)
    if not model:IsA("Model") then return end
    local torso = model:FindFirstChild("Torso")
    local root = model:FindFirstChild("HumanoidRootPart")
    if not torso or not root then return end
    local motors = {}
    for _, item in ipairs(model:GetDescendants()) do
        if item:IsA("Motor6D") then motors[item.Name] = item end
    end
    rigs[model] = {motors=motors,root=root,phase=math.random()*10}
end

function Animator.start()
    local actors=workspace:WaitForChild("Actors")
    actors.ChildAdded:Connect(register)
    actors.ChildRemoved:Connect(function(model) rigs[model]=nil end)
    for _, model in ipairs(actors:GetChildren()) do register(model) end
    RunService.PreSimulation:Connect(function()
        local now=workspace:GetServerTimeNow()
        local localCharacter=Players.LocalPlayer.Character
        local localRoot=localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")
        for model, rig in pairs(rigs) do
            if not rig.root.Parent then rigs[model]=nil; continue end
            if localRoot and (rig.root.Position-localRoot.Position).Magnitude>230 then continue end
            local motors=rig.motors
            local velocity=rig.root.AssemblyLinearVelocity
            local speed=Vector3.new(velocity.X,0,velocity.Z).Magnitude
            local walk=math.sin(now*10+rig.phase)*math.min(speed/22,1)*0.7
            local right,left,lean,twist=-walk,walk,0,0
            local pose=model:GetAttribute("Pose")
            local elapsed=now-(model:GetAttribute("PoseStart") or 0)
            local duration=model:GetAttribute("PoseDuration") or 0
            if model:GetAttribute("Dead") then
                lean=1.2; right=-1; left=-1
            elseif elapsed<duration and elapsed>=0 then
                local progress=math.clamp(elapsed/math.max(duration,0.01),0,1)
                local swing=math.sin(progress*math.pi)
                if pose=="guard" or pose=="heal" then right=-1.4; left=-1.2
                elseif pose=="thrust" or pose=="projectile" then right=-1.6*swing; left=-0.6; lean=0.2*swing
                elseif pose=="spin" or pose=="burst" then right=-1.4; left=-1.4; twist=progress*math.pi*2
                elseif pose=="barrage" then right=-1.2-math.sin(progress*math.pi*8)*0.5; left=-1.2+math.sin(progress*math.pi*8)*0.5
                elseif pose=="dash" or pose=="evade" then right=-0.6; left=0.7; lean=0.5
                else right=-2.1+swing*2.5; left=-0.5; twist=-0.65+swing*1.3 end
            elseif model:GetAttribute("Blocking") then right=-1.5; left=-1.4; lean=0.13 end
            local function set(name, cf) if motors[name] then motors[name].Transform=cf end end
            set("Right Shoulder",CFrame.Angles(right,0,0.08))
            set("Left Shoulder",CFrame.Angles(left,0,-0.08))
            set("Right Hip",CFrame.Angles(walk,0,0))
            set("Left Hip",CFrame.Angles(-walk,0,0))
            set("RootJoint",CFrame.new(0,math.sin(now*2+rig.phase)*0.025,0)*CFrame.Angles(lean,twist,0))
            set("Neck",CFrame.Angles(-lean*0.6,-twist*0.2,0))
        end
    end)
end

return Animator
