-- Injected only into the test place; never included in the shipping Rojo tree.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local LogService=game:GetService("LogService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local player=Players.LocalPlayer
local bridge=ReplicatedStorage:WaitForChild("RuntimeTestBridge")
local Profiles=require(ReplicatedStorage.Shared.MotionProfile).new(require(ReplicatedStorage.Shared.Content),require(ReplicatedStorage.Shared.AnimationIndex))
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
            -- Standing still plays the authored idle clip (breathing moves the waist), not the procedural pose.
            local waist=model.LowerTorso.Waist;local idleStart=waist.Transform;local breathing=false
            local idleDeadline=os.clock()+1.3
            repeat
                RunService.RenderStepped:Wait()
                breathing=breathing or waist.Transform.LookVector:Dot(idleStart.LookVector)<0.99999
            until os.clock()>idleDeadline
            assert(model:GetAttribute("MotionClip")==Profiles.locomotion(model:GetAttribute("CharacterId"),"idle",model:GetAttribute("WeaponDrawn")),"idle clip not playing: "..tostring(model:GetAttribute("MotionClip")))
            assert(breathing,"idle clip did not move the waist")
            local hip=model.LowerTorso.RightHip
            local original=hip.Transform
            local changed=false
            local deadline=os.clock()+0.5
            repeat
                humanoid:Move(Vector3.new(-1,0,0),false)
                RunService.RenderStepped:Wait()
                if (hip.Transform.Position-original.Position).Magnitude>0.01 or hip.Transform.LookVector:Dot(original.LookVector)<0.99 then changed=true end
            until os.clock()>deadline
            humanoid:Move(Vector3.zero);humanoid.Jump=true
            local states={}
            deadline=os.clock()+1.5
            repeat RunService.RenderStepped:Wait();states[model:GetAttribute("MotionState") or "missing"]=true until os.clock()>deadline
            controls:Enable()
            assert(changed,"walking did not change the leg joint")
            assert(states.jump and states.fall and states.land,"missing jump, fall or landing poses")
            return true
        elseif command=="brace" then
            -- Wait for a fresh gold window after replication, instead of spending it on the bridge trip.
            local untilWindow=os.clock()+5
            repeat
                RunService.RenderStepped:Wait()
                local phase=(workspace:GetServerTimeNow()-args.started)%args.period
                if phase>=args.opens+0.1 and phase<args.opens+0.3 then break end
            until os.clock()>untilWindow
            ReplicatedStorage.Network.Action:FireServer("Focus")
            local deadline=os.clock()+1.1
            local playerActed,victimActed=false,false
            repeat
                RunService.RenderStepped:Wait()
                playerActed=playerActed or player.Character:GetAttribute("MotionActionClip")=="base/restrain"
                victimActed=victimActed or args.victim:GetAttribute("MotionActionClip")=="base/struggle"
            until os.clock()>deadline
            assert(playerActed and victimActed,string.format("rescue acting missing: player=%s victim=%s playerPose=%s victimPose=%s distance=%.2f",
                tostring(playerActed),tostring(victimActed),tostring(player.Character:GetAttribute("Pose")),tostring(args.victim:GetAttribute("Pose")),
                (player.Character.HumanoidRootPart.Position-args.victim.PrimaryPart.Position).Magnitude))
            return true
        elseif command=="motionProfile" then
            local model=assert(args.model,"profile fixture did not replicate")
            local deadline=os.clock()+5
            local function matches()
                return model:GetAttribute("MotionProfile")==args.profile and model:GetAttribute("MotionClip")==args.base
                    and model:GetAttribute("MotionActionClip")==args.action
            end
            repeat RunService.RenderStepped:Wait() until matches() or os.clock()>deadline
            assert(matches(),"observer clip mismatch: "..tostring(model:GetAttribute("MotionClip")).." / "..tostring(model:GetAttribute("MotionActionClip")))
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
            local frames={}
            -- Frame times separate low-FPS hitches from genuine position snaps at normal frame rates.
            local worstFrame,frameAtLargest=0,0
            local function sample(frame)
                worstFrame=math.max(worstFrame,frame)
                local step=(root.Position-previous).Magnitude;previous=root.Position
                if step>largest then largest=step;frameAtLargest=frame end
                if args and args.trace then
                    table.insert(frames,{time=workspace:GetServerTimeNow(),dt=frame,step=step,distance=(root.Position-start).Magnitude,
                        speed=root.AssemblyLinearVelocity.Magnitude,velocity=root:FindFirstChild("DashVelocity")~=nil})
                end
            end
            input:SendKey(true,Enum.KeyCode.Q,false)
            local deadline=os.clock()+0.5
            repeat
                sample(RunService.RenderStepped:Wait())
                animated=animated or model:GetAttribute("MotionState")=="dash_front"
            until os.clock()>deadline
            input:SendKey(false,Enum.KeyCode.Q,false);input:SendKey(false,Enum.KeyCode.W,false)
            -- Ownership changes and snapshots can trail input under a four-Studio test load.
            -- Keep sampling through replication settling instead of measuring only the local prediction.
            deadline=os.clock()+0.65
            repeat
                sample(RunService.RenderStepped:Wait())
            until os.clock()>deadline
            local trace=#frames>0 and (" DASH_FRAMES "..game:GetService("HttpService"):JSONEncode(frames)) or ""
            assert(animated,"Q was not admitted while holding W")
            assert((root.Position-start).Magnitude>10,string.format("dash failed to travel: %.2f; largest step %.2f; worst frame %.3f s",(root.Position-start).Magnitude,largest,worstFrame))
            assert(largest<12,string.format("dash jumped an entire frame: %.2f studs in a %.3f s frame (worst frame %.3f s)",largest,frameAtLargest,worstFrame)..trace)
            return {distance=(root.Position-start).Magnitude,largestFrame=largest,frameAtLargest=frameAtLargest,worstFrame=worstFrame,frames=frames}
        elseif command=="sidestepInput" then
            local input=game:GetService("UserInputService"):CreateVirtualInput()
            local model=player.Character
            local root=model.HumanoidRootPart
            local camera=workspace.CurrentCamera
            local flat=Vector3.new(camera.CFrame.LookVector.X,0,camera.CFrame.LookVector.Z).Unit
            local cameraLeft=Vector3.new(flat.Z,0,-flat.X)
            -- Holding A turns the character left (AutoRotate); the dash must still be a camera-relative sidestep.
            input:SendKey(true,Enum.KeyCode.A,false);task.wait(0.15)
            local start=root.Position;local seen=false
            input:SendKey(true,Enum.KeyCode.Q,false)
            local deadline=os.clock()+0.3
            repeat RunService.RenderStepped:Wait();seen=seen or model:GetAttribute("MotionState")=="dash_left" until os.clock()>deadline
            local facing=Vector3.new(root.CFrame.LookVector.X,0,root.CFrame.LookVector.Z).Unit
            input:SendKey(false,Enum.KeyCode.Q,false);input:SendKey(false,Enum.KeyCode.A,false)
            task.wait(0.6)
            local moved=Vector3.new(root.Position.X-start.X,0,root.Position.Z-start.Z)
            assert(seen,"A+Q did not play the left sidestep: "..tostring(model:GetAttribute("MotionState")))
            assert(facing:Dot(flat)>math.cos(math.rad(12)),"sidestep did not face the camera: "..facing:Dot(flat))
            assert(moved.Magnitude>6 and moved.Unit:Dot(cameraLeft)>0.8,string.format("sidestep did not travel camera-left: moved %.2f, left dot %.2f",moved.Magnitude,moved.Magnitude>0 and moved.Unit:Dot(cameraLeft) or 0))
            return {distance=moved.Magnitude,facingDot=facing:Dot(flat)}
        elseif command=="swordPath" then
            -- Observed on another client: the draw must slide the blade out along its own axis and carry it
            -- to the hand continuously, rather than teleporting from the hip when the server swaps joints.
            local model=workspace.Actors:FindFirstChild(args.name) or Players:FindFirstChild(args.name).Character
            local deadline=os.clock()+4
            repeat RunService.RenderStepped:Wait() until model:GetAttribute("Pose")=="draw" or os.clock()>deadline
            assert(model:GetAttribute("Pose")=="draw","draw never started")
            local tsuka,lower=model.Katana.Tsuka,model.LowerTorso
            local start=lower.CFrame:ToObjectSpace(tsuka.CFrame)
            local previous=start.Position;local largest,slid,worst,travelled=0,0,0,0
            deadline=os.clock()+0.75
            repeat
                local frame=RunService.RenderStepped:Wait();worst=math.max(worst,frame)
                local point=lower.CFrame:PointToObjectSpace(tsuka.Position)
                local step=(point-previous).Magnitude;largest=math.max(largest,step);travelled+=step;previous=point
                slid=math.max(slid,(point-start.Position):Dot(start.ZVector))
            until os.clock()>deadline
            local direct=(previous-start.Position).Magnitude
            local gap=(tsuka.Position-model.RightHand.Position).Magnitude
            local report=string.format("slid %.2f, largest step %.2f of %.2f travelled (direct %.2f), gap %.2f, worst frame %.3f",slid,largest,travelled,direct,gap,worst)
            assert(slid>1.5,"blade did not slide out along the saya axis: "..report)
            -- A teleport puts nearly all travel in one step; a path spreads it over frames even at low frame rates.
            assert(largest<0.6*travelled,"sword jumped instead of travelling: "..report)
            assert(gap<1.2,"sword did not end in the hand: "..report)
            return report
        elseif command=="weapon" then
            local model=workspace.Actors:FindFirstChild(args.name) or Players:FindFirstChild(args.name).Character
            assert(model:GetAttribute("WeaponDrawn")==args.drawn,"weapon state not replicated")
            assert(model:FindFirstChild("Saya") and model:FindFirstChild("Katana"),"sword model missing")
            assert(model.RightHand.SwordHand.Enabled==args.drawn and model.LowerTorso.SwordHip.Enabled==not args.drawn,"sword joint swap not replicated")
            -- The sword now rests in the saya instead of being hidden, so the hand holds it only when drawn.
            local gap=(model.Katana.Tsuka.Position-model.RightHand.Position).Magnitude
            assert(args.drawn==(gap<1.2),"sword not where its enabled joint places it: "..gap)
            return true
        elseif command=="sceneKey" then
            -- Camera/UI readiness can precede the server's dialogue input gate.
            if args and args.readyAt then
                local deadline=os.clock()+5
                while workspace:GetServerTimeNow()<args.readyAt and os.clock()<deadline do RunService.RenderStepped:Wait() end
                assert(workspace:GetServerTimeNow()>=args.readyAt,"dialogue input never became eligible")
            end
            local inputService=game:GetService("UserInputService")
            assert(not inputService:GetFocusedTextBox(),"text field owns the story key")
            local input=inputService:CreateVirtualInput()
            input:SendKey(true,Enum.KeyCode.E,false);task.wait(0.1);input:SendKey(false,Enum.KeyCode.E,false)
            task.wait(0.65)
            return true
        elseif command=="story" then
            local function ready()
                local gui=player.PlayerGui:FindFirstChild("StoryUI")
                local model=player.Character
                local root=model and model:FindFirstChild("HumanoidRootPart")
                if not gui or not root then return false end
                if args.scene then
                    return gui.Cutscene.Visible and workspace.CurrentCamera.CameraType==Enum.CameraType.Scriptable and root.Anchored
                end
                return not gui.Cutscene.Visible and not gui.Objective.Visible and workspace.CurrentCamera.CameraType==Enum.CameraType.Custom
                    and workspace.CurrentCamera.CameraSubject==model:FindFirstChildOfClass("Humanoid")
            end
            local deadline=os.clock()+5
            repeat RunService.RenderStepped:Wait() until ready() or os.clock()>deadline
            assert(ready(),args.scene and "cutscene/cinematic lock did not start" or "story UI/camera was not restored")
            return true
        elseif command=="selection" then
            task.wait(0.4)
            local model=player.Character
            assert(model:GetAttribute("HasSheath"),"selection sword missing")
            if args.gear=="black" then
                assert(model.Katana.Blade.Color.R<0.2 and model:FindFirstChild("CorpsBelt") and model:FindFirstChild("MessengerCrow"),"Corps gear did not replicate")
            elseif args.gear=="box" then
                assert(model.StoryCarry:FindFirstChild("NezukoTravelBox"),"travel box did not replicate")
                assert(not model:GetAttribute("Carrying"),"box incorrectly locks both arms")
            else assert(player.PlayerGui.StoryUI.Training.Visible,"encounter HUD missing") end
            assert(#failures==0,table.concat(failures,"\n"))
            return true
        elseif command=="swamp" then
            if args.animation then
                local model=args.model;assert(model and model.Head.Transparency<1,"Nezuko not visible")
                local joint=model.LowerTorso.RightHip;local first=joint.Transform;local changed=false;local deadline=os.clock()+0.8
                repeat
                    RunService.RenderStepped:Wait();changed=changed or joint.Transform.LookVector:Dot(first.LookVector)<0.9999
                until os.clock()>deadline
                assert(changed,"Nezuko kick joints did not animate")
            else
                task.wait(0.35)
                local model=player.Character
                assert(model:GetAttribute("HasSheath") and model.Katana.Blade.Color.R<0.2 and model:FindFirstChild("CorpsBelt"))
                assert(model.StoryCarry:FindFirstChild("NezukoTravelBox") and not model:GetAttribute("Carrying"))
                if not args.gear then assert(player.PlayerGui.StoryUI.Training.Visible,"swamp HUD missing") end
            end
            assert(#failures==0,table.concat(failures,"\n"));return true
        elseif command=="bossAnimation" then
            local boss
            for _,model in ipairs(workspace.Actors:GetChildren()) do
                if model:GetAttribute("HandDemon") and model:GetAttribute("Zone")==player.Character:GetAttribute("Zone") then boss=model;break end
            end
            assert(boss,"Hand Demon did not replicate")
            local arm=boss.UpperTorso.HandArm1
            local original=arm.Transform;local changed=false;local deadline=os.clock()+0.7
            repeat
                RunService.RenderStepped:Wait()
                changed=changed or arm.Transform.LookVector:Dot(original.LookVector)<0.99999
            until os.clock()>deadline
            assert(changed,"extra arms did not animate")
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
