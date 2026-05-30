-- ==========================================================
-- INDO HANGOUT ALL-IN-ONE: AUTO FISH + AUTO MINE CRYSTAL
-- ANDROID/DELTA COMPATIBLE - FINAL VERSION
-- ==========================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")
local PathfindingService = game:GetService("PathfindingService")
local player = Players.LocalPlayer

-- ==========================================
-- STATE & CONFIG
-- ==========================================
local mode = "OFF"       -- OFF, FISH, MINE
local isSpacePressed = false
local fishingState = "IDLE"
local lastCastTime = 0
local lastMinigameTime = 0
local nextCastTime = 0
local lastMinigameGuiSeen = 0
local isCasting = false
local minigameJustStarted = false
local miningActive = false
local lastSpaceToggle = 0
local lastWhiteCenter = nil
local lastWhiteSample = os.clock()
local whiteVelocity = 0

-- Nama tool yang akan dicari (auto-detect fallback)
local FISH_TOOL_NAMES = {"Fishing Rod", "Rod", "Pancing", "FishingRod"}
local MINE_TOOL_NAMES = {"Pickaxe", "Cangkul", "Kapak", "Mining", "Pick", "Hammer"}

-- Nama/properti crystal di workspace
local CRYSTAL_NAMES = {"8sisi", "Crystal", "Kristal", "Gem", "Ore", "Batu"}
local CRYSTAL_MATERIAL = Enum.Material.Neon -- Material 272 = Neon (sesuai file map)
local MINE_STOP_DISTANCE = 3.2
local MINE_MAX_SCAN_DISTANCE = 260
local PATH_RETRY_DELAY = 0.35
local FISH_RECAST_DELAY = 1.15
local FISH_WAIT_TIMEOUT = 24
local MINE_SMOOTH_MOVE = true
local MINE_WALK_SPEED = 15

-- ==========================================
-- GUI UTAMA
-- ==========================================
local gui = Instance.new("ScreenGui")
gui.Name = "AllInOne_IH"
gui.ResetOnSpawn = false
gui.Parent = game:GetService("CoreGui")

local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0, 260, 0, 278)
main.Position = UDim2.new(1, -275, 0, 95)
main.BackgroundColor3 = Color3.fromRGB(18, 22, 28)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true

local mainCorner = Instance.new("UICorner", main)
mainCorner.CornerRadius = UDim.new(0, 10)

local mainStroke = Instance.new("UIStroke", main)
mainStroke.Color = Color3.fromRGB(73, 166, 194)
mainStroke.Thickness = 1.5
mainStroke.Transparency = 0.1

-- Title
local title = Instance.new("TextLabel", main)
title.Size = UDim2.new(1, -20, 0, 30)
title.Position = UDim2.new(0, 10, 0, 8)
title.BackgroundTransparency = 1
title.Text = "INDO HANGOUT"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextScaled = true

-- Status label
local statusLabel = Instance.new("TextLabel", main)
statusLabel.Size = UDim2.new(1, -20, 0, 28)
statusLabel.Position = UDim2.new(0, 10, 0, 43)
statusLabel.BackgroundColor3 = Color3.fromRGB(28, 34, 43)
statusLabel.Text = "Status: OFF"
statusLabel.TextColor3 = Color3.fromRGB(215, 235, 240)
statusLabel.Font = Enum.Font.Code
statusLabel.TextScaled = true
local statusCorner = Instance.new("UICorner", statusLabel)
statusCorner.CornerRadius = UDim.new(0, 6)

-- Tombol FISH
local btnFish = Instance.new("TextButton", main)
btnFish.Size = UDim2.new(0.92, 0, 0, 38)
btnFish.Position = UDim2.new(0.04, 0, 0, 80)
btnFish.BackgroundColor3 = Color3.fromRGB(41, 104, 170)
btnFish.Text = "🎣 AUTO FISH: OFF"
btnFish.Font = Enum.Font.GothamBold
btnFish.TextScaled = true
btnFish.TextColor3 = Color3.new(1, 1, 1)
local btnFishCorner = Instance.new("UICorner", btnFish)
btnFishCorner.CornerRadius = UDim.new(0, 8)

