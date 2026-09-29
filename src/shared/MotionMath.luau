-- Pure animation math shared by the client player and portable tests. No Roblox types.
local MotionMath = {}

local function bounceOut(a)
    local n, d = 7.5625, 2.75
    if a < 1/d then return n*a*a
    elseif a < 2/d then a -= 1.5/d; return n*a*a+0.75
    elseif a < 2.5/d then a -= 2.25/d; return n*a*a+0.9375 end
    a -= 2.625/d
    return n*a*a+0.984375
end

local function elasticOut(a)
    if a <= 0 or a >= 1 then return a end
    return 2^(-10*a)*math.sin((a*10-0.75)*(2*math.pi/3))+1
end

local curves = {
    Cubic = function(a) return 1-(1-a)^3 end,
    Elastic = elasticOut,
    Bounce = bounceOut,
}

local function directed(out, direction, a)
    if direction == "Out" then return out(a)
    elseif direction == "In" then return 1-out(1-a) end
    return a < 0.5 and (1-out(1-2*a))/2 or (1+out(2*a-1))/2
end

-- Roblox PoseEasingStyle/Direction for the segment from one keyframe to the next.
-- Legacy Cubic/Elastic/Bounce have In and Out reversed relative to TweenService; CubicV2 uses the correct
-- direction (Roblox documents the reversal for Cubic; Elastic/Bounce are assumed to share it).
function MotionMath.ease(style, direction, a)
    a = math.clamp(a, 0, 1)
    if style == "Linear" then return a
    elseif style == "Constant" then return a >= 1 and 1 or 0
    elseif style == "CubicV2" then return directed(curves.Cubic, direction, a) end
    local out = curves[style]
    if not out then return a end
    local swapped = direction == "In" and "Out" or direction == "Out" and "In" or direction
    return directed(out, swapped, a)
end

-- Index of the keyframe at or before t, and the 0..1 progress toward the next one (clamped at both ends).
function MotionMath.bracket(times, t)
    local n = #times
    if n == 0 then return 0, 0 end
    if t <= times[1] then return 1, 0 end
    if t >= times[n] then return n, 0 end
    local lo, hi = 1, n
    while hi-lo > 1 do
        local mid = (lo+hi)//2
        if times[mid] <= t then lo = mid else hi = mid end
    end
    return lo, (t-times[lo])/(times[hi]-times[lo])
end

-- Maps real time since an attack began onto clip time so the clip's Hit marker lands exactly on the
-- server windup and its End marker on windup + recovery. Server timings stay authoritative.
function MotionMath.warp(elapsed, hit, finish, windup, total)
    if elapsed <= 0 then return 0 end
    if windup > 0 and elapsed <= windup then return elapsed/windup*hit end
    if elapsed >= total or total <= windup then return finish end
    return hit+(elapsed-windup)/(total-windup)*(finish-hit)
end

-- Clip time for an action that started `elapsed` seconds ago and lasts `duration` on the server.
function MotionMath.actionTime(entry, elapsed, duration, windup)
    if entry.hit and entry.finish and windup then return MotionMath.warp(elapsed, entry.hit, entry.finish, windup, duration) end
    if entry.loop and entry.length > 0 then return elapsed%entry.length end
    return math.min(elapsed, entry.length)
end

-- Linear fade of a layer weight toward its target over `fade` seconds.
function MotionMath.approach(weight, target, dt, fade)
    if fade <= 0 then return target end
    local step = dt/fade
    if weight < target then return math.min(target, weight+step) end
    return math.max(target, weight-step)
end

-- Classifies a planar dash direction against the facing (Roblox LookVector; RightVector = (-lookZ, lookX)).
function MotionMath.dashDirection(lookX, lookZ, dirX, dirZ)
    local forward = lookX*dirX+lookZ*dirZ
    local side = -lookZ*dirX+lookX*dirZ
    if math.abs(forward) >= math.abs(side) then return forward >= 0 and "front" or "back" end
    return side > 0 and "right" or "left"
end

return MotionMath
