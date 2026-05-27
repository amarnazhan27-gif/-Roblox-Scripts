
--// INDO HANGOUT AUTO FISH (SUPER LIGHTWEIGHT VERSION)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local lastCastTime = 0
local isSpacePressed = false

-- ==========================================
-- GUI SUPER SEDERHANA & ENTENG (HANYA TOMBOL)
-- ==========================================
local gui = Instance.new("ScreenGui")
gui.Name = "AutoFish_Simple"
gui.Parent = game:GetService("CoreGui")

local button = Instance.new("TextButton", gui)
button.Size = UDim2.new(0, 120, 0, 50)
button.Position = UDim2.new(0.5, -60, 0.85, 0) -- Posisi di tengah bawah layar
button.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
button.Text = "OFF"
button.TextScaled = true
button.TextColor3 = Color3.new(1, 1, 1)

local enabled = false

local function setJumpState(canJump)
    pcall(function()
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, canJump) end
    end)
end

button.MouseButton1Click:Connect(function()
    enabled = not enabled
    button.Text = enabled and "ON" or "OFF"
    button.BackgroundColor3 = enabled and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
    setJumpState(not enabled)
    if not enabled and isSpacePressed and keyrelease then
        keyrelease(0x20)
        isSpacePressed = false
    end
end)

-- ==========================================
-- CORE FUNCTION (LOGIKA PANCING & TRACKING)
-- ==========================================
local function getFishingElements()
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return nil, nil end
    for _, v in pairs(playerGui:GetDescendants()) do
        if v.Name == "WhiteBar" and v:IsA("GuiObject") then
            local red = v.Parent:FindFirstChild("RedBar")
            if red and red:IsA("GuiObject") then return v, red end
        end
    end
    return nil, nil
end

local function getFishingRod()
    local char = player.Character
    local tool = char and char:FindFirstChildOfClass("Tool")
    if tool and string.find(string.lower(tool.Name), "rod") then return tool end
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        for _, item in pairs(backpack:GetChildren()) do
            if item:IsA("Tool") and string.find(string.lower(item.Name), "rod") then return item end
        end
    end
    return nil
end

RunService.Heartbeat:Connect(function()
    if not enabled then return end
    setJumpState(false)
    pcall(function()
        local white, red = getFishingElements()
        if not white or not red or not white.Visible then
            if isSpacePressed and keyrelease then keyrelease(0x20) isSpacePressed = false end
            return
        end
        local whiteCenter = white.AbsolutePosition.X + (white.AbsoluteSize.X / 2)
        local redCenter = red.AbsolutePosition.X + (red.AbsoluteSize.X / 2)
        local tolerance = white.AbsoluteSize.X * 0.1
        if whiteCenter < (redCenter - tolerance) then
            if not isSpacePressed and keypress then keypress(0x20) isSpacePressed = true end
        elseif whiteCenter > (redCenter + tolerance) then
            if isSpacePressed and keyrelease then keyrelease(0x20) isSpacePressed = false end
        end
    end)
end)

task.spawn(function()
    while task.wait(0.5) do
        if enabled then
            local white, red = getFishingElements()
            if (white and red and white.Visible) then lastCastTime = tick() else
                if tick() - lastCastTime > 2.5 then
                    pcall(function()
                        local rod = getFishingRod()
                        if rod then
                            if rod.Parent ~= player.Character then player.Character.Humanoid:EquipTool(rod) task.wait(0.4) end
                            rod:Activate()
                            if keypress and keyrelease then keypress(0x20) task.wait(0.1) keyrelease(0x20) end
                            lastCastTime = tick()
                        end
                    end)
                end
            end
        end
    end
end)