-- Tombol MINE
local btnMine = Instance.new("TextButton", main)
btnMine.Size = UDim2.new(0.92, 0, 0, 38)
btnMine.Position = UDim2.new(0.04, 0, 0, 124)
btnMine.BackgroundColor3 = Color3.fromRGB(167, 101, 38)
btnMine.Text = "⛏️ AUTO MINE: OFF"
btnMine.Font = Enum.Font.GothamBold
btnMine.TextScaled = true
btnMine.TextColor3 = Color3.new(1, 1, 1)
local btnMineCorner = Instance.new("UICorner", btnMine)
btnMineCorner.CornerRadius = UDim.new(0, 8)

local settingsTitle = Instance.new("TextLabel", main)
settingsTitle.Size = UDim2.new(1, -20, 0, 22)
settingsTitle.Position = UDim2.new(0, 10, 0, 170)
settingsTitle.BackgroundTransparency = 1
settingsTitle.Text = "SETTINGS"
settingsTitle.TextColor3 = Color3.fromRGB(130, 180, 195)
settingsTitle.Font = Enum.Font.GothamBold
settingsTitle.TextScaled = true

local btnSmooth = Instance.new("TextButton", main)
btnSmooth.Size = UDim2.new(0.44, 0, 0, 32)
btnSmooth.Position = UDim2.new(0.04, 0, 0, 198)
btnSmooth.BackgroundColor3 = Color3.fromRGB(35, 132, 92)
btnSmooth.Text = "Smooth Mine: ON"
btnSmooth.Font = Enum.Font.GothamSemibold
btnSmooth.TextScaled = true
btnSmooth.TextColor3 = Color3.new(1, 1, 1)
local btnSmoothCorner = Instance.new("UICorner", btnSmooth)
btnSmoothCorner.CornerRadius = UDim.new(0, 7)

local btnFishWait = Instance.new("TextButton", main)
btnFishWait.Size = UDim2.new(0.44, 0, 0, 32)
btnFishWait.Position = UDim2.new(0.52, 0, 0, 198)
btnFishWait.BackgroundColor3 = Color3.fromRGB(58, 76, 112)
btnFishWait.Text = "Wait: 24s"
btnFishWait.Font = Enum.Font.GothamSemibold
btnFishWait.TextScaled = true
btnFishWait.TextColor3 = Color3.new(1, 1, 1)
local btnFishWaitCorner = Instance.new("UICorner", btnFishWait)
btnFishWaitCorner.CornerRadius = UDim.new(0, 7)

local btnSpeed = Instance.new("TextButton", main)
btnSpeed.Size = UDim2.new(0.44, 0, 0, 32)
btnSpeed.Position = UDim2.new(0.04, 0, 0, 236)
btnSpeed.BackgroundColor3 = Color3.fromRGB(69, 86, 59)
btnSpeed.Text = "Speed: 15"
btnSpeed.Font = Enum.Font.GothamSemibold
btnSpeed.TextScaled = true
btnSpeed.TextColor3 = Color3.new(1, 1, 1)
local btnSpeedCorner = Instance.new("UICorner", btnSpeed)
btnSpeedCorner.CornerRadius = UDim.new(0, 7)

local btnRecast = Instance.new("TextButton", main)
btnRecast.Size = UDim2.new(0.44, 0, 0, 32)
btnRecast.Position = UDim2.new(0.52, 0, 0, 236)
btnRecast.BackgroundColor3 = Color3.fromRGB(90, 66, 112)
btnRecast.Text = "Recast: 1.2s"
btnRecast.Font = Enum.Font.GothamSemibold
btnRecast.TextScaled = true
btnRecast.TextColor3 = Color3.new(1, 1, 1)
local btnRecastCorner = Instance.new("UICorner", btnRecast)
btnRecastCorner.CornerRadius = UDim.new(0, 7)

