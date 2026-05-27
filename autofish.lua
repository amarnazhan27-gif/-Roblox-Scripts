
-- ==========================================
-- 4 & 5. SMART AUTO CAST & HUMANIZED CATCH (V3 - JEDA JALUR AMAN 20 DETIK)
-- ==========================================
local fishingState = "IDLE" -- Status: "IDLE", "WAITING", atau "REELING"

button.MouseButton1Click:Connect(function()
    autoFishEnabled = not autoFishEnabled
    button.Text = autoFishEnabled and "ON (FISHING...)" or "OFF"
    button.BackgroundColor3 = autoFishEnabled and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
    
    if not autoFishEnabled then
        fishingState = "IDLE" 
    end
end)

rodEvent.OnClientEvent:Connect(function(action, rodName)
    if autoFishEnabled and action == "StartReeling" then
        fishingState = "REELING" -- Kunci total, hentikan semua aktivitas lempar
        
        -- Simulasi waktu main minigame secara natural
        local reactionTime = math.random(5, 12) / 10 
        local playTime = math.random(25, 45) / 10 
        
        task.wait(reactionTime + playTime)
        
        pcall(function()
            rodEvent:FireServer("Catch", true, rodName)
        end)
        
        task.wait(0.5)
        local playerGui = player:FindFirstChild("PlayerGui")
        if playerGui then
            for _, v in pairs(playerGui:GetChildren()) do
                if v:FindFirstChild("MainFrame") and v.MainFrame:FindFirstChild("Frame") then
                    v.Enabled = false
                end
            end
        end
        
        -- Jeda istirahat setelah dapat ikan sebelum memulai siklus baru
        task.wait(math.random(15, 30) / 10) 
        fishingState = "IDLE" 
    end
end)

task.spawn(function()
    while true do
        task.wait(1.0) -- Cek status setiap 1 detik agar pemrosesan lebih stabil
        
        if autoFishEnabled and fishingState == "IDLE" then
            local char = player.Character
            if char then
                local tool = char:FindFirstChildOfClass("Tool")
                if tool then
                    fishingState = "WAITING" -- Langsung kunci status ke WAITING begitu mendeteksi pancingan siap
                    
                    pcall(function()
                        tool:Activate() -- Lempar umpan
                    end)
                    
                    -- SYSTEM SAFETY DELAY (Sesuai instruksi: Jarak toleransi tunggu ikan dinaikkan ke 20 detik)
                    -- Skrip akan dipaksa diam selama 20 detik penuh untuk memberi waktu ikan menyambar dan masuk ke minigame
                    task.wait(20) 
                    
                    -- Jika setelah 20 detik statusnya masih WAITING (artinya tidak ada ikan menyambar/gagal masuk minigame),
                    -- baru statusnya di-reset ke IDLE agar karakter melempar ulang umpan baru.
                    if fishingState == "WAITING" then
                        fishingState = "IDLE"
                    end
                end
            end
        end
    end
end)
