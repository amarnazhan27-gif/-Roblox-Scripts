--// INDO HANGOUT AUTO FISHING PERFECT COMPLETION (MACBOOK BLUESTACKS)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local lastCastTime = 0
local isSpacePressed = false

-- ==========================================
-- KONTROL JUMP STATE (ANTI-MELOMPAT)
-- ==========================================
local function setJumpState(canJump)
    pcall(function()
        local char = player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, canJump)
            end
        end
    end)
end

-- Otomatis mematikan lompat sejak skrip dieksekusi
setJumpState(false)

-- ==========================================
-- FUNGSI DETEKSI ELEMEN MINIGAME & TOOL
-- ==========================================
local function getFishingElements()
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return nil, nil end

    for _, v in pairs(playerGui:GetDescendants()) do
        if v.Name == "WhiteBar" and v:IsA("GuiObject") then
            local parent = v.Parent
            local red = parent:FindFirstChild("RedBar")
            if red and red:IsA("GuiObject") then
                return v, red
            end
        end
    end
    return nil, nil
end

local function getFishingRod()
    local char = player.Character
    if char then
        local tool = char:FindFirstChildOfClass("Tool")
        if tool and string.find(string.lower(tool.Name), "rod") then
            return tool
        end
    end
    
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        for _, item in pairs(backpack:GetChildren()) do
            if item:IsA("Tool") and string.find(string.lower(item.Name), "rod") then
                return item
            end
        end
    end
    return nil
end

-- ==========================================
-- LOGIKA UTAMA MINIGAME TRACKING (HEARTBEAT)
-- ==========================================
RunService.Heartbeat:Connect(function()
    setJumpState(false) -- Mengunci karakter agar tidak melompat

    pcall(function()
        local white, red = getFishingElements()

        if not white or not red or not white.Visible then
            if isSpacePressed and keyrelease then
                keyrelease(0x20)
                isSpacePressed = false
            end
            return
        end

        local whiteCenter = white.AbsolutePosition.X + (white.AbsoluteSize.X / 2)
        local redCenter = red.AbsolutePosition.X + (red.AbsoluteSize.X / 2)
        local tolerance = white.AbsoluteSize.X * 0.1

        if whiteCenter < (redCenter - tolerance) then
            if not isSpacePressed and keypress then
                keypress(0x20)
                isSpacePressed = true
            end
        elseif whiteCenter > (redCenter + tolerance) then
            if isSpacePressed and keyrelease then
                keyrelease(0x20)
                isSpacePressed = false
            end
        end
    end)
end)

-- ==========================================
-- SIKLUS OTOMATIS: AUTO EQUIP & AUTO CAST LOOP
-- ==========================================
task.spawn(function()
    while task.wait(0.5) do
        local white, red = getFishingElements()
        local isMinigameActive = (white and red and white.Visible)

        if isMinigameActive then
            lastCastTime = tick()
        else
            if tick() - lastCastTime > 2.5 then
                pcall(function()
                    local rod = getFishingRod()
                    if rod then
                        local char = player.Character
                        
                        -- TAHAP 1: AUTO EQUIP
                        if char and rod.Parent ~= char then
                            local hum = char:FindFirstChildOfClass("Humanoid")
                            if hum then
                                hum:EquipTool(rod)
                                task.wait(0.5)
                            end
                        end
                        
                        -- TAHAP 2: AUTO CAST
                        if rod.Parent == char then
                            rod:Activate() 
                            if keypress and keyrelease then
                                keypress(0x20)
                                task.wait(0.1)
                                keyrelease(0x20)
                            end
                            lastCastTime = tick()
                        end
                    end
                end)
            end
        end
    end
end)
