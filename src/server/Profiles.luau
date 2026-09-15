local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local Rules = require(Shared.Rules)
local Content = require(Shared.Content)
local Profiles = {}
Profiles.__index = Profiles

function Profiles.new()
    local offline = RunService:IsStudio() and not Config.StudioPersistence
    return setmetatable({store = not offline and DataStoreService:GetDataStore(Config.DataStoreName) or nil, sessions = {}, offline = offline}, Profiles)
end

function Profiles:load(player)
    local session = {token = HttpService:GenerateGUID(false), key = "player_" .. player.UserId, data = Rules.profile(nil, Content), writable = false, status = "Session only", saving = false, closing = false}
    self.sessions[player] = session
    if self.offline then return session end
    for attempt = 1, 3 do
        local ok, record = pcall(function()
            return self.store:UpdateAsync(session.key, function(existing)
                return Rules.claimLease(existing, session.token, os.time(), Config.LeaseSeconds)
            end)
        end)
        if ok and record and record.lease and record.lease.token == session.token then
            session.data = Rules.profile(record.data, Content)
            session.writable = true; session.status = "Saved progression"
            return session
        end
        if ok then session.status = "Another session owns your save; progress here is temporary"; return session end
        task.wait(attempt)
    end
    session.status = "Save service unavailable; progress here is temporary"
    return session
end

function Profiles:save(player, release)
    local session = self.sessions[player]
    if not session then return end
    if release then session.closing = true end
    if session.saving then
        if not release then return end
        local deadline = os.clock()+12
        repeat task.wait(0.1) until not session.saving or os.clock()>deadline
        if session.saving then return end
    end
    if session.writable then
        session.saving = true
        local snapshot = Rules.profile(session.data, Content)
        local ok, result = pcall(function()
            return self.store:UpdateAsync(session.key, function(record)
                return Rules.saveLease(record, session.token, os.time(), Config.LeaseSeconds, snapshot, release)
            end)
        end)
        session.saving = false
        if not ok then session.status = "Save delayed; retrying at the next checkpoint"
        elseif not result then session.writable = false; session.status = "Save ownership changed; progress here is temporary"
        else session.status = "Saved progression" end
    end
    if release then self.sessions[player] = nil end
end

return Profiles
