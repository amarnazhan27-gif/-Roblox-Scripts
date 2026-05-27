-- ==========================================================
-- INDO HANGOUT AUTO-FISH (V4 - THE PERFECT REVERT)
-- ==========================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local randomGuiName = "IH_UI_" .. tostring(math.random(100000, 999999))
local autoFishEnabled = false
local fishingState = "IDLE"

-- ==========================================
-- 1. GUI KONTROL (INSTAN)
-- ==========================================
local gui = Instance.new("ScreenGui")
gui.Name = randomGuiName
gui.ResetOnSpawn = false
gui.Parent = playerGui

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 160, 0, 70)
frame.Position = UDim2.new(0.5, -80, 0.8, 0)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BorderSizePixel = 2
frame.BorderColor3 = Color3.fromRGB(200, 200, 200)
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 20)
title.BackgroundTransparency = 1
title.Text = "AUTO FISH (V4 FIXED)"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.Code
title.TextSize = 13

local button = Instance.new("TextButton", frame)
button.Size = UDim2.new(0, 140, 0, 35)
button.Position = UDim2.new(0.5, -70, 0, 25)
button.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
button.Text = "OFF"
button.Font = Enum.Font.GothamBold
button.TextScaled = true
button.TextColor3 = Color3.new(1, 1, 1)

button.MouseButton1Click:Connect(function()
    autoFishEnabled = not autoFishEnabled
    button.Text = autoFishEnabled and "ON (FISHING...)" or "OFF"
    button.BackgroundColor3 = autoFishEnabled and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
    if not autoFishEnabled then fishingState = "IDLE" end
end)

-- Anti-AFK agar tidak di-kick server
player.Idled:Connect(function()
    pcall(function()
        VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(0.5)
        VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end)
end)

player:SetAttribute("DisableFishingAnimation", true)

-- ==========================================
-- 2. DETEKSI MINIGAME (ANTI-BUTA) & BYPASS
-- ==========================================
task.spawn(function()
    -- WaitForChild tanpa batas waktu memastikan skrip TERUS MENCARI sampai dapat, tidak akan gagal/buta
    local events = ReplicatedStorage:WaitForChild("Events", 9e9)
    local remoteEvent = events:WaitForChild("RemoteEvent", 9e9)
    local rodEvent = remoteEvent:WaitForChild("Rod", 9e9)

    print("[Auto-Fish] Jalur Server Ditemukan! Siap mendeteksi ikan.")

    rodEvent.OnClientEvent:Connect(function(action, rodName)
        -- Jika event yang ditangkap adalah "StartReeling" (minigame dimulai)
        if autoFishEnabled and action == "StartReeling" then
            fishingState = "REELING"
            print("[Auto-Fish] Ikan menyambar! Menunggu 2-3 detik...")
            
            -- Waktu tunggu yang pas, meniru jeda manusia (seperti yang "tadi bisa")
            task.wait(math.random(20, 35) / 10)
            
            if autoFishEnabled then
                -- BYPASS: Langsung kirim sinyal "Berhasil" ke server
                pcall(function()
                    rodEvent:FireServer("Catch", true, rodName)
                    print("[Auto-Fish] Tangkapan sukses dikirim!")
                end)
                
                -- Menutup GUI minigame bawaan agar layar tidak penuh
                task.wait(0.5)
                pcall(function()
                    for _, v in pairs(playerGui:GetChildren()) do
                        if v:FindFirstChild("MainFrame") and v.MainFrame:FindFirstChild("Frame") then
                            v.Enabled = false
                        end
                    end
                end)
                
                task.wait(2) 
                fishingState = "IDLE" -- Reset untuk lempar umpan lagi
            end
        end
    end)
end)

-- ==========================================
-- 3. AUTO CAST (DENGAN FAILSAFE 20 DETIK)
-- ==========================================
task.spawn(function()
    while true do
        task.wait(1) 
        
        if autoFishEnabled and fishingState == "IDLE" then
            local char = player.Character
            if char then
                local tool = char:FindFirstChildOfClass("Tool")
                if tool then
                    fishingState = "WAITING"
                    print("[Auto-Fish] Melempar umpan...")
                    
                    pcall(function()
                        tool:Activate()
                    end)
                    
                    -- Failsafe 20 Detik (Sesuai pesanan sebelumnya)
                    task.spawn(function()
                        task.wait(20)
                        if fishingState == "WAITING" and autoFishEnabled then
                            fishingState = "IDLE"
                            print("[Auto-Fish] 20 detik habis, tarik paksa untuk lempar ulang.")
                        end
                    end)
                end
            end
        end
    end
end)
