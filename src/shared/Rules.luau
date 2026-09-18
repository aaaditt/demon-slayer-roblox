-- Pure rules: no Roblox dependencies; exercised by tests/core.spec.luau.
local Rules = {}

function Rules.finite(value)
    return type(value) == "number" and value == value and math.abs(value) < math.huge
end

function Rules.integer(value, minimum, maximum)
    return Rules.finite(value) and value % 1 == 0 and value >= minimum and value <= maximum
end

-- Timing comes from the server clock, never from a client-provided timestamp.
function Rules.focusWindow(elapsed, period, opens, closes, lastCycle)
    if not Rules.finite(elapsed) or not Rules.finite(period) or elapsed < 0 or period <= 0 then return false, -1, 0 end
    local cycle = math.floor(elapsed/period)
    local phase = elapsed-cycle*period
    return cycle > lastCycle and phase >= opens and phase <= closes, cycle, phase
end

function Rules.trainingDamage(health, amount, floor)
    return math.min(amount, math.max(0, health-(floor or 0)))
end

function Rules.spend(state, move, now)
    if now < state.busyUntil or now < state.stunUntil then return false, "Recovering" end
    if (state.cooldowns[move.id] or 0) > now then return false, "Cooling down" end
    if state.energy < move.cost then return false, "Need more energy" end
    state.energy -= move.cost
    state.cooldowns[move.id] = now + move.cooldown
    state.busyUntil = now + move.windup + move.recovery + (move.hits - 1) * 0.09
    return true
end

function Rules.takeToken(bucket, now, rate, capacity)
    bucket.tokens = math.min(capacity, bucket.tokens + math.max(0, now - bucket.time) * rate)
    bucket.time = now
    if bucket.tokens < 1 then return false end
    bucket.tokens -= 1
    return true
end

function Rules.canDamage(attacker, defender)
    if attacker == defender or attacker.zone ~= defender.zone then return false end
    if attacker.mode == "Arena" and defender.mode == "Arena" then
        return attacker.kind == "player" and defender.kind == "player"
    end
    if attacker.mode == "Story" and defender.mode == "Story" then
        return attacker.kind ~= defender.kind
    end
    return attacker.mode == "Hub" and attacker.kind == "player" and defender.kind == "dummy"
end

function Rules.inShape(pattern, forward, side, range, width)
    if pattern == "spin" or pattern == "burst" then
        return forward * forward + side * side <= range * range
    end
    return forward >= -2 and forward <= range and math.abs(side) <= width / 2
end

function Rules.resolveDamage(amount, defense, now, frontal, guardCost, reduction, parryWindow)
    if defense.invulnerableUntil > now then return 0, "evade", 0 end
    if defense.guardUntil > now then return 0, "counter", 0 end
    if defense.blocking and frontal then
        if now - defense.blockStarted <= parryWindow then return 0, "parry", 0 end
        if defense.energy >= guardCost then return amount * (1 - reduction), "block", guardCost end
        return amount, "break", defense.energy
    end
    return amount, "hit", 0
end

function Rules.rank(xp)
    local names = {"Mizunoto", "Mizunoe", "Kanoto", "Kanoe", "Tsuchinoto", "Tsuchinoe", "Hinoto", "Hinoe", "Kinoto", "Kinoe"}
    return names[math.clamp(math.floor(math.sqrt(xp / 150)) + 1, 1, #names)]
end

function Rules.profile(raw, content)
    raw = type(raw) == "table" and raw or {}
    local function number(value, low, high)
        return Rules.finite(value) and math.clamp(math.floor(value), low, high) or low
    end
    local selected = type(raw.selected) == "string" and content.characters[raw.selected]
    local clean = {
        schema = 1, xp = number(raw.xp, 0, 100000000),
        chapter = number(raw.chapter, 1, #content.chapters + 1),
        selected = selected and selected.playable and selected.id or "tanjiro",
        kills = number(raw.kills, 0, 10000000), deaths = number(raw.deaths, 0, 10000000),
        wins = number(raw.wins, 0, 10000000), loadouts = {}, mastery = {},
    }
    for id, character in pairs(content.characters) do
        if character.playable then
            local supplied = type(raw.loadouts) == "table" and raw.loadouts[id]
            local set, slots = {}, {}
            if type(supplied) == "table" then
                for i = 1, 4 do
                    local move = supplied[i]
                    if type(move) == "string" and table.find(character.moves, move) and not set[move] then
                        slots[i] = move
                        set[move] = true
                    end
                end
            end
            for i = 1, 4 do
                if not slots[i] then
                    for _, move in ipairs(character.loadout) do
                        if not set[move] then slots[i] = move; set[move] = true; break end
                    end
                end
            end
            clean.loadouts[id] = slots
            clean.mastery[id] = number(type(raw.mastery) == "table" and raw.mastery[id], 0, 10000000)
        end
    end
    return clean
end

function Rules.claimLease(record, token, now, duration)
    if type(record) == "table" and type(record.lease) == "table" then
        local lease = record.lease
        if lease.token ~= token and Rules.finite(lease.expires) and lease.expires > now then return nil end
    end
    return {data = type(record) == "table" and record.data or nil, lease = {token = token, expires = now + duration}}
end

function Rules.saveLease(record, token, now, duration, snapshot, release)
    if type(record) ~= "table" or type(record.lease) ~= "table" or record.lease.token ~= token then return nil end
    local lease = nil
    if not release then lease = {token = token, expires = now + duration} end
    return {data = snapshot, lease = lease}
end

return Rules
