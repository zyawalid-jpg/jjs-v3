
-- JJS HUB V3 — GOD MODE EDITION
-- Anti-Cheat Bypass + Gojo 0.2 Domain Auto Kill All
-- Compatible: Delta, Fluxus, Codex, Krnl, Synapse X

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local Stats = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- ═══════════════════════════════════════════════════════════════
-- ANTI-CHEAT BYPASS SYSTEM
-- ═══════════════════════════════════════════════════════════════

local AntiCheat = {OriginalValues = {}, SpoofedValues = {}, Hooks = {}, DetectedRemotes = {}}

local mt = getrawmetatable and getrawmetatable(game) or nil
if mt then
    setreadonly(mt, false)
    local oldIndex = mt.__index
    local oldNamecall = mt.__namecall

    mt.__index = newcclosure(function(self, key)
        if self:IsA("Humanoid") and key == "WalkSpeed" then
            if AntiCheat.SpoofedValues[self] and AntiCheat.SpoofedValues[self].WalkSpeed then
                return AntiCheat.SpoofedValues[self].WalkSpeed
            end
        end
        if self:IsA("Humanoid") and key == "JumpPower" then
            if AntiCheat.SpoofedValues[self] and AntiCheat.SpoofedValues[self].JumpPower then
                return AntiCheat.SpoofedValues[self].JumpPower
            end
        end
        return oldIndex(self, key)
    end)

    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        if method == "FireServer" or method == "InvokeServer" then
            local remoteName = self.Name:lower()
            if remoteName:find("anticheat") or remoteName:find("ac_") or remoteName:find("detect") 
               or remoteName:find("ban") or remoteName:find("kick") or remoteName:find("report")
               or remoteName:find("check") or remoteName:find("verify") then
                print("[AC BYPASS] Blocked: " .. self.Name)
                return nil
            end
            if #args > 0 and typeof(args[1]) == "table" then
                for k, v in pairs(args[1]) do
                    if typeof(v) == "Vector3" then
                        args[1][k] = v + Vector3.new(math.random(-10, 10) / 100, math.random(-10, 10) / 100, math.random(-10, 10) / 100)
                    end
                end
            end
        end
        return oldNamecall(self, unpack(args))
    end)
    setreadonly(mt, true)
end

local function AntiFlyBypass()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local fakeGround = Instance.new("Part")
    fakeGround.Name = "_AC_GroundRef"
    fakeGround.Anchored = true
    fakeGround.CanCollide = false
    fakeGround.Transparency = 1
    fakeGround.Size = Vector3.new(1, 1, 1)
    fakeGround.Parent = Workspace
    RunService.Heartbeat:Connect(function()
        if hrp and fakeGround then fakeGround.Position = hrp.Position - Vector3.new(0, 3, 0) end
    end)
end

local function SpoofHumanoidState()
    local char = LocalPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    local oldGetState = humanoid.GetState
    humanoid.GetState = function(self)
        local state = oldGetState(self)
        if state == Enum.HumanoidStateType.Physics or state == Enum.HumanoidStateType.PlatformStanding then
            return Enum.HumanoidStateType.Running
        end
        return state
    end
end

local function HideFromDetection()
    for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
        if part:IsA("BasePart") then part:SetNetworkOwner(nil) end
    end
end

-- ═══════════════════════════════════════════════════════════════
-- GOJO 0.2 DOMAIN AUTO KILL SYSTEM
-- ═══════════════════════════════════════════════════════════════

local GojoSystem = {
    IsGojo = false, IsIn02Domain = false, IsRushing = false,
    Phase = 0, TargetsKilled = 0, AutoKillEnabled = false,
    Auto02Domain = false, AutoAwakening = false, InstaKillMode = false,
}

local function CheckIfGojo()
    local char = LocalPlayer.Character
    if not char then return false end
    for _, obj in pairs(char:GetDescendants()) do
        if obj.Name:lower():find("gojo") or obj.Name:lower():find("honored") 
           or obj.Name:lower():find("blindfold") or obj.Name:lower():find("sixeyes") then
            return true
        end
    end
    for _, tool in pairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            local name = tool.Name:lower()
            if name:find("lapse") or name:find("reversal") or name:find("hollow") 
               or name:find("purple") or name:find("limitless") then
                return true
            end
        end
    end
    return false
end

local function Detect02DomainState()
    local char = LocalPlayer.Character
    if not char then return false end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end
    for _, animTrack in pairs(humanoid:GetPlayingAnimationTracks()) do
        local animName = animTrack.Name:lower()
        if animName:find("0.2") or animName:find("domain") or animName:find("awakening")
           or animName:find("rush") or animName:find("chant") or animName:find("blindfold") then
            return true, animTrack
        end
    end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then
        local vel = hrp.Velocity.Magnitude
        if vel > 80 and GojoSystem.IsIn02Domain then return true end
    end
    if humanoid.PlatformStand and GojoSystem.IsIn02Domain then return true end
    return false
end

local function DetectPhase()
    local char = LocalPlayer.Character
    if not char then return 0 end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return 0 end
    local vel = hrp.Velocity.Magnitude
    if vel > 100 and vel < 150 then return 1
    elseif vel >= 150 and vel < 200 then return 2
    elseif vel >= 200 then return 3 end
    return 0
end

local function SimulateKeyPress(key, duration)
    duration = duration or 0.05
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:SetKeyDown(key)
        task.wait(duration)
        VirtualUser:SetKeyUp(key)
    end)
end

local function SimulateMouseClick(button)
    pcall(function()
        VirtualUser:CaptureController()
        if button == 2 then
            VirtualUser:Button2Down(Vector2.new())
            task.wait(0.05)
            VirtualUser:Button2Up(Vector2.new())
        else
            VirtualUser:Button1Down(Vector2.new())
            task.wait(0.05)
            VirtualUser:Button1Up(Vector2.new())
        end
    end)
end

local function GetHRP()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function GetAllPlayersInRange(range)
    local hrp = GetHRP()
    if not hrp then return {} end
    local targets = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local char = player.Character
        if not char then continue end
        local targetHRP = char:FindFirstChild("HumanoidRootPart")
        if not targetHRP then continue end
        local dist = (hrp.Position - targetHRP.Position).Magnitude
        if dist <= range then
            table.insert(targets, {Player = player, Character = char, HRP = targetHRP, Distance = dist})
        end
    end
    return targets
end

local function AutoKillAll02()
    if not GojoSystem.AutoKillEnabled or not GojoSystem.IsIn02Domain then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = GetHRP()
    if not hrp then return end

    local targets = GetAllPlayersInRange(50)
    table.sort(targets, function(a, b) return a.Distance < b.Distance end)

    for i, target in pairs(targets) do
        if i > 2 and not GojoSystem.InstaKillMode then break end
        if GojoSystem.IsRushing then
            hrp.CFrame = CFrame.new(target.HRP.Position + Vector3.new(0, 2, 0))
            SimulateKeyPress("F")
            task.wait(0.05)
            SimulateMouseClick(1)
            for _, remote in pairs(ReplicatedStorage:GetDescendants()) do
                if remote:IsA("RemoteEvent") then
                    pcall(function()
                        remote:FireServer({["Target"] = target.Player, ["Damage"] = 99999, ["InstaKill"] = true})
                    end)
                end
            end
            GojoSystem.TargetsKilled = GojoSystem.TargetsKilled + 1
        end
        task.wait(0.1)
    end
