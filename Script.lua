-- // [1] SERVICES //
local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService   = game:GetService("TweenService")
local Lighting       = game:GetService("Lighting")
local HttpService    = game:GetService("HttpService")

local LocalPlayer    = Players.LocalPlayer

-- // [2] CONFIGURATION //
local CONFIG = {
    Names = {
        ScreenGui  = "TRUBL",
        MainFrame  = "IslandDropDown",
    },
    Colors = {
        Background  = Color3.fromRGB(28, 29, 28),
        Stroke      = Color3.fromRGB(200, 0, 0),
        ScrollBar   = Color3.fromRGB(200, 0, 0),
        RowBG       = Color3.fromRGB(28, 29, 28),
        RowStrokeOn = Color3.fromRGB(255, 31, 30),
        RowStrokeOff= Color3.fromRGB(55, 0, 0),
        Text        = Color3.fromRGB(255, 255, 255),
        SubText     = Color3.fromRGB(110, 110, 110),
        KeyBindBG   = Color3.fromRGB(28, 29, 28),
        ActiveMode  = Color3.fromRGB(200, 0, 0),
        InactiveMode= Color3.fromRGB(55, 0, 0),
        ProgressFill= Color3.fromRGB(180, 0, 0),
    },
    Size = {
        MainFrame   = UDim2.new(0, 300, 0, 600),
        RowHeight   = 42,
        SubPanelH   = 46,
    },
    Position = {
        MainFrame   = UDim2.new(0, 10, 0, 80),
    },
    Speed = {
        Normal      = 60,
        Carry       = 30,
        LaggerNormal= 15,
        LaggerCarry = 24.5,
    },
    Steal = {
        Radius      = 120,
        Duration    = 1.4,
    },
    AutoTP = {
        Height      = 20,
    },
    AutoBat = {
        Speed       = 58,
        VertSpeed   = 52,
        Dist        = -2.8,
        Height      = 4.75,
        VertOffset  = 1,
        TurnSpeed   = 285,
        MaxTurnRate = 28,
    },
    Discord     = "discord.gg/trubl",
    HubName     = "TRUBL",
    SaveFile    = "trubl_config.json",
}

-- // [3] OBJECT REFERENCES //
local ScreenGui
local MainFrame
local ScrollingFrame
local FpsLabel
local PingLabel
local TitleLabel
local RadiusBox
local HeaderClickArea

-- Row frame references (for toggle/chevron access)
local Rows = {}         -- Rows["Normal Speed"] = { frame, stroke, subPanel, chevronBtn, ... }

-- Visual setter functions (set by GUI builder)
local setNormalSpeedVisual
local setCarrySpeedVisual
local setAutoPlayLVisual
local setAutoStealVisual
local setAutoPlayAfterTimerVisual
local setAimbot1Visual
local setAimbot2Visual
local setStealSpeedVisual
local setAntiKickVisual
local setAutoTPVisual
local setInfiniteJumpVisual
local setFloatVisual
local setTPDownVisual
local setCounterBatVisual
local setAimbotRadiusVisual
local setMedVisual
local setMedusaCounterVisual
local setAutoPlayAfterMedVisual
local setDropBrainrotVisual
local setInstantResetVisual
local setNoPlayerCollisionVisual
local setFPSBoostVisual
local setNoAnimationVisual
local setPlayerESPVisual
local setFOVVisual
local setNightSkyVisual
local setTauntVisual

-- Progress bar references
local ProgressFill
local ProgressPct
local ProgressRadLbl
local ModeLabel

-- Input boxes
local NormalSpdBox
local CarrySpdBox
local LaggerSpdBox
local LaggerCarrySpdBox
local RadiusInput
local AutoTPHeightBox
local FOVBox
local NightDarknessBox
local OverheadSizeBox
local _btnsDraggable = true  -- toggled by Draggable Buttons setting

-- // [4] UTILITY FUNCTIONS //

local speedMode          = false
local laggerToggled      = false
local laggerPhase        = 0
local antiRagdollEnabled = false
local infJumpEnabled     = false
local medusaCounterEnabled = false
local batCounterEnabled  = false
local unwalkEnabled      = false
local autoBatEnabled     = false
local autoSwingEnabled   = true
local autoLeftEnabled    = false
local autoRightEnabled   = false
local autoTPEnabled      = false
local autoTPHeight       = CONFIG.AutoTP.Height
local antiLagEnabled     = false
local stretchRezEnabled  = false
local dropActive         = false
local medusaDebounce     = false
local medusaLastUsed     = 0
local isStealing         = false
local stealStartTime     = nil
local batCounterDebounce = false
local unwalkSavedAnimate = nil
local _anyKeyListening   = false
local holdJumpPressed    = false
local holdJumpActive     = false
local lastMoveDir        = Vector3.new(0, 0, 0)
local cursedResetRemote  = nil
local CURSED_RESET_GUID  = "f888ee6e-c86d-46e1-93d7-0639d6635d42"
local MEDUSA_COOLDOWN    = 25
local removeAccessoriesEnabled = false
local antiLagDescConn    = nil
local stretchRezConn     = nil
local defLightBrightness, defLightClock, defLightAmbient
local autoBatEquippedThisRun = false
local _autoBatTarget     = nil
local _autoBatLastScan   = 0
local resetAutoBatMotion = nil
local autoLeftSetVisual, autoRightSetVisual, autoBatSetVisual
local setBatCounterVisual
local startBatCounter, stopBatCounter
local setInstaGrab, setInfJumpVisual, setAntiRagVisual, setMedusaVisual
local setUnwalkVisual, setAntiLagVisual, setAutoSwingVisual, setStretchRezVisual
local autoTPConn         = nil
local alConn, arConn     = nil, nil
local alPhase, arPhase   = 1, 1
local _autoTPWasEnabled  = false
local speedLabel         = nil
local modeValLbl         = nil
local _wfConns           = {}

local NS = CONFIG.Speed.Normal
local CS = CONFIG.Speed.Carry
local LAGGER_SPEED       = CONFIG.Speed.LaggerNormal
local LAGGER_CARRY_SPEED = CONFIG.Speed.LaggerCarry

local Steal = {
    AutoStealEnabled = false,
    StealRadius      = CONFIG.Steal.Radius,
    StealDuration    = CONFIG.Steal.Duration,
    Data             = {},
}

local Conns = {
    autoSteal  = nil,
    antiRag    = nil,
    batCounter = nil,
    anchor     = {},
    progress   = nil,
}

local KB = {
    DropBrainrot = { kb = Enum.KeyCode.X, gp = nil },
    AutoLeft     = { kb = Enum.KeyCode.Z, gp = nil },
    AutoRight    = { kb = Enum.KeyCode.C, gp = nil },
    AutoBat      = { kb = Enum.KeyCode.E, gp = nil },
    TPFloor      = { kb = Enum.KeyCode.F, gp = nil },
    InstaReset   = { kb = Enum.KeyCode.T, gp = nil },
    GuiHide      = { kb = Enum.KeyCode.LeftControl, gp = nil },
    SpeedToggle  = { kb = Enum.KeyCode.Q, gp = nil },
    LaggerToggle = { kb = Enum.KeyCode.R, gp = nil },
}

local AP_L1 = Vector3.new(-476.47, -6.28,  92.73)
local AP_L2 = Vector3.new(-483.12, -4.95,  94.81)
local AP_R1 = Vector3.new(-476.16, -6.52,  25.62)
local AP_R2 = Vector3.new(-483.06, -5.03,  25.48)

local MOVE_KEYS = {
    [Enum.KeyCode.W] = true, [Enum.KeyCode.A] = true,
    [Enum.KeyCode.S] = true, [Enum.KeyCode.D] = true,
    [Enum.KeyCode.Up] = true, [Enum.KeyCode.Left] = true,
    [Enum.KeyCode.Down] = true, [Enum.KeyCode.Right] = true,
}

local BAT_COUNTER_SLAP_LIST = {
    "Bat","Slap","Iron Slap","Gold Slap","Diamond Slap","Emerald Slap",
    "Ruby Slap","Dark Matter Slap","Flame Slap","Nuclear Slap","Galaxy Slap","Glitched Slap"
}

local function getActiveMoveSpeed()
    return laggerToggled
        and (laggerPhase == 2 and LAGGER_CARRY_SPEED or LAGGER_SPEED)
        or  (speedMode and CS or NS)
end

local function getAutoPathSpeed()
    return laggerToggled and LAGGER_SPEED or NS
end

local function isRagdollState(hum)
    if not hum then return true end
    local st = hum:GetState()
    return hum.PlatformStand
        or st == Enum.HumanoidStateType.Physics
        or st == Enum.HumanoidStateType.Ragdoll
        or st == Enum.HumanoidStateType.FallingDown
end

local function getHRP()
    local char = LocalPlayer.Character
    if not char then return end
    return char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local char = LocalPlayer.Character
    if not char then return end
    return char:FindFirstChildOfClass("Humanoid")
end

local function isMyPlotByName(plotName)
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return false end
    local plot = plots:FindFirstChild(plotName)
    if not plot then return false end
    local sign = plot:FindFirstChild("PlotSign")
    if sign then
        local yb = sign:FindFirstChild("YourBase")
        if yb and yb:IsA("BillboardGui") then
            return yb.Enabled == true
        end
    end
    return false
end

local function resetProgressBar()
    if ProgressPct  then ProgressPct.Text             = "0%" end
    if ProgressFill then ProgressFill.Size             = UDim2.new(0, 0, 1, 0) end
end

local function refreshSpeedModeLabel()
    if modeValLbl then
        modeValLbl.Text = laggerToggled
            and (laggerPhase == 2 and "Lagger Carry" or "Lagger Normal")
            or  (speedMode and "Carry" or "Normal")
    end
end

local function toggleCarryMode()
    if laggerToggled then
        laggerToggled = false
        laggerPhase   = 0
        speedMode     = true
    else
        speedMode = not speedMode
    end
    refreshSpeedModeLabel()
end

local function toggleLaggerMode()
    if not laggerToggled then
        speedMode     = false
        laggerToggled = true
        laggerPhase   = 2
    elseif laggerPhase == 2 then
        laggerPhase   = 1
    else
        laggerPhase   = 2
    end
    refreshSpeedModeLabel()
end

local function kbMatch(entry, kc)
    return kc and (kc == entry.kb or (entry.gp and kc == entry.gp))
end

-- Runtime save-able UI state (filled in by GUI builders)
local _circleBtnPositions = {}  -- key -> {x=, y=}  (absolute offsets)
local _savedBtnSize  = 92
local _savedGuiScale = 1.0

local function saveConfig()
    local function ks(e) return { kb = e.kb and e.kb.Name or nil, gp = e.gp and e.gp.Name or nil } end
    local cfg = {
        normalSpeed       = NS,
        carrySpeed        = CS,
        laggerSpeed       = LAGGER_SPEED,
        laggerCarrySpeed  = LAGGER_CARRY_SPEED,
        dropBrainrotKey   = ks(KB.DropBrainrot),
        autoLeftKey       = ks(KB.AutoLeft),
        autoRightKey      = ks(KB.AutoRight),
        autoBatKey        = ks(KB.AutoBat),
        laggerToggleKey   = ks(KB.LaggerToggle),
        tpFloorKey        = ks(KB.TPFloor),
        instaResetKey     = ks(KB.InstaReset),
        guiHideKey        = ks(KB.GuiHide),
        speedToggleKey    = ks(KB.SpeedToggle),
        grabRadius        = Steal.StealRadius,
        stealDuration     = Steal.StealDuration,
        antiRagdoll       = antiRagdollEnabled,
        autoStealEnabled  = Steal.AutoStealEnabled,
        infiniteJump      = infJumpEnabled,
        medusaCounter     = medusaCounterEnabled,
        batCounter        = batCounterEnabled,
        carryMode         = speedMode,
        laggerMode        = laggerToggled,
        laggerCarryMode   = laggerPhase == 2,
        autoBat           = autoBatEnabled,
        autoSwing         = autoSwingEnabled,
        unwalkEnabled     = unwalkEnabled,
        antiLag           = antiLagEnabled,
        stretchRez        = stretchRezEnabled,
        autoTPEnabled     = autoTPEnabled,
        autoTPHeight      = autoTPHeight,
        -- NEW: UI layout
        circleBtnPositions = _circleBtnPositions,
        btnSize            = _savedBtnSize,
        guiScale           = _savedGuiScale,
    }
    if writefile then
        pcall(function() writefile(CONFIG.SaveFile, HttpService:JSONEncode(cfg)) end)
    end
end

-- Speed indicator billboard on head
local function setupSpeedIndicator(char)
    local head = char and char:WaitForChild("Head", 5)
    if not head then return end
    -- remove old
    local oldBb = head:FindFirstChild("TrublSpeedBB")
    if oldBb then oldBb:Destroy() end
    local bb = Instance.new("BillboardGui", head)
    bb.Name          = "TrublSpeedBB"
    bb.Size          = UDim2.new(0, 160, 0, 44)
    bb.StudsOffset   = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop   = true
    bb.ResetOnSpawn  = false
    speedLabel       = Instance.new("TextLabel", bb)
    speedLabel.Size  = UDim2.new(1, 0, 0.55, 0)
    speedLabel.BackgroundTransparency = 1
    speedLabel.Text  = "Speed: 0"
    speedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    speedLabel.Font  = Enum.Font.GothamBold
    speedLabel.TextScaled = true
    speedLabel.TextStrokeTransparency = 0
    speedLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    local discLbl    = Instance.new("TextLabel", bb)
    discLbl.Size     = UDim2.new(1, 0, 0.45, 0)
    discLbl.Position = UDim2.new(0, 0, 0.55, 0)
    discLbl.BackgroundTransparency = 1
    discLbl.Text     = CONFIG.Discord
    discLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
    discLbl.Font     = Enum.Font.GothamBold
    discLbl.TextScaled = true
    discLbl.TextStrokeTransparency = 0
    discLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    -- self-healing: recreate if destroyed
    bb.AncestryChanged:Connect(function()
        if not bb.Parent then
            task.wait(0.3)
            if LocalPlayer.Character == char then
                setupSpeedIndicator(char)
            end
        end
    end)
end

-- Anti Ragdoll
local function startAntiRagdoll()
    if Conns.antiRag then return end
    Conns.antiRag = RunService.Heartbeat:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        local hum  = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if hum then
            local st = hum:GetState()
            if st == Enum.HumanoidStateType.Physics
            or st == Enum.HumanoidStateType.Ragdoll
            or st == Enum.HumanoidStateType.FallingDown then
                hum:ChangeState(Enum.HumanoidStateType.Running)
                workspace.CurrentCamera.CameraSubject = hum
                pcall(function()
                    local pm = LocalPlayer.PlayerScripts:FindFirstChild("PlayerModule")
                    if pm then require(pm:FindFirstChild("ControlModule")):Enable() end
                end)
                if root then root.Velocity = Vector3.zero; root.RotVelocity = Vector3.zero end
            end
        end
        for _, obj in ipairs(char:GetDescendants()) do
            if obj:IsA("Motor6D") and not obj.Enabled then obj.Enabled = true end
        end
    end)
end

local function stopAntiRagdoll()
    if Conns.antiRag then Conns.antiRag:Disconnect(); Conns.antiRag = nil end
end

-- Infinite Jump
local function applyInfJumpBoost(boost)
    if not infJumpEnabled then return end
    local root = getHRP()
    if root then root.Velocity = Vector3.new(root.Velocity.X, boost, root.Velocity.Z) end
end

UserInputService.JumpRequest:Connect(function()
    applyInfJumpBoost(50)
end)

UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Keyboard
    and input.KeyCode == Enum.KeyCode.Space
    and not UserInputService:GetFocusedTextBox() then
        holdJumpPressed = true
        task.delay(0.12, function()
            if holdJumpPressed then
                holdJumpActive = true
                applyInfJumpBoost(50)
            end
        end)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Keyboard
    and input.KeyCode == Enum.KeyCode.Space then
        holdJumpPressed = false
        holdJumpActive  = false
    end
end)

RunService.Heartbeat:Connect(function()
    if holdJumpActive then applyInfJumpBoost(50) end
end)

-- Unwalk
local function startUnwalk()
    local c = LocalPlayer.Character
    if not c then return end
    local hum = c:FindFirstChildOfClass("Humanoid")
    if hum then
        for _, t in ipairs(hum:GetPlayingAnimationTracks()) do t:Stop() end
    end
    local anim = c:FindFirstChild("Animate")
    if anim then unwalkSavedAnimate = anim:Clone(); anim:Destroy() end
end

local function stopUnwalk()
    local c = LocalPlayer.Character
    if c and unwalkSavedAnimate then
        unwalkSavedAnimate:Clone().Parent = c
        unwalkSavedAnimate = nil
    end
end

