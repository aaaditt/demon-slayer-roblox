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
        elseif command=="animation" then
            local controls=require(player.PlayerScripts:WaitForChild("PlayerModule")):GetControls()
            controls:Disable()
            local model=player.Character
            local humanoid=model:FindFirstChildOfClass("Humanoid")
            local r15=model:GetAttribute("RigKind")=="R15"
            local hip=r15 and model.RightUpperLeg.RightHip or model.Torso["Right Hip"]
            local function pose() return r15 and hip.Transform or hip.C0 end
            local original=pose()
            local changed=false
            local deadline=os.clock()+0.5
            repeat
                humanoid:Move(Vector3.new(-1,0,0),false)
                RunService.RenderStepped:Wait()
                local now=pose()
                if (now.Position-original.Position).Magnitude>0.01 or now.LookVector:Dot(original.LookVector)<0.99 then changed=true end
            until os.clock()>deadline
            local states={}
            local connection=humanoid.StateChanged:Connect(function(_,new)
                if new==Enum.HumanoidStateType.Jumping then states.jump=true
                elseif new==Enum.HumanoidStateType.Freefall then states.fall=true
                elseif new==Enum.HumanoidStateType.Landed then states.land=true end
            end)
            humanoid:Move(Vector3.zero);humanoid.Jump=true
            deadline=os.clock()+1.5
            repeat
                RunService.RenderStepped:Wait()
                if not r15 then states[model:GetAttribute("MotionState") or "missing"]=true end
            until os.clock()>deadline
            connection:Disconnect()
            controls:Enable()
            assert(changed,"walking did not change the leg joint")
            assert(states.jump and states.fall and states.land,"missing jump, fall or landing poses")
            return true
        elseif command=="dashInput" then
            local input=game:GetService("UserInputService"):CreateVirtualInput()
            local shade=player.PlayerGui.WisteriaUI:FindFirstChild("MenuShade")
            if shade.Visible then
                input:SendKey(true,Enum.KeyCode.M,false);task.wait(0.1);input:SendKey(false,Enum.KeyCode.M,false);task.wait(0.2)
            end
            assert(not shade.Visible,"menu did not close for movement test")
            local model=player.Character
            local root=model.HumanoidRootPart
            input:SendKey(true,Enum.KeyCode.W,false);task.wait(0.15)
            local start=root.Position;local previous=start;local largest=0;local animated=false
            input:SendKey(true,Enum.KeyCode.Q,false)
            local deadline=os.clock()+0.5
            repeat
                RunService.RenderStepped:Wait()
                largest=math.max(largest,(root.Position-previous).Magnitude);previous=root.Position
                animated=animated or model:GetAttribute("MotionState")=="evade" or string.sub(model:GetAttribute("Anim") or "",1,5)=="dash_"
            until os.clock()>deadline
            input:SendKey(false,Enum.KeyCode.Q,false);input:SendKey(false,Enum.KeyCode.W,false)
            -- Ownership changes and snapshots can trail input under a four-Studio test load.
            -- Keep sampling through replication settling instead of measuring only the local prediction.
            deadline=os.clock()+0.65
            repeat
                RunService.RenderStepped:Wait()
                largest=math.max(largest,(root.Position-previous).Magnitude);previous=root.Position
            until os.clock()>deadline
            assert(animated,"Q was not admitted while holding W")
            assert((root.Position-start).Magnitude>10,"dash failed to travel: "..(root.Position-start).Magnitude.."; largest frame "..largest)
            assert(largest<12,"dash jumped an entire frame: "..largest)
            return {distance=(root.Position-start).Magnitude,largestFrame=largest}
        elseif command=="weapon" then
            local model=workspace.Actors:FindFirstChild(args.name) or Players:FindFirstChild(args.name).Character
            assert(model:GetAttribute("WeaponDrawn")==args.drawn,"weapon state not replicated")
            if model:GetAttribute("RigKind")=="R15" then
                local grip=model.Sword.SwordGrip
                assert(grip.Part0==(args.drawn and model.RightHand or model.LowerTorso),"sword grip not replicated")
                assert(model.Sword.Blade.Transparency==(args.drawn and 0 or 1),"blade visibility incorrect")
                assert(model.Sword.Saya:IsDescendantOf(model),"saya missing")
            else
                assert(model:FindFirstChild("Scabbard") and model.Torso:FindFirstChild("WeaponGrip"))
                assert(model.Blade.LocalTransparencyModifier==(args.drawn and 0 or 1),"blade visibility incorrect")
            end
            return true
        elseif command=="hitFlash" then
            local model=workspace.Actors:FindFirstChild(args.name) or Players:FindFirstChild(args.name).Character
            local deadline=os.clock()+1
            repeat task.wait(0.05) until model:FindFirstChild("HitFlash") or os.clock()>deadline
            local flash=model:FindFirstChild("HitFlash")
            assert(flash and flash:IsA("Highlight") and flash.Adornee==model,"white hit flash missing on "..args.name)
            return true
        elseif command=="sceneKey" then
            local input=game:GetService("UserInputService"):CreateVirtualInput()
            input:SendKey(true,Enum.KeyCode.E,false);task.wait(0.1);input:SendKey(false,Enum.KeyCode.E,false)
            task.wait(0.65)
            return true
        elseif command=="story" then
            task.wait(0.4)
            local gui=player.PlayerGui:FindFirstChild("StoryUI")
            assert(gui,"story UI missing")
            if args.scene then
                assert(gui.Cutscene.Visible and workspace.CurrentCamera.CameraType==Enum.CameraType.Scriptable,"cutscene did not start")
                assert(player.Character.HumanoidRootPart.Anchored,"server did not lock cinematic movement")
            else
                assert(not gui.Cutscene.Visible and not gui.Objective.Visible,"story UI leaked")
                assert(workspace.CurrentCamera.CameraType==Enum.CameraType.Custom and workspace.CurrentCamera.CameraSubject==player.Character:FindFirstChildOfClass("Humanoid"),"camera was not restored")
            end
            return true
        elseif command=="ui" then
            local gui=player.PlayerGui:FindFirstChild("WisteriaUI")
            assert(gui,"missing UI")
            local labels=0
            for _,item in ipairs(gui:GetDescendants()) do if item:IsA("TextLabel") or item:IsA("TextButton") then labels+=1 end end
            assert(labels>30,"UI did not populate")
            assert(#failures==0,table.concat(failures,"\n"))
            return labels
        elseif command=="training" then
            task.wait(0.4)
            local gui=player.PlayerGui.StoryUI
            assert(gui.Training.Visible and gui.Objective.Visible and not gui.Cutscene.Visible,"training HUD missing")
            assert(workspace.CurrentCamera.CameraType==Enum.CameraType.Custom,"camera still locked")
            if args.weapon then assert(player.Character.StoryWeapon:FindFirstChild(args.weapon),"training weapon did not replicate") end
            assert(#failures==0,table.concat(failures,"\n"))
            return true
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
            if player.PlayerGui.WisteriaUI.MenuShade.Visible then
                input:SendKey(true,Enum.KeyCode.M,false);task.wait(0.1);input:SendKey(false,Enum.KeyCode.M,false)
            end
            local root=player.Character.HumanoidRootPart
            workspace.CurrentCamera.CameraType=Enum.CameraType.Scriptable
            workspace.CurrentCamera.CFrame=CFrame.lookAt(root.Position+Vector3.new(18,14,26),root.Position+Vector3.new(0,2,-12))
            return true
        end
        error("Unknown runtime test command")
    end)
    bridge:FireServer(token,ok,result)
end)
