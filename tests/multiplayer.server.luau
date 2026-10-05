-- Module injected into a temporary Studio test; uses the real Game service and real clients.
return function(session)
    local Players=game:GetService("Players")
    local ReplicatedStorage=game:GetService("ReplicatedStorage")
    local Config=require(ReplicatedStorage.Shared.Config)
    local StudioTestService=game:GetService("StudioTestService")
    local bridge=ReplicatedStorage.RuntimeTestBridge
    local answers={}
    local serial=0
    bridge.OnServerEvent:Connect(function(player,token,ok,result) answers[token]={player=player,ok=ok,result=result} end)
    local function waitFor(predicate,timeout,message)
        local deadline=os.clock()+(timeout or 15)
        repeat if predicate() then return end;task.wait(0.1) until os.clock()>deadline
        error(message or "timed out")
    end
    local function client(player,command,args)
        serial+=1;local token=serial
        bridge:FireClient(player,token,command,args)
        waitFor(function()return answers[token]end,35,"client response timeout: "..command)
        local a=answers[token];answers[token]=nil
        assert(a.player==player and a.ok,tostring(a.result))
        return a.result
    end
    local results={}
    local function check(name,run)
        local ok,err=pcall(run)
        table.insert(results,{name=name,ok=ok,error=not ok and tostring(err) or nil})
        print((ok and "PASS " or "FAIL ")..name..(not ok and (": "..tostring(err)) or ""))
        return ok
    end
    local ok,err=pcall(function()
        waitFor(function()return #Players:GetPlayers()>=2 end,100,"two clients did not join")
        local players=Players:GetPlayers()
        local p1,p2=players[1],players[2]
        waitFor(function()return session.players[p1] and session.players[p2] and session.players[p1].actor and session.players[p2].actor end,20,"player bootstrap failed")
        task.wait(3)
        local suiteArgs=StudioTestService:GetTestArgs()
        local selectionOnly=type(suiteArgs)=="table" and suiteArgs.selectionOnly
        local swampOnly=type(suiteArgs)=="table" and suiteArgs.swampOnly
        local asakusaOnly=type(suiteArgs)=="table" and suiteArgs.asakusaOnly
        local seededChapters,completedRoutes={},{}
        local function storyCheck(chapter,route,name,run)
            local e=session.players[p1]
            local savedLoadout=table.clone(e.profile.data.loadouts.tanjiro)
            local passed=check(name,function()
                -- A failed route must not leave the next check in an unfinished or locked mission.
                -- Record every fallback seed so the separate sequential-unlock check cannot pass on it.
                if e.mission then session:clearMission(e);session:spawn(p1,"Hub") end
                if e.profile.data.chapter<chapter then
                    table.insert(seededChapters,chapter)
                    print("STORY_ISOLATION_SEED chapter="..chapter)
                    e.profile.data.chapter=chapter
                end
                run()
            end)
            e.profile.data.loadouts.tanjiro=savedLoadout
            if route then completedRoutes[chapter]=passed end
        end
        if selectionOnly or swampOnly or asakusaOnly then
            session.players[p1].profile.data.chapter=asakusaOnly and 5 or swampOnly and 4 or 3;session.players[p1].profile.data.selected="giyu";session:spawn(p1,"Hub")
        else
        check("two real clients load GUI, attach cameras, and stand on the ground",function()
            for _,p in ipairs({p1,p2}) do
                local result=client(p,"ready")
                assert(result.position.Y>1 and result.position.Y<8,"invalid spawn height "..result.position.Y)
            end
        end)
        check("custom player rig supports client movement",function()
            assert(client(p1,"move")>5,"rig failed to walk")
        end)
        check("locomotion animates joints through walking, jumping and landing",function() client(p1,"animation") end)
        check("both clients observe Tanjiro's stance, combo and guard with shared fallback for Giyu",function()
            local Rig=require(game.ServerScriptService.Server.Rig)
            local Content=require(ReplicatedStorage.Shared.Content)
            local models={}
            local ok,err=pcall(function()
                for _,id in ipairs({"tanjiro","giyu"}) do
                    local model=Rig.create(workspace.Actors,Vector3.new(id=="tanjiro" and -8 or 8,4,25),Content.characters[id])
                    table.insert(models,model);model.HumanoidRootPart.Anchored=true
                    model.Humanoid:ChangeState(Enum.HumanoidStateType.Physics);Rig.draw(model,true)
                    local profile=id=="tanjiro" and "tanjiro" or "base"
                    local function observe(action)
                        for _,p in ipairs({p1,p2}) do client(p,"motionProfile",{model=model,profile=profile,base=profile.."/idle_drawn",action=action}) end
                    end
                    task.wait(0.5);observe(nil)
                    for i=1,3 do
                        model:SetAttribute("Pose","slash");model:SetAttribute("PoseVariant","combo_"..i)
                        model:SetAttribute("PoseStart",workspace:GetServerTimeNow());model:SetAttribute("PoseDuration",4);model:SetAttribute("PoseWindup",0.8)
                        observe(profile.."/combo_"..i)
                    end
                    model:SetAttribute("PoseDuration",0);model:SetAttribute("Blocking",true)
                    observe(profile.."/guard_hold")
                end
            end)
            for _,model in ipairs(models) do model:Destroy() end
            assert(ok,err)
        end)
        check("W plus Q produces a moving animated dash",function()
            local actor=session.players[p1].actor
            actor.model:PivotTo(CFrame.new(0,4,35));actor.lastPosition=actor.root.Position;actor.motionTime=workspace:GetServerTimeNow()
            task.wait(0.6)
            local ok,result=pcall(function() return client(p1,"dashInput") end)
            local motion=session.players[p1].actor.lastMotion
            print("DASH_DIAGNOSTIC "..game:GetService("HttpService"):JSONEncode(motion or {}))
            assert(ok,result)
            print("DASH_CLIENT "..game:GetService("HttpService"):JSONEncode(result))
            assert(motion and motion.distance>8,"server dash did not travel: "..(motion and motion.reason or "missing motion"))
        end)
        check("A plus Q sidesteps camera-left while facing the camera",function()
            local actor=session.players[p1].actor
            task.wait(Config.DodgeCooldown)
            actor.model:PivotTo(CFrame.new(0,4,35));actor.lastPosition=actor.root.Position;actor.motionTime=workspace:GetServerTimeNow()
            actor.energy=100
            task.wait(0.6)
            local result=client(p1,"sidestepInput")
            local motion=actor.lastMotion
            print("SIDESTEP_CLIENT "..game:GetService("HttpService"):JSONEncode(result))
            -- Stop-time distance overshoots slightly (front dashes measure ~16.5 of 16), so allow +1.
            assert(motion and motion.distance>8 and motion.distance<=Config.DodgeDistanceSide+1,"server sidestep reach "..(motion and motion.distance or -1))
        end)
        check("sword sheathe and draw replicate to both clients",function()
            -- The sword may already have auto-sheathed; toggle from whatever state it is in, and wait for the
            -- clip-timed joint swap (noto Release is later than the draw).
            local model=session.players[p1].actor.model
            local function toggle()
                local target=not model:GetAttribute("WeaponDrawn")
                client(p1,"action",{name="Weapon",wait=target and 0.7 or 1.7})
                assert(model:GetAttribute("WeaponDrawn")==target,"server weapon state")
                client(p2,"weapon",{name=p1.Name,drawn=target})
            end
            toggle();toggle()
        end)
        check("a draw seen by another client slides the blade out and carries it to the hand",function()
            local model=session.players[p1].actor.model
            if model:GetAttribute("WeaponDrawn") then client(p1,"action",{name="Weapon",wait=1.7}) end
            local result
            task.spawn(function() result={pcall(client,p2,"swordPath",{name=p1.Name})} end)
            task.wait(0.4)
            client(p1,"action",{name="Weapon",wait=0.8})
            waitFor(function() return result~=nil end,6,"sword path observer did not answer")
            assert(result[1],result[2])
            print("SWORD_PATH "..tostring(result[2]))
        end)
        -- VirtualInput delivers InputBegan without activating buttons in this Studio environment.
        -- Keep this diagnostic opt-in; desktop mouse navigation is checked separately (docs/QA.md).
        local testArgs=StudioTestService:GetTestArgs()
        if type(testArgs)=="table" and testArgs.virtualInput then
            check("virtual mouse clicks open all five menu tabs without client errors",function() client(p1,"tabs") end)
        end
        check("character selection and loadout changes travel over real remotes",function()
            client(p1,"action",{name="Select",payload="giyu"})
            assert(session.players[p1].actor.characterId=="giyu")
            client(p1,"action",{name="Equip",payload={slot=1,move="water_11"}})
            assert(session.players[p1].profile.data.loadouts.giyu[1]=="water_11")
            client(p1,"action",{name="Equip",payload={slot=1,move="muzan_brambles"}})
            assert(session.players[p1].profile.data.loadouts.giyu[1]=="water_11","foreign move admitted")
            client(p1,"ui")
        end)
        storyCheck(1,true,"prologue validates objectives, plays every scene, rewards once and cleans up",function()
            client(p1,"action",{name="Story",payload=1})
            local e=session.players[p1]
            assert(e.mission and e.actor.mode=="Story" and e.actor.characterId=="tanjiro")
            local mission=e.mission
            local story=mission.story
            local before=e.profile.data.xp
            assert(story and not mission.enemy,"prologue spawned a combat enemy")
            local continue=story.continue
            local receipt
            story.continue=function(self,skip)
                local age=workspace:GetServerTimeNow()-self.changedAt
                local line=self.line
                local accepted=continue(self,skip)
                receipt={age=age,line=line,accepted=accepted}
                print(string.format("STORY_INPUT_RECEIPT age=%.3f line=%d skip=%s accepted=%s",age,line,tostring(skip),tostring(accepted)))
                return accepted
            end
            client(p1,"story",{scene=true})
            print(string.format("STORY_INPUT_READY age=%.3f",workspace:GetServerTimeNow()-story.changedAt))
            client(p1,"sceneKey",{readyAt=story.changedAt+0.65})
            story.continue=continue
            assert(receipt and receipt.age>=0.6 and receipt.accepted,"eligible E did not reach and pass the server gate")
            assert(story.line==2,"E did not advance cinematic dialogue")
            assert(not story:interact(p2,"mother"),"another player advanced the story")
            client(p1,"action",{name="Skill",payload={slot=1,direction=Vector3.xAxis}})
            assert(not e.actor.cooldowns.water_1,"pre-training technique admitted")
            for stage=1,#story.data.steps do
                assert(story.stepIndex==stage,"unexpected story order")
                if story.phase=="objective" then
                    assert(not story:interact(p1,"invalid"),"unknown target admitted")
                    local anchor=mission.room.anchors[story.step.target]
                    e.actor.model:PivotTo(CFrame.new(mission.room.center+Vector3.new(0,3,0)))
                    e.actor.lastPosition=e.actor.root.Position;e.actor.motionTime=workspace:GetServerTimeNow()
                    assert(not story:interact(p1,story.step.target),"distant interaction admitted")
                    e.actor.model:PivotTo(CFrame.new(anchor.Position+Vector3.new(0,0,4)))
                    e.actor.lastPosition=e.actor.root.Position;e.actor.motionTime=workspace:GetServerTimeNow()
                    assert(story:interact(p1,story.step.target),"nearby interaction rejected")
                end
                local lines=#story.step.scene
                for line=story.line,lines do
                    assert(story.line==line)
                    task.wait(0.65)
                    client(p1,"action",{name="StoryContinue",wait=0.15})
                end
            end
            assert(e.mission==nil and e.profile.data.chapter==2 and e.profile.data.xp==before+110)
            assert(e.actor.mode=="Hub" and e.actor.characterId=="giyu","hub selection was not restored")
            for _,model in pairs(story.npcs) do assert(model.Parent==nil,"story actor leaked") end
            assert(mission.room.folder.Parent==nil,"story room leaked")
            client(p1,"action",{name="StorySkip"})
            assert(e.profile.data.xp==before+110,"duplicate completion reward")
            client(p1,"story",{scene=false})
        end)
        storyCheck(1,false,"leaving a cutscene restores camera and frees the mission slot",function()
            client(p1,"action",{name="Story",payload=1})
            local e=session.players[p1]
            local slot=e.mission.slot
            client(p1,"story",{scene=true})
            client(p1,"action",{name="Hub"})
            assert(not e.mission and not session.slots[slot])
            client(p1,"story",{scene=false})
        end)
        storyCheck(2,true,"Sagiri exercises validate progress, retry safely and unlock Final Selection",function()
            client(p1,"action",{name="Story",payload=2})
            local e=session.players[p1]
            local mission=e.mission;local story=mission and mission.story
            assert(story and story.data.id=="sagiri_training","training chapter did not start")
            local before=e.profile.data.xp
            local function place(a,position)
                session.combat:stopMotion(a);a.root.Anchored=true
                a.model:PivotTo(CFrame.new(position));a.root.AssemblyLinearVelocity=Vector3.zero
                a.lastPosition=a.root.Position;a.motionTime=workspace:GetServerTimeNow()
            end
            local function skip()
                story.changedAt=workspace:GetServerTimeNow()-1
                assert(story:continue(true),"scene skip failed")
            end
            for stage=1,#story.data.steps do
                assert(story.stepIndex==stage,"training order changed at "..stage)
                if story.phase=="objective" then
                    assert(not story:interact(p2,story.step.target),"other player advanced training")
                    place(e.actor,mission.room.anchors[story.step.target].Position)
                    assert(story:interact(p1,story.step.target))
                end
                skip()
                local exercise=story.challenge
                if exercise then
                    print("TRAINING_STAGE "..stage.." "..exercise.data.kind)
                    local d=exercise.data
                    assert(not story:continue(true),"scene skip bypassed exercise")
                    assert(not session.combat:cast(e.actor,require(ReplicatedStorage.Shared.Content).moves.water_1,-Vector3.zAxis),"training form admitted")
                    if d.kind=="route" then
                        -- Wrong-order markers cannot advance. Trap contact is tested with a controlled clock.
                        place(e.actor,mission.room.anchors.hut.Position);exercise:tick(workspace:GetServerTimeNow())
                        assert(exercise.routeIndex==1)
                        local h=mission.room.hazards[1].definition
                        local now=workspace:GetServerTimeNow()
                        exercise.started=now-h.windup-0.1-h.offset;e.actor.invulnerableUntil=0
                        place(e.actor,mission.room.center+Vector3.new(table.unpack(h.position)))
                        local hp=e.actor.humanoid.Health;exercise:hazards(now,e.actor)
                        assert(e.actor.humanoid.Health==hp-h.damage,"active trap did not damage")
                        exercise:hazards(now+0.1,e.actor);assert(e.actor.humanoid.Health==hp-h.damage,"trap tick bypassed immunity")
                        e.actor.humanoid.Health=1;exercise:tick(now)
                        assert(exercise.attempt==2 and e.actor.humanoid.Health==e.actor.humanoid.MaxHealth,"training retry failed")
                        for _,id in ipairs(d.checkpoints) do
                            place(e.actor,mission.room.anchors[id].Position)
                            exercise.lastCheckpoint=workspace:GetServerTimeNow()-1
                            exercise:tick(workspace:GetServerTimeNow())
                        end
                    else
                        place(e.actor,mission.room.center+Vector3.new(table.unpack(d.start)))
                        if exercise.enemy then
                            exercise.enemy.target=nil;exercise.enemy.root.Anchored=true;exercise.enemy.invulnerableUntil=0
                            local c=exercise.count
                            session.combat:damage(session.players[p2].actor,exercise.enemy,10,"none")
                            assert(exercise.count==c,"other player's damage advanced training")
                            if d.kind=="survive" then
                                client(p1,"training",{weapon="AxeHead"})
                                place(e.actor,exercise.enemy.root.Position+Vector3.new(0,0,6))
                                e.actor.busyUntil=0;e.actor.stunUntil=0;e.actor.cooldowns.basic=0
                                client(p1,"action",{name="Basic",payload=-Vector3.zAxis,wait=0.5})
                                assert(exercise.count==1,"remote axe strike did not count")
                                for _=2,d.hits do session.combat:damage(e.actor,exercise.enemy,10,"none") end
                                exercise:tick(workspace:GetServerTimeNow())
                                assert(story.challenge==exercise,"survival requirement bypassed")
                                exercise.started=workspace:GetServerTimeNow()-d.duration
                            elseif d.kind=="cut" then
                                session.combat:damage(e.actor,exercise.enemy,10,"none")
                                assert(exercise.count==0,"unfocused boulder hit counted")
                            else
                                client(p1,"training",{weapon="PracticeBlade"})
                                for _=1,d.hits do session.combat:damage(e.actor,exercise.enemy,10,"none") end
                            end
                        end
                        if d.kind=="breath" or d.kind=="cut" then
                            place(e.actor,mission.room.center+Vector3.new(table.unpack(d.start)))
                            assert(not exercise:focus(p2),"other player's focus admitted")
                            exercise.started=workspace:GetServerTimeNow();exercise.nextFocus=0
                            assert(not exercise:focus(p1),"early breath admitted")
                            for cycle=0,(d.cycles or 1)-1 do
                                exercise.started=workspace:GetServerTimeNow()-(cycle*d.period+1.85);exercise.nextFocus=0
                                if cycle==0 and d.kind=="breath" then
                                    client(p1,"sceneKey")
                                    assert(exercise.count==1,"E did not activate the breathing input")
                                else assert(exercise:focus(p1),"valid breath rejected") end
                                exercise.nextFocus=0;assert(not exercise:focus(p1),"duplicate breath admitted")
                            end
                            if d.kind=="cut" then session.combat:damage(e.actor,exercise.enemy,10,"none") end
                        end
                        exercise:tick(workspace:GetServerTimeNow())
                    end
                    assert(story.phase=="scene" and story.resultScene and not story.challenge,"exercise did not enter result scene")
                    assert(not e.actor.storyCanBasic and not e.actor.healthFloor and not mission.enemy,"exercise state leaked")
                    if story.step.splitBoulder then
                        story:tick(workspace:GetServerTimeNow()+1)
                        assert((mission.room.boulder[1].part.Position-mission.room.boulder[1].closed.Position).Magnitude>3,"boulder did not open")
                    end
                    skip()
                end
            end
            assert(not e.mission and e.profile.data.chapter==3 and e.profile.data.xp==before+130,"training progression/reward failed")
            assert(e.actor.characterId=="giyu" and not e.actor.storyCanBasic and not e.actor.healthFloor)
            for _,model in pairs(story.npcs) do assert(not model.Parent,"training NPC leaked") end
            assert(not mission.room.folder.Parent)
            client(p1,"action",{name="StorySkip"});assert(e.profile.data.xp==before+130)
            client(p1,"story",{scene=false})
        end)
        storyCheck(2,false,"leaving active training removes its enemy and restores normal controls",function()
            local e=session.players[p1]
            if e.mission then session:clearMission(e);session:spawn(p1,"Hub") end
            session:startMission(p1,2)
            local story=e.mission.story
            story.changedAt=workspace:GetServerTimeNow()-1;story:continue(true)
            e.actor.model:PivotTo(CFrame.new(e.mission.room.anchors.temple.Position))
            assert(story:interact(p1,"temple"))
            story.changedAt=workspace:GetServerTimeNow()-1;story:continue(true)
            local enemy=story.challenge.enemy;local slot=e.mission.slot
            client(p1,"action",{name="Hub"})
            assert(not e.mission and not session.slots[slot] and not enemy.model.Parent and not session.combat.actors[enemy.model])
            assert(not e.actor.storyCanBasic and not e.actor.healthFloor and not e.actor.root.Anchored)
            client(p1,"story",{scene=false})
        end)
        end
        if not swampOnly and not asakusaOnly then
        storyCheck(3,true,"Final Selection fights, patrol, induction and return award once and preserve the saved kit",function()
            local Content=require(ReplicatedStorage.Shared.Content)
            local e=session.players[p1]
            local original=table.clone(e.profile.data.loadouts.tanjiro)
            local alternate
            for _,id in ipairs(Content.characters.tanjiro.moves) do if Content.moves[id].style~="water" then alternate=id;break end end
            assert(alternate);e.profile.data.loadouts.tanjiro[1]=alternate
            client(p1,"action",{name="Story",payload=3})
            local mission=e.mission;local story=mission and mission.story
            assert(story and story.data.id=="fujikasane_selection")
            local firstRoom=mission.room;local before=e.profile.data.xp
            local function place(a,position)
                session.combat:stopMotion(a);a.root.Anchored=true;a.model:PivotTo(CFrame.new(position))
                a.root.AssemblyLinearVelocity=Vector3.zero;a.lastPosition=a.root.Position;a.motionTime=workspace:GetServerTimeNow()
            end
            local function skip() story.changedAt=workspace:GetServerTimeNow()-1;assert(story:continue(true)) end
            for stage=1,#story.data.steps do
                assert(story.stepIndex==stage,"selection stage order changed")
                if story.phase=="objective" then
                    assert(not story:interact(p2,story.step.target))
                    place(e.actor,mission.room.anchors[story.step.target].Position)
                    assert(story:interact(p1,story.step.target))
                end
                if story.step.id=="home" then
                    assert(story.map=="sagiri" and not firstRoom.folder.Parent and e.actor.room==mission.room,"map transition leaked old room")
                    assert(mission.room.folder:FindFirstChild("UrokodakiHouse"))
                    assert(story.npcs.kiriya.Head.Transparency==1 and story.npcs.nezuko.Head.Transparency==0)
                elseif story.step.id=="steel" then client(p1,"selection",{gear="black"})
                elseif story.step.id=="box" then
                    client(p1,"selection",{gear="box"})
                    assert(story.npcs.nezuko.Head.Transparency==1,"boxed Nezuko duplicated outside")
                end
                skip()
                local encounter=story.challenge
                if encounter then
                    print("SELECTION_STAGE "..stage.." "..encounter.data.kind)
                    assert(e.actor.storyLoadout[1]=="water_1" and not session.combat:cast(e.actor,Content.moves[alternate],-Vector3.zAxis),"foreign story form admitted")
                    assert(not story:continue(true),"skip bypassed selection encounter")
                    assert(not encounter:focus(p1),"training Focus admitted in selection")
                    if encounter.data.kind=="battle" then
                        for _,enemy in ipairs(encounter.enemies) do enemy.target=nil;enemy.root.Anchored=true;enemy.invulnerableUntil=0 end
                        local enemy=encounter.enemies[1]
                        place(e.actor,enemy.root.Position+Vector3.zAxis*7)
                        client(p1,"selection",{})
                        client(p1,"action",{name="Skill",payload={slot=1,direction=-Vector3.zAxis},wait=1.2})
                        assert(e.actor.cooldowns.water_1 and enemy.humanoid.Health<enemy.humanoid.MaxHealth,"Water skill remote used wrong kit")
                        for _,target in ipairs(encounter.enemies) do session.combat:damage(e.actor,target,1000,"none") end
                        encounter:tick(workspace:GetServerTimeNow())
                        waitFor(function() return story.phase=="scene" end,5,"battle deaths did not resolve")
                    elseif encounter.data.kind=="hand_boss" then
                        local boss=encounter.enemy;boss.invulnerableUntil=0
                        local hp=boss.humanoid.Health
                        session.combat:damage(e.actor,boss,1000,"none");assert(boss.humanoid.Health==hp,"guarding bypassed")
                        session.combat:damage(session.players[p2].actor,boss,1000,"none");assert(boss.humanoid.Health==hp,"other player hit private boss")
                        place(e.actor,boss.root.Position+Vector3.new(20,0,20))
                        encounter:beginAttack(workspace:GetServerTimeNow())
                        client(p1,"bossAnimation")
                        for _,npc in pairs(story.npcs) do
                            for _,part in ipairs(npc:GetDescendants()) do if part:IsA("BasePart") then assert(not part.CanCollide,"cinematic collision returned: "..npc.Name.."."..part.Name) end end
                        end
                        -- Resolve the telegraph on the server, then test a real client strike in recovery.
                        encounter.strikeAt=workspace:GetServerTimeNow()-0.1;encounter:resolveAttack(workspace:GetServerTimeNow())
                        assert(encounter.phase=="exposed")
                        assert(boss.root.Anchored,"boss recovery is not planted")
                        place(e.actor,boss.root.Position+Vector3.zAxis*7)
                        e.actor.busyUntil=0;e.actor.stunUntil=0
                        assert(session.combat:lineOfSight(e.actor,boss,e.actor.root.Position),"boss strike obstructed before attack")
                        client(p1,"action",{name="Basic",payload=-Vector3.zAxis,wait=0.6})
                        print("BOSS_STRIKE_DIAGNOSTIC "..game:GetService("HttpService"):JSONEncode({phase=encounter.phase,multiplier=boss.damageMultiplier,
                            health=boss.humanoid.Health,distance=(e.actor.root.Position-boss.root.Position).Magnitude,player=tostring(e.actor.root.Position),boss=tostring(boss.root.Position),
                            sight=session.combat:lineOfSight(e.actor,boss,e.actor.root.Position),drawn=e.actor.model:GetAttribute("WeaponDrawn"),cooldown=e.actor.cooldowns.basic,
                            recovery=encounter.exposedUntil-workspace:GetServerTimeNow(),busy=e.actor.busyUntil-workspace:GetServerTimeNow()}))
                        assert(boss.humanoid.Health<hp,"exposed boss rejected client strike")
                        session.combat:damage(e.actor,boss,1000,"none");encounter:tick(workspace:GetServerTimeNow())
                        waitFor(function() return story.phase=="scene" end,5,"boss death did not resolve")
                    else
                        place(e.actor,mission.room.anchors.watch_three.Position);encounter:tick(workspace:GetServerTimeNow())
                        assert(encounter.watchIndex==1 and not encounter.waveActive,"out-of-order patrol admitted")
                        for _,id in ipairs(encounter.data.checkpoints) do
                            place(e.actor,mission.room.anchors[id].Position);encounter:tick(workspace:GetServerTimeNow())
                            assert(encounter.waveActive,"patrol demon did not spawn")
                            local enemy=encounter.enemies[#encounter.enemies];enemy.invulnerableUntil=0
                            local watch=encounter.watchIndex
                            session.combat:damage(e.actor,enemy,1000,"none");encounter:tick(workspace:GetServerTimeNow())
                            waitFor(function() return encounter.watchIndex>watch end,5,"patrol death did not resolve")
                        end
                        assert(story.challenge==encounter,"patrol survival timer bypassed")
                        encounter.started=workspace:GetServerTimeNow()-encounter.data.duration
                        encounter:tick(workspace:GetServerTimeNow())
                    end
                    assert(story.phase=="scene" and story.resultScene and not story.challenge and not e.actor.storyMoves and not e.actor.healthFloor,"encounter did not cleanly finish")
                    skip()
                end
            end
            assert(not e.mission and e.profile.data.chapter==4 and e.profile.data.xp==before+150)
            assert(e.actor.characterId=="giyu" and not e.actor.storyLoadout and not e.actor.storyCanWeapon)
            assert(e.profile.data.loadouts.tanjiro[1]==alternate,"story overwrote saved loadout")
            e.profile.data.loadouts.tanjiro=original
            for _,model in pairs(story.npcs) do assert(not model.Parent,"selection actor leaked") end
            client(p1,"action",{name="StorySkip"});assert(e.profile.data.xp==before+150)
            client(p1,"story",{scene=false})
        end)
        storyCheck(3,false,"leaving a Hand Demon windup cancels the encounter and clears its room",function()
            local e=session.players[p1]
            if e.mission then session:clearMission(e);session:spawn(p1,"Hub") end
            session:startMission(p1,3)
            local mission=e.mission;local story=mission.story
            story.stepIndex=4;story:advance()
            e.actor.model:PivotTo(CFrame.new(mission.room.anchors.clearing.Position))
            assert(story:interact(p1,"clearing"))
            story.changedAt=workspace:GetServerTimeNow()-1;story:continue(true)
            local encounter=story.challenge;local boss=encounter.enemy
            encounter:beginAttack(workspace:GetServerTimeNow())
            client(p1,"action",{name="Hub"})
            assert(encounter.closed and not boss.model.Parent and not mission.room.folder.Parent and not session.slots[mission.slot])
            assert(not e.actor.storyMoves and not e.actor.storyLoadout and not e.actor.healthFloor)
            client(p1,"story",{scene=false})
        end)
        end
        if not selectionOnly and not asakusaOnly then
        storyCheck(4,true,"town investigation, Nezuko rescue, swamp bodies and farewell complete once",function()
            local e=session.players[p1]
            client(p1,"action",{name="Story",payload=4})
            local mission=e.mission;local story=mission and mission.story
            assert(story and story.data.id=="northwest_investigation")
            local before=e.profile.data.xp;local original=table.clone(e.profile.data.loadouts.tanjiro)
            local firstRoom=mission.room
            local function place(position,direction)
                session.combat:stopMotion(e.actor);e.actor.root.Anchored=true
                e.actor.model:PivotTo(CFrame.lookAt(position,position+(direction or -Vector3.zAxis)))
                e.actor.lastPosition=e.actor.root.Position;e.actor.motionTime=workspace:GetServerTimeNow();e.actor.root.AssemblyLinearVelocity=Vector3.zero
            end
            local function skip() story.changedAt=workspace:GetServerTimeNow()-1;assert(story:continue(true)) end
            for stage=1,#story.data.steps do
                assert(story.stepIndex==stage,"town story stage out of order")
                print("SWAMP_STAGE "..stage.." "..story.step.id)
                if story.phase=="objective" then
                    assert(not story:interact(p2,story.step.target) and not story:interact(p1,"forged"))
                    place(mission.room.center+Vector3.new(140,3,140))
                    assert(not story:interact(p1,story.step.target),"distant investigation admitted")
                    place(mission.room.anchors[story.step.target].Position)
                    assert(story:interact(p1,story.step.target))
                end
                if stage==1 then client(p1,"swamp",{gear=true}) end
                if story.step.id=="nezuko" then
                    assert(story.carry=="box_open" and story.npcs.nezuko.Head.Transparency==0)
                    client(p1,"swamp",{model=story.npcs.nezuko,animation=true})
                    story:tick(workspace:GetServerTimeNow()+1)
                    assert((story.npcs.nezuko.PrimaryPart.Position-(mission.room.center+Vector3.new(0,3,-62))).Magnitude<0.1)
                elseif story.step.id=="depths" then
                    assert(story.map=="swamp" and not firstRoom.folder.Parent and e.actor.room==mission.room)
                    assert(story.npcs.nezuko.Head.Transparency==1,"Nezuko followed Tanjiro below")
                    firstRoom=mission.room
                elseif story.step.id=="return" then
                    assert(story.map=="town" and not firstRoom.folder.Parent and story.npcs.nezuko.Head.Transparency==0)
                elseif story.step.id=="keepsake" then assert(not mission.room.folder:FindFirstChild("LostKeepsake"))
                elseif story.step.id=="departure" then
                    assert(story.carry=="box" and story.npcs.nezuko.Head.Transparency==1)
                    client(p1,"swamp",{gear=true})
                end
                skip()
                if story.phase=="challenge" then
                    local c=story.challenge
                    assert(c.data.kind=="swamp" and #c.enemies==c.data.bodyCount)
                    assert(not story:continue(true) and not c:focus(p1),"encounter bypassed")
                    local enemy=c.enemies[1];enemy.invulnerableUntil=0
                    local hp=enemy.humanoid.Health
                    session.combat:damage(e.actor,enemy,50,"none");assert(enemy.humanoid.Health==hp,"submersion bypassed")
                    local now=workspace:GetServerTimeNow();c:beginRise(now-0.7);c:tick(now)
                    c.nextPhase=now-0.01;c:resolveAttack(now)
                    assert(c.phase=="exposed")
                    session.combat:damage(session.players[p2].actor,enemy,50,"none");assert(enemy.humanoid.Health==hp,"other player damaged private body")
                    place(enemy.home+c.direction*7,-c.direction);e.actor.busyUntil=0;e.actor.stunUntil=0
                    client(p1,"swamp",{})
                    client(p1,"action",{name="Skill",payload={slot=1,direction=-c.direction},wait=0.7})
                    assert(enemy.humanoid.Health<hp,"real Water strike missed swamp opening")
                    if c.data.mode=="ambush" then
                        enemy.damageMultiplier=1
                        session.combat:damage(e.actor,enemy,10,"none");session.combat:damage(e.actor,enemy,10,"none")
                        assert(c.hits>=3 and story.challenge==c,"ambush timer bypassed")
                        c.started=workspace:GetServerTimeNow()-c.data.duration;c:tick(workspace:GetServerTimeNow())
                    else
                        for _,body in ipairs(c.enemies) do body.damageMultiplier=1;body.invulnerableUntil=0;session.combat:damage(e.actor,body,1000,"none") end
                        waitFor(function() return story.phase=="scene" end,5,"swamp deaths failed to complete")
                    end
                    assert(story.resultScene and c.closed and not c.pools and not e.actor.healthFloor and not e.actor.storyMoves)
                    for _,body in ipairs(c.enemies) do assert(not body.model.Parent) end
                    skip()
                end
            end
            assert(not e.mission and e.profile.data.chapter==5 and e.profile.data.xp==before+170)
            assert(e.actor.characterId=="giyu" and not e.actor.storyLoadout and not e.actor.root.Anchored)
            for i,id in ipairs(original) do assert(e.profile.data.loadouts.tanjiro[i]==id,"chapter changed saved kit") end
            for _,model in pairs(story.npcs) do assert(not model.Parent,"town actor leaked") end
            client(p1,"action",{name="StorySkip"});assert(e.profile.data.xp==before+170)
            client(p1,"story",{scene=false})
        end)
        storyCheck(4,false,"leaving an active swamp encounter cancels attacks and cleans pools and actors",function()
            local e=session.players[p1]
            if e.mission then session:clearMission(e);session:spawn(p1,"Hub") end
            session:startMission(p1,4)
            local mission=e.mission;local story=mission.story
            story.stepIndex=8;story:advance();story.changedAt=workspace:GetServerTimeNow()-1;story:continue(true)
            local c=story.challenge;local body=c.enemies[1];local pools=c.pools
            local now=workspace:GetServerTimeNow();c:beginRise(now-0.7);c:tick(now)
            client(p1,"action",{name="Hub"})
            assert(c.closed and not pools.Parent and not body.model.Parent and not mission.room.folder.Parent and not session.slots[mission.slot])
            assert(not e.actor.storyMoves and not e.actor.healthFloor and not e.actor.storyLoadout)
            client(p1,"story",{scene=false})
        end)
        end
        if not selectionOnly and not swampOnly then
        storyCheck(5,true,"Asakusa rescue, house reveal, Water encounters and farewell complete once",function()
            local e=session.players[p1]
            if e.mission then session:clearMission(e);session:spawn(p1,"Hub") end
            local selected=e.profile.data.selected
            local saved=game:GetService("HttpService"):JSONEncode(e.profile.data.loadouts)
            local before=e.profile.data.xp
            session:startMission(p1,5)
            local mission=assert(e.mission);local story=assert(mission.story)
            local street=mission.room
            assert(story.data.id=="asakusa_rescue" and e.actor.characterId=="tanjiro")
            local function place(position,direction)
                session.combat:stopMotion(e.actor);e.actor.root.Anchored=true
                e.actor.model:PivotTo(CFrame.lookAt(position,position+(direction or -Vector3.zAxis)))
                e.actor.root.AssemblyLinearVelocity=Vector3.zero;e.actor.lastPosition=position;e.actor.motionTime=workspace:GetServerTimeNow()
            end
            local function skip() story.changedAt=workspace:GetServerTimeNow()-1;assert(story:continue(true)) end
            for stage=1,#story.data.steps do
                assert(story.stepIndex==stage,"Asakusa stage order")
                print("ASAKUSA_STAGE "..stage.." "..story.step.id)
                if stage==1 then client(p1,"story",{scene=true}) end
                if story.phase=="objective" then
                    assert(not story:interact(p2,story.step.target) and not story:interact(p1,"forged"))
                    place(mission.room.center+Vector3.new(140,3,140));assert(not story:interact(p1,story.step.target))
                    place(mission.room.anchors[story.step.target].Position);assert(story:interact(p1,story.step.target))
                end
                if story.step.id=="hidden_house" then
                    assert(story.map=="clinic" and not street.folder.Parent and e.actor.room==mission.room)
                    assert(mission.room.folder:FindFirstChild("TamayoHouse"))
                elseif story.step.id=="leave" then
                    assert(story.carry=="box" and story.npcs.nezuko.Head.Transparency==1)
                end
                skip()
                if story.phase=="challenge" then
                    local c=story.challenge
                    assert(not story:continue(true),"scene skip bypassed challenge")
                    if c.data.kind=="restrain" then
                        assert(not e.actor.storyCanBasic and not e.actor.storyCanWeapon and not e.actor.storyMoves and story.carry=="box")
                        place(mission.room.anchors.civilian.Position)
                        c.started=workspace:GetServerTimeNow()
                        assert(not c:focus(p2))
                        local ok,err=pcall(function() client(p1,"brace",{victim=story.npcs.civilian,started=c.started,period=c.data.period,opens=c.data.window[1]}) end)
                        assert(ok,string.format("%s; count=%d elapsed=%.2f range=%.2f velocity=%.2f",tostring(err),c.count,
                            workspace:GetServerTimeNow()-c.started,(e.actor.root.Position-c:position()).Magnitude,e.actor.root.AssemblyLinearVelocity.Magnitude))
                        assert(c.count==1)
                        local count=c.count
                        client(p1,"action",{name="Skill",payload={slot=1,direction=-Vector3.zAxis},wait=0.1})
                        assert(not e.actor.cooldowns.water_1 and c.count==count,"skill admitted during restraint")
                        for cycle=c.lastCycle+1,c.lastCycle+3 do
                            c.started=workspace:GetServerTimeNow()-(cycle*c.data.period+1.2);c.nextFocus=0
                            assert(c:focus(p1),string.format("restraint beat rejected: cycle=%d last=%d range=%.2f velocity=%.2f",cycle,c.lastCycle,
                                (e.actor.root.Position-c:position()).Magnitude,e.actor.root.AssemblyLinearVelocity.Magnitude))
                            assert(not c:focus(p1),"duplicate restraint beat")
                        end
                        c:tick(workspace:GetServerTimeNow())
                    else
                        local enemy=c.enemies[1];enemy.invulnerableUntil=0
                        assert(not enemy.basicOnly,"Arrow/Temari techniques disabled")
                        -- Test remote hit admission/replication at fixed geometry, without an AI cast racing the input.
                        session.combat:stopMotion(enemy);enemy.root.Anchored=true
                        enemy.root.AssemblyLinearVelocity=Vector3.zero;enemy.castToken+=1
                        enemy.busyUntil=workspace:GetServerTimeNow()+4
                        local hp=enemy.humanoid.Health
                        session.combat:damage(session.players[p2].actor,enemy,30,"none");assert(enemy.humanoid.Health==hp)
                        place(enemy.root.Position+Vector3.zAxis*7)
                        e.actor.busyUntil=0;e.actor.stunUntil=0;e.actor.cooldowns={}
                        client(p1,"action",{name="Skill",payload={slot=1,direction=-Vector3.zAxis},wait=1.1})
                        assert(enemy.humanoid.Health<hp,string.format("real Water strike missed: admitted=%s range=%.2f sight=%s pose=%s",
                            tostring(e.actor.cooldowns.water_1~=nil),(e.actor.root.Position-enemy.root.Position).Magnitude,
                            tostring(session.combat:lineOfSight(e.actor,enemy,e.actor.root.Position)),tostring(e.actor.model:GetAttribute("Pose"))))
                        if c.data.kind=="hold" then
                            for _=1,3 do session.combat:damage(e.actor,enemy,10,"none") end
                            assert(c.hits>=3 and story.challenge==c,"hold timer bypassed")
                            session.combat:damage(e.actor,enemy,1000,"none");assert(enemy.humanoid.Health==1)
                            c.started=workspace:GetServerTimeNow()-c.data.duration;c:tick(workspace:GetServerTimeNow())
                        else
                            session.combat:damage(e.actor,enemy,1000,"none")
                            waitFor(function() return story.phase=="scene" end,5,"Yahaba defeat failed to progress")
                        end
                    end
                    assert(story.resultScene and c.closed and not e.actor.healthFloor and not e.actor.storyMoves)
                    skip()
                end
            end
            assert(not e.mission and e.profile.data.chapter==6 and e.profile.data.xp==before+190)
            assert(e.actor.characterId==selected and not e.actor.root.Anchored and not e.actor.storyLoadout)
            assert(game:GetService("HttpService"):JSONEncode(e.profile.data.loadouts)==saved,"saved kit changed")
            for _,model in pairs(story.npcs) do assert(not model.Parent,"Asakusa actor leaked") end
            client(p1,"action",{name="StorySkip"});assert(e.profile.data.xp==before+190)
            client(p1,"story",{scene=false})
        end)
        storyCheck(5,false,"leaving Asakusa defense cleans the nonlethal demon and story permissions",function()
            local e=session.players[p1]
            if e.mission then session:clearMission(e);session:spawn(p1,"Hub") end
            session:startMission(p1,5)
            local mission=e.mission;local story=mission.story
            story.stepIndex=8;story:advance() -- Enter the clinic through the normal map transition.
            story.changedAt=workspace:GetServerTimeNow()-1;story:continue(true)
            story.stepIndex=12;story:advance()
            e.actor.model:PivotTo(CFrame.new(mission.room.anchors.temari.Position))
            assert(story:interact(p1,"temari"))
            story.changedAt=workspace:GetServerTimeNow()-1;story:continue(true)
            local c=story.challenge;local enemy=c.enemies[1]
            client(p1,"action",{name="Hub"})
            assert(c.closed and not enemy.model.Parent and not mission.room.folder.Parent and not session.slots[mission.slot])
            assert(not e.actor.storyMoves and not e.actor.healthFloor and not e.actor.storyLoadout)
            client(p1,"story",{scene=false})
        end)
        if not asakusaOnly then
        if not selectionOnly and not swampOnly then
        check("all five story routes unlock sequentially without fallback seeds",function()
            assert(#seededChapters==0,"chapter isolation required fallback seeds: "..table.concat(seededChapters,","))
            for chapter=1,5 do assert(completedRoutes[chapter],"chapter route failed: "..chapter) end
            assert(session.players[p1].profile.data.chapter==6,"chapter six was not unlocked")
        end)
        end
        check("locked chapters cannot be started by forged remote requests",function()
            client(p2,"action",{name="Story",payload=20})
            assert(session.players[p2].mission==nil)
        end)
        check("two players enter a live PvP round and damage replicates",function()
            client(p1,"action",{name="Arena"})
            client(p2,"action",{name="Arena"})
            waitFor(function()return session.round.active end,5,"round did not start")
            local a,b=session.players[p1].actor,session.players[p2].actor
            a.model:PivotTo(CFrame.new(550,4,0));b.model:PivotTo(CFrame.new(550,4,-7))
            a.lastPosition=a.root.Position;b.lastPosition=b.root.Position
            a.invulnerableUntil=0;b.invulnerableUntil=0
            task.wait(0.3)
            local before=b.humanoid.Health
            client(p1,"action",{name="Basic",payload=Vector3.new(0,0,-1),wait=0.6})
            assert(b.humanoid.Health<before,"PvP basic hit failed")
            assert(session.round.active and a.arenaActive and b.arenaActive)
        end)
        check("elimination scoring, respawn and five-point round winner",function()
            local e1,e2=session.players[p1],session.players[p2]
            local old=e2.actor
            old.lastAttacker=e1.actor;old.humanoid.Health=0
            waitFor(function()return e2.actor~=old end,6,"arena player did not respawn")
            assert(e1.score==1 and e1.profile.data.kills>=1 and e2.profile.data.deaths>=1)
            e1.score=4
            local wins=e1.profile.data.wins
            e2.actor.lastAttacker=e1.actor;e2.actor.humanoid.Health=0
            task.wait(0.3)
            assert(not session.round.active and e1.profile.data.wins==wins+1)
        end)
        check("client UI survives mission and arena character respawns",function() client(p1,"ui");client(p2,"ui") end)
        end
        end
        local args=StudioTestService:GetTestArgs()
        if type(args)=="table" and args.visual then
            task.wait(3)
            session.players[p1].actor.lastCombat=0
            client(p1,"action",{name="Hub"})
            client(p1,"action",{name="Story",payload=args.visualSagiri and 2 or 1})
            if args.visualSagiri then
                -- Isolated review staging only; production does not expose stage-jump actions.
                local e=session.players[p1];local story=e.mission.story
                story.stepIndex=3;story:advance()
                e.actor.model:PivotTo(CFrame.new(e.mission.room.anchors.hut.Position))
                story:interact(p1,"hut")
                print("VISUAL_SAGIRI_HOUSE_READY");task.wait(45)
                story.stepIndex=6;story:advance()
                e.actor.model:PivotTo(CFrame.new(e.mission.room.anchors.waterfall.Position))
                story:interact(p1,"waterfall")
                story.changedAt=workspace:GetServerTimeNow()-1;story:continue(true)
                client(p1,"visual")
                print("VISUAL_SAGIRI_WATERFALL_READY");task.wait(45)
            else print("VISUAL_REVIEW_READY");task.wait(60) end
        end
    end)
    if not ok then table.insert(results,{name="test harness",ok=false,error=tostring(err)}) end
    local failures=0
    for _,r in ipairs(results) do if not r.ok then failures+=1 end end
    print(string.format("MULTIPLAYER_RESULT %d passed / %d failed",#results-failures,failures))
    StudioTestService:EndTest({results=results,failures=failures})
end
