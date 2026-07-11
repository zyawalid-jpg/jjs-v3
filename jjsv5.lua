-- JJS Hub V5 - Professional Edition
-- Auto-discovers game systems at runtime
-- No hardcoded names - everything is detected dynamically

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- ═══════════════════════════════════════════════════════════════
-- RUNTIME DISCOVERY SYSTEM
-- ═══════════════════════════════════════════════════════════════

local Discovered = {
    Remotes = {},
    Animations = {},
    Keybinds = {},
    CharacterTools = {},
    CombatRemotes = {},
    BlockRemote = nil,
    AttackRemote = nil,
    DashRemote = nil,
    DamageRemote = nil,
}

-- Monitor all remote traffic to discover combat remotes
local function MonitorRemotes()
    local mt = getrawmetatable and getrawmetatable(game)
    if not mt then return end

    setreadonly(mt, false)
    local oldNamecall = mt.__namecall

    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if method == "FireServer" or method == "InvokeServer" then
            if self:IsA("RemoteEvent") or self:IsA("RemoteFunction") then
                local name = self.Name:lower()
                local args = {...}

                -- Log remote usage for discovery
                if not Discovered.Remotes[name] then
                    Discovered.Remotes[name] = {Count = 0, Args = {}}
                end
                Discovered.Remotes[name].Count = Discovered.Remotes[name].Count + 1

                -- Detect combat remotes by argument patterns
                if #args > 0 then
                    local argStr = tostring(args[1])
                    if argStr:find("attack") or argStr:find("damage") or argStr:find("hit") 
                       or argStr:find("target") or argStr:find("position") then
                        Discovered.CombatRemotes[name] = self
                    end
                    if argStr:find("block") or argStr:find("guard") or argStr:find("defend") then
                        Discovered.BlockRemote = self
                    end
                end

                -- Detect by name patterns
                if name:find("attack") or name:find("m1") or name:find("punch") or name:find("combat") then
                    Discovered.AttackRemote = self
                    Discovered.CombatRemotes[name] = self
                end
                if name:find("block") or name:find("guard") or name:find("defend") then
                    Discovered.BlockRemote = self
                end
                if name:find("dash") or name:find("dodge") then
                    Discovered.DashRemote = self
                end
                if name:find("damage") or name:find("hit") then
                    Discovered.DamageRemote = self
                end
            end
        end
        return oldNamecall(self, ...)
    end)

    setreadonly(mt, true)
end

-- Scan LocalScripts for remote references
local function ScanLocalScripts()
    for _, script in pairs(LocalPlayer.PlayerScripts:GetDescendants()) do
        if script:IsA("LocalScript") or script:IsA("ModuleScript") then
            pcall(function()
                local src = script.Source
                if src then
                    -- Find remote references in source
                    for remoteName in src:gmatch('["']([%w_]+)["']%s*:') do
                        local r = ReplicatedStorage:FindFirstChild(remoteName)
                        if r and (r:IsA("RemoteEvent") or r:IsA("RemoteFunction")) then
                            Discovered.Remotes[remoteName:lower()] = {Remote = r, Source = script.Name}
                        end
                    end
                end
            end)
        end
    end
end

-- Monitor animations to discover combat anims
local function MonitorAnimations()
    local function onCharAdded(char)
        local hum = char:WaitForChild("Humanoid", 5)
        if not hum then return end

        hum.AnimationPlayed:Connect(function(track)
            local animId = track.Animation and track.Animation.AnimationId or "unknown"
            local name = track.Name:lower()

            if not Discovered.Animations[name] then
                Discovered.Animations[name] = {Id = animId, Count = 0}
            end
            Discovered.Animations[name].Count = Discovered.Animations[name].Count + 1
        end)
    end

    if LocalPlayer.Character then
        onCharAdded(LocalPlayer.Character)
    end
    LocalPlayer.CharacterAdded:Connect(onCharAdded)
end

-- Auto-discover keybinds by monitoring input during combat
local function DiscoverKeybinds()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        local key = input.KeyCode.Name
        if key == "Unknown" then return end

        -- Track key presses near enemies to discover combat keys
        local hrp = GetHRP()
        if hrp then
            for _, p in pairs(Players:GetPlayers()) do
                if p == LocalPlayer then continue end
                local c = p.Character
                if not c then continue end
                local h = c:FindFirstChild("HumanoidRootPart")
                if h and (hrp.Position - h.Position).Magnitude < 15 then
                    if not Discovered.Keybinds[key] then
                        Discovered.Keybinds[key] = {Uses = 0, NearEnemy = 0}
                    end
                    Discovered.Keybinds[key].NearEnemy = Discovered.Keybinds[key].NearEnemy + 1
                end
            end
        end
    end)
