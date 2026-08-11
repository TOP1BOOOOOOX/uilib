local runService = game:GetService("RunService")
local players = game:GetService("Players")
local localPlayer = players.LocalPlayer
local camera = workspace.CurrentCamera

local playerData = {}

-- Wait until the camera is fully initialised (sometimes it's not ready immediately)
while not camera or not camera.ViewportSize do
    task.wait(0.1)
end

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
        healthText = Drawing.new("Text"),
    }
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
    d.nameText.Font = Drawing.Fonts.Monospace
    d.nameText.Size = 13
    d.nameOutline.Font = Drawing.Fonts.Monospace
    d.nameOutline.Size = 13
    d.healthText.Font = Drawing.Fonts.Monospace
    d.healthText.Size = 13
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

local function worldToScreen(pos)
    -- This function always returns a Vector3 (screen coords) with .X,.Y,.Z and a boolean onScreen.
    -- In some games, WorldToViewportPoint may return false; we return a dummy offscreen point then.
    local result = camera:WorldToViewportPoint(pos)
    if type(result) == "boolean" then
        -- point is invalid (behind camera or too far)
        return Vector3.new(-9999, -9999, -9999), false
    end
    return result, true
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

        -- Create drawings if new player
        if not playerData[player.Name] then
            playerData[player.Name] = createDrawings(player.Name)
        end
        local d = playerData[player.Name]

        -- Simple bounding box: top = head top, bottom = root - 2 studs, left/right = root ± 1.5 studs
        local topPos = head.Position + Vector3.new(0, head.Size.Y/2, 0)
        local bottomPos = root.Position - Vector3.new(0, 2, 0)
        local leftPos = root.Position - Vector3.new(1.5, 0, 0)
        local rightPos = root.Position + Vector3.new(1.5, 0, 0)
        local rootPos = root.Position

        local corners = {
            topPos, bottomPos, leftPos, rightPos, rootPos
        }

        local minX, minY = math.huge, math.huge
        local maxX, maxY = -math.huge, -math.huge
        local allOnScreen = true

        for i, pos in ipairs(corners) do
            local screen, onScreen = worldToScreen(pos)
            if onScreen then
                minX = math.min(minX, screen.X)
                maxX = math.max(maxX, screen.X)
                minY = math.min(minY, screen.Y)
                maxY = math.max(maxY, screen.Y)
            else
                allOnScreen = false
                print("Point off screen for", player.Name, "index", i)
            end
        end

        -- If no valid points, hide everything and skip
        if minX == math.huge or minY == math.huge then
            for k, v in pairs(d) do v.Visible = false end
            continue
        end

        local boxWidth = maxX - minX
        local boxHeight = maxY - minY

        -- Print for debugging
        print(player.Name, "box size:", math.floor(boxWidth), math.floor(boxHeight), "onscreen:", allOnScreen)

        if boxWidth <= 0 or boxHeight <= 0 then
            for k, v in pairs(d) do v.Visible = false end
            continue
        end

        -- Draw box
        d.box.Visible = true
        d.box.Size = Vector2.new(boxWidth, boxHeight)
        d.box.Position = Vector2.new(minX, minY)

        d.boxOutline.Visible = true
        d.boxOutline.Size = d.box.Size
        d.boxOutline.Position = d.box.Position + Vector2.new(1,1)
        d.boxOutline.Color = Color3.new(0,0,0)

        d.boxFill.Visible = true
        d.boxFill.Size = d.box.Size
        d.boxFill.Position = d.box.Position
        d.boxFill.Color = Color3.fromRGB(30,30,30)
        d.boxFill.Transparency = 0.8

        -- Name / distance
        local dist = math.floor((rootPos - camera.CFrame.Position).Magnitude / 3)
        local nameStr = player.Name
        if string.len(nameStr) > 12 then nameStr = string.sub(nameStr, 1, 12) .. ".." end
        local label = nameStr .. " [" .. dist .. "m]"

        d.nameText.Visible = true
        d.nameText.Text = label
        d.nameText.Position = Vector2.new(minX + boxWidth/2 - d.nameText.TextBounds.X/2, minY - 20)
        d.nameText.Color = Color3.new(1,1,1)

        d.nameOutline.Visible = true
        d.nameOutline.Text = label
        d.nameOutline.Position = d.nameText.Position + Vector2.new(1,1)
        d.nameOutline.Color = Color3.new(0,0,0)

        -- Health bar
        local health = humanoid.Health
        local maxHealth = humanoid.MaxHealth
        local healthPct = health / maxHealth
        d.healthBar.Visible = true
        d.healthBarBg.Visible = true
        d.healthBar.Size = Vector2.new(2, math.floor(-healthPct * (boxHeight + 2) + 2))
        d.healthBar.Position = Vector2.new(minX - 4, minY + boxHeight)
        d.healthBar.Color = Color3.new(1,0,0):Lerp(Color3.new(0,1,0), healthPct)
        d.healthBarBg.Size = Vector2.new(2, math.floor(-1 * (boxHeight + 2) + 2))
        d.healthBarBg.Position = d.healthBar.Position
        d.healthBarOutline.Size = Vector2.new(2, boxHeight)
        d.healthBarOutline.Position = Vector2.new(minX - 3, minY + 1)
        d.healthBarOutline.Color = Color3.new(0,0,0)

        -- Health text
        d.healthText.Visible = true
        d.healthText.Text = tostring(math.floor(health))
        d.healthText.Position = Vector2.new(minX - 3, d.healthBar.Position.Y + d.healthBar.Size.Y - d.healthText.TextBounds.Y + 3)
        d.healthText.Color = d.healthBar.Color
    end

    -- Remove drawings for players who left
    for name, _ in pairs(playerData) do
        if not players:FindFirstChild(name) then
            removePlayer(name)
        end
    end
end

runService:BindToRenderStep("SimpleESP", 999, update)