-- ==========================================
-- HELPER: CARI TOOL DI BACKPACK/CHAR
-- ==========================================
local function findTool(nameList)
    local char = player.Character
    local bp = player.Backpack
    for _, name in ipairs(nameList) do
        -- Cek di tangan dulu
        if char then
            local t = char:FindFirstChild(name)
            if t and t:IsA("Tool") then return t, "hand" end
        end
        -- Cek backpack
        local t = bp:FindFirstChild(name)
        if t then return t, "backpack" end
    end
    -- Fallback: ambil tool apapun
    if char then
        local t = char:FindFirstChildWhichIsA("Tool")
        if t then return t, "hand" end
    end
    local t = bp:FindFirstChildWhichIsA("Tool")
    if t then return t, "backpack" end
    return nil, nil
end

-- ==========================================
-- HELPER: EQUIPT TOOL
-- ==========================================
local function equipTool(nameList)
    local char = player.Character
    if not char then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return nil end

    -- Sudah di tangan?
    local toolInHand = char:FindFirstChildWhichIsA("Tool")

    -- Cek apakah tool di tangan sudah sesuai
    for _, name in ipairs(nameList) do
        if toolInHand and toolInHand.Name:lower():find(name:lower()) then
            return toolInHand
        end
    end

    -- Cari di backpack
    local tool, loc = findTool(nameList)
    if tool and loc == "backpack" then
        hum:EquipTool(tool)
        task.wait(0.8)
        return char:FindFirstChildWhichIsA("Tool")
    end
    return toolInHand
end

-- ==========================================
-- FISHING: CAST ROD
-- ==========================================
local function castRod()
    if isCasting then return end
    isCasting = true
    pcall(function()
        local cam = workspace.CurrentCamera
        if not cam then return end
        local screenCenter = cam.ViewportSize / 2
        fishingState = "CASTING"
        statusLabel.Text = "Fish: Melempar umpan..."
        warn("[FISH] Melempar umpan...")
        local tool = player.Character and player.Character:FindFirstChildWhichIsA("Tool")
        if tool then
            pcall(function() tool:Activate() end)
        end
        VirtualUser:Button1Down(screenCenter, cam.CFrame)
        task.wait(1.65)
        VirtualUser:Button1Up(screenCenter, cam.CFrame)
        if tool then
            pcall(function() tool:Deactivate() end)
        end
        lastCastTime = os.clock()
        if mode == "FISH" and fishingState == "CASTING" then
            fishingState = "WAITING"
            statusLabel.Text = "Fish: Menunggu gigitan..."
        end
        warn("[FISH] Umpan dilempar, menunggu gigitan...")
    end)
    task.wait(0.35)
    isCasting = false
end

-- ==========================================
-- FISHING: PELACAK BAR MINIGAME
-- ==========================================
local function getFishingElements()
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return nil, nil end
    for _, v in pairs(playerGui:GetDescendants()) do
        local lowerName = v.Name:lower()
        if (lowerName == "whitebar" or lowerName:find("white")) and v:IsA("GuiObject") then
            local parent = v.Parent
            local red = parent and (parent:FindFirstChild("RedBar") or parent:FindFirstChild("redbar"))
            if not red and parent then
                for _, sibling in ipairs(parent:GetChildren()) do
                    if sibling:IsA("GuiObject") and sibling.Name:lower():find("red") then
                        red = sibling
                        break
                    end
                end
            end
            if red and red:IsA("GuiObject") then
                return v, red
            end
        end
    end
    return nil, nil
end

local function setSpacePressed(pressed, force)
    if isSpacePressed == pressed then return end
    local now = os.clock()
    if not force and now - lastSpaceToggle < 0.035 then return end
    VirtualInputManager:SendKeyEvent(pressed, Enum.KeyCode.Space, false, game)
    isSpacePressed = pressed
    lastSpaceToggle = now
