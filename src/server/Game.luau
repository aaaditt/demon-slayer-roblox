local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Content = require(Shared.Content)
local Config = require(Shared.Config)
local Rules = require(Shared.Rules)
local Rig = require(script.Parent.Rig)
local World = require(script.Parent.World)
local Combat = require(script.Parent.Combat)
local Profiles = require(script.Parent.Profiles)
local Game = {}
Game.__index = Game

local function remote(parent, name)
    local event = Instance.new("RemoteEvent"); event.Name = name; event.Parent = parent
    return event
end

function Game.new()
    local network = Instance.new("Folder"); network.Name = "Network"; network.Parent = ReplicatedStorage
    local self = setmetatable({players = {}, slots = {}, round = {active = false, ends = 0, number = 0}, accumulated = 0, shuttingDown = false}, Game)
    self.action = remote(network, "Action")
    self.state = remote(network, "State")
    self.effects = remote(network, "Effects")
    self.combat = Combat.new(self.effects)
    self.profiles = Profiles.new()
    self.world = World.init()
    return self
end

function Game:toast(player, message)
    if player.Parent == Players then self.state:FireClient(player, {kind = "toast", text = message}) end
end

function Game:push(player)
    local entry = self.players[player]
    if not entry or player.Parent ~= Players then return end
    local a, p = entry.actor, entry.profile.data
    local leaderboard = {}
    for peer, e in pairs(self.players) do
        if e.actor and e.actor.mode == "Arena" then table.insert(leaderboard, {name = peer.DisplayName, score = e.score}) end
    end
    table.sort(leaderboard, function(x,y) return x.score>y.score end)
    self.state:FireClient(player, {
        kind = "state", time = workspace:GetServerTimeNow(), selected = p.selected,
        mode = a and a.mode or "Hub", hp = a and a.humanoid.Health or 0, maxHp = Config.MaxHealth,
        energy = a and a.energy or 0, maxEnergy = Config.MaxEnergy,
        loadout = p.loadouts[p.selected], cooldowns = a and a.cooldowns or {},
        xp = p.xp, rank = Rules.rank(p.xp), chapter = p.chapter, mastery = p.mastery[p.selected],
        kills = p.kills, deaths = p.deaths, wins = p.wins, saveStatus = entry.profile.status,
        mission = entry.mission and {index = entry.mission.chapter.index, wave = entry.mission.wave, total = #entry.mission.chapter.enemies, ends = entry.mission.deadline} or nil,
        round = {active = self.round.active, ends = self.round.ends, number = self.round.number, leaderboard = leaderboard},
    })
end

function Game:spawn(player, mode)
    local entry = self.players[player]
    if not entry or player.Parent ~= Players then return end
    if entry.actor then self.combat:remove(entry.actor) end
    local p = entry.profile.data
    local definition = Content.characters[p.selected]
    local room = mode == "Arena" and World.Arena or mode == "Story" and entry.mission.room or World.Hub
    local position = room.spawn
    if mode == "Arena" then
        local angle = math.random()*math.pi*2
        position = room.center+Vector3.new(math.cos(angle)*60, 4, math.sin(angle)*60)
    end
    local model, humanoid, root = Rig.create(World.Actors, position, definition, player.Name)
    player.Character = model
    local actor = self.combat:register(model, humanoid, root, {
        kind = "player", mode = mode, zone = mode == "Arena" and "arena" or mode == "Story" and "story_" .. player.UserId or "hub",
        characterId = p.selected, player = player, room = room, arenaActive = self.round.active,
        onDeath = function(dead, killer) self:playerDied(player, dead, killer) end,
    })
    entry.actor = actor
    if RunService:IsRunning() then pcall(function() root:SetNetworkOwner(player) end) end
    player:SetAttribute("Mode", mode)
    self:push(player)
    return actor
end

function Game:clearMission(entry)
    local mission = entry.mission
    if not mission then return end
    mission.finished = true
    if mission.enemy then self.combat:remove(mission.enemy) end
    self.slots[mission.slot] = nil
    World.remove(mission.slot)
    entry.mission = nil
end

function Game:playerDied(player, dead, killer)
    local entry = self.players[player]
    if not entry or entry.actor ~= dead then return end
    local mode = dead.mode
    if mode == "Arena" then
        entry.profile.data.deaths += 1
        if self.round.active and killer and killer.player and killer.player ~= player and self.players[killer.player] then
            local winner = self.players[killer.player]
            winner.score += 1; winner.profile.data.kills += 1
            self:toast(killer.player, "Elimination  /  " .. winner.score .. " of " .. Config.ArenaScoreToWin)
            if winner.score >= Config.ArenaScoreToWin then self:finishRound(killer.player) end
        end
    elseif mode == "Story" then
        self:toast(player, "Mission failed. Your chapter remains unlocked.")
        self:clearMission(entry)
    end
    task.delay(2.5, function()
        if self.players[player] == entry and entry.actor == dead then self:spawn(player, mode == "Arena" and "Arena" or "Hub") end
    end)
end

function Game:nextWave(player, mission)
    local entry = self.players[player]
    if not entry or entry.mission ~= mission or mission.finished or not entry.actor.alive then return end
    mission.wave += 1
    if mission.wave > #mission.chapter.enemies then
        local p, chapter = entry.profile.data, mission.chapter
        mission.finished = true
        p.xp += chapter.reward
        p.mastery[p.selected] += 1
        if p.chapter == chapter.index then p.chapter = math.min(#Content.chapters+1, p.chapter+1) end
        self:toast(player, "CHAPTER COMPLETE  +" .. chapter.reward .. " XP")
        self:clearMission(entry)
        self:spawn(player, "Hub")
        task.spawn(function() self.profiles:save(player, false) end)
        return
    end
    local id = mission.chapter.enemies[mission.wave]
    local definition = Content.characters[id]
    local model, humanoid, root = Rig.create(World.Actors, mission.room.bossSpawn, definition)
    local enemy
    enemy = self.combat:register(model, humanoid, root, {
        kind = "npc", mode = "Story", zone = entry.actor.zone, room = mission.room,
        characterId = id, maxHealth = mission.chapter.bossHealth,
        damageScale = math.min(0.92, 0.5+mission.chapter.index*0.018), target = entry.actor,
        onDeath = function()
            task.delay(1, function()
                if enemy then self.combat:remove(enemy) end
                if self.players[player] == entry and entry.mission == mission and not mission.finished then
                    entry.actor.humanoid.Health = math.min(Config.MaxHealth, entry.actor.humanoid.Health+24)
                    entry.actor.energy = math.min(Config.MaxEnergy, entry.actor.energy+30)
                    self:nextWave(player, mission)
                end
            end)
        end,
    })
    mission.enemy = enemy
    if RunService:IsRunning() then pcall(function() root:SetNetworkOwner(nil) end) end
    self:toast(player, definition.name .. "  /  " .. definition.title)
    self:push(player)
end

function Game:startMission(player, index)
    local entry = self.players[player]
    if not entry or not entry.actor or entry.actor.mode ~= "Hub" or not entry.actor.alive then return end
    if not Rules.integer(index, 1, #Content.chapters) or index>entry.profile.data.chapter then self:toast(player, "Complete the previous chapter first."); return end
    local slot
    for i = 1, Config.MaxMissionRooms do if not self.slots[i] then slot = i; break end end
    if not slot then self:toast(player, "All mission rooms are in use. Try again shortly."); return end
    local chapter = Content.chapters[index]
    self.slots[slot] = player
    local mission = {slot = slot, chapter = chapter, room = World.mission(slot, Content.locations[chapter.location]), wave = 0, finished = false, deadline = workspace:GetServerTimeNow()+chapter.timeLimit}
    entry.mission = mission
    self:spawn(player, "Story")
    self:toast(player, chapter.objective)
    self:nextWave(player, mission)
end

function Game:finishRound(winner)
    if not self.round.active then return end
    self.round.active = false; self.round.restartAt = workspace:GetServerTimeNow()+8
    if winner and self.players[winner] then
        self.players[winner].profile.data.wins += 1
        task.spawn(function() self.profiles:save(winner, false) end)
    end
    for player, entry in pairs(self.players) do
        if entry.actor and entry.actor.mode == "Arena" then
            entry.actor.arenaActive = false; entry.actor.castToken += 1
            entry.actor.status = {}; entry.actor.lastAttacker = nil
            self:toast(player, winner and (winner.DisplayName .. " wins the round!") or "Round drawn.")
        end
    end
end

function Game:updateArena(now)
    local participants = {}
    for player, entry in pairs(self.players) do if entry.actor and entry.actor.mode == "Arena" then table.insert(participants, player) end end
    if #participants<2 then
        if self.round.active then self:finishRound(nil) end
        return
    end
    if not self.round.active and now >= (self.round.restartAt or 0) then
        self.round.active = true; self.round.ends = now+Config.ArenaRoundSeconds; self.round.number += 1
        for _, player in ipairs(participants) do
            self.players[player].score = 0
            self:spawn(player, "Arena")
            self:toast(player, "ROUND " .. self.round.number .. "  /  First to five")
        end
    elseif self.round.active and now>=self.round.ends then
        local best, score, tied = nil, -1, false
        for _, player in ipairs(participants) do
            local value = self.players[player].score
            if value>score then best = player; score = value; tied = false elseif value==score then tied = true end
        end
        self:finishRound(not tied and best or nil)
    end
end

function Game:handle(player, action, payload)
    local entry = self.players[player]
    if not entry or entry.profile.closing or type(action) ~= "string" or #action>24 then return end
    local now = workspace:GetServerTimeNow()
    if not Rules.takeToken(entry.bucket, now, Config.RemoteRate, Config.RemoteBurst) then return end
    local actor = entry.actor
    if action == "Ready" then self:push(player); return end
    if not actor or not actor.alive then return end
    local function direction()
        if typeof(payload) == "Vector3" and Rules.finite(payload.X) and Rules.finite(payload.Y) and Rules.finite(payload.Z) and payload.Magnitude < 100000 then
            local flat = Vector3.new(payload.X, 0, payload.Z)
            if flat.Magnitude>0.01 then return flat.Unit end
        end
        local flat = Vector3.new(actor.root.CFrame.LookVector.X, 0, actor.root.CFrame.LookVector.Z)
        return flat.Magnitude>0.01 and flat.Unit or Vector3.new(0,0,-1)
    end
    if action == "Basic" then self.combat:basic(actor, direction())
    elseif action == "Dodge" then self.combat:dodge(actor, direction())
    elseif action == "Guard" then if type(payload)=="boolean" then self.combat:guard(actor, payload) end
    elseif action == "Skill" then
        if type(payload)~="table" or not Rules.integer(payload.slot, 1, 4) then return end
        local loadout = entry.profile.data.loadouts[actor.characterId]
        local move = Content.moves[loadout[payload.slot]]
        if not move then return end
        local requestedDirection = payload.direction
        payload = requestedDirection
        local ok, reason = self.combat:cast(actor, move, direction())
        if not ok and now>(entry.lastNotice or 0)+1 then self:toast(player, reason); entry.lastNotice = now end
    elseif action == "Select" then
        if actor.mode~="Hub" or type(payload)~="string" or #payload>40 then return end
        local character = Content.characters[payload]
        if not character or not character.playable then return end
        if now<(entry.nextMenuAction or 0) then return end
        entry.nextMenuAction = now+0.75
        entry.profile.data.selected = payload
        self:spawn(player, "Hub")
        self:toast(player, character.name .. " selected")
    elseif action == "Equip" then
        if actor.mode~="Hub" or type(payload)~="table" or not Rules.integer(payload.slot, 1, 4) or type(payload.move)~="string" then return end
        local character = Content.characters[entry.profile.data.selected]
        if not table.find(character.moves, payload.move) then return end
        local loadout = entry.profile.data.loadouts[character.id]
        local previous = table.find(loadout, payload.move)
        if previous then loadout[previous] = loadout[payload.slot] end
        loadout[payload.slot] = payload.move
        self:push(player)
    elseif action == "Story" then
        self:startMission(player, payload)
    elseif action == "Arena" then
        if actor.mode=="Hub" then entry.score = 0; self:spawn(player, "Arena"); self:toast(player, "Arena joined. Invite another player to begin.") end
    elseif action == "Hub" then
        if actor.mode=="Hub" then return end
        if now-actor.lastCombat<5 then self:toast(player, "Wait five seconds out of combat to leave."); return end
        self:clearMission(entry); self:spawn(player, "Hub")
    end
end

function Game:addPlayer(player)
    local profile = self.profiles:load(player)
    if player.Parent~=Players then self.profiles:save(player, true); return end
    self.players[player] = {profile = profile, score = 0, bucket = {tokens = Config.RemoteBurst, time = workspace:GetServerTimeNow()}}
    self:spawn(player, "Hub")
    self:toast(player, "Welcome to the Wisteria courtyard. Choose your path.")
end

function Game:addDummy(position)
    local model, humanoid, root = Rig.create(World.Actors, position, Content.characters.training)
    local actor
    actor = self.combat:register(model, humanoid, root, {kind = "dummy", mode = "Hub", zone = "hub", characterId = "training", room = World.Hub, maxHealth = 300,
        onDeath = function()
            task.delay(2, function() self.combat:remove(actor); if not self.shuttingDown then self:addDummy(position) end end)
        end,
    })
    root.Anchored = true
end

function Game:start()
    Players.CharacterAutoLoads = false
    self:addDummy(Vector3.new(-32,4,-30))
    self:addDummy(Vector3.new(32,4,-30))
    self.action.OnServerEvent:Connect(function(player, action, payload) self:handle(player, action, payload) end)
    Players.PlayerAdded:Connect(function(player) self:addPlayer(player) end)
    Players.PlayerRemoving:Connect(function(player)
        local entry = self.players[player]
        if entry then
            self:clearMission(entry)
            if entry.actor then self.combat:remove(entry.actor) end
            self.players[player] = nil
        end
        self.profiles:save(player, true)
    end)
    for _, player in ipairs(Players:GetPlayers()) do task.spawn(function() self:addPlayer(player) end) end
    self.heartbeat = RunService.Heartbeat:Connect(function(dt)
        self.combat:tick(math.min(dt, 0.1))
        self.accumulated += dt
        if self.accumulated<0.2 then return end
        self.accumulated = 0
        local now = workspace:GetServerTimeNow()
        self:updateArena(now)
        for player, entry in pairs(self.players) do
            if entry.mission and now>entry.mission.deadline then
                self:toast(player, "Mission time expired. Try again from the courtyard.")
                self:clearMission(entry); self:spawn(player, "Hub")
            end
            self:push(player)
        end
    end)
    task.spawn(function()
        while not self.shuttingDown do
            task.wait(Config.SaveInterval)
            for player in pairs(self.players) do task.spawn(function() self.profiles:save(player, false) end) end
        end
    end)
    game:BindToClose(function()
        self.shuttingDown = true
        local outstanding = 0
        for player in pairs(self.profiles.sessions) do
            outstanding += 1
            task.spawn(function() self.profiles:save(player, true); outstanding -= 1 end)
        end
        local deadline = os.clock()+25
        while outstanding>0 and os.clock()<deadline do task.wait(0.1) end
    end)
    workspace:SetAttribute("WisteriaReady", true)
    print("[Wisteria] Server ready: 44 characters / 210 techniques / story and arena")
    return self
end

return Game
