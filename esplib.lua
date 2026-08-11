local runService = game:GetService('RunService')
local coregui = game:GetService('CoreGui')
local players = game:GetService('Players')
local localPlayer = players.LocalPlayer
local camera = workspace.CurrentCamera

local esp = {
    debug = true,   -- prints status of every player each frame
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

    team_chams = { false, Color3.new(1, 1, 1), Color3.new(1, 1, 1), .25, .75, true },
    team_boxes = { false, Color3.new(), Color3.new(), 0.95 },
    team_healthbar = { false, Color3.new(), Color3.new() },
    team_kevlarbar = { false, Color3.new(), Color3.new() },
    team_arrow = { false, Color3.new(), 0.5 },
    team_names = { false, Color3.new()},
    team_weapon = { false, Color3.new()},
    team_distance = false,
    team_health = false,

    enemy_chams = { false, Color3.new(1, 1, 1), Color3.new(1, 1, 1), .25, .75, true },
    enemy_boxes = { false, Color3.new(), Color3.new(), 0.95 },
    enemy_healthbar = { false, Color3.new(), Color3.new() },
    enemy_kevlarbar = { false, Color3.new(), Color3.new() },
    enemy_arrow = { false, Color3.new(), 0.5 },
    enemy_names = { false, Color3.new()},
    enemy_weapon = { false, Color3.new()},
    enemy_distance = false,
    enemy_health = false,

    priority_chams = { false, Color3.new(1, 1, 1), Color3.new(1, 1, 1), .25, .75, true },
    priority_boxes = { false, Color3.new(), Color3.new(), 0.95 },
    priority_healthbar = { false, Color3.new(), Color3.new() },
    priority_kevlarbar = { false, Color3.new(), Color3.new() },
    priority_arrow = { false, Color3.new(), 0.5 },
    priority_names = { false, Color3.new()},
    priority_weapon = { false, Color3.new()},
    priority_distance = false,
    priority_health = false,

    font = 'Plex',
    textsize = 13,

    players = {},
    priority_players = {},
    connections = {},
    visiblecheckparams = {}
}

-- local shortcuts
local NEWCF     = CFrame.new
local NEWVEC2   = Vector2.new
local NEWCOLOR3 = Color3.new
local MIN       = math.min
local MAX       = math.max
local ATAN2     = math.atan2
local CLAMP     = math.clamp
local FLOOR     = math.floor
local SIN       = math.sin
local COS       = math.cos
local RAD       = math.rad
local LEN       = string.len
local LOWER     = string.lower
local SUB       = string.sub
local TINSERT   = table.insert
local TFIND     = table.find

-- helper functions (unchanged except safety)
function esp:draw(a, b)
    local instance = Drawing.new(a)
    if type(b) == 'table' then
        for property, value in next, b do
            instance[property] = value
        end
    end
    return instance
end

function esp:create(a, b)
    local instance = Instance.new(a)
    if type(b) == 'table' then
        for property, value in next, b do
            instance[property] = value
        end
    end
    return instance
end

local folder = esp:create('Folder', { Parent = coregui })

function esp:raycast(a, b, c)
    c = type(c) == 'table' and c or {}
    local params = RaycastParams.new()
    params.IgnoreWater = true
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = c
    local ray = workspace:Raycast(a, b, params)
    if ray ~= nil and ray.Instance.Transparency >= .250 then
        TINSERT(c, ray.Instance)
        local newray = self:raycast(a,b,c)
        if newray ~= nil then ray = newray end
    end
    return ray
end

function esp.getcharacter(plr)
    return plr.Character
end

function esp.checkalive(plr)
    if not plr then plr = localPlayer end
    local char = plr.Character
    return char and char:FindFirstChild('Humanoid') and char:FindFirstChild('Head') and char.Humanoid.Health > 0
end

function esp.checkteam(plr, bool)
    if not plr then plr = localPlayer end
    return plr ~= localPlayer and bool or plr.Team ~= localPlayer.Team
end

