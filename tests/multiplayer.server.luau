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
            client(p1,"action",{name="Story",payload=1})
            print("VISUAL_REVIEW_READY")
            task.wait(60)
        end
    end)
    if not ok then table.insert(results,{name="test harness",ok=false,error=tostring(err)}) end
    local failures=0
    for _,r in ipairs(results) do if not r.ok then failures+=1 end end
    print(string.format("MULTIPLAYER_RESULT %d passed / %d failed",#results-failures,failures))
    StudioTestService:EndTest({results=results,failures=failures})
end