end

local function Auto02Domain()
    if not GojoSystem.Auto02Domain then return end
    if GojoSystem.IsIn02Domain then return end
    local char = LocalPlayer.Character
    if not char then return end

    local awakeningFull = false
    for _, v in pairs(char:GetDescendants()) do
        if v:IsA("NumberValue") or v:IsA("IntValue") then
            if v.Name:lower():find("awakening") or v.Name:lower():find("domain") then
                if v.Value >= (v.MaxValue or 100) * 0.9 then awakeningFull = true end
            end
        end
    end

    local hrp = GetHRP()
    if not hrp then return end
    local enemiesNearby = false
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local targetChar = player.Character
        if not targetChar then continue end
        local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
        if targetHRP and (hrp.Position - targetHRP.Position).Magnitude < 40 then
            enemiesNearby = true
            break
        end
    end

    if awakeningFull and enemiesNearby then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:SetKeyDown("G")
            task.wait(0.05)
            VirtualUser:SetKeyDown("R")
            task.wait(0.1)
            VirtualUser:SetKeyUp("R")
            VirtualUser:SetKeyUp("G")
        end)
        GojoSystem.IsIn02Domain = true
        GojoSystem.TargetsKilled = 0
    end
end

local function AutoAwakening()
    if not GojoSystem.AutoAwakening then return end
    if GojoSystem.IsIn02Domain then return end
    local char = LocalPlayer.Character
    if not char then return end
    for _, v in pairs(char:GetDescendants()) do
        if v:IsA("NumberValue") or v:IsA("IntValue") then
            if v.Name:lower():find("awakening") and v.Value >= (v.MaxValue or 100) then
                SimulateKeyPress("G")
                task.wait(0.5)
                break
            end
        end
    end
end


-- ═══════════════════════════════════════════════════════════════
-- CONFIGURATION
-- ═══════════════════════════════════════════════════════════════

local Config = {
    GojoGodMode = false, Auto02Domain = false, AutoAwakening = false,
    AutoKillAll = false, InstaKillMode = false, AutoPurple = false,
    AutoRed = false, AutoBlue = false, AutoLimitless = false,
    AntiCheatBypass = true, SpoofValues = true, HideFromAC = true, BlockACRemotes = true,
    AutoBlackFlash = false, AutoBlackFlashChain = false, AutoBlock = false,
    AutoParry = false, AutoCounter = false, AutoCombo = false,
    AutoM1Trade = false, AutoSkills = false, AutoDomain = false, AutoFeint = false,
    AutoDodge = false, AntiRagdoll = false, AutoRecover = false,
    InfCursedEnergy = false, NoCooldowns = false, InstantCharge = false,
    SpeedHack = false, WalkSpeed = 16, JumpPower = 50,
    AutoDash = false, InfiniteDash = false, Fly = false, Noclip = false, ClickTP = false,
    ESP = false, ESPTracers = false, ESPDistance = false, ESPHealth = false,
    HitboxExpander = false, FullBright = false, NoFog = false,
    AntiAFK = false, AutoClick = false,
    BlackFlashRange = 8, BlockRange = 12, ParryRange = 15,
    CounterRange = 10, ComboRange = 6, SkillDelay = 0.25,
    ComboDelay = 0.12, DodgeRange = 8, HitboxSize = 10,
    ESPRange = 500, KillRange = 50,
}

-- ═══════════════════════════════════════════════════════════════
-- GUI V3 — GOD MODE DESIGN
-- ═══════════════════════════════════════════════════════════════

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "JJS_HUB_V3"
ScreenGui.Parent = game.CoreGui
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local MainFrame = Instance.new("Frame")
MainFrame.Name = "Main"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(8, 8, 16)
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0.015, 0, 0.08, 0)
MainFrame.Size = UDim2.new(0, 320, 0, 540)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = true

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 14)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(180, 120, 255)
MainStroke.Thickness = 2
MainStroke.Parent = MainFrame

local Glow = Instance.new("ImageLabel")
Glow.Parent = MainFrame
Glow.BackgroundTransparency = 1
Glow.Position = UDim2.new(0, -20, 0, -20)
Glow.Size = UDim2.new(1, 40, 1, 40)
Glow.Image = "rbxassetid://4996891970"
Glow.ImageColor3 = Color3.fromRGB(180, 120, 255)
Glow.ImageTransparency = 0.85
Glow.ZIndex = 0

local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Parent = MainFrame
TitleBar.BackgroundColor3 = Color3.fromRGB(180, 120, 255)
TitleBar.BorderSizePixel = 0
TitleBar.Size = UDim2.new(1, 0, 0, 44)

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 14)
TitleCorner.Parent = TitleBar

local TitleText = Instance.new("TextLabel")
TitleText.Parent = TitleBar
TitleText.BackgroundTransparency = 1
TitleText.Size = UDim2.new(1, -60, 1, 0)
TitleText.Position = UDim2.new(0, 15, 0, 0)
TitleText.Font = Enum.Font.GothamBold
TitleText.Text = "  ⚡ JJS HUB V3"
TitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleText.TextSize = 18
TitleText.TextXAlignment = Enum.TextXAlignment.Left

local VersionText = Instance.new("TextLabel")
VersionText.Parent = TitleBar
VersionText.BackgroundTransparency = 1
VersionText.Position = UDim2.new(1, -80, 0, 0)
VersionText.Size = UDim2.new(0, 70, 1, 0)
VersionText.Font = Enum.Font.Gotham
VersionText.Text = "GOD MODE"
VersionText.TextColor3 = Color3.fromRGB(255, 220, 100)
VersionText.TextSize = 11
VersionText.TextXAlignment = Enum.TextXAlignment.Right

local MinBtn = Instance.new("TextButton")
MinBtn.Parent = TitleBar
MinBtn.BackgroundTransparency = 1
MinBtn.Size = UDim2.new(0, 30, 0, 30)
MinBtn.Position = UDim2.new(1, -65, 0, 7)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.Text = "−"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.TextSize = 20

local CloseBtn = Instance.new("TextButton")
CloseBtn.Parent = TitleBar
CloseBtn.BackgroundTransparency = 1
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -35, 0, 7)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 22

local ContentFrame = Instance.new("Frame")
ContentFrame.Parent = MainFrame
ContentFrame.BackgroundTransparency = 1
ContentFrame.Position = UDim2.new(0, 0, 0, 44)
ContentFrame.Size = UDim2.new(1, 0, 1, -44)
ContentFrame.ClipsDescendants = true

local TabFrame = Instance.new("Frame")
TabFrame.Parent = ContentFrame
TabFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 24)
TabFrame.BorderSizePixel = 0
TabFrame.Size = UDim2.new(1, 0, 0, 38)

local TabLayout = Instance.new("UIListLayout")
TabLayout.Parent = TabFrame
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
TabLayout.Padding = UDim.new(0, 3)

local Tabs = {}
local TabContents = {}
local ActiveTab = "Gojo"

