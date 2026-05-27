-- ==========================================================
-- INDO HANGOUT ULTIMATE AUTO-FISH (V3.4 - INPUT SIMULATION)
-- ==========================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local randomGuiName = "IH_UI_" .. tostring(math.random(100000, 999999))

-- Variabel Status
local autoFishEnabled = false
local fishingState = "IDLE"

-- Jalur Remote Event
local rodEvent = nil
pcall(function()
    rodEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("RemoteEvent"):WaitForChild("Rod")
end)

-- ==========================================
-- 1. GUI KONTROL (RENDERING INSTAN)
-- ==========================================
local gui = Instance.new("ScreenGui")
gui.Name = randomGuiName
gui.ResetOnSpawn = false
gui.Parent = playerGui

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 160, 0, 85)
frame.Position = UDim2.new(0.5, -80, 0.8, 0)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BorderSizePixel = 2
frame.BorderColor3 = Color3.fromRGB(200, 200, 200)
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 20)
title.BackgroundTransparency = 1
title.Text = "AUTO FISH V3.4"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.Code
title.TextSize = 14

local button = Instance.new("TextButton", frame)
button.Size = UDim2.new(0, 140, 0, 35)
button.Position = UDim2.new(0.5, -70, 0, 25)
button.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
button.Text = "OFF"
button.Font = Enum.Font.GothamBold
button.TextScaled = true
button.TextColor3 = Color3.new(1, 1, 1)

local statusLabel = Instance.new("TextLabel", frame)
statusLabel.Size = UDim2.new(1, 0, 0, 15)
statusLabel.Position = UDim2.new(0, 0, 0, 65)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: IDLE"
statusLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
statusLabel.Font = Enum.Font.SourceSansBold
statusLabel.TextSize = 13

button.MouseButton1Click:Connect(function()
    autoFishEnabled = not autoFishEnabled
    button.Text = autoFishEnabled and "ON (FISHING...)" or "OFF"
    button.BackgroundColor3 = autoFishEnabled and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
    fishingState = "IDLE"
    statusLabel.Text = autoFishEnabled and "Status: IDLE" or "Status: OFF"
end)

-- Anti-AFK
player.Idled:Connect(function()
    pcall(function()
        VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(0.5)
        VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end)
end)

player:SetAttribute("DisableFishingAnimation", true)

-- ==========================================
-- 2. SIMULASI KLIK UTK MENYELESAIKAN MINIGAME
-- ==========================================
if rodEvent then
    rodEvent.OnClientEvent:Connect(function(action, rodName)
        if autoFishEnabled and action == "StartReeling" then
            fishingState = "REELING"
            statusLabel.Text = "Status: PLAYING MINIGAME"
            print("[Auto-Fish] Minigame terdeteksi! Mulai simulasi hold & click...")
            
            -- Waktu reaksi sebelum mulai menekan layar (Human reaction time)
            task.wait(math.random(3, 6) / 10)
            
            -- SIMULASI HOLD & CLICK: Melakukan siklus tekan-lepas secara cepat pada layar
            -- Ini akan mengisi progress bar minigame secara natural di mata server
            local minigameDuration = math.random(25, 35) / 10 -- Berjalan selama 2.5 - 3.5 detik
            local startTime = os.clock()
            
            while os.clock() - startTime < minigameDuration and fishingState == "REELING" and autoFishEnabled do
                pcall(function()
                    -- Simulasi Tekan Layar (Hold)
                    VirtualUser:Button1Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                    task.wait(math.random(2, 4) / 10) -- Tahan selama 0.2 - 0.4 detik
                    
                    -- Simulasi Lepas Layar (Release)
                    VirtualUser:Button1Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                    task.wait(math.random(1, 2) / 10) -- Jeda lepas 0.1 - 0.2 detik
                end)
            end
            
            -- Failsafe: Memastikan tombol mouse benar-benar lepas setelah minigame selesai
            pcall(function() VirtualUser:Button1Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame) end)
            
            -- Istirahat sejenak sebelum melempar kembali
            task.wait(math.random(15, 25) / 10) 
            fishingState = "IDLE"
            statusLabel.Text = "Status: IDLE"
            print("[Auto-Fish] Minigame selesai. Bersiap melempar kembali.")
        end
    end)
else
    print("[Auto-Fish] Error: RemoteEvent Rod tidak ditemukan!")
end

-- ==========================================
-- 3. LOOP OTOMATIS MELEMPAR UMPAN (SMART AUTO CAST)
-- ==========================================
task.spawn(function()
    while true do
        task.wait(0.5)
        
        if autoFishEnabled and fishingState == "IDLE" then
            local char = player.Character
            if char then
                local tool = char:FindFirstChildOfClass("Tool")
                if tool then
                    fishingState = "WAITING"
                    statusLabel.Text = "Status: WAITING BITE..."
                    
                    pcall(function()
                        tool:Activate()
                    end)
                    
                    -- Proteksi Batas Tunggu 20 Detik
                    task.spawn(function()
                        task.wait(20)
                        if fishingState == "WAITING" and autoFishEnabled then
                            fishingState = "IDLE"
                            statusLabel.Text = "Status: TIMEOUT RE-CAST"
                            print("[Auto-Fish] Timeout 20 detik tercapai. Melempar ulang.")
                        end
                    end)
                end
            end
        end
    end
end)
