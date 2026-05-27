-- ==========================================================
-- INDO HANGOUT AUTO-FISH (ANDROID/DELTA - FIXED)
-- ==========================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local player = Players.LocalPlayer

-- State Machine Global
local enabled = false
local fishingState = "IDLE" -- IDLE, WAITING, MINIGAME, COOLDOWN
local lastCastTime = 0
local lastMinigameTime = 0
local isSpacePressed = false

-- ==========================================
-- LANGKAH 1: MENGAKTIFKAN TOMBOL ON/OFF 
-- ==========================================
local gui = Instance.new("ScreenGui")
gui.Name = "AutoFish_Sistematis"
gui.ResetOnSpawn = false
gui.Parent = game:GetService("CoreGui")

local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0, 180, 0, 90)
main.Position = UDim2.new(1, -190, 0, 50) -- Pindah ke pojok kanan atas agar tidak menghalangi
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
        -- Kembalikan fungsi lompat normal saat bot dimatikan
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
-- FUNGSI PELACAK INDIKATOR BAR (TIDAK DIRUBAH)
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
-- LANGKAH 4 & 5: MINIGAME & REPEAT (TIDAK DIRUBAH)
-- ==========================================
RunService.Heartbeat:Connect(function()
    if not enabled then return end

    local white, red = getFishingElements()

    if white and red and white.Visible then
        -- TAHAP MINIGAME SEDANG BERJALAN
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
        
        -- LANGKAH 6: REPEAT (KEMBALI KE TAHAP MELEMPAR UMPAN SETELAH MINIGAME SELESAI)
        if fishingState == "MINIGAME" then
            fishingState = "COOLDOWN"
            lastMinigameTime = os.time()
        elseif fishingState == "COOLDOWN" then
            if os.time() - lastMinigameTime >= 1 then
                fishingState = "IDLE" -- Status kembali menjadi IDLE (Siap mengulang Langkah 2 & 3)
            end
        end
    end
end)

-- ==========================================
-- LANGKAH 2 & 3: MEMEGANG ROD & MELEMPAR UMPAN
-- [FIX ANDROID] Ganti SendKeyEvent + SendMouseButtonEvent
-- dengan EquipTool() + Tool:Activate()
-- karena Android tidak punya keyboard fisik & pakai touch event
-- ==========================================
task.spawn(function()
    while true do
        task.wait(0.5) -- Sedikit lebih lambat agar tidak lagg/crash
        
        if enabled then
            local char = player.Character
            if not char then continue end
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            
            -- Anti Lompat dikunci
            if humanoid and humanoid:GetStateEnabled(Enum.HumanoidStateType.Jumping) then
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
            end
            
            -- Cek apakah Rod sudah dipegang atau ada di Backpack
            local toolInHand = char:FindFirstChildWhichIsA("Tool")
            local rodInBackpack = player.Backpack:FindFirstChild("Fishing Rod") or player.Backpack:FindFirstChild("Rod") or player.Backpack:FindFirstChildWhichIsA("Tool")

            -- Jika tidak pegang apa-apa, ambil dari backpack
            if not toolInHand and rodInBackpack and humanoid then
                humanoid:EquipTool(rodInBackpack)
                task.wait(1) -- Beri waktu lebih agar rod benar-benar aktif
                toolInHand = char:FindFirstChildWhichIsA("Tool")
            end

            -- Jika Statusnya "Siap Lempar" ATAU "Sudah 20 Detik Menunggu" (mungkin nyangkut)
            if fishingState == "IDLE" or (fishingState == "WAITING" and (os.time() - lastCastTime) >= 20) then
                if toolInHand then
                    fishingState = "WAITING"
                    lastCastTime = os.time()
                    
                    pcall(function()
                        warn(">>> [AUTO FISH] MENEMBAK SINYAL AKTIVASI (ULTIMATE FIX)...")
                        
                        -- 1. Paksa script lokal pancingan untuk bekerja (Bypass Manual Click)
                        if firesignal then
                            firesignal(toolInHand.Activated)
                        end
                        
                        -- 2. Backup Remote & Activate
                        local rodRemote = game:GetService("ReplicatedStorage"):FindFirstChild("Rod", true) 
                        if rodRemote then
                            rodRemote:FireServer("Equipped", nil, toolInHand)
                            task.wait(0.2)
                            rodRemote:FireServer("Throw", nil, toolInHand)
                        end
                        toolInHand:Activate()

                        -- 3. Terakhir Klik Fisik
                        local x = workspace.CurrentCamera.ViewportSize.X / 2
                        local y = workspace.CurrentCamera.ViewportSize.Y * 0.35 
                        if mouse1click then
                            mouse1click()
                        elseif mouse1press then
                            mouse1press()
                            task.wait(0.1)
                            mouse1release()
                        else
                            VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
                            task.wait(0.1)
                            VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
                        end
                        warn(">>> [AUTO FISH] Semua metode lempar telah dicoba!")
                    end)
                end
            elseif fishingState == "WAITING" and (os.time() - lastCastTime) >= 5 then
                -- RECOVERY CEPAT: Jika 5 detik umpan tidak muncul, langsung IDLE lagi
                -- agar bisa mencoba melempar ulang tanpa nunggu lama.
                fishingState = "IDLE"
            end
        end
    end
end)
