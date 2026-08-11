local runService = game:GetService('RunService')
local coregui = game:GetService('CoreGui')
local players = game:GetService('Players')
local localPlayer = players.LocalPlayer
local camera = workspace.CurrentCamera

local esp = {
    enabled = false,
    teamcheck = true,
    visiblecheck = false,
    outlines = true,
    limitdistance = false,
    shortnames = false,
    maxchar = 4,
    maxdistance = 1200,
    fadefactor = 20,
    arrowradius = 500,
    arrowsize = 20,
    arrowinfo = false,
    alwaysShowBoxes = true,   -- show 2D ESP even when off‑screen

    team_chams = { false, Color3.new(1,1,1), Color3.new(1,1,1), .25, .75, true },
    team_boxes = { false, Color3.new(), Color3.new(), 0.95 },
    team_healthbar = { false, Color3.new(), Color3.new() },
    team_kevlarbar = { false, Color3.new(), Color3.new() },
    team_arrow = { false, Color3.new(), 0.5 },
    team_names = { false, Color3.new() },
    team_weapon = { false, Color3.new() },
    team_distance = false,
    team_health = false,

    enemy_chams = { false, Color3.new(1,1,1), Color3.new(1,1,1), .25, .75, true },
    enemy_boxes = { false, Color3.new(), Color3.new(), 0.95 },
    enemy_healthbar = { false, Color3.new(), Color3.new() },
    enemy_kevlarbar = { false, Color3.new(), Color3.new() },
    enemy_arrow = { false, Color3.new(), 0.5 },
    enemy_names = { false, Color3.new() },
    enemy_weapon = { false, Color3.new() },
    enemy_distance = false,
    enemy_health = false,

    priority_chams = { false, Color3.new(1,1,1), Color3.new(1,1,1), .25, .75, true },
    priority_boxes = { false, Color3.new(), Color3.new(), 0.95 },
    priority_healthbar = { false, Color3.new(), Color3.new() },
    priority_kevlarbar = { false, Color3.new(), Color3.new() },
    priority_arrow = { false, Color3.new(), 0.5 },
    priority_names = { false, Color3.new() },
    priority_weapon = { false, Color3.new() },
    priority_distance = false,
    priority_health = false,

    font = 'Plex',
    textsize = 13,
    players = {},
    priority_players = {},
    connections = {}
}

--// Local shortcuts
local NEWVEC2, NEWCF, NEWCOLOR3 = Vector2.new, CFrame.new, Color3.new
local MIN, MAX, FLOOR = math.min, math.max, math.floor
local ATAN2, SIN, COS, RAD = math.atan2, math.sin, math.cos, math.rad
local LEN, LOWER, SUB = string.len, string.lower, string.sub
local TINSERT, TFIND = table.insert, table.find

function esp:draw(className, props)
    local obj = Drawing.new(className)
    for k, v in next, props or {} do obj[k] = v end
    return obj
end

function esp:create(className, props)
    local obj = Instance.new(className)
    for k, v in next, props or {} do obj[k] = v end
    return obj
end

local folder = esp:create('Folder', { Parent = coregui })

function esp.getcharacter(plr) return plr.Character end

function esp.checkalive(plr)
    local char = plr.Character
    return char and char:FindFirstChild('Humanoid') and char:FindFirstChild('Head') and char.Humanoid.Health > 0
end

function esp.checkteam(plr)
    return plr.Team ~= localPlayer.Team
end

function esp:rotatevector2(v2, r)
    local c = COS(r); local s = SIN(r)
    return NEWVEC2(c * v2.X - s * v2.Y, s * v2.X + c * v2.Y)
end

function esp:fadeviadistance(data)
    if not data.limit then return 1 end
    local dist = (data.cframe.p - camera.CFrame.p).Magnitude
    local fadeStart = data.maxdistance - data.factor
    return 1 - math.clamp((dist - fadeStart) / data.factor, 0, 1)
end

