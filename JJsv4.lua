
-- Pure Lua, no decorative text
-- Compatible: Delta, Fluxus, Codex, Krnl

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- Config
local Config = {
    AutoBlackFlash = false,
    AutoBlackFlashChain = false,
    AutoBlock = false,
    AutoParry = false,
    AutoCounter = false,
    AutoCombo = false,
    AutoSkills = false,
    AutoDomain = false,
    AutoDodge = false,
    AntiRagdoll = false,
    InfCE = false,
    NoCooldown = false,
    SpeedHack = false,
    WalkSpeed = 16,
    JumpPower = 50,
    ESP = false,
    Hitbox = false,
    Fly = false,
    Noclip = false,
    AntiAFK = false,
    GojoMode = false,
    AutoGojoSkills = false,
    KillRange = 50,
}

-- State
local Connections = {}
local ESPObjects = {}
local HitboxObjects = {}
local BlockState = {isBlocking = false}
local BFState = {chain = 0, lastHit = 0}

-- Utility
local function GetChar()
    return LocalPlayer.Character
end

local function GetHRP()
    local char = GetChar()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function GetHumanoid()
    local char = GetChar()
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function GetNearest(range)
    local hrp = GetHRP()
    if not hrp then return nil end
    local nearest = nil
    local minDist = range
    for _, p in pairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        local c = p.Character
        if not c then continue end
        local h = c:FindFirstChild("HumanoidRootPart")
        if not h then continue end
        local d = (hrp.Position - h.Position).Magnitude
        if d < minDist then
            minDist = d
            nearest = {Player = p, HRP = h, Humanoid = c:FindFirstChildOfClass("Humanoid")}
        end
    end
    return nearest
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
            table.insert(t, {Player = p, HRP = h, Dist = d})
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

-- Find remotes
local function FindRemote(pattern)
    for _, v in pairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("RemoteEvent") and v.Name:lower():find(pattern:lower()) then
            return v
        end
    end
    return nil
end

local AttackRemote = FindRemote("attack") or FindRemote("m1") or FindRemote("punch")
local BlockRemote = FindRemote("block") or FindRemote("guard")
local DamageRemote = FindRemote("damage") or FindRemote("hit")

-- GUI
local SG = Instance.new("ScreenGui")
SG.Name = "JJSV4"
SG.Parent = game.CoreGui
SG.ResetOnSpawn = false

local MF = Instance.new("Frame")
MF.Parent = SG
MF.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
MF.BorderSizePixel = 0
MF.Position = UDim2.new(0.02, 0, 0.1, 0)
MF.Size = UDim2.new(0, 260, 0, 460)
MF.Active = true
MF.Draggable = true

Instance.new("UICorner", MF).CornerRadius = UDim.new(0, 10)

local US = Instance.new("UIStroke")
US.Parent = MF
US.Color = Color3.fromRGB(200, 100, 255)
US.Thickness = 1.5

local TB = Instance.new("Frame")
TB.Parent = MF
TB.BackgroundColor3 = Color3.fromRGB(200, 100, 255)
TB.Size = UDim2.new(1, 0, 0, 36)
Instance.new("UICorner", TB).CornerRadius = UDim.new(0, 10)

local TL = Instance.new("TextLabel")
TL.Parent = TB
TL.BackgroundTransparency = 1
TL.Size = UDim2.new(1, -40, 1, 0)
TL.Position = UDim2.new(0, 12, 0, 0)
TL.Font = Enum.Font.GothamBold
TL.Text = "  JJS Hub V4"
TL.TextColor3 = Color3.fromRGB(255, 255, 255)
TL.TextSize = 16
TL.TextXAlignment = Enum.TextXAlignment.Left

local CB = Instance.new("TextButton")
CB.Parent = TB
CB.BackgroundTransparency = 1
CB.Size = UDim2.new(0, 30, 0, 30)
CB.Position = UDim2.new(1, -32, 0, 3)
CB.Font = Enum.Font.GothamBold
CB.Text = "X"
CB.TextColor3 = Color3.fromRGB(255, 255, 255)
CB.TextSize = 18

