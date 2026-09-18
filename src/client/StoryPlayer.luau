local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Lighting=game:GetService("Lighting")
local TweenService=game:GetService("TweenService")
local ContextActionService=game:GetService("ContextActionService")
local UserInputService=game:GetService("UserInputService")
local StoryPlayer={}
StoryPlayer.__index=StoryPlayer

local function make(class,parent,props)
    local obj=Instance.new(class)
    for k,v in pairs(props) do obj[k]=v end
    obj.Parent=parent;return obj
end
local function text(parent,value,size,pos,fontSize,color)
    return make("TextLabel",parent,{BackgroundTransparency=1,Text=value,Size=size,Position=pos,TextSize=fontSize,
        TextColor3=color or Color3.fromRGB(244,239,228),Font=Enum.Font.Gotham,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left})
end

function StoryPlayer.new(send,ui)
    local self=setmetatable({send=send,ui=ui},StoryPlayer)
    local gui=make("ScreenGui",Players.LocalPlayer:WaitForChild("PlayerGui"),{Name="StoryUI",ResetOnSpawn=false,DisplayOrder=30,IgnoreGuiInset=false})
    self.gui=gui
    local panel=make("Frame",gui,{Name="Objective",Size=UDim2.new(0.72,0,0,90),Position=UDim2.fromOffset(16,78),BackgroundColor3=Color3.fromRGB(18,26,37),BackgroundTransparency=0.1,BorderSizePixel=0,Visible=false})
    make("UISizeConstraint",panel,{MaxSize=Vector2.new(520,90)});make("UICorner",panel,{CornerRadius=UDim.new(0,8)})
    self.objectivePanel=panel
    self.title=text(panel,"",UDim2.new(1,-24,0,23),UDim2.fromOffset(12,6),13,Color3.fromRGB(246,200,123))
    self.objective=text(panel,"",UDim2.new(1,-24,0,47),UDim2.fromOffset(12,28),15)
    local exercise=make("Frame",gui,{Name="Training",Size=UDim2.new(0.72,0,0,98),Position=UDim2.fromOffset(16,174),BackgroundColor3=Color3.fromRGB(18,26,37),BackgroundTransparency=0.1,BorderSizePixel=0,Visible=false})
    make("UISizeConstraint",exercise,{MaxSize=Vector2.new(520,98)});make("UICorner",exercise,{CornerRadius=UDim.new(0,8)})
    self.exercise=exercise
    self.progress=text(exercise,"",UDim2.new(1,-24,0,27),UDim2.fromOffset(12,3),14)
    self.breathBar=make("Frame",exercise,{Size=UDim2.new(1,-24,0,12),Position=UDim2.fromOffset(12,34),BackgroundColor3=Color3.fromRGB(49,59,73),BorderSizePixel=0})
    self.window=make("Frame",self.breathBar,{Size=UDim2.fromScale(0.3,1),BackgroundColor3=Color3.fromRGB(175,142,78),BorderSizePixel=0})
    self.cursor=make("Frame",self.breathBar,{Size=UDim2.new(0,4,1,4),Position=UDim2.fromOffset(0,-2),BackgroundColor3=Color3.fromRGB(255,248,223),BorderSizePixel=0})
    self.focusButton=make("TextButton",exercise,{Text="BREATHE  [E / X]",Size=UDim2.new(1,-24,0,34),Position=UDim2.fromOffset(12,55),BackgroundColor3=Color3.fromRGB(38,48,61),TextColor3=Color3.fromRGB(245,226,189),Font=Enum.Font.GothamMedium,TextSize=14,BorderSizePixel=0})
    make("UICorner",self.focusButton,{CornerRadius=UDim.new(0,6)})
    self.focusButton.Activated:Connect(function() self:focus() end)
    self.cinema=make("Frame",gui,{Name="Cutscene",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Visible=false})
    make("Frame",self.cinema,{Size=UDim2.new(1,0,0,42),BackgroundColor3=Color3.new(),BorderSizePixel=0})
    local footer=make("Frame",self.cinema,{Name="Dialogue",Size=UDim2.new(1,0,0,155),Position=UDim2.new(0,0,1,-155),BackgroundColor3=Color3.fromRGB(10,14,22),BackgroundTransparency=0.04,BorderSizePixel=0})
    local inner=make("Frame",footer,{Size=UDim2.fromScale(0.9,1),Position=UDim2.fromScale(0.5,0),AnchorPoint=Vector2.new(0.5,0),BackgroundTransparency=1})
    make("UISizeConstraint",inner,{MaxSize=Vector2.new(980,155)})
    self.speaker=text(inner,"",UDim2.new(1,0,0,25),UDim2.fromOffset(0,8),14,Color3.fromRGB(246,200,123))
    self.dialogue=text(inner,"",UDim2.new(1,0,0,64),UDim2.fromOffset(0,35),18)
    self.dialogue.TextYAlignment=Enum.TextYAlignment.Top
    local function button(value,pos,callback)
        local b=make("TextButton",inner,{Text=value,Size=UDim2.new(0.47,0,0,36),Position=pos,BackgroundColor3=Color3.fromRGB(38,48,61),TextColor3=Color3.fromRGB(245,226,189),TextSize=13,Font=Enum.Font.GothamMedium,BorderSizePixel=0})
        make("UICorner",b,{CornerRadius=UDim.new(0,6)});b.Activated:Connect(callback);return b
    end
    button("SKIP SCENE  [Y]",UDim2.new(0,0,1,-44),function() self:request(true) end)
    button("CONTINUE  [E / A]",UDim2.new(0.53,0,1,-44),function() self:request(false) end)
    ContextActionService:BindActionAtPriority("StoryContinue",function(_,state)
        if not self.activeScene or UserInputService:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
        if state==Enum.UserInputState.Begin then self:request(false) end
        return Enum.ContextActionResult.Sink
    end,false,4000,Enum.KeyCode.E,Enum.KeyCode.ButtonA)
    ContextActionService:BindActionAtPriority("StorySkip",function(_,state)
        if not self.activeScene or UserInputService:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
        if state==Enum.UserInputState.Begin then self:request(true) end
        return Enum.ContextActionResult.Sink
    end,false,4000,Enum.KeyCode.Y,Enum.KeyCode.ButtonY)
    ContextActionService:BindActionAtPriority("StoryFocus",function(_,state)
        if not self:canFocus() then return Enum.ContextActionResult.Pass end
        if state==Enum.UserInputState.Begin then self:focus() end
        return Enum.ContextActionResult.Sink
    end,false,4000,Enum.KeyCode.E,Enum.KeyCode.ButtonX)
    RunService.RenderStepped:Connect(function()
        if not self.state then return end
        self.objectivePanel.Visible=self.state.phase~="scene" and not self.ui.shade.Visible
        local challenge=self.state.challenge
        self.exercise.Visible=challenge~=nil and not self.ui.shade.Visible
        if challenge then
            local focus=challenge.kind=="breath" or challenge.kind=="cut"
            self.breathBar.Visible=focus;self.focusButton.Visible=focus
            self.exercise.Size=UDim2.new(0.72,0,0,focus and 98 or 36)
            local progress=challenge.kind=="route" and ("Course markers: "..math.min(challenge.routeIndex-1,challenge.routeTotal).." / "..challenge.routeTotal)
                or ("Controlled hits: "..challenge.count.." / "..challenge.goal)
            if challenge.kind=="breath" then progress="Steady breaths: "..challenge.count.." / "..challenge.goal end
            if challenge.kind=="cut" then progress="Stand still. Breathe in gold, then strike." end
            if challenge.kind=="survive" then progress..="  ·  Hold out: "..challenge.surviveRemaining.."s" end
            self.progress.Text=progress.."  ·  "..challenge.remaining.."s"
            if focus then
                local now=workspace:GetServerTimeNow()
                local phase=(now-challenge.started)%challenge.period
                local ready=phase>=challenge.window[1] and phase<=challenge.window[2]
                self.window.Position=UDim2.fromScale(challenge.window[1]/challenge.period,0)
                self.window.Size=UDim2.fromScale((challenge.window[2]-challenge.window[1])/challenge.period,1)
                self.window.BackgroundColor3=ready and Color3.fromRGB(255,214,129) or Color3.fromRGB(175,142,78)
                self.cursor.Position=UDim2.new(phase/challenge.period,-2,0,-2)
                self.focusButton.Text=challenge.kind=="cut" and now<challenge.focusUntil and ("STRIKE NOW  ·  "..math.ceil(challenge.focusUntil-now).."s") or "BREATHE IN GOLD  [E / X]"
            end
        end
        local character=Players.LocalPlayer.Character
        local root=character and character:FindFirstChild("HumanoidRootPart")
        local distance=root and self.state.position and math.floor((root.Position-self.state.position).Magnitude) or nil
        self.objective.Text=self.state.objective..(distance and ("  •  "..distance.." studs") or "")
        self.dialogue.TextSize=workspace.CurrentCamera.ViewportSize.Y<540 and 15 or 18
        if self.activeScene then
            workspace.CurrentCamera.CameraType=Enum.CameraType.Scriptable
            workspace.CurrentCamera.CFrame=self.cameraValue.Value
        end
    end)
    self.cameraValue=Instance.new("CFrameValue")
    Players.LocalPlayer.CharacterAdded:Connect(function() self:releaseCamera() end)
    return self
