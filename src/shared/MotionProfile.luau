-- Pure, shared clip selection. The server and every observer resolve the same catalog profile.
-- Profiles only replace presentation; combat damage, admission and attack timing stay on the server.
local MotionProfile = {}

function MotionProfile.new(content, index)
    local resolver = {}
    function resolver.id(characterId)
        local character = content.characters[characterId]
        local id = character and character.motionProfile
        return id and content.motionProfiles[id] and id or "base"
    end
    function resolver.clip(characterId, slot)
        if not slot then return nil end
        local profile = content.motionProfiles[resolver.id(characterId)]
        local override = profile and profile.clips[slot]
        if override and index[override] then return override end
        local fallback = "base/"..slot
        return index[fallback] and fallback or nil
    end
    function resolver.locomotion(characterId, state, drawn)
        -- Preserve specificity before falling back: drawn -> sheathed -> unsuffixed.
        return (drawn and resolver.clip(characterId, state.."_drawn"))
            or resolver.clip(characterId, state.."_sheathed") or resolver.clip(characterId, state)
    end
    function resolver.action(characterId, pose, variant)
        return resolver.clip(characterId, variant) or resolver.clip(characterId, pose)
    end
    return resolver
end

return MotionProfile
