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
local MINE_STOP_DISTANCE = 6.5
local MINE_MAX_SCAN_DISTANCE = 260
local PATH_RETRY_DELAY = 0.35

-- ==========================================
-- GUI UTAMA
-- ==========================================
local gui = Instance.new("ScreenGui")
gui.Name = "AllInOne_IH"
gui.ResetOnSpawn = false
gui.Parent = game:GetService("CoreGui")

local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0, 220, 0, 160)
main.Position = UDim2.new(1, -230, 0, 100)
main.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
main.BorderSizePixel = 2
main.BorderColor3 = Color3.fromRGB(0, 200, 255)
main.Active = true
main.Draggable = true

-- Title
local title = Instance.new("TextLabel", main)
title.Size = UDim2.new(1, 0, 0, 28)
title.BackgroundColor3 = Color3.fromRGB(0, 100, 150)
title.Text = "INDO HANGOUT BOT"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextScaled = true

-- Status label
local statusLabel = Instance.new("TextLabel", main)
statusLabel.Size = UDim2.new(1, 0, 0, 22)
statusLabel.Position = UDim2.new(0, 0, 0, 28)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: OFF"
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.Font = Enum.Font.Code
statusLabel.TextScaled = true

-- Tombol FISH
local btnFish = Instance.new("TextButton", main)
btnFish.Size = UDim2.new(0.9, 0, 0, 40)
btnFish.Position = UDim2.new(0.05, 0, 0, 55)
btnFish.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
btnFish.Text = "🎣 AUTO FISH: OFF"
btnFish.Font = Enum.Font.GothamBold
btnFish.TextScaled = true
btnFish.TextColor3 = Color3.new(1, 1, 1)

-- Tombol MINE
local btnMine = Instance.new("TextButton", main)
btnMine.Size = UDim2.new(0.9, 0, 0, 40)
btnMine.Position = UDim2.new(0.05, 0, 0, 100)
btnMine.BackgroundColor3 = Color3.fromRGB(150, 80, 20)
btnMine.Text = "⛏️ AUTO MINE: OFF"
btnMine.Font = Enum.Font.GothamBold
btnMine.TextScaled = true
btnMine.TextColor3 = Color3.new(1, 1, 1)

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
        warn("[FISH] Casting...")
        local tool = player.Character and player.Character:FindFirstChildWhichIsA("Tool")
        if tool then
            pcall(function() tool:Activate() end)
        end
        VirtualUser:Button1Down(screenCenter, cam.CFrame)
        task.wait(2.15)
        VirtualUser:Button1Up(screenCenter, cam.CFrame)
        if tool then
            pcall(function() tool:Deactivate() end)
        end
        warn("[FISH] Umpan dilempar!")
    end)
    task.wait(1.4)
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
    local radius = math.max(MINE_STOP_DISTANCE, math.max(crystal.Size.X, crystal.Size.Z) * 0.5 + 4)
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
            if heightDelta < 18 and crystalHeightDelta < 8 then
                local clearance = hasClearLine(pos + Vector3.new(0, 2, 0), origin, ignore)
                local score = (pos - char.PrimaryPart.Position).Magnitude + (clearance and 0 or 35) + heightDelta
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
        AgentRadius = 2.6,
        AgentHeight = 5.2,
        AgentCanJump = true,
        AgentCanClimb = true,
        WaypointSpacing = 4,
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

    local lastPos = char.PrimaryPart.Position
    local stuckFor = 0
    for _, waypoint in ipairs(waypoints) do
        if mode ~= "MINE" then return false end
        if targetPart and not targetPart.Parent then return false end

        if waypoint.Action == Enum.PathWaypointAction.Jump then
            hum.Jump = true
        end
        hum:MoveTo(waypoint.Position)

        local started = os.clock()
        while mode == "MINE" and os.clock() - started < 4.5 do
            task.wait(0.15)
            if not char.PrimaryPart then return false end
            local currentPos = char.PrimaryPart.Position
            if (currentPos - waypoint.Position).Magnitude <= 3.3 then
                break
            end
            if (currentPos - targetPos).Magnitude <= 3.8 then
                return true
            end

            if (currentPos - lastPos).Magnitude < 0.25 then
                stuckFor = stuckFor + 0.15
                if stuckFor > 1.1 then
                    hum.Jump = true
                    local recover = targetPos - currentPos
                    if recover.Magnitude < 0.1 then
                        recover = Vector3.new(1, 0, 0)
                    end
                    hum:MoveTo(currentPos + recover.Unit * 5)
                    task.wait(PATH_RETRY_DELAY)
                    return false
                end
            else
                stuckFor = 0
                lastPos = currentPos
            end
        end
    end

    return char.PrimaryPart and (char.PrimaryPart.Position - targetPos).Magnitude <= 5
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
        if standPoint and (char.PrimaryPart.Position - standPoint).Magnitude > 4 then
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
        minigameJustStarted = false
        setSpacePressed(false, true)
        lastWhiteCenter = nil
        whiteVelocity = 0

        if fishingState == "MINIGAME" then
            fishingState = "COOLDOWN"
            lastMinigameTime = os.time()
            warn("[FISH] Minigame selesai!")
        elseif fishingState == "COOLDOWN" then
            if os.time() - lastMinigameTime >= 1 then
                fishingState = "IDLE"
                statusLabel.Text = "Fish: Siap cast..."
            end
        end
    end
end)

-- ==========================================
-- FISHING EQUIP + CAST LOOP
-- ==========================================
task.spawn(function()
    while true do
        task.wait(0.5)
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
            if fishingState == "IDLE" or
               (fishingState == "WAITING" and (os.time() - lastCastTime) >= 20) then
                fishingState = "WAITING"
                lastCastTime = os.time()
                statusLabel.Text = "Fish: Casting..."
                task.spawn(castRod)
            elseif fishingState == "WAITING" then
                statusLabel.Text = "Fish: Menunggu gigitan..."
            end
        elseif not tool then
            statusLabel.Text = "Fish: Tidak ada rod!"
        end
    end
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
        fishingState = "IDLE"
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
