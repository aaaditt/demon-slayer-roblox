-- Loads Animation Editor KeyframeSequences from ReplicatedStorage.Animations and samples them offline.
-- Semantics follow Roblox: each part's poses form a track, and a pose's easing governs the segment that
-- starts at it. Weight-0 poses are structural hierarchy only and are not keyed.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local MotionMath = require(Shared.MotionMath)
local AnimationIndex = require(Shared.AnimationIndex)

local Motion = {}
local cache = {}

local function find(name)
    local node = ReplicatedStorage:FindFirstChild("Animations")
    for segment in string.gmatch(name, "[^/]+") do
        node = node and node:FindFirstChild(segment)
    end
    return node and node:IsA("KeyframeSequence") and node or nil
end

-- Converts a KeyframeSequence into per-part tracks plus sorted markers.
function Motion.parse(name, sequence)
    local keyframes = sequence:GetKeyframes()
    table.sort(keyframes, function(a, b) return a.Time < b.Time end)
    local tracks, markers, parts = {}, {}, {}
    for _, keyframe in ipairs(keyframes) do
        for _, pose in ipairs(keyframe:GetDescendants()) do
            if pose:IsA("Pose") and pose.Weight > 0 then
                local track = tracks[pose.Name]
                if not track then
                    track = {times = {}, frames = {}, styles = {}, directions = {}}
                    tracks[pose.Name] = track; parts[pose.Name] = true
                end
                table.insert(track.times, keyframe.Time)
                table.insert(track.frames, pose.CFrame)
                table.insert(track.styles, pose.EasingStyle.Name)
                table.insert(track.directions, pose.EasingDirection.Name)
            end
        end
        for _, marker in ipairs(keyframe:GetMarkers()) do
            table.insert(markers, {t = keyframe.Time, name = marker.Name, value = marker.Value})
        end
    end
    local markerAt = {}
    for _, marker in ipairs(markers) do markerAt[marker.name] = markerAt[marker.name] or marker.t end
    local length = #keyframes > 0 and keyframes[#keyframes].Time or 0
    local entry = AnimationIndex[name] or {category = "action", loop = sequence.Loop, length = length, speed = 0}
    return {name = name, entry = entry, tracks = tracks, parts = parts, markers = markers, markerAt = markerAt, length = length}
end

-- Parsed clip, or nil when no KeyframeSequence exists yet (callers fall back to procedural poses).
function Motion.clip(name)
    if cache[name] == nil then
        local sequence = find(name)
        cache[name] = sequence and Motion.parse(name, sequence) or false
    end
    return cache[name] or nil
end

-- Writes the sampled Transform of every keyed part into `out[partName]`.
function Motion.sample(clip, t, out)
    for part, track in pairs(clip.tracks) do
        local i, alpha = MotionMath.bracket(track.times, t)
        local frame = track.frames[i]
        if alpha > 0 then
            frame = frame:Lerp(track.frames[i+1], MotionMath.ease(track.styles[i], track.directions[i], alpha))
        end
        out[part] = frame
    end
    return out
end

-- Calls `handler(marker)` for every marker crossed moving from `from` to `to` (loops wrap once).
function Motion.markers(clip, from, to, handler)
    if to < from and clip.entry.loop then
        Motion.markers(clip, from, clip.length+1e-6, handler)
        from = -1e-6
    end
    for _, marker in ipairs(clip.markers) do
        if marker.t > from and marker.t <= to then handler(marker) end
    end
end

return Motion
