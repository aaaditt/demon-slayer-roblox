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

check("tanjiro spawns as R15 with sword on left hip and draws to right hand",function()
    local CharacterBody=require(ServerScriptService.Server.CharacterBody)
    local SwordBuilder=require(ServerScriptService.Server.SwordBuilder)
    local model,humanoid,root=CharacterBody.create(World.Actors,Vector3.new(0,6,0),Content.characters.tanjiro,"TanjiroTest",{swordVariant="tanjiro_black"})
    assert(model and humanoid.RigType==Enum.HumanoidRigType.R15 and model.PrimaryPart==root,"R15 body")
    assert(model:GetAttribute("RigKind")=="R15" and model:GetAttribute("HasSheath") and not model:GetAttribute("WeaponDrawn"))
    print("R15 Animate script present:",model:FindFirstChild("Animate")~=nil)
    local grip=model.Sword.SwordGrip
    assert(grip.Part0==model.LowerTorso,"sheathed on hip")
    local saya=model.Sword.Saya
    assert(model.LowerTorso.CFrame:PointToObjectSpace(saya.Position).X<0,"saya on left hip")
    assert(model.Sword.Blade.Transparency==1 and not model.Sword.Blade.CanQuery)
    SwordBuilder.setDrawn(model,true)
    assert(grip.Part0==model.RightHand and model:GetAttribute("WeaponDrawn") and model.Sword.Blade.Transparency==0,"drawn to right hand")
    assert(model.Sword:FindFirstChild("TsubaSpoke"),"wagon-wheel tsuba")
    assert(model:FindFirstChild("FallbackLook"),"fallback look without uploaded assets")
    assert(CharacterBody.create(World.Actors,Vector3.zero,Content.characters.zenitsu,"Z",{})==nil,"only kits get R15")
    model:Destroy()
    local flame=CharacterBody.create(World.Actors,Vector3.new(0,6,0),Content.characters.tanjiro,"TanjiroFlame",{swordVariant="tanjiro_yoriichi"})
    assert(flame.Sword:FindFirstChild("TsubaFlame"),"Rengoku flame tsuba")
    flame:Destroy()
end)

