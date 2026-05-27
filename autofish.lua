-- ==========================================
-- 4 & 5. SMART AUTO CAST & HUMANIZED CATCH
-- ==========================================
local fishingState = "IDLE" -- Status bisa berupa: "IDLE", "WAITING", atau "REELING"

-- (Tambahan kecil pada tombol ON/OFF agar state keriset saat dimatikan)
button.MouseButton1Click:Connect(function()
    autoFishEnabled = not autoFishEnabled
    button.Text = autoFishEnabled and "ON (FISHING...)" or "OFF"
    button.BackgroundColor3 = autoFishEnabled and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
    
    if not autoFishEnabled then
        fishingState = "IDLE" -- Reset status jika dimatikan manual
    end
end)

rodEvent.OnClientEvent:Connect(function(action, rodName)
    if autoFishEnabled and action == "StartReeling" then
        fishingState = "REELING" -- Kunci status agar tidak melempar umpan saat narik ikan
        
        -- Waktu reaksi dan main pura-pura
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
        
        -- Jeda istirahat natural sebelum melempar umpan lagi
        task.wait(math.random(10, 20) / 10) 
        fishingState = "IDLE" -- Ubah status ke menganggur agar Auto Cast jalan lagi
    end
end)

task.spawn(function()
    while task.wait(0.5) do -- Loop mengecek lebih cepat
        -- HANYA klik/lempar jika sedang menganggur
        if autoFishEnabled and fishingState == "IDLE" then
            local char = player.Character
            if char then
                local tool = char:FindFirstChildOfClass("Tool")
                if tool then
                    fishingState = "WAITING" -- Kunci status agar tidak diklik-klik terus
                    
                    pcall(function()
                        tool:Activate()
                    end)
                    
                    -- Failsafe (Sistem Pengaman): 
                    -- Jika nyangkut (ikan tidak makan umpan lebih dari 15 detik), reset status agar lempar ulang
                    task.delay(15, function()
                        if fishingState == "WAITING" then
                            fishingState = "IDLE"
                        end
                    end)
                end
            end
        end
    end
end)
