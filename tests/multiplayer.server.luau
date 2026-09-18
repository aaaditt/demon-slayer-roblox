-- Module injected into a temporary Studio test; uses the real Game service and real clients.
return function(session)
    local Players=game:GetService("Players")
    local ReplicatedStorage=game:GetService("ReplicatedStorage")
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
    end
    local ok,err=pcall(function()
        waitFor(function()return #Players:GetPlayers()>=2 end,100,"two clients did not join")
        local players=Players:GetPlayers()
        local p1,p2=players[1],players[2]
        waitFor(function()return session.players[p1] and session.players[p2] and session.players[p1].actor and session.players[p2].actor end,20,"player bootstrap failed")
        task.wait(3)
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
        check("sword sheathe and draw replicate to both clients",function()
            client(p1,"action",{name="Weapon",wait=0.55})
            assert(not session.players[p1].actor.model:GetAttribute("WeaponDrawn"))
            client(p2,"weapon",{name=p1.Name,drawn=false})
            client(p1,"action",{name="Weapon",wait=0.55})
            client(p2,"weapon",{name=p1.Name,drawn=true})
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
        check("prologue validates objectives, plays every scene, rewards once and cleans up",function()
            client(p1,"action",{name="Story",payload=1})
            local e=session.players[p1]
            assert(e.mission and e.actor.mode=="Story" and e.actor.characterId=="tanjiro")
            local mission=e.mission
            local story=mission.story
            local before=e.profile.data.xp
            assert(story and not mission.enemy,"prologue spawned a combat enemy")
            client(p1,"story",{scene=true})
            client(p1,"sceneKey")
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
        check("leaving a cutscene restores camera and frees the mission slot",function()
            client(p1,"action",{name="Story",payload=1})
            local e=session.players[p1]
            local slot=e.mission.slot
            client(p1,"story",{scene=true})
            client(p1,"action",{name="Hub"})
            assert(not e.mission and not session.slots[slot])
            client(p1,"story",{scene=false})
        end)
        check("Sagiri exercises validate progress, retry safely and unlock Final Selection",function()
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
        check("leaving active training removes its enemy and restores normal controls",function()
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
