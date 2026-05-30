-- ==========================================
-- FISHING: CAST ROD v3 (RETRY + BOBBER DETECT)
-- Ganti fungsi castRod() yang lama dengan ini
-- ==========================================
local function isBobberActive()
    -- Cek apakah bobber/pelampung sudah ada di workspace
    -- (tanda casting berhasil)
    for _, v in pairs(workspace:GetDescendants()) do
        local name = v.Name:lower()
        if name:find("bobber") or name:find("float") or name:find("pelampung")
           or name:find("hook") or name:find("kail") or name:find("fishing") then
            if v:IsA("BasePart") or v:IsA("Part") or v:IsA("MeshPart") then
                return true
            end
        end
    end
    -- Cek juga dari sisi tool: jika rod punya ClickDetector atau RemoteEvent aktif
    return false
end

local function tryClickCastButton()
    -- Scan tombol cast di PlayerGui
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return false end
    for _, v in pairs(playerGui:GetDescendants()) do
        if (v:IsA("TextButton") or v:IsA("ImageButton")) and v.Visible then
            local name = v.Name:lower()
            if name:find("cast") or name:find("throw") or name:find("fish")
               or name:find("action") or name:find("use") then
                pcall(function() v:FireMouseButton1Click() end)
                warn("[FISH] Cast button ditemukan & diklik: " .. v.Name)
                return true
            end
        end
    end
    return false
end

local function castRod()
    if isCasting then return end
    isCasting = true

    -- Coba hingga 3x sampai berhasil
    local success = false
    for attempt = 1, 3 do
        if mode ~= "FISH" then break end
        warn("[FISH] Cast attempt " .. attempt)

        -- Pastikan rod benar-benar di tangan sebelum cast
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local tool = char and char:FindFirstChildWhichIsA("Tool")

        if not tool then
            -- Rod belum di tangan, tunggu sebentar lagi
            warn("[FISH] Rod belum equipped, menunggu...")
            task.wait(1)
            isCasting = false
            return
        end

        -- Metode 1: Coba klik cast button di GUI dulu
        local guiClicked = tryClickCastButton()

        if not guiClicked then
            -- Metode 2: VirtualUser di tengah layar
            local cam = workspace.CurrentCamera
            if cam then
                local screenCenter = cam.ViewportSize / 2
                VirtualUser:Button1Down(screenCenter, cam.CFrame)
                task.wait(2.0) -- tahan 2 detik (lebih lama = charge lebih kuat)
                VirtualUser:Button1Up(screenCenter, cam.CFrame)
            end
        else
            task.wait(1)
        end

        -- Tunggu sebentar lalu cek apakah casting berhasil
        task.wait(1.5)

        -- Cek indikator berhasil: minigame muncul, atau state berubah
        local white, red = getFishingElements()
        if white and white.Visible then
            warn("[FISH] Cast berhasil! Minigame sudah aktif.")
            success = true
            break
        end

        -- Cek bobber
        if isBobberActive() then
            warn("[FISH] Cast berhasil! Bobber terdeteksi.")
            success = true
            break
        end

        -- Jika gagal dan masih ada attempt, tunggu sebelum retry
        if attempt < 3 then
            warn("[FISH] Cast belum berhasil, retry dalam 2 detik...")
            task.wait(2)
        end
    end

    if not success then
        warn("[FISH] Cast gagal setelah 3x percobaan. Akan coba lagi di loop berikutnya.")
        fishingState = "IDLE" -- reset state agar loop utama mencoba lagi
    end

    task.wait(1)
    isCasting = false
end
Dan perbaiki loop utama fishing agar timeout lebih agresif:
lua-- Ganti bagian loop FISH di task.spawn yang lama dengan ini:
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

        -- Equip rod DULU, tunggu sampai benar-benar di tangan
        local tool = equipTool(FISH_TOOL_NAMES)
        if not tool then
            statusLabel.Text = "Fish: Tidak ada rod!"
            continue
        end

        -- Pastikan tool sudah di karakter (bukan backpack)
        local toolInHand = char:FindFirstChildWhichIsA("Tool")
        if not toolInHand then
            task.wait(1) -- tunggu equip selesai
            continue
        end

        -- Cast logic
        if not isCasting then
            if fishingState == "IDLE" then
                fishingState = "WAITING"
                lastCastTime = os.time()
                statusLabel.Text = "Fish: Casting..."
                task.spawn(castRod)

            elseif fishingState == "WAITING" then
                local elapsed = os.time() - lastCastTime
                statusLabel.Text = "Fish: Menunggu... (" .. elapsed .. "s)"

                -- Timeout 15 detik (lebih cepat dari sebelumnya 20 detik)
                if elapsed >= 15 then
                    warn("[FISH] TIMEOUT! Re-cast paksa.")
                    fishingState = "IDLE"
                end

            elseif fishingState == "COOLDOWN" then
                if os.time() - lastMinigameTime >= 1 then
                    fishingState = "IDLE"
                    statusLabel.Text = "Fish: Siap cast..."
                end
            end
        end
    end
end)
