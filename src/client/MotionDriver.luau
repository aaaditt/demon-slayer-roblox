-- Drive only a server-created constraint on the local character. These hints are never trusted by
-- the server: Combat retains its own origin, corridor, speed, deadline and swept collision checks.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local MotionDriver={}

function MotionDriver.start()
    RunService.PreSimulation:Connect(function(dt)
        local character=Players.LocalPlayer.Character
        local root=character and character:FindFirstChild("HumanoidRootPart")
        local velocity=root and root:FindFirstChild("DashVelocity")
        if not velocity or not velocity:IsA("LinearVelocity") or not velocity:GetAttribute("ClientDriven") then return end
        local origin=velocity:GetAttribute("Origin")
        local direction=velocity:GetAttribute("Direction")
        local distance=velocity:GetAttribute("Distance")
        local speed=velocity:GetAttribute("Speed")
        local expires=velocity:GetAttribute("Expires")
        if typeof(origin)~="Vector3" or typeof(direction)~="Vector3" or type(distance)~="number" or type(speed)~="number" or type(expires)~="number" then return end
        local remaining=distance-(root.Position-origin):Dot(direction)
        local rate=workspace:GetServerTimeNow()<expires and math.min(speed,math.max(0,remaining)/math.max(dt,1/240)) or 0
        velocity.PlaneVelocity=Vector2.new(direction.X,direction.Z)*rate
    end)
end

return MotionDriver