end

-- Get current character tools
local function ScanTools()
    local char = LocalPlayer.Character
    if not char then return end
    Discovered.CharacterTools = {}
    for _, obj in pairs(char:GetDescendants()) do
        if obj:IsA("Tool") then
            table.insert(Discovered.CharacterTools, obj.Name)
        end
    end
end

-- Initialize discovery
pcall(MonitorRemotes)
pcall(ScanLocalScripts)
pcall(MonitorAnimations)
pcall(DiscoverKeybinds)

-- ═══════════════════════════════════════════════════════════════
-- UTILITY
-- ═══════════════════════════════════════════════════════════════

local function GetChar() return LocalPlayer.Character end
local function GetHRP()
    local c = GetChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function GetHum()
    local c = GetChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function GetNearest(range)
    local hrp = GetHRP()
    if not hrp then return nil end
    local best = nil
    local bestDist = range
    for _, p in pairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        local c = p.Character
        if not c then continue end
        local h = c:FindFirstChild("HumanoidRootPart")
        if not h then continue end
        local d = (hrp.Position - h.Position).Magnitude
        if d < bestDist then
            bestDist = d
            best = {Player = p, HRP = h, Hum = c:FindFirstChildOfClass("Humanoid")}
        end
    end
    return best
end

local function GetAllInRange(range)
    local hrp = GetHRP()
    if not hrp then return {} end
    local t = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        local c = p.Character
        if not c then continue end
        local h = c:FindFirstChild("HumanoidRootPart")
        if not h then continue end
        local d = (hrp.Position - h.Position).Magnitude
        if d <= range then
            table.insert(t, {Player = p, HRP = h, Hum = c:FindFirstChildOfClass("Humanoid"), Dist = d})
        end
    end
    return t
end

local function Face(pos)
    local hrp = GetHRP()
    if hrp then
        hrp.CFrame = CFrame.new(hrp.Position, Vector3.new(pos.X, hrp.Position.Y, pos.Z))
    end
end

local function Press(key, dur)
    dur = dur or 0.05
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:SetKeyDown(key)
        task.wait(dur)
        VirtualUser:SetKeyUp(key)
    end)
end

local function Click()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:Button1Down(Vector2.new())
        task.wait(0.05)
        VirtualUser:Button1Up(Vector2.new())
    end)
end

