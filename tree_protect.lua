if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- 1. Tạo GUI hiển thị đếm ngược nổi bật
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LightningWatcher"
screenGui.ResetOnSpawn = false
screenGui.Parent = PlayerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 360, 0, 80)
frame.Position = UDim2.new(0.5, -180, 0.05, 0)
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
frame.BorderSizePixel = 3
frame.BorderColor3 = Color3.fromRGB(0, 255, 0)
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui

local txt = Instance.new("TextLabel")
txt.Size = UDim2.new(1, -20, 1, -10)
txt.Position = UDim2.new(0, 10, 0, 5)
txt.BackgroundTransparency = 1
txt.TextColor3 = Color3.fromRGB(255, 255, 255)
txt.Font = Enum.Font.GothamBold
txt.TextSize = 15
txt.TextWrapped = true
txt.Text = "🟢 Trạng thái: Đang theo dõi sét (An toàn)"
txt.Parent = frame

local isTriggered = false
local function onLightningDetected(source)
    if isTriggered then return end
    isTriggered = true
    
    frame.BorderColor3 = Color3.fromRGB(255, 0, 0)
    print("[DETECTED] Phát hiện sét từ: " .. source)
    
    -- Game thường cho 10 giây từ lúc báo động đỏ đến lúc sét rơi
    for i = 10, 1, -1 do
        txt.TextColor3 = Color3.fromRGB(255, 50, 50)
        txt.Text = string.format("⚡ BÁO ĐỘNG SÉT ĐÁNH! ⚡\nĐếm ngược: %d giây còn lại!\n(Nguồn: %s)", i, source)
        task.wait(1)
    end
    
    txt.TextColor3 = Color3.fromRGB(255, 255, 255)
    txt.Text = "💥 SÉT ĐÃ ĐÁNH XONG! Đang theo dõi đợt tiếp theo..."
    frame.BorderColor3 = Color3.fromRGB(0, 255, 0)
    task.wait(3)
    
    isTriggered = false
    txt.Text = "🟢 Trạng thái: Đang theo dõi sét (An toàn)"
end

-- 2. Quét UI theo cơ chế ẨN/HIỆN (Visible / Transparency / CanvasGroup)
local function trackUI(obj)
    if obj:IsA("GuiObject") then
        local lowerName = string.lower(obj.Name)
        -- Kiểm tra tên frame có liên quan đến cảnh báo/sét
        if lowerName:find("alert") or lowerName:find("warn") or lowerName:find("event") or lowerName:find("disaster") or lowerName:find("lightning") or lowerName:find("bao") or lowerName:find("set") then
            obj:GetPropertyChangedSignal("Visible"):Connect(function()
                if obj.Visible then
                    onLightningDetected("UI Frame: " .. obj.Name)
                end
            end)
        end
        
        -- Nếu là TextLabel nhưng bị ẩn và sau đó hiện lên
        if obj:IsA("TextLabel") or obj:IsA("TextButton") then
            local t = string.lower(obj.Text)
            if t:find("báo động") or t:find("sét") or t:find("thu hoạch") then
                obj:GetPropertyChangedSignal("Visible"):Connect(function()
                    if obj.Visible then
                        onLightningDetected("Text Visible: " .. obj.Text)
                    end
                end)
            end
        end
    end
end

for _, v in ipairs(PlayerGui:GetDescendants()) do trackUI(v) end
PlayerGui.DescendantAdded:Connect(trackUI)

-- 3. Theo dõi âm thanh báo động / sấm sét trong Workspace & SoundService
local function trackSound(sound)
    if sound:IsA("Sound") then
        local sName = string.lower(sound.Name)
        if sName:find("alert") or sName:find("warn") or sName:find("thunder") or sName:find("lightning") or sName:find("strike") or sName:find("coi") or sName:find("alarm") then
            sound.Played:Connect(function()
                onLightningDetected("Âm thanh báo động: " .. sound.Name)
            end)
        end
    end
end

for _, s in ipairs(game:GetDescendants()) do trackSound(s) end
game.DescendantAdded:Connect(trackSound)

-- 4. Theo dõi thay đổi bầu trời / ánh sáng (Game thường chớp màn hình hoặc đổi màu khi có thiên tai)
Lighting:GetPropertyChangedSignal("Brightness"):Connect(function()
    if Lighting.Brightness > 5 then
        onLightningDetected("Ánh sáng chớp Lighting")
    end
end)
