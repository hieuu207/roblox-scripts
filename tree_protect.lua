-- Chờ game tải xong
if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Gửi thông báo ra màn hình và Chatbox
local function sendAlert(message)
    print("[SET-SPY] " .. message)
    
    -- Hiện thông báo góc phải màn hình
    StarterGui:SetCore("SendNotification", {
        Title = "⚡ PHÁT HIỆN SÉT ĐÁNH! ⚡",
        Text = message,
        Duration = 8
    })

    -- Đẩy vào khung chat trong game
    pcall(function()
        local TextChatService = game:GetService("TextChatService")
        if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
            TextChatService.TextChannels.RBXGeneral:DisplaySystemMessage("[CẢNH BÁO SÉT]: " .. message)
        else
            game:GetService("ReplicatedStorage"):WaitForChild("DefaultChatSystemChatEvents"):WaitForChild("SayMessageRequest"):FireServer("[CẢNH BÁO]: " .. message, "All")
        end
    end)
end

-- Kiểm tra nội dung text
local function checkText(str)
    if typeof(str) ~= "string" or str == "" then return end
    local lower = string.lower(str)

    if lower:find("sét") or lower:find("báo động") or lower:find("thu hoạch") or lower:find("cảnh báo") or lower:find("lightning") then
        -- Trích xuất thời gian xuất hiện trong câu
        local seconds = string.match(lower, "(%d+)%s*s") or string.match(lower, "trong%s*(%d+)") or string.match(lower, "%-(%d+)") or string.match(lower, "(%d+)")
        
        if seconds then
            sendAlert("Thời gian sét đánh sau: " .. seconds .. " GIÂY! (Nội dung: " .. str .. ")")
        else
            sendAlert("Nội dung cảnh báo: " .. str)
        end
    end
end

-- Theo dõi tất cả UI hiện có và UI mới xuất hiện
local function scanElement(elem)
    if elem:IsA("TextLabel") or elem:IsA("TextButton") then
        checkText(elem.Text)
        elem:GetPropertyChangedSignal("Text"):Connect(function()
            checkText(elem.Text)
        end)
    end
end

PlayerGui.DescendantAdded:Connect(scanElement)
for _, elem in ipairs(PlayerGui:GetDescendants()) do
    scanElement(elem)
end

sendAlert("Trình theo dõi thời gian sét đánh đã bật thành công!")