end

function StoryPlayer:canFocus()
    local challenge=self.state and self.state.challenge
    return challenge and (challenge.kind=="breath" or challenge.kind=="cut") and not self.ui.shade.Visible and not UserInputService:GetFocusedTextBox()
end

function StoryPlayer:focus()
    if self:canFocus() then self.send("Focus") end
end

function StoryPlayer:request(skip)
    if not self.activeScene or os.clock()<(self.nextRequest or 0) then return end
    self.nextRequest=os.clock()+0.65
    self.send(skip and "StorySkip" or "StoryContinue")
end

function StoryPlayer:releaseCamera()
    if self.tween then self.tween:Cancel();self.tween=nil end
    if self.activeScene then
        local camera=workspace.CurrentCamera
        local character=Players.LocalPlayer.Character
        camera.CameraType=Enum.CameraType.Custom
        camera.CameraSubject=character and character:FindFirstChildOfClass("Humanoid") or nil
        camera.FieldOfView=self.savedFov or 70
    end
    self.activeScene=false;self.cinema.Visible=false
    ContextActionService:UnbindAction("StoryMovementLock")
end

function StoryPlayer:update(state)
    if state.kind~="state" then return end
    local story=state.story
    local scene=story and story.phase=="scene"
    self.ui.top.Visible=not scene;self.ui.hint.Visible=not scene
    if scene then self.ui.toastFrame.Visible=false end
    self.ui.skillbar.Visible=story==nil
    self.ui.status.Visible=story==nil or story.phase=="challenge"
    self.exercise.Visible=story~=nil and story.challenge~=nil
    if story and story.challenge then
        self.ui.hint.Text=story.canBasic and "Click / RT: strike   •   F / LT: guard   •   Q / RB: dash   •   E / X: breathe" or "WASD / stick: move   •   Space / A: jump   •   Q / RB: dash   •   E / X: breathe"
    end
    self.objectivePanel.Visible=story~=nil and story.phase~="scene"
    if not story then
        self:releaseCamera();self.state=nil
        if self.savedLighting then
            for key,value in pairs(self.savedLighting) do Lighting[key]=value end
            self.savedLighting=nil
        end
        return
    end
    if not self.savedLighting then self.savedLighting={ClockTime=Lighting.ClockTime,Brightness=Lighting.Brightness,Ambient=Lighting.Ambient,OutdoorAmbient=Lighting.OutdoorAmbient} end
    Lighting.ClockTime=story.clock;Lighting.Brightness=2.5
    Lighting.Ambient=Color3.fromRGB(109,123,143);Lighting.OutdoorAmbient=Color3.fromRGB(138,155,175)
    self.title.Text=string.upper(story.title).."  /  "..story.step.." OF "..story.total
    local changed=not self.state or self.state.serial~=story.serial
    self.state=story
    if story.phase~="scene" then self:releaseCamera();return end
    if not changed and self.activeScene then return end
    self.ui:toggle(false)
    if not self.activeScene then
        self.savedFov=workspace.CurrentCamera.FieldOfView
        self.cameraValue.Value=CFrame.lookAt(story.cameraFrom,story.cameraTo)
    end
    self.activeScene=true;self.cinema.Visible=true
    ContextActionService:BindActionAtPriority("StoryMovementLock",function() return Enum.ContextActionResult.Sink end,false,3500,
        Enum.PlayerActions.CharacterForward,Enum.PlayerActions.CharacterBackward,Enum.PlayerActions.CharacterLeft,Enum.PlayerActions.CharacterRight,Enum.PlayerActions.CharacterJump)
    self.speaker.Text=story.speaker.."  ·  "..story.line.." / "..story.lines
    self.dialogue.Text=story.text
    workspace.CurrentCamera.FieldOfView=55
    if self.tween then self.tween:Cancel() end
    local cameraTarget=CFrame.lookAt(story.cameraFrom,story.cameraTo)
    self.tween=TweenService:Create(self.cameraValue,TweenInfo.new(self.ui.effects.reduced and 0 or 0.75,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Value=cameraTarget})
    self.tween:Play()
end
return StoryPlayer
