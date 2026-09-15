local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local ContextActionService=game:GetService("ContextActionService")
local UserInputService=game:GetService("UserInputService")
local GuiService=game:GetService("GuiService")
local player=Players.LocalPlayer
local network=ReplicatedStorage:WaitForChild("Network")
local action=network:WaitForChild("Action")
local stateRemote=network:WaitForChild("State")
local effectRemote=network:WaitForChild("Effects")
local Effects=require(script.Parent.Effects)
local Animator=require(script.Parent.Animator)
local UI=require(script.Parent.UI)
local function send(name,payload) action:FireServer(name,payload) end
local ui=UI.new(send,Effects)
local function direction(dodge)
    local character=player.Character
    local root=character and character:FindFirstChild("HumanoidRootPart")
    local humanoid=character and character:FindFirstChildOfClass("Humanoid")
    if not root then return Vector3.new(0,0,-1) end
    if dodge and humanoid and humanoid.MoveDirection.Magnitude>0.1 then return humanoid.MoveDirection end
    if UserInputService.MouseEnabled and not UserInputService.TouchEnabled and UserInputService:GetLastInputType()~=Enum.UserInputType.Gamepad1 then
        local mouse=player:GetMouse()
        local offset=mouse.Hit.Position-root.Position
        if offset.Magnitude>0.1 then return offset.Unit end
    end
    return workspace.CurrentCamera.CFrame.LookVector
end
local function canAct() return not ui.shade.Visible and UserInputService:GetFocusedTextBox()==nil end
local function overButton()
    local mouse=UserInputService:GetMouseLocation()
    for _,item in ipairs(player.PlayerGui:GetGuiObjectsAtPosition(mouse.X,mouse.Y)) do
        if item:IsA("GuiButton") or item:FindFirstAncestorWhichIsA("GuiButton") then return true end
    end
    return false
end
ui.onSkill=function(slot) if canAct() then send("Skill",{slot=slot,direction=direction(false)}) end end
ui.onMenu=function(open)
    send("Guard",false)
    if open and UserInputService.GamepadEnabled then GuiService.SelectedObject=ui.panel:FindFirstChildWhichIsA("TextButton",true) else GuiService.SelectedObject=nil end
end

local function bind(name,callback,touch,...)
    ContextActionService:BindAction(name,function(_,inputState,input)
        return callback(inputState,input) and Enum.ContextActionResult.Sink or Enum.ContextActionResult.Pass
    end,touch,...)
end
bind("WisteriaAttack",function(s,input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 and overButton() then return false end
    if s==Enum.UserInputState.Begin and canAct() then send("Basic",direction(false));return true end
    return false
end,true,Enum.UserInputType.MouseButton1,Enum.KeyCode.ButtonR2)
bind("WisteriaGuard",function(s)
    if s==Enum.UserInputState.End or s==Enum.UserInputState.Cancel then send("Guard",false);return true end
    if s==Enum.UserInputState.Begin and canAct() then send("Guard",true);return true end
    return false
end,true,Enum.KeyCode.F,Enum.KeyCode.ButtonL2)
bind("WisteriaDodge",function(s)
    if s==Enum.UserInputState.Begin and canAct() then send("Dodge",direction(true));return true end
    return false
end,true,Enum.KeyCode.Q,Enum.KeyCode.ButtonR1)
local keyboard={Enum.KeyCode.One,Enum.KeyCode.Two,Enum.KeyCode.Three,Enum.KeyCode.Four}
local controller={Enum.KeyCode.ButtonX,Enum.KeyCode.ButtonY,Enum.KeyCode.ButtonB,Enum.KeyCode.ButtonL1}
for i=1,4 do
    bind("WisteriaSkill"..i,function(s) if s==Enum.UserInputState.Begin and canAct() then ui.onSkill(i);return true end return false end,false,keyboard[i],controller[i])
end
bind("WisteriaMenu",function(s) if s==Enum.UserInputState.Begin and not UserInputService:GetFocusedTextBox() then ui:toggle();return true end return false end,false,Enum.KeyCode.M,Enum.KeyCode.DPadUp)
ContextActionService:SetTitle("WisteriaAttack","Attack")
ContextActionService:SetTitle("WisteriaGuard","Guard")
ContextActionService:SetTitle("WisteriaDodge","Dodge")
ContextActionService:SetPosition("WisteriaAttack",UDim2.new(1,-150,1,-240))
ContextActionService:SetPosition("WisteriaGuard",UDim2.new(1,-220,1,-170))
ContextActionService:SetPosition("WisteriaDodge",UDim2.new(1,-80,1,-240))
UserInputService.WindowFocusReleased:Connect(function() send("Guard",false) end)
local function characterAdded(character)
    local humanoid=character:WaitForChild("Humanoid")
    workspace.CurrentCamera.CameraType=Enum.CameraType.Custom
    workspace.CurrentCamera.CameraSubject=humanoid
end
player.CharacterAdded:Connect(characterAdded)
if player.Character then task.spawn(characterAdded,player.Character) end
stateRemote.OnClientEvent:Connect(function(state) ui:update(state) end)
effectRemote.OnClientEvent:Connect(Effects.play)
Animator.start()
send("Ready")
task.spawn(function()
    for _=1,15 do
        task.wait(2)
        if ui.state then return end
        send("Ready")
    end
    ui:toast("Still connecting. Check the Studio Output window for server errors.")
end)
print("[Wisteria] Client ready")
