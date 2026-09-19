-- Pure melee rules for the R15 sword kit: no Roblox dependencies; exercised by tests/core.spec.luau.
local MeleeRules = {}

-- state = {step, lastEnd, busyUntil}. Returns the next M1 step (1-4) or nil while the actor cannot swing.
function MeleeRules.nextChain(state, now, cfg)
    if now < state.busyUntil then return nil end
    if state.step >= 4 then
        return now >= state.lastEnd + cfg.EndLag and 1 or nil
    end
    if state.step >= 1 and now - state.lastEnd <= cfg.ChainWindow then return state.step + 1 end
    return 1
end

-- forward/side/up are the target's offset in the attacker's local space (forward = -Z).
function MeleeRules.inHitbox(forward, side, up, box)
    return forward >= 0 and forward <= box.forwardOffset + box.length / 2 + box.tolerance
        and math.abs(side) <= box.width / 2 and math.abs(up) <= box.height / 2
end

-- Block only answers M1s from the front. Techniques always pass through.
function MeleeRules.blockOutcome(isBlocking, frontalDot, sinceBlockStart, isFinisher, isTechnique, cfg)
    if not isBlocking or isTechnique or frontalDot <= cfg.BlockFrontDot then return "hit" end
    if sinceBlockStart <= cfg.ParryWindow then return "parry" end
    if isFinisher then return "guardbreak" end
    return "block"
end

function MeleeRules.tier(move)
    if move.tier then return move.tier end
    return move.damage < 20 and 1 or move.damage < 35 and 2 or 3
end

-- Two opposing techniques whose active frames land within `window` seconds clash.
function MeleeRules.clash(aActiveAt, bActiveAt, aTier, bTier, window)
    if math.abs(aActiveAt - bActiveAt) > window then return nil end
    if aTier > bTier then return "a" end
    if bTier > aTier then return "b" end
    return "cancel"
end

-- Direction in the actor's local space, forward = -Z.
function MeleeRules.dashKind(localX, localZ)
    if localX * localX + localZ * localZ < 0.0001 then return "front" end
    if math.abs(localX) > math.abs(localZ) then return localX < 0 and "left" or "right" end
    return localZ <= 0 and "front" or "back"
end

return MeleeRules
