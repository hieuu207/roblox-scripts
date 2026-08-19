if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Workspace = game:GetService("Workspace")

local isHarvesting = false

-- Hàm cưỡng chế kích hoạt toàn bộ ProximityPrompt phím E
local function harvestTree()
    if isHarvesting then return end
    isHarvesting = true
    
    print("[ANTI-LIGHTNING] Đang thu hoạch cây trước khi sét đánh 1s...")

    for _, prompt in ipairs(Workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") then
            -- Mở rộng tối đa phạm vi và bỏ thời gian chờ phím E
            prompt.RequiresLineOfSight = false
            prompt.MaxActivationDistance = math.huge
            prompt.HoldDuration = 0
            
            -- Ưu tiên sử dụng hàm executor để giả lập ấn phím E chuẩn xác nhất
            if fireproximityprompt then
                fireproximityprompt(prompt)
            else
                prompt:InputHoldBegin()
                task.wait(0.05)
                prompt:InputHoldEnd()
            end
        end
    end

    task.wait(2)
    isHarvesting = false
end

-- Hàm tính toán thời gian từ thông báo cảnh báo
local function processAlert(text)
    local lowerText = string.lower(text)
    
    if string.find(lowerText, "báo động đỏ") or string.find(lowerText, "sét sắp đánh") or string.find(lowerText, "thu hoạch ngay") then
        -- Tìm số giây (ví dụ: "trong 10s", "trong 5s", "1-10s", "10 giây")
        local num = string.match(lowerText, "(%d+)%s*s") or string.match(lowerText, "%-(%d+)") or string.match(lowerText, "trong%s*(%d+)")
        
        if num then
            local totalSeconds = tonumber(num)
            if totalSeconds and totalSeconds > 1 then
                local waitTime = totalSeconds - 1
                print("[ANTI-LIGHTNING] Phát hiện sét! Đếm ngược: " .. totalSeconds .. "s. Chờ " .. waitTime .. "s để hái cây.")
                task.delay(waitTime, harvestTree)
                return
            end
        end
        
        -- Nếu thông báo không ghi rõ số hoặc thời gian còn <= 1s, kích hoạt ngay lập tức
        harvestTree()
    end
end

-- Lắng nghe các thông báo GUI
local function scanElement(elem)
    if elem:IsA("TextLabel") or elem:IsA("TextButton") then
        processAlert(elem.Text)
        elem:GetPropertyChangedSignal("Text"):Connect(function()
            processAlert(elem.Text)
        end)
    end
end

PlayerGui.DescendantAdded:Connect(scanElement)
for _, elem in ipairs(PlayerGui:GetDescendants()) do
    scanElement(elem)
end

game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Auto Harvest Ready",
    Text = "Hệ thống tự ấn E hái cây trước khi sét đánh 1s đã bật!",
    Duration = 5
})
