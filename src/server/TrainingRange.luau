-- Studio-only combat test range: still target, blocking target and a sparring partner that fights back.
-- Never runs in a published server (RunService:IsStudio() gate) and needs no uploaded assets.
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Content = require(Shared.Content)
local Config = require(Shared.Config)
local Swords = require(Shared.Swords)
local Rig = require(script.Parent.Rig)
local World = require(script.Parent.World)
local CharacterBody = require(script.Parent.CharacterBody)
local SwordBuilder = require(script.Parent.SwordBuilder)
local TrainingRange = {}
TrainingRange.__index = TrainingRange

local CENTER = Vector3.new(0, 4, -18)
local SPOTS = {still = Vector3.new(-14, 0, -8), blocker = Vector3.new(0, 0, -10), spar = Vector3.new(14, 0, -8)}
local LEASH = 46

local function label(model, head, text, color)
    local board = Instance.new("BillboardGui")
    board.Name = "RangeLabel"; board.Size = UDim2.fromOffset(240, 34)
    board.StudsOffset = Vector3.new(0, 4.4, 0); board.MaxDistance = 140
    board.AlwaysOnTop = true; board.Adornee = head; board.Parent = head
    local caption = Instance.new("TextLabel")
    caption.Size = UDim2.fromScale(1, 1); caption.BackgroundTransparency = 1
    caption.Font = Enum.Font.GothamBold; caption.TextSize = 14; caption.TextColor3 = color
    caption.TextStrokeTransparency = 0.4; caption.Text = text; caption.Parent = board
    model:SetAttribute("RangeRole", text)
end

function TrainingRange.start(game)
    -- Studio only, and never during the automated multiplayer suite (its sparring partner would interfere).
    if not RunService:IsStudio() or game:GetAttribute("WisteriaAutomatedTest") then return nil end
    local self = setmetatable({game = game, combat = game.combat, actors = {}, sparEnabled = true}, TrainingRange)
    self:spawnStill()
    self:spawnBlocker()
    self:spawnSparring()
    print("[Wisteria] Training range ready at " .. tostring(CENTER) .. " (Studio only).")
    return self
end

function TrainingRange:register(model, humanoid, root, options, text, color)
    local actor = self.combat:register(model, humanoid, root, options)
    actor.invulnerableUntil = 0
    label(model, model:FindFirstChild("Head"), text, color)
    table.insert(self.actors, actor)
    return actor
end

-- A still 400 HP target: pure damage, combo and hit-feedback testing.
function TrainingRange:spawnStill()
    local position = CENTER + SPOTS.still
    local model, humanoid, root = Rig.create(World.Actors, position, Content.characters.training)
    root.Anchored = true
    self.still = self:register(model, humanoid, root, {
        kind = "dummy", mode = "Hub", zone = "hub", characterId = "training", room = World.Hub, maxHealth = 400,
        onDeath = function() task.delay(1.5, function() self.combat:remove(self.still); if not self.game.shuttingDown then self:spawnStill() end end) end,
    }, "STILL TARGET", Color3.fromRGB(236, 226, 198))
end

-- A permanently blocking R15 target: guard, parry window, guard break and techniques-through-block.
function TrainingRange:spawnBlocker()
    local position = CENTER + SPOTS.blocker
    local model, humanoid, root = CharacterBody.create(World.Actors, position, Content.characters.tanjiro, "Blocking Target", {swordVariant = "tanjiro_black"})
    if not model then return end
    root.Anchored = true
    SwordBuilder.setDrawn(model, true)
    self.blocker = self:register(model, humanoid, root, {
        kind = "dummy", mode = "Hub", zone = "hub", characterId = "tanjiro", room = World.Hub, maxHealth = 400,
        onDeath = function() task.delay(1.5, function() self.combat:remove(self.blocker); if not self.game.shuttingDown then self:spawnBlocker() end end) end,
    }, "BLOCKING TARGET", Color3.fromRGB(150, 206, 255))
    self.blocker.blocking = true
    self.blocker.blockStarted = 0
    model:SetAttribute("Anim", "block"); model:SetAttribute("AnimStart", workspace:GetServerTimeNow())
end