--// 2D drawing helper (now defined BEFORE update)
local function drawBoxes(plr, smallestX, smallestY, biggestX, biggestY)
    local drawing = esp.players[plr]
    if not drawing then return end
    local player = players:FindFirstChild(plr)
    if not player then return end
    local character = esp.getcharacter(player)
    if not character or not character:FindFirstChild('HumanoidRootPart') then return end

    local centerMassPos = character.HumanoidRootPart.CFrame
    local distance = FLOOR((centerMassPos.p - camera.CFrame.p).Magnitude / 3) .. 'm'
    local health = FLOOR(character.Humanoid.Health)
    local kevlar = (player:FindFirstChild('Kevlar') and player.Kevlar.Value) or 0
    local transparency = esp:fadeviadistance({
        limit = esp.limitdistance,
        cframe = centerMassPos,
        maxdistance = esp.maxdistance,
        factor = esp.fadefactor
    })

    local flag = 'team_'
    if esp.checkteam(player) then flag = 'enemy_' end
    if TFIND(esp.priority_players, player) then flag = 'priority_' end

    local playerName = LEN(plr) > esp.maxchar and esp.shortnames and SUB(plr, 0, esp.maxchar) .. '..' or plr
    local boxW, boxH = biggestX - smallestX, biggestY - smallestY

    -- Box
    drawing.box.Visible = esp[flag .. 'boxes'][1]
    drawing.box_fill.Visible = drawing.box.Visible
    drawing.box_outline.Visible = esp.outlines and drawing.box.Visible
    if drawing.box.Visible then
        drawing.box.Size = NEWVEC2(FLOOR(boxW), FLOOR(boxH))
        drawing.box.Position = NEWVEC2(FLOOR(smallestX), FLOOR(smallestY))
        drawing.box.Color = esp[flag .. 'boxes'][2]
        drawing.box.Transparency = transparency
        drawing.box_fill.Size = drawing.box.Size
        drawing.box_fill.Position = drawing.box.Position
        drawing.box_fill.Color = esp[flag .. 'boxes'][3]
        drawing.box_fill.Transparency = MIN(esp[flag .. 'boxes'][4], transparency)
        drawing.box_outline.Size = drawing.box.Size
        drawing.box_outline.Position = drawing.box.Position + NEWVEC2(1,1)
        drawing.box_outline.Transparency = transparency
    end

    -- Health bar
    drawing.bar.Visible = esp[flag .. 'healthbar'][1]
    drawing.bar_inline.Visible = drawing.bar.Visible
    drawing.bar_outline.Visible = esp.outlines and drawing.bar.Visible
    if drawing.bar.Visible then
        local healthRatio = health / 100
        drawing.bar.Color = esp[flag .. 'healthbar'][3]:Lerp(esp[flag .. 'healthbar'][2], healthRatio)
        drawing.bar.Size = NEWVEC2(1, FLOOR(-healthRatio * (boxH + 2)) + 3)
        drawing.bar.Position = NEWVEC2(FLOOR(smallestX - 3), FLOOR(smallestY + boxH))
        drawing.bar.Transparency = transparency
        drawing.bar_inline.Size = NEWVEC2(1, FLOOR(-1 * (boxH + 2)) + 3)
        drawing.bar_inline.Position = drawing.bar.Position
        drawing.bar_inline.Transparency = transparency
        drawing.bar_outline.Size = NEWVEC2(1, FLOOR(boxH))
        drawing.bar_outline.Position = NEWVEC2(FLOOR(smallestX - 2), FLOOR(smallestY + 1))
        drawing.bar_outline.Transparency = transparency
    end

    -- Kevlar bar
    drawing.kevlarbar.Visible = esp[flag .. 'kevlarbar'][1]
    drawing.kevlarbar_inline.Visible = drawing.kevlarbar.Visible
    drawing.kevlarbar_outline.Visible = esp.outlines and drawing.kevlarbar.Visible
    if drawing.kevlarbar.Visible then
        local kevlarRatio = kevlar / 100
        drawing.kevlarbar.Color = esp[flag .. 'kevlarbar'][3]:Lerp(esp[flag .. 'kevlarbar'][2], kevlarRatio)
        drawing.kevlarbar.Size = NEWVEC2(FLOOR(kevlarRatio * boxW), 1)
        drawing.kevlarbar.Position = NEWVEC2(FLOOR(smallestX), FLOOR(biggestY + 2))
        drawing.kevlarbar.Transparency = transparency
        drawing.kevlarbar_inline.Size = NEWVEC2(FLOOR(boxW), 1)
        drawing.kevlarbar_inline.Position = drawing.kevlarbar.Position
        drawing.kevlarbar_inline.Transparency = transparency
        drawing.kevlarbar_outline.Size = NEWVEC2(FLOOR(boxW), 1)
        drawing.kevlarbar_outline.Position = NEWVEC2(FLOOR(smallestX + 1), FLOOR(biggestY + 3))
        drawing.kevlarbar_outline.Transparency = transparency
    end

    -- Name / Distance text
    local showName = esp[flag .. 'names'][1]
    local showDist = esp[flag .. 'distance']
    drawing.name.Visible = showName
    drawing.name_outline.Visible = esp.outlines and showName
    drawing.distance.Visible = not showName and showDist
    drawing.distance_outline.Visible = esp.outlines and drawing.distance.Visible

    local topText = showName and (showDist and '['..distance..'] '..playerName or playerName) or nil
    local distText = drawing.distance.Visible and '['..distance..']' or nil

    if topText then
        drawing.name.Text = topText
        drawing.name.Font = Drawing.Fonts[esp.font]
        drawing.name.Size = esp.textsize
        drawing.name.Color = esp[flag .. 'names'][2]
        local tb = drawing.name.TextBounds
        drawing.name.Position = NEWVEC2(FLOOR(smallestX + boxW/2 - tb.X/2), FLOOR(smallestY - tb.Y - 2))
        drawing.name.Transparency = transparency
        drawing.name_outline.Text = topText
        drawing.name_outline.Font = drawing.name.Font
        drawing.name_outline.Size = drawing.name.Size
        drawing.name_outline.Position = drawing.name.Position + NEWVEC2(1,1)
        drawing.name_outline.Transparency = transparency
    elseif distText then
        drawing.distance.Text = distText
        drawing.distance.Font = Drawing.Fonts[esp.font]
        drawing.distance.Size = esp.textsize
        drawing.distance.Color = esp[flag .. 'names'][2]
        local tb = drawing.distance.TextBounds
        drawing.distance.Position = NEWVEC2(FLOOR(smallestX + boxW/2 - tb.X/2), FLOOR(smallestY - tb.Y - 2))
        drawing.distance.Transparency = transparency
        drawing.distance_outline.Text = distText
        drawing.distance_outline.Font = drawing.distance.Font
        drawing.distance_outline.Size = drawing.distance.Size
        drawing.distance_outline.Position = drawing.distance.Position + NEWVEC2(1,1)
        drawing.distance_outline.Transparency = transparency
    end

    -- Health number
    drawing.health.Visible = health ~= 100 and health ~= 0 and esp[flag .. 'health']
    if drawing.health.Visible then
        drawing.health.Text = tostring(health)
        drawing.health.Font = Drawing.Fonts[esp.font]
        drawing.health.Size = esp.textsize
        drawing.health.Outline = esp.outlines
        drawing.health.Color = esp[flag .. 'healthbar'][3]:Lerp(esp[flag .. 'healthbar'][2], health/100)
        drawing.health.Position = NEWVEC2(FLOOR(smallestX - 3), FLOOR(drawing.bar.Position.Y + drawing.bar.Size.Y - drawing.health.TextBounds.Y + 5))
        drawing.health.Transparency = transparency
    end

    -- Weapon (safe)
    drawing.weapon.Visible = esp[flag .. 'weapon'][1]
    drawing.weapon_outline.Visible = esp.outlines and drawing.weapon.Visible
    if drawing.weapon.Visible then
        local toolName = "None"
        local equipped = character:FindFirstChild("EquippedTool")
        if equipped then toolName = LOWER(equipped.Value) or "None" end
        drawing.weapon.Text = toolName
        drawing.weapon.Font = Drawing.Fonts[esp.font]
        drawing.weapon.Size = esp.textsize
        drawing.weapon.Color = esp[flag .. 'weapon'][2]
        local tb = drawing.weapon.TextBounds
        drawing.weapon.Position = NEWVEC2(FLOOR(smallestX + boxW/2 - tb.X/2), FLOOR(biggestY + 4))
        drawing.weapon.Transparency = transparency
        drawing.weapon_outline.Text = toolName
        drawing.weapon_outline.Font = drawing.weapon.Font
        drawing.weapon_outline.Size = drawing.weapon.Size
        drawing.weapon_outline.Position = drawing.weapon.Position + NEWVEC2(1,1)
        drawing.weapon_outline.Transparency = transparency
    end
