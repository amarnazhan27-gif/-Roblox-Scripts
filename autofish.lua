-- ==========================================================
-- INDO HANGOUT ALL-IN-ONE: AUTO FISH + AUTO MINE CRYSTAL
-- ANDROID/DELTA COMPATIBLE - FINAL VERSION
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
local mode = "OFF"       -- OFF, FISH, MINE
local isSpacePressed = false
local fishingState = "IDLE"
local lastCastTime = 0
local lastMinigameTime = 0
local isCasting = false
local minigameJustStarted = false
local miningActive = false

-- Nama tool yang akan dicari (auto-detect fallback)
local FISH_TOOL_NAMES = {"Fishing Rod", "Rod", "Pancing", "FishingRod"}
local MINE_TOOL_NAMES = {"Pickaxe", "Cangkul", "Kapak", "Mining", "Pick", "Hammer"}

-- Nama/properti crystal di workspace
local CRYSTAL_NAMES = {"8sisi", "Crystal", "Kristal", "Gem", "Ore", "Batu"}
local CRYSTAL_MATERIAL = Enum.Material.Neon -- Material 272 = Neon (sesuai file map)

-- ==========================================
-- GUI UTAMA
-- ==========================================
local gui = Instance.new("ScreenGui")
gui.Name = "AllInOne_IH"
gui.ResetOnSpawn = false
gui.Parent = game:GetService("CoreGui")

local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0, 220, 0, 160)
main.Position = UDim2.new(1, -230, 0, 100)
main.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
main.BorderSizePixel = 2
main.BorderColor3 = Color3.fromRGB(0, 200, 255)
main.Active = true
main.Draggable = true

-- Title
local title = Instance.new("TextLabel", main)
title.Size = UDim2.new(1, 0, 0, 28)
title.BackgroundColor3 = Color3.fromRGB(0, 100, 150)
title.Text = "INDO HANGOUT BOT"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextScaled = true

-- Status label
local statusLabel = Instance.new("TextLabel", main)
statusLabel.Size = UDim2.new(1, 0, 0, 22)
statusLabel.Position = UDim2.new(0, 0, 0, 28)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: OFF"
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.Font = Enum.Font.Code
statusLabel.TextScaled = true

-- Tombol FISH
local btnFish = Instance.new("TextButton", main)
btnFish.Size = UDim2.new(0.9, 0, 0, 40)
btnFish.Position = UDim2.new(0.05, 0, 0, 55)
btnFish.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
btnFish.Text = "🎣 AUTO FISH: OFF"
btnFish.Font = Enum.Font.GothamBold
btnFish.TextScaled = true
btnFish.TextColor3 = Color3.new(1, 1, 1)

-- Tombol MINE
local btnMine = Instance.new("TextButton", main)
btnMine.Size = UDim2.new(0.9, 0, 0, 40)
btnMine.Position = UDim2.new(0.05, 0, 0, 100)
btnMine.BackgroundColor3 = Color3.fromRGB(150, 80, 20)
btnMine.Text = "⛏️ AUTO MINE: OFF"
btnMine.Font = Enum.Font.GothamBold
btnMine.TextScaled = true
btnMine.TextColor3 = Color3.new(1, 1, 1)

-- ==========================================
-- HELPER: CARI TOOL DI BACKPACK/CHAR
-- ==========================================
local function findTool(nameList)
    local char = player.Character
    local bp = player.Backpack
    for _, name in ipairs(nameList) do
        -- Cek di tangan dulu
        if char then
            local t = char:FindFirstChild(name)
            if t and t:IsA("Tool") then return t, "hand" end
        end
        -- Cek backpack
        local t = bp:FindFirstChild(name)
        if t then return t, "backpack" end
    end
    -- Fallback: ambil tool apapun
    if char then
        local t = char:FindFirstChildWhichIsA("Tool")
        if t then return t, "hand" end
    end
    local t = bp:FindFirstChildWhichIsA("Tool")
    if t then return t, "backpack" end
    return nil, nil
end

-- ==========================================
-- HELPER: EQUIPT TOOL
-- ==========================================
local function equipTool(nameList)
    local char = player.Character
    if not char then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return nil end

    -- Sudah di tangan?
    local toolInHand = char:FindFirstChildWhichIsA("Tool")

    -- Cek apakah tool di tangan sudah sesuai
    for _, name in ipairs(nameList) do
        if toolInHand and toolInHand.Name:lower():find(name:lower()) then
            return toolInHand
        end
    end

    -- Cari di backpack
    local tool, loc = findTool(nameList)
    if tool and loc == "backpack" then
        hum:EquipTool(tool)
        task.wait(0.8)
        return char:FindFirstChildWhichIsA("Tool")
    end
    return toolInHand
end