local function FireRemote(remote, ...)
    if not remote then return end
    pcall(function()
        if remote:IsA("RemoteEvent") then
            remote:FireServer(...)
        elseif remote:IsA("RemoteFunction") then
            remote:InvokeServer(...)
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- CONFIG
-- ═══════════════════════════════════════════════════════════════

local Config = {
    AutoBlock = false,
    AutoParry = false,
    AutoCounter = false,
    AutoCombo = false,
    AutoSkills = false,
    AutoDomain = false,
    AutoDodge = false,
    AutoBlackFlash = false,
    AutoBFChain = false,
    AntiRagdoll = false,
    InfCE = false,
    NoCooldown = false,
    SpeedHack = false,
    WalkSpeed = 16,
    JumpPower = 50,
    Fly = false,
    Noclip = false,
    ESP = false,
    Hitbox = false,
    AntiAFK = false,
    DebugMode = false,
    BlockKey = "F",
    DashKey = "Q",
    SkillKeys = {"Z","X","C","V"},
}

-- ═══════════════════════════════════════════════════════════════
-- GUI
-- ═══════════════════════════════════════════════════════════════

local SG2 = Instance.new("ScreenGui")
SG2.Name = "JJSV5"
SG2.Parent = game.CoreGui
SG2.ResetOnSpawn = false

local MF2 = Instance.new("Frame")
MF2.Parent = SG2
MF2.BackgroundColor3 = Color3.fromRGB(8, 8, 16)
MF2.BorderSizePixel = 0
MF2.Position = UDim2.new(0.02, 0, 0.08, 0)
MF2.Size = UDim2.new(0, 280, 0, 480)
MF2.Active = true
MF2.Draggable = true

Instance.new("UICorner", MF2).CornerRadius = UDim.new(0, 12)

local US2 = Instance.new("UIStroke")
US2.Parent = MF2
US2.Color = Color3.fromRGB(180, 100, 255)
US2.Thickness = 2

local TB2 = Instance.new("Frame")
TB2.Parent = MF2
TB2.BackgroundColor3 = Color3.fromRGB(180, 100, 255)
TB2.Size = UDim2.new(1, 0, 0, 38)
Instance.new("UICorner", TB2).CornerRadius = UDim.new(0, 12)

local TL2 = Instance.new("TextLabel")
TL2.Parent = TB2
TL2.BackgroundTransparency = 1
TL2.Size = UDim2.new(1, -50, 1, 0)
TL2.Position = UDim2.new(0, 12, 0, 0)
TL2.Font = Enum.Font.GothamBold
TL2.Text = "  JJS Hub V5"
TL2.TextColor3 = Color3.fromRGB(255, 255, 255)
TL2.TextSize = 17
TL2.TextXAlignment = Enum.TextXAlignment.Left

local CB2 = Instance.new("TextButton")
CB2.Parent = TB2
CB2.BackgroundTransparency = 1
CB2.Size = UDim2.new(0, 32, 0, 32)
CB2.Position = UDim2.new(1, -34, 0, 3)
CB2.Font = Enum.Font.GothamBold
CB2.Text = "X"
CB2.TextColor3 = Color3.fromRGB(255, 255, 255)
CB2.TextSize = 18

CB2.MouseButton1Click:Connect(function()
    SG2:Destroy()
    for _, c in pairs(Connections) do
        if c then c:Disconnect() end
    end
end)

local SF2 = Instance.new("ScrollingFrame")
SF2.Parent = MF2
SF2.BackgroundTransparency = 1
SF2.Position = UDim2.new(0, 8, 0, 44)
SF2.Size = UDim2.new(1, -16, 1, -52)
SF2.ScrollBarThickness = 3
SF2.ScrollBarImageColor3 = Color3.fromRGB(180, 100, 255)
SF2.CanvasSize = UDim2.new(0, 0, 0, 800)

local LL2 = Instance.new("UIListLayout")
LL2.Parent = SF2
LL2.SortOrder = Enum.SortOrder.LayoutOrder
LL2.Padding = UDim.new(0, 5)

local function Sec(text)
    local L = Instance.new("TextLabel")
    L.Parent = SF2
    L.BackgroundTransparency = 1
    L.Size = UDim2.new(1, 0, 0, 20)
    L.Font = Enum.Font.GothamBold
    L.Text = "> " .. text
    L.TextColor3 = Color3.fromRGB(180, 100, 255)
    L.TextSize = 12
    L.TextXAlignment = Enum.TextXAlignment.Left
    return L
end

local function Tog(text, key)
    local F = Instance.new("Frame")
    F.Parent = SF2
    F.BackgroundColor3 = Color3.fromRGB(16, 16, 28)
    F.Size = UDim2.new(1, 0, 0, 32)
    Instance.new("UICorner", F).CornerRadius = UDim.new(0, 5)

    local L = Instance.new("TextLabel")
    L.Parent = F
    L.BackgroundTransparency = 1
    L.Position = UDim2.new(0, 10, 0, 0)
    L.Size = UDim2.new(0.6, 0, 1, 0)
    L.Font = Enum.Font.Gotham
    L.Text = text
    L.TextColor3 = Color3.fromRGB(200, 200, 210)
    L.TextSize = 11
    L.TextXAlignment = Enum.TextXAlignment.Left

    local B = Instance.new("TextButton")
    B.Parent = F
    B.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    B.Position = UDim2.new(1, -46, 0.5, -9)
    B.Size = UDim2.new(0, 40, 0, 18)
    B.AutoButtonColor = false
    B.Text = ""
    Instance.new("UICorner", B).CornerRadius = UDim.new(1, 0)

    local K = Instance.new("Frame")
    K.Parent = B
    K.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    K.Position = UDim2.new(0, 2, 0.5, -6)
    K.Size = UDim2.new(0, 12, 0, 12)
    Instance.new("UICorner", K).CornerRadius = UDim.new(1, 0)

    local on = false
    B.MouseButton1Click:Connect(function()
        on = not on
        Config[key] = on
        if on then
            TweenService:Create(B, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(180, 100, 255)}):Play()
            TweenService:Create(K, TweenInfo.new(0.15), {Position = UDim2.new(0, 26, 0.5, -6)}):Play()
        else
            TweenService:Create(B, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(50, 50, 65)}):Play()
            TweenService:Create(K, TweenInfo.new(0.15), {Position = UDim2.new(0, 2, 0.5, -6)}):Play()
        end
    end)
