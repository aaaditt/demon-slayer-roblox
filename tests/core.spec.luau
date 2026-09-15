local Rules = require("../src/shared/Rules")
local Content = require("../src/shared/Content")
local passed = 0
local function test(name, run)
    run()
    passed += 1
    print("PASS " .. name)
end

test("reject malformed numeric input", function()
    assert(not Rules.finite(0/0))
    assert(not Rules.finite(math.huge))
    assert(not Rules.integer("1", 1, 4))
    assert(not Rules.integer(1.5, 1, 4))
    assert(Rules.integer(4, 1, 4))
end)

test("cooldown, stun, recovery and resource admission is atomic", function()
    local s = {energy = 40, busyUntil = 0, stunUntil = 0, cooldowns = {}}
    local move = Content.moves.water_1
    assert(Rules.spend(s, move, 1))
    local energy = s.energy
    assert(not Rules.spend(s, move, 1.1))
    assert(s.energy == energy)
    s.stunUntil = 10
    assert(not Rules.spend(s, move, 6))
    s.stunUntil = 0
    assert(Rules.spend(s, move, 11))
    assert(not Rules.spend(s, move, 20))
end)

test("remote spam exhausts and refills a token bucket", function()
    local b = {tokens = 2, time = 10}
    assert(Rules.takeToken(b, 10, 2, 2))
    assert(Rules.takeToken(b, 10, 2, 2))
    assert(not Rules.takeToken(b, 10, 2, 2))
    assert(Rules.takeToken(b, 10.5, 2, 2))
    assert(not Rules.takeToken(b, 10.5, 2, 2))
end)

test("hub safety and private mission isolation", function()
    local p = {mode = "Hub", zone = "hub", kind = "player"}
    assert(not Rules.canDamage(p, {mode = "Hub", zone = "hub", kind = "player"}))
    assert(Rules.canDamage(p, {mode = "Hub", zone = "hub", kind = "dummy"}))
    p.mode = "Story"; p.zone = "mission1"
    assert(Rules.canDamage(p, {mode = "Story", zone = "mission1", kind = "npc"}))
    assert(not Rules.canDamage(p, {mode = "Story", zone = "mission2", kind = "npc"}))
    p.mode = "Arena"; p.zone = "arena"
    assert(Rules.canDamage(p, {mode = "Arena", zone = "arena", kind = "player"}))
    assert(not Rules.canDamage(p, p))
end)

test("directional attacks cannot strike behind or outside reach", function()
    assert(Rules.inShape("slash", 8, 3, 12, 10))
    assert(not Rules.inShape("slash", -4, 0, 12, 10))
    assert(not Rules.inShape("slash", 8, 6, 12, 10))
    assert(not Rules.inShape("slash", 13, 0, 12, 10))
    assert(Rules.inShape("spin", -5, 0, 12, 12))
    assert(not Rules.inShape("spin", 10, 10, 12, 12))
end)

test("parry, guard break, rear attacks and dodge", function()
    local d = {invulnerableUntil = 0, guardUntil = 0, blocking = true, blockStarted = 1, energy = 20}
    local damage, reason, cost = Rules.resolveDamage(40, d, 1.1, true, 13, 0.75, 0.18)
    assert(damage == 0 and reason == "parry")
    damage, reason, cost = Rules.resolveDamage(40, d, 2, true, 13, 0.75, 0.18)
    assert(damage == 10 and reason == "block" and cost == 13)
    damage = Rules.resolveDamage(40, d, 2, false, 13, 0.75, 0.18)
    assert(damage == 40)
    d.energy = 2
    damage, reason = Rules.resolveDamage(40, d, 2, true, 13, 0.75, 0.18)
    assert(damage == 40 and reason == "break")
    d.invulnerableUntil = 3
    damage = Rules.resolveDamage(40, d, 2, false, 13, 0.75, 0.18)
    assert(damage == 0)
end)

test("corrupted profiles cannot grant arbitrary moves or characters", function()
    local p = Rules.profile({xp = 0/0, chapter = 999, selected = "kagaya", loadouts = {zenitsu = {"thunder_2", "thunder_1", "thunder_1", false}}}, Content)
    assert(p.xp == 0 and p.selected == "tanjiro")
    assert(p.chapter == #Content.chapters + 1)
    local seen = {}
    for _, move in ipairs(p.loadouts.zenitsu) do
        assert(table.find(Content.characters.zenitsu.moves, move))
        assert(not seen[move]); seen[move] = true
    end
    assert(#p.loadouts.zenitsu == 4)
end)

test("active save lease prevents a second server overwriting progression", function()
    local record = Rules.claimLease(nil, "serverA", 100, 180)
    assert(record and not Rules.claimLease(record, "serverB", 110, 180))
    assert(not Rules.saveLease(record, "serverB", 110, 180, {xp = 0}, false))
    local saved = Rules.saveLease(record, "serverA", 120, 180, {xp = 200}, true)
    assert(saved and saved.data.xp == 200 and saved.lease == nil)
    local second = Rules.claimLease(saved, "serverB", 121, 180)
    assert(second.data.xp == 200)
    assert(Rules.claimLease(record, "serverB", 281, 180))
end)

print(string.format("%d core tests passed", passed))
