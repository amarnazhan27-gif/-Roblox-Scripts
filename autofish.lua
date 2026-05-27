-- ==========================================================
-- INDO HANGOUT AUTO-FISH FINAL (ANDROID/DELTA - ALL FIXED)
-- ==========================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")
local player = Players.LocalPlayer

local enabled = false
local fishingState = "IDLE"
local lastCastTime = 0
local lastMinigameTime = 0
local isSpacePressed = false

-- ==========================================
-- LANGKAH 1: GUI TOMBOL ON/OFF
-- ==========================================
local gui = Instance.new("ScreenGui")
gui.Name = "AutoFish_Final"
gui.ResetOnSpawn = false
gui.Parent = game:GetService("CoreGui")

local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0, 200, 0, 100)
main.Position = UDim2.new(1, -210, 0, 150)
main.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
main.BorderSizePixel = 2
main.BorderColor3 = Color3.fromRGB(0, 255, 150)
main.Active = true
main.Draggable = true

local title = Instance.new("TextLabel", main)
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.Text = "AUTO FISH FINAL"
title.TextColor3 = Color3.fromRGB(0, 255, 150)
title.Font = Enum.Font.Code
title.TextScaled = true

local button = Instance.new("TextButton", main)
button.Size = UDim2.new(0.9, 0, 0, 45)
button.Position = UDim2.new(0.05, 0, 0.45, 0)
button.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
button.Text = "SYSTEM OFF"
button.Font = Enum.Font.GothamBold
button.TextScaled = true
button.TextColor3 = Color3.new(1, 1, 1)

button.MouseButton1Click:Connect(function()
    enabled = not enabled
    button.Text = enabled and "SYSTEM ON" or "SYSTEM OFF"
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
-- PELACAK BAR MINIGAME
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
-- FUNGSI CAST: TAHAN & LEPAS DI TENGAH LAYAR
-- FIX: VirtualUser + screenCenter (bukan Vector2.new(0,0))
-- ==========================================
local function castRod()
    local cam = workspace.CurrentCamera
    if not cam then return end

    local screenCenter = cam.ViewportSize / 2

    warn(">>> [AUTO FISH] Casting...")
    VirtualUser:Button1Down(screenCenter, cam.CFrame)
    task.wait(1.8)
    VirtualUser:Button1Up(screenCenter, cam.CFrame)
    warn(">>> [AUTO FISH] Umpan dilempar. Menunggu gigitan...")
end

-- ==========================================
-- LANGKAH 4 & 5: MINIGAME HANDLER
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
-- LANGKAH 2 & 3: EQUIP ROD & CAST
-- FIX: EquipTool() gantikan SendKeyEvent KeyCode.One
-- FIX: castRod() gantikan SendMouseButtonEvent & mouse1click()
-- ==========================================
task.spawn(function()
    while true do
        task.wait(0.5)

        if enabled then
            local char = player.Character
            if not char then continue end
            local humanoid = char:FindFirstChildOfClass("Humanoid")

            -- Anti Lompat
            if humanoid and humanoid:GetStateEnabled(Enum.HumanoidStateType.Jumping) then
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
            end

            local toolInHand = char:FindFirstChildWhichIsA("Tool")
            local rodInBackpack = player.Backpack:FindFirstChild("Fishing Rod")
                or player.Backpack:FindFirstChild("Rod")
                or player.Backpack:FindFirstChildWhichIsA("Tool")

            -- LANGKAH 2: Equip rod jika belum dipegang
            if not toolInHand and rodInBackpack and humanoid then
                warn(">>> [AUTO FISH] Mengambil Rod...")
                humanoid:EquipTool(rodInBackpack)
                task.wait(1)
                toolInHand = char:FindFirstChildWhichIsA("Tool")
            end

            -- LANGKAH 3: Lempar umpan
            if toolInHand then
                if fishingState == "IDLE" or (fishingState == "WAITING" and (os.time() - lastCastTime) >= 20) then
                    fishingState = "WAITING"
                    lastCastTime = os.time()
                    pcall(castRod)
                end
            end
        end
    end
end)
