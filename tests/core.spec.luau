local Rules = require("../src/shared/Rules")
local Content = require("../src/shared/Content")
local MotionMath = require("../src/shared/MotionMath")
local AnimationIndex = require("../src/shared/AnimationIndex")
local MotionProfile = require("../src/shared/MotionProfile")
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

test("breathing windows reject early, late and repeated beats", function()
    assert(not Rules.focusWindow(0.5,3.2,1.4,2.5,-1))
    assert(Rules.focusWindow(1.8,3.2,1.4,2.5,-1))
    assert(not Rules.focusWindow(1.9,3.2,1.4,2.5,0))
    assert(not Rules.focusWindow(2.7,3.2,1.4,2.5,-1))
    local accepted,cycle=Rules.focusWindow(5,3.2,1.4,2.5,0)
    assert(accepted and cycle==1)
    assert(not Rules.focusWindow(0/0,3.2,1.4,2.5,-1))
    assert(not Rules.focusWindow(1.8,0,1.4,2.5,-1))
end)

test("training damage preserves life without granting healing", function()
    assert(Rules.trainingDamage(160,12,1)==12)
    assert(Rules.trainingDamage(5,12,1)==4)
    assert(Rules.trainingDamage(1,12,1)==0)
    assert(Rules.trainingDamage(0,12,1)==0)
    assert(Rules.trainingDamage(5,12)==5)
end)

test("story combat permissions allow only the current chapter kit",function()
    local actor={storyLocked=true,storyCanBasic=false}
    assert(not Rules.storyMoveAllowed(actor,"basic") and not Rules.storyMoveAllowed(actor,"water_1"))
    actor.storyCanBasic=true
    assert(Rules.storyMoveAllowed(actor,"basic") and not Rules.storyMoveAllowed(actor,"water_1"))
    actor.storyMoves={water_1=true,water_2=true}
    assert(Rules.storyMoveAllowed(actor,"water_1"))
    assert(not Rules.storyMoveAllowed(actor,"sun_dance") and not Rules.storyMoveAllowed(actor,"water_11"))
    actor.storyMoves=nil;actor.storyCanBasic=false
    assert(not Rules.storyMoveAllowed(actor,"water_1"))
    actor.storyLocked=false;assert(Rules.storyMoveAllowed(actor,"water_1"))
end)

local function near(a, b) return math.abs(a-b) < 1e-6 end

test("pose easing hits endpoints, and legacy Cubic reverses CubicV2 directions", function()
    for _, style in ipairs({"Linear", "Cubic", "CubicV2", "Elastic", "Bounce"}) do
        for _, direction in ipairs({"In", "Out", "InOut"}) do
            assert(near(MotionMath.ease(style, direction, 0), 0) and near(MotionMath.ease(style, direction, 1), 1), style..direction)
        end
    end
    assert(near(MotionMath.ease("CubicV2", "In", 0.5), 0.125) and near(MotionMath.ease("CubicV2", "Out", 0.5), 0.875))
    assert(near(MotionMath.ease("CubicV2", "InOut", 0.5), 0.5))
    assert(near(MotionMath.ease("Cubic", "In", 0.3), MotionMath.ease("CubicV2", "Out", 0.3)))
    assert(MotionMath.ease("Constant", "In", 0.99) == 0 and MotionMath.ease("Linear", "In", 2) == 1)
end)

test("keyframe bracketing clamps and interpolates between neighbours", function()
    local times = {0, 0.5, 1.2, 2.4}
    local i, a = MotionMath.bracket(times, -1); assert(i == 1 and a == 0)
    i, a = MotionMath.bracket(times, 9); assert(i == 4 and a == 0)
    i, a = MotionMath.bracket(times, 0.85); assert(i == 2 and near(a, 0.5))
    i, a = MotionMath.bracket(times, 1.2); assert(i == 3 and a == 0)
end)