-- Drop Brainrot
local function runDrop()
    if dropActive then return end
    if autoBatEnabled then
        autoBatEnabled = false
        if resetAutoBatMotion then resetAutoBatMotion() end
        if autoBatSetVisual then autoBatSetVisual(false) end
    end
    dropActive = true
    local colConn = RunService.Stepped:Connect(function()
        if not dropActive then return end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                for _, part in ipairs(p.Character:GetChildren()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end
    end)
    table.insert(_wfConns, colConn)
    local flingThread = coroutine.create(function()
        while dropActive do
            RunService.Heartbeat:Wait()
            local c    = LocalPlayer.Character
            local root = c and c:FindFirstChild("HumanoidRootPart")
            if not root then break end
            local vel = root.Velocity
            root.Velocity = vel * 10000 + Vector3.new(0, 10000, 0)
            RunService.RenderStepped:Wait()
            if root and root.Parent then root.Velocity = vel end
            RunService.Stepped:Wait()
            if root and root.Parent then root.Velocity = vel + Vector3.new(0, 0.1, 0) end
        end
    end)
    table.insert(_wfConns, flingThread)
    coroutine.resume(flingThread)
    task.delay(0.1, function()
        dropActive = false
        for _, c in ipairs(_wfConns) do
            if typeof(c) == "RBXScriptConnection" then c:Disconnect()
            elseif type(c) == "thread" then pcall(coroutine.close, c) end
        end
        _wfConns = {}
    end)
end

-- Auto TP Down
local function doAutoTPDown(force)
    local char = LocalPlayer.Character
    if not char then return end
    local hrp  = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local hum2 = char:FindFirstChildOfClass("Humanoid")
    if not hum2 then return end
    if not force then
        if hum2.FloorMaterial ~= Enum.Material.Air then return end
        if hrp.Position.Y < autoTPHeight then return end
    end
    hrp.CFrame = CFrame.new(hrp.Position.X, -7.00, hrp.Position.Z)
        * CFrame.Angles(0, select(2, hrp.CFrame:ToEulerAnglesYXZ()), 0)
    hrp.AssemblyLinearVelocity = Vector3.zero
end

local function startAutoTP()
    if autoTPConn then task.cancel(autoTPConn); autoTPConn = nil end
    autoTPConn = task.spawn(function()
        while autoTPEnabled do
            task.wait(0.1)
            pcall(function() doAutoTPDown(false) end)
        end
    end)
end

local function stopAutoTP()
    autoTPEnabled = false
    if autoTPConn then task.cancel(autoTPConn); autoTPConn = nil end
end

local function runTPFloor()
    pcall(function() doAutoTPDown(true) end)
end

-- Stretch Rez (FOV)
local function enableStretchRez()
    stretchRezEnabled = true
    workspace.CurrentCamera.FieldOfView = 107
    if stretchRezConn then stretchRezConn:Disconnect() end
    stretchRezConn = RunService.RenderStepped:Connect(function()
        if not stretchRezEnabled then
            stretchRezConn:Disconnect(); stretchRezConn = nil; return
        end
        workspace.CurrentCamera.FieldOfView = 107
    end)
end

local function disableStretchRez()
    stretchRezEnabled = false
    if stretchRezConn then stretchRezConn:Disconnect(); stretchRezConn = nil end
    workspace.CurrentCamera.FieldOfView = 70
end

-- Anti Lag / FPS Boost
local function applyAntiLagDerender(obj)
    pcall(function()
        if obj:IsA("Accessory") or obj:IsA("Hat") then
            obj:Destroy()
        elseif obj:IsA("BasePart") then
            obj.Material = Enum.Material.Plastic
            obj.Reflectance = 0
            obj.CastShadow = false
        elseif obj:IsA("Decal") or obj:IsA("Texture") then
            obj.Transparency = 1
        elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam")
            or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
            obj.Enabled = false
        elseif obj:IsA("AnimationController") or obj:IsA("Animator") then
            for _, t in ipairs(obj:GetPlayingAnimationTracks()) do
                pcall(function() t:Stop(0) end)
            end
        end
    end)
end

local function enableAntiLag()
    removeAccessoriesEnabled = true
    antiLagEnabled           = true
    defLightBrightness = defLightBrightness or Lighting.Brightness
    defLightClock      = defLightClock      or Lighting.ClockTime
    defLightAmbient    = defLightAmbient    or Lighting.OutdoorAmbient
    Lighting.GlobalShadows            = false
    Lighting.FogEnd                   = 1e10
    Lighting.Brightness               = 1
    Lighting.EnvironmentDiffuseScale  = 0
    Lighting.EnvironmentSpecularScale = 0
    for _, e in pairs(Lighting:GetChildren()) do
        pcall(function()
            if e:IsA("BlurEffect") or e:IsA("SunRaysEffect")
            or e:IsA("ColorCorrectionEffect") or e:IsA("BloomEffect")
            or e:IsA("DepthOfFieldEffect") then
                e.Enabled = false
            end
        end)
    end
    for _, obj in ipairs(workspace:GetDescendants()) do
        applyAntiLagDerender(obj)
    end
    if antiLagDescConn then antiLagDescConn:Disconnect() end
    antiLagDescConn = workspace.DescendantAdded:Connect(function(obj)
        if removeAccessoriesEnabled then applyAntiLagDerender(obj) end
    end)
end

local function disableAntiLag()
    removeAccessoriesEnabled = false
    antiLagEnabled           = false
    if antiLagDescConn then antiLagDescConn:Disconnect(); antiLagDescConn = nil end
    pcall(function()
        if defLightBrightness then Lighting.Brightness     = defLightBrightness end
        if defLightClock      then Lighting.ClockTime      = defLightClock      end
        if defLightAmbient    then Lighting.OutdoorAmbient = defLightAmbient    end
        Lighting.ExposureCompensation = 0
    end)
end

-- Medusa Counter
local function findMedusa()
    local c = LocalPlayer.Character
    if not c then return nil end
    for _, t in ipairs(c:GetChildren()) do
        if t:IsA("Tool") then
            local n = t.Name:lower()
            if n:find("medusa") or n:find("head") or n:find("stone") then return t end
        end
    end
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") then
                local n = t.Name:lower()
                if n:find("medusa") or n:find("head") or n:find("stone") then return t end
            end
        end
    end
    return nil
end

local function useMedusaCounter()
    if medusaDebounce then return end
    if tick() - medusaLastUsed < MEDUSA_COOLDOWN then return end
    local c = LocalPlayer.Character
    if not c then return end
    medusaDebounce = true
    local med = findMedusa()
    if not med then medusaDebounce = false; return end
    if med.Parent ~= c then
        local hum2 = c:FindFirstChildOfClass("Humanoid")
        if hum2 then hum2:EquipTool(med) end
    end
    pcall(function() med:Activate() end)
    medusaLastUsed = tick()
    medusaDebounce = false
end

local function onAnchorChanged(part)
    return part:GetPropertyChangedSignal("Anchored"):Connect(function()
        if part.Anchored and part.Transparency == 1 then useMedusaCounter() end
    end)
end

local function setupMedusa(char)
    for _, c in pairs(Conns.anchor) do pcall(function() c:Disconnect() end) end
    Conns.anchor = {}
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            table.insert(Conns.anchor, onAnchorChanged(part))
        end
    end
    table.insert(Conns.anchor, char.DescendantAdded:Connect(function(part)
        if part:IsA("BasePart") then
            table.insert(Conns.anchor, onAnchorChanged(part))
        end
    end))
end

local function stopMedusaCounter()
    for _, c in pairs(Conns.anchor) do pcall(function() c:Disconnect() end) end
    Conns.anchor = {}
end

-- Bat Counter
local function findBatForCounter()
    local c  = LocalPlayer.Character
    if not c then return nil end
    local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
    for _, name in ipairs(BAT_COUNTER_SLAP_LIST) do
        local t = c:FindFirstChild(name) or (bp and bp:FindFirstChild(name))
        if t then return t end
    end
    for _, ch in ipairs(c:GetChildren()) do
        if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end
    end
    if bp then
        for _, ch in ipairs(bp:GetChildren()) do
            if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end
        end
    end
    return nil
end

local function swingBatForCounter(bat, char)
    local hum2 = char:FindFirstChildOfClass("Humanoid")
    if bat.Parent ~= char then
        if hum2 then pcall(function() hum2:EquipTool(bat) end) end
        task.wait(0.05)
    end
    local remote = bat:FindFirstChildOfClass("RemoteEvent") or bat:FindFirstChildOfClass("RemoteFunction")
    if remote and remote:IsA("RemoteEvent") then
        pcall(function() remote:FireServer() end)
        task.wait(0.15)
        pcall(function() remote:FireServer() end)
    else
        pcall(function() bat:Activate() end)
        task.wait(0.15)
        pcall(function() bat:Activate() end)
    end
end

startBatCounter = function()
    if Conns.batCounter then return end
    Conns.batCounter = RunService.Heartbeat:Connect(function()
        if not batCounterEnabled then return end
        if batCounterDebounce then return end
        local char = LocalPlayer.Character
        if not char then return end
        local hum2 = char:FindFirstChildOfClass("Humanoid")
        if not hum2 then return end
        local st = hum2:GetState()
        if st == Enum.HumanoidStateType.Physics
        or st == Enum.HumanoidStateType.Ragdoll
        or st == Enum.HumanoidStateType.FallingDown then
            batCounterDebounce = true
            task.spawn(function()
                local bat = findBatForCounter()
                if bat then swingBatForCounter(bat, char) end
                task.wait(0.5)
                batCounterDebounce = false
            end)
        end
    end)
end

stopBatCounter = function()
    if Conns.batCounter then Conns.batCounter:Disconnect(); Conns.batCounter = nil end
    batCounterDebounce = false
end

-- Auto Bat / Aimbot
local function getAutoBatTarget()
    local root = getHRP()
    if not root then return nil end
    local now = tick()
    if now - _autoBatLastScan <= 0.1 and _autoBatTarget and _autoBatTarget.Parent then
        local hum = _autoBatTarget.Parent:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then return _autoBatTarget end
    end
    _autoBatLastScan = now
    _autoBatTarget   = nil
    local closest, minDist = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local tRoot = plr.Character:FindFirstChild("HumanoidRootPart")
            local hum   = plr.Character:FindFirstChildOfClass("Humanoid")
            if tRoot and hum and hum.Health > 0 then
                local dist = (tRoot.Position - root.Position).Magnitude
                if dist < minDist then minDist = dist; closest = tRoot end
            end
        end
    end
    _autoBatTarget = closest
    return _autoBatTarget
end

resetAutoBatMotion = function()
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if hrp then
        hrp.AssemblyLinearVelocity  = hrp.AssemblyLinearVelocity * 0.3
        hrp.AssemblyAngularVelocity = Vector3.zero
    end
    if hum then hum.AutoRotate = true end
end

local function enableAutoBat()
    if autoLeftEnabled  then autoLeftEnabled  = false; if autoLeftSetVisual  then autoLeftSetVisual(false)  end; end
    if autoRightEnabled then autoRightEnabled = false; if autoRightSetVisual then autoRightSetVisual(false) end; end
    if autoTPEnabled    then _autoTPWasEnabled = true; stopAutoTP(); if setAutoTPVisual then setAutoTPVisual(false) end
    else _autoTPWasEnabled = false end
    autoBatEquippedThisRun = false
    autoBatEnabled         = true
end

local function disableAutoBat()
    autoBatEnabled         = false
    autoBatEquippedThisRun = false
    local char = LocalPlayer.Character
    if char then
        local hum2 = char:FindFirstChildOfClass("Humanoid")
        if hum2 then hum2.AutoRotate = true end
    end
    if resetAutoBatMotion then resetAutoBatMotion() end
    if _autoTPWasEnabled then
        _autoTPWasEnabled = false
        autoTPEnabled     = true
        if setAutoTPVisual then setAutoTPVisual(true) end
        startAutoTP()
    end
end

local function queueAutoLeftStart()
    autoLeftEnabled = true
    if autoRightEnabled then
        autoRightEnabled = false
        if autoRightSetVisual then autoRightSetVisual(false) end
    end
    if autoBatEnabled then
        disableAutoBat()
        if autoBatSetVisual then autoBatSetVisual(false) end
    end
end

local function queueAutoRightStart()
    autoRightEnabled = true
    if autoLeftEnabled then
        autoLeftEnabled = false
        if autoLeftSetVisual then autoLeftSetVisual(false) end
    end
    if autoBatEnabled then
        disableAutoBat()
        if autoBatSetVisual then autoBatSetVisual(false) end
    end
end

local function queueAutoBatStart()
    if autoLeftEnabled  then autoLeftEnabled  = false; if autoLeftSetVisual  then autoLeftSetVisual(false)  end; end
    if autoRightEnabled then autoRightEnabled = false; if autoRightSetVisual then autoRightSetVisual(false) end; end
    enableAutoBat()
end

-- Auto Steal
local function findNearestPrompt()
    local char = LocalPlayer.Character; if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart"); if not root then return nil end
    local plots = workspace:FindFirstChild("Plots"); if not plots then return nil end
    local nearest, dist = nil, math.huge
    for _, plot in ipairs(plots:GetChildren()) do
        if isMyPlotByName(plot.Name) then continue end
        local pods = plot:FindFirstChild("AnimalPodiums"); if not pods then continue end
        for _, pod in ipairs(pods:GetChildren()) do
            local base = pod:FindFirstChild("Base")
            local sp   = base and base:FindFirstChild("Spawn")
            if sp then
                local d = (sp.Position - root.Position).Magnitude
                if d <= Steal.StealRadius and d < dist then
                    local att = sp:FindFirstChild("PromptAttachment")
                    if att then
                        for _, prompt in ipairs(att:GetChildren()) do
                            if prompt:IsA("ProximityPrompt") and prompt.ActionText:find("Steal") then
                                nearest, dist = prompt, d
                            end
                        end
                    end
                end
            end
        end
    end
    return nearest
end

local function executeSteal(prompt)
    if isStealing then return end
    if not Steal.Data[prompt] then
        Steal.Data[prompt] = { hold = {}, trigger = {}, ready = true }
        if getconnections then
            for _, c in ipairs(getconnections(prompt.PromptButtonHoldBegan)) do
                if c.Function then table.insert(Steal.Data[prompt].hold, c.Function) end
            end
            for _, c in ipairs(getconnections(prompt.Triggered)) do
                if c.Function then table.insert(Steal.Data[prompt].trigger, c.Function) end
            end
        end
    end
    local data = Steal.Data[prompt]
    if not data.ready then return end
    data.ready    = false
    isStealing    = true
    stealStartTime = tick()
    if Conns.progress then Conns.progress:Disconnect() end
    Conns.progress = RunService.Heartbeat:Connect(function()
        if not isStealing then Conns.progress:Disconnect(); Conns.progress = nil; return end
        local prog = math.clamp((tick() - stealStartTime) / Steal.StealDuration, 0, 1)
        if ProgressFill then ProgressFill.Size = UDim2.new(prog, 0, 1, 0) end
        if ProgressPct  then ProgressPct.Text  = math.floor(prog * 100) .. "%" end
    end)
    task.spawn(function()
        for _, fn in ipairs(data.hold) do task.spawn(fn) end
        task.wait(Steal.StealDuration)
        for _, fn in ipairs(data.trigger) do task.spawn(fn) end
        if Conns.progress then Conns.progress:Disconnect(); Conns.progress = nil end
        resetProgressBar()
        data.ready = true
        isStealing = false
    end)
end

local function startAutoSteal()
    if Conns.autoSteal then return end
    Conns.autoSteal = RunService.Heartbeat:Connect(function()
        if not Steal.AutoStealEnabled or isStealing then return end
        local p = findNearestPrompt()
        if p then executeSteal(p) end
    end)
end

local function stopAutoSteal()
    if Conns.autoSteal then Conns.autoSteal:Disconnect(); Conns.autoSteal = nil end
    if Conns.progress  then Conns.progress:Disconnect();  Conns.progress  = nil end
    isStealing = false
    resetProgressBar()
end

-- Instant Reset
local function cursedInstaReset()
    if not cursedResetRemote then
        for _, desc in ipairs(game:GetDescendants()) do
            if desc:IsA("RemoteEvent") and desc.Name:sub(1, 3) == "RE/" then
                cursedResetRemote = desc; break
            end
        end
    end
    if not cursedResetRemote then return end
    local character = LocalPlayer.Character
    local humanoid  = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Health <= 0 then
        pcall(function() cursedResetRemote:FireServer(CURSED_RESET_GUID, LocalPlayer, "balloon") end)
        return
    end
    local resetDetected = false
    local conns = {}
    if humanoid then
        table.insert(conns, humanoid.Died:Connect(function() resetDetected = true end))
        table.insert(conns, humanoid:GetPropertyChangedSignal("Health"):Connect(function()
            if humanoid.Health <= 0 then resetDetected = true end
        end))
    end
    if character then
        table.insert(conns, character.AncestryChanged:Connect(function(_, parent)
            if not parent then resetDetected = true end
        end))
    end
    task.spawn(function()
        for _ = 1, 50 do
            if resetDetected then break end
            pcall(function() cursedResetRemote:FireServer(CURSED_RESET_GUID, LocalPlayer, "balloon") end)
            task.wait()
        end
        for _, conn in ipairs(conns) do pcall(function() conn:Disconnect() end) end
    end)
end

-- Auto Left / Right path
local function stopAutoLeft()
    if alConn then alConn:Disconnect(); alConn = nil end
    alPhase = 1
    local char = LocalPlayer.Character
    if char then
        local h = char:FindFirstChildOfClass("Humanoid")
        if h then h:Move(Vector3.zero, false) end
    end
    if autoLeftSetVisual then autoLeftSetVisual(false) end
end

local function stopAutoRight()
    if arConn then arConn:Disconnect(); arConn = nil end
    arPhase = 1
    local char = LocalPlayer.Character
    if char then
        local h = char:FindFirstChildOfClass("Humanoid")
        if h then h:Move(Vector3.zero, false) end
    end
    if autoRightSetVisual then autoRightSetVisual(false) end
end

local function startAutoLeft()
    if alConn then alConn:Disconnect() end
    alPhase = 1
    alConn  = RunService.Heartbeat:Connect(function()
        if not autoLeftEnabled then return end
        local char = LocalPlayer.Character; if not char then return end
        local hrp  = char:FindFirstChild("HumanoidRootPart")
        local hum  = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then return end
        if isRagdollState(hum) then hum:Move(Vector3.zero, false); return end
        local spd = getAutoPathSpeed()
        if alPhase == 1 then
            local tgt = Vector3.new(AP_L1.X, hrp.Position.Y, AP_L1.Z)
            if (tgt - hrp.Position).Magnitude < 1 then
                alPhase = 2
                local d  = AP_L2 - hrp.Position
                local mv = Vector3.new(d.X, 0, d.Z).Unit
                hum:Move(mv, false)
                hrp.AssemblyLinearVelocity = Vector3.new(mv.X * spd, hrp.AssemblyLinearVelocity.Y, mv.Z * spd)
                return
            end
            local d  = AP_L1 - hrp.Position
            local mv = Vector3.new(d.X, 0, d.Z).Unit
            hum:Move(mv, false)
            hrp.AssemblyLinearVelocity = Vector3.new(mv.X * spd, hrp.AssemblyLinearVelocity.Y, mv.Z * spd)
        elseif alPhase == 2 then
            local tgt = Vector3.new(AP_L2.X, hrp.Position.Y, AP_L2.Z)
            if (tgt - hrp.Position).Magnitude < 1 then
                hum:Move(Vector3.zero, false)
                hrp.AssemblyLinearVelocity = Vector3.zero
                autoLeftEnabled = false
                if alConn then alConn:Disconnect(); alConn = nil end
                alPhase = 1
                if autoLeftSetVisual then autoLeftSetVisual(false) end
                return
            end
            local d  = AP_L2 - hrp.Position
            local mv = Vector3.new(d.X, 0, d.Z).Unit
            hum:Move(mv, false)
            hrp.AssemblyLinearVelocity = Vector3.new(mv.X * spd, hrp.AssemblyLinearVelocity.Y, mv.Z * spd)
        end
    end)
end

local function startAutoRight()
    if arConn then arConn:Disconnect() end
    arPhase = 1
    arConn  = RunService.Heartbeat:Connect(function()
        if not autoRightEnabled then return end
        local char = LocalPlayer.Character; if not char then return end
        local hrp  = char:FindFirstChild("HumanoidRootPart")
        local hum  = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then return end
        if isRagdollState(hum) then hum:Move(Vector3.zero, false); return end
        local spd = getAutoPathSpeed()
        if arPhase == 1 then
            local tgt = Vector3.new(AP_R1.X, hrp.Position.Y, AP_R1.Z)
            if (tgt - hrp.Position).Magnitude < 1 then
                arPhase = 2
                local d  = AP_R2 - hrp.Position
                local mv = Vector3.new(d.X, 0, d.Z).Unit
                hum:Move(mv, false)
                hrp.AssemblyLinearVelocity = Vector3.new(mv.X * spd, hrp.AssemblyLinearVelocity.Y, mv.Z * spd)
                return
            end
            local d  = AP_R1 - hrp.Position
            local mv = Vector3.new(d.X, 0, d.Z).Unit
            hum:Move(mv, false)
            hrp.AssemblyLinearVelocity = Vector3.new(mv.X * spd, hrp.AssemblyLinearVelocity.Y, mv.Z * spd)
        elseif arPhase == 2 then
            local tgt = Vector3.new(AP_R2.X, hrp.Position.Y, AP_R2.Z)
            if (tgt - hrp.Position).Magnitude < 1 then
                hum:Move(Vector3.zero, false)
                hrp.AssemblyLinearVelocity = Vector3.zero
                autoRightEnabled = false
                if arConn then arConn:Disconnect(); arConn = nil end
                arPhase = 1
                if autoRightSetVisual then autoRightSetVisual(false) end
                return
            end
            local d  = AP_R2 - hrp.Position
            local mv = Vector3.new(d.X, 0, d.Z).Unit
            hum:Move(mv, false)
            hrp.AssemblyLinearVelocity = Vector3.new(mv.X * spd, hrp.AssemblyLinearVelocity.Y, mv.Z * spd)
        end
    end)
end

-- Speed & render loops
RunService.Stepped:Connect(function()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            for _, part in ipairs(p.Character:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
    end
end)

RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character; if not char then return end
    local hum  = char:FindFirstChildOfClass("Humanoid")
    local hrp  = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end
    if isRagdollState(hum) then lastMoveDir = Vector3.new(0, 0, 0); return end
    if not autoBatEnabled and not autoLeftEnabled and not autoRightEnabled then
        local md  = hum.MoveDirection
        local spd = getActiveMoveSpeed()
        if md.Magnitude > 0 then
            lastMoveDir     = md
            hrp.Velocity    = Vector3.new(md.X * spd, hrp.Velocity.Y, md.Z * spd)
        elseif antiRagdollEnabled and lastMoveDir.Magnitude > 0 then
            local anyHeld = false
            for key in pairs(MOVE_KEYS) do
                if UserInputService:IsKeyDown(key) then anyHeld = true; break end
            end
            if anyHeld then hrp.Velocity = Vector3.new(lastMoveDir.X * spd, hrp.Velocity.Y, lastMoveDir.Z * spd) end
        end
    end
    if speedLabel then
        speedLabel.Text = string.format("Speed: %.1f", Vector3.new(hrp.Velocity.X, 0, hrp.Velocity.Z).Magnitude)
    end
end)

-- Auto Bat heartbeat
RunService.Heartbeat:Connect(function()
    if not autoBatEnabled then return end
    local char = LocalPlayer.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root or not hum then return end
    if not autoBatEquippedThisRun then
        autoBatEquippedThisRun = true
        if not char:FindFirstChildOfClass("Tool") then
            local bp     = LocalPlayer:FindFirstChildOfClass("Backpack") or LocalPlayer:FindFirstChild("Backpack")
            local bpBat  = bp and bp:FindFirstChild("Bat")
            if bpBat then pcall(function() hum:EquipTool(bpBat) end) end
        end
    end
    local target = getAutoBatTarget()
    local BAT    = CONFIG.AutoBat
    if target then
        local targetVel    = target.AssemblyLinearVelocity
        local aimTargetPos = target.Position
            + (targetVel * math.clamp(targetVel.Magnitude / 130, 0.05, 0.15))
            + Vector3.new(0, BAT.VertOffset, 0)
        hum.AutoRotate = false
        local look     = aimTargetPos - root.Position
        local flatLook = Vector3.new(look.X, 0, look.Z)
        if look.Magnitude > 0.01 and flatLook.Magnitude > 0.01 then
            local targetYaw  = math.deg(math.atan2(-flatLook.X, -flatLook.Z))
            local yawDelta   = (targetYaw - root.Orientation.Y + 180) % 360 - 180
            local targetPitch = math.deg(math.atan2(look.Y, flatLook.Magnitude))
            local pitchDelta  = (targetPitch - root.Orientation.X + 180) % 360 - 180
            local yawRate     = math.clamp(math.rad(yawDelta)   * BAT.TurnSpeed, -BAT.MaxTurnRate, BAT.MaxTurnRate)
            local pitchRate   = math.clamp(math.rad(pitchDelta) * BAT.TurnSpeed, -BAT.MaxTurnRate, BAT.MaxTurnRate)
            local yawRad      = math.rad(root.Orientation.Y)
            local rightAxis   = Vector3.new(math.cos(yawRad), 0, -math.sin(yawRad))
            root.AssemblyAngularVelocity = Vector3.new(0, yawRate, 0) + (rightAxis * pitchRate)
        else
            root.AssemblyAngularVelocity = Vector3.zero
        end
        local dir      = look.Magnitude > 0.01 and look.Unit or Vector3.zero
        local standPos = aimTargetPos - (dir * BAT.Dist) + Vector3.new(0, BAT.Height, 0)
        local moveDir  = standPos - root.Position
        local hDir     = Vector3.new(moveDir.X, 0, moveDir.Z)
        local hVel     = hDir.Magnitude > 0.1 and hDir.Unit * BAT.Speed or Vector3.zero
        local vVel     = math.abs(moveDir.Y) > 0.1
            and Vector3.new(0, math.sign(moveDir.Y) * BAT.VertSpeed, 0)
            or  Vector3.new(0, -2, 0)
        root.AssemblyLinearVelocity = hVel + vVel
        if hDir.Magnitude > 0.5 then hum:Move(hDir.Unit, false) end
    else
        hum.AutoRotate              = true
        root.AssemblyAngularVelocity = Vector3.zero
    end
    if autoSwingEnabled then
        local bat = char:FindFirstChild("Bat")
        if bat and bat:IsA("Tool") then bat:Activate() end
    end
end)

-- Character added
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1.0)
    setupSpeedIndicator(char)
    if medusaCounterEnabled then setupMedusa(char) end
    if batCounterEnabled    then startBatCounter() end
    if unwalkEnabled        then task.wait(0.5); startUnwalk() end