local function CreateTab(name)
    local TabBtn = Instance.new("TextButton")
    TabBtn.Parent = TabFrame
    TabBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
    TabBtn.BorderSizePixel = 0
    TabBtn.Size = UDim2.new(0, 60, 1, -6)
    TabBtn.Position = UDim2.new(0, 0, 0, 3)
    TabBtn.Font = Enum.Font.GothamBold
    TabBtn.Text = name
    TabBtn.TextColor3 = Color3.fromRGB(140, 140, 170)
    TabBtn.TextSize = 10
    TabBtn.AutoButtonColor = false

    local TBC = Instance.new("UICorner")
    TBC.CornerRadius = UDim.new(0, 6)
    TBC.Parent = TabBtn

    local TabContent = Instance.new("ScrollingFrame")
    TabContent.Parent = ContentFrame
    TabContent.BackgroundTransparency = 1
    TabContent.Position = UDim2.new(0, 10, 0, 44)
    TabContent.Size = UDim2.new(1, -20, 1, -52)
    TabContent.ScrollBarThickness = 3
    TabContent.ScrollBarImageColor3 = Color3.fromRGB(180, 120, 255)
    TabContent.CanvasSize = UDim2.new(0, 0, 0, 900)
    TabContent.Visible = false

    local List = Instance.new("UIListLayout")
    List.Parent = TabContent
    List.SortOrder = Enum.SortOrder.LayoutOrder
    List.Padding = UDim.new(0, 6)

    Tabs[name] = TabBtn
    TabContents[name] = TabContent

    TabBtn.MouseButton1Click:Connect(function()
        ActiveTab = name
        for n, btn in pairs(Tabs) do
            if n == name then
                btn.BackgroundColor3 = Color3.fromRGB(180, 120, 255)
                btn.TextColor3 = Color3.fromRGB(255, 255, 255)
                TabContents[n].Visible = true
            else
                btn.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
                btn.TextColor3 = Color3.fromRGB(140, 140, 170)
                TabContents[n].Visible = false
            end
        end
    end)

    return TabContent
end

CreateTab("Gojo")
CreateTab("AC")
CreateTab("Combat")
CreateTab("Move")
CreateTab("Visual")
CreateTab("Misc")

Tabs["Gojo"].BackgroundColor3 = Color3.fromRGB(180, 120, 255)
Tabs["Gojo"].TextColor3 = Color3.fromRGB(255, 255, 255)
TabContents["Gojo"].Visible = true

local function CreateSection(parent, text)
    local Label = Instance.new("TextLabel")
    Label.Parent = parent
    Label.BackgroundTransparency = 1
    Label.Size = UDim2.new(1, 0, 0, 22)
    Label.Font = Enum.Font.GothamBold
    Label.Text = "▸ " .. text
    Label.TextColor3 = Color3.fromRGB(180, 120, 255)
    Label.TextSize = 12
    Label.TextXAlignment = Enum.TextXAlignment.Left
    return Label
end

local function CreateToggle(parent, name, configKey)
    local Frame = Instance.new("Frame")
    Frame.Parent = parent
    Frame.BackgroundColor3 = Color3.fromRGB(16, 16, 30)
    Frame.BorderSizePixel = 0
    Frame.Size = UDim2.new(1, 0, 0, 36)

    local FC = Instance.new("UICorner")
    FC.CornerRadius = UDim.new(0, 6)
    FC.Parent = Frame

    local Label = Instance.new("TextLabel")
    Label.Parent = Frame
    Label.BackgroundTransparency = 1
    Label.Position = UDim2.new(0, 12, 0, 0)
    Label.Size = UDim2.new(0.55, 0, 1, 0)
    Label.Font = Enum.Font.Gotham
    Label.Text = name
    Label.TextColor3 = Color3.fromRGB(200, 200, 215)
    Label.TextSize = 12
    Label.TextXAlignment = Enum.TextXAlignment.Left

    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Parent = Frame
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    ToggleBtn.BorderSizePixel = 0
    ToggleBtn.Position = UDim2.new(1, -52, 0.5, -10)
    ToggleBtn.Size = UDim2.new(0, 44, 0, 20)
    ToggleBtn.AutoButtonColor = false
    ToggleBtn.Text = ""

    local TBC = Instance.new("UICorner")
    TBC.CornerRadius = UDim.new(1, 0)
    TBC.Parent = ToggleBtn

    local Knob = Instance.new("Frame")
    Knob.Parent = ToggleBtn
    Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Knob.BorderSizePixel = 0
    Knob.Position = UDim2.new(0, 2, 0.5, -7)
    Knob.Size = UDim2.new(0, 14, 0, 14)

    local KC = Instance.new("UICorner")
    KC.CornerRadius = UDim.new(1, 0)
    KC.Parent = Knob

    local enabled = Config[configKey] or false

    local function UpdateVisual()
        if enabled then
            TweenService:Create(ToggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(180, 120, 255)}):Play()
            TweenService:Create(Knob, TweenInfo.new(0.2), {Position = UDim2.new(0, 28, 0.5, -7)}):Play()
        else
            TweenService:Create(ToggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 50, 65)}):Play()
            TweenService:Create(Knob, TweenInfo.new(0.2), {Position = UDim2.new(0, 2, 0.5, -7)}):Play()
        end
    end

    ToggleBtn.MouseButton1Click:Connect(function()
        enabled = not enabled
        Config[configKey] = enabled
        UpdateVisual()
        if configKey == "Auto02Domain" then GojoSystem.Auto02Domain = enabled end
        if configKey == "AutoAwakening" then GojoSystem.AutoAwakening = enabled end
        if configKey == "AutoKillAll" then GojoSystem.AutoKillEnabled = enabled end
        if configKey == "InstaKillMode" then GojoSystem.InstaKillMode = enabled end
    end)

    return Frame
end

local function CreateSlider(parent, name, configKey, min, max, default)
    local Frame = Instance.new("Frame")
    Frame.Parent = parent
    Frame.BackgroundColor3 = Color3.fromRGB(16, 16, 30)
    Frame.BorderSizePixel = 0
    Frame.Size = UDim2.new(1, 0, 0, 52)

    local FC = Instance.new("UICorner")
    FC.CornerRadius = UDim.new(0, 6)
    FC.Parent = Frame

    local Label = Instance.new("TextLabel")
    Label.Parent = Frame
    Label.BackgroundTransparency = 1
    Label.Position = UDim2.new(0, 12, 0, 4)
    Label.Size = UDim2.new(1, -24, 0, 16)
    Label.Font = Enum.Font.Gotham
    Label.Text = name .. ": " .. default
    Label.TextColor3 = Color3.fromRGB(200, 200, 215)
    Label.TextSize = 11
    Label.TextXAlignment = Enum.TextXAlignment.Left

    local Track = Instance.new("Frame")
    Track.Parent = Frame
    Track.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    Track.BorderSizePixel = 0
    Track.Position = UDim2.new(0, 12, 0, 30)
    Track.Size = UDim2.new(1, -24, 0, 5)

    local TC = Instance.new("UICorner")
    TC.CornerRadius = UDim.new(1, 0)
    TC.Parent = Track

    local Fill = Instance.new("Frame")
    Fill.Parent = Track
    Fill.BackgroundColor3 = Color3.fromRGB(180, 120, 255)
    Fill.BorderSizePixel = 0
    Fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)

    local FC2 = Instance.new("UICorner")
    FC2.CornerRadius = UDim.new(1, 0)
    FC2.Parent = Fill

    local dragging = false

    local function update(input)
        local pos = math.clamp((input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
        local value = math.floor(min + (pos * (max - min)))
        Config[configKey] = value
        Fill.Size = UDim2.new(pos, 0, 1, 0)
        Label.Text = name .. ": " .. value
    end

    Track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            update(input)
        end
    end)

    Track.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            update(input)
        end
    end)
end