test("attack time-warp lands the Hit marker exactly on the server windup", function()
    local entry = {hit = 0.3, finish = 0.8, length = 1, loop = false}
    assert(near(MotionMath.actionTime(entry, 0.12, 0.44, 0.12), 0.3), "hit not on windup")
    assert(near(MotionMath.actionTime(entry, 0.44, 0.44, 0.12), 0.8), "end not on recovery")
    assert(near(MotionMath.actionTime(entry, 0.06, 0.44, 0.12), 0.15) and MotionMath.actionTime(entry, 5, 0.44, 0.12) == 0.8)
    assert(near(MotionMath.actionTime({length = 2, loop = true}, 5, 30), 1) and MotionMath.actionTime({length = 2}, 5, 30) == 2)
    assert(MotionMath.approach(0, 1, 0.05, 0.1) == 0.5 and MotionMath.approach(0.9, 1, 1, 0.1) == 1)
end)

test("dash directions classify against the facing, not the world", function()
    assert(MotionMath.dashDirection(0, -1, 0, -1) == "front" and MotionMath.dashDirection(0, -1, 0, 1) == "back")
    assert(MotionMath.dashDirection(0, -1, 1, 0) == "right" and MotionMath.dashDirection(0, -1, -1, 0) == "left")
    assert(MotionMath.dashDirection(1, 0, 0, 1) == "right" and MotionMath.dashDirection(1, 0, 0, -1) == "left")
    assert(MotionMath.dashDirection(0, -1, 0.3, -0.9) == "front")
end)

test("generated animation index describes every clip the runtime can play", function()
    local count = 0
    for name, entry in pairs(AnimationIndex) do
        count += 1
        assert(entry.length > 0 and (entry.hit == nil or (entry.hit < entry.finish and entry.finish <= entry.length)), name)
    end
    assert(count >= 2 and AnimationIndex["base/idle_sheathed"].loop and AnimationIndex["base/idle_drawn"].loop)
end)

test("character motion picks specific clips and safely falls back for partial or missing profiles", function()
    local profiles=MotionProfile.new(Content,AnimationIndex)
    assert(profiles.id("tanjiro")=="tanjiro" and profiles.id("giyu")=="base")
    assert(profiles.locomotion("tanjiro","idle",true)=="tanjiro/idle_drawn")
    assert(profiles.locomotion("tanjiro","walk",true)=="tanjiro/walk_drawn")
    assert(profiles.locomotion("tanjiro","walk",false)=="base/walk_sheathed")
    assert(profiles.locomotion("giyu","walk",true)=="base/walk_sheathed")
    assert(profiles.action("tanjiro","slash","combo_2")=="tanjiro/combo_2")
    assert(profiles.action("tanjiro","slash","unknown")=="base/slash")
    assert(profiles.action("story_actor_3","slash")=="base/slash")
    assert(profiles.action("tanjiro","kneel")==nil)
    local partial=MotionProfile.new({characters={test={motionProfile="missing"}},motionProfiles={base={clips={slash="missing/clip"}}}},AnimationIndex)
    assert(partial.id("test")=="base" and partial.clip("test","slash")=="base/slash")
end)

test("approved movement rejects excess speed, reach, lateral drift, reverse and non-finite positions",function()
    assert(Rules.motionEnvelope(5,0,0.1,50,16,1.5))
    assert(Rules.motionEnvelope(16,0,0.7,50,16,1.5)) -- A late replicated endpoint stays bounded.
    assert(not Rules.motionEnvelope(10,0,0.1,50,16,1.5))
    assert(not Rules.motionEnvelope(18,0,1,50,16,1.5))
    assert(not Rules.motionEnvelope(5,2,0.1,50,16,1.5))
    assert(not Rules.motionEnvelope(-2,0,0.1,50,16,1.5))
    assert(not Rules.motionEnvelope(0/0,0,0.1,50,16,1.5))
    assert(not Rules.motionEnvelope(5,math.huge,0.1,50,16,1.5))
end)

test("Tanjiro combo Hit and End align to server timing for every override", function()
    for i=1,3 do
        local entry=AnimationIndex["tanjiro/combo_"..i]
        assert(math.abs(MotionMath.actionTime(entry,0.23,0.72,0.23)-entry.hit)<1e-6)
        assert(math.abs(MotionMath.actionTime(entry,0.72,0.72,0.23)-entry.finish)<1e-6)
    end
end)

print(string.format("%d core tests passed", passed))