-- ==========================================
-- FISHING: CAST ROD
-- ==========================================
local function castRod()
    if isCasting then return end
    isCasting = true
    pcall(function()
        local cam = workspace.CurrentCamera
        if not cam then return end
        local screenCenter = cam.ViewportSize / 2
        warn("[FISH] Casting...")
        VirtualUser:Button1Down(screenCenter, cam.CFrame)
        task.wait(1.8)
        VirtualUser:Button1Up(screenCenter, cam.CFrame)
        warn("[FISH] Umpan dilempar!")
    end)
    task.wait(2)
    isCasting = false
end

-- ==========================================
-- FISHING: PELACAK BAR MINIGAME
-- ==========================================
local function getFishingElements()
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return nil, nil end
    for _, v in pairs(playerGui:GetDescendants()) do
        if v.Name == "WhiteBar" and v:IsA("GuiObject") then
            local parent = v.Parent
            local red = parent and parent:FindFirstChild("RedBar")
            if red and red:IsA("GuiObject") then
                return v, red
            end
        end
    end
    return nil, nil
end

-- ==========================================
-- MINING: CARI CRYSTAL TERDEKAT
-- ==========================================
local function findNearestCrystal()
    local char = player.Character
    if not char or not char.PrimaryPart then return nil end
    local myPos = char.PrimaryPart.Position
    local nearest = nil
    local nearestDist = math.huge

    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("MeshPart") then
            -- Deteksi berdasarkan nama ATAU material Neon
            local nameMatch = false
            local matMatch = obj.Material == CRYSTAL_MATERIAL

            for _, cname in ipairs(CRYSTAL_NAMES) do
                if obj.Name:lower():find(cname:lower()) then
                    nameMatch = true
                    break
                end
            end

            if nameMatch or matMatch then
                local dist = (obj.Position - myPos).Magnitude
                if dist < nearestDist and dist < 200 then
                    nearest = obj
                    nearestDist = dist
                end
            end
        end
    end
    return nearest, nearestDist
end

-- ==========================================
-- MINING: JALAN KE CRYSTAL & TAMBANG
-- ==========================================
local function mineRoutine()
    miningActive = true
    while mode == "MINE" do
        task.wait(0.5)
        local char = player.Character
        if not char then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then continue end

        -- Disable lompat saat mine
        if hum:GetStateEnabled(Enum.HumanoidStateType.Jumping) then
            hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
        end

        -- Cari crystal terdekat
        local crystal, dist = findNearestCrystal()

        if not crystal then
            statusLabel.Text = "Mining: Crystal not found!"
            warn("[MINE] Crystal tidak ditemukan. Scan workspace...")
            task.wait(3)
            continue
        end

        statusLabel.Text = "Mining: " .. crystal.Name .. " (" .. math.floor(dist) .. " stud)"
        warn("[MINE] Crystal ditemukan: " .. crystal.Name .. " jarak: " .. math.floor(dist))

        -- Equip pickaxe
        local tool = equipTool(MINE_TOOL_NAMES)
        if not tool then
            statusLabel.Text = "Mining: No pickaxe found!"
            warn("[MINE] Tidak ada pickaxe di backpack!")
            task.wait(3)
            continue
        end

        -- Jalan ke crystal
        if dist > 8 then
            warn("[MINE] Jalan ke crystal...")
            hum:MoveTo(crystal.Position)
            -- Tunggu sampai dekat (max 10 detik)
            local t = 0
            while t < 10 and mode == "MINE" do
                task.wait(0.2)
                t = t + 0.2
                local newDist = (char.PrimaryPart.Position - crystal.Position).Magnitude
                if newDist <= 8 then break end
            end
        end

        -- Tambang: klik berkali-kali pada crystal
        local cam = workspace.CurrentCamera
        if cam then
            local screenPos, onScreen = cam:WorldToScreenPoint(crystal.Position)
            if onScreen then
                warn("[MINE] Menambang crystal...")
                for i = 1, 5 do
                    if mode ~= "MINE" then break end
                    -- Klik di posisi crystal di layar
                    VirtualUser:Button1Down(
                        Vector2.new(screenPos.X, screenPos.Y),
                        cam.CFrame
                    )
                    task.wait(0.15)
                    VirtualUser:Button1Up(
                        Vector2.new(screenPos.X, screenPos.Y),
                        cam.CFrame
                    )
                    task.wait(0.3)
                end
            else
                -- Crystal tidak terlihat di layar, coba activate tool
                warn("[MINE] Crystal di luar layar, activate tool...")
                pcall(function() tool:Activate() end)
                task.wait(1)
            end
        end

        task.wait(0.5)
    end
    miningActive = false
end

