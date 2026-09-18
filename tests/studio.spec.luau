-- Execute using run-in-roblox --place build/WisteriaChronicles.rbxlx --script tests/studio.spec.luau.
-- This is server/engine smoke coverage, not a multi-client or visual playtest.
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local ServerScriptService=game:GetService("ServerScriptService")
local Content=require(ReplicatedStorage.Shared.Content)
local Rig=require(ServerScriptService.Server.Rig)
local World=require(ServerScriptService.Server.World)
local Combat=require(ServerScriptService.Server.Combat)
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
