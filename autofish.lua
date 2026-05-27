-- ==========================================================
-- INDO HANGOUT AUTO-FISH (V7 - PERFECT STATE MACHINE)
-- ==========================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local player = Players.LocalPlayer

-- State Management global yang sinkron
local enabled = false
local fishingState = "IDLE" -- IDLE, WAITING, MINIGAME, COOLDOWN
local lastStateChange = os.clock()
local isSpacePressed = false

-- ==========================================
-- 1. KONTROL INTERFACE (GUI CORE)
-- ==========================================
local gui = Instance.new("ScreenGui")
gui.Name = "AutoFish_V7_Final"
gui.ResetOnSpawn = false
gui.Parent = game:GetService("CoreGui")

local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0, 180, 0, 90)
main.Position = UDim2.new(0.5, -90, 0.8, 0)
main.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
main.BorderSizePixel = 2
main.BorderColor3 = Color3.fromRGB(200, 200, 200)
main.Active = true
main.Draggable = true 

local title = Instance.new("TextLabel", main)
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.Text = "AUTO FISH V7"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.Code
title.TextScaled = true

local button = Instance.new("TextButton", main)
button.Size = UDim2.new(0.9, 0, 0, 40)
button.Position = UDim2.new(0.05, 0, 0.45, 0)
button.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
button.Text = "OFF"
button.Font = Enum.Font.GothamBold
button.TextScaled = true
button.TextColor3 = Color3.new(1, 1, 1)

local function changeState(newState)
    fishingState = newState
    lastStateChange = os.clock()
end

button.MouseButton1Click:Connect(function()
    enabled = not enabled
    button.Text = enabled and "ON" or "OFF"
    button.BackgroundColor3 = enabled and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
    
    if not enabled then
        changeState("IDLE")
        if isSpacePressed then
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
            isSpacePressed = false
        end
        -- Kembalikan fungsi lompat jika bot dimatikan
        pcall(function()
            local char = player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true) end
        end)
    end
end)

-- ==========================================
-- 2. DETEKTOR KORDINAT VISUAL BAR
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
-- 3. LOGIKA TRACKING MINIGAME (SINKRON & ANTI-LAG)
-- ==========================================
RunService.Heartbeat:Connect(function()
    if not enabled then return end

    local white, red = getFishingElements()

    -- JIKA MINIGAME AKTIF (UI Terlihat di Layar)
    if white and red and white.Visible then
        fishingState = "MINIGAME"
        
        local whiteCenter = white.AbsolutePosition.X + (white.AbsoluteSize.X / 2)
        local redCenter = red.AbsolutePosition.X + (red.AbsoluteSize.X / 2)
        local tolerance = white.AbsoluteSize.X * 0.1 

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
        
    -- JIKA UI MINIGAME TIDAK ADA DI LAYAR
    else
        -- Failsafe utama: Pastikan spasi langsung dilepas detik ini juga
        if isSpacePressed then
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
            isSpacePressed = false
        end
        
        -- Transisi State Otomatis tanpa merusak thread
        if fishingState == "MINIGAME" then
            changeState("COOLDOWN") -- Masuk masa jeda sejenak setelah menang
        elseif fishingState == "COOLDOWN" then
            if (os.clock() - lastStateChange) > 1.5 then 
                changeState("IDLE") -- Setelah 1.5 detik animasi selesai, siap lempar lagi
            end
        end
    end
end)

-- ==========================================
-- 4. LOOP OTOMATIS LEMPAR UMPAN & FAILSAFE 20s
-- ==========================================
task.spawn(function()
    while true do
        task.wait(0.3) -- Pengecekan intensif berkala cepat
        
        if enabled then
            local char = player.Character
            local tool = char and char:FindFirstChildOfClass("Tool")
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")
            
            -- PROTEKSI TOTAL: Kunci pergerakan lompat agar tidak melompat saat spasi ditekan bot
            if humanoid then
                if humanoid:GetStateEnabled(Enum.HumanoidStateType.Jumping) then
                    humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
                end
            end
            
            if tool then
                -- JIKA READY (IDLE): Langsung lempar pancingan
                if fishingState == "IDLE" then
                    changeState("WAITING")
                    pcall(function()
                        tool:Activate()
                    end)
                    print("[Auto-Fish] Umpan berhasil dilempar otomatis!")
                
                -- JIKA MENUNGGU (WAITING) DAN MATANG 20 DETIK: Tarik paksa / Re-cast
                elseif fishingState == "WAITING" and (os.clock() - lastStateChange) >= 20 then
                    changeState("IDLE")
                    print("[Auto-Fish] Batas 20 detik tercapai tanpa gigitan. Melakukan recast paksa!")
                end
            end
        end
    end
end)
