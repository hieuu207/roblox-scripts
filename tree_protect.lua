if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- 1. Tạo Giao diện Cảnh báo Đếm ngược nổi bật
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DisasterAlertGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local AlertFrame = Instance.new("Frame")
AlertFrame.Size = UDim2.new(0, 360, 0, 90)
AlertFrame.Position = UDim2.new(0.5, -180, 0.08, 0)
AlertFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
AlertFrame.BorderSizePixel = 2
AlertFrame.BorderColor3 = Color3.fromRGB(0, 200, 100)
AlertFrame.Active = true
AlertFrame.Draggable = true
AlertFrame.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 8)
Corner.Parent = AlertFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0.4, 0)
Title.BackgroundTransparency = 1
Title.TextColor3 = Color3.fromRGB(255, 220, 0)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.Text = "⚡ HỆ THỐNG THEO DÕI THỜI TIẾT ⚡"
Title.Parent = AlertFrame

local SubText = Instance.new("TextLabel")
SubText.Size = UDim2.new(1, -16, 0.55, 0)
SubText.Position = UDim2.new(0, 8, 0.4, 0)
SubText.BackgroundTransparency = 1
SubText.TextColor3 = Color3.fromRGB(200, 255, 200)
SubText.Font = Enum.Font.Gotham
SubText.TextSize = 14
SubText.TextWrapped = true
SubText.Text = "🟢 Trạng thái: An toàn (Không có sét)"
SubText.Parent = AlertFrame

local isAlerting = false

-- 2. Hàm kích hoạt đếm ngược
local function triggerCountdown(duration, sourceName)
    if isAlerting then return end
    isAlerting = true

    AlertFrame.BorderColor3 = Color3.fromRGB(255, 50, 50)
    
    task.spawn(function()
        for i = duration, 1, -1 do
            SubText.TextColor3 = Color3.fromRGB(255, 80, 80)
            SubText.Text = string.format("🚨 SÉT ĐÁNH SAU: %d GIÂY!\n(Nguồn: %s)", i, sourceName or "Hệ thống")
            task.wait(1)
        end
        SubText.TextColor3 = Color3.fromRGB(255, 255, 100)
        SubText.Text = "💥 SÉT ĐANG ĐÁNH! Chờ an toàn..."
        task.wait(3)

        SubText.TextColor3 = Color3.fromRGB(200, 255, 200)
        SubText.Text = "🟢 Trạng thái: An toàn (Đang quét...)"
        AlertFrame.BorderColor3 = Color3.fromRGB(0, 200, 100)
        isAlerting = false
    end)
end

-- 3. Cơ chế 1: Quét các biến đếm thời gian (IntValue, NumberValue, StringValue) trong game
local function checkValueObject(val)
    if val:IsA("ValueBase") then
        local name = string.lower(val.Name)
        if name:find("event") or name:find("weather") or name:find("lightning") or name:find("disaster") or name:find("storm") or name:find("timer") then
            val:GetPropertyChangedSignal("Value"):Connect(function()
                local valStr = tostring(val.Value):lower()
                if valStr:find("lightning") or valStr:find("sét") or valStr:find("strike") then
                    triggerCountdown(10, "Value: " .. val.Name)
                end
            end)
        end
    end
end

for _, v in ipairs(ReplicatedStorage:GetDescendants()) do checkValueObject(v) end
ReplicatedStorage.DescendantAdded:Connect(checkValueObject)

for _, v in ipairs(Workspace:GetDescendants()) do checkValueObject(v) end
Workspace.DescendantAdded:Connect(checkValueObject)

-- 4. Cơ chế 2: Bắt gói tin RemoteEvent từ Server gửi về máy
for _, obj in ipairs(game:GetDescendants()) do
    if obj:IsA("RemoteEvent") then
        obj.OnClientEvent:Connect(function(...)
            local eventName = string.lower(obj.Name)
            if eventName:find("lightning") or eventName:find("weather") or eventName:find("disaster") or eventName:find("alert") or eventName:find("warn") or eventName:find("set") then
                triggerCountdown(10, "Remote: " .. obj.Name)
            end
        end)
    end
end

-- 5. Cơ chế 3: Quét mọi UI hiện lên màn hình
PlayerGui.DescendantAdded:Connect(function(child)
    if child:IsA("TextLabel") or child:IsA("TextButton") then
        local check = function()
            local text = string.lower(child.Text)
            if text:find("sét") or text:find("báo động") or text:find("lightning") or text:find("thu hoạch") then
                local num = string.match(text, "(%d+)%s*s") or string.match(text, "%-(%d+)") or string.match(text, "(%d+)")
                local sec = tonumber(num) or 10
                triggerCountdown(sec, "Giao diện Text")
            end
        end
        child:GetPropertyChangedSignal("Text"):Connect(check)
        child:GetPropertyChangedSignal("Visible"):Connect(function()
            if child.Visible then check() end
        end)
        check()
    end
end)