CB.MouseButton1Click:Connect(function()
    SG:Destroy()
    for _, c in pairs(Connections) do
        if c then c:Disconnect() end
    end
end)

local SF = Instance.new("ScrollingFrame")
SF.Parent = MF
SF.BackgroundTransparency = 1
SF.Position = UDim2.new(0, 8, 0, 42)
SF.Size = UDim2.new(1, -16, 1, -50)
SF.ScrollBarThickness = 3
SF.ScrollBarImageColor3 = Color3.fromRGB(200, 100, 255)
SF.CanvasSize = UDim2.new(0, 0, 0, 700)

local LL = Instance.new("UIListLayout")
LL.Parent = SF
LL.SortOrder = Enum.SortOrder.LayoutOrder
LL.Padding = UDim.new(0, 5)

local function MakeSection(text)
    local L = Instance.new("TextLabel")
    L.Parent = SF
    L.BackgroundTransparency = 1
    L.Size = UDim2.new(1, 0, 0, 20)
    L.Font = Enum.Font.GothamBold
    L.Text = "> " .. text
    L.TextColor3 = Color3.fromRGB(200, 100, 255)
    L.TextSize = 12
    L.TextXAlignment = Enum.TextXAlignment.Left
    return L
end

local function MakeToggle(text, key)
    local F = Instance.new("Frame")
    F.Parent = SF
    F.BackgroundColor3 = Color3.fromRGB(18, 18, 32)
    F.BorderSizePixel = 0
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
    B.BorderSizePixel = 0
    B.Position = UDim2.new(1, -46, 0.5, -9)
    B.Size = UDim2.new(0, 40, 0, 18)
    B.AutoButtonColor = false
    B.Text = ""
    Instance.new("UICorner", B).CornerRadius = UDim.new(1, 0)
    
    local K = Instance.new("Frame")
    K.Parent = B
    K.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    K.BorderSizePixel = 0
    K.Position = UDim2.new(0, 2, 0.5, -6)
    K.Size = UDim2.new(0, 12, 0, 12)
    Instance.new("UICorner", K).CornerRadius = UDim.new(1, 0)
    
    local on = false
    B.MouseButton1Click:Connect(function()
        on = not on
        Config[key] = on
        if on then
            TweenService:Create(B, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(200, 100, 255)}):Play()
            TweenService:Create(K, TweenInfo.new(0.15), {Position = UDim2.new(0, 26, 0.5, -6)}):Play()
        else
            TweenService:Create(B, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(50, 50, 65)}):Play()
            TweenService:Create(K, TweenInfo.new(0.15), {Position = UDim2.new(0, 2, 0.5, -6)}):Play()
        end
    end)
    
    return F
end

local function MakeSlider(text, key, min, max, def)
    local F = Instance.new("Frame")
    F.Parent = SF
    F.BackgroundColor3 = Color3.fromRGB(18, 18, 32)
    F.BorderSizePixel = 0
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
    T.BorderSizePixel = 0
    T.Position = UDim2.new(0, 10, 0, 28)
    T.Size = UDim2.new(1, -20, 0, 5)
    Instance.new("UICorner", T).CornerRadius = UDim.new(1, 0)
    
    local Fi = Instance.new("Frame")
    Fi.Parent = T
    Fi.BackgroundColor3 = Color3.fromRGB(200, 100, 255)
    Fi.BorderSizePixel = 0
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
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            drag = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(inp)
        if drag and inp.UserInputType == Enum.UserInputType.MouseMovement then
            upd(inp)
        end
    end)
end

-- Build GUI
MakeSection("GOJO MODE")
MakeToggle("Gojo God Mode", "GojoMode")
MakeToggle("Auto Gojo Skills", "AutoGojoSkills")
MakeSlider("Kill Range", "KillRange", 10, 100, 50)

MakeSection("COMBAT")
MakeToggle("Auto Black Flash", "AutoBlackFlash")
MakeToggle("Auto BF Chain", "AutoBlackFlashChain")
MakeToggle("Auto Block", "AutoBlock")
MakeToggle("Auto Parry", "AutoParry")
MakeToggle("Auto Counter", "AutoCounter")
MakeToggle("Auto Combo", "AutoCombo")
MakeToggle("Auto Skills", "AutoSkills")
MakeToggle("Auto Domain", "AutoDomain")

