-- ==========================================================
-- INDO HANGOUT AUTO-FISH (KODE DIKUNCI - FIX AUTO CAST SAJA)
-- ==========================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser") -- Tambahan khusus untuk bypass klik layar
local player = Players.LocalPlayer

-- State Machine Global
local enabled = false
local fishingState = "IDLE" -- IDLE, WAITING, MINIGAME, COOLDOWN
local lastCastTime = 0
local lastMinigameTime = 0
local isSpacePressed = false

-- ==========================================
-- 1. GUI KONTROL INTERFACE (TETAP)
-- ==========================================
local gui = Instance.new("ScreenGui")
gui.Name = "AutoFish_Final_Fixed"
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
title.Text = "AUTO FISH v3"
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
-- 3. LOGIKA MINIGAME & ANTI LOMPAT (DIKUNCI)
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
            lastMinigameTime = os.time()
        elseif fishingState == "COOLDOWN" then
            if os.time() - lastMinigameTime >= 1 then
                fishingState = "IDLE"
            end
        end
    end
end)

-- ==========================================
-- 4. LOOP LEMPAR UMPAN (HANYA INI YANG DIUBAH)
-- ==========================================
task.spawn(function()
    while true do
        task.wait(0.3)
        
        if enabled then
            local char = player.Character
            local tool = char and char:FindFirstChildOfClass("Tool")
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")
            
            -- Kunci status lompat
            if humanoid and humanoid:GetStateEnabled(Enum.HumanoidStateType.Jumping) then
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
            end
            
            -- Otomatis pegang pancingan
            if not tool and player:FindFirstChild("Backpack") then
                local backpackTool = player.Backpack:FindFirstChildOfClass("Tool")
                if backpackTool then
                    backpackTool.Parent = char
                    task.wait(0.3)
                    tool = backpackTool
                end
            end
            
            if tool then
                -- JIKA STATUS IDLE (SIAP LEMPAR) ATAU ZONK 20 DETIK
                if fishingState == "IDLE" or (fishingState == "WAITING" and (os.time() - lastCastTime) >= 20) then
                    fishingState = "WAITING"
                    lastCastTime = os.time()
                    
                    pcall(function()
                        tool:Activate() -- Cara bawaan (sering diabaikan game)
                        
                        -- CARA MUTLAK: Memaksa simulasi klik mouse murni
                        if mouse1click then
                            mouse1click() -- Jika executor support klik asli
                        else
                            -- Jika tidak support, gunakan VirtualUser
                            VirtualUser:ClickButton1(Vector2.new(0,0))
                        end
                    end)
                    
                    -- Jeda sedikit agar tidak spam klik
                    task.wait(1)
                end
            end
        end
    end
end)