end

local function Sli(text, key, min, max, def)
    local F = Instance.new("Frame")
    F.Parent = SF2
    F.BackgroundColor3 = Color3.fromRGB(16, 16, 28)
    F.Size = UDim2.new(1, 0, 0, 48)
    Instance.new("UICorner", F).CornerRadius = UDim.new(0, 5)

    local L = Instance.new("TextLabel")
    L.Parent = F
    L.BackgroundTransparency = 1
    L.Position = UDim2.new(0, 10, 0, 3)
    L.Size = UDim2.new(1, -20, 0, 16)
    L.Font = Enum.Font.Gotham
    L.Text = text .. ": " .. def
    L.TextColor3 = Color3.fromRGB(200, 200, 210)
    L.TextSize = 11
    L.TextXAlignment = Enum.TextXAlignment.Left

    local T = Instance.new("Frame")
    T.Parent = F
    T.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    T.Position = UDim2.new(0, 10, 0, 28)
    T.Size = UDim2.new(1, -20, 0, 5)
    Instance.new("UICorner", T).CornerRadius = UDim.new(1, 0)

    local Fi = Instance.new("Frame")
    Fi.Parent = T
    Fi.BackgroundColor3 = Color3.fromRGB(180, 100, 255)
    Fi.Size = UDim2.new((def - min) / (max - min), 0, 1, 0)
    Instance.new("UICorner", Fi).CornerRadius = UDim.new(1, 0)

    local drag = false
    local function upd(inp)
        local pos = math.clamp((inp.Position.X - T.AbsolutePosition.X) / T.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + (pos * (max - min)))
        Config[key] = val
        Fi.Size = UDim2.new(pos, 0, 1, 0)
        L.Text = text .. ": " .. val
    end

    T.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            drag = true
            upd(inp)
        end
    end)
    T.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if drag and inp.UserInputType == Enum.UserInputType.MouseMovement then upd(inp) end
    end)
end

Sec("COMBAT")
Tog("Auto Block", "AutoBlock")
Tog("Auto Parry", "AutoParry")
Tog("Auto Counter", "AutoCounter")
Tog("Auto Combo", "AutoCombo")
Tog("Auto Skills", "AutoSkills")
Tog("Auto Domain", "AutoDomain")
Tog("Auto Black Flash", "AutoBlackFlash")
Tog("Auto BF Chain", "AutoBFChain")

Sec("DEFENSE")
Tog("Auto Dodge", "AutoDodge")
Tog("Anti Ragdoll", "AntiRagdoll")
Tog("Inf CE", "InfCE")
Tog("No Cooldown", "NoCooldown")

Sec("MOVEMENT")
Tog("Speed Hack", "SpeedHack")
Sli("Walk Speed", "WalkSpeed", 16, 200, 16)
Sli("Jump Power", "JumpPower", 50, 300, 50)
Tog("Fly", "Fly")
Tog("Noclip", "Noclip")

Sec("VISUAL")
Tog("ESP", "ESP")
Tog("Hitbox", "Hitbox")

Sec("MISC")
Tog("Anti AFK", "AntiAFK")
Tog("Side Dash + BF (E)", "SideDashBF")

Tog("Debug Mode", "DebugMode")

-- ═══════════════════════════════════════════════════════════════
-- CORE FEATURES
-- ═══════════════════════════════════════════════════════════════

local Connections = {}
local ESPObjects = {}
local HitboxObjects = {}
local BlockState = {isBlocking = false}
local BFState = {chain = 0, lastHit = 0}

-- Debug print
local function Debug(msg)
    if Config.DebugMode then
        print("[JJS V5] " .. msg)
    end
end