end

--// Main update loop
function esp:update()
    for name, drawing in next, self.players do
        local player = players:FindFirstChild(name)
        if not player then
            print("[ESP] " .. name .. " left")
            self.players[name] = nil
            continue
        end

        if not self.enabled or not self.checkalive(player) then
            for i, v in next, drawing do
                if i == 'chams' then v.ins.Enabled = false else v.Visible = false end
            end
            continue
        end

        local character = self.getcharacter(player)
        if not character or not character:FindFirstChild('HumanoidRootPart') then continue end

        local pass = (player ~= localPlayer)
        if self.teamcheck and not self.checkteam(player) then pass = false end
        if self.limitdistance then
            local dist = (character.HumanoidRootPart.Position - camera.CFrame.p).Magnitude
            if dist > self.maxdistance then pass = false end
        end

        local root = character.HumanoidRootPart
        local centerMassPos = root.CFrame
        local distance = FLOOR((centerMassPos.p - camera.CFrame.p).Magnitude / 3) .. 'm'
        local screenPos, onScreen = camera:WorldToViewportPoint(root.Position)

        local flag = self.checkteam(player) and 'enemy_' or 'team_'
        if TFIND(self.priority_players, player) then flag = 'priority_' end

        print(string.format("[ESP] %s | pass=%s onScreen=%s dist=%s flag=%s",
            name, tostring(pass), tostring(onScreen), distance, flag))

        -- Disable everything first
        for i, v in next, drawing do
            if i == 'chams' then v.ins.Enabled = false else v.Visible = false end
        end

        -- Chams (always if pass)
        drawing.chams.ins.Enabled = self[flag .. 'chams'][1] and pass
        drawing.chams.ins.Adornee = drawing.chams.ins.Enabled and character or nil
        drawing.chams.ins.Parent = folder
        if drawing.chams.ins.Enabled then
            local cfg = self[flag .. 'chams']
            drawing.chams.ins.FillColor = cfg[2]
            drawing.chams.ins.OutlineColor = cfg[3]
            drawing.chams.ins.FillTransparency = cfg[4]
            drawing.chams.ins.OutlineTransparency = cfg[5]
            drawing.chams.ins.DepthMode = cfg[6] and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
        end

        -- Arrow (off‑screen indicator)
        drawing.arrow.Visible = self[flag .. 'arrow'][1] and pass
        if drawing.arrow.Visible then
            local proj = camera.CFrame:PointToObjectSpace(centerMassPos.p)
            local ang = ATAN2(proj.Z, proj.X)
            local dir = NEWVEC2(COS(ang), SIN(ang))
            local a = (dir * self.arrowradius * .5) + camera.ViewportSize / 2
            local b = a - esp.rotatevector2(dir, RAD(30)) * self.arrowsize
            local c = a - esp.rotatevector2(dir, -RAD(30)) * self.arrowsize
            drawing.arrow.PointA, drawing.arrow.PointB, drawing.arrow.PointC = a, b, c
            drawing.arrow.Color = self[flag .. 'arrow'][2]
            drawing.arrow.Transparency = not onScreen and self[flag .. 'arrow'][3] or 0
        end

        -- 2D ESP (boxes, names) – show if pass AND (onScreen or alwaysShowBoxes)
        local show2D = pass and (onScreen or self.alwaysShowBoxes)
        if not show2D then continue end

        -- Safe box calculation
        local head = character:FindFirstChild('Head')
        local rightHand = character:FindFirstChild('RightHand') or character:FindFirstChild('RightUpperArm')
        local leftHand  = character:FindFirstChild('LeftHand')  or character:FindFirstChild('LeftUpperArm')
        local rightFoot = character:FindFirstChild('RightFoot') or character:FindFirstChild('RightLowerLeg')
        local leftFoot  = character:FindFirstChild('LeftFoot')  or character:FindFirstChild('LeftLowerLeg')

        local y, minY, minX
        if head and rightHand and leftHand and rightFoot and leftFoot then
            y = (centerMassPos.p - head.Position).magnitude + head.Size.Y / 2
            local x1 = (centerMassPos.p - rightHand.Position).magnitude
            local x2 = (centerMassPos.p - leftHand.Position).magnitude
            minY = math.max((centerMassPos.p - rightFoot.Position).magnitude,
                            (centerMassPos.p - leftFoot.Position).magnitude)
            minX = math.min(x1, x2)
        else
            -- fallback for incomplete rig
            local headPos = head and head.Position or (centerMassPos.p + Vector3.new(0,2,0))
            y = (centerMassPos.p - headPos).magnitude + (head and head.Size.Y/2 or 1)
            minY = y * 1.5
            minX = 1.5
        end

        local offsets = {
            NEWCF(minX, y, root.Size.Z/2), NEWCF(-minX, y, root.Size.Z/2),
            NEWCF(minX, y, -root.Size.Z/2), NEWCF(-minX, y, -root.Size.Z/2),
            NEWCF(minX, -minY, root.Size.Z/2), NEWCF(-minX, -minY, root.Size.Z/2),
            NEWCF(minX, -minY, -root.Size.Z/2), NEWCF(-minX, -minY, -root.Size.Z/2)
        }

        local smallestX, biggestX, smallestY, biggestY = math.huge, -math.huge, math.huge, -math.huge
        for _, offset in next, offsets do
            local pos = camera:WorldToViewportPoint(centerMassPos * offset.p)
            smallestX = MIN(smallestX, pos.X)
            biggestX = MAX(biggestX, pos.X)
            smallestY = MIN(smallestY, pos.Y)
            biggestY = MAX(biggestY, pos.Y)
        end

        -- Clamp to screen if off‑screen but alwaysShowBoxes is on
        if not onScreen and self.alwaysShowBoxes then
            local vs = camera.ViewportSize
            smallestX = math.clamp(smallestX, 0, vs.X)
            biggestX = math.clamp(biggestX, 0, vs.X)
            smallestY = math.clamp(smallestY, 0, vs.Y)
            biggestY = math.clamp(biggestY, 0, vs.Y)
        end

        if biggestX - smallestX <= 0 or biggestY - smallestY <= 0 then continue end

        drawBoxes(name, smallestX, smallestY, biggestX, biggestY)
    end