local function CreateButton(parent, name, callback)
    local Btn = Instance.new("TextButton")
    Btn.Parent = parent
    Btn.BackgroundColor3 = Color3.fromRGB(180, 120, 255)
    Btn.BorderSizePixel = 0
    Btn.Size = UDim2.new(1, 0, 0, 34)
    Btn.Font = Enum.Font.GothamBold
    Btn.Text = name
    Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Btn.TextSize = 12
    Btn.AutoButtonColor = true

    local BC = Instance.new("UICorner")
    BC.CornerRadius = UDim.new(0, 6)
    BC.Parent = Btn

    Btn.MouseButton1Click:Connect(callback)
    return Btn
end

-- POPULATE TABS
CreateSection(TabContents["Gojo"], "0.2 DOMAIN AUTO KILL")
CreateToggle(TabContents["Gojo"], "Gojo God Mode", "GojoGodMode")
CreateToggle(TabContents["Gojo"], "Auto 0.2 Domain", "Auto02Domain")
CreateToggle(TabContents["Gojo"], "Auto Awakening", "AutoAwakening")
CreateToggle(TabContents["Gojo"], "Auto Kill All", "AutoKillAll")
CreateToggle(TabContents["Gojo"], "Insta Kill Mode", "InstaKillMode")
CreateSlider(TabContents["Gojo"], "Kill Range", "KillRange", 10, 100, 50)

CreateSection(TabContents["Gojo"], "GOJO SKILLS")
CreateToggle(TabContents["Gojo"], "Auto Hollow Purple", "AutoPurple")
CreateToggle(TabContents["Gojo"], "Auto Reversal Red", "AutoRed")
CreateToggle(TabContents["Gojo"], "Auto Lapse Blue", "AutoBlue")
CreateToggle(TabContents["Gojo"], "Auto Limitless", "AutoLimitless")

CreateSection(TabContents["AC"], "BYPASS")
CreateToggle(TabContents["AC"], "Anti-Cheat Bypass", "AntiCheatBypass")
CreateToggle(TabContents["AC"], "Spoof Values", "SpoofValues")
CreateToggle(TabContents["AC"], "Hide From AC", "HideFromAC")
CreateToggle(TabContents["AC"], "Block AC Remotes", "BlockACRemotes")

CreateSection(TabContents["AC"], "STATUS")
local ACStatus = Instance.new("TextLabel")
ACStatus.Parent = TabContents["AC"]
ACStatus.BackgroundTransparency = 1
ACStatus.Size = UDim2.new(1, 0, 0, 60)
ACStatus.Font = Enum.Font.Gotham
ACStatus.Text = "Status: PROTECTED\nAC Remotes Blocked: ACTIVE\nSpoof Active: YES"
ACStatus.TextColor3 = Color3.fromRGB(78, 204, 163)
ACStatus.TextSize = 11
ACStatus.TextWrapped = true

CreateSection(TabContents["Combat"], "BLACK FLASH")
CreateToggle(TabContents["Combat"], "Auto Black Flash", "AutoBlackFlash")
CreateToggle(TabContents["Combat"], "Auto BF Chain", "AutoBlackFlashChain")
CreateSlider(TabContents["Combat"], "BF Range", "BlackFlashRange", 3, 20, 8)

CreateSection(TabContents["Combat"], "BLOCK & PARRY")
CreateToggle(TabContents["Combat"], "Auto Block", "AutoBlock")
CreateToggle(TabContents["Combat"], "Auto Parry", "AutoParry")
CreateToggle(TabContents["Combat"], "Auto Counter", "AutoCounter")
CreateSlider(TabContents["Combat"], "Block Range", "BlockRange", 5, 25, 12)

CreateSection(TabContents["Combat"], "OFFENSE")
CreateToggle(TabContents["Combat"], "Auto Combo (M1)", "AutoCombo")
CreateToggle(TabContents["Combat"], "Auto M1 Trade", "AutoM1Trade")
CreateToggle(TabContents["Combat"], "Auto Skills", "AutoSkills")
CreateToggle(TabContents["Combat"], "Auto Domain", "AutoDomain")
CreateToggle(TabContents["Combat"], "Auto Feint", "AutoFeint")
CreateSlider(TabContents["Combat"], "Combo Range", "ComboRange", 3, 15, 6)

CreateSection(TabContents["Move"], "SPEED")
CreateToggle(TabContents["Move"], "Speed Hack", "SpeedHack")
CreateSlider(TabContents["Move"], "Walk Speed", "WalkSpeed", 16, 250, 16)
CreateSlider(TabContents["Move"], "Jump Power", "JumpPower", 50, 300, 50)

CreateSection(TabContents["Move"], "DASH & MISC")
CreateToggle(TabContents["Move"], "Auto Dash", "AutoDash")
CreateToggle(TabContents["Move"], "Infinite Dash", "InfiniteDash")
CreateToggle(TabContents["Move"], "Fly", "Fly")
CreateToggle(TabContents["Move"], "Noclip", "Noclip")
CreateToggle(TabContents["Move"], "Click TP", "ClickTP")

CreateSection(TabContents["Visual"], "ESP")
CreateToggle(TabContents["Visual"], "ESP Players", "ESP")
CreateToggle(TabContents["Visual"], "ESP Tracers", "ESPTracers")
CreateToggle(TabContents["Visual"], "ESP Distance", "ESPDistance")
CreateToggle(TabContents["Visual"], "ESP Health", "ESPHealth")
CreateSlider(TabContents["Visual"], "ESP Range", "ESPRange", 100, 2000, 500)

CreateSection(TabContents["Visual"], "HITBOX & WORLD")
CreateToggle(TabContents["Visual"], "Hitbox Expander", "HitboxExpander")
CreateSlider(TabContents["Visual"], "Hitbox Size", "HitboxSize", 5, 25, 10)
CreateToggle(TabContents["Visual"], "Full Bright", "FullBright")
CreateToggle(TabContents["Visual"], "No Fog", "NoFog")

CreateSection(TabContents["Misc"], "AUTOMATION")
CreateToggle(TabContents["Misc"], "Anti AFK", "AntiAFK")
CreateToggle(TabContents["Misc"], "Auto Click", "AutoClick")

CreateSection(TabContents["Misc"], "INFO")
CreateButton(TabContents["Misc"], "Copy Loadstring", function()
    pcall(function()
        setclipboard('loadstring(game:HttpGet("https://raw.githubusercontent.com/nyxhub/jjs-v3/main/jjsv3.lua"))()')
    end)
end)

-- MINIMIZE / CLOSE
local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        TweenService:Create(MainFrame, TweenInfo.new(0.3), {Size = UDim2.new(0, 320, 0, 44)}):Play()
        MinBtn.Text = "+"
    else
        TweenService:Create(MainFrame, TweenInfo.new(0.3), {Size = UDim2.new(0, 320, 0, 540)}):Play()
        MinBtn.Text = "−"
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    TweenService:Create(MainFrame, TweenInfo.new(0.3), {Position = UDim2.new(0.015, 0, 1, 0)}):Play()
    task.wait(0.3)
    ScreenGui:Destroy()
    for _, conn in pairs(Connections) do
        if conn then conn:Disconnect() end
    end
end)


-- ═══════════════════════════════════════════════════════════════
-- CORE FEATURES
-- ═══════════════════════════════════════════════════════════════

local Connections = {}

local function GetCharacter() return LocalPlayer.Character end
local function GetHumanoid()
    local char = GetCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end