-- Auto Block - uses discovered block remote or key
local blockConn = RunService.Heartbeat:Connect(function()
    if not Config.AutoBlock then
        if BlockState.isBlocking then
            BlockState.isBlocking = false
            if Discovered.BlockRemote then
                FireRemote(Discovered.BlockRemote, false)
            else
                pcall(function() VirtualUser:SetKeyUp(Config.BlockKey) end)
            end
        end
        return
    end

    local hrp = GetHRP()
    if not hrp then return end

    local shouldBlock = false
    local targets = GetAllInRange(12)

    for _, t in pairs(targets) do
        local hum = t.Hum
        if hum then
            for _, track in pairs(hum:GetPlayingAnimationTracks()) do
                local n = track.Name:lower()
                if n:find("attack") or n:find("punch") or n:find("swing") or n:find("slash") or n:find("m1") then
                    shouldBlock = true
                    Debug("Enemy attacking: " .. track.Name)
                    break
                end
            end
        end

        local vel = t.HRP.Velocity.Magnitude
        if vel > 30 then
            shouldBlock = true
            Debug("Enemy rushing: " .. tostring(vel))
        end

        local toUs = (hrp.Position - t.HRP.Position).Unit
        local look = t.HRP.CFrame.LookVector
        if toUs:Dot(look) > 0.6 then
            shouldBlock = true
            Debug("Enemy facing us")
        end
    end

    if shouldBlock and not BlockState.isBlocking then
        BlockState.isBlocking = true
        Debug("Blocking...")
        if Discovered.BlockRemote then
            FireRemote(Discovered.BlockRemote, true)
        else
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:SetKeyDown(Config.BlockKey)
            end)
        end
    elseif not shouldBlock and BlockState.isBlocking then
        BlockState.isBlocking = false
        Debug("Stop blocking")
        if Discovered.BlockRemote then
            FireRemote(Discovered.BlockRemote, false)
        else
            pcall(function() VirtualUser:SetKeyUp(Config.BlockKey) end)
        end
    end
end)
table.insert(Connections, blockConn)

-- Auto Parry
local parryConn = RunService.Heartbeat:Connect(function()
    if not Config.AutoParry then return end
    local target = GetNearest(15)
    if not target then return end
    if not target.Hum then return end

    for _, track in pairs(target.Hum:GetPlayingAnimationTracks()) do
        local n = track.Name:lower()
        if n:find("attack") or n:find("punch") or n:find("m1") or n:find("swing") then
            if track.TimePosition > 0.05 and track.TimePosition < 0.35 then
                Debug("Parry timing: " .. tostring(track.TimePosition))
                Face(target.HRP.Position)

                if Discovered.BlockRemote then
                    FireRemote(Discovered.BlockRemote, "Parry")
                else
                    Press(Config.BlockKey)
                end

                task.wait(0.1)
                if Config.AutoCounter then
                    Click()
                    task.wait(0.08)
                    Press("Z")
                end
            end
        end
    end
end)
table.insert(Connections, parryConn)

-- Auto Black Flash
local bfConn = RunService.Heartbeat:Connect(function()
    if not Config.AutoBlackFlash then return end
    local target = GetNearest(8)
    if not target then return end

    Face(target.HRP.Position)

    -- Try via remote first
    if Discovered.AttackRemote then
        FireRemote(Discovered.AttackRemote, "BlackFlash")
    end

    -- Fallback to key simulation
    Click()
    task.wait(0.08)
    Press("R")
    task.wait(0.05)

    if Config.AutoBFChain then
        local now = tick()
        if now - BFState.lastHit < 2 then
            BFState.chain = BFState.chain + 1
            if BFState.chain >= 3 then
                Debug("BF Chain! Count: " .. tostring(BFState.chain))
                Press("R")
                task.wait(0.03)
                Press("R")
                BFState.chain = 0
            end
        else
            BFState.chain = 1
        end
        BFState.lastHit = now
    end
end)
table.insert(Connections, bfConn)

-- Auto Combo
local comboConn = RunService.Heartbeat:Connect(function()
    if not Config.AutoCombo then return end
    local target = GetNearest(6)
    if not target then return end
    Face(target.HRP.Position)

    if Discovered.AttackRemote then
        FireRemote(Discovered.AttackRemote, "M1")
    else
        Click()
    end
    task.wait(0.12)
end)
table.insert(Connections, comboConn)

-- Auto Skills
local skillIdx = 1
local skillConn = RunService.Heartbeat:Connect(function()
    if not Config.AutoSkills then return end
    local target = GetNearest(25)
    if not target then return end
    Face(target.HRP.Position)

    local key = Config.SkillKeys[skillIdx]
    Press(key)
    skillIdx = skillIdx % #Config.SkillKeys + 1
    task.wait(0.3)
end)
table.insert(Connections, skillConn)

