-- Chờ game tải xong
if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Danh sách từ khóa liên quan đến sét / thiên tai / phá cây
local BlockKeywords = {"lightning", "strike", "destroy", "damage", "storm", "burn", "killtree", "set"}
local AlertKeywords = {"báo động đỏ", "sét sắp đánh", "thu hoạch ngay", "cảnh báo"}

local isHarvesting = false

-- Hàm cưỡng chế bấm phím E để nhặt cây
local function harvestTree()
    if isHarvesting then return end
    isHarvesting = true

    print("[Anti-Lightning] Đang tự động bấm E nhặt toàn bộ cây...")

    for _, prompt in ipairs(Workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") then
            -- Mở rộng tối đa phạm vi và bỏ thời gian giữ phím E
            prompt.RequiresLineOfSight = false
            prompt.MaxActivationDistance = math.huge
            prompt.HoldDuration = 0

            -- Kích hoạt phím E
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

-- Hàm trích xuất thời gian đếm ngược và hẹn giờ nhặt trước 1s
local function processAlert(text)
    local lowerText = string.lower(text)

    for _, keyword in ipairs(AlertKeywords) do
        if string.find(lowerText, keyword) then
            -- Trích xuất số giây (ví dụ: "trong 10s", "1-10s", "10s", "trong 5")
            local num = string.match(lowerText, "%-(%d+)") or string.match(lowerText, "(%d+)%s*s") or string.match(lowerText, "trong%s*(%d+)")
            
            if num then
                local totalSec = tonumber(num)
                if totalSec and totalSec > 1 then
                    local delayTime = totalSec - 1
                    print("[Anti-Lightning] Phát hiện cảnh báo sét (" .. totalSec .. "s)! Sẽ tự động bấm E sau " .. delayTime .. "s.")
                    task.delay(delayTime, harvestTree)
                    return
                end
            end

            -- Nếu thời gian còn <= 1s hoặc không tìm thấy số, nhặt ngay
            harvestTree()
            break
        end
    end
end

-- 1. Lắng nghe thông báo đếm ngược trên giao diện màn hình
local function scanGui(elem)
    if elem:IsA("TextLabel") or elem:IsA("TextButton") then
        processAlert(elem.Text)
        elem:GetPropertyChangedSignal("Text"):Connect(function()
            processAlert(elem.Text)
        end)
    end
end

PlayerGui.DescendantAdded:Connect(scanGui)
for _, elem in ipairs(PlayerGui:GetDescendants()) do
    scanGui(elem)
end

-- 2. Hook chặn RemoteEvents từ Server gửi xuống (hoặc Client gửi lên)
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    if method == "FireServer" or method == "InvokeServer" then
        local remoteName = string.lower(tostring(self.Name))
        for _, keyword in ipairs(BlockKeywords) do
            if string.find(remoteName, keyword) then
                warn("[Anti-Lightning] Đã chặn Remote gọi gây hại: " .. self.Name)
                return nil
            end
        end
    end

    return oldNamecall(self, ...)
end)

-- 3. Tự động tìm và xoá Part/Hitbox sét rơi vào vùng cây trong Workspace
Workspace.DescendantAdded:Connect(function(child)
    task.wait()
    local childName = string.lower(tostring(child.Name))

    for _, keyword in ipairs(BlockKeywords) do
        if string.find(childName, keyword) then
            if child:IsA("BasePart") then
                child.CanTouch = false
                child.CanCollide = false
            end
            pcall(function()
                child:Destroy()
            end)
            print("[Anti-Lightning] Đã vô hiệu hóa vật thể sét: " .. childName)
            break
        end
    end
end)

-- Thông báo kích hoạt thành công
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Anti-Lightning Loaded",
    Text = "Hệ thống tự hái cây trước 1s & chặn sét đã bật!",
    Duration = 5
})