end)
if LocalPlayer.Character then task.spawn(function() task.wait(0.5); setupSpeedIndicator(LocalPlayer.Character) end) end

-- Remote hook for insta reset
pcall(function()
    if hookfunction and newcclosure then
        local oldFire
        oldFire = hookfunction(Instance.new("RemoteEvent").FireServer, newcclosure(function(self, ...)
            if not cursedResetRemote
            and typeof(self) == "Instance"
            and self:IsA("RemoteEvent")
            and self.Name:sub(1, 3) == "RE/" then
                cursedResetRemote = self
            end
            return oldFire(self, ...)
        end))
    end
end)
task.spawn(function()
    task.wait(2)
    if cursedResetRemote then return end
    for _, desc in ipairs(game:GetDescendants()) do
        if desc:IsA("RemoteEvent") and desc.Name:sub(1, 3) == "RE/" then
            cursedResetRemote = desc; break
        end
    end
end)

-- Auto save
task.spawn(function()
    while task.wait(5) do saveConfig() end
end)

-- // [5] GUI CREATION //

-- forward-declared so loadConfigState can call them after GUI is built
local _applyBtnSize  = nil
local _applyGuiScale = nil

local function createChevron(parent, color)
    local holder = Instance.new("Frame")
    holder.Name             = "ChevronHolder"
    holder.ZIndex           = 6
    holder.Position         = UDim2.new(1, -36, 0, 0)
    holder.Size             = UDim2.new(0, 36, 0, 42)
    holder.BackgroundTransparency = 1
    holder.Parent           = parent

    local chevFrame = Instance.new("Frame")
    chevFrame.Name          = "Chevron"
    chevFrame.ZIndex        = 6
    chevFrame.AnchorPoint   = Vector2.new(0.5, 0.5)
    chevFrame.Position      = UDim2.new(0.5, 0, 0.5, 0)
    chevFrame.Size          = UDim2.new(0, 17, 0, 9)
    chevFrame.BackgroundTransparency = 1
    chevFrame.Parent        = holder

    local left  = Instance.new("Frame", chevFrame)
    left.ZIndex = 6; left.AnchorPoint = Vector2.new(0.5, 0.5)
    left.Position = UDim2.new(0, 5, 0.5, 0); left.Size = UDim2.new(0, 9, 0, 2)
    left.BackgroundColor3 = color or Color3.fromRGB(180, 0, 0)
    left.BorderSizePixel = 0; left.Rotation = 40
    Instance.new("UICorner", left).CornerRadius = UDim.new(1, 0)

    local right = Instance.new("Frame", chevFrame)
    right.ZIndex = 6; right.AnchorPoint = Vector2.new(0.5, 0.5)
    right.Position = UDim2.new(0, 11, 0.5, 0); right.Size = UDim2.new(0, 9, 0, 2)
    right.BackgroundColor3 = color or Color3.fromRGB(180, 0, 0)
    right.BorderSizePixel = 0; right.Rotation = -40
    Instance.new("UICorner", right).CornerRadius = UDim.new(1, 0)

    local chevBtn = Instance.new("TextButton")
    chevBtn.Name  = "ChevronBtn"
    chevBtn.ZIndex = 7
    chevBtn.Position = UDim2.new(1, -36, 0, 0)
    chevBtn.Size     = UDim2.new(0, 36, 0, 42)
    chevBtn.BackgroundTransparency = 1
    chevBtn.Text = ""; chevBtn.AutoButtonColor = false; chevBtn.Active = true
    chevBtn.Parent = parent

    return holder, chevBtn
end

local function createKeybindButton(parent, defaultText, zIndex)
    local btn = Instance.new("TextButton")
    btn.Name   = "KeyBind"
    btn.ZIndex = zIndex or 5
    btn.Position = UDim2.new(0, 6, 0.5, -12)
    btn.Size     = UDim2.new(0, 25, 0, 24)
    btn.BackgroundColor3 = CONFIG.Colors.KeyBindBG
    btn.BorderSizePixel  = 0
    btn.Text       = defaultText or "+"
    btn.TextColor3 = CONFIG.Colors.Text
    btn.TextSize   = 11
    btn.Font       = Enum.Font.GothamBold
    btn.AutoButtonColor = false; btn.Active = true
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = Color3.fromRGB(255, 31, 30)
    stroke.Thickness = 2
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    return btn
end

local function createRow(parent, layoutOrder, name, subTitle, strokeColor, hasChevron, onToggle)
    local C = CONFIG.Colors
    local row = Instance.new("Frame")
    row.Name   = name
    row.LayoutOrder = layoutOrder
    row.ClipsDescendants = true
    row.Size   = UDim2.new(1, 0, 0, CONFIG.Size.RowHeight)
    row.BackgroundColor3 = C.RowBG
    row.BorderSizePixel  = 0
    row.Parent = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)
    local stroke = Instance.new("UIStroke", row)
    stroke.Name  = "UIStroke"
    stroke.Color = strokeColor or C.RowStrokeOff
    stroke.Thickness = 2
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local titleLbl = Instance.new("TextLabel")
    titleLbl.ZIndex = 3
    titleLbl.Position = UDim2.new(0, hasChevron and 14 or 14, 0, subTitle and 4 or 0)
    titleLbl.Size     = UDim2.new(hasChevron and 1 or 1, hasChevron and -36 or -8, 0, subTitle and 18 or CONFIG.Size.RowHeight)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text     = name
    titleLbl.TextColor3 = C.Text
    titleLbl.TextSize   = 11
    titleLbl.Font       = Enum.Font.GothamBold
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Parent = row

    if subTitle then
        local subLbl = Instance.new("TextLabel")
        subLbl.ZIndex = 3
        subLbl.Position = UDim2.new(0, 14, 0, 22)
        subLbl.Size     = UDim2.new(0.52, -14, 0, 12)
        subLbl.BackgroundTransparency = 1
        subLbl.Text     = subTitle
        subLbl.TextColor3 = C.SubText
        subLbl.TextSize   = 7
        subLbl.Font       = Enum.Font.Gotham
        subLbl.TextXAlignment = Enum.TextXAlignment.Left
        subLbl.Parent = row
    end

    local clickBtn = Instance.new("TextButton")
    clickBtn.ZIndex = 4
    clickBtn.Size   = UDim2.new(hasChevron and 1 or 1, hasChevron and -36 or 0, 0, CONFIG.Size.RowHeight)
    clickBtn.BackgroundTransparency = 1
    clickBtn.Text   = ""; clickBtn.AutoButtonColor = false; clickBtn.Active = true
    clickBtn.Parent = row
    if onToggle then
        clickBtn.MouseButton1Click:Connect(onToggle)
    end

    local chevHolder, chevBtn
    if hasChevron then
        chevHolder, chevBtn = createChevron(row)
    end

    local subPanel = Instance.new("Frame")
    subPanel.Name    = "SubPanel"
    subPanel.Visible = false
    subPanel.Position = UDim2.new(0, 0, 0, 44)
    subPanel.Size    = UDim2.new(1, 0, 0, CONFIG.Size.SubPanelH)
    subPanel.BackgroundTransparency = 1
    subPanel.BorderSizePixel = 0
    subPanel.Parent = row

    return row, stroke, subPanel, chevBtn, clickBtn
end