function esp:check(plr)
    if plr == players.LocalPlayer then return false end
    local character = self.getcharacter(plr)
    if not self.checkalive(plr) then return false end
    if esp.limitdistance and (character.PrimaryPart.CFrame.p - camera.CFrame.p).magnitude > esp.maxdistance then
        return false
    end
    if esp.teamcheck and not self.checkteam(plr, false) then return false end
    if esp.visiblecheck and not self:checkvisible(character, character.Head, esp.visiblecheckparams) then
        return false
    end
    return true
end

function esp:returnoffsets(x, y, minY, z)
    return {
        NEWCF(x, y, z), NEWCF(-x, y, z),
        NEWCF(x, y, -z), NEWCF(-x, y, -z),
        NEWCF(x, -minY, z), NEWCF(-x, -minY, z),
        NEWCF(x, -minY, -z), NEWCF(-x, -minY, -z)
    }
end

function esp:returntriangleoffsets(triangle)
    local minX = MIN(triangle.PointA.X, triangle.PointB.X, triangle.PointC.X)
    local minY = MIN(triangle.PointA.Y, triangle.PointB.Y, triangle.PointC.Y)
    local maxX = MAX(triangle.PointA.X, triangle.PointB.X, triangle.PointC.X)
    local maxY = MAX(triangle.PointA.Y, triangle.PointB.Y, triangle.PointC.Y)
    return minX, minY, maxX, maxY
end

function esp:convertnumrange(val, oldmin, oldmax, newmin, newmax)
    return (val - oldmin) * (newmax - newmin) / (oldmax - oldmin) + newmin
end

function esp:fadeviadistance(data)
    return data.limit and 1 - CLAMP(self:convertnumrange(FLOOR((data.cframe.p - camera.CFrame.p).magnitude), (data.maxdistance - data.factor), data.maxdistance, 0, 1), 0, 1) or 1
end

function esp:floorvector(vector)
    return NEWVEC2(FLOOR(vector.X), FLOOR(vector.Y))
end

function esp:rotatevector2(v2, r)
    local c = COS(r)
    local s = SIN(r)
    return NEWVEC2(c * v2.X - s * v2.Y, s * v2.X + c * v2.Y)
end

function esp:add(plr)
    if plr == localPlayer then return end
    local objs = {
        box_fill = esp:draw('Square', { Filled = true, Thickness = 1 }),
        box_outline = esp:draw('Square', { Filled = false, Thickness = 1 }),
        box = esp:draw('Square', { Filled = false, Thickness = 1, Color = NEWCOLOR3(1,1,1) }),
        arrow = esp:draw('Triangle', { Filled = true, Thickness = 1 }),
        bar_outline = esp:draw('Square', { Filled = true, Thickness = 1 }),
        bar_inline = esp:draw('Square', { Filled = true, Thickness = 1, Color = NEWCOLOR3(0.3,0.3,0.3) }),
        bar = esp:draw('Square', { Filled = true, Thickness = 1, Color = NEWCOLOR3(1,1,1) }),
        kevlarbar_outline = esp:draw('Square', { Filled = true, Thickness = 1 }),
        kevlarbar_inline = esp:draw('Square', { Filled = true, Thickness = 1, Color = NEWCOLOR3(0.3,0.3,0.3) }),
        kevlarbar = esp:draw('Square', { Filled = true, Thickness = 1, Color = NEWCOLOR3(1,1,1) }),
        name_outline = esp:draw('Text', { Color = NEWCOLOR3(), Font = 2, Size = 13 }),
        name = esp:draw('Text', { Color = NEWCOLOR3(1,1,1), Font = 2, Size = 13 }),
        distance_outline = esp:draw('Text', { Color = NEWCOLOR3(), Font = 2, Size = 13 }),
        distance = esp:draw('Text', { Color = NEWCOLOR3(1,1,1), Font = 2, Size = 13 }),
        weapon_outline = esp:draw('Text', { Color = NEWCOLOR3(), Font = 2, Size = 13 }),
        weapon = esp:draw('Text', { Color = NEWCOLOR3(1,1,1), Font = 2, Size = 13 }),
        health = esp:draw('Text', { Color = NEWCOLOR3(1,1,1), Font = 2, Size = 13, Center = true }),
        chams = { ins = esp:create('Highlight', { Name = plr.Name }) }
    }
    function objs.chams:Remove() objs.chams.ins:Destroy() end
    self.players[plr.Name] = objs
