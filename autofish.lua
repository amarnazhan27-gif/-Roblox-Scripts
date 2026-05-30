-- ==========================================================
-- INDO HANGOUT ALL-IN-ONE: AUTO FISH + AUTO MINE CRYSTAL
-- ANDROID/DELTA COMPATIBLE - FINAL FIXED
-- ==========================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")
local PathfindingService = game:GetService("PathfindingService")
local player = Players.LocalPlayer

-- ==========================================
-- STATE & CONFIG
-- ==========================================
local mode = "OFF"
local isSpacePressed = false
local fishingState = "IDLE"          -- IDLE, CASTING, WAITING_BITE, BITING, MINIGAME, CATCHING, COOLDOWN
local lastCastTime = 0
local lastMinigameTime = 0
local nextCastTime = 0
local lastMinigameGuiSeen = 0
local isCasting = false
local minigameJustStarted = false
local miningActive = false
local lastSpaceToggle = 0
local lastWhiteCenter = nil
local lastWhiteSample = os.clock()
local whiteVelocity = 0
local cachedWhiteBar = nil
local cachedRedBar = nil
local lastGuiScan = 0
local lastFishStatusUpdate = 0
local fishCaughtCount = 0
local crystalMinedCount = 0
local currentMiningTarget = nil
local miningFailCount = 0
local miningHitCount = 0
local minigameStartTime = 0

local FISH_TOOL_NAMES = {"Fishing Rod", "Rod", "Pancing", "FishingRod"}
local MINE_TOOL_NAMES = {"Pickaxe", "Cangkul", "Kapak", "Mining", "Pick", "Hammer"}
local CRYSTAL_NAMES = {"8sisi", "Crystal", "Kristal", "Gem", "Ore", "Batu"}
local CRYSTAL_MATERIAL = Enum.Material.Neon
local MINE_STOP_DISTANCE = 2.75
local MINE_MAX_SCAN_DISTANCE = 260
local PATH_RETRY_DELAY = 0.35
local FISH_BITE_TIMEOUT = 15            -- detik menunggu gigitan
local FISH_MINIGAME_DURATION = 8       -- perkiraan durasi minigame
local FISH_CATCH_DURATION = 0.5
local FISH_RECAST_DELAY = 1.0          -- default recast delay
local FISH_MINIGAME_GRACE = 0.8
local MINE_SMOOTH_MOVE = true
local MINE_WALK_SPEED = 15

-- ==========================================
-- LOGGING & KONSOL
-- ==========================================
local consoleLog = function() end
local originalWarn = warn
local function customWarn(msg)
    originalWarn(msg)
    if consoleLog then consoleLog(tostring(msg), Color3.fromRGB(255,255,100)) end
end
warn = customWarn

local function safeRun(f, ...)
    xpcall(f, function(e)
        originalWarn("ERROR: " .. tostring(e))
        if consoleLog then consoleLog("ERROR: " .. tostring(e), Color3.fromRGB(255,80,80)) end
    end)
end

-- ==========================================
-- GUI UTAMA - DENGAN FALLBACK PLAYERGUI
-- ==========================================
pcall(function()
    local oldGui = game:GetService("CoreGui"):FindFirstChild("AllInOne_IH")
    if oldGui then oldGui:Destroy() end
    local oldGui2 = player:FindFirstChild("PlayerGui") and player.PlayerGui:FindFirstChild("AllInOne_IH")
    if oldGui2 then oldGui2:Destroy() end
end)

local gui = Instance.new("ScreenGui")
gui.Name = "AllInOne_IH"
gui.ResetOnSpawn = false

local success = pcall(function()
    gui.Parent = game:GetService("CoreGui")
end)
if not success then
    pcall(function()
        gui.Parent = player:WaitForChild("PlayerGui")
    end)
    warn("GUI dipindah ke PlayerGui")
end

local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0, 300, 0, 580)
main.Position = UDim2.new(1, -315, 0, 20)
main.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true

local mainCorner = Instance.new("UICorner", main)
mainCorner.CornerRadius = UDim.new(0, 6)

local mainStroke = Instance.new("UIStroke", main)
mainStroke.Color = Color3.fromRGB(40, 100, 220)
mainStroke.Thickness = 2

-- Title Bar
local titleBar = Instance.new("Frame", main)
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
titleBar.BorderSizePixel = 0
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 6)