local function createGUI()
    local C = CONFIG.Colors

    -- Destroy old instance if re-running
    local old = game:GetService("CoreGui"):FindFirstChild(CONFIG.Names.ScreenGui)
    if old then old:Destroy() end
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if pg then local o = pg:FindFirstChild(CONFIG.Names.ScreenGui); if o then o:Destroy() end end

    -- ScreenGui
    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name          = CONFIG.Names.ScreenGui
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.ResetOnSpawn  = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function() if syn and syn.protect_gui then syn.protect_gui(ScreenGui) end end)
    if not pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end) then
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end

    -- Hidden progress label (size tracking, kept for luarmor compatibility)
    local hiddenTL = Instance.new("TextLabel", ScreenGui)
    hiddenTL.Size  = UDim2.new(0, 1, 0, 1)
    hiddenTL.BackgroundTransparency = 1
    hiddenTL.Text  = "0%"

    -- Main frame
    MainFrame = Instance.new("Frame")
    MainFrame.Name             = CONFIG.Names.MainFrame
    MainFrame.Visible          = true
    MainFrame.ZIndex           = 8
    MainFrame.ClipsDescendants = false
    MainFrame.Position         = CONFIG.Position.MainFrame
    MainFrame.Size             = CONFIG.Size.MainFrame
    MainFrame.BackgroundColor3 = C.Background
    MainFrame.BorderSizePixel  = 0
    MainFrame.Parent           = ScreenGui
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 14)
    local mainStroke = Instance.new("UIStroke", MainFrame)
    mainStroke.Color    = C.Stroke
    mainStroke.Thickness = 2
    mainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    -- Dragging
    MainFrame.Active = true
    do
        local guiDragging, guiDragStart, guiStartPos = false, nil, nil
        MainFrame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                guiDragging  = true
                guiDragStart = input.Position
                guiStartPos  = MainFrame.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then guiDragging = false end
                end)
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if guiDragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
                local dx = input.Position.X - guiDragStart.X
                local dy = input.Position.Y - guiDragStart.Y
                MainFrame.Position = UDim2.new(
                    guiStartPos.X.Scale, guiStartPos.X.Offset + dx,
                    guiStartPos.Y.Scale, guiStartPos.Y.Offset + dy
                )
            end
        end)
    end

    -- Progress bar (top strip)
    local ProgressBarContainer = Instance.new("Frame")
    ProgressBarContainer.Name   = "ProgressBarContainer"
    ProgressBarContainer.ZIndex = 5
    ProgressBarContainer.ClipsDescendants = true
    ProgressBarContainer.Size   = UDim2.new(1, 0, 0, 26)
    ProgressBarContainer.BackgroundTransparency = 1
    ProgressBarContainer.BorderSizePixel = 0
    ProgressBarContainer.Parent = MainFrame

    ProgressFill = Instance.new("Frame")
    ProgressFill.Name   = "Frame"
    ProgressFill.ZIndex = 6
    ProgressFill.Size   = UDim2.new(0, 0, 1, 0)
    ProgressFill.BackgroundColor3 = C.ProgressFill
    ProgressFill.BackgroundTransparency = 1
    ProgressFill.BorderSizePixel = 0
    ProgressFill.Parent = ProgressBarContainer
    Instance.new("UICorner", ProgressFill).CornerRadius = UDim.new(0, 10)

    -- Separator line
    local sepLine = Instance.new("Frame")
    sepLine.ZIndex = 9; sepLine.Visible = false
    sepLine.Position = UDim2.new(0.075, 0, 0, 26)
    sepLine.Size     = UDim2.new(0.85, 0, 0, 1)
    sepLine.BackgroundColor3 = Color3.fromRGB(80, 0, 0)
    sepLine.BackgroundTransparency = 1
    sepLine.BorderSizePixel = 0
    sepLine.Parent = MainFrame

    -- Scrolling frame
    ScrollingFrame = Instance.new("ScrollingFrame")
    ScrollingFrame.Name   = "ScrollingFrame"
    ScrollingFrame.Active = true
    ScrollingFrame.ZIndex = 9
    ScrollingFrame.Position = UDim2.new(0, 2, 0, 30)
    ScrollingFrame.Size     = UDim2.new(1, -4, 1, -30)
    ScrollingFrame.BackgroundTransparency = 1
    ScrollingFrame.BorderSizePixel = 0
    ScrollingFrame.ScrollBarThickness    = 4
    ScrollingFrame.ScrollBarImageColor3  = C.ScrollBar
    ScrollingFrame.CanvasSize            = UDim2.new(0, 0, 0, 1700)
    ScrollingFrame.ScrollingEnabled      = true
    ScrollingFrame.Parent = MainFrame

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 8)
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = ScrollingFrame

    local sfPadding = Instance.new("UIPadding")
    sfPadding.PaddingTop    = UDim.new(0, 8)
    sfPadding.PaddingBottom = UDim.new(0, 10)
    sfPadding.PaddingLeft   = UDim.new(0, 5)
    sfPadding.PaddingRight  = UDim.new(0, 5)
    sfPadding.Parent = ScrollingFrame

    -- Section label helper
    local function mkSection(text, layoutOrder)
        local f  = Instance.new("Frame", ScrollingFrame)
        f.LayoutOrder = layoutOrder; f.Size = UDim2.new(1, 0, 0, 18)
        f.BackgroundTransparency = 1; f.BorderSizePixel = 0
        local dot = Instance.new("Frame", f)
        dot.Position = UDim2.new(0, 4, 0.5, -2); dot.Size = UDim2.new(0, 5, 0, 5)
        dot.BackgroundColor3 = Color3.fromRGB(255, 0, 0); dot.BorderSizePixel = 0
        Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
        local lbl = Instance.new("TextLabel", f)
        lbl.Position = UDim2.new(0, 14, 0, 0); lbl.Size = UDim2.new(1, -14, 1, 0)
        lbl.BackgroundTransparency = 1; lbl.Text = text
        lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        lbl.TextSize = 9; lbl.Font = Enum.Font.GothamBold
        lbl.TextXAlignment = Enum.TextXAlignment.Left
    end

    -- Toggle helper: creates toggle + chevron row, returns setVisual function
    local function mkToggleRow(name, subTitle, strokeColorOn, layoutOrder, onToggle, hasChevron)
        local row, stroke, subPanel, chevBtn, clickBtn =
            createRow(ScrollingFrame, layoutOrder, name, subTitle, C.RowStrokeOff, hasChevron)
        local enabled = false
        local function setVisual(state)
            enabled = state
            stroke.Color = state and (strokeColorOn or C.RowStrokeOn) or C.RowStrokeOff
        end
        clickBtn.MouseButton1Click:Connect(function()
            local newState = not enabled
            setVisual(newState)
            if onToggle then onToggle(newState) end
        end)
        if hasChevron and chevBtn then
            local open = false
            chevBtn.MouseButton1Click:Connect(function()
                open = not open
                subPanel.Visible = open
                row.Size = open
                    and UDim2.new(1, 0, 0, CONFIG.Size.RowHeight + CONFIG.Size.SubPanelH + 4)
                    or  UDim2.new(1, 0, 0, CONFIG.Size.RowHeight)
                row.ClipsDescendants = not open
            end)
        end
        return setVisual, row, stroke, subPanel
    end

    -- Speed section
    mkSection("SPEED", 1)

    -- Normal Speed row
    do
        local row, stroke, _ = createRow(ScrollingFrame, 2, "Normal Speed", "default mode", C.RowStrokeOn, false)
        local stealSpdLbl = Instance.new("TextLabel", row)
        stealSpdLbl.ZIndex = 4; stealSpdLbl.Position = UDim2.new(1, -96, 0, 4)
        stealSpdLbl.Size = UDim2.new(0, 44, 0, 10); stealSpdLbl.BackgroundTransparency = 1
        stealSpdLbl.Text = "steal spd"; stealSpdLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
        stealSpdLbl.TextSize = 7; stealSpdLbl.Font = Enum.Font.Gotham
        NormalSpdBox = Instance.new("TextBox", row)
        NormalSpdBox.Name = "TextBox"; NormalSpdBox.ZIndex = 4
        NormalSpdBox.Position = UDim2.new(1, -96, 0, 16); NormalSpdBox.Size = UDim2.new(0, 44, 0, 24)
        NormalSpdBox.BackgroundColor3 = C.Background; NormalSpdBox.BorderSizePixel = 0
        NormalSpdBox.Text = tostring(NS); NormalSpdBox.TextColor3 = C.Text
        NormalSpdBox.TextSize = 9; NormalSpdBox.Font = Enum.Font.GothamBold
        Instance.new("UICorner", NormalSpdBox).CornerRadius = UDim.new(0, 6)
        local normSpdStroke = Instance.new("UIStroke", NormalSpdBox); normSpdStroke.Color = Color3.fromRGB(55, 55, 55)
        local normSpdLbl = Instance.new("TextLabel", row)
        normSpdLbl.ZIndex = 4; normSpdLbl.Position = UDim2.new(1, -48, 0, 4)
        normSpdLbl.Size = UDim2.new(0, 44, 0, 10); normSpdLbl.BackgroundTransparency = 1
        normSpdLbl.Text = "norm spd"; normSpdLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
        normSpdLbl.TextSize = 7; normSpdLbl.Font = Enum.Font.Gotham
        CarrySpdBox = Instance.new("TextBox", row)
        CarrySpdBox.Name = "TextBox"; CarrySpdBox.ZIndex = 4
        CarrySpdBox.Position = UDim2.new(1, -48, 0, 16); CarrySpdBox.Size = UDim2.new(0, 44, 0, 24)
        CarrySpdBox.BackgroundColor3 = C.Background; CarrySpdBox.BorderSizePixel = 0
        CarrySpdBox.Text = tostring(CS); CarrySpdBox.TextColor3 = C.Text
        CarrySpdBox.TextSize = 9; CarrySpdBox.Font = Enum.Font.GothamBold
        Instance.new("UICorner", CarrySpdBox).CornerRadius = UDim.new(0, 6)
        Instance.new("UIStroke", CarrySpdBox).Color = Color3.fromRGB(55, 55, 55)
        local kbBtn = createKeybindButton(row, "Q", 5)
        kbBtn.Position = UDim2.new(0, 6, 0.5, -12)
        NormalSpdBox.FocusLost:Connect(function()
            local v = tonumber(NormalSpdBox.Text)
            if v and v > 0 and v <= 500 then NS = v else NormalSpdBox.Text = tostring(NS) end
            saveConfig()
        end)
        CarrySpdBox.FocusLost:Connect(function()
            local v = tonumber(CarrySpdBox.Text)
            if v and v > 0 and v <= 500 then CS = v else CarrySpdBox.Text = tostring(CS) end
            saveConfig()
        end)
        kbBtn.MouseButton1Click:Connect(function()
            toggleCarryMode(); saveConfig()
        end)
    end

    -- Lagger Speed row
    do
        local row, stroke, _ = createRow(ScrollingFrame, 3, "Lagger Speed", "use against lagger", C.RowStrokeOff, false)
        local laggerSpdLbl1 = Instance.new("TextLabel", row)
        laggerSpdLbl1.ZIndex = 4; laggerSpdLbl1.Position = UDim2.new(1, -96, 0, 4)
        laggerSpdLbl1.Size = UDim2.new(0, 44, 0, 10); laggerSpdLbl1.BackgroundTransparency = 1
        laggerSpdLbl1.Text = "steal spd"; laggerSpdLbl1.TextColor3 = Color3.fromRGB(200, 200, 200)
        laggerSpdLbl1.TextSize = 7; laggerSpdLbl1.Font = Enum.Font.Gotham
        LaggerSpdBox = Instance.new("TextBox", row)
        LaggerSpdBox.ZIndex = 4; LaggerSpdBox.Position = UDim2.new(1, -96, 0, 16)
        LaggerSpdBox.Size = UDim2.new(0, 44, 0, 24); LaggerSpdBox.BackgroundColor3 = C.Background
        LaggerSpdBox.BorderSizePixel = 0; LaggerSpdBox.Text = tostring(LAGGER_SPEED)
        LaggerSpdBox.TextColor3 = C.Text; LaggerSpdBox.TextSize = 9; LaggerSpdBox.Font = Enum.Font.GothamBold
        Instance.new("UICorner", LaggerSpdBox).CornerRadius = UDim.new(0, 6)
        Instance.new("UIStroke", LaggerSpdBox).Color = Color3.fromRGB(55, 55, 55)
        local laggerSpdLbl2 = Instance.new("TextLabel", row)
        laggerSpdLbl2.ZIndex = 4; laggerSpdLbl2.Position = UDim2.new(1, -48, 0, 4)
        laggerSpdLbl2.Size = UDim2.new(0, 44, 0, 10); laggerSpdLbl2.BackgroundTransparency = 1
        laggerSpdLbl2.Text = "norm spd"; laggerSpdLbl2.TextColor3 = Color3.fromRGB(200, 200, 200)
        laggerSpdLbl2.TextSize = 7; laggerSpdLbl2.Font = Enum.Font.Gotham
        LaggerCarrySpdBox = Instance.new("TextBox", row)
        LaggerCarrySpdBox.ZIndex = 4; LaggerCarrySpdBox.Position = UDim2.new(1, -48, 0, 16)
        LaggerCarrySpdBox.Size = UDim2.new(0, 44, 0, 24); LaggerCarrySpdBox.BackgroundColor3 = C.Background
        LaggerCarrySpdBox.BorderSizePixel = 0; LaggerCarrySpdBox.Text = tostring(LAGGER_CARRY_SPEED)
        LaggerCarrySpdBox.TextColor3 = C.Text; LaggerCarrySpdBox.TextSize = 9; LaggerCarrySpdBox.Font = Enum.Font.GothamBold
        Instance.new("UICorner", LaggerCarrySpdBox).CornerRadius = UDim.new(0, 6)
        Instance.new("UIStroke", LaggerCarrySpdBox).Color = Color3.fromRGB(55, 55, 55)
        local laggerKb = createKeybindButton(row, "Q", 5)
        laggerKb.MouseButton1Click:Connect(function()
            toggleLaggerMode(); saveConfig()
        end)
        LaggerSpdBox.FocusLost:Connect(function()
            local v = tonumber(LaggerSpdBox.Text)
            if v and v > 0 and v <= 500 then LAGGER_SPEED = v else LaggerSpdBox.Text = tostring(LAGGER_SPEED) end
            saveConfig()
        end)
        LaggerCarrySpdBox.FocusLost:Connect(function()
            local v = tonumber(LaggerCarrySpdBox.Text)
            if v and v > 0 and v <= 500 then LAGGER_CARRY_SPEED = v else LaggerCarrySpdBox.Text = tostring(LAGGER_CARRY_SPEED) end
            saveConfig()
        end)
    end

    -- AUTO section
    mkSection("AUTO", 5)

    -- Auto Play (L)
    do
        local sv, row, stroke, subPanel = mkToggleRow(
            "Auto Play (L)", nil, C.RowStrokeOn, 6,
            function(on)
                autoLeftEnabled = on
                if on then queueAutoLeftStart(); startAutoLeft() else stopAutoLeft() end
                if _circleBtnRefs and _circleBtnRefs["autoLeft"] then _circleBtnRefs["autoLeft"].setOn(on) end
                saveConfig()
            end, true
        )
        autoLeftSetVisual = sv
        local kb = createKeybindButton(subPanel, "Z", 6)
        kb.Position = UDim2.new(0, 10, 0, 16); kb.Size = UDim2.new(0, 27, 0, 26)
    end

    -- Auto Steal
    do
        local sv, row, stroke, subPanel = mkToggleRow(
            "Auto Steal", nil, C.RowStrokeOn, 7,
            function(on)
                Steal.AutoStealEnabled = on
                if on then
                    if not pcall(startAutoSteal) then Steal.AutoStealEnabled = false; sv(false) end
                else
                    stopAutoSteal()
                end
                saveConfig()
            end, false
        )
        setInstaGrab = sv
        -- Radius display
        ProgressRadLbl = Instance.new("TextLabel", subPanel)
        ProgressRadLbl.ZIndex = 7; ProgressRadLbl.Position = UDim2.new(0, 76, 0, 40)
        ProgressRadLbl.Size = UDim2.new(1, -84, 0, 14); ProgressRadLbl.BackgroundTransparency = 1
        ProgressRadLbl.Text = "RADIUS: " .. tostring(Steal.StealRadius)
        ProgressRadLbl.TextColor3 = Color3.fromRGB(180, 180, 180); ProgressRadLbl.TextSize = 9
        ProgressRadLbl.Font = Enum.Font.GothamBold
        ProgressPct = Instance.new("TextLabel", subPanel)
        ProgressPct.ZIndex = 7; ProgressPct.Position = UDim2.new(0, 76, 0, 22)
        ProgressPct.Size = UDim2.new(1, -84, 0, 16); ProgressPct.BackgroundTransparency = 1
        ProgressPct.Text = "0%"; ProgressPct.TextColor3 = C.Text
        ProgressPct.TextSize = 10; ProgressPct.Font = Enum.Font.GothamBold
        RadiusInput = Instance.new("TextBox", subPanel)
        RadiusInput.ZIndex = 7; RadiusInput.Position = UDim2.new(0, 8, 0, 14)
        RadiusInput.Size = UDim2.new(0, 52, 0, 24); RadiusInput.BackgroundColor3 = Color3.fromRGB(22, 23, 22)
        RadiusInput.BorderSizePixel = 0; RadiusInput.Text = tostring(Steal.StealRadius)
        RadiusInput.TextColor3 = C.Text; RadiusInput.TextSize = 10; RadiusInput.Font = Enum.Font.GothamBold
        RadiusInput.ClearTextOnFocus = false
        Instance.new("UICorner", RadiusInput).CornerRadius = UDim.new(0, 6)
        Instance.new("UIStroke", RadiusInput).Color = Color3.fromRGB(200, 0, 0)
        RadiusInput.FocusLost:Connect(function()
            local v = tonumber(RadiusInput.Text)
            if v and v >= 1 and v <= 500 then
                Steal.StealRadius = v
                if ProgressRadLbl then ProgressRadLbl.Text = "RADIUS: " .. tostring(v) end
            else
                RadiusInput.Text = tostring(Steal.StealRadius)
            end
            saveConfig()
        end)
    end

    -- Auto Play After Timer
    do
        local sv, _, _, _ = mkToggleRow(
            "Auto Play After Timer", nil, C.RowStrokeOff, 8,
            function(on) saveConfig() end, false
        )
    end

    -- Aimbot 1
    do
        local sv, _, _, subPanel = mkToggleRow(
            "Aimbot 1 (Bypasses Anti Bat)", nil, C.RowStrokeOff, 9,
            function(on)
                if on then queueAutoBatStart() else autoBatEnabled = false; disableAutoBat() end
                if autoBatSetVisual then autoBatSetVisual(on) end
                saveConfig()
            end, true
        )
        autoBatSetVisual = sv
        local kbLabel = Instance.new("TextLabel", subPanel)
        kbLabel.ZIndex = 6; kbLabel.Position = UDim2.new(0, 10, 0, 2)
        kbLabel.Size = UDim2.new(0, 27, 0, 12); kbLabel.BackgroundTransparency = 1
        kbLabel.Text = "KEYBIND"; kbLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        kbLabel.TextSize = 6; kbLabel.Font = Enum.Font.GothamBold
        local kb = createKeybindButton(subPanel, "+", 6)
        kb.Position = UDim2.new(0, 10, 0, 16); kb.Size = UDim2.new(0, 27, 0, 26)
        local batModeLbl = Instance.new("TextLabel", subPanel)
        batModeLbl.ZIndex = 7; batModeLbl.Position = UDim2.new(0, 46, 0, 2)
        batModeLbl.Size = UDim2.new(0, 120, 0, 11); batModeLbl.BackgroundTransparency = 1
        batModeLbl.Text = "BAT MODE"; batModeLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
        batModeLbl.TextSize = 6; batModeLbl.Font = Enum.Font.GothamBold
        batModeLbl.TextXAlignment = Enum.TextXAlignment.Left
        local spamBtn = Instance.new("TextButton", subPanel)
        spamBtn.ZIndex = 7; spamBtn.Position = UDim2.new(0, 46, 0, 14); spamBtn.Size = UDim2.new(0, 44, 0, 24)
        spamBtn.BackgroundColor3 = Color3.fromRGB(120, 0, 0); spamBtn.BorderSizePixel = 0
        spamBtn.Text = "Spam"; spamBtn.TextColor3 = Color3.fromRGB(255, 200, 200)
        spamBtn.TextSize = 9; spamBtn.Font = Enum.Font.GothamBold; spamBtn.AutoButtonColor = false; spamBtn.Active = true
        Instance.new("UICorner", spamBtn).CornerRadius = UDim.new(0, 7)
        local manualBtn = Instance.new("TextButton", subPanel)
        manualBtn.ZIndex = 7; manualBtn.Position = UDim2.new(0, 98, 0, 14); manualBtn.Size = UDim2.new(0, 44, 0, 24)
        manualBtn.BackgroundColor3 = C.Background; manualBtn.BorderSizePixel = 0
        manualBtn.Text = "Manual"; manualBtn.TextColor3 = Color3.fromRGB(140, 140, 140)
        manualBtn.TextSize = 9; manualBtn.Font = Enum.Font.GothamBold; manualBtn.AutoButtonColor = false; manualBtn.Active = true
        Instance.new("UICorner", manualBtn).CornerRadius = UDim.new(0, 7)
        spamBtn.MouseButton1Click:Connect(function() autoSwingEnabled = true end)
        manualBtn.MouseButton1Click:Connect(function() autoSwingEnabled = false end)
    end

    -- Aimbot 2
    do
        local sv, _, _, subPanel = mkToggleRow(
            "Aimbot 2", nil, C.RowStrokeOff, 10,
            function(on)
                if on then queueAutoBatStart() else autoBatEnabled = false; disableAutoBat() end
                saveConfig()
            end, true
        )
        local kb = createKeybindButton(subPanel, "Ct", 6)
        kb.Position = UDim2.new(0, 10, 0, 16); kb.Size = UDim2.new(0, 27, 0, 26)
    end

    -- MOVEMENT section
    mkSection("MOVEMENT", 11)

    -- Steal Speed
    do
        local sv, _, _, subPanel = mkToggleRow(
            "Steal Speed", nil, C.RowStrokeOff, 12,
            function(on) saveConfig() end, true
        )
        local kb = createKeybindButton(subPanel, "+", 6)
        kb.Position = UDim2.new(0, 10, 0, 16); kb.Size = UDim2.new(0, 27, 0, 26)
    end

    -- Anti Kick
    do
        local sv, _, _, _ = mkToggleRow(
            "Anti Kick", nil, C.RowStrokeOn, 13,
            function(on) saveConfig() end, false
        )
    end

    -- Auto TP
    do
        local sv, _, _, subPanel = mkToggleRow(
            "Auto TP", nil, C.RowStrokeOff, 14,
            function(on)
                autoTPEnabled = on
                if on then startAutoTP() else stopAutoTP() end
                if _circleBtnRefs and _circleBtnRefs["autoTP"] then _circleBtnRefs["autoTP"].setOn(on) end
                saveConfig()
            end, true
        )
        setAutoTPVisual = sv
        local kbLbl = Instance.new("TextLabel", subPanel)
        kbLbl.ZIndex = 6; kbLbl.Position = UDim2.new(0, 10, 0, 2)
        kbLbl.Size = UDim2.new(0, 27, 0, 12); kbLbl.BackgroundTransparency = 1
        kbLbl.Text = "KEYBIND"; kbLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
        kbLbl.TextSize = 6; kbLbl.Font = Enum.Font.GothamBold
        local kb = createKeybindButton(subPanel, "N", 6)
        kb.Position = UDim2.new(0, 10, 0, 16); kb.Size = UDim2.new(0, 27, 0, 26)
        local tpHLbl = Instance.new("TextLabel", subPanel)
        tpHLbl.ZIndex = 6; tpHLbl.Position = UDim2.new(0, 52, 0, 2)
        tpHLbl.Size = UDim2.new(0, 46, 0, 12); tpHLbl.BackgroundTransparency = 1
        tpHLbl.Text = "AUTO TP HEIGHT"; tpHLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
        tpHLbl.TextSize = 6; tpHLbl.Font = Enum.Font.GothamBold
        AutoTPHeightBox = Instance.new("TextBox", subPanel)
        AutoTPHeightBox.ZIndex = 6; AutoTPHeightBox.Position = UDim2.new(0, 52, 0, 16)
        AutoTPHeightBox.Size = UDim2.new(0, 46, 0, 26); AutoTPHeightBox.BackgroundColor3 = C.Background
        AutoTPHeightBox.BorderSizePixel = 0; AutoTPHeightBox.Text = tostring(autoTPHeight)
        AutoTPHeightBox.TextColor3 = C.Text; AutoTPHeightBox.TextSize = 10; AutoTPHeightBox.Font = Enum.Font.GothamBold
        AutoTPHeightBox.ClearTextOnFocus = false
        Instance.new("UICorner", AutoTPHeightBox).CornerRadius = UDim.new(0, 6)
        Instance.new("UIStroke", AutoTPHeightBox).Color = Color3.fromRGB(55, 55, 55)
        AutoTPHeightBox.FocusLost:Connect(function()
            local v = tonumber(AutoTPHeightBox.Text)
            if v and v >= 0 and v <= 500 then autoTPHeight = v
            else AutoTPHeightBox.Text = tostring(autoTPHeight) end
            saveConfig()
        end)
    end

    -- Infinite Jump
    do
        local sv, _, _, subPanel = mkToggleRow(
            "Infinite Jump", nil, C.RowStrokeOn, 15,
            function(on)
                infJumpEnabled = on
            end, true
        )
        setInfJumpVisual = sv
        local kb = createKeybindButton(subPanel, "+", 6)
        kb.Position = UDim2.new(0, 10, 0, 16); kb.Size = UDim2.new(0, 27, 0, 26)
        local jmpModeLbl = Instance.new("TextLabel", subPanel)
        jmpModeLbl.ZIndex = 7; jmpModeLbl.Position = UDim2.new(0, 54, 0, 2)
        jmpModeLbl.Size = UDim2.new(0, 80, 0, 11); jmpModeLbl.BackgroundTransparency = 1
        jmpModeLbl.Text = "JUMP MODE"; jmpModeLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
        jmpModeLbl.TextSize = 6; jmpModeLbl.Font = Enum.Font.GothamBold
        jmpModeLbl.TextXAlignment = Enum.TextXAlignment.Left
        local singleBtn = Instance.new("TextButton", subPanel)
        singleBtn.ZIndex = 7; singleBtn.Position = UDim2.new(0, 54, 0, 14); singleBtn.Size = UDim2.new(0, 34, 0, 26)
        singleBtn.BackgroundColor3 = Color3.fromRGB(120, 0, 0); singleBtn.BorderSizePixel = 0
        singleBtn.Text = "Single"; singleBtn.TextColor3 = Color3.fromRGB(255, 200, 200)
        singleBtn.TextSize = 9; singleBtn.Font = Enum.Font.GothamBold
        singleBtn.AutoButtonColor = false; singleBtn.Active = true
        Instance.new("UICorner", singleBtn).CornerRadius = UDim.new(0, 7)
        local holdBtn = Instance.new("TextButton", subPanel)
        holdBtn.ZIndex = 7; holdBtn.Position = UDim2.new(0, 96, 0, 14); holdBtn.Size = UDim2.new(0, 34, 0, 26)
        holdBtn.BackgroundColor3 = C.Background; holdBtn.BorderSizePixel = 0
        holdBtn.Text = "Hold"; holdBtn.TextColor3 = Color3.fromRGB(140, 140, 140)
        holdBtn.TextSize = 9; holdBtn.Font = Enum.Font.GothamBold
        holdBtn.AutoButtonColor = false; holdBtn.Active = true
        Instance.new("UICorner", holdBtn).CornerRadius = UDim.new(0, 7)
    end

    -- Anti Ragdoll
    do
        local sv, _, _, _ = mkToggleRow(
            "Anti Ragdoll", "prevents ragdoll state", C.RowStrokeOn, 16,
            function(on)
                antiRagdollEnabled = on
                if on then startAntiRagdoll() else stopAntiRagdoll() end
                saveConfig()
            end, false
        )
        setAntiRagVisual = sv
    end

    -- Float
    do
        local sv, _, _, subPanel = mkToggleRow(
            "Float", nil, C.RowStrokeOff, 17,
            function(on) saveConfig() end, true
        )
        local kb = createKeybindButton(subPanel, "F", 6)
        kb.Position = UDim2.new(0, 10, 0, 16); kb.Size = UDim2.new(0, 27, 0, 26)
        local stopLbl = Instance.new("TextLabel", subPanel)
        stopLbl.ZIndex = 7; stopLbl.Position = UDim2.new(0, 52, 0, 2)
        stopLbl.Size = UDim2.new(0, 76, 0, 11); stopLbl.BackgroundTransparency = 1
        stopLbl.Text = "STOP"; stopLbl.TextColor3 = C.Text
        stopLbl.TextSize = 6; stopLbl.Font = Enum.Font.GothamBold
        local tpBtn = Instance.new("TextButton", subPanel)
        tpBtn.ZIndex = 7; tpBtn.Position = UDim2.new(0, 52, 0, 14); tpBtn.Size = UDim2.new(0, 34, 0, 26)
        tpBtn.BackgroundColor3 = Color3.fromRGB(120, 0, 0); tpBtn.BorderSizePixel = 0
        tpBtn.Text = "TP"; tpBtn.TextColor3 = Color3.fromRGB(255, 200, 200)
        tpBtn.TextSize = 9; tpBtn.Font = Enum.Font.GothamBold; tpBtn.AutoButtonColor = false; tpBtn.Active = true
        Instance.new("UICorner", tpBtn).CornerRadius = UDim.new(0, 7)
        tpBtn.MouseButton1Click:Connect(function() runTPFloor() end)
        local fallBtn = Instance.new("TextButton", subPanel)
        fallBtn.ZIndex = 7; fallBtn.Position = UDim2.new(0, 94, 0, 14); fallBtn.Size = UDim2.new(0, 34, 0, 26)
        fallBtn.BackgroundColor3 = C.Background; fallBtn.BorderSizePixel = 0
        fallBtn.Text = "Fall"; fallBtn.TextColor3 = Color3.fromRGB(140, 140, 140)
        fallBtn.TextSize = 9; fallBtn.Font = Enum.Font.GothamBold; fallBtn.AutoButtonColor = false; fallBtn.Active = true
        Instance.new("UICorner", fallBtn).CornerRadius = UDim.new(0, 7)
        local heightLbl = Instance.new("TextLabel", subPanel)
        heightLbl.ZIndex = 7; heightLbl.Position = UDim2.new(0, 144, 0, 2)
        heightLbl.Size = UDim2.new(0, 36, 0, 11); heightLbl.BackgroundTransparency = 1
        heightLbl.Text = "HEIGHT"; heightLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
        heightLbl.TextSize = 6; heightLbl.Font = Enum.Font.GothamBold
        local heightBox = Instance.new("TextBox", subPanel)
        heightBox.ZIndex = 7; heightBox.Position = UDim2.new(0, 144, 0, 14); heightBox.Size = UDim2.new(0, 36, 0, 26)
        heightBox.BackgroundColor3 = Color3.fromRGB(22, 23, 22); heightBox.BorderSizePixel = 0
        heightBox.Text = "20"; heightBox.TextColor3 = C.Text; heightBox.TextSize = 10; heightBox.Font = Enum.Font.GothamBold
        heightBox.ClearTextOnFocus = false
        Instance.new("UICorner", heightBox).CornerRadius = UDim.new(0, 6)
        Instance.new("UIStroke", heightBox).Color = Color3.fromRGB(55, 55, 55)
    end

    -- TP Down
    do
        local sv, _, _, subPanel = mkToggleRow(
            "TP Down", nil, C.RowStrokeOff, 18,
            function(on) saveConfig() end, true
        )
        local kb = createKeybindButton(subPanel, "V", 6)
        kb.Position = UDim2.new(0, 10, 0, 16); kb.Size = UDim2.new(0, 27, 0, 26)
        kb.MouseButton1Click:Connect(function() runTPFloor() end)
    end

    -- COMBAT section
    mkSection("COMBAT", 18)

    -- Counter Bat
    do
        local sv, _, _, subPanel = mkToggleRow(
            "Counter Bat", nil, C.RowStrokeOn, 20,
            function(on)
                batCounterEnabled = on
                if on then startBatCounter() else stopBatCounter() end
                saveConfig()
            end, true
        )
        setBatCounterVisual = sv
        local kb = createKeybindButton(subPanel, "+", 6)
        kb.Position = UDim2.new(0, 10, 0, 16); kb.Size = UDim2.new(0, 27, 0, 26)
        local cbModeLbl = Instance.new("TextLabel", subPanel)
        cbModeLbl.ZIndex = 7; cbModeLbl.Position = UDim2.new(0, 54, 0, 2)
        cbModeLbl.Size = UDim2.new(0, 120, 0, 11); cbModeLbl.BackgroundTransparency = 1
        cbModeLbl.Text = "CB MODE"; cbModeLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
        cbModeLbl.TextSize = 6; cbModeLbl.Font = Enum.Font.GothamBold
        cbModeLbl.TextXAlignment = Enum.TextXAlignment.Left
        local followBtn = Instance.new("TextButton", subPanel)
        followBtn.ZIndex = 7; followBtn.Position = UDim2.new(0, 54, 0, 16); followBtn.Size = UDim2.new(0, 34, 0, 24)
        followBtn.BackgroundColor3 = C.Background; followBtn.BorderSizePixel = 0
        followBtn.Text = "Follow"; followBtn.TextColor3 = Color3.fromRGB(140, 140, 140)
        followBtn.TextSize = 10; followBtn.Font = Enum.Font.GothamBold; followBtn.AutoButtonColor = false; followBtn.Active = true
        Instance.new("UICorner", followBtn).CornerRadius = UDim.new(0, 7)
        local noFollowBtn = Instance.new("TextButton", subPanel)
        noFollowBtn.ZIndex = 7; noFollowBtn.Position = UDim2.new(0, 96, 0, 16); noFollowBtn.Size = UDim2.new(0, 34, 0, 24)
        noFollowBtn.BackgroundColor3 = Color3.fromRGB(120, 0, 0); noFollowBtn.BorderSizePixel = 0
        noFollowBtn.Text = "No Follow"; noFollowBtn.TextColor3 = Color3.fromRGB(255, 200, 200)
        noFollowBtn.TextSize = 10; noFollowBtn.Font = Enum.Font.GothamBold; noFollowBtn.AutoButtonColor = false; noFollowBtn.Active = true
        Instance.new("UICorner", noFollowBtn).CornerRadius = UDim.new(0, 7)
    end

    -- Aimbot Radius
    do
        local sv, _, _, subPanel = mkToggleRow(
            "Aimbot radius", nil, C.RowStrokeOff, 21,
            function(on) saveConfig() end, true
        )
        local kb = createKeybindButton(subPanel, "+", 6)
        kb.Position = UDim2.new(0, 10, 0, 16); kb.Size = UDim2.new(0, 27, 0, 26)
        local radLbl = Instance.new("TextLabel", subPanel)
        radLbl.ZIndex = 7; radLbl.Position = UDim2.new(0, 62, 0, 2)
        radLbl.Size = UDim2.new(0, 46, 0, 11); radLbl.BackgroundTransparency = 1
        radLbl.Text = "RADIUS"; radLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
        radLbl.TextSize = 6; radLbl.Font = Enum.Font.GothamBold
        local aimbotRadBox = Instance.new("TextBox", subPanel)
        aimbotRadBox.ZIndex = 7; aimbotRadBox.Position = UDim2.new(0, 62, 0, 14)
        aimbotRadBox.Size = UDim2.new(0, 46, 0, 24); aimbotRadBox.BackgroundColor3 = Color3.fromRGB(22, 23, 22)
        aimbotRadBox.BorderSizePixel = 0; aimbotRadBox.Text = "15"
        aimbotRadBox.TextColor3 = C.Text; aimbotRadBox.TextSize = 10; aimbotRadBox.Font = Enum.Font.GothamBold
        aimbotRadBox.ClearTextOnFocus = false
        Instance.new("UICorner", aimbotRadBox).CornerRadius = UDim.new(0, 6)
        Instance.new("UIStroke", aimbotRadBox).Color = Color3.fromRGB(55, 55, 55)
    end

    -- Med
    do
        local sv, _, _, subPanel = mkToggleRow(
            "Med", nil, C.RowStrokeOff, 22,
            function(on) saveConfig() end, true
        )
        local kb = createKeybindButton(subPanel, "+", 6)
        kb.Position = UDim2.new(0, 10, 0, 16); kb.Size = UDim2.new(0, 27, 0, 26)
    end

    -- Medusa Counter
    do
        local sv, _, _, _ = mkToggleRow(
            "Medusa Counter", nil, C.RowStrokeOn, 23,
            function(on)
                medusaCounterEnabled = on
                if on then setupMedusa(LocalPlayer.Character) else stopMedusaCounter() end
                saveConfig()
            end, false
        )
        setMedusaVisual = sv
    end

    -- AUTO PLAY AFTER MED
    do
        local sv, _, _, _ = mkToggleRow(
            "AUTO PLAY AFTER MED", nil, C.RowStrokeOff, 24,
            function(on) saveConfig() end, false
        )
    end

    -- Drop Brainrot
    do
        local sv, _, _, subPanel = mkToggleRow(
            "Drop Brainrot", nil, C.RowStrokeOff, 25,
            function(on) saveConfig() end, true
        )
        local kb = createKeybindButton(subPanel, "H", 6)
        kb.Position = UDim2.new(0, 10, 0, 16); kb.Size = UDim2.new(0, 27, 0, 26)
        kb.MouseButton1Click:Connect(function() runDrop() end)
    end

    -- UTILITY section
    mkSection("UTILITY", 25)

    -- Instant Reset
    do
        local sv, _, _, subPanel = mkToggleRow(
            "Instant reset", nil, C.RowStrokeOff, 27,
            function(on) saveConfig() end, true
        )
        local kb = createKeybindButton(subPanel, "+", 6)
        kb.Position = UDim2.new(0, 10, 0, 16); kb.Size = UDim2.new(0, 27, 0, 26)
        kb.MouseButton1Click:Connect(function() cursedInstaReset() end)
    end

    -- No Player Collision
    do
        local sv, _, _, _ = mkToggleRow(
            "No Player Collision", nil, C.RowStrokeOn, 28,
            function(on) saveConfig() end, false
        )
    end

    -- FPS Boost
    do
        local sv, _, _, _ = mkToggleRow(
            "FPS Boost", nil, C.RowStrokeOn, 29,
            function(on)
                if on then enableAntiLag() else disableAntiLag() end
                saveConfig()
            end, false
        )
        setAntiLagVisual = sv
    end

    -- No Animation
    do
        local sv, _, _, _ = mkToggleRow(
            "No Animation", nil, C.RowStrokeOn, 30,
            function(on)
                unwalkEnabled = on
                if on then startUnwalk() else stopUnwalk() end
            end, false
        )
        setUnwalkVisual = sv
    end

    -- Player ESP
    do
        local sv, _, _, subPanel = mkToggleRow(
            "Player ESP", nil, C.RowStrokeOn, 31,
            function(on) saveConfig() end, true
        )
        local espSizeLbl = Instance.new("TextLabel", subPanel)
        espSizeLbl.ZIndex = 6; espSizeLbl.Position = UDim2.new(0, 10, 0, 2)
        espSizeLbl.Size = UDim2.new(0, 46, 0, 12); espSizeLbl.BackgroundTransparency = 1
        espSizeLbl.Text = "PLAYER ESP SIZE"; espSizeLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
        espSizeLbl.TextSize = 6; espSizeLbl.Font = Enum.Font.GothamBold
        local espSizeBox = Instance.new("TextBox", subPanel)
        espSizeBox.ZIndex = 6; espSizeBox.Position = UDim2.new(0, 10, 0, 16)
        espSizeBox.Size = UDim2.new(0, 46, 0, 26); espSizeBox.BackgroundColor3 = C.Background
        espSizeBox.BorderSizePixel = 0; espSizeBox.Text = "6"
        espSizeBox.TextColor3 = C.Text; espSizeBox.TextSize = 10; espSizeBox.Font = Enum.Font.GothamBold
        espSizeBox.ClearTextOnFocus = false
        Instance.new("UICorner", espSizeBox).CornerRadius = UDim.new(0, 6)
        Instance.new("UIStroke", espSizeBox).Color = Color3.fromRGB(55, 55, 55)
    end

    -- FOV
    do
        local sv, _, _, subPanel = mkToggleRow(
            "FOV", nil, C.RowStrokeOn, 32,
            function(on)
                if on then enableStretchRez() else disableStretchRez() end
                saveConfig()
            end, true
        )
        setStretchRezVisual = sv
        local fovLabel = Instance.new("TextLabel", subPanel)
        fovLabel.ZIndex = 6; fovLabel.Position = UDim2.new(0, 10, 0, 2)
        fovLabel.Size = UDim2.new(0, 46, 0, 12); fovLabel.BackgroundTransparency = 1
        fovLabel.Text = "FOV"; fovLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        fovLabel.TextSize = 6; fovLabel.Font = Enum.Font.GothamBold
        FOVBox = Instance.new("TextBox", subPanel)
        FOVBox.ZIndex = 6; FOVBox.Position = UDim2.new(0, 10, 0, 16)
        FOVBox.Size = UDim2.new(0, 46, 0, 26); FOVBox.BackgroundColor3 = C.Background
        FOVBox.BorderSizePixel = 0; FOVBox.Text = "100"
        FOVBox.TextColor3 = C.Text; FOVBox.TextSize = 10; FOVBox.Font = Enum.Font.GothamBold
        FOVBox.ClearTextOnFocus = false
        Instance.new("UICorner", FOVBox).CornerRadius = UDim.new(0, 6)
        Instance.new("UIStroke", FOVBox).Color = Color3.fromRGB(55, 55, 55)
        FOVBox.FocusLost:Connect(function()
            local v = tonumber(FOVBox.Text)
            if v and v >= 30 and v <= 120 then
                workspace.CurrentCamera.FieldOfView = v
            end
        end)
    end

    -- Night Sky
    do
        local sv, _, _, subPanel = mkToggleRow(
            "Night Sky", nil, C.RowStrokeOff, 33,
            function(on) saveConfig() end, true
        )
        local nightLbl = Instance.new("TextLabel", subPanel)
        nightLbl.ZIndex = 6; nightLbl.Position = UDim2.new(0, 10, 0, 2)
        nightLbl.Size = UDim2.new(0, 46, 0, 12); nightLbl.BackgroundTransparency = 1
        nightLbl.Text = "NIGHT DARKNESS"; nightLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
        nightLbl.TextSize = 6; nightLbl.Font = Enum.Font.GothamBold
        NightDarknessBox = Instance.new("TextBox", subPanel)
        NightDarknessBox.ZIndex = 6; NightDarknessBox.Position = UDim2.new(0, 10, 0, 16)
        NightDarknessBox.Size = UDim2.new(0, 46, 0, 26); NightDarknessBox.BackgroundColor3 = C.Background
        NightDarknessBox.BorderSizePixel = 0; NightDarknessBox.Text = "5"
        NightDarknessBox.TextColor3 = C.Text; NightDarknessBox.TextSize = 10; NightDarknessBox.Font = Enum.Font.GothamBold
        NightDarknessBox.ClearTextOnFocus = false
        Instance.new("UICorner", NightDarknessBox).CornerRadius = UDim.new(0, 6)
        Instance.new("UIStroke", NightDarknessBox).Color = Color3.fromRGB(55, 55, 55)
    end

    -- Taunt
    do
        local sv, _, _, subPanel = mkToggleRow(
            "Taunt", nil, C.RowStrokeOff, 34,
            function(on) saveConfig() end, true
        )
        local kb = createKeybindButton(subPanel, "+", 6)
        kb.Position = UDim2.new(0, 10, 0, 16); kb.Size = UDim2.new(0, 27, 0, 26)
        local tauntBtn = Instance.new("TextButton", subPanel)
        tauntBtn.ZIndex = 6; tauntBtn.Position = UDim2.new(0.5, -55, 0.5, -10)
        tauntBtn.Size = UDim2.new(0, 110, 0, 20); tauntBtn.BackgroundColor3 = Color3.fromRGB(32, 33, 32)
        tauntBtn.BorderSizePixel = 0; tauntBtn.Text = CONFIG.HubName .. " MOGGED YOU"
        tauntBtn.TextColor3 = C.Text; tauntBtn.TextSize = 9; tauntBtn.Font = Enum.Font.GothamBold
        tauntBtn.AutoButtonColor = false; tauntBtn.Active = true
        Instance.new("UICorner", tauntBtn).CornerRadius = UDim.new(0, 7)
        Instance.new("UIStroke", tauntBtn).Color = Color3.fromRGB(70, 0, 0)
    end

    -- SETTINGS section
    mkSection("SETTINGS", 34)

    -- Config row
    do
        local cfgFrame = Instance.new("Frame", ScrollingFrame)
        cfgFrame.LayoutOrder = 35; cfgFrame.Size = UDim2.new(1, 0, 0, 34)
        cfgFrame.BackgroundColor3 = Color3.fromRGB(22, 23, 22); cfgFrame.BorderSizePixel = 0
        Instance.new("UICorner", cfgFrame).CornerRadius = UDim.new(0, 10)
        Instance.new("UIStroke", cfgFrame).Color = Color3.fromRGB(55, 0, 0)
        local copyBtn = Instance.new("TextButton", cfgFrame)
        copyBtn.ZIndex = 4; copyBtn.Position = UDim2.new(0, 6, 0.5, -12); copyBtn.Size = UDim2.new(0.5, -9, 0, 24)
        copyBtn.BackgroundColor3 = Color3.fromRGB(32, 33, 32); copyBtn.BorderSizePixel = 0
        copyBtn.Text = "Copy Config"; copyBtn.TextColor3 = C.Text; copyBtn.TextSize = 9; copyBtn.Font = Enum.Font.GothamBold
        copyBtn.AutoButtonColor = false; copyBtn.Active = true
        Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0, 7)
        Instance.new("UIStroke", copyBtn).Color = Color3.fromRGB(70, 0, 0)
        local loadBtn = Instance.new("TextButton", cfgFrame)
        loadBtn.ZIndex = 4; loadBtn.Position = UDim2.new(0.5, 3, 0.5, -12); loadBtn.Size = UDim2.new(0.5, -9, 0, 24)
        loadBtn.BackgroundColor3 = Color3.fromRGB(32, 33, 32); loadBtn.BorderSizePixel = 0
        loadBtn.Text = "Load Config"; loadBtn.TextColor3 = C.Text; loadBtn.TextSize = 9; loadBtn.Font = Enum.Font.GothamBold
        loadBtn.AutoButtonColor = false; loadBtn.Active = true
        Instance.new("UICorner", loadBtn).CornerRadius = UDim.new(0, 7)
        Instance.new("UIStroke", loadBtn).Color = Color3.fromRGB(70, 0, 0)
        copyBtn.MouseButton1Click:Connect(function()
            pcall(function()
                local cfg = HttpService:JSONEncode({
                    normalSpeed = NS, carrySpeed = CS,
                    laggerSpeed = LAGGER_SPEED, laggerCarrySpeed = LAGGER_CARRY_SPEED,
                    stealRadius = Steal.StealRadius,
                })
                if setclipboard then setclipboard(cfg) end
            end)
        end)
    end

    -- Config paste box
    do
        local pasteFrame = Instance.new("Frame", ScrollingFrame)
        pasteFrame.LayoutOrder = 36; pasteFrame.Size = UDim2.new(1, 0, 0, 42)
        pasteFrame.BackgroundColor3 = Color3.fromRGB(22, 23, 22); pasteFrame.BorderSizePixel = 0
        Instance.new("UICorner", pasteFrame).CornerRadius = UDim.new(0, 10)
        Instance.new("UIStroke", pasteFrame).Color = Color3.fromRGB(55, 0, 0)
        local pasteBox = Instance.new("TextBox", pasteFrame)
        pasteBox.ZIndex = 4; pasteBox.ClipsDescendants = true
        pasteBox.Position = UDim2.new(0, 8, 0.5, -13); pasteBox.Size = UDim2.new(1, -16, 0, 26)
        pasteBox.BackgroundColor3 = Color3.fromRGB(32, 33, 32); pasteBox.BorderSizePixel = 0
        pasteBox.Text = ""; pasteBox.TextColor3 = C.Text; pasteBox.TextSize = 9; pasteBox.Font = Enum.Font.GothamBold
        pasteBox.TextTruncate = Enum.TextTruncate.AtEnd
        pasteBox.PlaceholderText = "Paste config code here..."
        pasteBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
        pasteBox.ClearTextOnFocus = false
        Instance.new("UICorner", pasteBox).CornerRadius = UDim.new(0, 7)
        Instance.new("UIStroke", pasteBox).Color = Color3.fromRGB(70, 0, 0)
        local sfPad = Instance.new("UIPadding", pasteBox)
        sfPad.PaddingLeft = UDim.new(0, 6); sfPad.PaddingRight = UDim.new(0, 6)
        pasteBox.FocusLost:Connect(function()
            local ok, cfg = pcall(function() return HttpService:JSONDecode(pasteBox.Text) end)
            if ok and cfg then
                if cfg.normalSpeed      then NS             = cfg.normalSpeed       end
                if cfg.carrySpeed       then CS             = cfg.carrySpeed        end
                if cfg.laggerSpeed      then LAGGER_SPEED   = cfg.laggerSpeed       end
                if cfg.laggerCarrySpeed then LAGGER_CARRY_SPEED = cfg.laggerCarrySpeed end
                if cfg.stealRadius      then Steal.StealRadius = cfg.stealRadius    end
                if NormalSpdBox         then NormalSpdBox.Text = tostring(NS)       end
                if CarrySpdBox          then CarrySpdBox.Text  = tostring(CS)       end
                if LaggerSpdBox         then LaggerSpdBox.Text = tostring(LAGGER_SPEED) end
                if LaggerCarrySpdBox    then LaggerCarrySpdBox.Text = tostring(LAGGER_CARRY_SPEED) end
                if RadiusInput          then RadiusInput.Text = tostring(Steal.StealRadius) end
            end
            pasteBox.Text = ""
        end)
    end

    -- Overhead GUI Size
    do
        local ohFrame = Instance.new("Frame", ScrollingFrame)
        ohFrame.LayoutOrder = 37; ohFrame.Size = UDim2.new(1, 0, 0, 34)
        ohFrame.BackgroundColor3 = Color3.fromRGB(22, 23, 22); ohFrame.BorderSizePixel = 0
        Instance.new("UICorner", ohFrame).CornerRadius = UDim.new(0, 10)
        Instance.new("UIStroke", ohFrame).Color = Color3.fromRGB(55, 0, 0)
        local ohLbl = Instance.new("TextLabel", ohFrame)
        ohLbl.Position = UDim2.new(0, 8, 0, 0); ohLbl.Size = UDim2.new(0, 115, 1, 0)
        ohLbl.BackgroundTransparency = 1; ohLbl.Text = "Button Size"
        ohLbl.TextColor3 = C.Text; ohLbl.TextSize = 9; ohLbl.Font = Enum.Font.GothamBold
        ohLbl.TextXAlignment = Enum.TextXAlignment.Left
        -- minus
        local ohMinus = Instance.new("TextButton", ohFrame)
        ohMinus.Size = UDim2.new(0,24,0,24); ohMinus.Position = UDim2.new(1,-110,0.5,-12)
        ohMinus.BackgroundColor3=Color3.fromRGB(30,30,30); ohMinus.BorderSizePixel=0
        ohMinus.Text="−"; ohMinus.TextColor3=C.Text; ohMinus.TextSize=14; ohMinus.Font=Enum.Font.GothamBlack
        ohMinus.AutoButtonColor=false; ohMinus.ZIndex=4
        Instance.new("UICorner",ohMinus).CornerRadius=UDim.new(0,6)
        -- value label
        local ohVal = Instance.new("TextLabel", ohFrame)
        ohVal.Size=UDim2.new(0,36,1,0); ohVal.Position=UDim2.new(1,-82,0,0)
        ohVal.BackgroundTransparency=1; ohVal.Text="100"
        ohVal.TextColor3=Color3.fromRGB(200,0,0); ohVal.TextSize=10; ohVal.Font=Enum.Font.GothamBlack
        ohVal.TextXAlignment=Enum.TextXAlignment.Center; ohVal.ZIndex=4
        -- plus
        local ohPlus = Instance.new("TextButton", ohFrame)
        ohPlus.Size = UDim2.new(0,24,0,24); ohPlus.Position = UDim2.new(1,-44,0.5,-12)
        ohPlus.BackgroundColor3=Color3.fromRGB(30,30,30); ohPlus.BorderSizePixel=0
        ohPlus.Text="+"; ohPlus.TextColor3=C.Text; ohPlus.TextSize=14; ohPlus.Font=Enum.Font.GothamBlack
        ohPlus.AutoButtonColor=false; ohPlus.ZIndex=4
        Instance.new("UICorner",ohPlus).CornerRadius=UDim.new(0,6)
        local _btnSz = _savedBtnSize
        local function applyBtnSize(v)
            _btnSz = math.clamp(v, 50, 150)
            _savedBtnSize = _btnSz
            ohVal.Text = tostring(_btnSz)
            -- buttons are direct children of the TrublCircleBtns ScreenGui
            local function resizeIn(parent)
                if not parent then return end
                for _, b in pairs(parent:GetChildren()) do
                    if b:IsA("TextButton") then
                        b.Size = UDim2.new(0, _btnSz, 0, _btnSz)
                    end
                end
            end
            pcall(function() resizeIn(game:GetService("CoreGui"):FindFirstChild("TrublCircleBtns")) end)
            pcall(function() resizeIn(LocalPlayer.PlayerGui:FindFirstChild("TrublCircleBtns")) end)
            saveConfig()
        end
        _applyBtnSize = applyBtnSize
        ohVal.Text = tostring(_btnSz)
        ohMinus.MouseButton1Click:Connect(function() applyBtnSize(_btnSz-5) end)
        ohPlus.MouseButton1Click:Connect(function() applyBtnSize(_btnSz+5) end)
    end

    -- GUI size slider row
    do
        local gsFrame = Instance.new("Frame", ScrollingFrame)
        gsFrame.LayoutOrder = 38; gsFrame.Size = UDim2.new(1, 0, 0, 34)
        gsFrame.BackgroundColor3 = Color3.fromRGB(22, 23, 22); gsFrame.BorderSizePixel = 0
        Instance.new("UICorner", gsFrame).CornerRadius = UDim.new(0, 10)
        Instance.new("UIStroke", gsFrame).Color = Color3.fromRGB(55, 0, 0)
        local gsLbl = Instance.new("TextLabel", gsFrame)
        gsLbl.Position = UDim2.new(0, 8, 0, 0); gsLbl.Size = UDim2.new(0, 115, 1, 0)
        gsLbl.BackgroundTransparency = 1; gsLbl.Text = "GUI Size"
        gsLbl.TextColor3 = C.Text; gsLbl.TextSize = 9; gsLbl.Font = Enum.Font.GothamBold
        gsLbl.TextXAlignment = Enum.TextXAlignment.Left
        local gsMinus = Instance.new("TextButton", gsFrame)
        gsMinus.Size = UDim2.new(0,24,0,24); gsMinus.Position = UDim2.new(1,-110,0.5,-12)
        gsMinus.BackgroundColor3=Color3.fromRGB(30,30,30); gsMinus.BorderSizePixel=0
        gsMinus.Text="−"; gsMinus.TextColor3=C.Text; gsMinus.TextSize=14; gsMinus.Font=Enum.Font.GothamBlack
        gsMinus.AutoButtonColor=false; gsMinus.ZIndex=4
        Instance.new("UICorner",gsMinus).CornerRadius=UDim.new(0,6)
        local gsVal = Instance.new("TextLabel", gsFrame)
        gsVal.Size=UDim2.new(0,36,1,0); gsVal.Position=UDim2.new(1,-82,0,0)
        gsVal.BackgroundTransparency=1; gsVal.Text="1.0"
        gsVal.TextColor3=Color3.fromRGB(200,0,0); gsVal.TextSize=10; gsVal.Font=Enum.Font.GothamBlack
        gsVal.TextXAlignment=Enum.TextXAlignment.Center; gsVal.ZIndex=4
        local gsPlus = Instance.new("TextButton", gsFrame)
        gsPlus.Size = UDim2.new(0,24,0,24); gsPlus.Position = UDim2.new(1,-44,0.5,-12)
        gsPlus.BackgroundColor3=Color3.fromRGB(30,30,30); gsPlus.BorderSizePixel=0
        gsPlus.Text="+"; gsPlus.TextColor3=C.Text; gsPlus.TextSize=14; gsPlus.Font=Enum.Font.GothamBlack
        gsPlus.AutoButtonColor=false; gsPlus.ZIndex=4
        Instance.new("UICorner",gsPlus).CornerRadius=UDim.new(0,6)
        local _guiScale = _savedGuiScale
        -- UIScale on MainFrame
        local uiScaleObj = Instance.new("UIScale", MainFrame)
        uiScaleObj.Scale = _guiScale
        local function applyGuiScale(v)
            _guiScale = math.clamp(math.floor(v*10+0.5)/10, 0.5, 2.0)
            _savedGuiScale = _guiScale
            gsVal.Text = string.format("%.1f", _guiScale)
            uiScaleObj.Scale = _guiScale
            saveConfig()
        end
        _applyGuiScale = applyGuiScale
        gsVal.Text = string.format("%.1f", _guiScale)
        gsMinus.MouseButton1Click:Connect(function() applyGuiScale(_guiScale-0.1) end)
        gsPlus.MouseButton1Click:Connect(function() applyGuiScale(_guiScale+0.1) end)
    end

    -- Draggable Buttons toggle
    do
        local dbFrame = Instance.new("Frame", ScrollingFrame)
        dbFrame.LayoutOrder = 39; dbFrame.Size = UDim2.new(1, 0, 0, 34)
        dbFrame.BackgroundColor3 = Color3.fromRGB(22,22,22); dbFrame.BorderSizePixel = 0
        Instance.new("UICorner", dbFrame).CornerRadius = UDim.new(0, 10)
        Instance.new("UIStroke", dbFrame).Color = Color3.fromRGB(55,0,0)
        local dbLbl = Instance.new("TextLabel", dbFrame)
        dbLbl.Position = UDim2.new(0,8,0,0); dbLbl.Size = UDim2.new(0.7,0,1,0)
        dbLbl.BackgroundTransparency=1; dbLbl.Text="Draggable Buttons"
        dbLbl.TextColor3=C.Text; dbLbl.TextSize=9; dbLbl.Font=Enum.Font.GothamBold
        dbLbl.TextXAlignment=Enum.TextXAlignment.Left
        -- toggle pill
        local pillBg = Instance.new("TextButton", dbFrame)
        pillBg.Size=UDim2.new(0,44,0,22); pillBg.Position=UDim2.new(1,-52,0.5,-11)
        pillBg.BackgroundColor3=Color3.fromRGB(200,30,40); pillBg.BorderSizePixel=0
        pillBg.Text=""; pillBg.AutoButtonColor=false; pillBg.ZIndex=4
        Instance.new("UICorner",pillBg).CornerRadius=UDim.new(1,0)
        local pillCirc = Instance.new("Frame", pillBg)
        pillCirc.Size=UDim2.new(0,16,0,16); pillCirc.Position=UDim2.new(1,-19,0.5,-8)
        pillCirc.BackgroundColor3=Color3.fromRGB(255,255,255); pillCirc.BorderSizePixel=0
        Instance.new("UICorner",pillCirc).CornerRadius=UDim.new(1,0)
        local pillOn = true
        local function setPill(on)
            pillOn = on; _btnsDraggable = on
            game:GetService("TweenService"):Create(pillBg,TweenInfo.new(0.15),{
                BackgroundColor3=on and Color3.fromRGB(200,30,40) or Color3.fromRGB(60,60,60)
            }):Play()
            game:GetService("TweenService"):Create(pillCirc,TweenInfo.new(0.15),{
                Position=on and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)
            }):Play()
        end
        pillBg.MouseButton1Click:Connect(function() setPill(not pillOn) end)
    end

    -- FPS / Ping labels
    FpsLabel = Instance.new("TextLabel", MainFrame)
    FpsLabel.Name    = "FpsLabel"
    FpsLabel.ZIndex  = 16
    FpsLabel.Position = UDim2.new(0, 5, 0, 0)
    FpsLabel.Size    = UDim2.new(0, 62, 0, 13)
    FpsLabel.BackgroundTransparency = 1
    FpsLabel.Text    = "FPS: --"
    FpsLabel.TextColor3 = C.Text
    FpsLabel.Font    = Enum.Font.GothamBold
    FpsLabel.TextSize = 9
    FpsLabel.TextXAlignment = Enum.TextXAlignment.Left
    FpsLabel.TextYAlignment = Enum.TextYAlignment.Bottom

    PingLabel = Instance.new("TextLabel", MainFrame)
    PingLabel.Name   = "PingLabel"
    PingLabel.ZIndex = 16
    PingLabel.Position = UDim2.new(0, 5, 0, 13)
    PingLabel.Size   = UDim2.new(0, 62, 0, 13)
    PingLabel.BackgroundTransparency = 1
    PingLabel.Text   = "Ping: --ms"
    PingLabel.TextColor3 = C.Text
    PingLabel.Font   = Enum.Font.GothamBold
    PingLabel.TextSize = 9
    PingLabel.TextXAlignment = Enum.TextXAlignment.Left
    PingLabel.TextYAlignment = Enum.TextYAlignment.Top

    TitleLabel = Instance.new("TextLabel", MainFrame)
    TitleLabel.ZIndex = 16
    TitleLabel.Size   = UDim2.new(1, 0, 0, 26)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text   = CONFIG.HubName
    TitleLabel.TextColor3 = C.Text
    TitleLabel.TextSize   = 11
    TitleLabel.Font       = Enum.Font.GothamBold

    -- Header click to minimize
    HeaderClickArea = Instance.new("TextButton", MainFrame)
    HeaderClickArea.Name  = "HeaderClickArea"
    HeaderClickArea.ZIndex = 5
    HeaderClickArea.Size  = UDim2.new(1, 0, 0, 26)
    HeaderClickArea.BackgroundTransparency = 1
    HeaderClickArea.Text  = ""; HeaderClickArea.AutoButtonColor = false; HeaderClickArea.Active = true
    local minimized = false
    HeaderClickArea.MouseButton1Click:Connect(function()
        minimized = not minimized
        ScrollingFrame.Visible = not minimized
        MainFrame.Size = minimized
            and UDim2.new(0, CONFIG.Size.MainFrame.X.Offset, 0, 30)
            or  CONFIG.Size.MainFrame
    end)

    -- Speed mode label on main frame
    modeValLbl = Instance.new("TextLabel", MainFrame)
    modeValLbl.ZIndex = 17
    modeValLbl.Position = UDim2.new(0, 70, 0, 0)
    modeValLbl.Size = UDim2.new(0, 120, 0, 26)
    modeValLbl.BackgroundTransparency = 1
    modeValLbl.Text = "Normal"
    modeValLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
    modeValLbl.Font = Enum.Font.GothamBold
    modeValLbl.TextSize = 9
    modeValLbl.TextXAlignment = Enum.TextXAlignment.Center

    -- Radius box on header
    local radHeaderLbl = Instance.new("TextLabel", MainFrame)
    radHeaderLbl.ZIndex = 16; radHeaderLbl.Position = UDim2.new(1, -38, 0, 0)
    radHeaderLbl.Size = UDim2.new(0, 36, 0, 13); radHeaderLbl.BackgroundTransparency = 1
    radHeaderLbl.Text = "Radius"; radHeaderLbl.TextColor3 = C.Text
    radHeaderLbl.TextSize = 7; radHeaderLbl.Font = Enum.Font.GothamBold
    radHeaderLbl.TextYAlignment = Enum.TextYAlignment.Bottom
    local radHeaderBox = Instance.new("TextBox", MainFrame)
    radHeaderBox.Name = "TextBox"; radHeaderBox.ZIndex = 16
    radHeaderBox.Position = UDim2.new(1, -36, 0, 14); radHeaderBox.Size = UDim2.new(0, 33, 0, 11)
    radHeaderBox.BackgroundTransparency = 1; radHeaderBox.BorderSizePixel = 0
    radHeaderBox.Text = tostring(Steal.StealRadius)
    radHeaderBox.TextColor3 = C.Text; radHeaderBox.TextSize = 10; radHeaderBox.Font = Enum.Font.GothamBold
    radHeaderBox.FocusLost:Connect(function()
        local v = tonumber(radHeaderBox.Text)
        if v and v >= 1 then
            Steal.StealRadius = v
            if RadiusInput   then RadiusInput.Text   = tostring(v) end
            if ProgressRadLbl then ProgressRadLbl.Text = "RADIUS: " .. tostring(v) end
        else
            radHeaderBox.Text = tostring(Steal.StealRadius)
        end
        saveConfig()
    end)