end

function esp:disable(plr)
    local objects = self.players[plr.Name]
    if objects then
        for i, v in next, objects do
            if i == 'chams' then
                v.ins.Enabled = false
            else
                v.Visible = false
            end
        end
    end
end

function esp:remove(plr)
    local objects = self.players[plr.Name]
    if objects then
        for i, v in next, objects do v:Remove() end
    end
    self.players[plr.Name] = nil
end

function esp:connect(a, callback)
    local c = a:Connect(callback)
    TINSERT(self.connections, c)
    return c
end

function esp:bindtorenderstep(name, priority, callback)
    local a = {}
    function a:Disconnect() runService:UnbindFromRenderStep(name) end
    runService:BindToRenderStep(name, priority, callback)
    TINSERT(self.connections, a)
    return a
end

function esp:clearconnections()
    for _, c in next, self.connections do c:Disconnect() end
end

function esp:update()
    for plr, drawing in next, esp.players do
        local player = players:FindFirstChild(plr)
        if not player then
            if esp.debug then print("[ESP] "..plr.." left") end
            esp.players[plr] = nil
            continue
        end

        if not esp.enabled or not esp.checkalive(player) then
            esp:disable(player)
            continue
        end

        local character = esp.getcharacter(player)
        if not character or not character:FindFirstChild('HumanoidRootPart') then
            esp:disable(player)
            continue
        end

        local pass = esp:check(player)
        local centerMassPos = character.HumanoidRootPart.CFrame
        local screenPos, onScreen = camera:WorldToViewportPoint(character.HumanoidRootPart.Position)
        local distance = tostring(FLOOR((centerMassPos.p - camera.CFrame.p).Magnitude / 3)) .. 'm'

        local flag = 'team_'
        if esp.checkteam(player, false) then flag = 'enemy_' end
        if TFIND(esp.priority_players, player) then flag = 'priority_' end

        if esp.debug then
            print(string.format("[ESP] %s | pass=%s onScreen=%s dist=%s flag=%s", plr, tostring(pass), tostring(onScreen), distance, flag))
        end

        if not (pass and onScreen) then
            esp:disable(player)
        end

        -- arrows (always show if pass)
        drawing.arrow.Visible = esp[flag..'arrow'][1] and pass
        if drawing.arrow.Visible then
            local proj = camera.CFrame:PointToObjectSpace(centerMassPos.p)
            local ang = ATAN2(proj.Z, proj.X)
            local dir = NEWVEC2(COS(ang), SIN(ang))
            local a = (dir * esp.arrowradius * .5) + camera.ViewportSize / 2
            local b = a - esp:rotatevector2(dir, RAD(30)) * esp.arrowsize
            local c = a - esp:rotatevector2(dir, -RAD(30)) * esp.arrowsize
            drawing.arrow.PointA = a; drawing.arrow.PointB = b; drawing.arrow.PointC = c
            drawing.arrow.Color = esp[flag..'arrow'][2]
            drawing.arrow.Transparency = not onScreen and esp[flag..'arrow'][3] or 0
        end

        -- chams
        drawing.chams.ins.Enabled = esp[flag..'chams'][1] and pass
        drawing.chams.ins.Adornee = drawing.chams.ins.Enabled and character or nil
        drawing.chams.ins.Parent = folder
        if drawing.chams.ins.Enabled then
            drawing.chams.ins.FillColor = esp[flag..'chams'][2]
            drawing.chams.ins.OutlineColor = esp[flag..'chams'][3]
            drawing.chams.ins.FillTransparency = esp[flag..'chams'][4]
            drawing.chams.ins.OutlineTransparency = esp[flag..'chams'][5]
            drawing.chams.ins.DepthMode = esp[flag..'chams'][6] and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
        end

        -- skip 2D if not onScreen or not pass
        if not pass or not onScreen then continue end

        -- SAFE OFFSET: try to get limbs, fallback to fixed size if missing
        local head = character:FindFirstChild('Head')
        local rightHand = character:FindFirstChild('RightHand') or character:FindFirstChild('RightUpperArm')
        local leftHand = character:FindFirstChild('LeftHand') or character:FindFirstChild('LeftUpperArm')
        local rightFoot = character:FindFirstChild('RightFoot') or character:FindFirstChild('RightLowerLeg')
        local leftFoot = character:FindFirstChild('LeftFoot') or character:FindFirstChild('LeftLowerLeg')

        if not (head and rightHand and leftHand and rightFoot and leftFoot) then
            if esp.debug then print("[ESP] "..plr.." missing limbs, using default box") end
            -- use a simple, fixed size box based on head and root distance
            local headPos = head and head.Position or (centerMassPos.p + Vector3.new(0,2,0))
            local y = (centerMassPos.p - headPos).magnitude + (head and head.Size.Y/2 or 1)
            local minY = y * 1.5  -- rough leg length
            local minX = 1.5

            local offsets = esp:returnoffsets(minX, y, minY, character.HumanoidRootPart.Size.Z / 2)
            local smallestX, biggestX, smallestY, biggestY = math.huge, -math.huge, math.huge, -math.huge
            for i, v in next, offsets do
                local pos = camera:WorldToViewportPoint(centerMassPos * v.p)
                if smallestX > pos.X then smallestX = pos.X end
                if biggestX < pos.X then biggestX = pos.X end
                if smallestY > pos.Y then smallestY = pos.Y end
                if biggestY < pos.Y then biggestY = pos.Y end
            end
            drawBoxes(plr, smallestX, smallestY, biggestX, biggestY)
        else
            local y = (centerMassPos.p - head.Position).magnitude + head.Size.Y / 2
            local x1 = (centerMassPos.p - rightHand.Position).magnitude
            local x2 = (centerMassPos.p - leftHand.Position).magnitude
            local minY1 = (centerMassPos.p - rightFoot.Position).magnitude
            local minY2 = (centerMassPos.p - leftFoot.Position).magnitude
            local minY = minY1 > minY2 and minY1 or minY2
            local minX = x1 < x2 and x1 or x2

            local offsets = esp:returnoffsets(minX, y, minY, character.HumanoidRootPart.Size.Z / 2)
            local smallestX, biggestX, smallestY, biggestY = math.huge, -math.huge, math.huge, -math.huge
            for i, v in next, offsets do
                local pos = camera:WorldToViewportPoint(centerMassPos * v.p)
                if smallestX > pos.X then smallestX = pos.X end
                if biggestX < pos.X then biggestX = pos.X end
                if smallestY > pos.Y then smallestY = pos.Y end
                if biggestY < pos.Y then biggestY = pos.Y end
            end
            drawBoxes(plr, smallestX, smallestY, biggestX, biggestY)
        end
    end
