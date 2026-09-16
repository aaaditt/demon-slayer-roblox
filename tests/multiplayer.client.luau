-- Injected only into the test place; never included in the shipping Rojo tree.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local LogService=game:GetService("LogService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local player=Players.LocalPlayer
local bridge=ReplicatedStorage:WaitForChild("RuntimeTestBridge")
local failures={}
LogService.MessageOut:Connect(function(message,kind)
    if kind==Enum.MessageType.MessageError and (string.find(message,"Client") or string.find(message,"Wisteria")) then table.insert(failures,message) end
end)
bridge.OnClientEvent:Connect(function(token,command,args)
    local ok,result=pcall(function()
        if command=="ready" then
            local gui=player:WaitForChild("PlayerGui"):WaitForChild("WisteriaUI",15)
            assert(gui,"client GUI missing")
            task.wait(1)
            assert(workspace.CurrentCamera.CameraSubject==player.Character:FindFirstChildOfClass("Humanoid"),"camera not attached")
            assert(#failures==0,table.concat(failures,"\n"))
            return {gui=true,camera=true,position=player.Character.HumanoidRootPart.Position}
        elseif command=="action" then
            ReplicatedStorage.Network.Action:FireServer(args.name,args.payload)
            task.wait(args.wait or 0.3)
            return true
        elseif command=="move" then
            local controls=require(player.PlayerScripts:WaitForChild("PlayerModule")):GetControls()
            controls:Disable()
            local humanoid=player.Character:FindFirstChildOfClass("Humanoid")
            local start=player.Character.HumanoidRootPart.Position
            local untilTime=os.clock()+0.6
            repeat humanoid:Move(Vector3.new(1,0,0),false);RunService.RenderStepped:Wait() until os.clock()>=untilTime
            humanoid:Move(Vector3.zero);controls:Enable()
            return (player.Character.HumanoidRootPart.Position-start).Magnitude
        elseif command=="ui" then
            local gui=player.PlayerGui:FindFirstChild("WisteriaUI")
            assert(gui,"missing UI")
            local labels=0
            for _,item in ipairs(gui:GetDescendants()) do if item:IsA("TextLabel") or item:IsA("TextButton") then labels+=1 end end
            assert(labels>30,"UI did not populate")
            assert(#failures==0,table.concat(failures,"\n"))
            return labels
        elseif command=="tabs" then
            local input=game:GetService("UserInputService"):CreateVirtualInput()
            local gui=player.PlayerGui.WisteriaUI
            for _,tab in ipairs({"Characters","Techniques","Codex","Settings","Journey"}) do
                local button
                for _,item in ipairs(gui:GetDescendants()) do if item:IsA("TextButton") and item.Text==tab then button=item;break end end
                assert(button,"tab button missing: "..tab)
                local function opened()
                    for _,item in ipairs(gui:GetDescendants()) do if item:IsA("TextLabel") and string.find(item.Text,string.upper(tab).."  /",1,true) then return true end end
                    return false
                end
                local center=button.AbsolutePosition+button.AbsoluteSize/2
                for attempt=1,2 do
                    local point=center+(attempt==2 and game:GetService("GuiService"):GetGuiInset() or Vector2.zero)
                    input:SendMousePosition(point)
                    input:SendMouseButton(point,Enum.UserInputType.MouseButton1,true,0)
                    task.wait(0.1)
                    input:SendMouseButton(point,Enum.UserInputType.MouseButton1,false,0)
                    task.wait(0.4)
                    if opened() then break end
                end
                assert(opened(),"tab click failed: "..tab)
            end
            assert(#failures==0,table.concat(failures,"\n"))
            return true
        elseif command=="visual" then
            local input=game:GetService("UserInputService"):CreateVirtualInput()
            input:SendKey(true,Enum.KeyCode.M,false);task.wait(0.1);input:SendKey(false,Enum.KeyCode.M,false)
            local root=player.Character.HumanoidRootPart
            workspace.CurrentCamera.CameraType=Enum.CameraType.Scriptable
            workspace.CurrentCamera.CFrame=CFrame.lookAt(root.Position+Vector3.new(18,14,26),root.Position+Vector3.new(0,2,-12))
            return true
        end
        error("Unknown runtime test command")
    end)
    bridge:FireServer(token,ok,result)
end)
