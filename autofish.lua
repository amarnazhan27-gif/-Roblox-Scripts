-- ==========================================================
-- INDO HANGOUT AUTO-FISH PRO (VERSION 2.0)
-- Based on Reverse Engineering Findings
-- ==========================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

-- State Management
local isEnabled = false
local fishingState = "IDLE" -- IDLE, CASTING, WAITING, MINIGAME
local lastCast = 0

-- UI Configuration (Premium Dark Theme)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "IndoHangoutPro"
screenGui.ResetOnSpawn = false
screenGui.Parent = game:GetService("CoreGui")

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 200, 0, 120)
mainFrame.Position = UDim2.new(0.85, 0, 0.1, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
mainFrame.BorderSizePixel = 0

local corner = Instance.new("UICorner", mainFrame)
corner.CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel", mainFrame)
title.Size = UDim2.new(1, 0, 0, 35)
title.Text = "AUTO FISH v2.0"
title.TextColor3 = Color3.fromRGB(110, 60, 255)
title.Font = Enum.Font.GothamBold
title.BackgroundTransparency = 1
title.TextSize = 14

local toggleBtn = Instance.new("TextButton", mainFrame)
toggleBtn.Size = UDim2.new(0, 160, 0, 40)
toggleBtn.Position = UDim2.new(0.1, 0, 0.45, 0)
toggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
toggleBtn.Text = "Status: OFF"
toggleBtn.TextColor3 = Color3.new(1, 1, 1)
toggleBtn.Font = Enum.Font.GothamMedium
toggleBtn.TextSize = 12

local btnCorner = Instance.new("UICorner", toggleBtn)

toggleBtn.MouseButton1Click:Connect(function()
    isEnabled = not isEnabled
    toggleBtn.Text = isEnabled and "Status: ON" or "Status: OFF"
    toggleBtn.BackgroundColor3 = isEnabled and Color3.fromRGB(60, 180, 110) or Color3.fromRGB(180, 60, 60)
    if isEnabled then
        fishingState = "IDLE"
    end
end)

-- ==========================================
-- CORE LOGIC: FISHING MECHANICS
-- ==========================================

-- Fungsi mencari Bobber/Umpan di air
local function getMyBobber()
    local char = player.Character
    if not char then return nil end
    for _, v in pairs(workspace:GetChildren()) do
        if (v.Name:lower():find("bobber") or v.Name:lower():find("bait") or v.Name:lower():find("hook")) then
            if (v:GetPivot().Position - char.PrimaryPart.Position).Magnitude < 100 then
                return v
            end
        end
    end
    return nil
end

-- Fungsi Minigame (Sama seperti v1 tapi lebih efisien)
local function handleMinigame()
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return end

    local whiteBar, redBar
    for _, v in pairs(playerGui:GetDescendants()) do
        if v.Name == "WhiteBar" and v.Visible then
            whiteBar = v
            redBar = v.Parent:FindFirstChild("RedBar")
            break
        end
    end

    if whiteBar and redBar then
        fishingState = "MINIGAME"
        local whitePos = whiteBar.AbsolutePosition.X + (whiteBar.AbsoluteSize.X / 2)
        local redPos = redBar.AbsolutePosition.X + (redBar.AbsoluteSize.X / 2)
        local tol = whiteBar.AbsoluteSize.X * 0.1

        if whitePos < (redPos - tol) then
            VirtualUser:Button1Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        else
            VirtualUser:Button1Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        end
    else
        if fishingState == "MINIGAME" then
            fishingState = "IDLE"
            VirtualUser:Button1Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            task.wait(1) -- Jeda setelah tangkap ikan
        end
    end
end

-- ==========================================
-- MAIN RUNTIME LOOP
-- ==========================================

RunService.Heartbeat:Connect(function()
    if not isEnabled then return end
    
    handleMinigame()
    
    if fishingState == "IDLE" then
        local char = player.Character
        if not char then return end
        
        local tool = char:FindFirstChildWhichIsA("Tool")
        local backpackRod = player.Backpack:FindFirstChild("Fishing Rod") or player.Backpack:FindFirstChild("Rod") or player.Backpack:FindFirstChildWhichIsA("Tool")
        
        -- Auto Equip
        if not tool and backpackRod then
            char.Humanoid:EquipTool(backpackRod)
            return
        end
        
        if tool and (os.time() - lastCast > 3) then
            fishingState = "CASTING"
            lastCast = os.time()
            
            task.spawn(function()
                warn(">>> CASTING BAIT...")
                -- Hold click to charge (Teknik VirtualUser jauh lebih stabil)
                VirtualUser:Button1Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                task.wait(1.8) -- Charge tenaga
                VirtualUser:Button1Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                
                -- Attempt Direct Remote firing (Reverse Engineered from common scripts)
                local eventName = "RodExecution" -- Ganti jika tau nama aslinya
                local remote = ReplicatedStorage:FindFirstChild(eventName, true) or ReplicatedStorage:FindFirstChild("Rod", true)
                if remote then
                    pcall(function()
                        remote:FireServer("Throw", 100, tool)
                    end)
                end
                
                fishingState = "WAITING"
                warn(">>> WAITING FOR FISH...")
            end)
        end
    end
end)

warn(">>> INDO HANGOUT PRO LOADED SUCCESSFULLY!")