-- Auto Domain
local domainConn = RunService.Heartbeat:Connect(function()
    if not Config.AutoDomain then return end
    local targets = GetAllInRange(25)
    if #targets < 1 then return end

    local char = GetChar()
    if not char then return end

    for _, v in pairs(char:GetDescendants()) do
        if v:IsA("NumberValue") or v:IsA("IntValue") then
            if v.Name:lower():find("awaken") or v.Name:lower():find("domain") then
                if v.Value >= (v.MaxValue or 100) * 0.85 then
                    Debug("Domain ready! Activating...")
                    Press("G")
                    task.wait(4)
                    return
                end
            end
        end
    end
end)
table.insert(Connections, domainConn)

-- Auto Dodge
local dodgeConn = RunService.Heartbeat:Connect(function()
    if not Config.AutoDodge then return end
    local hrp = GetHRP()
    if not hrp then return end

    local targets = GetAllInRange(8)
    for _, t in pairs(targets) do
        local hum = t.Hum
        if hum then
            for _, track in pairs(hum:GetPlayingAnimationTracks()) do
                local n = track.Name:lower()
                if n:find("attack") or n:find("punch") then
                    if track.TimePosition < 0.2 then
                        Debug("Dodging attack from " .. t.Player.Name)
                        local dir = (hrp.Position - t.HRP.Position).Unit * 12
                        hrp.CFrame = CFrame.new(hrp.Position + dir)
                        Press(Config.DashKey)
                        task.wait(0.15)
                    end
                end
            end
        end
    end
end)
table.insert(Connections, dodgeConn)

-- Anti Ragdoll
local ragdollConn = RunService.Heartbeat:Connect(function()
    if not Config.AntiRagdoll then return end
    local hum = GetHum()
    if not hum then return end

    if hum.PlatformStand then
        hum.PlatformStand = false
        hum.Sit = false
    end

    local s = hum:GetState()
    if s == Enum.HumanoidStateType.Physics or s == Enum.HumanoidStateType.FallingDown or s == Enum.HumanoidStateType.Ragdoll then
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
    end

    local char = GetChar()
    if char then
        for _, p in pairs(char:GetDescendants()) do
            if p:IsA("BasePart") then
                p.AssemblyLinearVelocity = Vector3.new(0, math.max(0, p.AssemblyLinearVelocity.Y), 0)
                p.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            end
        end
    end
end)
table.insert(Connections, ragdollConn)

-- Inf CE
local ceConn = RunService.Heartbeat:Connect(function()
    if not Config.InfCE then return end
    local char = GetChar()
    if not char then return end

    for _, v in pairs(char:GetDescendants()) do
        if v:IsA("NumberValue") or v:IsA("IntValue") then
            local n = v.Name:lower()
            if n:find("energy") or n:find("ce") or n:find("cursed") or n:find("power") then
                v.Value = v.MaxValue or 999999
            end
        end
    end
end)
table.insert(Connections, ceConn)

-- No Cooldown
local cdConn = RunService.Heartbeat:Connect(function()
    if not Config.NoCooldown then return end
    local char = GetChar()
    if not char then return end

    for _, v in pairs(char:GetDescendants()) do
        if v:IsA("NumberValue") or v:IsA("IntValue") then
            local n = v.Name:lower()
            if n:find("cooldown") or n:find("cd") or n:find("timer") then
                v.Value = 0
            end
        end
    end
end)
table.insert(Connections, cdConn)

-- Speed
local speedConn = RunService.Heartbeat:Connect(function()
    local hum = GetHum()
    if not hum then return end
    hum.WalkSpeed = Config.SpeedHack and Config.WalkSpeed * 1.5 or Config.WalkSpeed
    hum.JumpPower = Config.JumpPower
end)
table.insert(Connections, speedConn)

