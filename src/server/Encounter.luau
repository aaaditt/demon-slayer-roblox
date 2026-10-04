local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Content=require(ReplicatedStorage.Shared.Content)
local Rules=require(ReplicatedStorage.Shared.Rules)
local Rig=require(script.Parent.Rig)
local World=require(script.Parent.World)
local Encounter={}
Encounter.__index=Encounter

function Encounter.new(story)
    local self=setmetatable({story=story,data=story.step.challenge,enemies={},closed=false,attempt=0},Encounter)
    self:reset(false)
    return self
end

function Encounter:position()
    if self.data.kind=="vigil" then
        local id=self.data.checkpoints[math.min(self.watchIndex,#self.data.checkpoints)]
        return self.story.mission.room.anchors[id].Position
    end
    return self.story.mission.room.anchors[self.story.step.target].Position
end

function Encounter:clearEnemies()
    for _,enemy in ipairs(self.enemies) do self.story.game.combat:remove(enemy) end
    self.enemies={};self.enemy=nil;self.story.mission.enemy=nil
end

function Encounter:spawn(id,position,boss)
    local attempt=self.attempt
    local definition=table.clone(Content.characters[id])
    if boss then definition.color={119,144,107};definition.skinColor={119,144,107} end
    local model,humanoid,root=Rig.create(World.Actors,position,definition)
    if boss then Rig.handDemon(model);model:ScaleTo(1.5) end
    local enemy=self.story.game.combat:register(model,humanoid,root,{
        kind="npc",mode="Story",zone=self.story:actor().zone,room=self.story.mission.room,characterId=id,
        maxHealth=self.data.health,basicOnly=not self.data.techniques,attackInterval=1.5,damageScale=self.data.damageScale or 1,
        healthFloor=self.data.kind=="hold" and 1 or nil,
        onDamaged=function(source,damage)
            if not self.closed and self.attempt==attempt and source==self.story:actor() and damage>0 then self.hits+=1 end
        end,
        target=not boss and self.story:actor() or nil,damageMultiplier=boss and 0 or 1,
        controlImmuneUntil=boss and math.huge or 0,
    })
    enemy.invulnerableUntil=workspace:GetServerTimeNow()+0.6
    table.insert(self.enemies,enemy)
    if boss then self.enemy=enemy;self.story.mission.enemy=enemy;model:SetAttribute("BossPhase","pursuit") end
    pcall(function() root:SetNetworkOwner(nil) end)
    return enemy
end

function Encounter:reset(retry)
    local actor=self.story:actor()
    if self.closed or not actor or not actor.alive then return end
    self:clearEnemies();self.attempt+=1
    local now=workspace:GetServerTimeNow()
    self.started=now;self.deadline=now+self.data.limit;self.defeated=0;self.watchIndex=1;self.waveActive=false;self.hits=0;self.nextAlly=now+1
    self.phase="pursuit";self.nextAttack=now+1.8;self.attack=nil;self.attackNumber=0
    self.story:freeze(false)
    actor.castToken+=1;actor.storyCanBasic=true;actor.storyMoves={};actor.healthFloor=1;actor.basicStyle="water"
    for _,id in ipairs(self.story.data.loadout) do actor.storyMoves[id]=true end
    actor.humanoid.Health=actor.humanoid.MaxHealth;actor.energy=100;actor.status={};actor.stunUntil=0;actor.busyUntil=0;actor.blocking=false
    actor.cooldowns={};actor.invulnerableUntil=now+1.5
    -- Time spent in dialogue must not trigger auto-sheathe as control returns for a fight.
    actor.weaponSince=now
    actor.model:PivotTo(CFrame.new(self.story.mission.room.center+Vector3.new(table.unpack(self.data.start))))
    actor.lastPosition=actor.root.Position;actor.motionTime=now;actor.root.AssemblyLinearVelocity=Vector3.zero
    if self.data.kind=="hand_boss" then
        self:spawn("hand_demon",self.story.mission.room.center+Vector3.new(table.unpack(self.data.spawn)),true)
    elseif self.data.kind=="battle" or self.data.kind=="hold" then
        for _,definition in ipairs(self.data.enemies) do self:spawn(definition.id,self.story.mission.room.center+Vector3.new(table.unpack(definition.position)),false) end
    end
    self:updateMarker();self.story.serial+=1
    if retry then self.story.game:toast(self.story.player,"Catch your breath. This encounter restarts from its checkpoint.") end
end

function Encounter:updateMarker()
    self.story:clearPrompt()
    local anchor=self.data.kind=="vigil" and self.story.mission.room.anchors[self.data.checkpoints[math.min(self.watchIndex,#self.data.checkpoints)]] or self.story.mission.room.anchors[self.story.step.target]
    self.story:mark(anchor,self.data.kind=="vigil" and "Night patrol "..math.min(self.watchIndex,#self.data.checkpoints) or "Keep your guard up")
end

-- Focus requests are reserved for the Sagiri timing exercises.
function Encounter:focus() return false end

function Encounter:beginAttack(now)
    local boss,actor=self.enemy,self.story:actor()
    if not boss or not boss.alive or not actor then return end
    local delta=actor.root.Position-boss.root.Position
    local flat=Vector3.new(delta.X,0,delta.Z)
    local direction=flat.Magnitude>0.01 and flat.Unit or -Vector3.zAxis
    self.attackNumber+=1
    local sweep=self.attackNumber%2==0
    self.attack={origin=boss.root.Position,direction=direction,pattern=sweep and "spin" or "thrust",range=sweep and self.data.sweep or self.data.reach,width=self.data.width}
    self.phase="windup";self.strikeAt=now+self.data.windup
    boss.damageMultiplier=0;boss.humanoid:Move(Vector3.zero);boss.root.Anchored=true
    boss.root.AssemblyLinearVelocity=Vector3.zero;boss.root.AssemblyAngularVelocity=Vector3.zero
    boss.root.CFrame=CFrame.lookAt(boss.root.Position,boss.root.Position+direction)
    boss.model:SetAttribute("BossPhase",self.phase)
    boss.model:SetAttribute("Pose",sweep and "barrage" or "thrust");boss.model:SetAttribute("PoseStart",now);boss.model:SetAttribute("PoseDuration",self.data.windup+0.3)
    self.story.game.combat:emit(boss,"telegraph",{position=self.attack.origin,direction=direction,color={172,193,131},duration=self.data.windup,pattern=self.attack.pattern,range=self.attack.range,width=self.attack.width})
end

function Encounter:resolveAttack(now)
    local boss,actor,attack=self.enemy,self.story:actor(),self.attack
    if not boss or not boss.alive or not actor or not attack or self.phase~="windup" or now<self.strikeAt then return end
    local point=CFrame.lookAt(attack.origin,attack.origin+attack.direction):PointToObjectSpace(actor.root.Position)
    if math.abs(point.Y)<5 and Rules.inShape(attack.pattern,-point.Z,point.X,attack.range,attack.width) and self.story.game.combat:lineOfSight(boss,actor,attack.origin) then
        self.story.game.combat:damage(boss,actor,self.data.damage,"none")
    end
    self.story.game.combat:emit(boss,"cast",{position=attack.origin,direction=attack.direction,color={172,193,131},pattern=attack.pattern,range=attack.range,width=attack.width})
    self.phase="exposed";self.exposedUntil=now+self.data.recovery;self.attack=nil
    -- Recovery is a planted opening; release physics only when pursuit resumes.
    boss.damageMultiplier=1;boss.model:SetAttribute("BossPhase",self.phase)
end

function Encounter:tick(now)
    local actor=self.story:actor()
    if self.closed or not actor or not actor.alive then return end
    if actor.humanoid.Health<=1 or now>self.deadline then self:reset(true);return end
    if self.data.kind~="vigil" and (actor.root.Position-(self.story.mission.room.center+Vector3.new(table.unpack(self.data.start)))).Magnitude>self.data.radius+15 then self:reset(true);return end
    local alive=0
    for _,enemy in ipairs(self.enemies) do
        if enemy.alive then alive+=1
        elseif not enemy.encounterCounted then
            enemy.encounterCounted=true;self.defeated+=1
            self.story.game.combat:emit(enemy,"defeat",{position=enemy.root.Position,color={174,186,179}})
            self.story.game.combat:remove(enemy)
        end
    end
    if self.data.kind=="hand_boss" then
        if alive==0 then self.story:finishChallenge();return end
        local boss=self.enemy
        if self.phase=="windup" and now>=self.strikeAt then self:resolveAttack(now)
        elseif self.phase=="exposed" and now>=self.exposedUntil then
            self.phase="pursuit";boss.damageMultiplier=0;self.nextAttack=now+1.2;boss.model:SetAttribute("BossPhase",self.phase)
            boss.root.Anchored=false;boss.root.AssemblyLinearVelocity=Vector3.zero
            pcall(function() boss.root:SetNetworkOwner(nil) end)
        elseif self.phase=="pursuit" then
            local delta=actor.root.Position-boss.root.Position
            local distance=Vector2.new(delta.X,delta.Z).Magnitude
            if distance>12 then boss.humanoid:MoveTo(actor.root.Position) else boss.humanoid:Move(Vector3.zero) end
            if now>=self.nextAttack and distance<=self.data.reach then self:beginAttack(now) end
        end
    elseif self.data.kind=="hold" then
        if self.data.ally and now>=self.nextAlly then
            self.nextAlly=now+2;self.story:pose(self.story.npcs[self.data.ally],"kick",0.7)
        end
        if self.hits>=self.data.hits and now-self.started>=self.data.duration then self.story:finishChallenge() end
    elseif self.data.kind=="battle" then
        if alive==0 then self.story:finishChallenge() end
    else
        if self.waveActive and alive==0 then
            self.waveActive=false;self.watchIndex+=1;self:updateMarker()
        end
        if self.watchIndex>#self.data.checkpoints then
            if now-self.started>=self.data.duration then self.story:finishChallenge() end
        elseif not self.waveActive and (actor.root.Position-self:position()).Magnitude<self.data.radius then
            self:spawn("demon_scout",self:position()+Vector3.new(-5,0,-12),false)
            self.waveActive=true
        end
    end
end

function Encounter:snapshot()
    return {kind=self.data.kind,combat=true,defeated=self.defeated,total=self.data.kind=="vigil" and #self.data.checkpoints or self.data.enemies and #self.data.enemies or 1,
        remaining=math.max(0,math.ceil(self.deadline-workspace:GetServerTimeNow())),phase=self.phase,hits=self.hits,goal=self.data.hits,
        bossHp=self.enemy and self.enemy.humanoid.Health,bossMax=self.data.health,
        watchIndex=self.watchIndex,holdRemaining=self.data.duration and math.max(0,math.ceil(self.data.duration-(workspace:GetServerTimeNow()-self.started))) or nil}
end

function Encounter:destroy()
    if self.closed then return end
    self.closed=true;self:clearEnemies();self.story:clearPrompt()
    local actor=self.story:actor()
    if actor then
        self.story.game.combat:stopMotion(actor)
        actor.storyCanBasic=false;actor.storyMoves=nil;actor.healthFloor=nil;actor.basicStyle=nil;actor.blocking=false;actor.castToken+=1
    end
end
return Encounter
