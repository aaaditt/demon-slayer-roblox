-- Execute using run-in-roblox --place build/WisteriaChronicles.rbxlx --script tests/studio.spec.luau.
-- This is server/engine smoke coverage, not a multi-client or visual playtest.
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local ServerScriptService=game:GetService("ServerScriptService")
local Content=require(ReplicatedStorage.Shared.Content)
local Rig=require(ServerScriptService.Server.Rig)
local World=require(ServerScriptService.Server.World)
local Combat=require(ServerScriptService.Server.Combat)
local Encounter=require(ServerScriptService.Server.Encounter)
local SwampEncounter=require(ServerScriptService.Server.SwampEncounter)
local failures={}
local passed=0
local function check(name,run)
    local ok,err=pcall(run)
    if ok then passed+=1;print("PASS "..name) else table.insert(failures,name..": "..tostring(err));warn("FAIL "..name..": "..tostring(err)) end
end
local effects={FireAllClients=function() end}
local world=World.init()
local combat=Combat.new(effects)

check("all character rigs have required R6 joints and humanoids",function()
    for _,c in pairs(Content.characters) do
        if c.playable then
            local model,humanoid,root=Rig.create(World.Actors,Vector3.new(0,4,0),c)
            assert(model.PrimaryPart==root and humanoid.RigType==Enum.HumanoidRigType.R6,c.id)
            assert(model.Torso:FindFirstChild("Right Shoulder") and root:FindFirstChild("RootJoint"),c.id)
            model:Destroy()
        end
    end
end)

check("all location themes produce bounded mission rooms",function()
    local index=0
    for _,location in pairs(Content.locations) do
        index+=1
        local room=World.mission(index,location)
        assert(World.inside(room,room.spawn),location.id)
        assert(World.inside(room,room.bossSpawn),location.id)
        assert(room.folder:FindFirstChild("Ground"),location.id)
        World.remove(index)
    end
end)

check("Kamado prologue has an enterable house and every objective anchor",function()
    local story=Content.chapters[1].story
    local room=World.mission(1,Content.locations.kamado,story)
    assert(room.folder:FindFirstChild("KamadoHouse"),"house missing")
    for _,step in ipairs(story.steps) do
        if step.target then assert(room.anchors[step.target] and World.inside(room,room.anchors[step.target].Position),step.id) end
    end
    local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={room.folder};params.RespectCanCollide=true
    assert(not workspace:Blockcast(CFrame.new(room.center+Vector3.new(0,3,-100)),Vector3.new(2,4,2),Vector3.new(0,0,-17),params),"house doorway is blocked")
    World.remove(1)
end)

local function actor(id,kind,position)
    local model,humanoid,root=Rig.create(World.Actors,position,Content.characters[id])
    root.Anchored=true
    local a=combat:register(model,humanoid,root,{kind=kind,mode="Story",zone="test",characterId=id,room=World.Hub})
    a.invulnerableUntil=0
    return a
end