local function GetHRP()
    local char = GetCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function GetNearestPlayer(range)
    local hrp = GetHRP()
    if not hrp then return nil, math.huge end
    local nearest = nil
    local nearestDist = math.huge
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local char = player.Character
        if not char then continue end
        local targetHRP = char:FindFirstChild("HumanoidRootPart")
        if not targetHRP then continue end
        local dist = (hrp.Position - targetHRP.Position).Magnitude
        if dist < nearestDist and dist <= range then
            nearestDist = dist
            nearest = {Player = player, Character = char, HRP = targetHRP, Humanoid = char:FindFirstChildOfClass("Humanoid")}
        end
    end
    return nearest, nearestDist
end

local function GetAllPlayersInRange(range)
    local hrp = GetHRP()
    if not hrp then return {} end
    local targets = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local char = player.Character
        if not char then continue end
        local targetHRP = char:FindFirstChild("HumanoidRootPart")
        if not targetHRP then continue end
        local dist = (hrp.Position - targetHRP.Position).Magnitude
        if dist <= range then
            table.insert(targets, {Player = player, Character = char, HRP = targetHRP, Distance = dist})
        end
    end
    return targets
end

local function FaceTarget(targetPos)
    local hrp = GetHRP()
    if not hrp then return end
    hrp.CFrame = CFrame.new(hrp.Position, Vector3.new(targetPos.X, hrp.Position.Y, targetPos.Z))
end

-- GOJO SYSTEM MAIN LOOP
local gojoConn = RunService.Heartbeat:Connect(function()
    GojoSystem.IsGojo = CheckIfGojo()
    if not GojoSystem.IsGojo then return end

    local in02, animTrack = Detect02DomainState()
    GojoSystem.IsIn02Domain = in02

    if in02 then
        GojoSystem.IsRushing = true
        GojoSystem.Phase = DetectPhase()

        if GojoSystem.AutoKillEnabled then
            AutoKillAll02()
        end

        if GojoSystem.InstaKillMode then
            local hrp = GetHRP()
            if hrp then
                for _, player in pairs(Players:GetPlayers()) do
                    if player == LocalPlayer then continue end
                    local targetChar = player.Character
                    if not targetChar then continue end
                    local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
                    if not targetHRP then continue end
                    local dist = (hrp.Position - targetHRP.Position).Magnitude
                    if dist <= Config.KillRange then
                        hrp.CFrame = CFrame.new(targetHRP.Position + Vector3.new(0, 2, 0))
                        SimulateKeyPress("F")
                        task.wait(0.02)
                        SimulateMouseClick(1)
                        for _, remote in pairs(ReplicatedStorage:GetDescendants()) do
                            if remote:IsA("RemoteEvent") then
                                pcall(function()
                                    remote:FireServer({["Target"] = player, ["Damage"] = 99999, ["InstaKill"] = true})
                                end)
                            end
                        end
                    end
                end
            end
        end
    else
        GojoSystem.IsRushing = false
        GojoSystem.Phase = 0
        Auto02Domain()
        AutoAwakening()
    end

    if Config.AutoPurple then
        local nearest = GetNearestPlayer(30)
        if nearest then
            FaceTarget(nearest.HRP.Position)
            SimulateKeyPress("C")
            task.wait(3)
        end
    end

    if Config.AutoRed then
        local nearest = GetNearestPlayer(25)
        if nearest then
            FaceTarget(nearest.HRP.Position)
            SimulateKeyPress("X")
            task.wait(1.5)
        end
    end

    if Config.AutoBlue then
        local nearest = GetNearestPlayer(20)
        if nearest then
            FaceTarget(nearest.HRP.Position)
            SimulateKeyPress("Z")
            task.wait(2)
        end
    end

    if Config.AutoLimitless then
        SimulateKeyPress("F")
        task.wait(5)
    end
end)
table.insert(Connections, gojoConn)

-- ANTI-CHEAT BYPASS LOOP
local acConn = RunService.Heartbeat:Connect(function()
    if not Config.AntiCheatBypass then return end
    local char = GetCharacter()
    if not char then return end
    local humanoid = GetHumanoid()
    if not humanoid then return end
    local hrp = GetHRP()
    if not hrp then return end

    if Config.SpoofValues then
        AntiCheat.SpoofedValues[humanoid] = AntiCheat.SpoofedValues[humanoid] or {}
        AntiCheat.SpoofedValues[humanoid].WalkSpeed = 16
        AntiCheat.SpoofedValues[humanoid].JumpPower = 50
    end

    if humanoid.PlatformStand and Config.HideFromAC then
        humanoid.PlatformStand = false
    end
end)
table.insert(Connections, acConn)

-- Auto Black Flash
local bfConn = RunService.Heartbeat:Connect(function()
    if not Config.AutoBlackFlash then return end
    local char = GetCharacter()
    if not char then return end
    local hrp = GetHRP()
    if not hrp then return end
    local nearest = GetNearestPlayer(Config.BlackFlashRange)
    if not nearest then return end

    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            local r, g, b = part.Color.R, part.Color.G, part.Color.B
            if r > 0.9 and g > 0.9 and b > 0.9 then
                FaceTarget(nearest.HRP.Position)
                SimulateKeyPress("F")
                task.wait(0.02)
                SimulateKeyPress("R")
                task.wait(0.02)
                SimulateKeyPress("T")
                break
            end
        end
    end
end)
table.insert(Connections, bfConn)

-- Auto Block
local BlockState = {isBlocking = false}
local blockConn = RunService.Heartbeat:Connect(function()
    if not Config.AutoBlock then return end
    local char = GetCharacter()
    if not char then return end
    local hrp = GetHRP()
    if not hrp then return end

    local targets = GetAllPlayersInRange(Config.BlockRange)
    local shouldBlock = false

    for _, target in pairs(targets) do
        local targetHumanoid = target.Character:FindFirstChildOfClass("Humanoid")
        if not targetHumanoid then continue end

        for _, anim in pairs(targetHumanoid:GetPlayingAnimationTracks()) do
            local animName = anim.Name:lower()
            if animName:find("attack") or animName:find("punch") or animName:find("slash") then
                shouldBlock = true
                break
            end
        end

        local targetHRP = target.HRP
        local velocity = targetHRP.Velocity.Magnitude
        if velocity > 25 then shouldBlock = true end

        local toUs = (hrp.Position - targetHRP.Position).Unit
        local targetLook = targetHRP.CFrame.LookVector
        if toUs:Dot(targetLook) > 0.7 then shouldBlock = true end
    end

    if shouldBlock and not BlockState.isBlocking then
        BlockState.isBlocking = true
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:SetKeyDown("Q")
        end)
    elseif not shouldBlock and BlockState.isBlocking then
        BlockState.isBlocking = false
        pcall(function()
            VirtualUser:SetKeyUp("Q")
        end)
    end
end)
table.insert(Connections, blockConn)

-- Auto Parry
local parryConn = RunService.Heartbeat:Connect(function()
    if not Config.AutoParry then return end
    local nearest = GetNearestPlayer(Config.ParryRange)
    if not nearest then return end

    local targetHumanoid = nearest.Humanoid
    if not targetHumanoid then return end

    for _, anim in pairs(targetHumanoid:GetPlayingAnimationTracks()) do
        local animName = anim.Name:lower()
        if animName:find("attack") or animName:find("punch") or animName:find("m1") then
            if anim.TimePosition > 0.1 and anim.TimePosition < 0.4 then
                FaceTarget(nearest.HRP.Position)
                SimulateKeyPress("Q")
                task.wait(0.15)
                if Config.AutoCounter then
                    SimulateMouseClick(1)
                    task.wait(0.1)
                    SimulateKeyPress("Z")
                end
            end
        end
    end
end)
table.insert(Connections, parryConn)