end

-- // [6] FUNCTIONALITY //

-- FPS updater
task.spawn(function()
    local lastTime = tick()
    local frameCount = 0
    RunService.RenderStepped:Connect(function()
        frameCount += 1
        local now = tick()
        if now - lastTime >= 1 then
            if FpsLabel then FpsLabel.Text = "FPS: " .. frameCount end
            frameCount = 0
            lastTime   = now
        end
    end)
end)

-- Ping updater
task.spawn(function()
    while task.wait(2) do
        pcall(function()
            if PingLabel then
                PingLabel.Text = "Ping: " .. tostring(LocalPlayer:GetAttribute("Ping") or math.random(30, 80)) .. "ms"
            end
        end)
    end
end)

-- Global keybind listener
UserInputService.InputBegan:Connect(function(input, gpe)
    if _anyKeyListening then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        if gpe or UserInputService:GetFocusedTextBox() then return end
    elseif not (input.UserInputType.Name:match("^Gamepad")) then
        return
    end
    local kc = input.KeyCode
    if kbMatch(KB.LaggerToggle, kc) then
        toggleLaggerMode(); saveConfig()
    elseif kbMatch(KB.SpeedToggle, kc) then
        toggleCarryMode(); saveConfig()
    elseif kbMatch(KB.DropBrainrot, kc) then
        runDrop()
    elseif kbMatch(KB.TPFloor, kc) then
        runTPFloor()
    elseif kbMatch(KB.InstaReset, kc) then
        cursedInstaReset()
    elseif kbMatch(KB.AutoLeft, kc) then
        autoLeftEnabled = not autoLeftEnabled
        if autoLeftEnabled then queueAutoLeftStart(); startAutoLeft() else stopAutoLeft() end
        if autoLeftSetVisual then autoLeftSetVisual(autoLeftEnabled) end
    elseif kbMatch(KB.AutoRight, kc) then
        autoRightEnabled = not autoRightEnabled
        if autoRightEnabled then queueAutoRightStart(); startAutoRight() else stopAutoRight() end
        if autoRightSetVisual then autoRightSetVisual(autoRightEnabled) end
    elseif kbMatch(KB.AutoBat, kc) then
        if not autoBatEnabled then
            queueAutoBatStart()
            if autoBatSetVisual then autoBatSetVisual(true) end
        else
            autoBatEnabled = false; disableAutoBat()
            if autoBatSetVisual then autoBatSetVisual(false) end
        end
    elseif kbMatch(KB.GuiHide, kc) then
        if MainFrame then MainFrame.Visible = not MainFrame.Visible end
    end
end)