-- A sparring partner that closes in, swings and casts techniques (for clashes, blocking and getting hit).
function TrainingRange:spawnSparring()
    local position = CENTER + SPOTS.spar
    local definition = Content.characters.giyu
    local model, humanoid, root = Rig.create(World.Actors, position, definition)
    self.spar = self:register(model, humanoid, root, {
        kind = "sparring", mode = "Hub", zone = "hub", characterId = "giyu", room = World.Hub, maxHealth = 500,
        damageScale = 0.5, attackInterval = 1.4, home = position,
        onDeath = function() task.delay(2, function() self.combat:remove(self.spar); if not self.game.shuttingDown then self:spawnSparring() end end) end,
    }, "SPARRING PARTNER  (fights back)", Color3.fromRGB(255, 176, 140))
end

-- Retarget the sparring partner, leash it home and top the targets back up between tests.
function TrainingRange:tick()
    local now = workspace:GetServerTimeNow()
    for _, actor in ipairs(self.actors) do
        if actor.alive and actor.model.Parent and now - actor.lastCombat > 5 and actor.humanoid.Health < actor.humanoid.MaxHealth then
            actor.humanoid.Health = actor.humanoid.MaxHealth
        end
    end
    if self.blocker and self.blocker.alive then
        self.blocker.blocking = true
        if now - self.blocker.blockStarted > 1 then self.blocker.blockStarted = now - Config.Melee.ParryWindow - 0.01 end
    end
    local spar = self.spar
    if not spar or not spar.alive then return end
    local closest, distance = nil, LEASH
    for _, entry in pairs(self.game.players) do
        local actor = entry.actor
        if actor and actor.alive and actor.mode == "Hub" then
            local offset = (actor.root.Position - spar.home).Magnitude
            if offset < distance then closest, distance = actor, offset end
        end
    end
    spar.target = self.sparEnabled and closest or nil
    if not spar.target and (spar.root.Position - spar.home).Magnitude > 4 then spar.humanoid:MoveTo(spar.home) end
end

-- Studio-only test commands from the client panel.
function TrainingRange:command(player, payload)
    local entry = self.game.players[player]
    local actor = entry and entry.actor
    if not actor or type(payload) ~= "table" or type(payload.kind) ~= "string" then return end
    if payload.kind == "heal" then
        actor.humanoid.Health = actor.humanoid.MaxHealth
        actor.energy = Config.MaxEnergy
        actor.cooldowns = {}; actor.stunUntil = 0; actor.busyUntil = 0; actor.chain = nil
        self.game:toast(player, "Range: healed, cooldowns cleared")
    elseif payload.kind == "sword" then
        local order = {"urokodaki_steel", "tanjiro_black", "tanjiro_yoriichi"}
        local current = actor.model:GetAttribute("SwordVariant")
        local index = table.find(order, current) or #order
        local nextId = order[index % #order + 1]
        if actor.model:GetAttribute("RigKind") ~= "R15" then self.game:toast(player, "Range: sword swap needs the R15 kit (play Tanjiro)"); return end
        local drawn = actor.model:GetAttribute("WeaponDrawn")
        local sword = actor.model:FindFirstChild("Sword")
        if sword then sword:Destroy() end
        actor.model:SetAttribute("SwordVariant", nextId)
        SwordBuilder.build(actor.model, nextId)
        SwordBuilder.setDrawn(actor.model, drawn == true)
        self.game:toast(player, "Range: " .. nextId)
    elseif payload.kind == "spar" then
        self.sparEnabled = not self.sparEnabled
        if self.spar then self.spar.target = nil end
        self.game:toast(player, "Range: sparring partner " .. (self.sparEnabled and "engaged" or "paused"))
    elseif payload.kind == "teleport" then
        if actor.mode ~= "Hub" then self.game:toast(player, "Range: return to the hub first"); return end
        actor.model:PivotTo(CFrame.new(CENTER + Vector3.new(0, 1, 6)))
        actor.lastPosition = actor.root.Position; actor.motionTime = workspace:GetServerTimeNow()
        self.game:toast(player, "Range: teleported")
    end
end

TrainingRange.CENTER = CENTER
TrainingRange.SWORDS = Swords
return TrainingRange
