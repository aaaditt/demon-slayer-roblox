local Encounter=require(script.Parent.Encounter)
local Rig=require(script.Parent.Rig)
local Rules=require(game:GetService("ReplicatedStorage").Shared.Rules)
local SwampEncounter=setmetatable({}, {__index=Encounter})
SwampEncounter.__index=SwampEncounter

function SwampEncounter.new(story)
    local self=setmetatable({story=story,data=story.step.challenge,enemies={},closed=false,attempt=0},SwampEncounter)
    self:reset(false);return self
end
function SwampEncounter:position()
    return self.story.mission.room.center+Vector3.new(table.unpack(self.data.start))
end
function SwampEncounter:updateMarker()
    self.story:clearPrompt()
    self.story:mark(self.story.mission.room.anchors[self.data.mode=="depths" and "depths" or "courtyard"],"Watch the pools")
end
function SwampEncounter:reset(retry)
    if self.closed then return end
    self:finishAllyMotion()
    if self.pools then self.pools:Destroy() end
    Encounter.reset(self,retry)
    self.hits=0;self.turn=0;self.active=nil;self.phase="submerged";self.phaseAt=workspace:GetServerTimeNow();self.nextPhase=self.phaseAt+1
    self.pools=Instance.new("Folder");self.pools.Name="ActiveSwampPools";self.pools.Parent=self.story.mission.room.folder
    for i,coords in ipairs(self.data.pools) do
        local home=self.story.mission.room.center+Vector3.new(table.unpack(coords))
        local enemy=self:spawn("swamp_demon",home,false)
        enemy.target=nil;enemy.root.Anchored=true;enemy.controlImmuneUntil=math.huge
        enemy.damageMultiplier=0;enemy.home=home;enemy.healthFloor=self.data.mode=="ambush" and 1 or nil
        Rig.swampBody(enemy.model,i)
        for _,p in ipairs(enemy.model:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false;p.CanQuery=false end end
        enemy.root.CFrame=CFrame.new(home-Vector3.yAxis*8)
        enemy.onDamaged=function(source)
            if source==self.story:actor() then self.hits+=1 end
        end
        local pool=Instance.new("Part");pool.Name="SwampPool";pool.Anchored=true;pool.CanCollide=false;pool.CanTouch=false;pool.CanQuery=false
        pool.Size=Vector3.new(9,0.15,9);pool.Color=Color3.fromRGB(26,77,75);pool.Material=Enum.Material.Glass
        pool.Position=home-Vector3.yAxis*2.8;pool.Parent=self.pools
    end
end
function SwampEncounter:beginRise(now)
    local living={}
    for _,enemy in ipairs(self.enemies) do if enemy.alive then table.insert(living,enemy) end end
    if #living==0 then return end
    self.turn+=1;self.active=living[(self.turn-1)%#living+1]
    local boss=self.active;local delta=self.story:actor().root.Position-boss.home
    local flat=Vector3.new(delta.X,0,delta.Z);self.direction=flat.Magnitude>0.01 and flat.Unit or Vector3.zAxis
    self.phase="rising";self.phaseAt=now;self.nextPhase=now+0.65
    boss.model:SetAttribute("Pose","emerge");boss.model:SetAttribute("PoseStart",now);boss.model:SetAttribute("PoseDuration",0.65)
end
function SwampEncounter:resolveAttack(now)
    local boss,actor=self.active,self.story:actor()
    if self.closed or self.phase~="windup" or now<self.nextPhase or not boss or not boss.alive or not actor then return end
    local point=CFrame.lookAt(boss.home,boss.home+self.direction):PointToObjectSpace(actor.root.Position)
    if math.abs(point.Y)<5 and Rules.inShape("thrust",-point.Z,point.X,self.data.reach,self.data.width)
        and self.story.game.combat:lineOfSight(boss,actor,boss.home) then
        self.story.game.combat:damage(boss,actor,self.data.damage,"none")
    end
    self.story.game.combat:emit(boss,"cast",{position=boss.home,direction=self.direction,color={88,167,155},pattern="thrust",range=self.data.reach,width=self.data.width})
    self.phase="exposed";self.phaseAt=now;self.nextPhase=now+self.data.recovery;boss.damageMultiplier=1
    boss.model:SetAttribute("Pose","recoil");boss.model:SetAttribute("PoseStart",now);boss.model:SetAttribute("PoseDuration",0.5)
    if self.data.mode=="last" then
        -- Nezuko keeps the survivors' side of the courtyard safe and creates this opening.
        local nezuko=self.story.npcs.nezuko
        if nezuko then
            self.story:pose(nezuko,"kick",0.7)
            self.allyMove={model=nezuko,home=nezuko:GetPivot(),to=CFrame.lookAt(boss.home+Vector3.zAxis*4,boss.home),start=now}
        end
    end
end
function SwampEncounter:tick(now)
    local actor=self.story:actor()
    if self.closed or not actor or not actor.alive then return end
    if self.allyMove then
        local m=self.allyMove;local t=now-m.start
        local alpha=t<0.3 and t/0.3 or t<0.7 and 1 or math.max(0,1-(t-0.7)/0.4)
        m.model:PivotTo(m.home:Lerp(m.to,alpha))
        if t>=1.1 then self:finishAllyMotion() end
    end
    if actor.humanoid.Health<=1 or now>self.deadline or (actor.root.Position-self:position()).Magnitude>self.data.radius+15 then self:reset(true);return end
    local alive=0
    for _,enemy in ipairs(self.enemies) do
        if enemy.alive then alive+=1
        elseif not enemy.encounterCounted then
            enemy.encounterCounted=true;self.defeated+=1
            self.story.game.combat:emit(enemy,"defeat",{position=enemy.root.Position,color={108,163,150}})
            self.story.game.combat:remove(enemy)
        end
    end
    if (self.data.mode=="ambush" and self.hits>=self.data.hits and now-self.started>=self.data.duration) or alive==0 then self.story:finishChallenge();return end
    local boss=self.active
    if boss and not boss.alive then self.active=nil;boss=nil;self.phase="submerged";self.nextPhase=now+0.7 end
    if self.phase=="submerged" then
        if now>=self.nextPhase then self:beginRise(now) end
    elseif self.phase=="rising" or self.phase=="sinking" then
        local alpha=math.clamp((now-self.phaseAt)/0.65,0,1)
        local height=self.phase=="rising" and (-8+8*alpha) or -8*alpha
        local pos=boss.home+Vector3.yAxis*height
        boss.root.CFrame=CFrame.lookAt(pos,pos+self.direction)
        if now>=self.nextPhase then
            if self.phase=="rising" then
                self.phase="windup";self.nextPhase=now+self.data.windup
                boss.model:SetAttribute("Pose","thrust");boss.model:SetAttribute("PoseStart",now);boss.model:SetAttribute("PoseDuration",self.data.windup)
                self.story.game.combat:emit(boss,"telegraph",{position=boss.home,direction=self.direction,color={88,167,155},duration=self.data.windup,pattern="thrust",range=self.data.reach,width=self.data.width})
            else self.phase="submerged";self.nextPhase=now+0.7 end
        end
    elseif self.phase=="windup" then self:resolveAttack(now)
    elseif self.phase=="exposed" and now>=self.nextPhase then
        self.phase="sinking";self.phaseAt=now;self.nextPhase=now+0.65;boss.damageMultiplier=0
        boss.model:SetAttribute("Pose","emerge");boss.model:SetAttribute("PoseStart",now);boss.model:SetAttribute("PoseDuration",0.65)
    end
end
function SwampEncounter:snapshot()
    return {kind="swamp",combat=true,mode=self.data.mode,phase=self.phase,hits=self.hits,goal=self.data.hits,
        holdRemaining=math.max(0,math.ceil(self.data.duration-(workspace:GetServerTimeNow()-self.started))),
        defeated=self.defeated,total=self.data.bodyCount,remaining=math.max(0,math.ceil(self.deadline-workspace:GetServerTimeNow()))}
end
function SwampEncounter:destroy()
    self:finishAllyMotion()
    if self.pools then self.pools:Destroy();self.pools=nil end
    Encounter.destroy(self)
end
function SwampEncounter:finishAllyMotion()
    if self.allyMove then
        if self.allyMove.model.Parent then self.allyMove.model:PivotTo(self.allyMove.home) end
        self.allyMove=nil
    end
end
return SwampEncounter