-- // [7] INITIALIZATION //

local _savedCfg = nil

local function loadConfigKeys()
    if not (isfile and isfile(CONFIG.SaveFile)) then return end
    local ok, cfg = pcall(function() return HttpService:JSONDecode(readfile(CONFIG.SaveFile)) end)
    if not ok or not cfg then return end
    _savedCfg = cfg
    local function lk(e, d)
        if type(d) ~= "table" then return end
        if d.kb and Enum.KeyCode[d.kb] then e.kb = Enum.KeyCode[d.kb] end
        if d.gp and Enum.KeyCode[d.gp] then e.gp = Enum.KeyCode[d.gp] end
    end
    lk(KB.DropBrainrot,  cfg.dropBrainrotKey)
    lk(KB.AutoLeft,      cfg.autoLeftKey)
    lk(KB.AutoRight,     cfg.autoRightKey)
    lk(KB.AutoBat,       cfg.autoBatKey)
    lk(KB.LaggerToggle,  cfg.laggerToggleKey)
    lk(KB.TPFloor,       cfg.tpFloorKey)
    lk(KB.InstaReset,    cfg.instaResetKey)
    lk(KB.GuiHide,       cfg.guiHideKey)
    lk(KB.SpeedToggle,   cfg.speedToggleKey)
    if cfg.normalSpeed      then NS             = cfg.normalSpeed       end
    if cfg.carrySpeed       then CS             = cfg.carrySpeed        end
    if cfg.laggerSpeed      then LAGGER_SPEED   = cfg.laggerSpeed       end
    if cfg.laggerCarrySpeed then LAGGER_CARRY_SPEED = cfg.laggerCarrySpeed end
    if cfg.grabRadius       then Steal.StealRadius  = cfg.grabRadius    end
    if cfg.stealDuration    then Steal.StealDuration = cfg.stealDuration end
    if cfg.autoTPHeight     then autoTPHeight   = cfg.autoTPHeight      end
    if cfg.autoSwing ~= nil then autoSwingEnabled = cfg.autoSwing == true end
    if cfg.circleBtnPositions and type(cfg.circleBtnPositions) == "table" then
        _circleBtnPositions = cfg.circleBtnPositions
    end
    if cfg.btnSize  and type(cfg.btnSize)  == "number" then _savedBtnSize  = cfg.btnSize  end
    if cfg.guiScale and type(cfg.guiScale) == "number" then _savedGuiScale = cfg.guiScale end
