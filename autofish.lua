-- ==========================================================
-- INDO HANGOUT AUTO-FISH (V6 - ULTIMATE TRACKER & AUTO-CAST)
-- ==========================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Variabel Status
local enabled = false
local fishingState = "IDLE"
local isSpacePressed = false
local lastCastTime = 0

-- ==========================================
-- 1. GUI KONTROL
-- ==========================================
local gui = Instance.new("ScreenGui")
gui.Name = "AutoFish_V6"
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
title.Text = "AUTO FISH V6"
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
    button.Text = enabled and "ON (FISHING...)" or "OFF"
    button.BackgroundColor3 = enabled and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
    
    if not enabled then
        fishingState = "IDLE"
        if isSpacePressed then
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
            isSpacePressed = false
        end
    end
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
-- 2. FUNGSI PELACAK GUI MINIGAME
-- ==========================================
local function getFishingElements()
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
-- 3. LOGIKA TRACKING (MINIGAME PLAYER)
-- ==========================================
RunService.Heartbeat:Connect(function()
    if not enabled then return end

    local success, err = pcall(function()
        local white, red = getFishingElements()

        -- Jika UI Minigame tidak ada di layar
        if not white or not red or not white.Visible then
            if isSpacePressed then
                if keyrelease then keyrelease(0x20) else VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game) end
                isSpacePressed = false
            end
            
            -- Set status kembali ke IDLE jika minigame selesai
            if fishingState == "REELING" then
                task.wait(1) -- Jeda setelah tangkapan sukses
                fishingState = "IDLE"
            end
            return
        end

        -- Jika UI Minigame Muncul, set status ke REELING
        fishingState = "REELING"
        lastCastTime = os.time() -- Reset timer failsafe saat main minigame

        local whiteCenter = white.AbsolutePosition.X + (white.AbsoluteSize.X / 2)
        local redCenter = red.AbsolutePosition.X + (red.AbsoluteSize.X / 2)
        local tolerance = white.AbsoluteSize.X * 0.1 

        if whiteCenter < (redCenter - tolerance) then
            if not isSpacePressed then
                if keypress then keypress(0x20) else VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game) end
                isSpacePressed = true
            end
        elseif whiteCenter > (redCenter + tolerance) then
            if isSpacePressed then
                if keyrelease then keyrelease(0x20) else VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game) end
                isSpacePressed = false
            end
        end
    end)
end)

-- ==========================================
-- 4. LOOP AUTO-CAST & FAILSAFE 20 DETIK
-- ==========================================
task.spawn(function()
    while true do
        task.wait(1)
        
        if enabled then
            local char = player.Character
            local tool = char and char:FindFirstChildOfClass("Tool")
            
            -- Jika sedang menganggur (tidak main minigame) dan pancingan dipegang
            if fishingState == "IDLE" and tool then
                fishingState = "WAITING"
                lastCastTime = os.time()
                
                -- Melempar umpan
                pcall(function()
                    tool:Activate()
                end)
                print("[Auto-Fish] Melempar umpan...")
            end
            
            -- Failsafe: Jika menunggu ikan lebih dari 20 detik, reset ke IDLE agar melempar ulang
            if fishingState == "WAITING" and (os.time() - lastCastTime) >= 20 then
                fishingState = "IDLE"
                print("[Auto-Fish] Ikan tidak makan selama 20 detik. Reset lemparan!")
            end
        end
    end
end)
