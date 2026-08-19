if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local RootPart = Character:WaitForChild("HumanoidRootPart")

local BlockKeywords = {"lightning", "strike", "destroy", "damage", "storm", "burn", "killtree", "set"}
local AlertKeywords = {"báo động", "sét", "thu hoạch", "cảnh báo", "lightning", "strike"}
local isHarvesting = false

-- Hàm cưỡng chế nhặt toàn bộ cây
local function forceHarvestAll()
    if isHarvesting then return end
    isHarvesting = true

    print("[ANTI-LIGHTNING] Đang cưỡng chế nhặt toàn bộ cây...")

    for _, prompt in ipairs(Workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") then
            task.spawn(function()
                -- 1. Bỏ qua mọi giới hạn tương tác
                prompt.RequiresLineOfSight = false
                prompt.MaxActivationDistance = 9999
                prompt.HoldDuration = 0

                -- 2. Đưa nhân vật tới gần gốc cây trong tích tắc để hợp lệ hóa vị trí
                local parentPart = prompt.Parent
                if parentPart and parentPart:IsA("BasePart") and RootPart then
                    local originalCFrame = RootPart.CFrame
                    RootPart.CFrame = parentPart.CFrame + Vector3.new(0, 2, 0)
                    task.wait(0.05)

                    -- 3. Kích hoạt ProximityPrompt
                    if fireproximityprompt then
                        fireproximityprompt(prompt)
                    else
                        prompt:InputHoldBegin()
                        task.wait(0.05)
                        prompt:InputHoldEnd()
                    end

                    -- 4. Kích hoạt trực tiếp sự kiện Trigger
                    pcall(function()
                        prompt:InputHoldBegin()
                        prompt:InputHoldEnd()
                    end)

                    task.wait(0.05)
                    RootPart.CFrame = originalCFrame
                end
            end)
        end
    end

    task.wait(1.5)
    isHarvesting = false
end

-- Hàm đọc và tính toán thời gian cảnh báo
local function checkAlert(text)
    if typeof(text) ~= "string" then return end
    local lowerText = string.lower(text)

    for _, kw in ipairs(AlertKeywords) do
        if string.find(lowerText, kw) then
            -- Bắt các dạng số: "1-10s", "10s", "10 giây", "10"
            local num = string.match(lowerText, "%-(%d+)") or string.match(lowerText, "(%d+)%s*s") or string.match(lowerText, "trong%s*(%d+)") or string.match(lowerText, "(%d+)")
            
            if num then
                local sec = tonumber(num)
                if sec and sec > 1 then
                    print("[ANTI-LIGHTNING] Phát hiện cảnh báo: " .. sec .. "s. Hẹn giờ hái trước 1s!")
                    task.delay(sec - 1, forceHarvestAll)
                    return
                end
            end

            forceHarvestAll()
            break
        end
    end
end

-- Quét toàn bộ GUI của người chơi
local function bindGui(elem)
    if elem:IsA("TextLabel") or elem:IsA("TextButton") then
        checkAlert(elem.Text)
        elem:GetPropertyChangedSignal("Text"):Connect(function()
            checkAlert(elem.Text)
        end)
    end
end

LocalPlayer.PlayerGui.DescendantAdded:Connect(bindGui)
for _, elem in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
    bindGui(elem)
end

-- Hook chặn các luồng Remote gây hại
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    if method == "FireServer" or method == "InvokeServer" then
        local remoteName = string.lower(tostring(self.Name))
        for _, keyword in ipairs(BlockKeywords) do
            if string.find(remoteName, keyword) then
                return nil
            end
        end
    end
    return oldNamecall(self, ...)
end)

-- Tự động triệt tiêu Part sét trong Workspace
Workspace.DescendantAdded:Connect(function(child)
    task.wait()
    local name = string.lower(tostring(child.Name))
    for _, kw in ipairs(BlockKeywords) do
        if string.find(name, kw) then
            if child:IsA("BasePart") then
                child.CanTouch = false
                child.CanCollide = false
            end
            pcall(function() child:Destroy() end)
            break
        end
    end
end)

game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Anti-Lightning v2",
    Text = "Đã tối ưu hóa nhặt cây bằng dịch chuyển & kích hoạt cưỡng chế!",
    Duration = 5
})