end

local function loadConfigState()
    local cfg = _savedCfg; if not cfg then return end
    if NormalSpdBox    then NormalSpdBox.Text    = tostring(NS)               end
    if CarrySpdBox     then CarrySpdBox.Text     = tostring(CS)               end
    if LaggerSpdBox    then LaggerSpdBox.Text    = tostring(LAGGER_SPEED)     end
    if LaggerCarrySpdBox then LaggerCarrySpdBox.Text = tostring(LAGGER_CARRY_SPEED) end
    if RadiusInput     then RadiusInput.Text     = tostring(Steal.StealRadius) end
    if ProgressRadLbl  then ProgressRadLbl.Text  = "RADIUS: " .. tostring(Steal.StealRadius) end
    if AutoTPHeightBox then AutoTPHeightBox.Text = tostring(autoTPHeight)     end
    task.spawn(function()
        task.wait(0.15)
        if cfg.antiRagdoll     then antiRagdollEnabled = true; if setAntiRagVisual  then setAntiRagVisual(true)  end; startAntiRagdoll() end
        if cfg.autoStealEnabled then Steal.AutoStealEnabled = true; if setInstaGrab then setInstaGrab(true) end; pcall(startAutoSteal) end
        if cfg.infiniteJump    then infJumpEnabled = true; if setInfJumpVisual then setInfJumpVisual(true) end end
        if cfg.medusaCounter   then medusaCounterEnabled = true; if setMedusaVisual then setMedusaVisual(true) end; setupMedusa(LocalPlayer.Character) end
        if cfg.batCounter      then batCounterEnabled = true; if setBatCounterVisual then setBatCounterVisual(true) end; startBatCounter() end
        if cfg.laggerMode then
            laggerToggled = true; speedMode = false
            laggerPhase   = cfg.laggerCarryMode and 2 or 1
            refreshSpeedModeLabel()
            if _circleBtnRefs and _circleBtnRefs["lagger"] then _circleBtnRefs["lagger"].setOn(true) end
        elseif cfg.carryMode then
            speedMode = false; toggleCarryMode()
            if _circleBtnRefs and _circleBtnRefs["carry"] then _circleBtnRefs["carry"].setOn(speedMode) end
        end
        if cfg.autoTPEnabled   then autoTPEnabled = true; if setAutoTPVisual  then setAutoTPVisual(true)  end; startAutoTP()
            if _circleBtnRefs and _circleBtnRefs["autoTP"] then _circleBtnRefs["autoTP"].setOn(true) end
        end
        if cfg.autoBat         then autoBatEnabled = true; if autoBatSetVisual then autoBatSetVisual(true) end; queueAutoBatStart()
            if _circleBtnRefs and _circleBtnRefs["bat"] then _circleBtnRefs["bat"].setOn(true) end
        end
        if cfg.unwalkEnabled   then unwalkEnabled = true; if setUnwalkVisual  then setUnwalkVisual(true)  end; task.spawn(function() task.wait(0.5); startUnwalk() end) end
        if cfg.antiLag         then enableAntiLag(); if setAntiLagVisual      then setAntiLagVisual(true)  end end
        if cfg.stretchRez      then enableStretchRez(); if setStretchRezVisual then setStretchRezVisual(true) end end
        -- restore UI sliders
        if _applyBtnSize  then _applyBtnSize(_savedBtnSize)   end
        if _applyGuiScale then _applyGuiScale(_savedGuiScale) end
    end)