MakeSection("DEFENSE")
MakeToggle("Auto Dodge", "AutoDodge")
MakeToggle("Anti Ragdoll", "AntiRagdoll")
MakeToggle("Inf CE", "InfCE")
MakeToggle("No Cooldown", "NoCooldown")

MakeSection("MOVEMENT")
MakeToggle("Speed Hack", "SpeedHack")
MakeSlider("Walk Speed", "WalkSpeed", 16, 200, 16)
MakeSlider("Jump Power", "JumpPower", 50, 300, 50)
MakeToggle("Fly", "Fly")
MakeToggle("Noclip", "Noclip")

MakeSection("VISUAL")
MakeToggle("ESP", "ESP")
MakeToggle("Hitbox", "Hitbox")

MakeSection("MISC")
MakeToggle("Anti AFK", "AntiAFK")

-- CORE LOOPS

-- Auto Block - detects enemy attack animations
local blockConn = RunService.Heartbeat:Connect(function()
    if not Config.AutoBlock then
        if BlockState.isBlocking then
            BlockState.isBlocking = false
            pcall(function() VirtualUser:SetKeyUp("F") end)
        end
        return
    end
    
    local hrp = GetHRP()
    if not hrp then return end
    
    local shouldBlock = false
    local targets = GetAllInRange(12)
    
    for _, t in pairs(targets) do
        local hum = t.Player.Character and t.Player.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            for _, track in pairs(hum:GetPlayingAnimationTracks()) do
                local n = track.Name:lower()
                if n:find("attack") or n:find("punch") or n:find("swing") or n:find("slash") or n:find("m1") then
                    shouldBlock = true
                    break
                end
            end
        end
        
        local vel = t.HRP.Velocity.Magnitude
        if vel > 30 then shouldBlock = true end
        
        local toUs = (hrp.Position - t.HRP.Position).Unit
        local look = t.HRP.CFrame.LookVector
        if toUs:Dot(look) > 0.6 then shouldBlock = true end
    end
    
    if shouldBlock and not BlockState.isBlocking then
        BlockState.isBlocking = true
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:SetKeyDown("F")
        end)
    elseif not shouldBlock and BlockState.isBlocking then
        BlockState.isBlocking = false
        pcall(function() VirtualUser:SetKeyUp("F") end)
    end
end)
table.insert(Connections, blockConn)

-- Auto Parry
local parryConn = RunService.Heartbeat:Connect(function()
    if not Config.AutoParry then return end
    local target = GetNearest(15)
    if not target then return end
    if not target.Humanoid then return end
    
    for _, track in pairs(target.Humanoid:GetPlayingAnimationTracks()) do
        local n = track.Name:lower()
        if n:find("attack") or n:find("punch") or n:find("m1") then
            if track.TimePosition > 0.05 and track.TimePosition < 0.35 then
                Face(target.HRP.Position)
                Press("F")
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
    
    -- Method 1: Try to land BF with timing after M1
    Click()
    task.wait(0.08)
    Press("R")
    task.wait(0.05)
    
    -- Method 2: If chain mode, spam for consecutive BFs
    if Config.AutoBlackFlashChain then
        local now = tick()
        if now - BFState.lastHit < 2 then
            BFState.chain = BFState.chain + 1
            if BFState.chain >= 3 then
                -- 4th consecutive = chain
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
    Click()
    task.wait(0.12)
end)
table.insert(Connections, comboConn)

