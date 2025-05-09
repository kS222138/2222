-- 依赖服务
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- 存储绘制的对象
local ESPObjects = {}

-- 绘制玩家ESP
local function CreateESP(player)
    if player == LocalPlayer then return end -- 不绘制自己

    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")
    local head = character:WaitForChild("Head")

    -- 方框（Box ESP）
    local box = Drawing.new("Square")
    box.Visible = false
    box.Color = Color3.fromRGB(0, 255, 0) -- 绿色
    box.Thickness = 1
    box.Filled = false

    -- 名字标签（Name Tag）
    local nameTag = Drawing.new("Text")
    nameTag.Visible = false
    nameTag.Text = player.Name
    nameTag.Color = Color3.fromRGB(255, 255, 255)
    nameTag.Size = 16
    nameTag.Center = true
    nameTag.Outline = true

    -- 血量条（Health Bar）
    local healthBar = Drawing.new("Line")
    healthBar.Visible = false
    healthBar.Color = Color3.fromRGB(255, 0, 0) -- 红色
    healthBar.Thickness = 2

    -- 预判点（Aimbot Prediction）
    local predictionDot = Drawing.new("Circle")
    predictionDot.Visible = false
    predictionDot.Color = Color3.fromRGB(255, 255, 0) -- 黄色
    predictionDot.Radius = 5
    predictionDot.Filled = true

    -- 存储到表
    ESPObjects[player] = {
        Box = box,
        NameTag = nameTag,
        HealthBar = healthBar,
        PredictionDot = predictionDot,
        Character = character,
        Humanoid = humanoid,
        Head = head
    }
end

-- 更新ESP位置
local function UpdateESP()
    for player, data in pairs(ESPObjects) do
        if not player.Character or not data.Head then
            -- 玩家已离开或死亡，清除绘制
            for _, drawing in pairs(data) do
                if typeof(drawing) == "userdata" then
                    drawing:Remove()
                end
            end
            ESPObjects[player] = nil
            continue
        end

        -- 计算玩家头部在屏幕上的位置
        local headPos, headOnScreen = Camera:WorldToViewportPoint(data.Head.Position)

        if headOnScreen then
            -- 计算方框大小
            local characterSize = data.Character:GetExtentsSize()
            local scaleFactor = 1000 / (headPos.Z * math.tan(math.rad(Camera.FieldOfView / 2)) * 2

            -- 更新方框
            data.Box.Visible = true
            data.Box.Size = Vector2.new(characterSize.X * scaleFactor, characterSize.Y * scaleFactor)
            data.Box.Position = Vector2.new(headPos.X - data.Box.Size.X / 2, headPos.Y - data.Box.Size.Y / 2)

            -- 更新名字标签
            data.NameTag.Visible = true
            data.NameTag.Position = Vector2.new(headPos.X, headPos.Y - data.Box.Size.Y / 2 - 20)

            -- 更新血量条
            local healthPercent = data.Humanoid.Health / data.Humanoid.MaxHealth
            data.HealthBar.Visible = true
            data.HealthBar.From = Vector2.new(headPos.X - data.Box.Size.X / 2, headPos.Y - data.Box.Size.Y / 2 - 5)
            data.HealthBar.To = Vector2.new(headPos.X - data.Box.Size.X / 2 + data.Box.Size.X * healthPercent, headPos.Y - data.Box.Size.Y / 2 - 5)

            -- 更新预判点（计算提前量）
            local bulletSpeed = 1000 -- 假设子弹速度（需根据游戏调整）
            local distance = (data.Head.Position - Camera.CFrame.Position).Magnitude
            local travelTime = distance / bulletSpeed
            local predictedPosition = data.Head.Position + data.Humanoid.MoveDirection * data.Humanoid.WalkSpeed * travelTime

            local predictedPos, predictedOnScreen = Camera:WorldToViewportPoint(predictedPosition)
            if predictedOnScreen then
                data.PredictionDot.Visible = true
                data.PredictionDot.Position = Vector2.new(predictedPos.X, predictedPos.Y)
            else
                data.PredictionDot.Visible = false
            end
        else
            -- 不在屏幕上，隐藏绘制
            data.Box.Visible = false
            data.NameTag.Visible = false
            data.HealthBar.Visible = false
            data.PredictionDot.Visible = false
        end
    end
end

-- 初始化ESP
for _, player in ipairs(Players:GetPlayers()) do
    CreateESP(player)
end

-- 新玩家加入时创建ESP
Players.PlayerAdded:Connect(CreateESP)

-- 玩家离开时清除ESP
Players.PlayerRemoving:Connect(function(player)
    if ESPObjects[player] then
        for _, drawing in pairs(ESPObjects[player]) do
            if typeof(drawing) == "userdata" then
                drawing:Remove()
            end
        end
        ESPObjects[player] = nil
    end
end)

-- 每帧更新ESP
RunService.RenderStepped:Connect(UpdateESP)