end

-- ==========================================
-- MINING: CARI CRYSTAL TERDEKAT
-- ==========================================
local function isLikelyCrystal(obj)
    if not (obj:IsA("BasePart") or obj:IsA("MeshPart")) then return false, 0 end

    local lowerName = obj.Name:lower()
    local score = 0
    for _, cname in ipairs(CRYSTAL_NAMES) do
        if lowerName:find(cname:lower()) then
            score = score + 4
            break
        end
    end
    if obj.Material == CRYSTAL_MATERIAL then score = score + 3 end
    if obj:IsA("MeshPart") then score = score + 1 end
    if obj.Transparency < 0.85 then score = score + 1 end
    if obj.CanCollide or obj.CanQuery then score = score + 1 end

    local parent = obj.Parent
    while parent and parent ~= workspace do
        local pname = parent.Name:lower()
        if pname:find("crystal") or pname:find("ore") or pname:find("mine") or pname:find("batu") then
            score = score + 3
            break
        end
        parent = parent.Parent
    end

    return score >= 4, score
end

local function findNearestCrystal()
    local char = player.Character
    if not char or not char.PrimaryPart then return nil end
    local myPos = char.PrimaryPart.Position
    local nearest = nil
    local nearestValue = math.huge
    local nearestDist = math.huge

    for _, obj in pairs(workspace:GetDescendants()) do
        local ok, score = isLikelyCrystal(obj)
        if ok then
            local dist = (obj.Position - myPos).Magnitude
            if dist < MINE_MAX_SCAN_DISTANCE then
                local value = dist - (score * 10)
                if value < nearestValue then
                    nearest = obj
                    nearestDist = dist
                    nearestValue = value
                end
            end
        end
    end
    return nearest, nearestDist
end

local function raycastGround(pos, ignoreList)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = ignoreList or {}
    params.IgnoreWater = false
    return workspace:Raycast(pos + Vector3.new(0, 18, 0), Vector3.new(0, -70, 0), params)
end

local function hasClearLine(fromPos, toPos, ignoreList)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = ignoreList or {}
    local direction = toPos - fromPos
    local hit = workspace:Raycast(fromPos, direction, params)
    return not hit or hit.Instance == nil
end

local function getMiningStandPoint(crystal)
    local char = player.Character
    if not char or not char.PrimaryPart then return nil end

    local origin = crystal.Position
    local crystalWidth = math.max(crystal.Size.X, crystal.Size.Z)
    local radius = math.clamp((crystalWidth * 0.32) + 2.15, MINE_STOP_DISTANCE, 4.6)
    local ignore = {char, crystal}
    local bestPos = nil
    local bestScore = math.huge

    for i = 1, 16 do
        local angle = (math.pi * 2) * (i / 16)
        local offset = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
        local sample = origin + offset
        local ground = raycastGround(sample, ignore)
        if ground and ground.Instance and ground.Normal.Y > 0.55 then
            local pos = ground.Position + Vector3.new(0, 3, 0)
            local heightDelta = math.abs(pos.Y - char.PrimaryPart.Position.Y)
            local crystalHeightDelta = pos.Y - origin.Y
            if heightDelta < 10 and crystalHeightDelta < 4.5 then
                local clearance = hasClearLine(pos + Vector3.new(0, 2, 0), origin, ignore)
                local distToCrystal = (Vector3.new(pos.X, origin.Y, pos.Z) - origin).Magnitude
                local score = (pos - char.PrimaryPart.Position).Magnitude + math.abs(distToCrystal - radius) * 4 + (clearance and 0 or 12) + heightDelta
                if score < bestScore then
                    bestScore = score
                    bestPos = pos
                end
            end
        end
    end

    if bestPos then return bestPos end

    local delta = char.PrimaryPart.Position - origin
    local flat = Vector3.new(delta.X, 0, delta.Z)
    if flat.Magnitude < 1 then flat = Vector3.new(1, 0, 0) end
    local fallback = origin + flat.Unit * radius
    local ground = raycastGround(fallback, ignore)
    return ground and (ground.Position + Vector3.new(0, 3, 0)) or fallback
