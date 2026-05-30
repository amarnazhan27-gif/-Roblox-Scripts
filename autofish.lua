-- ==========================================================
-- INDO HANGOUT ALL-IN-ONE: AUTO FISH + AUTO MINE CRYSTAL
-- ANDROID/DELTA COMPATIBLE - v4.0 SMART MINIGAME
-- ==========================================================
-- SOLUSI MINIGAME:
--   - Masuk minigame TEPAT di 15 detik
--   - Selama minigame: kontrol Space berdasarkan bar GUI
--   - Selesai minigame: deteksi dari GUI MENGHILANG (bukan timer)
--   - Fallback timer 15 detik dari start minigame (max timeout)
-- SOLUSI INDIKATOR:
--   - setFishPhase(0) selalu reset semua dots ke abu-abu
--   - Tombol OFF juga paksa reset semua dots
-- ==========================================================

local Players             = game:GetService("Players")
local RunService          = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser         = game:GetService("VirtualUser")
local PathfindingService  = game:GetService("PathfindingService")
local TweenService        = game:GetService("TweenService")
local player              = Players.LocalPlayer

-- ==========================================
-- STATE & CONFIG
-- ==========================================
local mode            = "OFF"
local isSpacePressed  = false
local fishingState    = "IDLE"
-- States: IDLE -> CASTING -> WAITING -> MINIGAME -> SUCCESS -> IDLE

local lastCastTime        = 0
local lastMinigameGuiSeen = 0
local isCasting           = false
local minigameJustStarted = false
local miningActive        = false
local lastSpaceToggle     = 0
local lastWhiteCenter     = nil
local lastWhiteSample     = os.clock()
local whiteVelocity       = 0
local cachedWhiteBar      = nil
local cachedRedBar        = nil
local lastGuiScan         = 0
local fishCaughtCount     = 0
local crystalMinedCount   = 0
local currentMiningTarget = nil
local miningFailCount     = 0
local miningHitCount      = 0
local minigameStartTime   = 0
local biteWaitStartTime   = 0
local successHandled      = false
local guiEverSeen         = false   -- apakah GUI minigame pernah terdeteksi

-- FISHING TIMING
local FISH_BITE_WAIT     = 15.0  -- 15 detik tepat tunggu gigitan
local FISH_MINIGAME_MAX  = 15.0  -- Max timeout fallback minigame (bukan pakai ini untuk selesai!)
local FISH_RECAST_DELAY  = 1.0   -- Delay sebelum recast
local FISH_CAST_DURATION = 1.8   -- Durasi hold klik cast

-- MINING CONFIG
local FISH_TOOL_NAMES      = {"Fishing Rod", "Rod", "Pancing", "FishingRod"}
local MINE_TOOL_NAMES      = {"Pickaxe", "Cangkul", "Kapak", "Mining", "Pick", "Hammer"}
local CRYSTAL_NAMES        = {"8sisi", "Crystal", "Kristal", "Gem", "Ore", "Batu"}
local CRYSTAL_MATERIAL     = Enum.Material.Neon
local MINE_STOP_DISTANCE   = 2.75
local MINE_MAX_SCAN_DISTANCE = 260
local PATH_RETRY_DELAY     = 0.35
local MINE_SMOOTH_MOVE     = true
local MINE_WALK_SPEED      = 15

-- ==========================================
-- LOGGING
-- ==========================================
local consoleLog  = function() end
local originalWarn = warn

local function customWarn(msg)
    originalWarn(msg)
    if consoleLog then consoleLog(tostring(msg), Color3.fromRGB(255, 255, 100)) end
end
warn = customWarn

local function safeRun(f)
    xpcall(f, function(e)
        originalWarn("ERROR: " .. tostring(e))
        if consoleLog then consoleLog("ERROR: " .. tostring(e), Color3.fromRGB(255, 80, 80)) end
    end)
end

-- ==========================================
-- BERSIHKAN GUI LAMA
-- ==========================================
pcall(function()
    local cg = game:GetService("CoreGui"):FindFirstChild("IH_v4")
    if cg then cg:Destroy() end
    local pg = player:FindFirstChild("PlayerGui") and player.PlayerGui:FindFirstChild("IH_v4")
    if pg then pg:Destroy() end
end)

local gui = Instance.new("ScreenGui")
gui.Name = "IH_v4"
gui.ResetOnSpawn = false

local ok = pcall(function() gui.Parent = game:GetService("CoreGui") end)
if not ok then
    pcall(function() gui.Parent = player:WaitForChild("PlayerGui") end)
    warn("GUI di PlayerGui (CoreGui tidak bisa diakses)")
end

-- ==========================================
-- MAIN FRAME
-- ==========================================
local main = Instance.new("Frame", gui)
main.Size          = UDim2.new(0, 300, 0, 630)
main.Position      = UDim2.new(1, -315, 0, 20)
main.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
main.BorderSizePixel  = 0
main.Active        = true
main.Draggable     = true
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)
local mainStroke = Instance.new("UIStroke", main)
mainStroke.Color = Color3.fromRGB(40, 100, 220); mainStroke.Thickness = 2

-- Title
local titleBar = Instance.new("Frame", main)
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 32)
titleBar.BorderSizePixel  = 0
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 8)