-- R15 sword kit (Tanjiro). combat:tick runs from Heartbeat here so forced motion and stuns resolve as in play.
do
    local RunService=game:GetService("RunService")
    local CharacterBody=require(ServerScriptService.Server.CharacterBody)
    local SwordBuilder=require(ServerScriptService.Server.SwordBuilder)
    local AnimSets=require(ReplicatedStorage.Shared.AnimSets)
    local Config=require(ReplicatedStorage.Shared.Config)
    local M=Config.Melee
    local events={}
    local meleeCombat=Combat.new({FireAllClients=function(_,e) table.insert(events,e) end})
    local ticking=RunService.Heartbeat:Connect(function(dt) meleeCombat:tick(dt) end)
    local base=World.Hub.center+Vector3.new(40,4,40)
    local function swordsman(offset,kind)
        local model,humanoid,root=CharacterBody.create(World.Actors,base+offset,Content.characters.tanjiro,"Swordsman"..kind)
        local a=meleeCombat:register(model,humanoid,root,{kind=kind,mode="Story",zone="melee",characterId="tanjiro",room=World.Hub})
        a.invulnerableUntil=0
        return a
    end
    local function dummy(offset)
        local model,humanoid,root=Rig.create(World.Actors,base+offset,Content.characters.akaza)
        local a=meleeCombat:register(model,humanoid,root,{kind="npc",mode="Story",zone="melee",characterId="akaza",room=World.Hub})
        a.invulnerableUntil=0
        return a
    end
    local function face(a,b)
        local p=a.root.Position
        a.root.CFrame=CFrame.lookAt(p,Vector3.new(b.root.Position.X,p.Y,b.root.Position.Z))
    end
    local function lastHit(target)
        for i=#events,1,-1 do if events[i].kind=="hit" and events[i].actor==target.model then return events[i] end end
    end

    check("sword kit M1 string lands four cuts and the finisher launches",function()
        local a=swordsman(Vector3.zero,"player")
        local b=dummy(Vector3.new(0,0,-5))
        a.root.Anchored=true;face(a,b)
        assert(meleeCombat:basic(a,a.root.CFrame.LookVector),"draw then swing admitted")
        task.wait(AnimSets.Tanjiro.draw.markers.End+0.05)
        local health=b.humanoid.Health
        for i=1,4 do
            local anim=AnimSets.Tanjiro["m1_"..i]
            if i>1 then assert(meleeCombat:basic(a,a.root.CFrame.LookVector),"swing "..i.." admitted") end
            assert(a.model:GetAttribute("Anim")=="m1_"..i,"anim m1_"..i)
            task.wait(i<4 and anim.markers.CanChain+0.03 or anim.markers.Hit+0.03)
            local hit=lastHit(b)
            assert(hit and hit.result=="hit" and hit.source=="m1","cut "..i.." connected")
            if i<4 then assert(b.stunUntil>workspace:GetServerTimeNow(),"hitstun "..i) end
        end
        assert(math.abs((health-b.humanoid.Health)-(3*M.Damage+M.FinisherDamage))<0.01,"damage "..(health-b.humanoid.Health))
        -- Edit-mode runs do not simulate physics; verify the server launched a forced knockback away from the attacker.
        local m=b.motion
        assert(m and m.forced and m.distance>=15 and m.direction:Dot(a.root.CFrame.LookVector)>0.9,"finisher knockback motion")
        assert(not meleeCombat:basic(a,a.root.CFrame.LookVector),"end lag after finisher")
        meleeCombat:remove(a);meleeCombat:remove(b)
    end)

    check("sword kit misses targets behind the swordsman",function()
        local a=swordsman(Vector3.zero,"player")
        local b=dummy(Vector3.new(0,0,-5))
        a.root.Anchored=true;b.root.Anchored=true
        face(a,b);a.root.CFrame*=CFrame.Angles(0,math.pi,0)
        SwordBuilder.setDrawn(a.model,true)
        local health=b.humanoid.Health
        assert(meleeCombat:basic(a,a.root.CFrame.LookVector))
        task.wait(AnimSets.Tanjiro.m1_1.markers.End)
        assert(b.humanoid.Health==health,"hit behind")
        meleeCombat:remove(a);meleeCombat:remove(b)
    end)

    check("block stops frontal M1s, finisher breaks guard, techniques pass block",function()
        local a=swordsman(Vector3.zero,"player")
        local b=swordsman(Vector3.new(0,0,-5),"npc")
        a.root.Anchored=true;b.root.Anchored=true
        face(a,b);face(b,a)
        SwordBuilder.setDrawn(a.model,true)
        meleeCombat:guard(b,true)
        assert(b.blocking and b.model:GetAttribute("Anim")=="block")
        task.wait(M.ParryWindow+0.05)
        local health=b.humanoid.Health
        for i=1,3 do
            assert(meleeCombat:basic(a,a.root.CFrame.LookVector),"swing "..i)
            task.wait(AnimSets.Tanjiro["m1_"..i].markers.CanChain+0.03)
            assert(lastHit(b).result=="block","cut "..i.." blocked")
        end
        assert(b.humanoid.Health==health,"blocked M1s dealt damage")
        assert(meleeCombat:basic(a,a.root.CFrame.LookVector))
        task.wait(AnimSets.Tanjiro.m1_4.markers.Hit+0.05)
        assert(lastHit(b).result=="guardbreak" and not b.blocking and b.stunUntil>workspace:GetServerTimeNow()+0.5,"guard break")
        task.wait(1.2)
        b.stunUntil=0;meleeCombat:guard(b,true);task.wait(M.ParryWindow+0.05)
        a.busyUntil=0;a.cooldowns={};a.energy=100
        local before=b.humanoid.Health
        assert(meleeCombat:cast(a,Content.moves.water_1,a.root.CFrame.LookVector))
        task.wait(Content.moves.water_1.windup+0.2)
        assert(b.humanoid.Health<before,"technique was stopped by an M1-only block")
        meleeCombat:remove(a);meleeCombat:remove(b)
    end)

    check("directional dashes travel, keep facing, use separate cooldowns and grant no invulnerability",function()
        local a=swordsman(Vector3.zero,"player")
        local look=a.root.CFrame.LookVector
        assert(meleeCombat:dodge(a,look),"front dash")
        assert(a.model:GetAttribute("Anim")=="dash_f" and a.invulnerableUntil<=workspace:GetServerTimeNow(),"no i-frames")
        assert(a.motion and a.motion.distance>=18 and a.motion.direction:Dot(look)>0.95,"front dash motion")
        assert(a.root.CFrame.LookVector:Dot(look)>0.95,"facing kept")
        task.wait(M.DashDuration+0.1);meleeCombat:stopMotion(a);a.busyUntil=0
        assert(not meleeCombat:dodge(a,look),"front dash cooldown")
        assert(meleeCombat:dodge(a,a.root.CFrame.RightVector) and a.model:GetAttribute("Anim")=="dash_r","side dash on its own cooldown")
        meleeCombat:remove(a)
    end)

    check("opposing techniques within the window clash and cancel",function()
        local a=swordsman(Vector3.zero,"player")
        local b=swordsman(Vector3.new(0,0,-8),"npc")
        a.root.Anchored=true;b.root.Anchored=true
        face(a,b);face(b,a)
        for _,f in ipairs({a,b}) do SwordBuilder.setDrawn(f.model,true) end
        local ha,hb=a.humanoid.Health,b.humanoid.Health
        assert(meleeCombat:cast(b,Content.moves.water_1,b.root.CFrame.LookVector))
        task.wait(0.05)
        assert(meleeCombat:cast(a,Content.moves.water_1,a.root.CFrame.LookVector))
        local clash
        for _,e in ipairs(events) do if e.kind=="clash" then clash=e end end
        assert(clash and clash.outcome=="cancel","clash event")
        task.wait(Content.moves.water_1.windup+0.3)
        assert(a.humanoid.Health==ha and b.humanoid.Health==hb,"clashed techniques dealt damage")
        meleeCombat:remove(a);meleeCombat:remove(b)
    end)
    ticking:Disconnect()
end

print(string.format("STUDIO_RESULT %d passed / %d failed",passed,#failures))
if #failures>0 then error(table.concat(failures,"\n")) end
