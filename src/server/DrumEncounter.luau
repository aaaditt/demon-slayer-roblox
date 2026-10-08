local Encounter=require(script.Parent.Encounter)
local Rules=require(game:GetService("ReplicatedStorage").Shared.Rules)
local DrumEncounter=setmetatable({}, {__index=Encounter})
DrumEncounter.__index=DrumEncounter

function DrumEncounter.new(story)
    local self=setmetatable({story=story,data=story.step.challenge,enemies={},closed=false,attempt=0},DrumEncounter)
    self:reset(false);return self
end
function DrumEncounter:position()
    return self.story.mission.room.arenaBase.Position+Vector3.yAxis*3
end
function DrumEncounter:clearTurn()
    local turn=self.turn
    if not turn then return end
    self.turn=nil
    local actor=turn.actor
    if actor.model.Parent then
        actor.root.Anchored=turn.anchored;actor.root.AssemblyLinearVelocity=Vector3.zero
        actor.model:SetAttribute("InCutscene",false)
        actor.busyUntil=math.max(workspace:GetServerTimeNow(),turn.busyUntil)
        actor.lastPosition=actor.root.Position;actor.motionTime=workspace:GetServerTimeNow()
        if not turn.anchored then pcall(function() actor.root:SetNetworkOwner(actor.player) end) end
    end
end
function DrumEncounter:reset(retry)
    if self.closed then return end
    self:clearTurn()
    local room=self.story.mission.room
    room.arena:PivotTo(room.arenaBase);room.arena:SetAttribute("Turns",0)
    Encounter.reset(self,retry)
    self.turnNumber=0;self.phase="waiting";self.nextPhase=workspace:GetServerTimeNow()+1;self.lanes=nil
    local boss=self:spawn("kyogai",self:position(),false)
    self.enemy=boss;self.story.mission.enemy=boss
    boss.target=nil;boss.root.Anchored=true;boss.damageMultiplier=0;boss.controlImmuneUntil=math.huge
    boss.model:SetAttribute("BossPhase",self.phase)
end
function DrumEncounter:beginTurn(now)
    local actor,boss=self.story:actor(),self.enemy
    if self.closed or self.turn or not actor or not boss or not boss.alive then return end
    self.story.game.combat:stopMotion(actor);actor.castToken+=1
    local room=self.story.mission.room
    self.turnNumber+=1
    self.turn={actor=actor,anchored=actor.root.Anchored,busyUntil=actor.busyUntil,
        playerFrom=actor.root.CFrame,bossFrom=boss.root.CFrame,roomFrom=room.arena:GetPivot(),
        roomTo=room.arenaBase*CFrame.Angles(0,self.turnNumber*math.pi/2,0),started=now}
    actor.root.Anchored=true;actor.root.AssemblyLinearVelocity=Vector3.zero
    actor.model:SetAttribute("InCutscene",true);actor.busyUntil=math.max(actor.busyUntil,now+self.data.turnTime)
    boss.damageMultiplier=0;self.phase="turning";self.nextPhase=now+self.data.turnTime
    boss.model:SetAttribute("BossPhase",self.phase);self.story:pose(boss.model,"barrage",self.data.turnTime)
    room.arena:SetAttribute("Turns",self.turnNumber)
end
function DrumEncounter:beginClaws(now)
    local actor,boss=self.story:actor(),self.enemy
    local delta=actor.root.Position-boss.root.Position
    local flat=Vector3.new(delta.X,0,delta.Z)
    local direction=flat.Magnitude>0.01 and flat.Unit or Vector3.zAxis
    local right=direction:Cross(Vector3.yAxis)
    self.phase="windup";self.nextPhase=now+self.data.windup;self.lanes={}
    boss.root.CFrame=CFrame.lookAt(boss.root.Position,boss.root.Position+direction)
    boss.model:SetAttribute("BossPhase",self.phase);self.story:pose(boss.model,"barrage",self.data.windup)
    for _,offset in ipairs({-self.data.laneGap,0,self.data.laneGap}) do
        local lane={origin=boss.root.Position+right*offset,direction=direction}
        table.insert(self.lanes,lane)
        self.story.game.combat:emit(boss,"telegraph",{position=lane.origin,direction=direction,color={208,155,105},duration=self.data.windup,pattern="thrust",range=self.data.reach,width=self.data.width})
    end
end
function DrumEncounter:resolveClaws(now)
    local actor,boss=self.story:actor(),self.enemy
    if self.closed or self.phase~="windup" or now<self.nextPhase or not actor or not boss or not boss.alive then return end
    local hit=false
    for _,lane in ipairs(self.lanes) do
        local point=CFrame.lookAt(lane.origin,lane.origin+lane.direction):PointToObjectSpace(actor.root.Position)
        if math.abs(point.Y)<5 and Rules.inShape("thrust",-point.Z,point.X,self.data.reach,self.data.width)
            and self.story.game.combat:lineOfSight(boss,actor,lane.origin) then hit=true end
        self.story.game.combat:emit(boss,"cast",{position=lane.origin,direction=lane.direction,color={208,155,105},pattern="thrust",range=self.data.reach,width=self.data.width})
    end
    if hit then self.story.game.combat:damage(boss,actor,self.data.damage,"none") end
    self.lanes=nil;self.phase="exposed";self.nextPhase=now+self.data.recovery
    boss.damageMultiplier=1;boss.model:SetAttribute("BossPhase",self.phase);self.story:pose(boss.model,"recoil",0.4)
end
function DrumEncounter:tick(now)
    local actor,boss=self.story:actor(),self.enemy
    if self.closed or not actor or not actor.alive then return end
    if actor.humanoid.Health<=1 or now>self.deadline or (actor.root.Position-self:position()).Magnitude>self.data.radius+15 then self:reset(true);return end
    if not boss.alive then self.defeated=1;self.story:finishChallenge();return end
    if self.phase=="turning" then
        local turn=self.turn
        local alpha=math.clamp((now-turn.started)/self.data.turnTime,0,1)
        local pivot=turn.roomFrom:Lerp(turn.roomTo,alpha)
        local delta=pivot*turn.roomFrom:Inverse()
        self.story.mission.room.arena:PivotTo(pivot)
        actor.root.CFrame=delta*turn.playerFrom;boss.root.CFrame=delta*turn.bossFrom
        actor.lastPosition=actor.root.Position;actor.motionTime=now
        if now>=self.nextPhase then self:clearTurn();self:beginClaws(now) end
    elseif self.phase=="windup" then self:resolveClaws(now)
    elseif now>=self.nextPhase then self:beginTurn(now) end
end
function DrumEncounter:snapshot()
    local state=Encounter.snapshot(self);state.turns=self.turnNumber;return state
end
function DrumEncounter:destroy()
    self:clearTurn()
    local room=self.story.mission.room
    if room.arena.Parent then room.arena:PivotTo(room.arenaBase) end
    Encounter.destroy(self)
end
return DrumEncounter
