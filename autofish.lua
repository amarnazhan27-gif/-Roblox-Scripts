-- ==========================================================
-- INDO HANGOUT ULTIMATE AUTO-FISH (V3.1 - FIXED GUI FREEZE)
-- ==========================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer

local rodEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("RemoteEvent"):WaitForChild("Rod")

local fishingState = "IDLE" -- Status: "IDLE", "WAITING", atau "REELING"
local autoFishEnabled = false

-- ==========================================
-- 1. SISTEM ANTI-AFK (Bisa Ditinggal Tidur)
-- ==========================================
player.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    task.wait(math.random(5, 15) / 10)
    VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
end)

-- ==========================================
-- 2. MATIKAN ANIMASI KAMERA
-- ==========================================
player:SetAttribute("DisableFishingAnimation", true)

-- ==========================================
-- 3. GUI KONTROL (TAMPIL INSTAN & AMAN)
-- ==========================================
local gui = Instance.new("ScreenGui")
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

button.MouseButton1Click:Connect(function()
    autoFishEnabled = not autoFishEnabled
    button.Text = autoFishEnabled and "ON (FISHING...)" or "OFF"
    button.BackgroundColor3 = autoFishEnabled and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
    
    if not autoFishEnabled then
        fishingState = "IDLE" 
    end
end)

-- ==========================================
-- 4. SIMULASI MINIGAME (HUMANIZED CATCH)
-- ==========================================
rodEvent.OnClientEvent:Connect(function(action, rodName)
    if autoFishEnabled and action == "StartReeling" then
        fishingState = "REELING" -- Kunci status agar auto cast berhenti klik
        
        local reactionTime = math.random(5, 12) / 10 
        local playTime = math.random(25, 45) / 10 
        
        task.wait(reactionTime + playTime)
        
        pcall(function()
            rodEvent:FireServer("Catch", true, rodName)
        end)
        
        task.wait(0.5)
        local playerGui = player:FindFirstChild("PlayerGui")
        if playerGui then
            for _, v in pairs(playerGui:GetChildren()) do
                if v:FindFirstChild("MainFrame") and v.MainFrame:FindFirstChild("Frame") then
                    v.Enabled = false
                end
            end
        end
        
        task.wait(math.random(15, 30) / 10) 
        fishingState = "IDLE" -- Buka kunci setelah selesai dapat ikan
    end
end)

-- ==========================================
-- 5. AUTO CAST (THREAD TERPISAH - JEDA LUAS 20 DETIK)
-- ==========================================
task.spawn(function()
    while true do
        task.wait(0.5) -- Loop ringan untuk memantau status
        
        if autoFishEnabled and fishingState == "IDLE" then
            local char = player.Character
            if char then
                local tool = char:FindFirstChildOfClass("Tool")
                if tool then
                    fishingState = "WAITING" -- Kunci status agar tidak terjadi klik ganda
                    
                    pcall(function()
                        tool:Activate() -- Lempar umpan
                    end)
                    
                    -- Masukkan sistem tunggu 20 detik ke thread terpisah agar skrip tidak lag/freeze
                    task.spawn(function()
                        task.wait(20) -- Beri jarak aman 20 detik penuh untuk memicu minigame
                        
                        -- Jika setelah 20 detik ikan tidak makan umpan (masih WAITING), reset ke IDLE agar lempar ulang
                        if fishingState == "WAITING" then
                            fishingState = "IDLE"
                        end
                    end)
                end
            end
        end
    end
end)
