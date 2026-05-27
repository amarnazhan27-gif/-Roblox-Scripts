-- ==========================================================
-- INDO HANGOUT ULTIMATE AUTO-FISH (SAFE & HUMANIZED MODE)
-- ==========================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer

local rodEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("RemoteEvent"):WaitForChild("Rod")

-- ==========================================
-- 1. SISTEM ANTI-AFK (Bisa Ditinggal Tidur)
-- ==========================================
player.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    task.wait(math.random(5, 15) / 10) -- Jeda acak
    VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
end)

-- ==========================================
-- 2. MATIKAN ANIMASI KAMERA (Aman karena fitur bawaan game)
-- ==========================================
player:SetAttribute("DisableFishingAnimation", true)

-- ==========================================
-- 3. GUI KONTROL SUPER RINGAN & DRAGGABLE (NAMA ACAK)
-- ==========================================
local gui = Instance.new("ScreenGui")
-- Nama GUI diacak agar tidak terdeteksi oleh Anti-Cheat yang mencari nama spesifik
gui.Name = HttpService:GenerateGUID(false) 
gui.ResetOnSpawn = false
gui.Parent = game:GetService("CoreGui")

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 150, 0, 70)
frame.Position = UDim2.new(0.5, -75, 0.8, 0)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BorderSizePixel = 2
frame.BorderColor3 = Color3.fromRGB(200, 200, 200)
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 20)
title.BackgroundTransparency = 1
title.Text = "AUTO FISH (SAFE)"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.Code
title.TextSize = 14

local button = Instance.new("TextButton", frame)
button.Size = UDim2.new(0, 130, 0, 35)
button.Position = UDim2.new(0.5, -65, 0, 25)
button.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
button.Text = "OFF"
button.Font = Enum.Font.GothamBold
button.TextScaled = true
button.TextColor3 = Color3.new(1, 1, 1)

local autoFishEnabled = false
local isReeling = false -- Penanda agar skrip tidak spam klik saat sedang narik ikan

button.MouseButton1Click:Connect(function()
    autoFishEnabled = not autoFishEnabled
    button.Text = autoFishEnabled and "ON (FISHING...)" or "OFF"
    button.BackgroundColor3 = autoFishEnabled and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
end)

-- ==========================================
-- 4. SIMULASI MINIGAME (HUMANIZED CATCH)
-- ==========================================
rodEvent.OnClientEvent:Connect(function(action, rodName)
    if autoFishEnabled and action == "StartReeling" then
        isReeling = true
        
        -- Waktu reaksi manusia (0.5 sampai 1.2 detik)
        local reactionTime = math.random(5, 12) / 10 
        -- Waktu pura-pura main minigame (2.5 sampai 4.5 detik)
        local playTime = math.random(25, 45) / 10 
        
        -- Tunggu total waktu yang natural sebelum menangkap
        task.wait(reactionTime + playTime)
        
        -- Gunakan pcall (Protected Call) agar jika server ngelag, skrip tidak error
        pcall(function()
            rodEvent:FireServer("Catch", true, rodName)
        end)
        
        -- Tutup GUI minigame secara paksa tapi dengan delay natural
        task.wait(0.5)
        local playerGui = player:FindFirstChild("PlayerGui")
        if playerGui then
            for _, v in pairs(playerGui:GetChildren()) do
                if v:FindFirstChild("MainFrame") and v.MainFrame:FindFirstChild("Frame") then
                    v.Enabled = false
                end
            end
        end
        
        isReeling = false
    end
end)

-- ==========================================
-- 5. AUTO CAST DENGAN JEDA ACAK
-- ==========================================
task.spawn(function()
    while true do
        -- Jeda acak antara 1.5 detik sampai 3.5 detik untuk setiap lemparan
        task.wait(math.random(15, 35) / 10) 
        
        if autoFishEnabled and not isReeling then
            local char = player.Character
            if char then
                local tool = char:FindFirstChildOfClass("Tool")
                if tool then
                    pcall(function()
                        tool:Activate()
                    end)
                end
            end
        end
    end
end)
