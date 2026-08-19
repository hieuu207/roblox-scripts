if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- 1. TẠO GIAO DIỆN HIỂN THỊ ĐẾM NGƯỢC RIÊNG
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LightningDetectorGui"
screenGui.ResetOnSpawn = false

-- Thử gắn vào CoreGui, nếu executor không hỗ trợ thì gắn vào PlayerGui
local successParent = pcall(function()
    screenGui.Parent = CoreGui
end)
if not successParent or not screenGui.Parent then
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local alertFrame = Instance.new("Frame")
alertFrame.Size = UDim2.new(0, 320, 0, 90)
alertFrame.Position = UDim2.new(0.5, -160, 0.1, 0)
alertFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
alertFrame.BorderSizePixel = 2
alertFrame.BorderColor3 = Color3.fromRGB(255, 170, 0)
alertFrame.Active = true
alertFrame.Draggable = true
alertFrame.Parent = screenGui

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0.35, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 14
titleLabel.Text = "⚡ TRÌNH BẮT SỰ KIỆN SÉT ⚡"
titleLabel.Parent = alertFrame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -10, 0.6, 0)
statusLabel.Position = UDim2.new(0, 5, 0.35, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 13
statusLabel.TextWrapped = true
statusLabel.Text = "Đang quét tín hiệu máy chủ & giao diện..."
statusLabel.Parent = alertFrame

local lastTrigger = 0

-- Hàm cập nhật giao diện đếm ngược
local function triggerAlert(sourceInfo, countdownSeconds)
    if tick() - lastTrigger < 2 then return end
    lastTrigger = tick()

    alertFrame.BorderColor3 = Color3.fromRGB(255, 0, 0)
    
    task.spawn(function()
        for i = countdownSeconds, 0, -1 do
            statusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
            statusLabel.Text = string.format("🚨 SÉT ĐÁNH TRONG: %d GIÂY!\n(%s)", i, sourceInfo)
            task.wait(1)
        end
        statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        statusLabel.Text = "Đã đánh xong! Đang tiếp tục quét..."
        alertFrame.BorderColor3 = Color3.fromRGB(255, 170, 0)
    end)
end

-- 2. HOOK TOÀN BỘ SỰ KIỆN MẠNG (REMOTE EVENTS) TỪ SERVER VỀ CLIENT
local oldFire
oldFire = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    if (method == "FireServer" or method == "InvokeServer") then
        local name = string.lower(tostring(self.Name))
        if name:find("lightning") or name:find("strike") or name:find("set") or name:find("disaster") or name:find("weather") then
            triggerAlert("Remote: " .. self.Name, 10)
        end
    end

    return oldFire(self, ...)
end)

-- Lắng nghe các OnClientEvent (Server gọi xuống)
for _, obj in ipairs(game:GetDescendants()) do
    if obj:IsA("RemoteEvent") then
        obj.OnClientEvent:Connect(function(...)
            local eventName = string.lower(obj.Name)
            if eventName:find("lightning") or eventName:find("strike") or eventName:find("weather") or eventName:find("event") or eventName:find("warn") or eventName:find("alert") or eventName:find("set") then
                triggerAlert("Server Event: " .. obj.Name, 10)
            end
        end)
    end
end

-- 3. QUÉT TEXT TRÊN TOÀN BỘ CÁC VÙNG BỘ NHỚ
local function checkText(text, location)
    if typeof(text) ~= "string" or text == "" then return end
    local lower = string.lower(text)

    if lower:find("sét") or lower:find("báo động") or lower:find("thu hoạch ngay") or lower:find("sét sắp") then
        local sec = string.match(lower, "(%d+)%s*s") or string.match(lower, "trong%s*(%d+)") or string.match(lower, "%-(%d+)") or string.match(lower, "(%d+)")
        local duration = tonumber(sec) or 10
        triggerAlert("GUI: " .. location, duration)
    end
end

local function watchElement(elem)
    if elem:IsA("TextLabel") or elem:IsA("TextButton") then
        checkText(elem.Text, elem.Name)
        elem:GetPropertyChangedSignal("Text"):Connect(function()
            checkText(elem.Text, elem.Name)
        end)
    end
end

-- Lắng nghe PlayerGui và CoreGui
LocalPlayer:WaitForChild("PlayerGui").DescendantAdded:Connect(watchElement)
for _, elem in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
    watchElement(elem)
end

pcall(function()
    CoreGui.DescendantAdded:Connect(watchElement)
    for _, elem in ipairs(CoreGui:GetDescendants()) do
        watchElement(elem)
    end
end)