-- ==========================================
-- FISHING MINIGAME HANDLER (Heartbeat)
-- ==========================================
RunService.Heartbeat:Connect(function()
    if mode ~= "FISH" then
        -- Paksa lepas Space jika tidak fishing
        if isSpacePressed then
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
            isSpacePressed = false
        end
        return
    end

    local white, red = getFishingElements()

    if white and red and white.Visible then
        -- Minigame aktif
        if not minigameJustStarted then
            minigameJustStarted = true
            -- Reset paksa Space di awal minigame
            if isSpacePressed then
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                isSpacePressed = false
            end
            fishingState = "MINIGAME"
            statusLabel.Text = "Fish: Minigame!"
            warn("[FISH] Minigame dimulai!")
        end

        local whiteCenter = white.AbsolutePosition.X + (white.AbsoluteSize.X / 2)
        local redCenter = red.AbsolutePosition.X + (red.AbsoluteSize.X / 2)
        -- Toleransi kecil = lebih presisi = lebih sering menang
        local tolerance = white.AbsoluteSize.X * 0.05

        if whiteCenter < (redCenter - tolerance) then
            if not isSpacePressed then
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                isSpacePressed = true
            end
        elseif whiteCenter > (redCenter + tolerance) then
            if isSpacePressed then
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                isSpacePressed = false
            end
        end

    else
        -- Minigame tidak aktif
        minigameJustStarted = false
        if isSpacePressed then
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
            isSpacePressed = false
        end

        if fishingState == "MINIGAME" then
            fishingState = "COOLDOWN"
            lastMinigameTime = os.time()
            warn("[FISH] Minigame selesai!")
        elseif fishingState == "COOLDOWN" then
            if os.time() - lastMinigameTime >= 1 then
                fishingState = "IDLE"
                statusLabel.Text = "Fish: Siap cast..."
            end
        end
    end
end)

-- ==========================================
-- FISHING EQUIP + CAST LOOP
-- ==========================================
task.spawn(function()
    while true do
        task.wait(0.5)
        if mode ~= "FISH" then continue end

        local char = player.Character
        if not char then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")

        -- Anti lompat
        if hum and hum:GetStateEnabled(Enum.HumanoidStateType.Jumping) then
            hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
        end

        -- Equip rod
        local tool = equipTool(FISH_TOOL_NAMES)

        if tool and not isCasting then
            if fishingState == "IDLE" or
               (fishingState == "WAITING" and (os.time() - lastCastTime) >= 20) then
                fishingState = "WAITING"
                lastCastTime = os.time()
                statusLabel.Text = "Fish: Casting..."
                task.spawn(castRod)
            elseif fishingState == "WAITING" then
                statusLabel.Text = "Fish: Menunggu gigitan..."
            end
        elseif not tool then
            statusLabel.Text = "Fish: Tidak ada rod!"
        end
    end
end)

-- ==========================================
-- TOMBOL FISH
-- ==========================================
btnFish.MouseButton1Click:Connect(function()
    if mode == "FISH" then
        -- Matikan fish
        mode = "OFF"
        btnFish.Text = "🎣 AUTO FISH: OFF"
        btnFish.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
        fishingState = "IDLE"
        isCasting = false
        statusLabel.Text = "Status: OFF"

        if isSpacePressed then
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
            isSpacePressed = false
        end
        pcall(function()
            local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true) end
        end)
    else
        -- Nyalakan fish, matikan mine
        mode = "FISH"
        btnFish.Text = "🎣 AUTO FISH: ON"
        btnFish.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        btnMine.Text = "⛏️ AUTO MINE: OFF"
        btnMine.BackgroundColor3 = Color3.fromRGB(150, 80, 20)
        fishingState = "IDLE"
        statusLabel.Text = "Fish: Aktif..."
        warn("[SYSTEM] Mode FISHING aktif")
    end
end)

-- ==========================================
-- TOMBOL MINE
-- ==========================================
btnMine.MouseButton1Click:Connect(function()
    if mode == "MINE" then
        -- Matikan mine
        mode = "OFF"
        btnMine.Text = "⛏️ AUTO MINE: OFF"
        btnMine.BackgroundColor3 = Color3.fromRGB(150, 80, 20)
        statusLabel.Text = "Status: OFF"

        pcall(function()
            local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true) end
        end)
    else
        -- Nyalakan mine, matikan fish
        mode = "MINE"
        btnMine.Text = "⛏️ AUTO MINE: ON"
        btnMine.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        btnFish.Text = "🎣 AUTO FISH: OFF"
        btnFish.BackgroundColor3 = Color3.fromRGB(50, 100, 200)

        if isSpacePressed then
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
            isSpacePressed = false
        end
        fishingState = "IDLE"
        statusLabel.Text = "Mine: Aktif..."
        warn("[SYSTEM] Mode MINING aktif")

        if not miningActive then
            task.spawn(mineRoutine)
        end
    end
end)

warn("=== INDO HANGOUT BOT LOADED ===")
warn("Tombol FISH = Auto Mancing")
warn("Tombol MINE = Auto Nambang Crystal")
warn("Jika crystal tidak ditemukan, cek output untuk scan nama object")