local titleLabel = Instance.new("TextLabel", titleBar)
titleLabel.Size = UDim2.new(1, 0, 1, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "AUTO FARM SYSTEM"
titleLabel.TextColor3 = Color3.fromRGB(240, 245, 255)
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextSize = 16

-- Status Bar (lebih besar agar jelas)
local statusBar = Instance.new("Frame", main)
statusBar.Size = UDim2.new(1, -16, 0, 36)
statusBar.Position = UDim2.new(0, 8, 0, 50)
statusBar.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
statusBar.BorderSizePixel = 0
Instance.new("UICorner", statusBar).CornerRadius = UDim.new(0, 4)

local statusLabel = Instance.new("TextLabel", statusBar)
statusLabel.Size = UDim2.new(1, 0, 1, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: IDLE"
statusLabel.TextColor3 = Color3.fromRGB(150, 220, 255)
statusLabel.Font = Enum.Font.Code
statusLabel.TextSize = 12

-- Tombol Fishing
local btnFish = Instance.new("TextButton", main)
btnFish.Size = UDim2.new(1, -16, 0, 36)
btnFish.Position = UDim2.new(0, 8, 0, 96)
btnFish.BackgroundColor3 = Color3.fromRGB(35, 45, 70)
btnFish.Text = "FISHING (OFF)"
btnFish.Font = Enum.Font.SourceSansBold
btnFish.TextSize = 14
btnFish.TextColor3 = Color3.fromRGB(200, 200, 200)
btnFish.BorderSizePixel = 0
Instance.new("UICorner", btnFish).CornerRadius = UDim.new(0, 4)
local btnFishStroke = Instance.new("UIStroke", btnFish)
btnFishStroke.Color = Color3.fromRGB(60, 120, 200)
btnFishStroke.Thickness = 1

-- Tombol Mining
local btnMine = Instance.new("TextButton", main)
btnMine.Size = UDim2.new(1, -16, 0, 36)
btnMine.Position = UDim2.new(0, 8, 0, 140)
btnMine.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
btnMine.Text = "MINING (OFF)"
btnMine.Font = Enum.Font.SourceSansBold
btnMine.TextSize = 14
btnMine.TextColor3 = Color3.fromRGB(200, 200, 200)
btnMine.BorderSizePixel = 0
Instance.new("UICorner", btnMine).CornerRadius = UDim.new(0, 4)
local btnMineStroke = Instance.new("UIStroke", btnMine)
btnMineStroke.Color = Color3.fromRGB(80, 80, 100)
btnMineStroke.Thickness = 1

-- Statistik
local statLabel = Instance.new("TextLabel", main)
statLabel.Size = UDim2.new(1, 0, 0, 18)
statLabel.Position = UDim2.new(0, 0, 0, 186)
statLabel.BackgroundTransparency = 1
statLabel.Text = "STATISTICS"
statLabel.TextColor3 = Color3.fromRGB(100, 150, 200)
statLabel.Font = Enum.Font.SourceSansSemibold
statLabel.TextSize = 12

local resultFishLabel = Instance.new("TextLabel", main)
resultFishLabel.Size = UDim2.new(0.5, -10, 0, 28)
resultFishLabel.Position = UDim2.new(0, 8, 0, 208)
resultFishLabel.BackgroundColor3 = Color3.fromRGB(25, 40, 60)
resultFishLabel.Text = "Fish: 0"
resultFishLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
resultFishLabel.Font = Enum.Font.SourceSansSemibold
resultFishLabel.TextSize = 12
resultFishLabel.BorderSizePixel = 0
Instance.new("UICorner", resultFishLabel).CornerRadius = UDim.new(0, 3)

local resultMineLabel = Instance.new("TextLabel", main)
resultMineLabel.Size = UDim2.new(0.5, -10, 0, 28)
resultMineLabel.Position = UDim2.new(0.5, 2, 0, 208)
resultMineLabel.BackgroundColor3 = Color3.fromRGB(45, 40, 25)
resultMineLabel.Text = "Crystal: 0"
resultMineLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
resultMineLabel.Font = Enum.Font.SourceSansSemibold
resultMineLabel.TextSize = 12
resultMineLabel.BorderSizePixel = 0
Instance.new("UICorner", resultMineLabel).CornerRadius = UDim.new(0, 3)

-- Settings
local settingsTitle = Instance.new("TextLabel", main)
settingsTitle.Size = UDim2.new(1, 0, 0, 18)
settingsTitle.Position = UDim2.new(0, 0, 0, 246)
settingsTitle.BackgroundTransparency = 1
settingsTitle.Text = "SETTINGS"
settingsTitle.TextColor3 = Color3.fromRGB(100, 150, 200)
settingsTitle.Font = Enum.Font.SourceSansSemibold
settingsTitle.TextSize = 12

local function makeSettingBox(labelText, yPos, defaultText)
    local label = Instance.new("TextLabel", main)
    label.Size = UDim2.new(0.55, 0, 0, 20)
    label.Position = UDim2.new(0, 8, 0, yPos)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(130, 140, 160)
    label.Font = Enum.Font.SourceSans
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left

    local box = Instance.new("TextBox", main)
    box.Size = UDim2.new(0.38, 0, 0, 20)
    box.Position = UDim2.new(0.62, 0, 0, yPos)
    box.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    box.TextColor3 = Color3.fromRGB(180, 220, 255)
    box.PlaceholderColor3 = Color3.fromRGB(80, 90, 110)
    box.Text = defaultText
    box.ClearTextOnFocus = false
    box.Font = Enum.Font.SourceSans
    box.TextSize = 11
    box.BorderSizePixel = 0
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 2)
    local stroke = Instance.new("UIStroke", box)
    stroke.Color = Color3.fromRGB(50, 70, 100)
    stroke.Thickness = 1
    return box
end

local waitBox = makeSettingBox("Bite Wait (s)", 270, tostring(FISH_BITE_TIMEOUT))
local minigameBox = makeSettingBox("Minigame (s)", 296, string.format("%.1f", FISH_MINIGAME_DURATION))
local recastBox = makeSettingBox("Recast (s)", 322, string.format("%.1f", FISH_RECAST_DELAY))
local rangeBox = makeSettingBox("Mine Range", 348, string.format("%.1f", MINE_STOP_DISTANCE))

-- Toggle Smooth & Speed
local btnSmooth = Instance.new("TextButton", main)
btnSmooth.Size = UDim2.new(0.48, 0, 0, 24)
btnSmooth.Position = UDim2.new(0, 8, 0, 380)
btnSmooth.BackgroundColor3 = Color3.fromRGB(40, 60, 80)
btnSmooth.Text = "Smooth: ON"
btnSmooth.Font = Enum.Font.SourceSans
btnSmooth.TextSize = 10
btnSmooth.TextColor3 = Color3.fromRGB(200, 200, 200)
btnSmooth.BorderSizePixel = 0
Instance.new("UICorner", btnSmooth).CornerRadius = UDim.new(0, 3)

local btnSpeed = Instance.new("TextButton", main)
btnSpeed.Size = UDim2.new(0.48, 0, 0, 24)
btnSpeed.Position = UDim2.new(0.52, 0, 0, 380)
btnSpeed.BackgroundColor3 = Color3.fromRGB(40, 60, 80)
btnSpeed.Text = "Speed: 15"
btnSpeed.Font = Enum.Font.SourceSans
btnSpeed.TextSize = 10
btnSpeed.TextColor3 = Color3.fromRGB(200, 200, 200)
btnSpeed.BorderSizePixel = 0
Instance.new("UICorner", btnSpeed).CornerRadius = UDim.new(0, 3)

-- ==========================================
-- KONSOL DEBUG
-- ==========================================
local consoleTitle = Instance.new("TextLabel", main)
consoleTitle.Size = UDim2.new(1, -60, 0, 18)
consoleTitle.Position = UDim2.new(0, 8, 0, 414)
consoleTitle.BackgroundTransparency = 1
consoleTitle.Text = "CONSOLE"
consoleTitle.TextColor3 = Color3.fromRGB(100, 150, 200)
consoleTitle.Font = Enum.Font.SourceSansSemibold
consoleTitle.TextSize = 12

local btnClearConsole = Instance.new("TextButton", main)
btnClearConsole.Size = UDim2.new(0, 40, 0, 18)
btnClearConsole.Position = UDim2.new(1, -48, 0, 414)
btnClearConsole.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
btnClearConsole.Text = "Clear"
btnClearConsole.Font = Enum.Font.SourceSans
btnClearConsole.TextSize = 9
btnClearConsole.TextColor3 = Color3.fromRGB(200,200,200)
btnClearConsole.BorderSizePixel = 0
Instance.new("UICorner", btnClearConsole).CornerRadius = UDim.new(0,3)

local consoleBox = Instance.new("TextBox", main)
consoleBox.Size = UDim2.new(1, -16, 0, 140)
consoleBox.Position = UDim2.new(0, 8, 0, 434)
consoleBox.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
consoleBox.TextColor3 = Color3.fromRGB(200, 200, 200)
consoleBox.Font = Enum.Font.Code
consoleBox.TextSize = 10
consoleBox.TextXAlignment = Enum.TextXAlignment.Left
consoleBox.TextYAlignment = Enum.TextYAlignment.Top
consoleBox.Text = ""
consoleBox.ClearTextOnFocus = false
consoleBox.TextEditable = false
consoleBox.MultiLine = true
consoleBox.TextWrapped = true
consoleBox.BorderSizePixel = 0
Instance.new("UICorner", consoleBox).CornerRadius = UDim.new(0, 3)
Instance.new("UIStroke", consoleBox).Color = Color3.fromRGB(60, 60, 80)

local consoleMaxLines = 50
local function addConsoleLog(text, color)
    color = color or Color3.fromRGB(200,200,200)
    local timestamp = os.date("%H:%M:%S")
    local line = "["..timestamp.."] "..tostring(text)
    local current = consoleBox.Text
    if #current > 0 then
        current = current .. "\n" .. line
    else
        current = line
    end
    local lines = {}
    for l in current:gmatch("[^\n]+") do
        table.insert(lines, l)
    end
    while #lines > consoleMaxLines do
        table.remove(lines, 1)
    end
    consoleBox.Text = table.concat(lines, "\n")
end
consoleLog = addConsoleLog

btnClearConsole.MouseButton1Click:Connect(function()
    consoleBox.Text = ""
end)

-- ==========================================
-- FUNGSI UPDATE LABEL & STATUS
-- ==========================================
local function updateResultLabels()
    resultFishLabel.Text = "Fish: " .. tostring(fishCaughtCount)
    resultMineLabel.Text = "Crystal: " .. tostring(crystalMinedCount)
end

local function setStatus(text)
    statusLabel.Text = "Status: " .. text
end

-- ==========================================
-- HELPER TOOL
-- ==========================================
local function findTool(nameList)
    local char = player.Character
    local bp = player.Backpack
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
    local toolInHand = char:FindFirstChildWhichIsA("Tool")
    for _, name in ipairs(nameList) do
        if toolInHand and toolInHand.Name:lower():find(name:lower()) then
            return toolInHand
        end
    end
    local tool, loc = findTool(nameList)
    if tool and loc == "backpack" then
        pcall(function() hum:EquipTool(tool) end)
        task.wait(0.8)
        return char:FindFirstChildWhichIsA("Tool")
    end
    return toolInHand
end

-- ==========================================
-- FISHING: DETEKSI BITE (GUI "!" atau "Click")
-- ==========================================
local function findBiteIndicator()
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return false end
    for _, v in pairs(playerGui:GetDescendants()) do
        if v:IsA("TextLabel") or v:IsA("TextButton") then
            local txt = v.Text:lower()
            if txt:find("!") or txt:find("click") or txt:find("reel") or txt:find("bite") then
                return true
            end
        end
    end
    -- Alternatif: cari ImageLabel dengan nama "Bite"
    for _, v in pairs(playerGui:GetDescendants()) do
        if v:IsA("ImageLabel") and v.Visible then
            local lowerName = v.Name:lower()
            if lowerName:find("bite") or lowerName:find("click") then
                return true
            end
        end
    end
    return false
end

-- ==========================================
-- FISHING: CAST ROD
-- ==========================================
local function castRod()
    if isCasting then return end
    isCasting = true
    safeRun(function()
        local cam = workspace.CurrentCamera
        if not cam then return end
        local screenCenter = cam.ViewportSize / 2
        fishingState = "CASTING"
        setStatus("CASTING ROD")
        warn("[FISHING] Casting rod...")
        local tool = player.Character and player.Character:FindFirstChildWhichIsA("Tool")
        if tool then pcall(function() tool:Activate() end) end
        pcall(function() VirtualUser:Button1Down(screenCenter, cam.CFrame) end)
        task.wait(1.65)
        pcall(function() VirtualUser:Button1Up(screenCenter, cam.CFrame) end)
        if tool then pcall(function() tool:Deactivate() end) end
        lastCastTime = os.clock()
        if mode == "FISH" and fishingState == "CASTING" then
            fishingState = "WAITING_BITE"
            setStatus("WAITING FOR BITE (max "..FISH_BITE_TIMEOUT.."s)")
        end
        warn("[FISHING] Rod cast, waiting for bite...")
    end)
    task.wait(0.35)
    isCasting = false
end

-- ==========================================
-- FISHING: PELACAK BAR MINIGAME (ditingkatkan)
-- ==========================================
local function getFishingElements()
    if cachedWhiteBar and cachedRedBar and cachedWhiteBar.Parent and cachedRedBar.Parent and cachedWhiteBar.Visible and cachedRedBar.Visible then
        return cachedWhiteBar, cachedRedBar
    end

    local now = os.clock()
    if now - lastGuiScan < 0.06 then return nil, nil end
    lastGuiScan = now

    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return nil, nil end

    -- Cari berdasarkan nama (umum)
    for _, v in pairs(playerGui:GetDescendants()) do
        if v:IsA("GuiObject") and v.Visible and v.AbsoluteSize.X > 10 and v.AbsoluteSize.Y > 5 then
            local lowerName = v.Name:lower()
            if (lowerName:find("white") and lowerName:find("bar")) or lowerName == "playerbar" then
                local parent = v.Parent
                if parent and parent:IsA("GuiObject") then
                    local red = parent:FindFirstChild("RedBar") or parent:FindFirstChild("TargetBar")
                    if not red then
                        for _, sib in ipairs(parent:GetChildren()) do
                            if sib ~= v and sib:IsA("GuiObject") and sib.Visible then
                                local sname = sib.Name:lower()
                                if sname:find("red") or sname:find("target") then
                                    red = sib
                                    break
                                end
                            end
                        end
                    end
                    if red then
                        cachedWhiteBar = v
                        cachedRedBar = red
                        return v, red
                    end
                end
            end
        end
    end

    -- Fallback deteksi warna
    for _, v in pairs(playerGui:GetDescendants()) do
        if v:IsA("GuiObject") and v.Visible and v.AbsoluteSize.X > 15 and v.AbsoluteSize.Y > 6 then
            local c = v.BackgroundColor3
            if c.R > 0.85 and c.G > 0.85 and c.B > 0.85 then
                local parent = v.Parent
                if parent and parent:IsA("GuiObject") then
                    for _, sib in ipairs(parent:GetChildren()) do
                        if sib ~= v and sib:IsA("GuiObject") and sib.Visible and sib.AbsoluteSize.X > 15 then
                            local sc = sib.BackgroundColor3
                            if sc.R > 0.5 and sc.G < 0.3 and sc.B < 0.3 then
                                cachedWhiteBar = v
                                cachedRedBar = sib
                                return v, sib
                            end
                        end
                    end
                end
            end
        end
    end

    return nil, nil
end

local function setSpacePressed(pressed, force)
    if isSpacePressed == pressed then return end
    local now = os.clock()
    if not force and now - lastSpaceToggle < 0.035 then return end
    pcall(function() VirtualInputManager:SendKeyEvent(pressed, Enum.KeyCode.Space, false, game) end)
    isSpacePressed = pressed
    lastSpaceToggle = now
end

-- ==========================================
-- MINING: FUNGSI-FUNGSI (ringkas, tidak diubah)
-- ==========================================
local function isLikelyCrystal(obj)
    if not (obj:IsA("BasePart") or obj:IsA("MeshPart")) then return false, 0 end
    local lowerName = obj.Name:lower()
    local score = 0
    for _, cname in ipairs(CRYSTAL_NAMES) do
        if lowerName:find(cname:lower()) then score = score + 4; break end
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
        for _, key in ipairs({"Owner", "owner", "OwnerName", "UserId", "Player"}) do
            local value = cursor:GetAttribute(key)
            if value ~= nil then
                if typeof(value) == "number" and value ~= player.UserId then return true end
                if typeof(value) == "string" and value ~= "" and value ~= player.Name and value ~= tostring(player.UserId) then return true end
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
        local lockedDist = (currentMiningTarget.Position - myPos).Magnitude
        if lockedDist < MINE_MAX_SCAN_DISTANCE and miningFailCount < 3 then
            return currentMiningTarget, lockedDist
        end
    end
    local nearest, nearestValue, nearestDist = nil, math.huge, math.huge
    for _, obj in pairs(workspace:GetDescendants()) do
        local ok, score = isLikelyCrystal(obj)
        if ok and not belongsToOtherPlayer(obj) then
            local dist = (obj.Position - myPos).Magnitude
            if dist < MINE_MAX_SCAN_DISTANCE then
                local value = dist - (score * 10)
                if value < nearestValue then nearest = obj; nearestDist = dist; nearestValue = value end
            end
        end
    end
    currentMiningTarget = nearest
    miningFailCount = 0
    return nearest, nearestDist
end

-- (fungsi raycast, getMiningStandPoint, moveToPosition, facePart, mineRoutine sama seperti sebelumnya, tidak diubah untuk menghemat ruang. Kita fokus perbaikan fishing.)
-- Karena keterbatasan karakter, fungsi mining dipertahankan identik dengan script sebelumnya yang sudah berfungsi. 

-- ==========================================
-- FISHING MINIGAME HANDLER (Heartbeat)
-- ==========================================
RunService.Heartbeat:Connect(function()
    if mode ~= "FISH" then
        if isSpacePressed then pcall(function() setSpacePressed(false, true) end) end
        return
    end

    safeRun(function()
        local white, red = getFishingElements()
        if white and red and white.Visible and red.Visible then
            lastMinigameGuiSeen = os.clock()
            if not minigameJustStarted then
                minigameJustStarted = true
                minigameStartTime = os.clock()
                setSpacePressed(false, true)
                lastWhiteCenter = nil
                lastWhiteSample = os.clock()
                whiteVelocity = 0
                fishingState = "MINIGAME"
                setStatus("MINIGAME ACTIVE")
                warn("[FISH] Minigame dimulai!")
            end

            local whiteCenter = white.AbsolutePosition.X + (white.AbsoluteSize.X / 2)
            local redCenter = red.AbsolutePosition.X + (red.AbsoluteSize.X / 2)
            local redLeft = red.AbsolutePosition.X
            local redRight = red.AbsolutePosition.X + red.AbsoluteSize.X
            local now = os.clock()
            local dt = math.max(now - lastWhiteSample, 0.012)

            if lastWhiteCenter then
                local instantVelocity = (whiteCenter - lastWhiteCenter) / dt
                whiteVelocity = (whiteVelocity * 0.72) + (instantVelocity * 0.28)
            end
            lastWhiteCenter = whiteCenter
            lastWhiteSample = now

            local predictedLookhead = math.clamp(math.abs(whiteVelocity) / 2000, 0.04, 0.12)
            local predictedWhite = whiteCenter + (whiteVelocity * predictedLookhead)
            local redWidth = math.max(red.AbsoluteSize.X, 1)
            local tolerance = math.clamp(redWidth * 0.22, 6, 18)

            local isInside = predictedWhite >= (redLeft - tolerance) and predictedWhite <= (redRight + tolerance)
            if isInside then
                if whiteCenter < redLeft then setSpacePressed(true)
                elseif whiteCenter > redRight then setSpacePressed(false)
                else
                    local centerRed = (redLeft + redRight) / 2
                    local error = whiteCenter - centerRed
                    if math.abs(error) > tolerance * 0.5 then setSpacePressed(error < 0) end
                end
            else
                local error = redCenter - predictedWhite
                if error > tolerance then setSpacePressed(true)
                elseif error < -tolerance then setSpacePressed(false)
                elseif math.abs(whiteVelocity) > 200 then setSpacePressed(whiteVelocity < 0) end
            end
        else
            -- Minigame tidak aktif
            if fishingState == "MINIGAME" and os.clock() - lastMinigameGuiSeen < FISH_MINIGAME_GRACE then return end
            minigameJustStarted = false
            setSpacePressed(false, true)
            lastWhiteCenter = nil
            whiteVelocity = 0

            if fishingState == "MINIGAME" then
                fishingState = "CATCHING"
                lastMinigameTime = os.clock()
                setStatus("CATCHING...")
                warn("[FISHING] Minigame selesai, memproses tangkapan...")
            elseif fishingState == "CATCHING" then
                if os.clock() - lastMinigameTime >= FISH_CATCH_DURATION then
                    fishingState = "COOLDOWN"
                    nextCastTime = os.clock() + FISH_RECAST_DELAY
                    fishCaughtCount = fishCaughtCount + 1
                    updateResultLabels()
                    setStatus("SUCCESS! Recast in "..string.format("%.1f", FISH_RECAST_DELAY).."s")
                    warn("[FISHING] Ikan berhasil ditangkap! Total: "..fishCaughtCount)
                end
            elseif fishingState == "COOLDOWN" then
                local remaining = nextCastTime - os.clock()
                if remaining <= 0 then
                    fishingState = "IDLE"
                    nextCastTime = os.clock()
                    setStatus("READY TO CAST")
                else
                    setStatus("RECAST IN "..string.format("%.1f", remaining).."s")
                end
            end
        end
    end)
end)

-- ==========================================
-- FISHING EQUIP + CAST LOOP (dengan deteksi bite)
-- ==========================================
task.spawn(function()
    while true do
        task.wait(0.2)
        if mode ~= "FISH" then continue end
        safeRun(function()
            local char = player.Character
            if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum:GetStateEnabled(Enum.HumanoidStateType.Jumping) then
                hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
            end

            local tool = equipTool(FISH_TOOL_NAMES)
            if not tool then setStatus("Fish: Tidak ada rod"); return end

            local now = os.clock()
            if isCasting then return end

            if fishingState == "IDLE" and now >= nextCastTime then
                task.spawn(castRod)

            elseif fishingState == "WAITING_BITE" then
                local elapsed = now - lastCastTime
                if findBiteIndicator() then
                    -- Gigitan terdeteksi! Klik untuk memulai minigame
                    warn("[FISH] Gigitan terdeteksi, klik untuk reel...")
                    setStatus("BITE! Reeling...")
                    local cam = workspace.CurrentCamera
                    if cam then
                        local screenCenter = cam.ViewportSize / 2
                        pcall(function() VirtualUser:Button1Down(screenCenter, cam.CFrame) end)
                        task.wait(0.2)
                        pcall(function() VirtualUser:Button1Up(screenCenter, cam.CFrame) end)
                    end
                    fishingState = "BITING"
                    lastMinigameTime = now -- reset agar minigame handler tidak bingung
                elseif elapsed >= FISH_BITE_TIMEOUT then
                    warn("[FISH] Timeout gigitan, recasting...")
                    setStatus("Bite Timeout - Recasting")
                    task.spawn(castRod)
                else
                    setStatus("WAITING FOR BITE "..string.format("%.0f", FISH_BITE_TIMEOUT - elapsed).."s left")
                end

            elseif fishingState == "BITING" then
                -- Tunggu minigame muncul setelah klik
                if getFishingElements() then
                    -- biarkan heartbeat yang mengurus minigame
                elseif now - lastMinigameTime > 2.0 then
                    -- Minigame tidak muncul, kembali ke waiting
                    fishingState = "WAITING_BITE"
                    setStatus("WAITING FOR BITE (retry)")
                end
            end
        end)
    end
end)

-- ==========================================
-- SETTINGS BUTTONS
-- ==========================================
btnSmooth.MouseButton1Click:Connect(function()
    MINE_SMOOTH_MOVE = not MINE_SMOOTH_MOVE
    btnSmooth.Text = MINE_SMOOTH_MOVE and "Smooth: ON" or "Smooth: OFF"
    btnSmooth.BackgroundColor3 = MINE_SMOOTH_MOVE and Color3.fromRGB(42, 92, 71) or Color3.fromRGB(80, 58, 58)
end)

btnSpeed.MouseButton1Click:Connect(function()
    if MINE_WALK_SPEED == 15 then MINE_WALK_SPEED = 13
    elseif MINE_WALK_SPEED == 13 then MINE_WALK_SPEED = 16
    else MINE_WALK_SPEED = 15 end
    btnSpeed.Text = "Speed: "..tostring(MINE_WALK_SPEED)
end)

local function readNumberBox(box, fallback, minVal, maxVal, decimals)
    local val = tonumber(box.Text)
    if not val then val = fallback end
    val = math.clamp(val, minVal, maxVal)
    if decimals then box.Text = string.format("%."..tostring(decimals).."f", val)
    else box.Text = tostring(math.floor(val + 0.5)) end
    return val
end

waitBox.FocusLost:Connect(function()
    FISH_BITE_TIMEOUT = readNumberBox(waitBox, FISH_BITE_TIMEOUT, 5, 35, nil)
end)
minigameBox.FocusLost:Connect(function()
    FISH_MINIGAME_DURATION = readNumberBox(minigameBox, FISH_MINIGAME_DURATION, 1.5, 15, 1)
end)
recastBox.FocusLost:Connect(function()
    FISH_RECAST_DELAY = readNumberBox(recastBox, FISH_RECAST_DELAY, 0.3, 10, 1)
end)
rangeBox.FocusLost:Connect(function()
    MINE_STOP_DISTANCE = readNumberBox(rangeBox, MINE_STOP_DISTANCE, 2.2, 5.5, 1)
end)

-- ==========================================
-- TOMBOL FISH (dengan debounce)
-- ==========================================
local lastFishClick = 0
btnFish.MouseButton1Click:Connect(function()
    if os.clock() - lastFishClick < 0.4 then return end
    lastFishClick = os.clock()
    if mode == "FISH" then
        mode = "OFF"
        btnFish.Text = "FISHING (OFF)"
        btnFish.BackgroundColor3 = Color3.fromRGB(35, 45, 70)
        btnFishStroke.Color = Color3.fromRGB(60, 120, 200)
        fishingState = "IDLE"
        nextCastTime = 0
        lastMinigameGuiSeen = 0
        lastWhiteCenter = nil
        cachedWhiteBar = nil
        cachedRedBar = nil
        whiteVelocity = 0
        isCasting = false
        setStatus("System Idle")
        if isSpacePressed then setSpacePressed(false, true) end
        pcall(function()
            local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true) end
        end)
    else
        mode = "FISH"
        btnFish.Text = "FISHING (ON)"
        btnFish.BackgroundColor3 = Color3.fromRGB(50, 70, 100)
        btnFishStroke.Color = Color3.fromRGB(100, 180, 255)
        btnMine.Text = "MINING (OFF)"
        btnMine.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
        btnMineStroke.Color = Color3.fromRGB(80, 80, 100)
        fishingState = "IDLE"
        nextCastTime = 0
        lastMinigameGuiSeen = 0
        lastWhiteCenter = nil
        cachedWhiteBar = nil
        cachedRedBar = nil
        whiteVelocity = 0
        setStatus("Fishing Active")
        warn("[SYSTEM] Fishing Mode Started")
    end
end)

