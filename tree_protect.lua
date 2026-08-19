-- Chờ game tải xong
if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- Danh sách từ khóa liên quan đến sét / thiên tai / phá cây
local BlockKeywords = {"lightning", "strike", "destroy", "damage", "storm", "burn", "killtree", "set"}

-- 1. Hook chặn RemoteEvents từ Server gửi xuống (hoặc Client gửi lên) liên quan đến sét
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

-- 2. Tự động tìm và xoá Part/Hitbox sét rơi vào vùng cây của bạn trong Workspace
Workspace.DescendantAdded:Connect(function(child)
    task.wait() -- Chờ đối tượng khởi tạo thuộc tính
    local childName = string.lower(tostring(child.Name))
    
    for _, keyword in ipairs(BlockKeywords) do
        if string.find(childName, keyword) then
            -- Vô hiệu hóa hitbox / xóa part sét
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

-- 3. Thông báo kích hoạt thành công
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Anti-Lightning Loaded",
    Text = "Hệ thống bảo vệ cây khỏi sét đánh đã bật!",
    Duration = 5
})
