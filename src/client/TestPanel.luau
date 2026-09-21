-- Studio-only combat readout: live animation, combo, cooldowns, last hit and target health,
-- plus test hotkeys. Never created in a published client (RunService:IsStudio() gate).
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local TestPanel = {}
TestPanel.__index = TestPanel

local ROWS = {"rig", "anim", "combo", "resource", "dash", "hit", "target"}
local KEYS = {
    {code = Enum.KeyCode.F1, kind = "sword", title = "Next sword"},
    {code = Enum.KeyCode.F2, kind = "heal", title = "Heal + clear cooldowns"},
    {code = Enum.KeyCode.F3, kind = "spar", title = "Pause/engage sparring"},
    {code = Enum.KeyCode.F4, kind = "teleport", title = "Go to training range"},
}

local function text(parent, order, color)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -16, 0, 16); label.Position = UDim2.new(0, 8, 0, 4 + order * 17)
    label.BackgroundTransparency = 1; label.Font = Enum.Font.Code; label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left; label.TextColor3 = color or Color3.fromRGB(226, 222, 210)
    label.Text = ""; label.Parent = parent
    return label
end

function TestPanel.new(send)
    if not RunService:IsStudio() then return nil end
    local self = setmetatable({send = send, state = nil, lastHit = nil, rows = {}, actors = workspace:WaitForChild("Actors")}, TestPanel)
    local gui = Instance.new("ScreenGui")
    gui.Name = "WisteriaTestPanel"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true
    gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    local frame = Instance.new("Frame")
    frame.Size = UDim2.fromOffset(330, 4 + 17 * (#ROWS + 2) + 8); frame.Position = UDim2.fromOffset(12, 96)
    frame.BackgroundColor3 = Color3.fromRGB(14, 14, 20); frame.BackgroundTransparency = 0.25
    frame.BorderSizePixel = 0; frame.Parent = gui
    local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 6); corner.Parent = frame
    local title = text(frame, 0, Color3.fromRGB(246, 206, 128))
    title.Font = Enum.Font.GothamBold; title.Text = "COMBAT TEST  ·  Studio only"
    for index, key in ipairs(ROWS) do self.rows[key] = text(frame, index) end
    local hint = text(frame, #ROWS + 1, Color3.fromRGB(160, 172, 190))
    hint.Text = "F1 sword · F2 heal · F3 spar · F4 range · LMB combo · F block · Q+WASD dash"
    for _, key in ipairs(KEYS) do
        ContextActionService:BindAction("WisteriaTest" .. key.kind, function(_, inputState)
            if inputState == Enum.UserInputState.Begin and not UserInputService:GetFocusedTextBox() then
                send("Range", {kind = key.kind})
                return Enum.ContextActionResult.Sink
            end
            return Enum.ContextActionResult.Pass
        end, false, key.code)
    end
    RunService.RenderStepped:Connect(function() self:refresh() end)
    return self
end

function TestPanel:update(state)
    if state.kind == "state" then self.state = state end
end

function TestPanel:onEffect(event)
    local character = Players.LocalPlayer.Character
    if event.kind ~= "hit" or not character then return end
    if event.attacker == character then
        self.lastHit = string.format("dealt %d  %s%s", event.amount or 0, event.result or "?", event.finisher and "  FINISHER" or "")
    elseif event.actor == character then
        self.lastHit = string.format("took %d  %s%s", event.amount or 0, event.result or "?", event.finisher and "  FINISHER" or "")
    end
end

local function seconds(cooldowns, key, now)
    local ready = cooldowns and cooldowns[key]
    if not ready then return "-" end
    local left = ready - now
    return left > 0 and string.format("%.1fs", left) or "ok"
end

function TestPanel:refresh()
    local character = Players.LocalPlayer.Character
    local rows = self.rows
    if not character then rows.rig.Text = "waiting for character"; return end
    local now = workspace:GetServerTimeNow()
    local rig = character:GetAttribute("RigKind") or "R6"
    local sword = character:GetAttribute("SwordVariant") or "-"
    local drawn = character:GetAttribute("WeaponDrawn") and "drawn" or "sheathed"
    rows.rig.Text = string.format("rig %s   sword %s   %s", rig, sword, drawn)
    local anim = character:GetAttribute("Anim")
    local started = character:GetAttribute("AnimStart") or 0
    rows.anim.Text = (anim and anim ~= "") and string.format("anim %-13s %.2fs ago", anim, now - started) or "anim -"
    local step = anim and string.match(tostring(anim), "^m1_(%d)")
    rows.combo.Text = string.format("combo %s   blocking %s", step or "-", tostring(character:GetAttribute("Blocking") == true))
    local state = self.state
    if state then
        rows.resource.Text = string.format("hp %d/%d   energy %d/%d", math.floor(state.hp or 0), state.maxHp or 0, math.floor(state.energy or 0), state.maxEnergy or 0)
        rows.dash.Text = string.format("dash  front %s  back %s  left %s  right %s", seconds(state.cooldowns, "dash_front", now),
            seconds(state.cooldowns, "dash_back", now), seconds(state.cooldowns, "dash_left", now), seconds(state.cooldowns, "dash_right", now))
    end
    rows.hit.Text = "last hit  " .. (self.lastHit or "-")
    local root = character:FindFirstChild("HumanoidRootPart")
    local best, bestDistance
    for _, model in ipairs(self.actors:GetChildren()) do
        local role = model:GetAttribute("RangeRole")
        local part = root and model ~= character and model:FindFirstChild("HumanoidRootPart")
        if role and part then
            local distance = (part.Position - root.Position).Magnitude
            if not bestDistance or distance < bestDistance then best, bestDistance = model, distance end
        end
    end
    local humanoid = best and best:FindFirstChildOfClass("Humanoid")
    rows.target.Text = humanoid and string.format("target %s  %d/%d hp  %.0f studs", best:GetAttribute("RangeRole"), humanoid.Health, humanoid.MaxHealth, bestDistance)
        or "target  none nearby (F4 to reach the range)"
end

return TestPanel
