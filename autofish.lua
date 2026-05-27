-- ==========================================================
-- INDO HANGOUT ULTIMATE AUTO-FISH (V3.2 - INSTANT RENDER)
-- ==========================================================

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Ganti HttpService dengan math.random biasa agar tidak bikin crash di Delta
local randomGuiName = "IH_UI_" .. tostring(math.random(100000, 999999))

-- ==========================================================
-- 1. GUI KONTROL (DITARUH DI ATAS AGAR DIJAMIN LANGSUNG MUNCUL)
-- ==========================================================
local gui = Instance.new("ScreenGui")
gui.Name = randomGuiName
gui.ResetOnSpawn = false
gui.Parent = playerGui -- Menggunakan PlayerGui (100% aman di semua executor mobile)

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
title.Text = "AUTO FISH (V3.2)"
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
local fishingState = "IDLE"

button.MouseButton1Click:Connect(function()
    autoFishEnabled = not autoFishEnabled
    button.Text = autoFishEnabled and "ON (FISHING...)" or "OFF"
    button.BackgroundColor3 = autoFishEnabled and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
    
    if not autoFishEnabled then
        fishingState = "IDLE" 
    end
end)

-- ==========================================================
-- 2. LOGIKA UTAMA GAME (DIBUNGKUS AGAR TIDAK MENAHAN UI)
-- ==========================================================
task.spawn(function()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local VirtualUser = game:GetService("VirtualUser")
    
    -- Ambil folder Events dengan batasan timeout agar tidak stuck selamanya
    local eventsFolder = ReplicatedStorage:WaitForChild("Events", 15)
    if not eventsFolder then return end
    
    local remoteEventFolder = eventsFolder:WaitForChild("RemoteEvent", 15)
    if not remoteEventFolder then return end
    
    local rodEvent = remoteEventFolder:WaitForChild("Rod", 15)
    if not rodEvent then return end

    -- Sistem Anti-AFK
    player.Idled:Connect(function()
        pcall(function()
            VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            task.wait(math.random(5, 15) / 10)
            VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        end)
    end)

    -- Mematikan Animasi Kamera
    player:SetAttribute("DisableFishingAnimation", true)

    -- Sinyal Deteksi Minigame
    rodEvent.OnClientEvent:Connect(function(action, rodName)
        if autoFishEnabled and action == "StartReeling" then
            fishingState = "REELING" 
            
            local reactionTime = math.random(5, 12) / 10 
            local playTime = math.random(25, 45) / 10 
            
            task.wait(reactionTime + playTime)
            
            pcall(function()
                rodEvent:FireServer("Catch", true, rodName)
            end)
            
            task.wait(0.5)
            pcall(function()
                if playerGui then
                    for _, v in pairs(playerGui:GetChildren()) do
                        if v:FindFirstChild("MainFrame") and v.MainFrame:FindFirstChild("Frame") then
                            v.Enabled = false
                        end
                    end
                end
            end)
            
            task.wait(math.random(15, 30) / 10) 
            fishingState = "IDLE" 
        end
    end)

    -- Loop Auto Cast Aman
    while true do
        task.wait(0.5) 
        
        if autoFishEnabled and fishingState == "IDLE" then
            local char = player.Character
            if char then
                local tool = char:FindFirstChildOfClass("Tool")
                if tool then
                    fishingState = "WAITING" 
                    
                    pcall(function()
                        tool:Activate() 
                    end)
                    
                    task.spawn(function()
                        task.wait(20) -- Jeda pengunci 20 detik penuh sesuai instruksi Komandan
                        if fishingState == "WAITING" then
                            fishingState = "IDLE"
                        end
                    end)
                end
            end
        end
    end
end)
