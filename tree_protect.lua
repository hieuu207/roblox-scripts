if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- 1. Tạo Giao diện Bảng đếm ngược can thiệp bộ nhớ
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MemoryWatcherGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 380, 0, 110)
Frame.Position = UDim2.new(0.5, -190, 0.05, 0)
Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
Frame.BorderSizePixel = 2
Frame.BorderColor3 = Color3.fromRGB(0, 255, 180)
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0.35, 0)
Title.BackgroundTransparency = 1
Title.TextColor3 = Color3.fromRGB(255, 215, 0)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.Text = "🧠 MEMORY SCANNER (GC & UPVALUES)"
Title.Parent = Frame

local Display = Instance.new("TextLabel")
Display.Size = UDim2.new(1, -20, 0.6, 0)
Display.Position = UDim2.new(0, 10, 0.35, 0)
Display.BackgroundTransparency = 1
Display.TextColor3 = Color3.fromRGB(255, 255, 255)
Display.Font = Enum.Font.GothamMedium
Display.TextSize = 13
Display.TextWrapped = true
Display.Text = "Đang hook vào bộ nhớ của các Script đang chạy..."
Display.Parent = Frame

local function showTime(seconds, scriptSource)
    Display.TextColor3 = Color3.fromRGB(255, 60, 60)
    Display.Text = string.format("⚡ THỜI GIAN SÉT TRONG MÃ NGUỒN: %d GIÂY!\nNguồn Script: %s", math.floor(seconds), tostring(scriptSource))
end

-- 2. Quét Garbage Collector (GC) & Upvalues của toàn bộ hàm đang chạy
local function scanMemory()
    if not getgc or not debug.getupvalues then
        Display.Text = "❌ Executor của bạn không hỗ trợ getgc / debug.getupvalues!"
        return
    end

    for _, obj in pairs(getgc(true)) do
        if type(obj) == "function" and not isexecutorclosure(obj) then
            -- A. Quét các Upvalues (Biến local cấp hàm)
            local upvalues = debug.getupvalues(obj)
            for key, val in pairs(upvalues) do
                if type(val) == "number" and val > 0 and val <= 120 then
                    -- Kiểm tra xem hàm này có chứa các hằng số liên quan đến sét hay không
                    if debug.getconstants then
                        local constants = debug.getconstants(obj)
                        for _, const in pairs(constants) do
                            if type(const) == "string" then
                                local cLower = string.lower(const)
                                if cLower:find("lightning") or cLower:find("strike") or cLower:find("set") or cLower:find("storm") or cLower:find("warn") then
                                    local scriptObj = rawget(getfenv(obj), "script")
                                    local scriptName = scriptObj and scriptObj:GetFullName() or "Internal Function"
                                    showTime(val, scriptName)
                                    return
                                end
                            end
                        end
                    end
                end
            end

            -- B. Quét các Table trong bộ nhớ (State / Module Cache)
            if type(obj) == "table" then
                for k, v in pairs(obj) do
                    local strKey = string.lower(tostring(k))
                    if strKey:find("lightning") or strKey:find("timer") or strKey:find("strike") or strKey:find("countdown") then
                        if type(v) == "number" and v > 0 then
                            showTime(v, "State Table: " .. strKey)
                            return
                        end
                    end
                end
            end
        end
    end
end

-- Chạy vòng lặp quét bộ nhớ liên tục
task.spawn(function()
    while task.wait(0.5) do
        pcall(scanMemory)
    end
end)
