local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Shared=ReplicatedStorage.Shared
local Content=require(Shared.Content)
local Rules=require(Shared.Rules)
local Rig=require(script.Parent.Rig)
local World=require(script.Parent.World)
local Training={}
Training.__index=Training
local fighting={survive=true,strikes=true,spar=true,cut=true}

function Training.new(story)
    local self=setmetatable({story=story,data=story.step.challenge,closed=false,attempt=0},Training)
    self:reset(false)
    return self
end

function Training:position()
    if self.data.kind=="route" then
        local id=self.data.checkpoints[self.routeIndex]
        return id and self.story.mission.room.anchors[id].Position or nil
    end
    return self.story.mission.room.anchors[self.story.step.target].Position
end

function Training:reset(retry)
    local actor=self.story:actor()
    if self.closed or not actor or not actor.alive then return end
    self.attempt+=1
    local attempt=self.attempt
    if self.enemy then self.story.game.combat:remove(self.enemy);self.enemy=nil end
    local now=workspace:GetServerTimeNow()
    self.started=now;self.deadline=now+self.data.limit;self.count=0;self.lastCycle=-1;self.nextFocus=0
    self.routeIndex=1;self.lastCheckpoint=nil;self.hazardHits={};self.focusUntil=0
    self.story:freeze(false)
    actor.castToken+=1;actor.storyCanBasic=fighting[self.data.kind]==true
    actor.healthFloor=1;actor.basicStyle="practice";actor.blocking=false
    actor.humanoid.Health=actor.humanoid.MaxHealth;actor.energy=100;actor.status={};actor.stunUntil=0;actor.busyUntil=0
    actor.invulnerableUntil=now+1
    actor.model:PivotTo(CFrame.new(self.story.mission.room.center+Vector3.new(table.unpack(self.data.start))))
    actor.root.AssemblyLinearVelocity=Vector3.zero;actor.lastPosition=actor.root.Position;actor.motionTime=now
    Rig.storyWeapon(actor.model,self.data.weapon)
    self.story:setCarry("none")
    if self.data.enemy then
        local definition=table.clone(Content.characters[self.data.enemy])
        if self.data.enemy=="training" then definition.name="Practice target";definition.weapon="none" end
        local model,humanoid,root=Rig.create(World.Actors,self.story.mission.room.center+Vector3.new(table.unpack(self.data.spawn)),definition)
        if self.data.enemy=="sabito" then Rig.storyWeapon(model,"practice") end
        local static=self.data.kind=="strikes" or self.data.kind=="cut"
        model.Head.Nameplate.Health.Visible=false
        if static then
            for _,item in ipairs(model:GetDescendants()) do if item:IsA("BasePart") then item.Transparency=1;item.CanCollide=false end end
            model.Head.Nameplate.Enabled=false;root.Anchored=true
            if self.data.kind=="strikes" then
                local post=Instance.new("Part");post.Name="PracticePost";post.Anchored=true;post.Size=Vector3.new(1.6,6,1.6)
                post.CFrame=root.CFrame;post.Color=Color3.fromRGB(151,110,69);post.Material=Enum.Material.Wood;post.Parent=model
                local arm=post:Clone();arm.Name="PracticeCrossbar";arm.Size=Vector3.new(5,0.7,0.7);arm.CFrame=post.CFrame*CFrame.new(0,0.9,0);arm.Parent=model
            end
        end
        local enemy=self.story.game.combat:register(model,humanoid,root,{
            kind="npc",mode="Story",zone=actor.zone,room=self.story.mission.room,characterId=self.data.enemy,
            maxHealth=1000,healthFloor=1,basicOnly=true,basicStyle=self.data.enemy=="temple_demon" and "demon" or "practice",
            damageScale=self.data.damageScale or 0.45,attackInterval=1.35,target=not static and actor or nil,
            onDamaged=function(source,damage)
                if self.closed or self.attempt~=attempt or source~=self.story:actor() or damage<=0 then return end
                if self.data.kind=="cut" and workspace:GetServerTimeNow()>self.focusUntil then
                    self.story.game:toast(self.story.player,"Steady a breath in the gold window, then strike.")
                    return
                end
                self.count+=1
            end,
        })
        enemy.invulnerableUntil=now+0.5
        self.enemy=enemy;self.story.mission.enemy=enemy
        if not static then pcall(function() root:SetNetworkOwner(nil) end) end
    end
    self:updateMarker()
    self.story.serial+=1
    if retry then self.story.game:toast(self.story.player,"Take a breath and try again. This exercise has restarted.") end
end

function Training:updateMarker()
    self.story:clearPrompt()
    if self.data.kind=="route" then
        self.story:mark(self.story.mission.room.anchors[self.data.checkpoints[self.routeIndex]],"Course marker "..self.routeIndex)
    elseif self.enemy then self.story:mark(self.enemy.root,self.data.kind=="cut" and "Focus, then strike" or "Land controlled hits")
    else self.story:mark(self.story.mission.room.anchors[self.story.step.target],"Stand here and breathe") end
