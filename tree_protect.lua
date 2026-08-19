-- Chờ game tải hoàn tất
if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Workspace = game:GetService("Workspace")

-- Từ khóa cảnh báo sét xuất hiện trên màn hình
local ALERT_KEYWORDS = {"báo động đỏ", "cảnh báo", "sét sắp đánh", "thu hoạch ngay"}

-- Hàm thực hiện hành động thu hoạch / nhặt cây
local function autoHarvestTrees()
    print("[CẢNH BÁO SÉT] Đang tự động nhặt/thu hoạch toàn bộ cây!")

    -- Cách 1: Tự động kích hoạt ProximityPrompt (nút giữ E/nhặt cây gần nhất)
    for _, prompt in ipairs(Workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") then
            -- Bỏ qua thời gian giữ và kích hoạt ngay lập tức
            prompt.HoldDuration = 0
            prompt:InputHoldBegin()
            task.wait()
            prompt:InputHoldEnd()
        end
    end

    -- Cách 2: Tự động gửi Remote thu hoạch (nếu game dùng RemoteEvent)
    for _, remote in ipairs(game:GetDescendants()) do
        if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
            local rName = string.lower(remote.Name)
            if rName:find("harvest") or rName:find("collect") or rName:find("pickup") or rName:find("cay") or rName:find("tree") then
                pcall(function()
                    if remote:IsA("RemoteEvent") then
                        remote:FireServer()
                    end
                end)
            end
        end
    end
end

-- Hàm kiểm tra nội dung text cảnh báo
local function checkText(textLabel)
    if textLabel:IsA("TextLabel") or textLabel:IsA("TextButton") then
        local text = string.lower(textLabel.Text)
        for _, keyword in ipairs(ALERT_KEYWORDS) do
            if string.find(text, keyword) then
                autoHarvestTrees()
                break
            end
        end
    end
end

-- Theo dõi GUI khi có thông báo mới bật lên
PlayerGui.DescendantAdded:Connect(function(child)
    task.wait(0.1)
    checkText(child)
end)

-- Theo dõi nếu text của GUI đã có sẵn thay đổi nội dung sang cảnh báo sét
for _, guiElement in ipairs(PlayerGui:GetDescendants()) do
    if guiElement:IsA("TextLabel") or guiElement:IsA("TextButton") then
        guiElement:GetPropertyChangedSignal("Text"):Connect(function()
            checkText(guiElement)
        end)
    end
end

-- Thông báo kích hoạt thành công
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Auto Harvest Ready",
    Text = "Hệ thống tự động hái cây khi có sét đã sẵn sàng!",
    Duration = 5
})