local titleLabel = Instance.new("TextLabel", titleBar)
titleLabel.Size = UDim2.new(1, 0, 1, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text      = "AUTO FARM SYSTEM v4"
titleLabel.TextColor3 = Color3.fromRGB(240, 245, 255)
titleLabel.Font      = Enum.Font.SourceSansBold
titleLabel.TextSize  = 16

-- Status
local statusBar = Instance.new("Frame", main)
statusBar.Size = UDim2.new(1, -16, 0, 32)
statusBar.Position = UDim2.new(0, 8, 0, 50)
statusBar.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
statusBar.BorderSizePixel  = 0
Instance.new("UICorner", statusBar).CornerRadius = UDim.new(0, 4)

local statusLabel = Instance.new("TextLabel", statusBar)
statusLabel.Size = UDim2.new(1, 0, 1, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Text      = "Status: IDLE"
statusLabel.TextColor3 = Color3.fromRGB(150, 220, 255)
statusLabel.Font      = Enum.Font.Code
statusLabel.TextSize  = 13

-- ==========================================
-- FISHING PHASE INDICATOR PANEL
-- ==========================================
local fishPanel = Instance.new("Frame", main)
fishPanel.Size     = UDim2.new(1, -16, 0, 80)
fishPanel.Position = UDim2.new(0, 8, 0, 90)
fishPanel.BackgroundColor3 = Color3.fromRGB(12, 18, 28)
fishPanel.BorderSizePixel  = 0
Instance.new("UICorner", fishPanel).CornerRadius = UDim.new(0, 6)
local fps = Instance.new("UIStroke", fishPanel)
fps.Color = Color3.fromRGB(30, 60, 100); fps.Thickness = 1

local fishPanelTitle = Instance.new("TextLabel", fishPanel)
fishPanelTitle.Size = UDim2.new(1, 0, 0, 18)
fishPanelTitle.Position = UDim2.new(0, 0, 0, 4)
fishPanelTitle.BackgroundTransparency = 1
fishPanelTitle.Text      = "FISHING PHASE"
fishPanelTitle.TextColor3 = Color3.fromRGB(80, 130, 200)
fishPanelTitle.Font      = Enum.Font.SourceSansSemibold
fishPanelTitle.TextSize  = 11

local phaseNames  = {"CAST", "WAIT", "GAME", "DONE"}
local phaseColors = {
    Color3.fromRGB(80,  160, 255),  -- CAST = biru
    Color3.fromRGB(255, 200,  50),  -- WAIT = kuning
    Color3.fromRGB(255,  80, 200),  -- GAME = pink/magenta
    Color3.fromRGB(80,  255, 130),  -- DONE = hijau
}
local COLOR_INACTIVE = Color3.fromRGB(35, 35, 50)
local COLOR_DONE_DOT = Color3.fromRGB(40, 100, 55)
local COLOR_DONE_LBL = Color3.fromRGB(80, 200, 100)
local COLOR_PEND_LBL = Color3.fromRGB(70, 70, 90)

local phaseDots    = {}
local phaseLabels  = {}
local phaseTweens  = {}  -- simpan tween aktif agar bisa dibatalkan

for i, name in ipairs(phaseNames) do
    local container = Instance.new("Frame", fishPanel)
    container.Size     = UDim2.new(0.22, 0, 0, 46)
    container.Position = UDim2.new((i - 1) * 0.245 + 0.01, 0, 0, 24)
    container.BackgroundTransparency = 1

    local dot = Instance.new("Frame", container)
    dot.Size             = UDim2.new(0, 18, 0, 18)
    dot.Position         = UDim2.new(0.5, -9, 0, 2)
    dot.BackgroundColor3 = COLOR_INACTIVE
    dot.BorderSizePixel  = 0
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
    local ds = Instance.new("UIStroke", dot)
    ds.Color = Color3.fromRGB(60, 60, 80); ds.Thickness = 1.5

    local lbl = Instance.new("TextLabel", container)
    lbl.Size = UDim2.new(1, 0, 0, 18)
    lbl.Position = UDim2.new(0, 0, 0, 24)
    lbl.BackgroundTransparency = 1
    lbl.Text      = name
    lbl.TextColor3 = COLOR_PEND_LBL
    lbl.Font      = Enum.Font.SourceSansBold
    lbl.TextSize  = 10

    phaseDots[i]   = dot
    phaseLabels[i] = lbl
    phaseTweens[i] = nil
end

-- Garis penghubung
for i = 1, 3 do
    local line = Instance.new("Frame", fishPanel)
    line.Size     = UDim2.new(0.18, 0, 0, 2)
    line.Position = UDim2.new(i * 0.245 - 0.06, 0, 0, 33)
    line.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    line.BorderSizePixel  = 0
end

-- Progress bar fase
local timerBar = Instance.new("Frame", fishPanel)
timerBar.Size     = UDim2.new(1, -12, 0, 5)
timerBar.Position = UDim2.new(0, 6, 1, -9)
timerBar.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
timerBar.BorderSizePixel  = 0
Instance.new("UICorner", timerBar).CornerRadius = UDim.new(1, 0)

local timerFill = Instance.new("Frame", timerBar)
timerFill.Size = UDim2.new(0, 0, 1, 0)
timerFill.BackgroundColor3 = Color3.fromRGB(100, 180, 255)
timerFill.BorderSizePixel  = 0
Instance.new("UICorner", timerFill).CornerRadius = UDim.new(1, 0)

-- ==========================================
-- SET FISH PHASE (FIX: selalu reset semua dot dulu)
-- ==========================================
local activeFishPhase = -1  -- -1 = belum diinit

local function stopAllPhaseTweens()
    for i = 1, #phaseTweens do
        if phaseTweens[i] then
            phaseTweens[i]:Cancel()
            phaseTweens[i] = nil
        end
    end
end

local function setFishPhase(phaseIdx)
    -- Selalu jalankan, tidak ada early return agar reset selalu bekerja
    activeFishPhase = phaseIdx

    -- Hentikan semua animasi pulse dulu
    stopAllPhaseTweens()

    -- Reset semua dot ke abu-abu dulu
    for i = 1, #phaseDots do
        phaseDots[i].BackgroundColor3 = COLOR_INACTIVE
        phaseLabels[i].TextColor3     = COLOR_PEND_LBL
    end

    timerFill.BackgroundColor3 = Color3.fromRGB(100, 180, 255)

    if phaseIdx == 0 then
        -- Mode OFF: semua abu-abu, bar kosong
        timerFill.Size = UDim2.new(0, 0, 1, 0)
        return
    end

    -- Warnai dot sesuai fase
    for i = 1, #phaseDots do
        local dot = phaseDots[i]
        local lbl = phaseLabels[i]
        if i < phaseIdx then
            -- Sudah selesai
            dot.BackgroundColor3 = COLOR_DONE_DOT
            lbl.TextColor3       = COLOR_DONE_LBL
        elseif i == phaseIdx then
            -- Aktif sekarang
            dot.BackgroundColor3 = phaseColors[i]
            lbl.TextColor3       = phaseColors[i]
            -- Pulse animation
            local tw = TweenService:Create(
                dot,
                TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
                {BackgroundColor3 = dot.BackgroundColor3:Lerp(Color3.fromRGB(255, 255, 255), 0.35)}
            )
            tw:Play()
            phaseTweens[i] = tw
        end
        -- i > phaseIdx: sudah di-reset ke abu-abu di atas
    end

    timerFill.BackgroundColor3 = phaseColors[math.clamp(phaseIdx, 1, 4)]
end

local function updateTimerFill(fraction)
    timerFill.Size = UDim2.new(math.clamp(fraction, 0, 1), 0, 1, 0)
end

-- ==========================================
-- TOMBOL FISH & MINE
-- ==========================================
local btnFish = Instance.new("TextButton", main)
btnFish.Size   = UDim2.new(1, -16, 0, 36)
btnFish.Position = UDim2.new(0, 8, 0, 178)
btnFish.BackgroundColor3 = Color3.fromRGB(35, 45, 70)
btnFish.Text      = "FISHING"
btnFish.Font      = Enum.Font.SourceSansBold
btnFish.TextSize  = 14
btnFish.TextColor3 = Color3.fromRGB(200, 200, 200)
btnFish.BorderSizePixel = 0
Instance.new("UICorner", btnFish).CornerRadius = UDim.new(0, 4)
local btnFishStroke = Instance.new("UIStroke", btnFish)
btnFishStroke.Color = Color3.fromRGB(60, 120, 200); btnFishStroke.Thickness = 1

local btnMine = Instance.new("TextButton", main)
btnMine.Size   = UDim2.new(1, -16, 0, 36)
btnMine.Position = UDim2.new(0, 8, 0, 220)
btnMine.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
btnMine.Text      = "MINING"
btnMine.Font      = Enum.Font.SourceSansBold
btnMine.TextSize  = 14
btnMine.TextColor3 = Color3.fromRGB(200, 200, 200)
btnMine.BorderSizePixel = 0
Instance.new("UICorner", btnMine).CornerRadius = UDim.new(0, 4)
local btnMineStroke = Instance.new("UIStroke", btnMine)
btnMineStroke.Color = Color3.fromRGB(80, 80, 100); btnMineStroke.Thickness = 1

-- Statistik
local statTitle = Instance.new("TextLabel", main)
statTitle.Size = UDim2.new(1, 0, 0, 18)
statTitle.Position = UDim2.new(0, 0, 0, 266)
statTitle.BackgroundTransparency = 1
statTitle.Text = "STATISTICS"
statTitle.TextColor3 = Color3.fromRGB(100, 150, 200)
statTitle.Font = Enum.Font.SourceSansSemibold; statTitle.TextSize = 12

local resultFishLabel = Instance.new("TextLabel", main)
resultFishLabel.Size = UDim2.new(0.5, -10, 0, 28)
resultFishLabel.Position = UDim2.new(0, 8, 0, 288)
resultFishLabel.BackgroundColor3 = Color3.fromRGB(25, 40, 60)
resultFishLabel.Text = "Fish: 0"
resultFishLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
resultFishLabel.Font = Enum.Font.SourceSansSemibold; resultFishLabel.TextSize = 12
resultFishLabel.BorderSizePixel = 0
Instance.new("UICorner", resultFishLabel).CornerRadius = UDim.new(0, 3)

local resultMineLabel = Instance.new("TextLabel", main)
resultMineLabel.Size = UDim2.new(0.5, -10, 0, 28)
resultMineLabel.Position = UDim2.new(0.5, 2, 0, 288)
resultMineLabel.BackgroundColor3 = Color3.fromRGB(45, 40, 25)
resultMineLabel.Text = "Crystal: 0"
resultMineLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
resultMineLabel.Font = Enum.Font.SourceSansSemibold; resultMineLabel.TextSize = 12
resultMineLabel.BorderSizePixel = 0
Instance.new("UICorner", resultMineLabel).CornerRadius = UDim.new(0, 3)

-- Settings (Mine)
local settingsTitle = Instance.new("TextLabel", main)
settingsTitle.Size = UDim2.new(1, 0, 0, 18)
settingsTitle.Position = UDim2.new(0, 0, 0, 326)
settingsTitle.BackgroundTransparency = 1
settingsTitle.Text = "SETTINGS (Mine)"
settingsTitle.TextColor3 = Color3.fromRGB(100, 150, 200)
settingsTitle.Font = Enum.Font.SourceSansSemibold; settingsTitle.TextSize = 12

local function makeSettingBox(labelText, yPos, defaultText)
    local label = Instance.new("TextLabel", main)
    label.Size = UDim2.new(0.55, 0, 0, 20)
    label.Position = UDim2.new(0, 8, 0, yPos)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(130, 140, 160)
    label.Font = Enum.Font.SourceSans; label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left

    local box = Instance.new("TextBox", main)
    box.Size = UDim2.new(0.38, 0, 0, 20)
    box.Position = UDim2.new(0.62, 0, 0, yPos)
    box.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    box.TextColor3 = Color3.fromRGB(180, 220, 255)
    box.PlaceholderColor3 = Color3.fromRGB(80, 90, 110)
    box.Text = defaultText; box.ClearTextOnFocus = false
    box.Font = Enum.Font.SourceSans; box.TextSize = 11
    box.BorderSizePixel = 0
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 2)
    local s = Instance.new("UIStroke", box)
    s.Color = Color3.fromRGB(50, 70, 100); s.Thickness = 1
    return box
end

local rangeBox  = makeSettingBox("Mine Range",  350, string.format("%.1f", MINE_STOP_DISTANCE))

local btnSmooth = Instance.new("TextButton", main)
btnSmooth.Size = UDim2.new(0.48, 0, 0, 24)
btnSmooth.Position = UDim2.new(0, 8, 0, 378)
btnSmooth.BackgroundColor3 = Color3.fromRGB(40, 60, 80)
btnSmooth.Text = "Smooth: ON"; btnSmooth.Font = Enum.Font.SourceSans; btnSmooth.TextSize = 10
btnSmooth.TextColor3 = Color3.fromRGB(200, 200, 200); btnSmooth.BorderSizePixel = 0
Instance.new("UICorner", btnSmooth).CornerRadius = UDim.new(0, 3)

local btnSpeed = Instance.new("TextButton", main)
btnSpeed.Size = UDim2.new(0.48, 0, 0, 24)
btnSpeed.Position = UDim2.new(0.52, 0, 0, 378)
btnSpeed.BackgroundColor3 = Color3.fromRGB(40, 60, 80)
btnSpeed.Text = "Speed: 15"; btnSpeed.Font = Enum.Font.SourceSans; btnSpeed.TextSize = 10
btnSpeed.TextColor3 = Color3.fromRGB(200, 200, 200); btnSpeed.BorderSizePixel = 0
Instance.new("UICorner", btnSpeed).CornerRadius = UDim.new(0, 3)

-- ==========================================
-- CONSOLE
-- ==========================================
local conTitle = Instance.new("TextLabel", main)
conTitle.Size = UDim2.new(1, -60, 0, 18)
conTitle.Position = UDim2.new(0, 8, 0, 414)
conTitle.BackgroundTransparency = 1
conTitle.Text = "CONSOLE"; conTitle.TextColor3 = Color3.fromRGB(100, 150, 200)
conTitle.Font = Enum.Font.SourceSansSemibold; conTitle.TextSize = 12

local btnClear = Instance.new("TextButton", main)
btnClear.Size = UDim2.new(0, 40, 0, 18)
btnClear.Position = UDim2.new(1, -48, 0, 414)
btnClear.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
btnClear.Text = "Clear"; btnClear.Font = Enum.Font.SourceSans; btnClear.TextSize = 9
btnClear.TextColor3 = Color3.fromRGB(200, 200, 200); btnClear.BorderSizePixel = 0
Instance.new("UICorner", btnClear).CornerRadius = UDim.new(0, 3)

local consoleBox = Instance.new("TextBox", main)
consoleBox.Size = UDim2.new(1, -16, 0, 170)
consoleBox.Position = UDim2.new(0, 8, 0, 434)
consoleBox.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
consoleBox.TextColor3 = Color3.fromRGB(200, 200, 200)
consoleBox.Font = Enum.Font.Code; consoleBox.TextSize = 10
consoleBox.TextXAlignment = Enum.TextXAlignment.Left
consoleBox.TextYAlignment = Enum.TextYAlignment.Top
consoleBox.Text = ""; consoleBox.ClearTextOnFocus = false
consoleBox.TextEditable = false; consoleBox.MultiLine = true
consoleBox.TextWrapped = true; consoleBox.BorderSizePixel = 0
Instance.new("UICorner", consoleBox).CornerRadius = UDim.new(0, 3)
local cbs = Instance.new("UIStroke", consoleBox)
cbs.Color = Color3.fromRGB(60, 60, 80); cbs.Thickness = 1

local consoleMaxLines = 60
local function addConsoleLog(text)
    local ts   = os.date("%H:%M:%S")
    local line = "[" .. ts .. "] " .. tostring(text)
    local cur  = consoleBox.Text
    cur = (#cur > 0) and (cur .. "\n" .. line) or line
    local lines = {}
    for l in cur:gmatch("[^\n]+") do table.insert(lines, l) end
    while #lines > consoleMaxLines do table.remove(lines, 1) end
    consoleBox.Text = table.concat(lines, "\n")
end
consoleLog = addConsoleLog

btnClear.MouseButton1Click:Connect(function() consoleBox.Text = "" end)

-- ==========================================
-- HELPERS UMUM
-- ==========================================
local function updateResultLabels()
    resultFishLabel.Text = "Fish: "    .. tostring(fishCaughtCount)
    resultMineLabel.Text = "Crystal: " .. tostring(crystalMinedCount)
end

local function setStatus(text)
    statusLabel.Text = text
end

local function findTool(nameList)
    local char = player.Character
    local bp   = player.Backpack
    for _, name in ipairs(nameList) do
        if char then
            local t = char:FindFirstChild(name)
            if t and t:IsA("Tool") then return t, "hand" end
        end
        local t = bp:FindFirstChild(name)
        if t then return t, "backpack" end
    end
    if char then
        local t = char:FindFirstChildWhichIsA("Tool")
        if t then return t, "hand" end
    end
    local t = bp:FindFirstChildWhichIsA("Tool")
    if t then return t, "backpack" end
    return nil, nil
end

local function equipTool(nameList)
    local char = player.Character
    if not char then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return nil end
    local inHand = char:FindFirstChildWhichIsA("Tool")
    for _, name in ipairs(nameList) do
        if inHand and inHand.Name:lower():find(name:lower()) then return inHand end
    end
    local tool, loc = findTool(nameList)
    if tool and loc == "backpack" then
        pcall(function() hum:EquipTool(tool) end)
        task.wait(0.8)
        return char:FindFirstChildWhichIsA("Tool")
    end
    return inHand
end

-- ==========================================
-- FISHING: RESET STATE (FIX: paksa reset dots)
-- ==========================================
local function resetFishingState()
    isCasting         = false
    isSpacePressed    = false
    minigameJustStarted = false
    successHandled    = false
    guiEverSeen       = false
    cachedWhiteBar    = nil
    cachedRedBar      = nil
    lastGuiScan       = 0
    lastWhiteCenter   = nil
    whiteVelocity     = 0
    lastMinigameGuiSeen = 0
    fishingState      = "IDLE"
    -- FIX: paksa reset semua fase indicator
    setFishPhase(0)
    updateTimerFill(0)
end

-- ==========================================
-- FISHING: SPACE HELPER
-- ==========================================
local function setSpaceKey(pressed, force)
    if isSpacePressed == pressed then return end
    local now = os.clock()
    if not force and now - lastSpaceToggle < 0.035 then return end
    pcall(function() VirtualInputManager:SendKeyEvent(pressed, Enum.KeyCode.Space, false, game) end)
    isSpacePressed    = pressed
    lastSpaceToggle   = now
end

-- ==========================================
-- FISHING: DETEKSI BAR MINIGAME
-- ==========================================
local function getFishingElements()
    -- Pakai cache jika masih valid
    if cachedWhiteBar and cachedRedBar
       and cachedWhiteBar.Parent and cachedRedBar.Parent
       and cachedWhiteBar.Visible and cachedRedBar.Visible then
        return cachedWhiteBar, cachedRedBar
    end

    local now = os.clock()
    if now - lastGuiScan < 0.06 then return nil, nil end
    lastGuiScan = now

    local pg = player:FindFirstChild("PlayerGui")
    if not pg then return nil, nil end

    -- Pass 1: nama eksak
    for _, v in pairs(pg:GetDescendants()) do
        if v:IsA("GuiObject") and v.Visible then
            local lname  = v.Name:lower()
            local parent = v.Parent
            if (lname == "whitebar" or lname:match("^whitebar") or lname:match("whitebar$") or
                lname == "playerbar" or (lname:find("white") and lname:find("bar"))) and
               parent and parent:IsA("GuiObject") then
                local red = parent:FindFirstChild("RedBar") or parent:FindFirstChild("redbar") or
                            parent:FindFirstChild("TargetBar") or parent:FindFirstChild("targetbar")
                if not red then
                    for _, sib in ipairs(parent:GetChildren()) do
                        if sib ~= v and sib:IsA("GuiObject") and sib.Visible then
                            local sn = sib.Name:lower()
                            if sn:find("red") or sn:find("target") or sn:find("goal") or sn:find("indicator") then
                                red = sib; break
                            end
                        end
                    end
                end
                if red and v.AbsoluteSize.X > 10 and v.AbsoluteSize.Y > 5 then
                    cachedWhiteBar = v; cachedRedBar = red
                    return v, red
                end
            end
        end
    end

    -- Pass 2: heuristik warna
    for _, v in pairs(pg:GetDescendants()) do
        if v:IsA("GuiObject") and v.Visible
           and v.AbsoluteSize.X > 15 and v.AbsoluteSize.Y > 6 then
            local c = v.BackgroundColor3
            local p = v.Parent
            if c.R > 0.85 and c.G > 0.85 and c.B > 0.85 and p and p:IsA("GuiObject") then
                for _, sib in ipairs(p:GetChildren()) do
                    if sib ~= v and sib:IsA("GuiObject") and sib.Visible and sib.AbsoluteSize.X > 15 then
                        local sc = sib.BackgroundColor3
                        if sc.R > 0.52 and sc.G < 0.28 and sc.B < 0.28 then
                            cachedWhiteBar = v; cachedRedBar = sib
                            return v, sib
                        end
                    end
                end
            end
        end
    end

    cachedWhiteBar = nil; cachedRedBar = nil
    return nil, nil
end

-- ==========================================
-- FISHING: HANDLE SUCCESS
-- ==========================================
local function handleFishSuccess(reason)
    if successHandled then return end
    successHandled = true

    setSpaceKey(false, true)
    fishingState = "SUCCESS"
    setFishPhase(4)
    updateTimerFill(1)

    fishCaughtCount = fishCaughtCount + 1
    updateResultLabels()
    isSpacePressed      = false
    minigameJustStarted = false

    local msg = "✅ Ikan tertangkap! (" .. tostring(fishCaughtCount) .. ")"
    if reason then msg = msg .. " [" .. reason .. "]" end
    setStatus(msg)
    warn("[FISHING] " .. msg)

    -- Recast setelah delay
    task.spawn(function()
        task.wait(FISH_RECAST_DELAY)
        if mode ~= "FISH" then return end
        resetFishingState()
        warn("[FISHING] Recast...")
        task.wait(0.1)
        task.spawn(function()
            local function castRodInner()
                if isCasting then return end
                isCasting = true
                safeRun(function()
                    local cam = workspace.CurrentCamera
                    if not cam then isCasting = false; return end
                    local sc = cam.ViewportSize / 2

                    fishingState = "CASTING"
                    setFishPhase(1)
                    updateTimerFill(0)
                    setStatus("🎣 Melempar umpan...")
                    warn("[FISHING] Melempar umpan...")

                    local tool = player.Character and player.Character:FindFirstChildWhichIsA("Tool")
                    if tool then pcall(function() tool:Activate() end) end
                    pcall(function() VirtualUser:Button1Down(sc, cam.CFrame) end)

                    local castStart = os.clock()
                    while os.clock() - castStart < FISH_CAST_DURATION do
                        task.wait(0.05)
                        if mode ~= "FISH" then
                            pcall(function() VirtualUser:Button1Up(sc, cam.CFrame) end)
                            isCasting = false; return
                        end
                        updateTimerFill((os.clock() - castStart) / FISH_CAST_DURATION)
                    end

                    pcall(function() VirtualUser:Button1Up(sc, cam.CFrame) end)
                    if tool then pcall(function() tool:Deactivate() end) end
                    updateTimerFill(1)
                    task.wait(0.2)

                    if mode == "FISH" then
                        fishingState     = "WAITING"
                        biteWaitStartTime = os.clock()
                        lastCastTime     = os.clock()
                        setFishPhase(2)
                        updateTimerFill(0)
                        setStatus("⏳ Menunggu gigitan... (15s)")
                        warn("[FISHING] Umpan dilempar! Menunggu 15 detik...")
                    end
                end)
                task.wait(0.2)
                isCasting = false
            end
            castRodInner()
        end)
    end)
end

-- ==========================================
-- FISHING: CAST ROD (forward declaration workaround)
-- ==========================================
local castRod
castRod = function()
    if isCasting then return end
    isCasting = true
    safeRun(function()
        local cam = workspace.CurrentCamera
        if not cam then isCasting = false; return end
        local sc = cam.ViewportSize / 2

        fishingState = "CASTING"
        setFishPhase(1)
        updateTimerFill(0)
        setStatus("🎣 Melempar umpan...")
        warn("[FISHING] Melempar umpan...")

        local tool = player.Character and player.Character:FindFirstChildWhichIsA("Tool")
        if tool then pcall(function() tool:Activate() end) end
        pcall(function() VirtualUser:Button1Down(sc, cam.CFrame) end)

        local castStart = os.clock()
        while os.clock() - castStart < FISH_CAST_DURATION do
            task.wait(0.05)
            if mode ~= "FISH" then
                pcall(function() VirtualUser:Button1Up(sc, cam.CFrame) end)
                isCasting = false; return
            end
            updateTimerFill((os.clock() - castStart) / FISH_CAST_DURATION)
        end

        pcall(function() VirtualUser:Button1Up(sc, cam.CFrame) end)
        if tool then pcall(function() tool:Deactivate() end) end
        updateTimerFill(1)
        task.wait(0.2)

        if mode == "FISH" then
            fishingState     = "WAITING"
            biteWaitStartTime = os.clock()
            lastCastTime     = os.clock()
            setFishPhase(2)
            updateTimerFill(0)
            setStatus("⏳ Menunggu gigitan... (15s)")
            warn("[FISHING] Umpan dilempar! Menunggu 15 detik...")
        end
    end)
    task.wait(0.2)
    isCasting = false
end

-- ==========================================
-- HEARTBEAT: FISHING CONTROLLER
-- ==========================================
RunService.Heartbeat:Connect(function()
    if mode ~= "FISH" then
        if isSpacePressed then
            pcall(function() VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game) end)
            isSpacePressed = false
        end
        return
    end

    safeRun(function()
        local now = os.clock()

        -- ── WAITING: hitung 15 detik ────────────────────────────────────
        if fishingState == "WAITING" then
            local elapsed  = now - biteWaitStartTime
            local fraction = math.clamp(elapsed / FISH_BITE_WAIT, 0, 1)
            updateTimerFill(fraction)
            setStatus(string.format("⏳ Menunggu gigitan... %.1fs", math.max(0, FISH_BITE_WAIT - elapsed)))

            if elapsed >= FISH_BITE_WAIT then
                -- Tepat 15 detik → masuk minigame
                fishingState     = "MINIGAME"
                minigameStartTime = now
                successHandled   = false
                guiEverSeen      = false
                minigameJustStarted = false
                lastMinigameGuiSeen = 0
                cachedWhiteBar   = nil
                cachedRedBar     = nil
                lastGuiScan      = 0
                lastWhiteCenter  = nil
                whiteVelocity    = 0
                setSpaceKey(false, true)
                setFishPhase(3)
                updateTimerFill(0)
                setStatus("🎮 Minigame dimulai!")
                warn("[FISHING] 15 detik → Masuk minigame!")
            end
            return
        end

        -- ── MINIGAME ─────────────────────────────────────────────────────
        if fishingState == "MINIGAME" then
            local elapsed = now - minigameStartTime

            -- Update progress bar (max display 15 detik)
            updateTimerFill(math.clamp(elapsed / FISH_MINIGAME_MAX, 0, 1))

            -- FALLBACK: jika lebih dari FISH_MINIGAME_MAX detik → paksa selesai
            if elapsed >= FISH_MINIGAME_MAX then
                setSpaceKey(false, true)
                warn("[FISHING] Timeout fallback " .. FISH_MINIGAME_MAX .. "s → paksa selesai")
                handleFishSuccess("timeout")
                return
            end

            local white, red = getFishingElements()

            if white and red and white.Visible and red.Visible then
                -- ── GUI TERDETEKSI ──────────────────────────────────────
                guiEverSeen         = true
                lastMinigameGuiSeen = now

                if not minigameJustStarted then
                    minigameJustStarted = true
                    setSpaceKey(false, true)
                    lastWhiteCenter = nil
                    whiteVelocity   = 0
                end

                -- Hitung posisi bar
                local whiteCenter = white.AbsolutePosition.X + white.AbsoluteSize.X / 2
                local redLeft     = red.AbsolutePosition.X
                local redRight    = red.AbsolutePosition.X + red.AbsoluteSize.X
                local redCenter   = (redLeft + redRight) / 2
                local dt          = math.max(now - lastWhiteSample, 0.012)

                if lastWhiteCenter then
                    local inst   = (whiteCenter - lastWhiteCenter) / dt
                    whiteVelocity = whiteVelocity * 0.72 + inst * 0.28
                end
                lastWhiteCenter = whiteCenter
                lastWhiteSample = now

                local lookAhead = math.clamp(math.abs(whiteVelocity) / 2000, 0.04, 0.12)
                local predicted = whiteCenter + whiteVelocity * lookAhead
                local redWidth  = math.max(red.AbsoluteSize.X, 1)
                local tolerance = math.clamp(redWidth * 0.22, 6, 18)
                local inside    = predicted >= (redLeft - tolerance) and predicted <= (redRight + tolerance)

                if inside then
                    if whiteCenter < redLeft then
                        setSpaceKey(true)
                    elseif whiteCenter > redRight then
                        setSpaceKey(false)
                    else
                        local err = whiteCenter - redCenter
                        if math.abs(err) > tolerance * 0.5 then setSpaceKey(err < 0) end
                    end
                else
                    local err = redCenter - predicted
                    if     err >  tolerance then setSpaceKey(true)
                    elseif err < -tolerance then setSpaceKey(false)
                    elseif math.abs(whiteVelocity) > 200 then setSpaceKey(whiteVelocity < 0) end
                end

                setStatus(string.format("🎮 Minigame... %.1fs", elapsed))

            else
                -- ── GUI TIDAK TERDETEKSI ────────────────────────────────
                if guiEverSeen then
                    -- GUI PERNAH terlihat, tapi SEKARANG HILANG
                    -- → Ini tandanya minigame SELESAI (ikan tertangkap / gagal)
                    -- Beri grace period 0.25 detik agar tidak false-positive
                    if lastMinigameGuiSeen > 0 and (now - lastMinigameGuiSeen) >= 0.25 then
                        setSpaceKey(false, true)
                        warn("[FISHING] GUI hilang setelah " .. string.format("%.1f", elapsed) .. "s → Minigame selesai!")
                        handleFishSuccess("gui-disappeared")
                        return
                    end
                else
                    -- GUI belum pernah terdeteksi: lakukan rhythmic tapping sambil tunggu GUI muncul
                    -- (kadang GUI muncul sedikit terlambat setelah 15 detik)
                    local rhythm = (math.floor(elapsed * 4) % 2 == 0)
                    setSpaceKey(rhythm)
                    setStatus(string.format("🎮 Menunggu GUI... %.1fs", elapsed))
                end
            end
            return
        end

        -- ── SUCCESS: tunggu saja (handleFishSuccess sudah handle recast) ─
        if fishingState == "SUCCESS" then return end
    end)
end)

-- ==========================================
-- FISHING EQUIP + CAST LOOP
-- ==========================================
task.spawn(function()
    while true do
        task.wait(0.15)
        if mode ~= "FISH" then continue end
        safeRun(function()
            local char = player.Character
            if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid")

            -- Anti lompat
            if hum and hum:GetStateEnabled(Enum.HumanoidStateType.Jumping) then
                hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
            end

            local tool = equipTool(FISH_TOOL_NAMES)
            if tool and not isCasting then
                if fishingState == "IDLE" then
                    setStatus("🎣 Siap melempar umpan...")
                    task.spawn(castRod)
                end
            elseif not tool then
                setStatus("⚠️ Rod tidak ditemukan!")
            end
        end)
    end
end)

-- ==========================================
-- MINING FUNCTIONS
-- ==========================================
local function isLikelyCrystal(obj)
    if not (obj:IsA("BasePart") or obj:IsA("MeshPart")) then return false, 0 end
    local lname = obj.Name:lower()
    local score = 0
    for _, cname in ipairs(CRYSTAL_NAMES) do
        if lname:find(cname:lower()) then score = score + 4; break end
    end
    if obj.Material == CRYSTAL_MATERIAL then score = score + 3 end
    if obj:IsA("MeshPart") then score = score + 1 end
    if obj.Transparency < 0.85 then score = score + 1 end
    if obj.CanCollide or obj.CanQuery then score = score + 1 end
    local parent = obj.Parent
    while parent and parent ~= workspace do
        local pname = parent.Name:lower()
        if pname:find("crystal") or pname:find("ore") or pname:find("mine") or pname:find("batu") then
            score = score + 3; break
        end
        parent = parent.Parent
    end
    return score >= 4, score
end

local function belongsToOtherPlayer(obj)
    local cursor = obj
    while cursor and cursor ~= workspace do
        for _, key in ipairs({"Owner","owner","OwnerName","ownerName","UserId","userId","Player","player"}) do
            local value = cursor:GetAttribute(key)
            if value ~= nil then
                if typeof(value) == "number" and value ~= player.UserId then return true end
                if typeof(value) == "string" and value ~= "" and value ~= player.Name
                   and value ~= player.DisplayName and value ~= tostring(player.UserId) then return true end
            end
        end
        for _, cn in ipairs({"Owner","OwnerName","PlayerName","UserId"}) do
            local child = cursor:FindFirstChild(cn)
            if child and child:IsA("ValueBase") then
                local v2 = child.Value
                if typeof(v2) == "number" and v2 ~= player.UserId then return true end
                if typeof(v2) == "string" and v2 ~= "" and v2 ~= player.Name
                   and v2 ~= player.DisplayName and v2 ~= tostring(player.UserId) then return true end
                if typeof(v2) == "Instance" and v2:IsA("Player") and v2 ~= player then return true end
            end
        end
        cursor = cursor.Parent
    end
    return false
end

local function findNearestCrystal()
    local char = player.Character
    if not char or not char.PrimaryPart then return nil end
    local myPos = char.PrimaryPart.Position
    if currentMiningTarget and currentMiningTarget.Parent and not belongsToOtherPlayer(currentMiningTarget) then
        local d = (currentMiningTarget.Position - myPos).Magnitude
        if d < MINE_MAX_SCAN_DISTANCE and miningFailCount < 3 then return currentMiningTarget, d end
    end
    local nearest, nearestValue, nearestDist = nil, math.huge, math.huge
    for _, obj in pairs(workspace:GetDescendants()) do
        local ok, score = isLikelyCrystal(obj)
        if ok and not belongsToOtherPlayer(obj) then
            local dist = (obj.Position - myPos).Magnitude
            if dist < MINE_MAX_SCAN_DISTANCE then
                local value = dist - score * 10
                if value < nearestValue then nearest = obj; nearestDist = dist; nearestValue = value end
            end
        end
    end
    currentMiningTarget = nearest; miningFailCount = 0
    return nearest, nearestDist
end

local function raycastGround(pos, ignoreList)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = ignoreList or {}
    params.IgnoreWater = false
    return workspace:Raycast(pos + Vector3.new(0,18,0), Vector3.new(0,-70,0), params)
end

local function hasClearLine(fromPos, toPos, ignoreList)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = ignoreList or {}
    local hit = workspace:Raycast(fromPos, toPos - fromPos, params)
    return not hit or hit.Instance == nil
end

local function getMiningStandPoint(crystal)
    local char = player.Character
    if not char or not char.PrimaryPart then return nil end
    local origin = crystal.Position
    local cw     = math.max(crystal.Size.X, crystal.Size.Z)
    local radius = math.clamp(cw * 0.28 + 1.9, MINE_STOP_DISTANCE, 4.2)
    local ignore = {char, crystal}
    local bestPos, bestScore = nil, math.huge
    for i = 1, 16 do
        local angle  = math.pi * 2 * (i / 16)
        local sample = origin + Vector3.new(math.cos(angle)*radius, 0, math.sin(angle)*radius)
        local ground = raycastGround(sample, ignore)
        if ground and ground.Instance and ground.Normal.Y > 0.55 then
            local pos    = ground.Position + Vector3.new(0, 3, 0)
            local hDelta = math.abs(pos.Y - char.PrimaryPart.Position.Y)
            if hDelta < 10 and pos.Y - origin.Y < 4.5 then
                local clear = hasClearLine(pos + Vector3.new(0,2,0), origin, ignore)
                local distC = (Vector3.new(pos.X, origin.Y, pos.Z) - origin).Magnitude
                local sc    = (pos - char.PrimaryPart.Position).Magnitude + math.abs(distC-radius)*4 + (clear and 0 or 12) + hDelta
                if sc < bestScore then bestScore = sc; bestPos = pos end
            end
        end
    end
    if bestPos then return bestPos end
    local delta = char.PrimaryPart.Position - origin
    local flat  = Vector3.new(delta.X, 0, delta.Z)
    if flat.Magnitude < 1 then flat = Vector3.new(1,0,0) end
    local fb     = origin + flat.Unit * radius
    local ground = raycastGround(fb, ignore)
    return ground and (ground.Position + Vector3.new(0,3,0)) or fb
end

local function moveToPosition(hum, targetPos, targetPart)
    local char = player.Character
    if not char or not char.PrimaryPart then return false end
    local path = PathfindingService:CreatePath({
        AgentRadius = 1.9, AgentHeight = 5.2,
        AgentCanJump = true, AgentCanClimb = true,
        WaypointSpacing = MINE_SMOOTH_MOVE and 7 or 3,
        Costs = {Water = 5},
    })
    local ok = pcall(function() path:ComputeAsync(char.PrimaryPart.Position, targetPos) end)
    local wps
    if ok and path.Status == Enum.PathStatus.Success then
        wps = path:GetWaypoints()
    else
        wps = {{Position = targetPos, Action = Enum.PathWaypointAction.Walk}}
    end
    local orig     = hum.WalkSpeed
    hum.WalkSpeed  = MINE_SMOOTH_MOVE and MINE_WALK_SPEED + math.random(-1,1) or MINE_WALK_SPEED
    local lastPos  = char.PrimaryPart.Position
    local stuckFor = 0
    for index, wp in ipairs(wps) do
        if mode ~= "MINE" then hum.WalkSpeed = orig; return false end
        if targetPart and not targetPart.Parent then hum.WalkSpeed = orig; return false end
        if wp.Action == Enum.PathWaypointAction.Jump then hum.Jump = true end
        hum:MoveTo(wp.Position)
        local started = os.clock()
        while mode == "MINE" and os.clock()-started < 4.5 do
            task.wait(MINE_SMOOTH_MOVE and 0.08 or 0.15)
            if not char.PrimaryPart then hum.WalkSpeed = orig; return false end
            local cur   = char.PrimaryPart.Position
            local reach = (MINE_SMOOTH_MOVE and index < #wps) and 5.2 or 2.4
            if (cur - wp.Position).Magnitude <= reach then break end
            if (cur - targetPos).Magnitude <= 2.1 then hum.WalkSpeed = orig; return true end
            if (cur - lastPos).Magnitude < 0.2 then
                stuckFor = stuckFor + (MINE_SMOOTH_MOVE and 0.08 or 0.15)
                if stuckFor > 1.1 then
                    hum.Jump = true
                    local rec = targetPos - cur
                    if rec.Magnitude < 0.1 then rec = Vector3.new(1,0,0) end
                    hum:MoveTo(cur + rec.Unit * 5)
                    task.wait(PATH_RETRY_DELAY)
                    hum.WalkSpeed = orig; return false
                end
            else stuckFor = 0; lastPos = cur end
        end
    end
    hum.WalkSpeed = orig
    return char.PrimaryPart and (char.PrimaryPart.Position - targetPos).Magnitude <= 2.4
end

local function facePart(part)
    local char = player.Character
    if not char or not char.PrimaryPart or not part then return end
    local pos = char.PrimaryPart.Position
    pcall(function()
        char:SetPrimaryPartCFrame(CFrame.lookAt(pos, Vector3.new(part.Position.X, pos.Y, part.Position.Z)))
    end)
end

local function mineRoutine()
    miningActive = true
    while mode == "MINE" do
        task.wait(0.5)
        safeRun(function()
            local char = player.Character
            if not char or not char.PrimaryPart then return end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hum then return end

            local crystal, dist = findNearestCrystal()
            if not crystal then
                setStatus("Mining: Crystal not found")
                warn("[MINE] Crystal tidak ditemukan...")
                task.wait(3); return
            end

            setStatus("Mining: " .. crystal.Name .. " (" .. math.floor(dist) .. " stud)")

            local tool = equipTool(MINE_TOOL_NAMES)
            if not tool then
                setStatus("Mining: No pickaxe!")
                task.wait(3); return
            end

            local standPoint = getMiningStandPoint(crystal)
            if standPoint and (char.PrimaryPart.Position - standPoint).Magnitude > 2.0 then
                local arrived = moveToPosition(hum, standPoint, crystal)
                if not arrived then
                    miningFailCount = miningFailCount + 1
                    if miningFailCount >= 3 then currentMiningTarget = nil end
                    task.wait(0.4); return
                end
            end

            facePart(crystal)
            local cam = workspace.CurrentCamera
            if cam then
                local aimPos = crystal.Position + Vector3.new(0, math.clamp(crystal.Size.Y*0.15, 0.5, 2.5), 0)
                local screenPos, onScreen = cam:WorldToScreenPoint(aimPos)
                if onScreen then
                    local minedThisTarget = false
                    for i = 1, 7 do
                        if mode ~= "MINE" then break end
                        if crystal.Parent == nil then minedThisTarget = true; break end
                        facePart(crystal)
                        pcall(function() VirtualUser:Button1Down(Vector2.new(screenPos.X, screenPos.Y), cam.CFrame) end)
                        task.wait(0.15)
                        pcall(function() VirtualUser:Button1Up(Vector2.new(screenPos.X, screenPos.Y), cam.CFrame) end)
                        task.wait(0.3)
                        pcall(function() tool:Activate() end)
                    end
                    if minedThisTarget or crystal.Parent == nil then
                        crystalMinedCount = crystalMinedCount + 1
                        updateResultLabels()
                        setStatus("Mining: Crystal mined!")
                        currentMiningTarget = nil; miningFailCount = 0
                    else
                        miningHitCount = miningHitCount + 1
                        if miningHitCount >= 3 then
                            crystalMinedCount = crystalMinedCount + 1
                            miningHitCount    = 0
                            updateResultLabels()
                        end
                    end
                else
                    pcall(function() tool:Activate() end)
                    task.wait(1)
                end
            end
        end)
        task.wait(0.5)
    end
    miningActive = false
end

-- ==========================================
-- SETTINGS BUTTONS
-- ==========================================
btnSmooth.MouseButton1Click:Connect(function()
    MINE_SMOOTH_MOVE = not MINE_SMOOTH_MOVE
    btnSmooth.Text = MINE_SMOOTH_MOVE and "Smooth: ON" or "Smooth: OFF"
    btnSmooth.BackgroundColor3 = MINE_SMOOTH_MOVE and Color3.fromRGB(42,92,71) or Color3.fromRGB(80,58,58)
end)

btnSpeed.MouseButton1Click:Connect(function()
    if MINE_WALK_SPEED == 15 then MINE_WALK_SPEED = 13
    elseif MINE_WALK_SPEED == 13 then MINE_WALK_SPEED = 16
    else MINE_WALK_SPEED = 15 end
    btnSpeed.Text = "Speed: " .. tostring(MINE_WALK_SPEED)
end)

rangeBox.FocusLost:Connect(function()
    local v = tonumber(rangeBox.Text)
    if not v then v = MINE_STOP_DISTANCE end
    v = math.clamp(v, 2.2, 5.5)
    MINE_STOP_DISTANCE = v
    rangeBox.Text = string.format("%.1f", v)
end)

-- ==========================================
-- TOMBOL FISH (FIX: paksa reset dots saat OFF)
-- ==========================================
local function forceTurnOffFish()
    mode = "OFF"
    btnFish.Text = "FISHING"
    btnFish.BackgroundColor3 = Color3.fromRGB(35, 45, 70)
    btnFishStroke.Color = Color3.fromRGB(60, 120, 200)
    -- Paksa release Space
    pcall(function() VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game) end)
    isSpacePressed = false
    -- Paksa reset semua state & indikator
    resetFishingState()
    setStatus("System Idle")
    -- Pulihkan lompat
    pcall(function()
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true) end
    end)
