-- ==========================================================
-- INDO HANGOUT AUTO-FISH (DELTA/ANDROID 100% TOUCH OPTIMIZED)
-- ==========================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local player = Players.LocalPlayer

-- State Machine Global
local enabled = false
local fishingState = "IDLE" 
local lastCastTime = 0
local lastMinigameTime = 0
local isScreenPressed = false -- Diganti dari isSpacePressed

-- Kalkulasi Tengah Layar Dinamis
local cam = workspace.CurrentCamera
local function getScreenCenter()
    return Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
end

-- ==========================================
-- 1. MENGAKTIFKAN TOMBOL ON/OFF 
-- ==========================================
local gui = Instance.new("ScreenGui")
gui.Name = "AutoFish_Sistematis"
gui.ResetOnSpawn = false
gui.Parent = game:GetService("CoreGui")

local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0, 180, 0, 90)
main.Position = UDim2.new(1, -190, 0, 50) 
main.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
main.BorderSizePixel = 2
main.BorderColor3 = Color3.fromRGB(200, 200, 200)
main.Active = true
main.Draggable = true 

local title = Instance.new("TextLabel", main)
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.Text = "AUTO FISH ALUR"
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
        if isScreenPressed then
            VirtualUser:Button1Up(getScreenCenter(), cam.CFrame)
            isScreenPressed = false
        end
        pcall(function()
            local char = player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true) end
        end)
    else
        fishingState = "IDLE"
    end
end)

-- ==========================================
-- 2. FUNGSI PELACAK INDIKATOR BAR
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
-- 3. MINIGAME (MENGGUNAKAN SIMULASI KLIK LAYAR)
-- ==========================================
RunService.Heartbeat:Connect(function()
    if not enabled then return end

    local white, red = getFishingElements()

    if white and red and white.Visible then
        fishingState = "MINIGAME"
        
        local whiteCenter = white.AbsolutePosition.X + (white.AbsoluteSize.X / 2)
        local redCenter = red.AbsolutePosition.X + (red.AbsoluteSize.X / 2)
        local tolerance = white.AbsoluteSize.X * 0.1 

        -- GANTI SPASI DENGAN KLIK/TAHAN LAYAR (TOUCH SIMULATION)
        if whiteCenter < (redCenter - tolerance) then
            if not isScreenPressed then
                VirtualUser:Button1Down(getScreenCenter(), cam.CFrame)
                isScreenPressed = true
            end
        elseif whiteCenter > (redCenter + tolerance) then
            if isScreenPressed then
                VirtualUser:Button1Up(getScreenCenter(), cam.CFrame)
                isScreenPressed = false
            end
        end
        
    else
        if isScreenPressed then
            VirtualUser:Button1Up(getScreenCenter(), cam.CFrame)
            isScreenPressed = false
        end
        
        if fishingState == "MINIGAME" then
            fishingState = "COOLDOWN"
            lastMinigameTime = os.time()
        elseif fishingState == "COOLDOWN" then
            if os.time() - lastMinigameTime >= 1 then
                fishingState = "IDLE" 
            end
        end
    end
end)

-- ==========================================
-- 4. AUTO CAST (MENGGUNAKAN KOORDINAT TENGAH LAYAR)
-- ==========================================
task.spawn(function()
    while true do
        task.wait(0.5) 
        
        if enabled then
            local char = player.Character
            if not char then continue end
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            
            if humanoid and humanoid:GetStateEnabled(Enum.HumanoidStateType.Jumping) then
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
            end
            
            local toolInHand = char:FindFirstChildWhichIsA("Tool")
            local rodInBackpack = player.Backpack:FindFirstChild("Fishing Rod") or player.Backpack:FindFirstChild("Rod") or player.Backpack:FindFirstChildWhichIsA("Tool")

            if not toolInHand and rodInBackpack and humanoid then
                humanoid:EquipTool(rodInBackpack)
                task.wait(1) 
                toolInHand = char:FindFirstChildWhichIsA("Tool")
            end

            if fishingState == "IDLE" or (fishingState == "WAITING" and (os.time() - lastCastTime) >= 20) then
                if toolInHand then
                    fishingState = "WAITING"
                    lastCastTime = os.time()
                    
                    pcall(function()
                        warn(">>> [AUTO FISH] Menyiapkan Tenaga (Casting)...")
                        local center = getScreenCenter()
                        
                        -- Pindahkan klik ke tengah layar agar tidak mengenai tombol menu Roblox
                        VirtualUser:Button1Down(center, cam.CFrame)
                        task.wait(1.8) 
                        VirtualUser:Button1Up(center, cam.CFrame)
                        
                        -- Mengaktifkan tool secara paksa sebagai pelengkap
                        toolInHand:Activate()
                        
                        warn(">>> [AUTO FISH] Menunggu Umpan Muncul...")
                        
                        local success = false
                        local startTime = os.time()
                        
                        repeat
                            task.wait(0.2)
                            if fishingState == "MINIGAME" then
                                success = true
                                break
                            end
                            
                            for _, v in pairs(workspace:GetChildren()) do
                                if v.Name:lower():find("bobber") or v.Name:lower():find("bait") or v.Name:lower():find("hook") then
                                    if char.PrimaryPart and (v:GetPivot().Position - char.PrimaryPart.Position).Magnitude < 80 then
                                        success = true
                                        break
                                    end
                                end
                            end
                        until success or (os.time() - startTime) > 5
                        
                        if success then
                            warn(">>> [AUTO FISH] BERHASIL! Umpan di air.")
                        else
                            warn(">>> [AUTO FISH] Gagal terdeteksi, mencoba ulang...")
                            fishingState = "IDLE" 
                        end
                    end)
                end
            end
        end
    end
end)