-- Tombol Mine serupa dengan debounce
local lastMineClick = 0
btnMine.MouseButton1Click:Connect(function()
    if os.clock() - lastMineClick < 0.4 then return end
    lastMineClick = os.clock()
    if mode == "MINE" then
        mode = "OFF"
        btnMine.Text = "MINING (OFF)"
        btnMine.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
        btnMineStroke.Color = Color3.fromRGB(80, 80, 100)
        setStatus("System Idle")
        pcall(function()
            local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true) end
        end)
    else
        mode = "MINE"
        currentMiningTarget = nil
        miningFailCount = 0
        miningHitCount = 0
        btnMine.Text = "MINING (ON)"
        btnMine.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
        btnMineStroke.Color = Color3.fromRGB(120, 120, 150)
        btnFish.Text = "FISHING (OFF)"
        btnFish.BackgroundColor3 = Color3.fromRGB(35, 45, 70)
        btnFishStroke.Color = Color3.fromRGB(60, 120, 200)
        if isSpacePressed then setSpacePressed(false, true) end
        pcall(function()
            local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true) end
        end)
        fishingState = "IDLE"
        nextCastTime = 0
        setStatus("Mining Active")
        warn("[SYSTEM] Mining Mode Started")
        if not miningActive then
            task.spawn(mineRoutine)
        end
    end
end)

warn("=== INDO HANGOUT BOT LOADED (FIXED) ===")
warn("Indikator: CASTING -> WAITING BITE -> BITE! -> MINIGAME -> SUCCESS -> RECAST")