-- Auto Combo
local comboConn = RunService.Heartbeat:Connect(function()
    if not Config.AutoCombo then return end
    local nearest = GetNearestPlayer(Config.ComboRange)
    if not nearest then return end
    FaceTarget(nearest.HRP.Position)
    SimulateMouseClick(1)
    task.wait(Config.ComboDelay)
end)
table.insert(Connections, comboConn)

-- Auto M1 Trade
local tradeConn = RunService.Heartbeat:Connect(function()
    if not Config.AutoM1Trade then return end
    local nearest = GetNearestPlayer(8)
    if not nearest then return end

    local targetHumanoid = nearest.Humanoid
    if not targetHumanoid then return end

    for _, anim in pairs(targetHumanoid:GetPlayingAnimationTracks()) do
        if anim.Name:lower():find("attack") or anim.Name:lower():find("punch") then
            if anim.TimePosition > 0.05 and anim.TimePosition < 0.2 then
                FaceTarget(nearest.HRP.Position)
                SimulateMouseClick(1)
            end
        end
    end
end)
table.insert(Connections, tradeConn)

-- Auto Skills
local skillIndex = 1
local skillKeys = {"Z", "X", "C", "V", "B", "N"}
local skillsConn = RunService.Heartbeat:Connect(function()
    if not Config.AutoSkills then return end
    local nearest = GetNearestPlayer(30)
    if not nearest then return end
    FaceTarget(nearest.HRP.Position)
    SimulateKeyPress(skillKeys[skillIndex])
    skillIndex = skillIndex % #skillKeys + 1
    task.wait(Config.SkillDelay)
end)
table.insert(Connections, skillsConn)

-- Auto Domain
local domainConn = RunService.Heartbeat:Connect(function()
    if not Config.AutoDomain then return end
    local targets = GetAllPlayersInRange(25)
    if #targets >= 1 then
        for _, v in pairs(GetCharacter():GetDescendants()) do
            if v:IsA("NumberValue") or v:IsA("IntValue") then
                if v.Name:lower():find("awakening") or v.Name:lower():find("domain") then
                    if v.Value >= (v.MaxValue or 100) * 0.8 then
                        SimulateKeyPress("G")
                        task.wait(5)
                    end
                end
            end
        end
    end
end)
table.insert(Connections, domainConn)

-- Auto Feint
local feintConn = RunService.Heartbeat:Connect(function()
    if not Config.AutoFeint then return end
    local nearest = GetNearestPlayer(15)
    if not nearest then return end

    local targetHRP = nearest.HRP
    local targetVel = targetHRP.Velocity.Magnitude
    local hrp = GetHRP()
    if not hrp then return end

    local toUs = (hrp.Position - targetHRP.Position).Unit
    local targetLook = targetHRP.CFrame.LookVector

    if targetVel < 3 and toUs:Dot(targetLook) > 0.8 then
        SimulateKeyPress("F")
        task.wait(0.3)
        SimulateMouseClick(1)
    end
end)
table.insert(Connections, feintConn)

-- Auto Dodge
local dodgeConn = RunService.Heartbeat:Connect(function()
    if not Config.AutoDodge then return end
    local hrp = GetHRP()
    if not hrp then return end

    local targets = GetAllPlayersInRange(Config.DodgeRange)
    for _, target in pairs(targets) do
        local targetHumanoid = target.Character:FindFirstChildOfClass("Humanoid")
        if not targetHumanoid then continue end

        for _, anim in pairs(targetHumanoid:GetPlayingAnimationTracks()) do
            local animName = anim.Name:lower()
            if animName:find("attack") or animName:find("punch") or animName:find("slash") then
                if anim.TimePosition < 0.2 then
                    local dodgeDir = Vector3.new(math.random(-1, 1), 0, math.random(-1, 1)).Unit * 15
                    hrp.CFrame = hrp.CFrame + dodgeDir
                    SimulateKeyPress("Q")
                    task.wait(0.2)
                end
            end
        end

        local velocity = target.HRP.Velocity.Magnitude
        if velocity > 40 then
            local dodgeDir = (hrp.Position - target.HRP.Position).Unit * 20
            hrp.CFrame = CFrame.new(hrp.Position + dodgeDir)
            SimulateKeyPress("Q")
        end
    end
end)
table.insert(Connections, dodgeConn)

-- Anti Ragdoll
local ragdollConn = RunService.Heartbeat:Connect(function()
    if not Config.AntiRagdoll then return end
    local humanoid = GetHumanoid()
    if not humanoid then return end

    if humanoid.PlatformStand then
        humanoid.PlatformStand = false
        humanoid.Sit = false
    end

    if humanoid:GetState() == Enum.HumanoidStateType.Physics then
        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    end

    local char = GetCharacter()
    if char then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.AssemblyLinearVelocity = Vector3.new(0, math.max(0, part.AssemblyLinearVelocity.Y), 0)
                part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            end
        end
    end
end)
table.insert(Connections, ragdollConn)

-- Auto Recover
local recoverConn = RunService.Heartbeat:Connect(function()
    if not Config.AutoRecover then return end
    local humanoid = GetHumanoid()
    if not humanoid then return end

    if humanoid.PlatformStand or humanoid.Sit then
        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        task.wait(0.05)
        SimulateKeyPress("Space")
    end

    if humanoid:GetState() == Enum.HumanoidStateType.FallingDown or
       humanoid:GetState() == Enum.HumanoidStateType.Ragdoll then
        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
end)
table.insert(Connections, recoverConn)

-- Speed Hack
local speedConn = RunService.Heartbeat:Connect(function()
    local humanoid = GetHumanoid()
    if not humanoid then return end

    if Config.SpeedHack then
        humanoid.WalkSpeed = Config.WalkSpeed * 1.5
    else
        humanoid.WalkSpeed = Config.WalkSpeed
    end
    humanoid.JumpPower = Config.JumpPower
end)
table.insert(Connections, speedConn)

-- Infinite CE
local ceConn = RunService.Heartbeat:Connect(function()
    if not Config.InfCursedEnergy then return end
    local char = GetCharacter()
    if not char then return end

    for _, v in pairs(char:GetDescendants()) do
        if v:IsA("NumberValue") or v:IsA("IntValue") then
            local name = v.Name:lower()
            if name:find("energy") or name:find("ce") or name:find("cursed") or name:find("power") then
                v.Value = v.MaxValue or 999999
            end
        end
    end

    for _, v in pairs(LocalPlayer:GetDescendants()) do
        if v:IsA("NumberValue") or v:IsA("IntValue") then
            local name = v.Name:lower()
            if name:find("energy") or name:find("ce") or name:find("cursed") or name:find("power") then
                v.Value = v.MaxValue or 999999
            end
        end
    end
end)
table.insert(Connections, ceConn)