-- Fly
local flyConn
local flyToggle = RunService.Heartbeat:Connect(function()
    if not Config.Fly then
        if flyConn then flyConn:Disconnect() flyConn = nil end
        return
    end

    local char = GetChar()
    if not char then return end
    local hrp = GetHRP()
    if not hrp then return end
    local hum = GetHum()
    if not hum then return end

    if not flyConn then
        hum.PlatformStand = true
        local bg = Instance.new("BodyGyro")
        bg.Name = "JJSFlyG"
        bg.Parent = hrp
        bg.MaxTorque = Vector3.new(400000, 400000, 400000)
        bg.P = 10000

        local bv = Instance.new("BodyVelocity")
        bv.Name = "JJSFlyV"
        bv.Parent = hrp
        bv.MaxForce = Vector3.new(400000, 400000, 400000)
        bv.Velocity = Vector3.new(0, 0, 0)

        flyConn = RunService.RenderStepped:Connect(function()
            if not Config.Fly then return end
            local cam = Camera
            local dir = Vector3.new(0, 0, 0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0, 1, 0) end
            if dir.Magnitude > 0 then dir = dir.Unit * 50 end
            bv.Velocity = dir
            bg.CFrame = cam.CFrame
        end)
    end
end)
table.insert(Connections, flyToggle)

-- Noclip
local noclipConn
local noclipToggle = RunService.Heartbeat:Connect(function()
    if not Config.Noclip then
        if noclipConn then noclipConn:Disconnect() noclipConn = nil end
        return
    end
    if not noclipConn then
        noclipConn = RunService.Stepped:Connect(function()
            if not Config.Noclip then return end
            local char = GetChar()
            if not char then return end
            for _, p in pairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end)
    end
end)
table.insert(Connections, noclipToggle)

-- ESP
local espConn = RunService.RenderStepped:Connect(function()
    if not Config.ESP then
        for p, objs in pairs(ESPObjects) do
            for _, obj in pairs(objs) do
                if typeof(obj) == "Instance" then obj:Destroy()
                elseif typeof(obj) == "table" and obj.Remove then obj:Remove() end
            end
        end
        ESPObjects = {}
        return
    end

    for _, p in pairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        local c = p.Character
        if not c then
            if ESPObjects[p] then
                for _, obj in pairs(ESPObjects[p]) do
                    if typeof(obj) == "Instance" then obj:Destroy()
                    elseif typeof(obj) == "table" and obj.Remove then obj:Remove() end
                end
                ESPObjects[p] = nil
            end
            continue
        end

        local h = c:FindFirstChild("HumanoidRootPart")
        if not h then continue end

        local d = (Camera.CFrame.Position - h.Position).Magnitude
        if d > 500 then
            if ESPObjects[p] then
                for _, obj in pairs(ESPObjects[p]) do
                    if typeof(obj) == "Instance" then obj:Destroy()
                    elseif typeof(obj) == "table" and obj.Remove then obj:Remove() end
                end
                ESPObjects[p] = nil
            end
            continue
        end

        if not ESPObjects[p] then
            ESPObjects[p] = {}
            local hl = Instance.new("Highlight")
            hl.Name = "JJS_ESP"
            hl.Parent = c
            hl.FillColor = Color3.fromRGB(255, 0, 0)
            hl.OutlineColor = Color3.fromRGB(255, 255, 255)
            hl.FillTransparency = 0.7
            hl.OutlineTransparency = 0
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            table.insert(ESPObjects[p], hl)
        end
    end
end)
table.insert(Connections, espConn)

-- Hitbox
local hitboxConn = RunService.Heartbeat:Connect(function()
    if not Config.Hitbox then
        for p, _ in pairs(HitboxObjects) do
            local c = p.Character
            if c then
                local h = c:FindFirstChild("HumanoidRootPart")
                if h then
                    h.Size = Vector3.new(2, 2, 1)
                    h.Transparency = 1
                end
            end
        end
        HitboxObjects = {}
        return
    end

    for _, p in pairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        local c = p.Character
        if not c then continue end
        local h = c:FindFirstChild("HumanoidRootPart")
        if not h then continue end
        h.Size = Vector3.new(10, 10, 10)
        h.Transparency = 0.7
        h.CanCollide = false
        HitboxObjects[p] = true
    end
end)
table.insert(Connections, hitboxConn)

-- Anti AFK
local afkConn = LocalPlayer.Idled:Connect(function()
    if Config.AntiAFK then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)
table.insert(Connections, afkConn)

