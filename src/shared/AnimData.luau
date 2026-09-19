-- Pure keyframe helpers shared by the server (timings), client (KeyframePlayer) and build (KeyframeSequence export).
-- Pose values are {rx, ry, rz} degrees with optional {px, py, pz} stud offsets, applied as Motor6D.Transform.
-- R15 axis notes: shoulder +rx raises the arm forward, RightShoulder +rz swings it outward (LeftShoulder -rz),
-- elbow +rx bends forward, knee -rx bends back, Root -rx leans forward, Waist +ry turns the chest left.
local AnimData = {}

AnimData.JOINTS = {
    "Root", "Waist", "Neck",
    "RightShoulder", "RightElbow", "RightWrist",
    "LeftShoulder", "LeftElbow", "LeftWrist",
    "RightHip", "RightKnee", "RightAnkle",
    "LeftHip", "LeftKnee", "LeftAnkle",
}

-- Part1 of each R15 joint, used by the KeyframeSequence exporter to nest Poses.
AnimData.PARENT = {
    Root = {"HumanoidRootPart", "LowerTorso"}, Waist = {"LowerTorso", "UpperTorso"}, Neck = {"UpperTorso", "Head"},
    RightShoulder = {"UpperTorso", "RightUpperArm"}, RightElbow = {"RightUpperArm", "RightLowerArm"}, RightWrist = {"RightLowerArm", "RightHand"},
    LeftShoulder = {"UpperTorso", "LeftUpperArm"}, LeftElbow = {"LeftUpperArm", "LeftLowerArm"}, LeftWrist = {"LeftLowerArm", "LeftHand"},
    RightHip = {"LowerTorso", "RightUpperLeg"}, RightKnee = {"RightUpperLeg", "RightLowerLeg"}, RightAnkle = {"RightLowerLeg", "RightFoot"},
    LeftHip = {"LowerTorso", "LeftUpperLeg"}, LeftKnee = {"LeftUpperLeg", "LeftLowerLeg"}, LeftAnkle = {"LeftLowerLeg", "LeftFoot"},
}

function AnimData.get(set, id)
    return set[id]
end

function AnimData.marker(set, id, name)
    local anim = set[id]
    return anim and anim.markers[name]
end

local function ease(kind, x)
    if kind == "out" then return 1 - (1 - x) * (1 - x) end
    if kind == "in" then return x * x end
    if kind == "inout" then return x < 0.5 and 2 * x * x or 1 - (-2 * x + 2) ^ 2 / 2 end
    return x
end

local function expand(v)
    return {v[1] or 0, v[2] or 0, v[3] or 0, v[4] or 0, v[5] or 0, v[6] or 0}
end

-- Returns {joint = {rx, ry, rz, px, py, pz}} for every joint named in any keyframe.
-- A joint missing from a keyframe holds neutral (zero) at that keyframe.
function AnimData.sample(anim, t)
    local frames = anim.keyframes
    if anim.loop then t = t % anim.duration end
    t = math.clamp(t, 0, anim.duration)
    local a, b = frames[1], frames[#frames]
    if t <= a.t then b = a
    elseif t >= b.t then a = b
    else
        for i = 1, #frames - 1 do
            if t >= frames[i].t and t <= frames[i + 1].t then a, b = frames[i], frames[i + 1]; break end
        end
    end
    local x = b.t > a.t and ease(b.easing, (t - a.t) / (b.t - a.t)) or 1
    local result = {}
    for _, joint in ipairs(anim.joints) do
        local va, vb = expand(a.pose[joint] or {}), expand(b.pose[joint] or {})
        local out = table.create(6)
        for i = 1, 6 do out[i] = va[i] + (vb[i] - va[i]) * x end
        result[joint] = out
    end
    return result
end

-- Fills anim.joints (union of joints in its keyframes, in AnimData.JOINTS order). Call once per set.
function AnimData.prepare(set)
    for id, anim in pairs(set) do
        anim.id = id
        local used = {}
        for _, k in ipairs(anim.keyframes) do
            for joint in pairs(k.pose) do used[joint] = true end
        end
        anim.joints = {}
        for _, joint in ipairs(AnimData.JOINTS) do
            if used[joint] then table.insert(anim.joints, joint) end
        end
    end
    return set
end

return AnimData