end

local function moveToPosition(hum, targetPos, targetPart)
    local char = player.Character
    if not char or not char.PrimaryPart then return false end

    local path = PathfindingService:CreatePath({
        AgentRadius = 1.9,
        AgentHeight = 5.2,
        AgentCanJump = true,
        AgentCanClimb = true,
        WaypointSpacing = MINE_SMOOTH_MOVE and 7 or 3,
        Costs = {
            Water = 5,
        },
    })

    local ok = pcall(function()
        path:ComputeAsync(char.PrimaryPart.Position, targetPos)
    end)

    local waypoints = nil
    if ok and path.Status == Enum.PathStatus.Success then
        waypoints = path:GetWaypoints()
    else
        waypoints = {{Position = targetPos, Action = Enum.PathWaypointAction.Walk}}
    end

    local originalWalkSpeed = hum.WalkSpeed
    if MINE_SMOOTH_MOVE then
        hum.WalkSpeed = MINE_WALK_SPEED + math.random(-1, 1)
    else
        hum.WalkSpeed = MINE_WALK_SPEED
    end

    local lastPos = char.PrimaryPart.Position
    local stuckFor = 0
    for index, waypoint in ipairs(waypoints) do
        if mode ~= "MINE" then
            hum.WalkSpeed = originalWalkSpeed
            return false
        end
        if targetPart and not targetPart.Parent then
            hum.WalkSpeed = originalWalkSpeed
            return false
        end

        if waypoint.Action == Enum.PathWaypointAction.Jump then
            hum.Jump = true
        end
        hum:MoveTo(waypoint.Position)

        local started = os.clock()
        while mode == "MINE" and os.clock() - started < 4.5 do
            task.wait(MINE_SMOOTH_MOVE and 0.08 or 0.15)
            if not char.PrimaryPart then
                hum.WalkSpeed = originalWalkSpeed
                return false
            end
            local currentPos = char.PrimaryPart.Position
            local waypointReach = (MINE_SMOOTH_MOVE and index < #waypoints) and 5.2 or 2.4
            if (currentPos - waypoint.Position).Magnitude <= waypointReach then
                break
            end
            if (currentPos - targetPos).Magnitude <= 2.6 then
                hum.WalkSpeed = originalWalkSpeed
                return true
            end

            if (currentPos - lastPos).Magnitude < 0.2 then
                stuckFor = stuckFor + (MINE_SMOOTH_MOVE and 0.08 or 0.15)
                if stuckFor > 1.1 then
                    hum.Jump = true
                    local recover = targetPos - currentPos
                    if recover.Magnitude < 0.1 then
                        recover = Vector3.new(1, 0, 0)
                    end
                    hum:MoveTo(currentPos + recover.Unit * 5)
                    task.wait(PATH_RETRY_DELAY)
                    hum.WalkSpeed = originalWalkSpeed
                    return false
                end
            else
                stuckFor = 0
                lastPos = currentPos
            end
        end
    end

    hum.WalkSpeed = originalWalkSpeed
    return char.PrimaryPart and (char.PrimaryPart.Position - targetPos).Magnitude <= 3
end

local function facePart(part)
    local char = player.Character
    if not char or not char.PrimaryPart or not part then return end
    local pos = char.PrimaryPart.Position
    local lookAt = Vector3.new(part.Position.X, pos.Y, part.Position.Z)
    char:SetPrimaryPartCFrame(CFrame.lookAt(pos, lookAt))
end

-- ==========================================
-- MINING: JALAN KE CRYSTAL & TAMBANG
-- ==========================================
local function mineRoutine()
    miningActive = true
    while mode == "MINE" do
        task.wait(0.5)
        local char = player.Character
        if not char then continue end
        if not char.PrimaryPart then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then continue end

        -- Cari crystal terdekat
        local crystal, dist = findNearestCrystal()

        if not crystal then
            statusLabel.Text = "Mining: Crystal not found!"
            warn("[MINE] Crystal tidak ditemukan. Scan workspace...")
            task.wait(3)
            continue
        end

        statusLabel.Text = "Mining: " .. crystal.Name .. " (" .. math.floor(dist) .. " stud)"
        warn("[MINE] Crystal ditemukan: " .. crystal.Name .. " jarak: " .. math.floor(dist))

        -- Equip pickaxe
        local tool = equipTool(MINE_TOOL_NAMES)
        if not tool then
            statusLabel.Text = "Mining: No pickaxe found!"
            warn("[MINE] Tidak ada pickaxe di backpack!")
            task.wait(3)
            continue
        end

        -- Jalan ke titik samping crystal, bukan ke pusatnya, agar tidak naik ke atas batu.
        local standPoint = getMiningStandPoint(crystal)
        if standPoint and (char.PrimaryPart.Position - standPoint).Magnitude > 2.4 then
            warn("[MINE] Pathfinding ke sisi crystal...")
            local arrived = moveToPosition(hum, standPoint, crystal)
            if not arrived then
                task.wait(0.4)
                continue
            end
        end

        -- Tambang: klik berkali-kali pada crystal
        facePart(crystal)
        local cam = workspace.CurrentCamera
        if cam then
            local aimPos = crystal.Position + Vector3.new(0, math.clamp(crystal.Size.Y * 0.15, 0.5, 2.5), 0)
            local screenPos, onScreen = cam:WorldToScreenPoint(aimPos)
            if onScreen then
                warn("[MINE] Menambang crystal...")
                for i = 1, 7 do
                    if mode ~= "MINE" then break end
                    if crystal.Parent == nil then break end
                    facePart(crystal)
                    -- Klik di posisi crystal di layar
                    VirtualUser:Button1Down(
                        Vector2.new(screenPos.X, screenPos.Y),
                        cam.CFrame
                    )
                    task.wait(0.15)
                    VirtualUser:Button1Up(
                        Vector2.new(screenPos.X, screenPos.Y),
                        cam.CFrame
                    )
                    task.wait(0.3)
                    pcall(function() tool:Activate() end)
                end
            else
                -- Crystal tidak terlihat di layar, coba activate tool
                warn("[MINE] Crystal di luar layar, activate tool...")
                pcall(function() tool:Activate() end)
                task.wait(1)
            end
        end

        task.wait(0.5)
    end
    miningActive = false
end

-- ==========================================
-- FISHING MINIGAME HANDLER (Heartbeat)
-- ==========================================
RunService.Heartbeat:Connect(function()
    if mode ~= "FISH" then
        -- Paksa lepas Space jika tidak fishing
        if isSpacePressed then
            setSpacePressed(false, true)
        end
        return
    end

    local white, red = getFishingElements()

    if white and red and white.Visible then
        lastMinigameGuiSeen = os.clock()
        -- Minigame aktif
        if not minigameJustStarted then
            minigameJustStarted = true
            -- Reset paksa Space di awal minigame
            setSpacePressed(false, true)
            lastWhiteCenter = nil
            whiteVelocity = 0
            fishingState = "MINIGAME"
            statusLabel.Text = "Fish: Minigame!"
            warn("[FISH] Minigame dimulai!")
        end

        local whiteCenter = white.AbsolutePosition.X + (white.AbsoluteSize.X / 2)
        local redCenter = red.AbsolutePosition.X + (red.AbsoluteSize.X / 2)
        local now = os.clock()
        local dt = math.max(now - lastWhiteSample, 0.016)
        if lastWhiteCenter then
            local instantVelocity = (whiteCenter - lastWhiteCenter) / dt
            whiteVelocity = (whiteVelocity * 0.65) + (instantVelocity * 0.35)
        end
        lastWhiteCenter = whiteCenter
        lastWhiteSample = now

        local predictedWhite = whiteCenter + (whiteVelocity * 0.08)
        local redWidth = math.max(red.AbsoluteSize.X, 1)
        local tolerance = math.clamp(redWidth * 0.18, 5, 16)
        local error = redCenter - predictedWhite

        if error > tolerance then
            setSpacePressed(true)
        elseif error < -tolerance then
            setSpacePressed(false)
        elseif math.abs(whiteVelocity) > 180 then
            setSpacePressed(whiteVelocity < 0)
        end

    else
        -- Minigame tidak aktif
        if fishingState == "MINIGAME" and os.clock() - lastMinigameGuiSeen < 0.25 then
            return
        end
        minigameJustStarted = false
        setSpacePressed(false, true)
        lastWhiteCenter = nil
        whiteVelocity = 0

        if fishingState == "MINIGAME" then
            fishingState = "COOLDOWN"
            lastMinigameTime = os.clock()
            nextCastTime = os.clock() + FISH_RECAST_DELAY
            statusLabel.Text = "Fish: Ikan didapat, siap ulang..."
            warn("[FISH] Minigame selesai!")
        elseif fishingState == "COOLDOWN" then
            if os.clock() - lastMinigameTime >= FISH_RECAST_DELAY then
                fishingState = "IDLE"
                statusLabel.Text = "Fish: Siap melempar..."
            end
        end
    end
end)

-- ==========================================
-- FISHING EQUIP + CAST LOOP
-- ==========================================
task.spawn(function()
    while true do
        task.wait(0.2)
        if mode ~= "FISH" then continue end

        local char = player.Character
        if not char then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")

        -- Anti lompat
        if hum and hum:GetStateEnabled(Enum.HumanoidStateType.Jumping) then
            hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
        end

        -- Equip rod
        local tool = equipTool(FISH_TOOL_NAMES)

        if tool and not isCasting then
            local now = os.clock()
            if (fishingState == "IDLE" and now >= nextCastTime) or
               (fishingState == "WAITING" and (now - lastCastTime) >= FISH_WAIT_TIMEOUT) then
                if fishingState == "WAITING" then
                    statusLabel.Text = "Fish: Lempar ulang..."
                    warn("[FISH] Timeout gigitan, casting ulang")
                else
                    statusLabel.Text = "Fish: Siap melempar..."
                end
                task.spawn(castRod)
            elseif fishingState == "WAITING" then
                statusLabel.Text = "Fish: Menunggu gigitan..."
            elseif fishingState == "CASTING" then
                statusLabel.Text = "Fish: Melempar umpan..."
            elseif fishingState == "COOLDOWN" then
                statusLabel.Text = "Fish: Siap ulang..."
            end
        elseif not tool then
            statusLabel.Text = "Fish: Tidak ada rod!"
        end
    end
end)

-- ==========================================
-- SETTINGS BUTTONS
-- ==========================================
btnSmooth.MouseButton1Click:Connect(function()
    MINE_SMOOTH_MOVE = not MINE_SMOOTH_MOVE
    btnSmooth.Text = MINE_SMOOTH_MOVE and "Smooth Mine: ON" or "Smooth Mine: OFF"
    btnSmooth.BackgroundColor3 = MINE_SMOOTH_MOVE and Color3.fromRGB(35, 132, 92) or Color3.fromRGB(92, 75, 75)
end)

btnFishWait.MouseButton1Click:Connect(function()
    if FISH_WAIT_TIMEOUT == 24 then
        FISH_WAIT_TIMEOUT = 30
    elseif FISH_WAIT_TIMEOUT == 30 then
        FISH_WAIT_TIMEOUT = 18
    else
        FISH_WAIT_TIMEOUT = 24
    end
    btnFishWait.Text = "Wait: " .. tostring(FISH_WAIT_TIMEOUT) .. "s"
end)

btnSpeed.MouseButton1Click:Connect(function()
    if MINE_WALK_SPEED == 15 then
        MINE_WALK_SPEED = 13
    elseif MINE_WALK_SPEED == 13 then
        MINE_WALK_SPEED = 16
    else
        MINE_WALK_SPEED = 15
    end
    btnSpeed.Text = "Speed: " .. tostring(MINE_WALK_SPEED)
end)

btnRecast.MouseButton1Click:Connect(function()
    if FISH_RECAST_DELAY == 1.15 then
        FISH_RECAST_DELAY = 1.8
    elseif FISH_RECAST_DELAY == 1.8 then
        FISH_RECAST_DELAY = 0.9
    else
        FISH_RECAST_DELAY = 1.15
    end
    btnRecast.Text = "Recast: " .. string.format("%.1f", FISH_RECAST_DELAY) .. "s"
end)

-- ==========================================
-- TOMBOL FISH
-- ==========================================
btnFish.MouseButton1Click:Connect(function()
    if mode == "FISH" then
        -- Matikan fish
        mode = "OFF"
        btnFish.Text = "🎣 AUTO FISH: OFF"
        btnFish.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
        fishingState = "IDLE"
        nextCastTime = 0
        lastMinigameGuiSeen = 0
        lastWhiteCenter = nil
        whiteVelocity = 0
        isCasting = false
        statusLabel.Text = "Status: OFF"

        if isSpacePressed then
            setSpacePressed(false, true)
        end
        pcall(function()
            local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true) end
        end)
    else
        -- Nyalakan fish, matikan mine
        mode = "FISH"
        btnFish.Text = "🎣 AUTO FISH: ON"
        btnFish.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        btnMine.Text = "⛏️ AUTO MINE: OFF"
        btnMine.BackgroundColor3 = Color3.fromRGB(150, 80, 20)
        fishingState = "IDLE"
        nextCastTime = 0
        lastMinigameGuiSeen = 0
        lastWhiteCenter = nil
        whiteVelocity = 0
        statusLabel.Text = "Fish: Aktif..."
        warn("[SYSTEM] Mode FISHING aktif")
    end
end)