-- Side Dash + Black Flash (E keybind)
local sideDashConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode ~= Enum.KeyCode.E then return end
    if not Config.SideDashBF then return end

    local hrp = GetHRP()
    if not hrp then return end

    local target = GetNearest(15)
    local dashDir

    if Config.SideDashDirection == "Left" then
        dashDir = Camera.CFrame.RightVector * -15
    else
        dashDir = Camera.CFrame.RightVector * 15
    end

    hrp.CFrame = CFrame.new(hrp.Position + dashDir)

    if Discovered.DashRemote then
        FireRemote(Discovered.DashRemote, "Dash", dashDir)
    else
        Press(Config.DashKey)
    end

    Debug("Side dash: " .. Config.SideDashDirection)
    task.wait(0.08)

    if target then
        Face(target.HRP.Position)
    end

    Debug("Black Flash attempt...")

    if Discovered.AttackRemote then
        FireRemote(Discovered.AttackRemote, "BlackFlash")
        FireRemote(Discovered.AttackRemote, "BF")
    end

    for name, remote in pairs(Discovered.CombatRemotes) do
        pcall(function()
            remote:FireServer("BlackFlash")
            remote:FireServer("BF")
        end)
    end

    Click()
    task.wait(0.06)
    Press("R")
    task.wait(0.04)
    Press("F")

    if Config.AutoBFChain then
        local now = tick()
        if now - BFState.lastHit < 2 then
            BFState.chain = BFState.chain + 1
            if BFState.chain >= 3 then
                Debug("Side dash BF Chain!")
                Press("R")
                task.wait(0.03)
                Press("R")
                BFState.chain = 0
            end
        else
            BFState.chain = 1
        end
        BFState.lastHit = now
    end
end)
table.insert(Connections, sideDashConn)

-- Full Bright
local fbConn = RunService.Heartbeat:Connect(function()
    if Config.ESP then
        Lighting.Brightness = 8
        Lighting.GlobalShadows = false
    end
end)
table.insert(Connections, fbConn)

-- Debug info display
local debugConn = RunService.Heartbeat:Connect(function()
    if not Config.DebugMode then return end
    if tick() % 5 < 0.1 then
        print("=== JJS V5 DEBUG ===")
        print("Block Remote: " .. (Discovered.BlockRemote and Discovered.BlockRemote.Name or "NOT FOUND"))
        print("Attack Remote: " .. (Discovered.AttackRemote and Discovered.AttackRemote.Name or "NOT FOUND"))
        print("Dash Remote: " .. (Discovered.DashRemote and Discovered.DashRemote.Name or "NOT FOUND"))
        print("Damage Remote: " .. (Discovered.DamageRemote and Discovered.DamageRemote.Name or "NOT FOUND"))
        print("Combat Remotes: " .. tostring(#Discovered.CombatRemotes))
        print("Animations tracked: " .. tostring(#Discovered.Animations))
        print("Keybinds tracked: " .. tostring(#Discovered.Keybinds))
        print("====================")
    end
end)
table.insert(Connections, debugConn)

-- Notification
local N = Instance.new("Frame")
N.Parent = SG2
N.BackgroundColor3 = Color3.fromRGB(8, 8, 16)
N.BorderSizePixel = 0
N.Position = UDim2.new(0.5, -140, 0, -80)
N.Size = UDim2.new(0, 280, 0, 55)
N.AnchorPoint = Vector2.new(0.5, 0)
Instance.new("UICorner", N).CornerRadius = UDim.new(0, 10)

local NS = Instance.new("UIStroke")
NS.Parent = N
NS.Color = Color3.fromRGB(180, 100, 255)
NS.Thickness = 2

local NT = Instance.new("TextLabel")
NT.Parent = N
NT.BackgroundTransparency = 1
NT.Size = UDim2.new(1, 0, 1, 0)
NT.Font = Enum.Font.GothamBold
NT.Text = "JJS Hub V5 Loaded"
NT.TextColor3 = Color3.fromRGB(180, 100, 255)
NT.TextSize = 16

N:TweenPosition(UDim2.new(0.5, -140, 0, 25), Enum.EasingDirection.Out, Enum.EasingStyle.Back, 0.5, true)

task.delay(4, function()
    N:TweenPosition(UDim2.new(0.5, -140, 0, -80), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.4, true)
    task.wait(0.4)
    N:Destroy()
end)

print("[JJS Hub V5] Loaded successfully")
print("[JJS Hub V5] Activate Debug Mode to see discovered remotes")
print("[JJS Hub V5] Features: AutoBlock, AutoParry, AutoBF, AutoCombo, AutoSkills, AutoDomain, AutoDodge, AntiRagdoll, InfCE, NoCD, Speed, Fly, Noclip, ESP, Hitbox")