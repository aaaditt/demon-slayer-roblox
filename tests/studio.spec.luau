-- Execute using run-in-roblox --place build/WisteriaChronicles.rbxlx --script tests/studio.spec.luau.
-- This is server/engine smoke coverage, not a multi-client or visual playtest.
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local ServerScriptService=game:GetService("ServerScriptService")
local Config=require(game:GetService("ReplicatedStorage").Shared.Config)
local AnimationIndex=require(game:GetService("ReplicatedStorage").Shared.AnimationIndex)
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

check("all character rigs have blocky R15 joints, humanoids and grounded feet",function()
    local joints={"Root","Waist","Neck","RightShoulder","LeftShoulder","RightElbow","LeftElbow","RightWrist","LeftWrist","RightHip","LeftHip","RightKnee","LeftKnee","RightAnkle","LeftAnkle"}
    for _,c in pairs(Content.characters) do
        if c.playable then
            local model,humanoid,root=Rig.create(World.Actors,Vector3.new(0,4,0),c)
            assert(model.PrimaryPart==root and humanoid.RigType==Enum.HumanoidRigType.R15,c.id)
            local found={}
            for _,item in ipairs(model:GetDescendants()) do if item:IsA("Motor6D") then found[item.Name]=item end end
            for _,name in ipairs(joints) do assert(found[name] and found[name].Part0 and found[name].Part1,c.id.." missing "..name) end
            -- The Humanoid floats the root base HipHeight above the floor; the soles must sit exactly there.
            local floor=root.Position.Y-root.Size.Y/2-humanoid.HipHeight
            for _,side in ipairs({"Right","Left"}) do
                local foot=model[side.."Foot"]
                assert(math.abs(foot.Position.Y-foot.Size.Y/2-floor)<0.02,c.id.." "..side.." sole off floor")
            end
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
    assert(boss.model.UpperTorso:FindFirstChild("HandArm6"),"multi-arm rig missing")
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

check("directional dashes keep facing on sides and back with their own reach and i-frames",function()
    local a=actor("tanjiro","player",Vector3.new(0,4,15))
    local function dash(direction,facing)
        combat:stopMotion(a);a.busyUntil=0;a.cooldowns.dodge=0;a.energy=100
        a.root.CFrame=CFrame.lookAt(a.root.Position,a.root.Position+Vector3.new(0,0,-1))
        local now=workspace:GetServerTimeNow()
        local kind=combat:dodge(a,direction,facing)
        return kind,a.motion and a.motion.distance or 0,a.root.CFrame.LookVector,a.invulnerableUntil-now
    end
    local cos5=math.cos(math.rad(5))
    local kind,distance,look,iframes=dash(Vector3.new(0,0,1))
    assert(kind=="back" and a.model:GetAttribute("Pose")=="dash_back","back classification")
    assert(math.abs(distance-Config.DodgeDistanceBack)<0.01 and look:Dot(Vector3.new(0,0,-1))>cos5,"back dash turned or wrong reach "..distance)
    assert(math.abs(iframes-Config.DodgeIFramesBack)<0.02,"back i-frames")
    kind,distance,look,iframes=dash(Vector3.new(-1,0,0))
    assert(kind=="left" and math.abs(distance-Config.DodgeDistanceSide)<0.01 and look:Dot(Vector3.new(0,0,-1))>cos5,"side dash turned or wrong reach")
    assert(math.abs(iframes-Config.DodgeIFramesSide)<0.02 and Config.DodgeIFramesSide<Config.DodgeIFramesFront,"side i-frames")
    kind,distance,look=dash(Vector3.xAxis,Vector3.xAxis)
    assert(kind=="front" and math.abs(distance-Config.DodgeDistance)<0.01 and look:Dot(Vector3.xAxis)>cos5,"front dash must face travel")
    -- A camera facing makes the same world direction a sidestep, and the dasher turns to that facing.
    kind,distance,look=dash(Vector3.xAxis,Vector3.new(0,0,1))
    assert(kind=="left" and look:Dot(Vector3.new(0,0,1))>cos5,"camera-relative sidestep")
    combat:remove(a)
end)

check("dodge starts bounded motion without teleport and cleanup removes constraints",function()
    local a=actor("tanjiro","player",Vector3.new(0,4,15))
    local start=a.root.Position
    combat:dodge(a,Vector3.xAxis)
    assert((a.root.Position-start).Magnitude<0.01,"dodge teleported")
    assert(a.motion and a.root:FindFirstChild("DashVelocity"),"dash constraint missing")
    assert(a.energy==82 and a.model:GetAttribute("Pose")=="dash_right")
    combat:stopMotion(a)
    assert(not a.root:FindFirstChild("DashVelocity") and not a.root:FindFirstChild("DashAttachment"))
    combat:remove(a)
end)

check("Editor-format clips load, target real rig parts and sample their authored poses",function()
    local Motion=require(game:GetService("StarterPlayer").StarterPlayerScripts.Client.Motion)
    local model=Rig.create(World.Actors,Vector3.new(0,40,0),Content.characters.tanjiro)
    local sequences=0
    for _,item in ipairs(game:GetService("ReplicatedStorage").Animations:GetDescendants()) do
        if item:IsA("KeyframeSequence") then
            sequences+=1
            for _,pose in ipairs(item:GetDescendants()) do
                if pose:IsA("Pose") then assert(model:FindFirstChild(pose.Name),item.Name.." poses missing part "..pose.Name) end
            end
        end
    end
    model:Destroy()
    assert(sequences>=2,"KeyframeSequences were not built into ReplicatedStorage.Animations")
    local clip=assert(Motion.clip("base/idle_sheathed"),"idle clip missing")
    assert(clip.entry.loop and math.abs(clip.length-2.4)<1e-4 and not clip.parts.HumanoidRootPart,"clip metadata or weight-0 structure")
    local function angle(a,b) return math.acos(math.clamp((a.LookVector:Dot(b.LookVector)+a.UpVector:Dot(b.UpVector))/2,-1,1)) end
    local start=Motion.sample(clip,0,{})
    assert(angle(start.UpperTorso,CFrame.Angles(math.rad(-3),math.rad(5),0))<1e-3,"t=0 waist differs from authored pose")
    assert(math.abs(start.LowerTorso.Position.Y+0.03)<1e-4,"root offset lost")
    local peak=Motion.sample(clip,1.2,{})
    assert(angle(peak.UpperTorso,CFrame.Angles(math.rad(-4.5),math.rad(5),0))<1e-3,"t=1.2 waist differs")
    local mid=Motion.sample(clip,0.6,{}).UpperTorso
    assert(angle(mid,start.UpperTorso)>1e-4 and angle(mid,peak.UpperTorso)>1e-4,"no interpolation between keyframes")
    assert(Motion.clip("base/does_not_exist")==nil,"missing clips must fall back to procedural poses")
end)

check("animator per-frame cost stays small for a crowded scene",function()
    local Animator=require(game:GetService("StarterPlayer").StarterPlayerScripts.Client.Animator)
    local models,states={},{}
    for i=1,12 do
        local model=Rig.create(World.Actors,Vector3.new(i*6,40,0),Content.characters.tanjiro)
        if i%3==0 then model:SetAttribute("Pose","dash_left");model:SetAttribute("PoseStart",workspace:GetServerTimeNow());model:SetAttribute("PoseDuration",60) end
        table.insert(models,model);states[model]=assert(Animator.track(model),"rig not tracked")
    end
    local frames,started=60,os.clock()
    for f=1,frames do
        for _,model in ipairs(models) do Animator.step(model,states[model],workspace:GetServerTimeNow(),1/60) end
    end
    local perFrame=(os.clock()-started)/frames*1000
    print(string.format("ANIMATOR_BENCH %.3f ms per frame for 12 rigs (%.3f ms per rig)",perFrame,perFrame/12))
    for _,model in ipairs(models) do model:Destroy() end
    assert(perFrame<4,"animator too expensive: "..perFrame.." ms per frame")
end)

check("every nichirin sword sheathes inside its saya and uses its sourced fittings",function()
    local function inside(point,saya)
        for i=1,3 do
            local body=saya["SayaBody"..i];local p=body.CFrame:PointToObjectSpace(point)
            if math.abs(p.X)<=body.Size.X/2+0.01 and math.abs(p.Y)<=body.Size.Y/2+0.01 and math.abs(p.Z)<=body.Size.Z/2+0.01 then return true end
        end
        return false
    end
    for _,c in pairs(Content.characters) do
        if c.weapon=="katana" or c.weapon=="needle" or c.weapon=="serpent" then
            local model=Rig.create(World.Actors,Vector3.new(0,40,0),c)
            Rig.draw(model,false)
            assert(model.LowerTorso.SwordHip.Enabled and not model.RightHand.SwordHand.Enabled,c.id.." sheathed joints")
            local katana,saya=model.Katana,model.Saya
            for _,name in ipairs({"Blade","Blade2","Blade3","Hamon1","Hamon2","Hamon3"}) do
                assert(inside(katana[name].Position,saya),c.id.." "..name.." outside saya")
            end
            local tip=katana.Kissaki
            assert(inside(tip.CFrame*Vector3.new(0,0,-tip.Size.Z/2+0.02),saya),c.id.." tip pierces saya")
            assert(not inside(katana.Tsuka.Position,saya) and not inside(katana.Kashira.Position,saya),c.id.." hilt swallowed")
            Rig.draw(model,true)
            assert(model.RightHand.SwordHand.Enabled and not model.LowerTorso.SwordHip.Enabled,c.id.." drawn joints")
            model:Destroy()
        end
    end
    local function build(id) return Rig.create(World.Actors,Vector3.new(0,40,0),Content.characters[id]) end
    local tanjiro,giyu,rengoku,kanao=build("tanjiro"),build("giyu"),build("rengoku"),build("kanao")
    assert(tanjiro.Katana.Blade.Color.R<0.2 and tanjiro.Katana:FindFirstChild("TsubaPoints"),"Tanjiro black blade/wheel tsuba")
    local plates=0;for _,item in ipairs(giyu.Katana:GetChildren()) do if item.Name=="Tsuba" then plates+=1 end end
    assert(plates==3 and giyu.Katana.Blade.Color.B>giyu.Katana.Blade.Color.R,"Giyu blue blade/hex tsuba")
    assert(rengoku.Katana:FindFirstChild("TsubaFlame") and kanao.Katana:FindFirstChild("TsubaPetal"),"flame/flower tsuba")
    for _,m in ipairs({tanjiro,giyu,rengoku,kanao}) do m:Destroy() end
end)

check("draw, noto, fast sheathe, cancel and iai follow clip timing on the server",function()
    local a=actor("tanjiro","player",Vector3.new(0,4,15))
    local model=a.model
    local function inHand() return model.RightHand.SwordHand.Enabled and not model.LowerTorso.SwordHip.Enabled end
    local function ready() a.busyUntil=0;a.stunUntil=0 end
    local noto=AnimationIndex["base/sheathe_noto"]
    -- Out of combat: the full noto. Busy only through the chiburi; the joint moves at Release.
    local ok,duration=combat:weapon(a,false)
    assert(ok and model:GetAttribute("Pose")=="sheathe_noto" and math.abs(duration-noto.length)<1e-4,"noto not chosen out of combat")
    assert(math.abs(a.busyUntil-workspace:GetServerTimeNow()-noto.markers.Seat)<0.05 and model:GetAttribute("WeaponState")=="sheathing")
    task.wait(noto.markers.Release-0.15)
    assert(inHand(),"sword left the hand before Release")
    task.wait(noto.length-noto.markers.Release+0.3)
    assert(not inHand() and model:GetAttribute("SwordInHand")==false and model:GetAttribute("WeaponState")=="sheathed","noto did not seat the sword")
    -- Draw: the hand takes the sword when the clip ends.
    ready();ok,duration=combat:weapon(a,true)
    assert(ok and model:GetAttribute("Pose")=="draw" and not inHand(),"draw swapped early")
    task.wait(duration+0.15)
    assert(inHand() and model:GetAttribute("WeaponState")=="drawn","draw did not grip")
    -- In combat: the fast sheathe.
    ready();a.lastCombat=workspace:GetServerTimeNow()
    ok=combat:weapon(a,false)
    assert(ok and model:GetAttribute("Pose")=="sheathe_fast","fast sheathe not chosen in combat")
    task.wait(AnimationIndex["base/sheathe_fast"].length+0.15)
    assert(not inHand(),"fast sheathe did not seat")
    -- Drawing again during a noto cancels its Release.
    ready();combat:weapon(a,true);task.wait(0.6);ready();a.lastCombat=0
    assert(combat:weapon(a,false) and model:GetAttribute("Pose")=="sheathe_noto")
    task.wait(noto.markers.Seat+0.05)
    assert(combat:weapon(a,true),"draw could not cancel the noto after the chiburi")
    task.wait(noto.markers.Release+0.2)
    assert(inHand() and model:GetAttribute("WeaponDrawn"),"cancelled noto still sheathed the sword")
    -- A sheathed attack draws with the iai clip, then casts with its windup replicated for time-warp.
    ready();a.lastCombat=workspace:GetServerTimeNow();combat:weapon(a,false);task.wait(0.5);ready()
    a.energy=100;a.cooldowns={}
    assert(combat:cast(a,Content.moves.water_1,Vector3.xAxis) and model:GetAttribute("Pose")=="draw_iai","sheathed attack did not iai-draw")
    task.wait(AnimationIndex["base/draw_iai"].length+0.1)
    assert(model:GetAttribute("Pose")=="slash" and model:GetAttribute("PoseWindup")==Content.moves.water_1.windup and model:GetAttribute("PoseVariant")==nil,"chained cast pose")
    combat:remove(a)
end)

check("auto-sheathe, story weapon locks, combo variants and hit reactions",function()
    local a=actor("tanjiro","player",Vector3.new(0,4,15))
    local b=actor("tanjiro","enemy",Vector3.new(0,4,19))
    local model=a.model
    assert(model:GetAttribute("WeaponDrawn"),"spawned sheathed")
    a.weaponSince=workspace:GetServerTimeNow()-(Config.AutoSheatheSeconds+1);a.lastCombat=0
    a.storyLocked=true;a.storyCanWeapon=false
    combat:tick(0.03)
    assert(model:GetAttribute("WeaponDrawn"),"auto-sheathe ignored a story weapon lock")
    a.storyLocked=false
    combat:tick(0.03)
    assert(not model:GetAttribute("WeaponDrawn") and model:GetAttribute("Pose")=="sheathe_noto","idle sword did not auto-sheathe")
    Rig.draw(model,true);a.busyUntil=0;a.weaponSince=workspace:GetServerTimeNow()
    for combo=1,3 do
        a.busyUntil=0;a.cooldowns={}
        assert(combat:basic(a,Vector3.new(0,0,1)),"basic "..combo)
        assert(model:GetAttribute("PoseVariant")=="combo_"..combo,"combo variant "..tostring(model:GetAttribute("PoseVariant")))
    end
    -- An idle defender flinches; one mid-attack keeps its attack pose.
    b.busyUntil=0;b.model:SetAttribute("PoseDuration",0)
    combat:damage(a,b,5,"none")
    assert(b.model:GetAttribute("Pose")=="hit_light","idle target did not flinch")
    b.busyUntil=workspace:GetServerTimeNow()+1;b.model:SetAttribute("Pose","slash")
    b.model:SetAttribute("PoseStart",workspace:GetServerTimeNow());b.model:SetAttribute("PoseDuration",1)
    combat:damage(a,b,5,"none")
    assert(b.model:GetAttribute("Pose")=="slash","flinch interrupted an attack pose")
    combat:remove(a);combat:remove(b)
end)

check("sword draw state and story combat restrictions are server controlled",function()
    local a=actor("tanjiro","player",Vector3.new(0,4,15))
    assert(a.model:FindFirstChild("Saya") and a.model.LowerTorso:FindFirstChild("SwordHip") and a.model.RightHand:FindFirstChild("SwordHand"))
    assert(combat:weapon(a,false) and not a.model:GetAttribute("WeaponDrawn"))
    assert(not combat:weapon(a,true),"draw bypassed the chiburi recovery")
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