end

-- Run
repeat task.wait() until game:IsLoaded()
loadConfigKeys()
createGUI()
loadConfigState()
-- ============================================================
-- CIRCLE QUICK BUTTONS (floating individual, draggable)
-- ============================================================
local _circleBtnRefs = {}
local function buildCircleButtons()
    local TS   = game:GetService("TweenService")
    local UIS4 = game:GetService("UserInputService")

    local gui3 = Instance.new("ScreenGui")
    gui3.Name = "TrublCircleBtns"
    gui3.ResetOnSpawn = false
    pcall(function() gui3.IgnoreGuiInset = true end)
    pcall(function() gui3.Parent = game:GetService("CoreGui") end)
    if not gui3.Parent then gui3.Parent = LocalPlayer.PlayerGui end

    local SZ     = 92
    local DARK   = Color3.fromRGB(18,18,18)
    local RED    = Color3.fromRGB(210,30,40)
    local REDON  = Color3.fromRGB(255,60,70)
    local WHITE  = Color3.fromRGB(235,235,235)
    local ACTIVE = Color3.fromRGB(150,15,25)
    local KILL_C = Color3.fromRGB(255,200,0)  -- kill switch highlight colour

    -- each button has its own independent floating position
    -- spread out so none overlap by default; all draggable individually
    local defs = {
        -- Row 1: right side, top cluster
        {label="AUTO\nLEFT",      key="autoLeft",   pos=UDim2.new(1,-210,0,80),  hasKill=false},
        {label="AUTO\nRIGHT",     key="autoRight",  pos=UDim2.new(1,-310,0,80),  hasKill=false},
        {label="BAT\nAIMBOT",     key="bat",         pos=UDim2.new(1,-410,0,80),  hasKill=false},
        -- Row 2: spread so not overlapping
        {label="AUTO\nTP",        key="autoTP",      pos=UDim2.new(1,-210,0,190), hasKill=true},
        {label="LAGGER",          key="lagger",      pos=UDim2.new(1,-310,0,190), hasKill=true},
        {label="CARRY\nSPD",      key="carry",       pos=UDim2.new(1,-410,0,190), hasKill=true},
        -- Row 3
        {label="DROP\nBRAINROT",  key="drop",        pos=UDim2.new(1,-210,0,300), hasKill=false},
        {label="TP\nDOWN",        key="tpDown",      pos=UDim2.new(1,-310,0,300), hasKill=false},
        {label="INSTA\nRESET",    key="instaReset",  pos=UDim2.new(1,-410,0,300), hasKill=false},
    }

    -- keys that do NOT get wiped when another non-independent button turns on
    local INDEPENDENT = {carry=true, lagger=true, autoTP=true}

    local function killOthers(exceptKey)
        for k, ref in pairs(_circleBtnRefs) do
            if k ~= exceptKey and not INDEPENDENT[k] and not INDEPENDENT[exceptKey] then
                if ref.getState() then
                    ref.setOn(false)
                    -- also stop the actual feature
                    if k == "autoLeft" then
                        autoLeftEnabled = false; pcall(stopAutoLeft)
                        if autoLeftSetVisual then autoLeftSetVisual(false) end
                    elseif k == "autoRight" then
                        autoRightEnabled = false; pcall(stopAutoRight)
                        if autoRightSetVisual then autoRightSetVisual(false) end
                    elseif k == "bat" then
                        pcall(disableAutoBat)
                        if autoBatSetVisual then autoBatSetVisual(false) end
                    elseif k == "drop" then
                        dropActive = false
                    end
                end
            end
        end
    end

    for _, def in ipairs(defs) do
        local btn = Instance.new("TextButton", gui3)
        btn.Size             = UDim2.new(0, SZ, 0, SZ)
        btn.Position         = def.pos
        btn.BackgroundColor3 = DARK
        btn.BorderSizePixel  = 0
        btn.Text             = def.label
        btn.TextColor3       = WHITE
        btn.Font             = Enum.Font.GothamBlack
        btn.TextSize         = 13
        btn.TextWrapped      = true
        btn.AutoButtonColor  = false
        btn.ZIndex           = 12

        local corner = Instance.new("UICorner", btn)
        corner.CornerRadius = UDim.new(1, 0)

        local stroke = Instance.new("UIStroke", btn)
        stroke.Color            = RED
        stroke.Thickness        = 3
        stroke.ApplyStrokeMode  = Enum.ApplyStrokeMode.Border

        -- Kill-switch indicator dot (top-right corner, only for carry/lagger/autoTP)
        local killDot = nil
        if def.hasKill then
            killDot = Instance.new("Frame", btn)
            killDot.Name             = "KillDot"
            killDot.ZIndex           = 14
            killDot.Size             = UDim2.new(0, 14, 0, 14)
            killDot.Position         = UDim2.new(1, -16, 0, 2)
            killDot.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            killDot.BorderSizePixel  = 0
            Instance.new("UICorner", killDot).CornerRadius = UDim.new(1, 0)
            -- clickable kill area
            local killBtn = Instance.new("TextButton", killDot)
            killBtn.Size                  = UDim2.new(1, 0, 1, 0)
            killBtn.BackgroundTransparency= 1
            killBtn.Text                  = "✕"
            killBtn.TextColor3            = Color3.fromRGB(160, 160, 160)
            killBtn.TextSize              = 9
            killBtn.Font                  = Enum.Font.GothamBold
            killBtn.ZIndex                = 15
            killBtn.AutoButtonColor       = false
            killBtn.MouseButton1Click:Connect(function()
                -- kill switch: turn OFF this feature immediately
                pcall(function()
                    if def.key == "carry" then
                        if speedMode then toggleCarryMode() end
                        if _circleBtnRefs["carry"] then _circleBtnRefs["carry"].setOn(false) end
                        saveConfig()
                    elseif def.key == "lagger" then
                        if laggerToggled then
                            laggerToggled = false; laggerPhase = 0
                            refreshSpeedModeLabel(); saveConfig()
                        end
                        if _circleBtnRefs["lagger"] then _circleBtnRefs["lagger"].setOn(false) end
                    elseif def.key == "autoTP" then
                        autoTPEnabled = false; stopAutoTP()
                        if _circleBtnRefs["autoTP"]  then _circleBtnRefs["autoTP"].setOn(false) end
                        if setAutoTPVisual            then setAutoTPVisual(false) end
                        saveConfig()
                    end
                end)
            end)
        end

        local state = false
        local function setOn(on)
            state = on
            TS:Create(btn,   TweenInfo.new(0.12), {BackgroundColor3 = on and ACTIVE or DARK}):Play()
            TS:Create(stroke, TweenInfo.new(0.12), {Color = on and REDON or RED, Thickness = on and 5 or 3}):Play()
            if killDot then
                killDot.BackgroundColor3 = on and KILL_C or Color3.fromRGB(60, 60, 60)
            end
        end
        _circleBtnRefs[def.key] = {setOn = setOn, getState = function() return state end}

        -- ── Restore saved position ──
        if _circleBtnPositions[def.key] then
            local p = _circleBtnPositions[def.key]
            local sw = workspace.CurrentCamera.ViewportSize.X
            local sh = workspace.CurrentCamera.ViewportSize.Y
            local ax = math.clamp(p.x, 0, sw - SZ)
            local ay = math.clamp(p.y, 0, sh - SZ)
            btn.Position = UDim2.new(0, ax, 0, ay)
        end

        -- ── Individual drag (threshold 6px before it counts as drag) ──
        local dragging    = false
        local didDrag     = false
        local dragStart4  = nil
        local startPos4   = nil

        btn.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1
            or inp.UserInputType == Enum.UserInputType.Touch then
                dragging   = true
                didDrag    = false
                dragStart4 = inp.Position
                startPos4  = btn.Position
                inp.Changed:Connect(function()
                    if inp.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)

        UIS4.InputChanged:Connect(function(inp)
            if not dragging or not _btnsDraggable then return end
            if inp.UserInputType == Enum.UserInputType.MouseMovement
            or inp.UserInputType == Enum.UserInputType.Touch then
                local dx = inp.Position.X - dragStart4.X
                local dy = inp.Position.Y - dragStart4.Y
                -- Only start dragging after 6px movement to protect first-click
                if math.abs(dx) > 6 or math.abs(dy) > 6 then
                    didDrag = true
                    local sw = workspace.CurrentCamera.ViewportSize.X
                    local sh = workspace.CurrentCamera.ViewportSize.Y
                    local baseX = startPos4.X.Scale * sw + startPos4.X.Offset
                    local baseY = startPos4.Y.Scale * sh + startPos4.Y.Offset
                    local newX  = math.clamp(baseX + dx, 0, sw - SZ)
                    local newY  = math.clamp(baseY + dy, 0, sh - SZ)
                    btn.Position = UDim2.new(0, newX, 0, newY)
                end
            end
        end)

        -- ── Click handler: fires on InputEnded so drag vs click is clear ──
        btn.InputEnded:Connect(function(inp)
            if inp.UserInputType ~= Enum.UserInputType.MouseButton1
            and inp.UserInputType ~= Enum.UserInputType.Touch then return end
            if didDrag then
                -- save position
                -- save absolute pixel position so it restores correctly regardless of scale
                local absX = btn.Position.X.Scale * workspace.CurrentCamera.ViewportSize.X + btn.Position.X.Offset
                local absY = btn.Position.Y.Scale * workspace.CurrentCamera.ViewportSize.Y + btn.Position.Y.Offset
                _circleBtnPositions[def.key] = {x = absX, y = absY}
                saveConfig()
                return
            end
            pcall(function()
                if def.key == "autoLeft" then
                    killOthers("autoLeft")
                    autoLeftEnabled = not autoLeftEnabled
                    if autoLeftEnabled then startAutoLeft() else stopAutoLeft() end
                    setOn(autoLeftEnabled)
                    if autoLeftSetVisual then autoLeftSetVisual(autoLeftEnabled) end

                elseif def.key == "autoRight" then
                    killOthers("autoRight")
                    autoRightEnabled = not autoRightEnabled
                    if autoRightEnabled then startAutoRight() else stopAutoRight() end
                    setOn(autoRightEnabled)
                    if autoRightSetVisual then autoRightSetVisual(autoRightEnabled) end

                elseif def.key == "bat" then
                    killOthers("bat")
                    if autoBatEnabled then
                        disableAutoBat(); setOn(false)
                        if autoBatSetVisual then autoBatSetVisual(false) end
                    else
                        enableAutoBat(); setOn(true)
                        if autoBatSetVisual then autoBatSetVisual(true) end
                    end

                elseif def.key == "autoTP" then
                    autoTPEnabled = not autoTPEnabled
                    if autoTPEnabled then startAutoTP() else stopAutoTP() end
                    setOn(autoTPEnabled)
                    if setAutoTPVisual then setAutoTPVisual(autoTPEnabled) end
                    saveConfig()

                elseif def.key == "drop" then
                    killOthers("drop")
                    runDrop()
                    task.wait(0.05); setOn(dropActive)

                elseif def.key == "tpDown" then
                    local hrp = LocalPlayer.Character
                        and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        hrp.CFrame = CFrame.new(hrp.Position.X, -7, hrp.Position.Z)
                            * CFrame.Angles(0, select(2, hrp.CFrame:ToEulerAnglesYXZ()), 0)
                    end

                elseif def.key == "lagger" then
                    toggleLaggerMode()
                    setOn(laggerToggled)
                    saveConfig()

                elseif def.key == "carry" then
                    toggleCarryMode()
                    setOn(speedMode)
                    saveConfig()

                elseif def.key == "instaReset" then
                    cursedInstaReset()
                end
            end)
        end)
    end
end

buildCircleButtons()
