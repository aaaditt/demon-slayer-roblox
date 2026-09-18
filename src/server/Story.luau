local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Content=require(ReplicatedStorage.Shared.Content)
local Rig=require(script.Parent.Rig)
local World=require(script.Parent.World)
local Training=require(script.Parent.Training)
local Story={}
Story.__index=Story

local function visible(model,shown)
    if not model then return end
    for _,p in ipairs(model:GetDescendants()) do
        if p:IsA("BasePart") then
            if p:GetAttribute("StoryTransparency")==nil then p:SetAttribute("StoryTransparency",p.Transparency) end
            p.Transparency=shown and p:GetAttribute("StoryTransparency") or 1
        elseif p:IsA("BillboardGui") then p.Enabled=shown end
    end
end

function Story.new(gameService,player,mission)
    local self=setmetatable({game=gameService,player=player,mission=mission,data=mission.chapter.story,
        stepIndex=0,line=0,serial=0,npcs={},connections={},carry="none",phase="objective",closed=false},Story)
    for _,definition in ipairs(self.data.actors) do
        local d=definition.template and table.clone(Content.characters[definition.template]) or {weapon="none"}
        d.id=definition.id;d.name=definition.name;d.color=definition.color
        local model,humanoid,root=Rig.create(World.Actors,mission.room.center+Vector3.new(table.unpack(definition.position)),d)
        if definition.scale then model:ScaleTo(definition.scale) end
        model.Head.Nameplate:Destroy() -- Speaker names and prompts identify noncombat story actors.
        local bamboo=model:FindFirstChild("Bamboo")
        if bamboo and self.data.id=="kamado_prologue" then bamboo.Transparency=1 end
        if self.data.map=="sagiri" then Rig.storyWeapon(model,nil) end
        root.Anchored=true;humanoid.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
        for _,p in ipairs(model:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end
        model:SetAttribute("ActorKind","story");self.npcs[definition.id]=model
        visible(model,definition.visible~=false)
    end
    local entry=gameService.players[player]
    entry.actor.storyLocked=true
    Rig.storyWeapon(entry.actor.model,nil)
    self:setCarry(self.data.initialCarry or "none")
    return self
end

function Story:actor()
    local entry=self.game.players[self.player]
    return entry and entry.mission==self.mission and entry.actor or nil
end

function Story:setCarry(kind)
    local actor=self:actor()
    if not actor then return end
    local previous=actor.model:FindFirstChild("StoryCarry")
    if previous then previous:Destroy() end
    self.carry=kind;actor.model:SetAttribute("Carrying",kind~="none")
    if kind=="nezuko" then visible(self.npcs.nezuko,false) end
    if kind=="none" then return end
    local carry=Instance.new("Model");carry.Name="StoryCarry";carry.Parent=actor.model
    local torso=actor.model.Torso
    local function piece(name,size,offset,color)
        local p=Instance.new("Part");p.Name=name;p.Size=size;p.Color=color;p.Massless=true
        p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CFrame=torso.CFrame*offset
        p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=carry
        local w=Instance.new("WeldConstraint");w.Part0=torso;w.Part1=p;w.Parent=p
    end
    if kind=="charcoal" then
        piece("WovenBasket",Vector3.new(1.8,2.1,1),CFrame.new(0,0,1),Color3.fromRGB(142,105,65))
        for i=-1,1 do piece("Charcoal",Vector3.new(0.45,0.65,0.5),CFrame.new(i*0.5,1.15,1),Color3.fromRGB(42,43,47)) end
    else
        piece("NezukoRobe",Vector3.new(1.5,1.9,0.75),CFrame.new(0,0.5,1.05),Color3.fromRGB(231,137,163))
        piece("NezukoHead",Vector3.new(1.4,0.8,0.85),CFrame.new(0,1.8,1.05),Color3.fromRGB(235,197,171))
        piece("NezukoHair",Vector3.new(1.5,1.65,0.5),CFrame.new(0,1.15,1.6),Color3.fromRGB(32,27,41))
        if self.encounter or self.data.id~="kamado_prologue" then piece("Bamboo",Vector3.new(0.9,0.18,0.18),CFrame.new(0,1.55,0.58),Color3.fromRGB(112,153,93)) end
        for _,side in ipairs({-1,1}) do
            piece("NezukoArm",Vector3.new(0.55,0.65,1.8),CFrame.new(side*0.9,0.8,0.5),Color3.fromRGB(231,137,163))
            piece("NezukoLeg",Vector3.new(0.6,0.65,1.5),CFrame.new(side*0.9,-0.55,0.8),Color3.fromRGB(73,51,63))
        end
    end
end

function Story:freeze(enabled)
    local actor=self:actor()
    if not actor then return end
    self.game.combat:stopMotion(actor)
    actor.root.Anchored=enabled
    actor.root.AssemblyLinearVelocity=Vector3.zero
    actor.model:SetAttribute("InCutscene",enabled)
    actor.lastPosition=actor.root.Position;actor.motionTime=workspace:GetServerTimeNow()
    if not enabled then pcall(function() actor.root:SetNetworkOwner(self.player) end) end
end

function Story:clearPrompt()
    if self.prompt then self.prompt:Destroy();self.prompt=nil end
    if self.marker then self.marker:Destroy();self.marker=nil end
    if self.promptConnection then self.promptConnection:Disconnect();self.promptConnection=nil end
end

function Story:applyActors(states)
    for id,state in pairs(states or {}) do
        local model=self.npcs[id]
        if model then
            if state.position then
                local r=state.rotation or {0,0,0}
                model:PivotTo(CFrame.new(self.mission.room.center+Vector3.new(table.unpack(state.position)))*CFrame.Angles(math.rad(r[1]),math.rad(r[2]),math.rad(r[3])))
            end
            if state.visible~=nil then visible(model,state.visible and not (id=="nezuko" and self.carry=="nezuko")) end
        end
    end
end

function Story:mark(anchor,message)
    if self.marker then self.marker:Destroy() end
    local marker=Instance.new("BillboardGui");marker.Name="StoryWaypoint";marker.Adornee=anchor
    marker.Size=UDim2.fromOffset(170,52);marker.StudsOffset=Vector3.new(0,5,0);marker.AlwaysOnTop=true;marker.MaxDistance=450;marker.Parent=anchor
    local label=Instance.new("TextLabel");label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=1
    label.Text="◆  "..message;label.TextColor3=Color3.fromRGB(255,219,135);label.TextStrokeTransparency=0.25
    label.TextSize=16;label.Font=Enum.Font.GothamMedium;label.TextWrapped=true;label.Parent=marker;self.marker=marker
end

function Story:advance()
    if self.closed then return end
    self:clearPrompt();self:freeze(false)
    self.stepIndex+=1;self.line=0;self.serial+=1;self.phase="objective"
    local step=self.data.steps[self.stepIndex]
    if not step then self.game:completeMission(self.player,self.mission);return end
    self.step=step;self.sceneLines=step.scene;self.resultScene=false;self.clockOverride=nil
    if self.data.id=="kamado_prologue" then
        for _,name in ipairs({"mother","takeo","hanako","shigeru","rokuta"}) do visible(self.npcs[name],not step.tragedy) end
        visible(self.npcs.giyu,self.encounter==true)
        visible(self.npcs.nezuko,self.carry~="nezuko")
    end
    self:applyActors(step.actors)
    if step.tragedy and not self.encounter then
        local m=self.npcs.nezuko
        m:PivotTo(CFrame.new(self.mission.room.center+Vector3.new(5,1.2,-103))*CFrame.Angles(0,0,math.pi/2))
    end
    if step.automatic then self:startScene();return end
    local anchor=self.mission.room.anchors[step.target]
    local prompt=Instance.new("ProximityPrompt")
    prompt.Name="StoryInteraction";prompt.ActionText=step.action;prompt.ObjectText=step.title
    prompt.MaxActivationDistance=10;prompt.RequiresLineOfSight=false;prompt.HoldDuration=0.2
    prompt.KeyboardKeyCode=Enum.KeyCode.E;prompt.GamepadKeyCode=Enum.KeyCode.ButtonX;prompt.Parent=anchor
    self.prompt=prompt
    self.promptConnection=prompt.Triggered:Connect(function(player) self:interact(player,step.target) end)
    self:mark(anchor,step.action)
    self.game:push(self.player)
end

function Story:interact(player,target)
    local actor=self:actor()
    if self.closed or player~=self.player or not actor or not actor.alive or self.phase~="objective" or target~=self.step.target then return false end
    local anchor=self.mission.room.anchors[target]
    if not anchor or (actor.root.Position-anchor.Position).Magnitude>12 then return false end
    self:startScene();return true
end

function Story:pose(model,name)
    if not model then return end
    model:SetAttribute("Pose",name or "idle")
    model:SetAttribute("PoseStart",workspace:GetServerTimeNow());model:SetAttribute("PoseDuration",name and 30 or 0)
end

function Story:showLine()
    self.serial+=1;self.changedAt=workspace:GetServerTimeNow()
    local line=self.sceneLines[self.line]
    local actor=self:actor()
    if not actor then return end
    self:pose(actor.model,line.playerPose)
    self:pose(self.npcs.giyu,line.giyuPose);self:pose(self.npcs.nezuko,line.nezukoPose)
    if self.step.encounter then
        local center=self.mission.room.center
        local giyu=self.npcs.giyu
        if self.line==2 then
            local destination=CFrame.lookAt(center+Vector3.new(13,3,8),actor.root.Position)
            self.slide={model=giyu,from=CFrame.new(center+Vector3.new(30,3,3)),to=destination,start=self.changedAt,duration=0.45}
        elseif self.line>=3 then
            giyu:PivotTo(CFrame.lookAt(center+Vector3.new(13,3,8),actor.root.Position))
        end
        if self.line==4 then self.npcs.nezuko:PivotTo(CFrame.lookAt(actor.root.Position+Vector3.new(0,0,-3),giyu.PrimaryPart.Position)) end
    end
    self.game:push(self.player)
end

function Story:startScene(result)
    self:clearPrompt();self.phase="scene";self.line=1
    self.resultScene=result==true;self.sceneLines=result and self.step.outro or self.step.scene
    if result then
        self.clockOverride=self.step.resultClock
        self:applyActors(self.step.resultActors)
    else
        if self.step.carryOnScene then self:setCarry(self.step.carryOnScene) end
        self:applyActors(self.step.actors)
    end
    if self.step.encounter then
        self.encounter=true
        local actor=self:actor();local center=self.mission.room.center
        actor.model:PivotTo(CFrame.new(center+Vector3.new(12,3,20)))
        self.npcs.nezuko:PivotTo(CFrame.lookAt(center+Vector3.new(12,3,16),actor.root.Position))
        self.npcs.giyu:PivotTo(CFrame.lookAt(center+Vector3.new(30,3,3),actor.root.Position))
        visible(self.npcs.nezuko,true);visible(self.npcs.giyu,true)
    end
    self:freeze(true);self:showLine()
end

function Story:continue(skip)
    local actor=self:actor()
    if self.closed or not actor or not actor.alive or self.phase~="scene" or workspace:GetServerTimeNow()-self.changedAt<0.6 then return false end
    if skip or self.line>=#self.sceneLines then
        self.slide=nil
        if self.encounter then self.npcs.giyu:PivotTo(CFrame.new(self.mission.room.center+Vector3.new(13,3,8))) end
        self:pose(actor.model,nil);self:pose(self.npcs.giyu,nil);self:pose(self.npcs.nezuko,nil)
        if self.step.challenge and not self.resultScene then self:startChallenge()
        else
            if self.step.carryAfter then self:setCarry(self.step.carryAfter) end
            self:advance()
        end
    else self.line+=1;self:showLine() end
    return true
end

function Story:startChallenge()
    self:clearPrompt();self.phase="challenge";self:freeze(false)
    local npc=self.npcs[self.step.challenge.enemy]
    if npc then visible(npc,false) end
    self.challenge=Training.new(self)
    self.game:push(self.player)
end

function Story:finishChallenge()
    if not self.challenge or self.closed then return end
    self.challenge:destroy();self.challenge=nil
    local npc=self.npcs[self.step.challenge.enemy]
    if npc then visible(npc,true) end
    if self.step.splitBoulder then
        self.boulderSplitStart=workspace:GetServerTimeNow()
        self.mission.room.boulderRope.Transparency=1
    end
    self:startScene(true)
end

function Story:snapshot()
    local line=self.phase=="scene" and self.sceneLines[self.line] or nil
    local shot=line and self.data.shots[line.shot] or nil
    local target=self.step.target and self.mission.room.anchors[self.step.target]
    return {id=self.data.id,serial=self.serial,step=self.stepIndex,total=#self.data.steps,title=self.step.title,
        objective=self.step.objective,phase=self.phase,line=self.line,lines=#self.sceneLines,clock=self.clockOverride or self.step.clock,
        challenge=self.challenge and self.challenge:snapshot(),canBasic=self.challenge and self:actor().storyCanBasic or false,
        speaker=line and line.speaker,text=line and line.text,position=self.challenge and self.challenge:position() or target and target.Position,
        cameraFrom=shot and self.mission.room.center+Vector3.new(table.unpack(shot.from)),
        cameraTo=shot and self.mission.room.center+Vector3.new(table.unpack(shot.to))}
end

function Story:tick(now)
    if self.challenge then self.challenge:tick(now) end
    if self.boulderSplitStart then
        local alpha=math.clamp((now-self.boulderSplitStart)/0.8,0,1)
        for _,half in ipairs(self.mission.room.boulder) do half.part.CFrame=half.closed:Lerp(half.open,alpha) end
        if alpha>=1 then self.boulderSplitStart=nil end
    end
    if self.slide then
        local slide=self.slide
        local progress=math.clamp((now-slide.start)/slide.duration,0,1)
        slide.model:PivotTo(slide.from:Lerp(slide.to,1-(1-progress)^3))
        if progress>=1 then self.slide=nil end
    end
end

function Story:destroy()
    if self.closed then return end
    if self.challenge then self.challenge:destroy();self.challenge=nil end
    self.closed=true;self:clearPrompt();self:freeze(false)
    self:setCarry("none")
    for _,model in pairs(self.npcs) do model:Destroy() end
end
return Story
