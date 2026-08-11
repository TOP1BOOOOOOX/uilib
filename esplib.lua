local runService = game:GetService("RunService")
local players = game:GetService("Players")
local localPlayer = players.LocalPlayer
local camera = workspace.CurrentCamera

-- Set your preferences
local teamCheck = false          -- true = only enemies
local outlines = true
local fontSize = 13
local font = Drawing.Fonts.Monospace

-- Store drawings per player
local playerData = {}

local function createDrawings(name)
    local d = {
        box = Drawing.new("Square"),
        boxFill = Drawing.new("Square"),
        boxOutline = Drawing.new("Square"),
        nameText = Drawing.new("Text"),
        nameOutline = Drawing.new("Text"),
        healthBar = Drawing.new("Square"),
        healthBarBg = Drawing.new("Square"),
        healthBarOutline = Drawing.new("Square"),
        distanceText = Drawing.new("Text"),
        distanceOutline = Drawing.new("Text"),
        healthText = Drawing.new("Text"),
        chams = Instance.new("Highlight")  -- if you want highlights
    }
    d.chams.Name = name
    d.chams.Parent = game:GetService("CoreGui")
    d.box.Filled = false
    d.box.Thickness = 1
    d.box.Color = Color3.new(1,1,1)
    d.boxFill.Filled = true
    d.boxFill.Thickness = 1
    d.boxOutline.Filled = false
    d.boxOutline.Thickness = 1
    d.healthBar.Filled = true
    d.healthBar.Thickness = 1
    d.healthBarBg.Filled = true
    d.healthBarBg.Color = Color3.new(0.3,0.3,0.3)
    d.healthBarOutline.Filled = true
    d.healthBarOutline.Thickness = 1
    d.nameText.Font = font
    d.nameText.Size = fontSize
    d.nameOutline.Font = font
    d.nameOutline.Size = fontSize
    d.distanceText.Font = font
    d.distanceText.Size = fontSize
    d.distanceOutline.Font = font
    d.distanceOutline.Size = fontSize
    d.healthText.Font = font
    d.healthText.Size = fontSize
    d.healthText.Center = true
    return d
end

local function removePlayer(name)
    local d = playerData[name]
    if d then
        for _, v in pairs(d) do
            if v.Remove then v:Remove() end
        end
        playerData[name] = nil
    end
end