end

function Training:focus(player)
    local actor=self.story:actor()
    local now=workspace:GetServerTimeNow()
    if self.closed or player~=self.story.player or not actor or not actor.alive or self.story.phase~="challenge" then return false end
    if self.data.kind~="breath" and self.data.kind~="cut" then return false end
    if now<self.nextFocus or now>self.deadline then return false end
    local v=actor.root.AssemblyLinearVelocity
    if (actor.root.Position-self:position()).Magnitude>self.data.radius or Vector2.new(v.X,v.Z).Magnitude>2 then return false end
    local window=self.data.window
    local accepted,cycle=Rules.focusWindow(now-self.started,self.data.period,window[1],window[2],self.lastCycle)
    self.nextFocus=now+0.55
    if not accepted then self.story.game:toast(player,"Stay still and breathe while the bar is gold.");return false end
    self.lastCycle=cycle
    if self.data.kind=="cut" then self.focusUntil=now+4
    else self.count+=1 end
    actor.model:SetAttribute("Pose","heal");actor.model:SetAttribute("PoseStart",now);actor.model:SetAttribute("PoseDuration",0.5)
    self.story.game:push(player)
    return true
end

function Training:hazards(now,actor)
    for _,hazard in ipairs(self.story.mission.room.hazards or {}) do
        local d=hazard.definition
        local phase=(now-self.started+d.offset)%d.period
        local warning=phase<d.windup
        local active=phase>=d.windup and phase<d.windup+d.active
        hazard.warning.Color=active and Color3.fromRGB(228,91,70) or Color3.fromRGB(237,192,96)
        hazard.warning.Transparency=(warning or active) and 0.25 or 0.85
        hazard.log.Transparency=active and 0 or 0.8
        hazard.log.CFrame=hazard.origin*CFrame.new(0,active and 0 or -1.8,0)
        local delta=actor.root.Position-(self.story.mission.room.center+Vector3.new(table.unpack(d.position)))
        local size=Vector3.new(table.unpack(d.size))
        if active and math.abs(delta.X)<size.X/2 and math.abs(delta.Y)<size.Y/2+1 and math.abs(delta.Z)<size.Z/2 and now>(self.hazardHits[d.id] or 0)+1 and now>actor.invulnerableUntil then
            self.hazardHits[d.id]=now
            actor.humanoid:TakeDamage(Rules.trainingDamage(actor.humanoid.Health,d.damage,1))
            self.story.game.combat:emit(actor,"hit",{position=actor.root.Position,amount=d.damage,result="hit"})
        end
    end
end

function Training:tick(now)
    local actor=self.story:actor()
    if self.closed or not actor or not actor.alive then return end
    if actor.humanoid.Health<=1 or now>self.deadline or self.enemy and not self.enemy.alive then self:reset(true);return end
    local complete=false
    if self.data.kind=="route" then
        self:hazards(now,actor)
        local pos=self:position()
        if pos and (actor.root.Position-pos).Magnitude<self.data.radius and now>(self.lastCheckpoint or self.started)+0.6 then
            self.lastCheckpoint=now;self.routeIndex+=1
            if self.routeIndex>#self.data.checkpoints then complete=true else self:updateMarker() end
        end
    else
        if (actor.root.Position-(self.story.mission.room.center+Vector3.new(table.unpack(self.data.start)))).Magnitude>self.data.radius+12 then self:reset(true);return end
        if self.data.kind=="breath" then complete=self.count>=self.data.cycles
        elseif self.data.kind=="cut" then complete=self.count>=1
        elseif self.data.kind=="survive" then complete=self.count>=self.data.hits and now-self.started>=self.data.duration
        else complete=self.count>=self.data.hits end
    end
    if complete then self.story:finishChallenge() end
end

function Training:snapshot()
    return {kind=self.data.kind,count=self.count,goal=self.data.cycles or self.data.hits or 1,
        remaining=math.max(0,math.ceil(self.deadline-workspace:GetServerTimeNow())),started=self.started,
        period=self.data.period,window=self.data.window,focusUntil=self.focusUntil,
        routeIndex=self.routeIndex,routeTotal=self.data.checkpoints and #self.data.checkpoints or nil,
        surviveRemaining=self.data.duration and math.max(0,math.ceil(self.data.duration-(workspace:GetServerTimeNow()-self.started))) or nil}
end

function Training:destroy()
    if self.closed then return end
    self.closed=true
    local actor=self.story:actor()
    if actor then actor.storyCanBasic=false;actor.healthFloor=nil;actor.basicStyle=nil;actor.blocking=false;actor.castToken+=1 end
    if self.enemy then self.story.game.combat:remove(self.enemy);self.enemy=nil end
    self.story.mission.enemy=nil
    self.story:clearPrompt()
    for _,h in ipairs(self.story.mission.room.hazards or {}) do h.warning.Transparency=0.85;h.log.Transparency=0.8;h.log.CFrame=h.origin end
end
return Training
