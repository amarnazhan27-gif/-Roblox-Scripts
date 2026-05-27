-- ==========================================================
-- INDO HANGOUT AUTO-FISH (V8 - THE ULTIMATE UNIFIED SCRIPT)
-- ==========================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local player = Players.LocalPlayer

-- State Machine Global (Aman & Sinkron)
local enabled = false
local fishingState = "IDLE" -- IDLE, WAITING, MINIGAME, COOLDOWN
local lastCastTime = 0
local lastMinigameTime = 0
local isSpacePressed = false

-- ==========================================
-- 1. GUI KONTROL INTERFACE
-- ==========================================
local gui = Instance.new("ScreenGui")
gui.Name = "AutoFish_V8_Unified"
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
title.Text = "AUTO FISH V8"
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

button.MouseButton1Click:Connect(function()
    enabled = not enabled
    button.Text = enabled and "ON" or "OFF"
    button.BackgroundColor3 = enabled and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
    
    if not enabled then
        fishingState = "IDLE"
        if isSpacePressed then
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
            isSpacePressed = false
        end
    else
        fishingState = "IDLE"
    end
end)

-- ==========================================
-- 2. FUNGSI PELACAK INDIKATOR BAR (MILIK ANDA)
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
-- 3. INTERFASI HEARTBEAT (100% ANTI-YIELD / ANTI-LOMPAT)
-- ==========================================
RunService.Heartbeat:Connect(function()
    if not enabled then return end

    local white, red = getFishingElements()

    -- JIKA UI MINIGAME MUNCUL (Bermain Minigame)
    if white and red and white.Visible then
        fishingState = "MINIGAME"
        
        local whiteCenter = white.AbsolutePosition.X + (white.AbsoluteSize.X / 2)
        local redCenter = red.AbsolutePosition.X + (red.AbsoluteSize.X / 2)
        -- Toleransi jarak 10% sesuai kodingan sukses Anda
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
        -- Proteksi Instant: Lepas spasi detik ini juga agar TIDAK LOMPAT
        if isSpacePressed then
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
            isSpacePressed = false
        end
        
        -- Manajemen Transisi State Berbasis Waktu Mikro (Aman dari Bug Thread)
        if fishingState == "MINIGAME" then
            fishingState = "COOLDOWN"
            lastMinigameTime = os.time()
        elseif fishingState == "COOLDOWN" then
            -- Jeda 2 detik setelah minigame menghilang agar animasi selesai, lalu kembali ke IDLE
            if os.time() - lastMinigameTime >= 2 then
                fishingState = "IDLE"
            end
        end
    end
end)

-- ==========================================
-- 4. LOOP SEPARASI OTOMATIS LEMPAR & RECAST (20 DETIK)
-- ==========================================
task.spawn(function()
    while true do
        task.wait(0.5) -- Cek berkala secara stabil setiap setengah detik
        
        if enabled then
            local char = player.Character
            local tool = char and char:FindFirstChildOfClass("Tool")
            
            -- Otomatis ambil pancingan dari tas jika belum dipegang
            if not tool and player:FindFirstChild("Backpack") then
                local backpackTool = player.Backpack:FindFirstChildOfClass("Tool")
                if backpackTool then
                    backpackTool.Parent = char
                    task.wait(0.3)
                    tool = backpackTool
                end
            end
            
            if tool then
                -- TAHAP TEPAT: JIKA STATUS IDLE, LEMPAR UMPAN!
                if fishingState == "IDLE" then
                    fishingState = "WAITING"
                    lastCastTime = os.time()
                    print("[Auto-Fish] Melempar umpan otomatis...")
                    
                    pcall(function()
                        tool:Activate()
                        -- Simulasi klik fisik di tengah layar untuk memicu pancingan custom
                        VirtualInputManager:SendMouseButtonEvent(200, 200, 0, true, game, 0)
                        task.wait(0.1)
                        VirtualInputManager:SendMouseButtonEvent(200, 200, 0, false, game, 0)
                    end)
                    
                -- TAHAP FAILSAFE: JIKA SUDAH 20 DETIK TANPA GIGITAN, RECAST!
                elseif fishingState == "WAITING" and (os.time() - lastCastTime) >= 20 then
                    fishingState = "IDLE"
                    print("[Auto-Fish] Jarak umpan mencapai 20 detik. Tarik paksa dan lempar ulang!")
                    
                    pcall(function()
                        tool:Activate() -- Tarik pancingan kembali
                        VirtualInputManager:SendMouseButtonEvent(200, 200, 0, true, game, 0)
                        task.wait(0.1)
                        VirtualInputManager:SendMouseButtonEvent(200, 200, 0, false, game, 0)
                    end)
                    task.wait(1.5) -- Beri waktu jeda tarikan sebelum masuk ke loop lempar berikutnya
                end
            end
        end
    end
end)