local function update()
    for _, player in ipairs(players:GetPlayers()) do
        if player == localPlayer then continue end
        local char = player.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Head") then
            if playerData[player.Name] then removePlayer(player.Name) end
            continue
        end

        local head = char.Head
        local root = char.HumanoidRootPart
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then
            if playerData[player.Name] then removePlayer(player.Name) end
            continue
        end

        -- Team check
        if teamCheck and player.Team == localPlayer.Team then
            if playerData[player.Name] then removePlayer(player.Name) end
            continue
        end

        -- Create drawings if new player
        if not playerData[player.Name] then
            playerData[player.Name] = createDrawings(player.Name)
        end
        local d = playerData[player.Name]

        local rootPos = root.Position
        local headPos = head.Position

        -- Simple box: top = head top, bottom = root bottom, left/right = ±2 studs from root
        local top = headPos + Vector3.new(0, head.Size.Y/2, 0)
        local bottom = rootPos - Vector3.new(0, 2, 0)   -- rough leg estimate
        local left = rootPos - Vector3.new(1.5, 0, 0)
        local right = rootPos + Vector3.new(1.5, 0, 0)

        -- Convert corners to screen
        local corners = {
            camera:WorldToViewportPoint(top),
            camera:WorldToViewportPoint(bottom),
            camera:WorldToViewportPoint(left),
            camera:WorldToViewportPoint(right),
            camera:WorldToViewportPoint(rootPos)
        }

        local minX, minY = math.huge, math.huge
        local maxX, maxY = -math.huge, -math.huge
        for _, pos in ipairs(corners) do
            minX = math.min(minX, pos.X)
            maxX = math.max(maxX, pos.X)
            minY = math.min(minY, pos.Y)
            maxY = math.max(maxY, pos.Y)
        end

        local boxWidth = maxX - minX
        local boxHeight = maxY - minY

        -- Print for debugging
        print(player.Name, "box size:", math.floor(boxWidth), math.floor(boxHeight))

        if boxWidth <= 0 or boxHeight <= 0 then
            -- Hide everything
            for k, v in pairs(d) do
                if k ~= "chams" then v.Visible = false end
            end
            d.chams.Enabled = false
            continue
        end

        -- Draw box
        d.box.Visible = true
        d.box.Size = Vector2.new(boxWidth, boxHeight)
        d.box.Position = Vector2.new(minX, minY)
        d.box.Color = Color3.new(1,1,1)   -- white border

        if outlines then
            d.boxOutline.Visible = true
            d.boxOutline.Size = d.box.Size
            d.boxOutline.Position = d.box.Position + Vector2.new(1,1)
            d.boxOutline.Color = Color3.new(0,0,0)
        end

        d.boxFill.Visible = true
        d.boxFill.Size = d.box.Size
        d.boxFill.Position = d.box.Position
        d.boxFill.Color = Color3.fromRGB(30,30,30)
        d.boxFill.Transparency = 0.8

        -- Name / distance
        local dist = math.floor((rootPos - camera.CFrame.Position).Magnitude / 3)
        local nameStr = player.Name
        if string.len(nameStr) > 10 then nameStr = string.sub(nameStr, 1, 10) .. ".." end
        local label = nameStr .. " [" .. dist .. "m]"

        d.nameText.Visible = true
        d.nameText.Text = label
        d.nameText.Position = Vector2.new(minX + boxWidth/2 - d.nameText.TextBounds.X/2, minY - 20)
        d.nameText.Color = Color3.new(1,1,1)

        if outlines then
            d.nameOutline.Visible = true
            d.nameOutline.Text = label
            d.nameOutline.Position = d.nameText.Position + Vector2.new(1,1)
            d.nameOutline.Color = Color3.new(0,0,0)
        end

        -- Health bar
        local health = humanoid.Health
        local maxHealth = humanoid.MaxHealth
        local healthPct = health / maxHealth
        d.healthBar.Visible = true
        d.healthBarBg.Visible = true
        d.healthBar.Size = Vector2.new(2, -healthPct * (boxHeight + 2) + 2)
        d.healthBar.Position = Vector2.new(minX - 4, minY + boxHeight)
        d.healthBar.Color = Color3.new(1,0,0):Lerp(Color3.new(0,1,0), healthPct)
        d.healthBarBg.Size = Vector2.new(2, -1 * (boxHeight + 2) + 2)
        d.healthBarBg.Position = d.healthBar.Position
        d.healthBarOutline.Size = Vector2.new(2, boxHeight)
        d.healthBarOutline.Position = Vector2.new(minX - 3, minY + 1)
        d.healthBarOutline.Color = Color3.new(0,0,0)

        -- Health text
        d.healthText.Visible = true
        d.healthText.Text = tostring(math.floor(health))
        d.healthText.Position = Vector2.new(minX - 3, d.healthBar.Position.Y + d.healthBar.Size.Y - d.healthText.TextBounds.Y + 3)
        d.healthText.Color = d.healthBar.Color

        -- Chams (optional)
        d.chams.Enabled = true
        d.chams.Adornee = char
        d.chams.FillColor = Color3.new(1,0,0)
        d.chams.OutlineColor = Color3.new(1,0,0)
        d.chams.FillTransparency = 0.5
        d.chams.OutlineTransparency = 0.5
        d.chams.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    end

    -- Remove drawings for players who left
    for name, _ in pairs(playerData) do
        if not players:FindFirstChild(name) then
            removePlayer(name)
        end
    end
end

runService:BindToRenderStep("SimpleESP", 999, update)
