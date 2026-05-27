-- ==========================================================
-- INDO HANGOUT AUTO-FISH (MINIGAME TERKUNCI - JALUR BELAKANG)
-- ==========================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local player = Players.LocalPlayer

-- State Machine Global (Menggunakan os.clock untuk akurasi tinggi)
local enabled = false
local fishingState = "IDLE" 
local lastCastTime = os.clock()
local lastStateChange = os.clock()
local isSpacePressed = false

-- ==========================================
-- 1. GUI KONTROL INTERFACE (DIKUNCI)
-- ==========================================
local gui = Instance.new("ScreenGui")
gui.Name = "AutoFish_Murni"
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
        if isSpacePressed then
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
            isSpacePressed = false
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
-- 2. FUNGSI PELACAK INDIKATOR BAR (DIKUNCI)
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
-- 3. MINIGAME LOGIC (DIKUNCI - TERBUKTI BERHASIL)
-- ==========================================
RunService.Heartbeat:Connect(function()
    if not enabled then return end

    local white, red = getFishingElements()

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
        
    else
        if isSpacePressed then
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
            isSpacePressed = false
        end
        
        if fishingState == "MINIGAME" then
            fishingState = "COOLDOWN"
            lastStateChange = os.clock()
        elseif fishingState == "COOLDOWN" then
            if (os.clock() - lastStateChange) >= 1.5 then
                fishingState = "IDLE"
            end
        end
    end
end)

-- ==========================================
-- 4. AUTO CAST (SERANGAN JALUR BELAKANG & NATIVE API)
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
            local rodInBackpack = player.Backpack:FindFirstChildWhichIsA("Tool")

            if not toolInHand and rodInBackpack and humanoid then
                humanoid:EquipTool(rodInBackpack)
                task.wait(1) 
                toolInHand = char:FindFirstChildWhichIsA("Tool")
            end

            if fishingState == "IDLE" or (fishingState == "WAITING" and (os.clock() - lastCastTime) >= 20) then
                if toolInHand then
                    fishingState = "WAITING"
                    lastCastTime = os.clock()
                    
                    pcall(function()
                        warn(">>> [AUTO FISH] Mengeksekusi Lemparan Jalur Belakang...")
                        
                        -- METODE 1: Eksekusi Kasar (Native Delta API)
                        -- Mengeksploitasi fungsi bawaan executor yang tidak bisa diblokir game
                        if mouse1click then mouse1click() end
                        if mouse1press and mouse1release then
                            mouse1press()
                            task.wait(0.5)
                            mouse1release()
                        end
                        if tap then 
                            local cam = workspace.CurrentCamera
                            tap(Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2))
                        end
                        
                        -- METODE 2: Serangan RemoteEvent (Membajak Server)
                        -- Mencari semua file pengirim data di dalam pancingan dan memaksanya menyala
                        for _, objek in pairs(toolInHand:GetDescendants()) do
                            if objek:IsA("RemoteEvent") then
                                objek:FireServer()
                                objek:FireServer("Click")
                                objek:FireServer("Cast")
                                objek:FireServer("Throw")
                                -- Jika game butuh koordinat mouse, kita lempar koordinat karakter
                                objek:FireServer(char.PrimaryPart.Position + char.PrimaryPart.CFrame.LookVector * 15)
                            end
                        end
                        
                        -- METODE 3: Paksa Activate
                        toolInHand:Activate()
                        
                        warn(">>> [AUTO FISH] Menunggu Umpan Muncul...")
                        
                        -- Deteksi Umpan (Failsafe 5 detik)
                        local success = false
                        local startTime = os.clock()
                        
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
                        until success or (os.clock() - startTime) > 5
                        
                        if not success then
                            warn(">>> [AUTO FISH] Gagal terdeteksi, mencoba ulang...")
                            fishingState = "IDLE" 
                        end
                    end)
                end
            end
        end
    end
end)
