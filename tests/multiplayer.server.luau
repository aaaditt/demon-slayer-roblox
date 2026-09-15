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
        waitFor(function()return answers[token]end,20,"client response timeout: "..command)
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
        waitFor(function()return #Players:GetPlayers()>=2 end,40,"two clients did not join")
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
        check("character selection and loadout changes travel over real remotes",function()
            client(p1,"action",{name="Select",payload="giyu"})
            assert(session.players[p1].actor.characterId=="giyu")
            client(p1,"action",{name="Equip",payload={slot=1,move="water_11"}})
            assert(session.players[p1].profile.data.loadouts.giyu[1]=="water_11")
            client(p1,"action",{name="Equip",payload={slot=1,move="muzan_brambles"}})
            assert(session.players[p1].profile.data.loadouts.giyu[1]=="water_11","foreign move admitted")
            client(p1,"ui")
        end)
        check("story rewards advance one chapter and mission cleanup removes enemies",function()
            client(p1,"action",{name="Story",payload=1})
            local e=session.players[p1]
            assert(e.mission and e.actor.mode=="Story")
            local before=e.profile.data.xp
            local enemy=e.mission.enemy
            assert(enemy and enemy.target==e.actor)
            enemy.humanoid.Health=0
            waitFor(function()return e.mission==nil end,6,"mission did not finish")
            assert(e.profile.data.chapter==2 and e.profile.data.xp>before)
            assert(e.actor.mode=="Hub" and session.combat.actors[enemy.model]==nil)
            -- These assertions exercise reward plumbing, not player combat difficulty.
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
    end)
    if not ok then table.insert(results,{name="test harness",ok=false,error=tostring(err)}) end
    local failures=0
    for _,r in ipairs(results) do if not r.ok then failures+=1 end end
    print(string.format("MULTIPLAYER_RESULT %d passed / %d failed",#results-failures,failures))
    StudioTestService:EndTest({results=results,failures=failures})
end
