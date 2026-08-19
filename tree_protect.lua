if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- 1. Tạo Giao diện Thông báo & Đếm ngược
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ControllerLightningWatcher"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 360, 0, 90)
Frame.Position = UDim2.new(0.5, -180, 0.05, 0)
Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
Frame.BorderSizePixel = 2
Frame.BorderColor3 = Color3.fromRGB(0, 255, 120)
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0.4, 0)
Title.BackgroundTransparency = 1
Title.TextColor3 = Color3.fromRGB(255, 220, 0)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 15
Title.Text = "⚡ TỰ ĐỘNG THU HOẠCH SÉT ĐÁNH ⚡"
Title.Parent = Frame

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -16, 0.55, 0)
Status.Position = UDim2.new(0, 8, 0.4, 0)
Status.BackgroundTransparency = 1
Status.TextColor3 = Color3.fromRGB(200, 255, 200)
Status.Font = Enum.Font.Gotham
Status.TextSize = 13
Status.TextWrapped = true
Status.Text = "🟢 Trạng thái: Đang theo dõi cây & tín hiệu máy chủ..."
Status.Parent = Frame

local isHarvesting = false

-- 2. Hàm cưỡng chế bấm E (Sưu tầm) vào gốc cây của bạn
local function collectTree()
    if isHarvesting then return end
    isHarvesting = true

    print("[AUTO-COLLECT] Đang tự động nhặt/sưu tầm cây!")
    
    for _, prompt in ipairs(Workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") then
            local action = string.lower(prompt.ActionText or "")
            local obj = string.lower(prompt.ObjectText or "")
            
            -- Bắt đúng phím E 'Sưu tầm' hoặc tương tác cây
            if action:find("sưu tầm") or action:find("suu tam") or action:find("collect") or action:find("harvest") or obj:find("cây") or obj:find("cay") then
                prompt.RequiresLineOfSight = false
                prompt.MaxActivationDistance = 99999
                prompt.HoldDuration = 0

                if fireproximityprompt then
                    fireproximityprompt(prompt)
                else
                    prompt:InputHoldBegin()
                    task.wait(0.05)
                    prompt:InputHoldEnd()
                end
            end
        end
    end

    task.wait(1.5)
    isHarvesting = false
end

-- 3. Hàm kích hoạt cảnh báo & hẹn giờ nhặt cây
local isAlerting = false
local function triggerLightningAlert(sourceName, countdown)
    if isAlerting then return end
    isAlerting = true

    Frame.BorderColor3 = Color3.fromRGB(255, 50, 50)
    local timeLeft = countdown or 10

    task.spawn(function()
        for i = timeLeft, 1, -1 do
            Status.TextColor3 = Color3.fromRGB(255, 80, 80)
            Status.Text = string.format("🚨 SÉT ĐÁNH SAU: %d GIÂY!\n(Nguồn: %s)", i, sourceName)
            
            -- Tự động nhặt cây khi còn đúng 1 giây (hoặc nếu thời gian quá gấp thì nhặt ngay)
            if i <= 1 then
                collectTree()
            end
            task.wait(1)
        end

        collectTree() -- Đảm bảo nhặt dứt điểm
        Status.TextColor3 = Color3.fromRGB(255, 255, 100)
        Status.Text = "💥 ĐÃ TỰ ĐỘNG SƯU TẦM CÂY VÀO TÚI ĐỒ!"
        task.wait(3)

        Status.TextColor3 = Color3.fromRGB(200, 255, 200)
        Status.Text = "🟢 Trạng thái: Đang theo dõi cây & tín hiệu máy chủ..."
        Frame.BorderColor3 = Color3.fromRGB(0, 255, 120)
        isAlerting = false
    end)
end

-- 4. Hook trực tiếp vào các Controllers trong ReplicatedStorage.Client.Controllers
task.spawn(function()
    pcall(function()
        for _, module in ipairs(ReplicatedStorage:GetDescendants()) do
            if module:IsA("ModuleScript") then
                local mName = string.lower(module.Name)
                if mName:find("disaster") or mName:find("weather") or mName:find("lightning") or mName:find("event") or mName:find("alert") or mName:find("notification") then
                    local controller = require(module)
                    if type(controller) == "table" then
                        for k, v in pairs(controller) do
                            if type(v) == "function" then
                                local oldFunc = v
                                controller[k] = function(...)
                                    triggerLightningAlert("Controller: " .. module.Name, 10)
                                    return oldFunc(...)
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
end)

-- 5. Lắng nghe mọi tín hiệu RemoteEvent từ Server gửi về
for _, obj in ipairs(game:GetDescendants()) do
    if obj:IsA("RemoteEvent") then
        obj.OnClientEvent:Connect(function(...)
            local eName = string.lower(obj.Name)
            if eName:find("lightning") or eName:find("disaster") or eName:find("weather") or eName:find("storm") or eName:find("alert") or eName:find("set") then
                triggerLightningAlert("Remote: " .. obj.Name, 10)
            end
        end)
    end
end

-- 6. Quét giao diện thông báo màu đỏ xuất hiện ở góc màn hình
PlayerGui.DescendantAdded:Connect(function(child)
    if child:IsA("TextLabel") or child:IsA("TextButton") then
        local checkText = function()
            local t = string.lower(child.Text)
            if t:find("sét") or t:find("báo động") or t:find("thu hoạch") then
                local num = string.match(t, "(%d+)%s*s") or string.match(t, "%-(%d+)") or string.match(t, "(%d+)")
                local sec = tonumber(num) or 10
                triggerLightningAlert("Thông báo GUI", sec)
            end
        end
        child:GetPropertyChangedSignal("Text"):Connect(checkText)
        child:GetPropertyChangedSignal("Visible"):Connect(function()
            if child.Visible then checkText() end
        end)
        checkText()
    end
end)