-- Auto Skills
local skillIdx = 1
local skillKeys = {"Z", "X", "C", "V"}
local skillConn = RunService.Heartbeat:Connect(function()
    if not Config.AutoSkills then return end
    local target = GetNearest(25)
    if not target then return end
    Face(target.HRP.Position)
    Press(skillKeys[skillIdx])
    skillIdx = skillIdx % #skillKeys + 1
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
        local hum = t.Player.Character and t.Player.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            for _, track in pairs(hum:GetPlayingAnimationTracks()) do
                local n = track.Name:lower()
                if n:find("attack") or n:find("punch") then
                    if track.TimePosition < 0.2 then
                        local dir = (hrp.Position - t.HRP.Position).Unit * 12
                        hrp.CFrame = CFrame.new(hrp.Position + dir)
                        Press("Q")
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
    local hum = GetHumanoid()
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
    local hum = GetHumanoid()
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
    local hum = GetHumanoid()
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

-- Gojo Mode - Auto skills for Gojo character
local gojoConn = RunService.Heartbeat:Connect(function()
    if not Config.GojoMode then return end
    
    local char = GetChar()
    if not char then return end
    
    -- Check if Gojo (by looking for specific moves/tools)
    local isGojo = false
    for _, obj in pairs(char:GetDescendants()) do
        local n = obj.Name:lower()
        if n:find("gojo") or n:find("limitless") or n:find("purple") or n:find("sixeyes") then
            isGojo = true
            break
        end
    end
    
    if not isGojo then
        -- Also check by tool names
        for _, tool in pairs(char:GetChildren()) do
            if tool:IsA("Tool") then
                local n = tool.Name:lower()
                if n:find("lapse") or n:find("reversal") or n:find("hollow") or n:find("purple") then
                    isGojo = true
                    break
                end
            end
        end
    end
    
    if not isGojo then return end
    
    -- Auto Gojo skills
    if Config.AutoGojoSkills then
        local target = GetNearest(30)
        if target then
            Face(target.HRP.Position)
            -- Purple (C) when close
            if target.Dist and target.Dist < 15 then
                Press("C")
                task.wait(3)
            end
            -- Red (X) at mid range
            if target.Dist and target.Dist < 25 then
                Press("X")
                task.wait(1.5)
            end
            -- Blue (Z) for pull
            Press("Z")
            task.wait(2)
        end
    end
    
    -- Auto kill all in range during domain/awakening
    local hrp = GetHRP()
    if not hrp then return end
    
    local hum = GetHumanoid()
    if hum and hum.PlatformStand then
        -- Likely in domain/0.2 state
        for _, p in pairs(Players:GetPlayers()) do
            if p == LocalPlayer then continue end
            local c = p.Character
            if not c then continue end
            local h = c:FindFirstChild("HumanoidRootPart")
            if not h then continue end
            local d = (hrp.Position - h.Position).Magnitude
            if d <= Config.KillRange then
                hrp.CFrame = CFrame.new(h.Position + Vector3.new(0, 2, 0))
                Press("F")
                task.wait(0.05)
                Click()
                if DamageRemote then
                    pcall(function()
                        DamageRemote:FireServer({Target = p, Damage = 99999})
                    end)
                end
            end
        end
    end
end)
table.insert(Connections, gojoConn)

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

-- Full Bright
local fbConn = RunService.Heartbeat:Connect(function()
    if Config.ESP then
        Lighting.Brightness = 8
        Lighting.GlobalShadows = false
    end
end)
table.insert(Connections, fbConn)

-- Notification
local N = Instance.new("Frame")
N.Parent = SG
N.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
N.BorderSizePixel = 0
N.Position = UDim2.new(0.5, -140, 0, -80)
N.Size = UDim2.new(0, 280, 0, 55)
N.AnchorPoint = Vector2.new(0.5, 0)
Instance.new("UICorner", N).CornerRadius = UDim.new(0, 10)

local NS = Instance.new("UIStroke")
NS.Parent = N
NS.Color = Color3.fromRGB(200, 100, 255)
NS.Thickness = 2

local NT = Instance.new("TextLabel")
NT.Parent = N
NT.BackgroundTransparency = 1
NT.Size = UDim2.new(1, 0, 1, 0)
NT.Font = Enum.Font.GothamBold
NT.Text = "JJS Hub V4 Loaded"
NT.TextColor3 = Color3.fromRGB(200, 100, 255)
NT.TextSize = 16

N:TweenPosition(UDim2.new(0.5, -140, 0, 25), Enum.EasingDirection.Out, Enum.EasingStyle.Back, 0.5, true)

task.delay(4, function()
    N:TweenPosition(UDim2.new(0.5, -140, 0, -80), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.4, true)
    task.wait(0.4)
    N:Destroy()
end)
