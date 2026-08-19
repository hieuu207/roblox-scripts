if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local isFarming = false

-- Hàm giả lập ấn bàn phím vật lý (Cách trị Executor lỗi fireproximityprompt)
local function ForceCollect()
    if isFarming then return end
    isFarming = true

    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then 
        isFarming = false
        return 
    end
    
    print("[HỆ THỐNG] Đang dịch chuyển và ấn E...")

    for _, prompt in ipairs(Workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") then
            local action = string.lower(prompt.ActionText or "")
            if action:find("sưu tầm") or action:find("nhặt") or action:find("thu hoạch") then
                local part = prompt.Parent
                if part and part:IsA("BasePart") then
                    -- 1. Lưu vị trí cũ và Dịch chuyển nhân vật sát thẳng vào gốc cây
                    local oldCFrame = char.HumanoidRootPart.CFrame
                    char.HumanoidRootPart.CFrame = part.CFrame + Vector3.new(0, 2, 0)
                    task.wait(0.2) -- Đợi game nhận diện vị trí
                    
                    -- 2. Giả lập phần cứng đè phím E
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                    task.wait(prompt.HoldDuration + 0.1) -- Giữ phím E theo thời gian yêu cầu của game
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                    
                    task.wait(0.1)
                    -- Trả nhân vật về chỗ cũ
                    char.HumanoidRootPart.CFrame = oldCFrame
                end
            end
        end
    end
    
    task.wait(2)
    isFarming = false
end

-- Hàm đọc text thông báo của game
local function ReadAlert(textStr)
    if typeof(textStr) ~= "string" then return end
    local txt = string.lower(textStr)
    
    -- Nếu bắt được đúng dòng chữ cảnh báo sét của game
    if txt:find("sét sắp đánh") or txt:find("thu hoạch ngay") or txt:find("báo động đỏ") then
        -- Lọc ra con số giây đếm ngược trong thông báo (VD: "trong 10s")
        local secNum = string.match(txt, "(%d+)%s*s") or string.match(txt, "trong%s*(%d+)") or string.match(txt, "%-(%d+)")
        local seconds = tonumber(secNum)
        
        if seconds and seconds > 1 then
            local waitTime = seconds - 1.5 -- Thu hoạch trước 1.5 giây để bù độ trễ ping
            print("[CẢNH BÁO] Sét đánh sau " .. seconds .. "s. Sẽ hái cây sau " .. waitTime .. "s!")
            
            task.delay(waitTime, function()
                ForceCollect()
            end)
        else
            -- Nếu thời gian quá gấp (dưới 1s) hoặc không tìm thấy số, nhặt ngay lập tức
            ForceCollect()
        end
    end
end

-- Quét toàn bộ TextLabel đang có trên màn hình
for _, gui in ipairs(PlayerGui:GetDescendants()) do
    if gui:IsA("TextLabel") or gui:IsA("TextButton") then
        gui:GetPropertyChangedSignal("Text"):Connect(function()
            ReadAlert(gui.Text)
        end)
    end
end

-- Quét các thông báo mới hiện ra sau này
PlayerGui.DescendantAdded:Connect(function(child)
    task.wait(0.1)
    if child:IsA("TextLabel") or child:IsA("TextButton") then
        child:GetPropertyChangedSignal("Text"):Connect(function()
            ReadAlert(child.Text)
        end)
        ReadAlert(child.Text)
    end
end)

-- Thông báo kích hoạt
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Virtual Input Bypassed",
    Text = "Đã dùng lệnh giả lập bàn phím để trị Executor lởm!",
    Duration = 5
})