end

btnFish.MouseButton1Click:Connect(function()
    if mode == "FISH" then
        forceTurnOffFish()
    else
        -- Matikan mine jika aktif
        if mode == "MINE" then
            mode = "OFF"
            btnMine.Text = "MINING"
            btnMine.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
            btnMineStroke.Color = Color3.fromRGB(80, 80, 100)
        end
        mode = "FISH"
        btnFish.Text = "FISHING ●"
        btnFish.BackgroundColor3 = Color3.fromRGB(50, 70, 100)
        btnFishStroke.Color = Color3.fromRGB(100, 180, 255)
        resetFishingState()
        setStatus("Fishing Active")
        warn("[SYSTEM] Fishing Mode Aktif")
    end
end)

-- ==========================================
-- TOMBOL MINE
-- ==========================================
btnMine.MouseButton1Click:Connect(function()
    if mode == "MINE" then
        mode = "OFF"
        btnMine.Text = "MINING"
        btnMine.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
        btnMineStroke.Color = Color3.fromRGB(80, 80, 100)
        setStatus("System Idle")
        pcall(function()
            local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true) end
        end)
    else
        -- Matikan fish jika aktif
        if mode == "FISH" then forceTurnOffFish() end
        mode = "MINE"
        currentMiningTarget = nil; miningFailCount = 0; miningHitCount = 0
        btnMine.Text = "MINING ●"
        btnMine.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
        btnMineStroke.Color = Color3.fromRGB(120, 120, 150)
        btnFish.Text = "FISHING"
        btnFish.BackgroundColor3 = Color3.fromRGB(35, 45, 70)
        btnFishStroke.Color = Color3.fromRGB(60, 120, 200)
        pcall(function()
            local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true) end
        end)
        setStatus("Mining Active")
        warn("[SYSTEM] Mining Mode Aktif")
        if not miningActive then task.spawn(mineRoutine) end
    end
end)

-- ==========================================
-- INISIALISASI
-- ==========================================
setFishPhase(0)   -- pastikan semua dot abu-abu saat pertama kali load

warn("=== INDO HANGOUT BOT v4 LOADED ===")
warn("File: autofish_v4.lua")
warn("FISH: 15s tunggu → minigame → selesai saat GUI hilang → recast")
warn("MINE: Auto scan & tambang crystal")