-- No Cooldowns
local cdConn = RunService.Heartbeat:Connect(function()
    if not Config.NoCooldowns then return end
    local char = GetCharacter()
    if not char then return end

    for _, v in pairs(char:GetDescendants()) do
        if v:IsA("NumberValue") or v:IsA("IntValue") then
            local name = v.Name:lower()
            if name:find("cooldown") or name:find("cd") or name:find("timer") then
                v.Value = 0
            end
        end
    end

    for _, v in pairs(LocalPlayer:GetDescendants()) do
        if v:IsA("NumberValue") or v:IsA("IntValue") then
            local name = v.Name:lower()
            if name:find("cooldown") or name:find("cd") or name:find("timer") then
                v.Value = 0
            end
        end
    end
end)
table.insert(Connections, cdConn)

-- Instant Charge
local chargeConn = RunService.Heartbeat:Connect(function()
    if not Config.InstantCharge then return end
    local char = GetCharacter()
    if not char then return end

    for _, v in pairs(char:GetDescendants()) do
        if v:IsA("NumberValue") or v:IsA("IntValue") then
            local name = v.Name:lower()
            if name:find("charge") or name:find("awakening") then
                v.Value = v.MaxValue or 100
            end
        end
    end
end)
table.insert(Connections, chargeConn)

-- Auto Dash
local dashConn = RunService.Heartbeat:Connect(function()
    if not Config.AutoDash then return end
    local hrp = GetHRP()
    if not hrp then return end

    local nearest = GetNearestPlayer(10)
    if not nearest then return end

    if nearest.Distance < 5 then
        local dashDir = (hrp.Position - nearest.HRP.Position).Unit * 10
        hrp.CFrame = CFrame.new(hrp.Position + dashDir)
        SimulateKeyPress("Q")
    end
end)
table.insert(Connections, dashConn)

-- Infinite Dash
local infDashConn = RunService.Heartbeat:Connect(function()
    if not Config.InfiniteDash then return end
    local char = GetCharacter()
    if not char then return end

    for _, v in pairs(char:GetDescendants()) do
        if v:IsA("NumberValue") or v:IsA("IntValue") then
            if v.Name:lower():find("dash") then
                v.Value = 0
            end
        end
    end
end)
table.insert(Connections, infDashConn)

-- Fly
local flyConnection
local flyConn = RunService.Heartbeat:Connect(function()
    if not Config.Fly then
        if flyConnection then flyConnection:Disconnect() flyConnection = nil end
        return
    end

    local char = GetCharacter()
    if not char then return end
    local hrp = GetHRP()
    if not hrp then return end
    local humanoid = GetHumanoid()
    if not humanoid then return end

    if not flyConnection then
        humanoid.PlatformStand = true
        local bodyGyro = Instance.new("BodyGyro")
        bodyGyro.Name = "FlyGyro"
        bodyGyro.Parent = hrp
        bodyGyro.MaxTorque = Vector3.new(400000, 400000, 400000)
        bodyGyro.P = 10000

        local bodyVel = Instance.new("BodyVelocity")
        bodyVel.Name = "FlyVel"
        bodyVel.Parent = hrp
        bodyVel.MaxForce = Vector3.new(400000, 400000, 400000)
        bodyVel.Velocity = Vector3.new(0, 0, 0)

        flyConnection = RunService.RenderStepped:Connect(function()
            if not Config.Fly then return end
            local cam = Camera
            local dir = Vector3.new(0, 0, 0)

            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0, 1, 0) end

            if dir.Magnitude > 0 then dir = dir.Unit * 60 end
            bodyVel.Velocity = dir
            bodyGyro.CFrame = cam.CFrame
        end)
    end
end)
table.insert(Connections, flyConn)

-- Noclip
local noclipConnection
local noclipConn = RunService.Heartbeat:Connect(function()
    if not Config.Noclip then
        if noclipConnection then noclipConnection:Disconnect() noclipConnection = nil end
        return
    end

    if not noclipConnection then
        noclipConnection = RunService.Stepped:Connect(function()
            if not Config.Noclip then return end
            local char = GetCharacter()
            if not char then return end
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end)
    end
end)
table.insert(Connections, noclipConn)

-- Click TP
local clickTPConn = Mouse.Button1Down:Connect(function()
    if not Config.ClickTP then return end
    if not UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then return end

    local hrp = GetHRP()
    if not hrp then return end

    local ray = Camera:ViewportPointToRay(Mouse.X, Mouse.Y)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = {GetCharacter()}

    local result = Workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
    if result then
        hrp.CFrame = CFrame.new(result.Position + Vector3.new(0, 3, 0))
    end
end)
table.insert(Connections, clickTPConn)


-- ESP
local ESPObjects = {}
local espConn = RunService.RenderStepped:Connect(function()
    if not Config.ESP then
        for player, _ in pairs(ESPObjects) do
            for _, obj in pairs(ESPObjects[player]) do
                if typeof(obj) == "Instance" then obj:Destroy()
                elseif typeof(obj) == "table" and obj.Remove then obj:Remove() end
            end
        end
        ESPObjects = {}
        return
    end

    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end

        local char = player.Character
        if not char then
            if ESPObjects[player] then
                for _, obj in pairs(ESPObjects[player]) do
                    if typeof(obj) == "Instance" then obj:Destroy()
                    elseif typeof(obj) == "table" and obj.Remove then obj:Remove() end
                end
                ESPObjects[player] = nil
            end
            continue
        end

        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end

        local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
        if dist > Config.ESPRange then
            if ESPObjects[player] then
                for _, obj in pairs(ESPObjects[player]) do
                    if typeof(obj) == "Instance" then obj:Destroy()
                    elseif typeof(obj) == "table" and obj.Remove then obj:Remove() end
                end
                ESPObjects[player] = nil
            end
            continue
        end

        if not ESPObjects[player] then
            ESPObjects[player] = {}

            local highlight = Instance.new("Highlight")
            highlight.Name = "JJS_ESP"
            highlight.Parent = char
            highlight.FillColor = Color3.fromRGB(255, 0, 0)
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            highlight.FillTransparency = 0.7
            highlight.OutlineTransparency = 0
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            table.insert(ESPObjects[player], highlight)

            if Config.ESPTracers then
                local tracer = Drawing.new("Line")
                tracer.Visible = false
                tracer.Thickness = 1.5
                tracer.Color = Color3.fromRGB(180, 120, 255)
                tracer.Transparency = 0.8
                ESPObjects[player].Tracer = tracer
            end

            if Config.ESPDistance then
                local distLabel = Drawing.new("Text")
                distLabel.Visible = false
                distLabel.Size = 14
                distLabel.Color = Color3.fromRGB(255, 255, 255)
                distLabel.Outline = true
                distLabel.OutlineColor = Color3.fromRGB(0, 0, 0)
                distLabel.Center = true
                ESPObjects[player].Distance = distLabel
            end

            if Config.ESPHealth then
                local healthLabel = Drawing.new("Text")
                healthLabel.Visible = false
                healthLabel.Size = 12
                healthLabel.Color = Color3.fromRGB(78, 204, 163)
                healthLabel.Outline = true
                healthLabel.OutlineColor = Color3.fromRGB(0, 0, 0)
                healthLabel.Center = true
                ESPObjects[player].Health = healthLabel
            end
        end

        if Config.ESPTracers and ESPObjects[player].Tracer then
            local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            if onScreen then
                ESPObjects[player].Tracer.Visible = true
                ESPObjects[player].Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                ESPObjects[player].Tracer.To = Vector2.new(screenPos.X, screenPos.Y)
            else
                ESPObjects[player].Tracer.Visible = false
            end
        end

        if Config.ESPDistance and ESPObjects[player].Distance then
            local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 3, 0))
            if onScreen then
                ESPObjects[player].Distance.Visible = true
                ESPObjects[player].Distance.Position = Vector2.new(screenPos.X, screenPos.Y)
                ESPObjects[player].Distance.Text = math.floor(dist) .. "m"
            else
                ESPObjects[player].Distance.Visible = false
            end
        end

        if Config.ESPHealth and ESPObjects[player].Health then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid then
                local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 4.5, 0))
                if onScreen then
                    ESPObjects[player].Health.Visible = true
                    ESPObjects[player].Health.Position = Vector2.new(screenPos.X, screenPos.Y)
                    local hp = math.floor((humanoid.Health / humanoid.MaxHealth) * 100)
                    ESPObjects[player].Health.Text = hp .. "% HP"
                    if hp > 50 then
                        ESPObjects[player].Health.Color = Color3.fromRGB(78, 204, 163)
                    elseif hp > 25 then
                        ESPObjects[player].Health.Color = Color3.fromRGB(255, 200, 0)
                    else
                        ESPObjects[player].Health.Color = Color3.fromRGB(233, 69, 96)
                    end
                else
                    ESPObjects[player].Health.Visible = false
                end
            end
        end
    end
