-- ==========================================================
-- INDO HANGOUT ALL-IN-ONE AUTO-FISH (FIXED SAFE ZONE CLICK)
-- ==========================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local player = Players.LocalPlayer

local enabled = false
local isSpacePressed = false
local lastCastTime = 0
local castCooldown = 7 -- Jeda waktu (detik) untuk melempar ulang jika ikan tidak gigit

-- ==========================================
-- 1. GUI INTERFACE
-- ==========================================
local gui = Instance.new("ScreenGui")
gui.Name = "AutoFish_FullSystem"
gui.ResetOnSpawn = false
gui.Parent = game:GetService("CoreGui")

local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0, 200, 0, 100)
main.Position = UDim2.new(1, -210, 0, 150) 
main.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
main.BorderSizePixel = 2
main.BorderColor3 = Color3.fromRGB(0, 255, 150)
main.Active = true
main.Draggable = true 

local title = Instance.new("TextLabel", main)
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.Text = "AUTO FISH v3 (SAFE CLICK)"
title.TextColor3 = Color3.fromRGB(0, 255, 150)
title.Font = Enum.Font.Code
title.TextScaled = true

local button = Instance.new("TextButton", main)
button.Size = UDim2.new(0.9, 0, 0, 45)
button.Position = UDim2.new(0.05, 0, 0.45, 0)
button.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
button.Text = "SYSTEM OFF"
button.Font = Enum.Font.GothamBold
button.TextScaled = true
button.TextColor3 = Color3.new(1, 1, 1)

button.MouseButton1Click:Connect(function()
    enabled = not enabled
    button.Text = enabled and "SYSTEM ON" or "SYSTEM OFF"
    button.BackgroundColor3 = enabled and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
    
    if not enabled then
        if isSpacePressed then
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
            isSpacePressed = false
        end
    else
        lastCastTime = tick()
    end
end)

-- ==========================================
-- 2. RADAR PELACAK BAR MINIGAME
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
-- 3. AMAN DARI UI: SIMULASI KETUK AREA SUNGAI (KIRI)
-- ==========================================
local function blindClick()
    local camera = workspace.CurrentCamera
    if not camera then return end
    
    -- Menggunakan persentase layar agar akurat di HP ukuran apapun
    -- X = 25% dari kiri layar (Area sungai yang kosong)
    -- Y = 50% dari atas layar (Tengah-tengah vertikal, menghindari analog jalan)
    local safeX = camera.ViewportSize.X * 0.25
    local safeY = camera.ViewportSize.Y * 0.5

    -- Eksekusi ketukan di zona aman
    VirtualInputManager:SendMouseButtonEvent(safeX, safeY, 0, true, game)
    task.wait(0.05)
    VirtualInputManager:SendMouseButtonEvent(safeX, safeY, 0, false, game)
end

-- ==========================================
-- 4. LOGIKA UTAMA (LOOPING)
-- ==========================================
RunService.Heartbeat:Connect(function()
    if not enabled then return end

    local white, red = getFishingElements()

    -- Kondisi A: Minigame Muncul
    if white and red and white.Visible then
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
        
        lastCastTime = tick() 

    -- Kondisi B: Standby / Selesai Memancing
    else
        if isSpacePressed then
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
            isSpacePressed = false
            lastCastTime = tick() + 2 -- Jeda pasca tangkap
        end

        if tick() - lastCastTime > castCooldown then
            blindClick()
            lastCastTime = tick()
        end
    end
end)