end

-- helper to draw all 2D elements after box bounds are known
local function drawBoxes(plr, smallestX, smallestY, biggestX, biggestY)
    local drawing = esp.players[plr]
    if not drawing then return end
    local player = players:FindFirstChild(plr)
    if not player then return end
    local character = esp.getcharacter(player)
    local centerMassPos = character.HumanoidRootPart.CFrame
    local distance = tostring(FLOOR((centerMassPos.p - camera.CFrame.p).Magnitude / 3)) .. 'm'
    local health = FLOOR(character.Humanoid.Health)
    local kevlar = 0
    if player:FindFirstChild('Kevlar') then kevlar = player.Kevlar.Value end
    local transparency = esp:fadeviadistance({
        limit = esp.limitdistance,
        cframe = centerMassPos,
        maxdistance = esp.maxdistance,
        factor = esp.fadefactor
    })
    local flag = 'team_'
    if esp.checkteam(player, false) then flag = 'enemy_' end
    if TFIND(esp.priority_players, player) then flag = 'priority_' end

    local playerName = LEN(plr) > esp.maxchar and esp.shortnames and SUB(plr, 0, esp.maxchar) .. '..' or plr

    -- box
    drawing.box.Visible = esp[flag..'boxes'][1]
    drawing.box_fill.Visible = drawing.box.Visible
    drawing.box_outline.Visible = esp.outlines and drawing.box.Visible
    if drawing.box.Visible then
        drawing.box.Size = esp:floorvector(NEWVEC2(biggestX - smallestX, biggestY - smallestY))
        drawing.box.Position = esp:floorvector(NEWVEC2(smallestX, smallestY))
        drawing.box.Color = esp[flag..'boxes'][2]
        drawing.box.Transparency = transparency
        drawing.box_fill.Size = drawing.box.Size
        drawing.box_fill.Position = drawing.box.Position
        drawing.box_fill.Color = esp[flag..'boxes'][3]
        drawing.box_fill.Transparency = MIN(esp[flag..'boxes'][4], transparency)
        drawing.box_outline.Size = drawing.box.Size
        drawing.box_outline.Position = drawing.box.Position + NEWVEC2(1,1)
        drawing.box_outline.Transparency = transparency
    end

    -- healthbar
    drawing.bar.Visible = esp[flag..'healthbar'][1]
    drawing.bar_inline.Visible = drawing.bar.Visible
    drawing.bar_outline.Visible = esp.outlines and drawing.bar.Visible
    if drawing.bar.Visible then
        drawing.bar.Color = esp[flag..'healthbar'][3]:Lerp(esp[flag..'healthbar'][2], health/100)
        drawing.bar.Size = esp:floorvector(NEWVEC2(1, (-health/100 * (biggestY - smallestY + 2)) + 3))
        drawing.bar.Position = esp:floorvector(NEWVEC2(smallestX - 3, smallestY + drawing.bar_outline.Size.Y))
        drawing.bar.Transparency = transparency
        drawing.bar_inline.Size = esp:floorvector(NEWVEC2(1, (-1 * (biggestY - smallestY + 2)) + 3))
        drawing.bar_inline.Position = drawing.bar.Position
        drawing.bar_inline.Transparency = transparency
        drawing.bar_outline.Size = esp:floorvector(NEWVEC2(1, biggestY - smallestY))
        drawing.bar_outline.Position = esp:floorvector(NEWVEC2(smallestX - 2, smallestY + 1))
        drawing.bar_outline.Transparency = transparency
    end

    -- kevlarbar
    drawing.kevlarbar.Visible = esp[flag..'kevlarbar'][1]
    drawing.kevlarbar_inline.Visible = drawing.kevlarbar.Visible
    drawing.kevlarbar_outline.Visible = esp.outlines and drawing.kevlarbar.Visible
    if drawing.kevlarbar.Visible then
        drawing.kevlarbar.Color = esp[flag..'kevlarbar'][3]:Lerp(esp[flag..'kevlarbar'][2], kevlar/100)
        drawing.kevlarbar.Size = esp:floorvector(NEWVEC2((kevlar/100 * (biggestX - smallestX)), 1))
        drawing.kevlarbar.Position = esp:floorvector(NEWVEC2(smallestX, biggestY + 2))
        drawing.kevlarbar.Transparency = transparency
        drawing.kevlarbar_inline.Size = esp:floorvector(NEWVEC2((1 * (biggestX - smallestX)), 1))
        drawing.kevlarbar_inline.Position = drawing.kevlarbar.Position
        drawing.kevlarbar_inline.Transparency = transparency
        drawing.kevlarbar_outline.Size = esp:floorvector(NEWVEC2(biggestX - smallestX, 1))
        drawing.kevlarbar_outline.Position = esp:floorvector(NEWVEC2(smallestX + 1, biggestY + 3))
        drawing.kevlarbar_outline.Transparency = transparency
    end

    -- distance
    drawing.distance.Visible = not esp[flag..'names'][1] and esp[flag..'distance']
    drawing.distance_outline.Visible = esp.outlines and drawing.distance.Visible
    if drawing.distance.Visible then
        drawing.distance.Text = '['..distance..']'
        drawing.distance.Font = Drawing.Fonts[esp.font]
        drawing.distance.Size = esp.textsize
        drawing.distance.Color = esp[flag..'names'][2]
        drawing.distance.Position = esp:floorvector(NEWVEC2(smallestX + (biggestX - smallestX)/2 - drawing.distance.TextBounds.X/2, smallestY - drawing.distance.TextBounds.Y - 2))
        drawing.distance.Transparency = transparency
        drawing.distance_outline.Text = drawing.distance.Text
        drawing.distance_outline.Font = drawing.distance.Font
        drawing.distance_outline.Size = drawing.distance.Size
        drawing.distance_outline.Position = drawing.distance.Position + NEWVEC2(1,1)
        drawing.distance_outline.Transparency = transparency
    end

    -- name
    drawing.name.Visible = esp[flag..'names'][1]
    drawing.name_outline.Visible = esp.outlines and drawing.name.Visible
    if drawing.name.Visible then
        drawing.name.Text = esp[flag..'distance'] and '['..distance..'] '..playerName or playerName
        drawing.name.Font = Drawing.Fonts[esp.font]
        drawing.name.Size = esp.textsize
        drawing.name.Color = esp[flag..'names'][2]
        drawing.name.Position = esp:floorvector(NEWVEC2(smallestX + (biggestX - smallestX)/2 - drawing.name.TextBounds.X/2, smallestY - drawing.name.TextBounds.Y - 2))
        drawing.name.Transparency = transparency
        drawing.name_outline.Text = drawing.name.Text
        drawing.name_outline.Font = drawing.name.Font
        drawing.name_outline.Size = drawing.name.Size
        drawing.name_outline.Position = drawing.name.Position + NEWVEC2(1,1)
        drawing.name_outline.Transparency = transparency
    end

    -- health text
    drawing.health.Visible = health ~= 100 and health ~= 0 and esp[flag..'health']
    if drawing.health.Visible then
        drawing.health.Text = tostring(health)
        drawing.health.Font = Drawing.Fonts[esp.font]
        drawing.health.Size = esp.textsize
        drawing.health.Outline = esp.outlines
        drawing.health.Color = esp[flag..'healthbar'][3]:Lerp(esp[flag..'healthbar'][2], health/100)
        drawing.health.Position = esp:floorvector(NEWVEC2(smallestX - 3, drawing.bar.Position.Y + drawing.bar.Size.Y - drawing.health.TextBounds.Y + 5))
        drawing.health.Transparency = transparency
    end

    -- weapon (safe)
    drawing.weapon.Visible = esp[flag..'weapon'][1]
    drawing.weapon_outline.Visible = esp.outlines and drawing.weapon.Visible
    if drawing.weapon.Visible then
        local toolName = "None"
        local equipped = character:FindFirstChild("EquippedTool")
        if equipped then toolName = LOWER(equipped.Value) or "None" end
        drawing.weapon.Text = toolName
        drawing.weapon.Font = Drawing.Fonts[esp.font]
        drawing.weapon.Size = esp.textsize
        drawing.weapon.Color = esp[flag..'weapon'][2]
        drawing.weapon.Position = esp:floorvector(NEWVEC2(smallestX + (biggestX - smallestX)/2 - drawing.weapon.TextBounds.X/2, biggestY + 4))
        drawing.weapon.Transparency = transparency
        drawing.weapon_outline.Text = drawing.weapon.Text
        drawing.weapon_outline.Font = drawing.weapon.Font
        drawing.weapon_outline.Size = drawing.weapon.Size
        drawing.weapon_outline.Position = drawing.weapon.Position + NEWVEC2(1,1)
        drawing.weapon_outline.Transparency = transparency
    end
end

-- initialization
for _, plr in next, players:GetPlayers() do
    esp:add(plr)
end
esp:connect(players.PlayerAdded, function(plr) esp:add(plr) end)
esp:connect(players.PlayerRemoving, function(plr) esp:remove(plr) end)
esp:bindtorenderstep('esp', 999, esp.update)

return esp