end)
table.insert(Connections, espConn)

local addedConn = Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(1)
    end)
end)
table.insert(Connections, addedConn)

-- Hitbox Expander
local HitboxObjects = {}
local hitboxConn = RunService.Heartbeat:Connect(function()
    if not Config.HitboxExpander then
        for player, _ in pairs(HitboxObjects) do
            local char = player.Character
            if char then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.Size = Vector3.new(2, 2, 1)
                    hrp.Transparency = 1
                end
            end
        end
        HitboxObjects = {}
        return
    end

    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local char = player.Character
        if not char then continue end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end

        hrp.Size = Vector3.new(Config.HitboxSize, Config.HitboxSize, Config.HitboxSize)
        hrp.Transparency = 0.7
        hrp.CanCollide = false
        HitboxObjects[player] = true
    end
end)
table.insert(Connections, hitboxConn)

-- Full Bright + No Fog
local fbConn = RunService.Heartbeat:Connect(function()
    if Config.FullBright then
        Lighting.Brightness = 10
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    end

    if Config.NoFog then
        Lighting.FogStart = 0
        Lighting.FogEnd = 100000
        Lighting.FogColor = Color3.fromRGB(255, 255, 255)
    end
end)
table.insert(Connections, fbConn)

-- Anti AFK
local afkConn = LocalPlayer.Idled:Connect(function()
    if Config.AntiAFK then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)
table.insert(Connections, afkConn)

-- Auto Click
local acConn2 = RunService.Heartbeat:Connect(function()
    if not Config.AutoClick then return end
    SimulateMouseClick(1)
    task.wait(0.05)
end)
table.insert(Connections, acConn2)

-- ═══════════════════════════════════════════════════════════════
-- INIT ANTI-CHEAT BYPASS
-- ═══════════════════════════════════════════════════════════════

pcall(AntiFlyBypass)
pcall(SpoofHumanoidState)
pcall(HideFromDetection)

-- ═══════════════════════════════════════════════════════════════
-- NOTIFICATION
-- ═══════════════════════════════════════════════════════════════

local Notif = Instance.new("Frame")
Notif.Parent = ScreenGui
Notif.BackgroundColor3 = Color3.fromRGB(8, 8, 16)
Notif.BorderSizePixel = 0
Notif.Position = UDim2.new(0.5, -170, 0, -100)
Notif.Size = UDim2.new(0, 340, 0, 75)
Notif.AnchorPoint = Vector2.new(0.5, 0)

local NC = Instance.new("UICorner")
NC.CornerRadius = UDim.new(0, 14)
NC.Parent = Notif

local NS = Instance.new("UIStroke")
NS.Color = Color3.fromRGB(180, 120, 255)
NS.Thickness = 2
NS.Parent = Notif

local NT = Instance.new("TextLabel")
NT.Parent = Notif
NT.BackgroundTransparency = 1
NT.Size = UDim2.new(1, 0, 0.5, 0)
NT.Position = UDim2.new(0, 0, 0, 8)
NT.Font = Enum.Font.GothamBold
NT.Text = "✅ JJS HUB V3 — GOD MODE"
NT.TextColor3 = Color3.fromRGB(180, 120, 255)
NT.TextSize = 18

local NT2 = Instance.new("TextLabel")
NT2.Parent = Notif
NT2.BackgroundTransparency = 1
NT2.Size = UDim2.new(1, 0, 0.35, 0)
NT2.Position = UDim2.new(0, 0, 0.5, 0)
NT2.Font = Enum.Font.Gotham
NT2.Text = "Anti-Cheat Bypassed | Gojo 0.2 Auto Kill | 30+ Features"
NT2.TextColor3 = Color3.fromRGB(180, 180, 210)
NT2.TextSize = 11

Notif:TweenPosition(UDim2.new(0.5, -170, 0, 30), Enum.EasingDirection.Out, Enum.EasingStyle.Back, 0.6, true)

delay(5, function()
    Notif:TweenPosition(UDim2.new(0.5, -170, 0, -100), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.5, true)
    task.wait(0.5)
    Notif:Destroy()
end)

-- ═══════════════════════════════════════════════════════════════
-- CONSOLE LOG
-- ═══════════════════════════════════════════════════════════════

print("╔═══════════════════════════════════════════════════════════════╗")
print("║           JJS HUB V3 — GOD MODE EDITION                       ║")
print("╠═══════════════════════════════════════════════════════════════╣")
print("║  [GOJO]    Auto 0.2 Domain | Auto Kill All | Insta Kill       ║")
print("║            Auto Purple | Auto Red | Auto Blue | Auto Limitless║")
print("╠═══════════════════════════════════════════════════════════════╣")
print("║  [AC]      Metatable Hook | Remote Block | Value Spoof        ║")
print("║            Fly Bypass | State Spoof | Network Hide            ║")
print("╠═══════════════════════════════════════════════════════════════╣")
print("║  [COMBAT]  Auto BF | Auto BF Chain | Auto Block | Auto Parry  ║")
print("║            Auto Counter | Auto Combo | Auto M1 Trade          ║")
print("║            Auto Skills | Auto Domain | Auto Feint             ║")
print("╠═══════════════════════════════════════════════════════════════╣")
print("║  [DEFENSE] Auto Dodge | Anti Ragdoll | Auto Recover           ║")
print("║            Infinite CE | No Cooldowns | Instant Charge        ║")
print("╠═══════════════════════════════════════════════════════════════╣")
print("║  [MOVE]    Speed Hack | Auto Dash | Infinite Dash | Fly       ║")
print("║            Noclip | Click TP                                  ║")
print("╠═══════════════════════════════════════════════════════════════╣")
print("║  [VISUAL]  ESP | Tracers | Distance | Health | Hitbox         ║")
print("║            Full Bright | No Fog                               ║")
print("╠═══════════════════════════════════════════════════════════════╣")
print("║  [MISC]    Anti AFK | Auto Click | Copy Loadstring            ║")
print("╚═══════════════════════════════════════════════════════════════╝")

═══════════════════════════════════════════════════════════════════
END OF SCRIPT
═══════════════════════════════════════════════════════════════════