-- ==========================================
-- TOMBOL MINE
-- ==========================================
btnMine.MouseButton1Click:Connect(function()
    if mode == "MINE" then
        -- Matikan mine
        mode = "OFF"
        btnMine.Text = "⛏️ AUTO MINE: OFF"
        btnMine.BackgroundColor3 = Color3.fromRGB(150, 80, 20)
        statusLabel.Text = "Status: OFF"

        pcall(function()
            local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true) end
        end)
    else
        -- Nyalakan mine, matikan fish
        mode = "MINE"
        btnMine.Text = "⛏️ AUTO MINE: ON"
        btnMine.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        btnFish.Text = "🎣 AUTO FISH: OFF"
        btnFish.BackgroundColor3 = Color3.fromRGB(50, 100, 200)

        if isSpacePressed then
            setSpacePressed(false, true)
        end
        pcall(function()
            local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true) end
        end)
        fishingState = "IDLE"
        nextCastTime = 0
        lastMinigameGuiSeen = 0
        lastWhiteCenter = nil
        whiteVelocity = 0
        statusLabel.Text = "Mine: Aktif..."
        warn("[SYSTEM] Mode MINING aktif")

        if not miningActive then
            task.spawn(mineRoutine)
        end
    end
end)

warn("=== INDO HANGOUT BOT LOADED ===")
warn("Tombol FISH = Auto Mancing")
warn("Tombol MINE = Auto Nambang Crystal")
warn("Jika crystal tidak ditemukan, cek output untuk scan nama object")