end

--// Player add/remove
function esp:add(plr)
    if plr == localPlayer then return end
    local d = {
        box_fill = self:draw('Square', { Filled = true, Thickness = 1 }),
        box_outline = self:draw('Square', { Filled = false, Thickness = 1 }),
        box = self:draw('Square', { Filled = false, Thickness = 1, Color = NEWCOLOR3(1,1,1) }),
        arrow = self:draw('Triangle', { Filled = true, Thickness = 1 }),
        bar_outline = self:draw('Square', { Filled = true, Thickness = 1 }),
        bar_inline = self:draw('Square', { Filled = true, Thickness = 1, Color = NEWCOLOR3(0.3,0.3,0.3) }),
        bar = self:draw('Square', { Filled = true, Thickness = 1, Color = NEWCOLOR3(1,1,1) }),
        kevlarbar_outline = self:draw('Square', { Filled = true, Thickness = 1 }),
        kevlarbar_inline = self:draw('Square', { Filled = true, Thickness = 1, Color = NEWCOLOR3(0.3,0.3,0.3) }),
        kevlarbar = self:draw('Square', { Filled = true, Thickness = 1, Color = NEWCOLOR3(1,1,1) }),
        name_outline = self:draw('Text', { Color = NEWCOLOR3(), Font = 2, Size = 13 }),
        name = self:draw('Text', { Color = NEWCOLOR3(1,1,1), Font = 2, Size = 13 }),
        distance_outline = self:draw('Text', { Color = NEWCOLOR3(), Font = 2, Size = 13 }),
        distance = self:draw('Text', { Color = NEWCOLOR3(1,1,1), Font = 2, Size = 13 }),
        weapon_outline = self:draw('Text', { Color = NEWCOLOR3(), Font = 2, Size = 13 }),
        weapon = self:draw('Text', { Color = NEWCOLOR3(1,1,1), Font = 2, Size = 13 }),
        health = self:draw('Text', { Color = NEWCOLOR3(1,1,1), Font = 2, Size = 13, Center = true }),
        chams = { ins = self:create('Highlight', { Name = plr.Name }) }
    }
    function d.chams:Remove() d.chams.ins:Destroy() end
    self.players[plr.Name] = d
end

function esp:remove(plr)
    local d = self.players[plr.Name]
    if d then
        for _, v in next, d do
            if type(v) == 'table' and v.Remove then v:Remove()
            elseif type(v) == 'userdata' then v:Remove()
            end
        end
        self.players[plr.Name] = nil
    end
end

--// Initialize
for _, plr in next, players:GetPlayers() do
    esp:add(plr)
end
esp.connections[1] = players.PlayerAdded:Connect(function(plr) esp:add(plr) end)
esp.connections[2] = players.PlayerRemoving:Connect(function(plr) esp:remove(plr) end)
runService:BindToRenderStep('esp', 999, function() esp:update() end)
table.insert(esp.connections, { Disconnect = function() runService:UnbindFromRenderStep('esp') end })

return esp