check("Sagiri contains accessible interiors, course surfaces and a splittable boulder",function()
    local chapter=Content.chapters[2]
    local room=World.mission(1,Content.locations[chapter.location],chapter.story)
    assert(room.folder:FindFirstChild("MountainTemple") and room.folder:FindFirstChild("UrokodakiHouse"))
    local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={room.folder};params.RespectCanCollide=true
    for _,door in ipairs({Vector3.new(-112,4,63),Vector3.new(-48,4,107)}) do
        assert(not workspace:Blockcast(CFrame.new(room.center+door),Vector3.new(2,4,2),Vector3.new(0,0,-19),params),"blocked doorway")
    end
    for id,anchor in pairs(room.anchors) do
        assert(World.inside(room,anchor.Position),id)
        local floor=workspace:Raycast(anchor.Position+Vector3.yAxis*3,-Vector3.yAxis*12,params)
        assert(floor and floor.Normal.Y>0.8,"objective has no walkable floor: "..id)
    end
    assert(#room.hazards==3 and #room.boulder==2)
    for _,half in ipairs(room.boulder) do assert((half.open.Position-half.closed.Position).Magnitude>3) end
    World.remove(1)
end)

check("training admits basic strikes, rejects forms and cannot kill the sparring partner",function()
    local a=actor("tanjiro","player",Vector3.new(0,4,15))
    local b=actor("sabito","npc",Vector3.new(0,4,8))
    a.storyLocked=true;a.storyCanBasic=true;a.basicStyle="practice"
    Rig.storyWeapon(a.model,"axe")
    assert(a.model.StoryWeapon:FindFirstChild("AxeHead") and not a.model:GetAttribute("HasSheath"))
    assert(not combat:cast(a,Content.moves.water_1,-Vector3.zAxis))
    assert(combat:basic(a,-Vector3.zAxis));task.wait(0.2)
    assert(b.humanoid.Health<160,"training strike missed")
    b.healthFloor=1;b.humanoid.Health=4
    local calls=0;b.onDamaged=function(source,damage) assert(source==a and damage==3);calls+=1 end
    combat:damage(a,b,50,"none")
    assert(b.humanoid.Health==1 and b.alive and calls==1,"nonlethal floor failed")
    Rig.storyWeapon(a.model,"practice")
    assert(a.model.StoryWeapon:FindFirstChild("PracticeBlade") and not a.model.StoryWeapon:FindFirstChild("AxeHead"))
    Rig.storyWeapon(a.model,nil);assert(not a.model:FindFirstChild("StoryWeapon"))
    combat:remove(a);combat:remove(b)
end)

check("Fujikasane objectives have floors and forest routes are unobstructed",function()
    local chapter=Content.chapters[3]
    local room=World.mission(1,Content.locations[chapter.location],chapter.story)
    assert(room.folder:FindFirstChild("WisteriaCrown") and room.folder:FindFirstChild("OreTable"))
    local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={room.folder};params.RespectCanCollide=true
    for _,pair in ipairs(room.paths) do
        local hit=workspace:Blockcast(CFrame.new(room.center+pair[1]+Vector3.yAxis*4),Vector3.new(2,4,2),pair[2]-pair[1],params)
        assert(not hit,"forest route blocked by "..(hit and hit.Instance.Name or ""))
    end
    for id,anchor in pairs(room.anchors) do
        assert(World.inside(room,anchor.Position),id)
        assert(workspace:Raycast(anchor.Position+Vector3.yAxis*2,-Vector3.yAxis*8,params),"missing objective floor: "..id)
    end
    World.remove(1)
end)

check("Hand Demon guarding, telegraphed damage and recovery windows are authoritative",function()
    local chapter=Content.chapters[3]
    local room=World.mission(1,Content.locations[chapter.location],chapter.story)
    local a=actor("tanjiro","player",room.center+Vector3.new(65,3,-46));a.room=room
    local finished=0
    local story={data=chapter.story,step=chapter.story.steps[5],mission={room=room},serial=0,
        actor=function() return a end,freeze=function() end,clearPrompt=function() end,mark=function() end,
        finishChallenge=function() finished+=1 end,game={combat=combat,toast=function() end,push=function() end}}
    local encounter=Encounter.new(story)
    local boss=encounter.enemy;boss.invulnerableUntil=0
    assert(boss.model.Torso:FindFirstChild("HandArm6"),"multi-arm rig missing")
    local hp=boss.humanoid.Health
    combat:damage(a,boss,50,"none");assert(boss.humanoid.Health==hp,"guarded neck took damage")
    a.root.CFrame=CFrame.new(boss.root.Position+Vector3.new(0,0,12));a.invulnerableUntil=0
    local before=a.humanoid.Health;local now=workspace:GetServerTimeNow()
    encounter:beginAttack(now)
    assert(encounter.phase=="windup" and a.humanoid.Health==before,"windup caused early damage")
    encounter:tick(now+0.4);assert(a.humanoid.Health==before)
    encounter:tick(encounter.strikeAt)
    assert(a.humanoid.Health==before-encounter.data.damage and encounter.phase=="exposed","marked attack missed")
    assert(boss.root.Anchored,"boss drifts during its recovery opening")
    combat:damage(a,boss,50,"none");assert(boss.humanoid.Health==hp-50,"recovery was not vulnerable")
    encounter:tick(encounter.exposedUntil+0.01)
    combat:damage(a,boss,50,"none");assert(boss.humanoid.Health==hp-50,"recovery window never closed")
    -- The next attack is a sweep; moving beyond its circle avoids damage.
    encounter:beginAttack(now+8);a.root.CFrame=CFrame.new(boss.root.Position+Vector3.new(0,0,20))
    before=a.humanoid.Health;encounter:resolveAttack(now+10)
    assert(a.humanoid.Health==before,"outside sweep circle was hit")
    a.humanoid.Health=1;encounter:tick(workspace:GetServerTimeNow())
    assert(encounter.attempt==2 and a.humanoid.Health==a.humanoid.MaxHealth and not boss.model.Parent,"retry leaked old boss")
    encounter:destroy();assert(not a.storyMoves and not a.healthFloor and not story.mission.enemy and finished==0)
    combat:remove(a);World.remove(1)
end)

check("town streets, rescue doorway and swamp objectives are navigable",function()
    for _,map in ipairs({"town","swamp"}) do
        local story=table.clone(Content.chapters[4].story);story.map=map
        local room=World.mission(1,Content.locations.town,story)
        local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={room.folder};params.RespectCanCollide=true
        for _,pair in ipairs(room.paths) do
            local hit=workspace:Blockcast(CFrame.new(room.center+pair[1]+Vector3.yAxis*4),Vector3.new(2,4,2),pair[2]-pair[1],params)
            assert(not hit,map.." path blocked: "..(hit and hit.Instance.Name or ""))
        end
        for id,anchor in pairs(room.anchors) do
            assert(World.inside(room,anchor.Position) and workspace:Raycast(anchor.Position+Vector3.yAxis*2,-Vector3.yAxis*8,params),id)
        end
        if map=="town" then assert(room.folder:FindFirstChild("RescueHouse") and room.folder:FindFirstChild("LostKeepsake")) end
        World.remove(1)
    end
end)

check("swamp submersion, early strike rejection, exposure, lethal damage and retry are authoritative",function()
    local data=table.clone(Content.chapters[4].story);data.map="swamp"
    local room=World.mission(1,Content.locations.town,data)
    local a=actor("tanjiro","player",room.center+Vector3.new(0,3,18));a.room=room
    local finished=0
    local story={data=data,step=data.steps[9],mission={room=room},serial=0,npcs={},
        actor=function() return a end,freeze=function() end,clearPrompt=function() end,mark=function() end,
        finishChallenge=function() finished+=1 end,game={combat=combat,toast=function() end,push=function() end}}
    local encounter=SwampEncounter.new(story)
    assert(#encounter.enemies==2 and #encounter.pools:GetChildren()==2)
    local enemy=encounter.enemies[1];enemy.invulnerableUntil=0
    local hp=enemy.humanoid.Health
    combat:damage(a,enemy,50,"none");assert(enemy.humanoid.Health==hp,"submerged demon took damage")
    local now=workspace:GetServerTimeNow();encounter:beginRise(now)
    encounter:tick(encounter.nextPhase)
    assert(encounter.phase=="windup" and math.abs(enemy.root.Position.Y-enemy.home.Y)<0.01,"rise failed")
    a.root.CFrame=CFrame.new(enemy.home+encounter.direction*7);a.invulnerableUntil=0
    local before=a.humanoid.Health
    encounter:resolveAttack(encounter.nextPhase-0.01);assert(a.humanoid.Health==before,"early claw hit")
    encounter:resolveAttack(encounter.nextPhase)
    assert(a.humanoid.Health==before-encounter.data.damage and encounter.phase=="exposed")
    combat:damage(a,enemy,30,"none");assert(enemy.humanoid.Health==hp-30)
    encounter:tick(encounter.nextPhase);assert(enemy.damageMultiplier==0)
    encounter:tick(encounter.nextPhase);assert(enemy.root.Position.Y<0,"demon failed to sink")
    a.humanoid.Health=1;local oldPools=encounter.pools;encounter:tick(workspace:GetServerTimeNow())
    assert(encounter.attempt==2 and a.humanoid.Health==a.humanoid.MaxHealth and not enemy.model.Parent and not oldPools.Parent)
    -- This plugin suite runs in edit mode, where Humanoid death simulation is stopped.
    -- Verify lethal health here; the two-client play suite requires actual Died progression.
    for _,body in ipairs(encounter.enemies) do body.damageMultiplier=1;body.invulnerableUntil=0;combat:damage(a,body,1000,"none") end
    for _,body in ipairs(encounter.enemies) do assert(body.humanoid.Health<=0,"lethal damage rejected") end
    encounter:destroy();assert(not a.storyMoves and not a.healthFloor and not room.folder:FindFirstChild("ActiveSwampPools"))
    combat:remove(a);World.remove(1)
end)

check("server cast damages an in-range enemy and rejects a cooldown replay",function()
    local a=actor("tanjiro","player",Vector3.new(0,4,0))
    local b=actor("akaza","npc",Vector3.new(0,4,-7))
    assert(combat:cast(a,Content.moves.water_1,Vector3.new(0,0,-1)))
    assert(not combat:cast(a,Content.moves.water_1,Vector3.new(0,0,-1)))
    task.wait(0.5)
    assert(b.humanoid.Health<160,"enemy took no damage")
    combat:remove(a);combat:remove(b)
end)

check("hub players and other private instances are protected",function()
    local a=actor("tanjiro","player",Vector3.new(0,4,0))
    local b=actor("giyu","player",Vector3.new(0,4,-7))
    a.mode="Hub";b.mode="Hub"
    combat:damage(a,b,50,"poison");assert(b.humanoid.Health==160)
    a.mode="Story";b.mode="Story";b.kind="npc";b.zone="other"
    combat:damage(a,b,50,"poison");assert(b.humanoid.Health==160)
    combat:remove(a);combat:remove(b)
end)

check("walls block melee and server dash collision",function()
    local a=actor("tanjiro","player",Vector3.new(0,4,0))
    local b=actor("akaza","npc",Vector3.new(0,4,-9))
    local wall=Instance.new("Part");wall.Anchored=true;wall.Size=Vector3.new(20,12,1);wall.Position=Vector3.new(0,5,-4);wall.Parent=workspace
    assert(not combat:lineOfSight(a,b,a.root.Position))
    combat:move(a,Vector3.new(0,0,-1),20)
    assert(not a.motion or a.motion.distance<3,"dash destination crossed the wall clearance")
    wall:Destroy();combat:remove(a);combat:remove(b)
end)

check("dodge starts bounded motion without teleport and cleanup removes constraints",function()
    local a=actor("tanjiro","player",Vector3.new(0,4,15))
    local start=a.root.Position
    combat:dodge(a,Vector3.xAxis)
    assert((a.root.Position-start).Magnitude<0.01,"dodge teleported")
    assert(a.motion and a.root:FindFirstChild("DashVelocity"),"dash constraint missing")
    assert(a.energy==82 and a.model:GetAttribute("Pose")=="evade")
    combat:stopMotion(a)
    assert(not a.root:FindFirstChild("DashVelocity") and not a.root:FindFirstChild("DashAttachment"))
    combat:remove(a)
end)

check("sword draw state and story combat restrictions are server controlled",function()
    local a=actor("tanjiro","player",Vector3.new(0,4,15))
    assert(a.model:FindFirstChild("Scabbard") and a.model.Torso:FindFirstChild("WeaponGrip"))
    assert(combat:weapon(a,false) and not a.model:GetAttribute("WeaponDrawn"))
    assert(not combat:weapon(a,true),"draw bypassed recovery")
    a.busyUntil=0;a.storyLocked=true
    assert(not combat:cast(a,Content.moves.water_1,Vector3.xAxis))
    assert(not combat:weapon(a,true))
    a.model:SetAttribute("InCutscene",true)
    local energy=a.energy;combat:dodge(a,Vector3.xAxis)
    assert(a.energy==energy and not a.motion,"cutscene dodge admitted")
    combat:remove(a)
end)

check("defense, status and regeneration execute inside the engine",function()
    local a=actor("shinobu","player",Vector3.new(0,4,0))
    local b=actor("akaza","npc",Vector3.new(0,4,-7))
    b.root.CFrame=CFrame.lookAt(b.root.Position,a.root.Position)
    b.blocking=true;b.blockStarted=workspace:GetServerTimeNow()-1
    combat:damage(a,b,40,"poison")
    assert(b.humanoid.Health==150 and b.energy==87)
    b.blocking=false
    combat:damage(a,b,10,"poison")
    assert(b.status.poison)
    b.humanoid.Health=80;b.busyUntil=0;b.stunUntil=0;b.energy=100
    assert(combat:cast(b,Content.moves.demon_regen,Vector3.new(0,0,1)))
    task.wait(0.9)
    assert(b.humanoid.Health==108)
    combat:remove(a);combat:remove(b)
end)

check("all move patterns execute without runtime errors",function()
    local tested={}
    for _,move in pairs(Content.moves) do
        if tested[move.pattern] then continue end
        tested[move.pattern]=true
        local a=actor("tanjiro","player",Vector3.new(0,4,0))
        local b=actor("akaza","npc",Vector3.new(0,4,-8))
        assert(combat:cast(a,move,Vector3.new(0,0,-1)))
        task.wait(move.windup+move.recovery+0.4)
        combat:remove(a);combat:remove(b)
    end
end)

print(string.format("STUDIO_RESULT %d passed / %d failed",passed,#failures))
if #failures>0 then error(table.concat(failures,"\n")) end
