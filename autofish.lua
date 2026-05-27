-- ==========================================================
-- INDO HANGOUT AUTO-FISH (SUPREME NEON UI - ZERO JUMP GUARANTEED)
-- ==========================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

local enabled = false
local isSpacePressed = false

local lastWhiteX = 0
local lastUpdateTime = 0

-- ==========================================
-- 1. PREMIUM CYBERPUNK GUI INTERFACE
-- ==========================================
local gui = Instance.new("ScreenGui")
gui.Name = "AutoFish_SupremeUI"
gui.ResetOnSpawn = false
gui.Parent = game:GetService("CoreGui")

local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0, 220, 0, 120)
main.Position = UDim2.new(1, -240, 0, 60) 
main.BackgroundColor3 = Color3.fromRGB(15, 16, 22) 
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true 

local mainCorner = Instance.new("UICorner", main)
mainCorner.CornerRadius = UDim.new(0, 12)

local mainStroke = Instance.new("UIStroke", main)
mainStroke.Thickness = 2
mainStroke.Color = Color3.fromRGB(0, 230, 255) 
mainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local glowBar = Instance.new("Frame", main)
glowBar.Size = UDim2.new(1, 0, 0, 4)
glowBar.Position = UDim2.new(0, 0, 0, 0)
glowBar.BackgroundColor3 = Color3.fromRGB(0, 230, 255)
glowBar.BorderSizePixel = 0

local barCorner = Instance.new("UICorner", glowBar)
barCorner.CornerRadius = UDim.new(0, 12)

local title = Instance.new("TextLabel", main)
title.Size = UDim2.new(1, 0, 0, 35)
title.Position = UDim2.new(0, 0, 0, 8)
title.BackgroundTransparency = 1
title.Text = "⚡ CYBER RADAR V1.3"
title.TextColor3 = Color3.fromRGB(240, 240, 245)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Center

local statusLabel = Instance.new("TextLabel", main)
statusLabel.Size = UDim2.new(1, 0, 0, 20)
statusLabel.Position = UDim2.new(0, 0, 0, 38)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "STATUS: STANDBY"
statusLabel.TextColor3 = Color3.fromRGB(150, 155, 170)
statusLabel.Font = Enum.Font.GothamSemibold
statusLabel.TextSize = 10

local button = Instance.new("TextButton", main)
button.Size = UDim2.new(0.85, 0, 0, 40)
button.Position = UDim2.new(0.075, 0, 0.55, 0)
button.BackgroundColor3 = Color3.fromRGB(240, 45, 80) 
button.Text = "ACTIVATE SYSTEM"
button.Font = Enum.Font.GothamBold
button.TextSize = 12
button.TextColor3 = Color3.new(1, 1, 1)
button.AutoButtonColor = false

local btnCorner = Instance.new("UICorner", button)
btnCorner.CornerRadius = UDim.new(0, 8)

local btnStroke = Instance.new("UIStroke", button)
btnStroke.Thickness = 1.5
btnStroke.Color = Color3.fromRGB(255, 255, 255)
btnStroke.Transparency = 0.8

local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local tweenOn = TweenService:Create(button, tweenInfo, {BackgroundColor3 = Color3.fromRGB(0, 200, 115)}) 
local tweenOff = TweenService:Create(button, tweenInfo, {BackgroundColor3 = Color3.fromRGB(240, 45, 80)})
local strokeOn = TweenService:Create(mainStroke, tweenInfo, {Color = Color3.fromRGB(0, 255, 150)}) 
local strokeOff = TweenService:Create(mainStroke, tweenInfo, {Color = Color3.fromRGB(0, 230, 255)})

-- ==========================================
-- SANA SINI AMAN: PENGUNCI JUMP TOTAL PASCA-GAME
-- ==========================================
local function forceStopJump()
    isSpacePressed = false
    -- Kirim sinyal lepas spasi berlapis untuk memastikan tidak tersangkut di sistem
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
    
    pcall(function()
        local character = player.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                -- Matikan fungsi lompat sepenuhnya
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
                humanoid.JumpPower = 0
                
                -- Berikan jeda aman agar input lag dari Auto Clicker luar selesai diproses game
                task.wait(0.3) 
                
                -- Kembalikan fungsi lompat ke normal untuk pergerakan manual
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
                humanoid.JumpPower = 50
            end
        end
    end)
end

button.MouseButton1Click:Connect(function()
    enabled = not enabled
    if enabled then
        tweenOn:Play()
        strokeOn:Play()
        button.Text = "SYSTEM ACTIVE"
        statusLabel.Text = "STATUS: SCANNING BAR..."
        statusLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
    else
        tweenOff:Play()
        strokeOff:Play()
        button.Text = "ACTIVATE SYSTEM"
        statusLabel.Text = "STATUS: STANDBY"
        statusLabel.TextColor3 = Color3.fromRGB(150, 155, 170)
        forceStopJump()
    end
end)

-- ==========================================
-- 2. PELACAK GUI TINGKAT TINGGI
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
-- 3. LOGIKA PREDIKSI & EKSEKUSI INSTAN
-- ==========================================
RunService.Heartbeat:Connect(function()
    if not enabled then return end

    local white, red = getFishingElements()

    if white and red and white.Visible then
        statusLabel.Text = "STATUS: WINNING MINIGAME 🔥"
        statusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
        
        local currentTime = tick()
        local deltaTime = currentTime - lastUpdateTime
        
        local whiteCenter = white.AbsolutePosition.X + (white.AbsoluteSize.X / 2)
        local redCenter = red.AbsolutePosition.X + (red.AbsoluteSize.X / 2)
        
        local velocity = 0
        if deltaTime > 0 and lastWhiteX ~= 0 then
            velocity = (whiteCenter - lastWhiteX) / deltaTime
        end
        
        lastWhiteX = whiteCenter
        lastUpdateTime = currentTime

        local predictedWhiteCenter = whiteCenter + (velocity * 0.05)
        
        local halfRedSize = red.AbsoluteSize.X / 2
        local leftBound = redCenter - halfRedSize
        local rightBound = redCenter + halfRedSize

        if predictedWhiteCenter >= leftBound and predictedWhiteCenter <= rightBound then
            if not isSpacePressed then
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                isSpacePressed = true
            end
        else
            if isSpacePressed then
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                isSpacePressed = false
            end
        end
    else
        lastWhiteX = 0
        if enabled then
            statusLabel.Text = "STATUS: SCANNING BAR..."
            statusLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
        end
        if isSpacePressed then
            -- Langsung kunci kaki begitu minigame selesai/hilang dari layar
            forceStopJump()
        end
    end
end)
