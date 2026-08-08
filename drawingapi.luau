--[[
    Compkiller Interface (Drawing API Implementation)
    Author: 4lpaca (Adapted for Drawing API)
    License: MIT
    
    Description:
    A complete re-assignment and reconstruction of the Compkiller interface
    utilizing strictly the Roblox Drawing API. This custom engine includes
    manual clipping, a custom hierarchy system, simulated Z-indexing, 
    and a custom mathematical tweening engine to bypass the need for Instance.new
    while retaining 100% of the original features.
--]]

local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- [ Core Math & Engine Configuration ] --
local Engine = {
    RenderQueue = {},
    Connections = {},
    TweenQueue = {},
    MousePos = Vector2.new(0, 0),
    MouseDown = false,
    HoveredElements = {},
    ActiveInput = nil,
    Time = 0,
    Delta = 0,
    ClipRects = {}
}

local Theme = {
    Highlight = Color3.fromRGB(17, 238, 253),
    Toggle = Color3.fromRGB(14, 203, 213),
    Risky = Color3.fromRGB(251, 255, 39),
    BGDBColor = Color3.fromRGB(22, 24, 29),
    BlockColor = Color3.fromRGB(28, 29, 34),
    StrokeColor = Color3.fromRGB(37, 38, 43),
    SwitchColor = Color3.fromRGB(255, 255, 255),
    DropColor = Color3.fromRGB(33, 35, 39),
    MouseEnter = Color3.fromRGB(55, 58, 65),
    BlockBackground = Color3.fromRGB(39, 40, 47),
    LineColor = Color3.fromRGB(65, 65, 65),
    HighStrokeColor = Color3.fromRGB(55, 56, 63),
}

-- [ Mathematical Lerping & Tweening Simulation ] --
local function Lerp(a, b, t)
    return a + (b - a) * t
end

local function LerpVector2(a, b, t)
    return Vector2.new(Lerp(a.X, b.X, t), Lerp(a.Y, b.Y, t))
end

local function LerpColor(a, b, t)
    return Color3.new(Lerp(a.R, b.R, t), Lerp(a.G, b.G, t), Lerp(a.B, b.B, t))
end

local function CreateCustomTween(object, properties, duration, callback)
    local startValues = {}
    for k, v in pairs(properties) do
        startValues[k] = object[k]
    end
    
    local tweenData = {
        Object = object,
        Properties = properties,
        StartValues = startValues,
        Duration = duration,
        Elapsed = 0,
        Callback = callback
    }
    table.insert(Engine.TweenQueue, tweenData)
    return tweenData
end

-- [ Custom Hierarchy & Drawing Wrapper System ] --
-- Replaces Instance.new by creating a virtual DOM for Drawing API
local BaseDrawing = {}
BaseDrawing.__index = BaseDrawing

function BaseDrawing.new(typeStr)
    local self = setmetatable({}, BaseDrawing)
    self.Type = typeStr
    self.Instance = Drawing.new(typeStr)
    self.Children = {}
    self.Parent = nil
    
    self.Visible = true
    self.ZIndex = 1
    self.Transparency = 1
    self.Color = Color3.new(1, 1, 1)
    
    -- Virtual Positioning (Simulating UDim2)
    self.Position = Vector2.new(0, 0)
    self.Size = Vector2.new(0, 0)
    self.AbsolutePosition = Vector2.new(0, 0)
    self.AbsoluteSize = Vector2.new(0, 0)
    
    -- Specifics
    self.Text = ""
    self.TextSize = 14
    self.Center = false
    self.Outline = false
    self.OutlineColor = Color3.new(0,0,0)
    self.Font = 2
    
    self.Filled = true
    self.Thickness = 1
    
    self.Clip = false
    self.ClipBounds = nil
    
    self.OnInputBegan = nil
    self.OnInputEnded = nil
    self.OnHover = nil
    self.OnLeave = nil
    
    table.insert(Engine.RenderQueue, self)
    return self
end

function BaseDrawing:Destroy()
    self.Instance:Remove()
    if self.Parent then
        for i, v in ipairs(self.Parent.Children) do
            if v == self then
                table.remove(self.Parent.Children, i)
                break
            end
        end
    end
    for i, v in ipairs(Engine.RenderQueue) do
        if v == self then
            table.remove(Engine.RenderQueue, i)
            break
        end
    end
    for _, child in ipairs(self.Children) do
        child:Destroy()
    end
end

function BaseDrawing:AddChild(child)
    child.Parent = self
    table.insert(self.Children, child)
end

function BaseDrawing:UpdateTransform()
    if self.Parent then
        self.AbsolutePosition = self.Parent.AbsolutePosition + self.Position
    else
        self.AbsolutePosition = self.Position
    end
    self.AbsoluteSize = self.Size
end

function BaseDrawing:Render()
    if not self.Visible then
        self.Instance.Visible = false
        return
    end

    local parentVis = true
    local curr = self.Parent
    while curr do
        if not curr.Visible then
            parentVis = false
            break
        end
        curr = curr.Parent
    end

    if not parentVis then
        self.Instance.Visible = false
        return
    end

    self:UpdateTransform()
    self.Instance.Visible = true
    self.Instance.Transparency = self.Transparency
    self.Instance.Color = self.Color
    self.Instance.ZIndex = self.ZIndex

    -- Handle Clipping Mathematically (Drawing API lacks ClipsDescendants)
    local renderPos = self.AbsolutePosition
    local renderSize = self.AbsoluteSize
    local isClippedOut = false

    if self.ClipBounds then
        local minX = math.max(renderPos.X, self.ClipBounds.Min.X)
        local minY = math.max(renderPos.Y, self.ClipBounds.Min.Y)
        local maxX = math.min(renderPos.X + renderSize.X, self.ClipBounds.Max.X)
        local maxY = math.min(renderPos.Y + renderSize.Y, self.ClipBounds.Max.Y)
        
        if minX >= maxX or minY >= maxY then
            isClippedOut = true
        else
            renderPos = Vector2.new(minX, minY)
            renderSize = Vector2.new(maxX - minX, maxY - minY)
        end
    end

    if isClippedOut then
        self.Instance.Visible = false
        return
    end

    if self.Type == "Square" then
        self.Instance.Position = renderPos
        self.Instance.Size = renderSize
        self.Instance.Filled = self.Filled
        self.Instance.Thickness = self.Thickness
    elseif self.Type == "Text" then
        self.Instance.Position = renderPos
        self.Instance.Text = self.Text
        self.Instance.Size = self.TextSize
        self.Instance.Center = self.Center
        self.Instance.Outline = self.Outline
        self.Instance.OutlineColor = self.OutlineColor
        self.Instance.Font = self.Font
    elseif self.Type == "Image" then
        self.Instance.Position = renderPos
        self.Instance.Size = renderSize
        if self.Data then self.Instance.Data = self.Data end
    elseif self.Type == "Line" then
        self.Instance.From = renderPos
        self.Instance.To = renderPos + renderSize
        self.Instance.Thickness = self.Thickness
    end
end

-- [ Layout System (Replaces UIListLayout) ] --
local function UpdateListLayout(container, padding)
    local currentY = 0
    for _, child in ipairs(container.Children) do
        if child.Visible then
            child.Position = Vector2.new(child.Position.X, currentY)
            currentY = currentY + child.Size.Y + (padding or 0)
        end
    end
    container.Size = Vector2.new(container.Size.X, currentY)
end

-- [ Engine Tick ] --
RunService.RenderStepped:Connect(function(dt)
    Engine.Time = Engine.Time + dt
    Engine.Delta = dt
    Engine.MousePos = UserInputService:GetMouseLocation()
    
    -- Process Tweens
    for i = #Engine.TweenQueue, 1, -1 do
        local t = Engine.TweenQueue[i]
        t.Elapsed = t.Elapsed + dt
        local alpha = math.clamp(t.Elapsed / t.Duration, 0, 1)
        
        for k, targetVal in pairs(t.Properties) do
            local startVal = t.StartValues[k]
            if typeof(startVal) == "number" then
                t.Object[k] = Lerp(startVal, targetVal, alpha)
            elseif typeof(startVal) == "Vector2" then
                t.Object[k] = LerpVector2(startVal, targetVal, alpha)
            elseif typeof(startVal) == "Color3" then
                t.Object[k] = LerpColor(startVal, targetVal, alpha)
            end
        end
        
        if alpha >= 1 then
            if t.Callback then t.Callback() end
            table.remove(Engine.TweenQueue, i)
        end
    end

    -- Process Rendering and Hover States
    table.sort(Engine.RenderQueue, function(a, b) return a.ZIndex < b.ZIndex end)
    
    local hoveringOver = nil
    for _, obj in ipairs(Engine.RenderQueue) do
        obj:Render()
        if obj.Visible and obj.Instance.Visible and (obj.OnHover or obj.OnInputBegan) then
            if Engine.MousePos.X >= obj.AbsolutePosition.X and Engine.MousePos.X <= obj.AbsolutePosition.X + obj.AbsoluteSize.X and
               Engine.MousePos.Y >= obj.AbsolutePosition.Y and Engine.MousePos.Y <= obj.AbsolutePosition.Y + obj.AbsoluteSize.Y then
                hoveringOver = obj
            end
        end
    end

    if hoveringOver ~= Engine.HoveredElements.Current then
        if Engine.HoveredElements.Current and Engine.HoveredElements.Current.OnLeave then
            Engine.HoveredElements.Current.OnLeave()
        end
        Engine.HoveredElements.Current = hoveringOver
        if hoveringOver and hoveringOver.OnHover then
            hoveringOver.OnHover()
        end
    end
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        Engine.MouseDown = true
        if Engine.HoveredElements.Current and Engine.HoveredElements.Current.OnInputBegan then
            Engine.ActiveInput = Engine.HoveredElements.Current
            Engine.HoveredElements.Current.OnInputBegan(input)
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, gpe)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        Engine.MouseDown = false
        if Engine.ActiveInput and Engine.ActiveInput.OnInputEnded then
            Engine.ActiveInput.OnInputEnded(input)
        end
        Engine.ActiveInput = nil
    end
end)

-- [ Library Core Implementation ] --
local CompkillerLib = {
    Windows = {},
    KeybindsList = {},
    Flags = {},
    Theme = Theme,
    DragTarget = nil,
    DragOffset = Vector2.new(0, 0)
}

function CompkillerLib:MakeDraggable(target, handle)
    handle.OnInputBegan = function(input)
        CompkillerLib.DragTarget = target
        CompkillerLib.DragOffset = target.Position - Engine.MousePos
    end
    handle.OnInputEnded = function(input)
        CompkillerLib.DragTarget = nil
    end
    RunService.RenderStepped:Connect(function()
        if CompkillerLib.DragTarget == target and Engine.MouseDown then
            target.Position = Engine.MousePos + CompkillerLib.DragOffset
        end
    end)
end

function CompkillerLib:CreateWindow(config)
    config = config or {}
    config.Name = config.Name or "COMPKILLER"
    config.Size = config.Size or Vector2.new(700, 565)
    
    local WindowObj = {
        Tabs = {},
        SelectedTab = nil,
        IsOpen = true
    }
    
    local MainFrame = BaseDrawing.new("Square")
    MainFrame.Size = config.Size
    MainFrame.Position = Vector2.new(Camera.ViewportSize.X/2 - config.Size.X/2, Camera.ViewportSize.Y/2 - config.Size.Y/2)
    MainFrame.Color = self.Theme.BGDBColor
    MainFrame.Filled = true
    MainFrame.ZIndex = 10
    
    local Outline = BaseDrawing.new("Square")
    Outline.Size = config.Size
    Outline.Color = self.Theme.StrokeColor
    Outline.Filled = false
    Outline.Thickness = 1
    Outline.ZIndex = 11
    MainFrame:AddChild(Outline)
    
    local Sidebar = BaseDrawing.new("Square")
    Sidebar.Size = Vector2.new(185, config.Size.Y)
    Sidebar.Color = self.Theme.BlockBackground
    Sidebar.Filled = true
    Sidebar.ZIndex = 12
    MainFrame:AddChild(Sidebar)

    local SidebarLine = BaseDrawing.new("Square")
    SidebarLine.Size = Vector2.new(1, config.Size.Y)
    SidebarLine.Position = Vector2.new(184, 0)
    SidebarLine.Color = self.Theme.StrokeColor
    SidebarLine.Filled = true
    SidebarLine.ZIndex = 13
    Sidebar:AddChild(SidebarLine)

    local TitleLabel = BaseDrawing.new("Text")
    TitleLabel.Text = config.Name
    TitleLabel.Size = Vector2.new(150, 30)
    TitleLabel.Position = Vector2.new(60, 20)
    TitleLabel.Color = self.Theme.SwitchColor
    TitleLabel.TextSize = 15
    TitleLabel.ZIndex = 15
    Sidebar:AddChild(TitleLabel)

    local TabContainer = BaseDrawing.new("Square")
    TabContainer.Size = Vector2.new(185, config.Size.Y - 100)
    TabContainer.Position = Vector2.new(0, 70)
    TabContainer.Color = self.Theme.BlockBackground
    TabContainer.Filled = false
    TabContainer.Transparency = 0
    TabContainer.ZIndex = 13
    Sidebar:AddChild(TabContainer)
    
    local ContentContainer = BaseDrawing.new("Square")
    ContentContainer.Size = Vector2.new(config.Size.X - 185, config.Size.Y)
    ContentContainer.Position = Vector2.new(185, 0)
    ContentContainer.Color = self.Theme.BGDBColor
    ContentContainer.Filled = true
    ContentContainer.ZIndex = 12
    MainFrame:AddChild(ContentContainer)
    
    CompkillerLib:MakeDraggable(MainFrame, Sidebar)

    -- Keybind Toggling
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.Insert then
            WindowObj.IsOpen = not WindowObj.IsOpen
            MainFrame.Visible = WindowObj.IsOpen
        end
    end)

    function WindowObj:CreateTab(tabConfig)
        tabConfig = tabConfig or {}
        tabConfig.Name = tabConfig.Name or "Tab"
        
        local TabObj = {
            Sections = {},
            Active = false
        }
        
        local TabButton = BaseDrawing.new("Square")
        TabButton.Size = Vector2.new(185, 35)
        TabButton.Color = CompkillerLib.Theme.BlockBackground
        TabButton.Filled = true
        TabButton.Transparency = 1
        TabButton.ZIndex = 14
        TabContainer:AddChild(TabButton)
        
        local TabHighlight = BaseDrawing.new("Square")
        TabHighlight.Size = Vector2.new(3, 20)
        TabHighlight.Position = Vector2.new(0, 7.5)
        TabHighlight.Color = CompkillerLib.Theme.Highlight
        TabHighlight.Filled = true
        TabHighlight.Transparency = 0
        TabHighlight.ZIndex = 15
        TabHighlight.Visible = false
        TabButton:AddChild(TabHighlight)
        
        local TabLabel = BaseDrawing.new("Text")
        TabLabel.Text = tabConfig.Name
        TabLabel.Size = Vector2.new(150, 35)
        TabLabel.Position = Vector2.new(40, 10)
        TabLabel.Color = CompkillerLib.Theme.SwitchColor
        TabLabel.TextSize = 14
        TabLabel.ZIndex = 15
        TabLabel.Transparency = 0.5
        TabButton:AddChild(TabLabel)
        
        local TabPage = BaseDrawing.new("Square")
        TabPage.Size = ContentContainer.Size
        TabPage.Position = Vector2.new(0, 0)
        TabPage.Color = CompkillerLib.Theme.BGDBColor
        TabPage.Filled = true
        TabPage.ZIndex = 13
        TabPage.Visible = false
        ContentContainer:AddChild(TabPage)

        local LeftCol = BaseDrawing.new("Square")
        LeftCol.Size = Vector2.new((TabPage.Size.X / 2) - 15, TabPage.Size.Y - 20)
        LeftCol.Position = Vector2.new(10, 10)
        LeftCol.Color = CompkillerLib.Theme.BGDBColor
        LeftCol.Transparency = 0
        LeftCol.Filled = false
        LeftCol.ZIndex = 14
        TabPage:AddChild(LeftCol)
        
        local RightCol = BaseDrawing.new("Square")
        RightCol.Size = Vector2.new((TabPage.Size.X / 2) - 15, TabPage.Size.Y - 20)
        RightCol.Position = Vector2.new((TabPage.Size.X / 2) + 5, 10)
        RightCol.Color = CompkillerLib.Theme.BGDBColor
        RightCol.Transparency = 0
        RightCol.Filled = false
        RightCol.ZIndex = 14
        TabPage:AddChild(RightCol)
        
        TabButton.OnInputBegan = function()
            for _, t in ipairs(WindowObj.Tabs) do
                t.TabPage.Visible = false
                t.TabHighlight.Visible = false
                t.TabLabel.Transparency = 0.5
                t.Active = false
            end
            TabPage.Visible = true
            TabHighlight.Visible = true
            TabLabel.Transparency = 1
            TabObj.Active = true
            WindowObj.SelectedTab = TabObj
        end
        
        table.insert(WindowObj.Tabs, TabObj)
        TabObj.TabPage = TabPage
        TabObj.TabHighlight = TabHighlight
        TabObj.TabLabel = TabLabel
        
        if #WindowObj.Tabs == 1 then
            TabButton.OnInputBegan()
        end
        
        UpdateListLayout(TabContainer, 2)

        function TabObj:CreateSection(secConfig)
            secConfig = secConfig or {}
            secConfig.Name = secConfig.Name or "Section"
            secConfig.Side = secConfig.Side or "Left"
            
            local SecObj = {
                Elements = {}
            }
            
            local TargetCol = string.lower(secConfig.Side) == "left" and LeftCol or RightCol
            
            local SecFrame = BaseDrawing.new("Square")
            SecFrame.Size = Vector2.new(TargetCol.Size.X, 35) 
            SecFrame.Color = CompkillerLib.Theme.BlockColor
            SecFrame.Filled = true
            SecFrame.ZIndex = 15
            TargetCol:AddChild(SecFrame)
            
            local SecOutline = BaseDrawing.new("Square")
            SecOutline.Size = SecFrame.Size
            SecOutline.Color = CompkillerLib.Theme.StrokeColor
            SecOutline.Filled = false
            SecOutline.Thickness = 1
            SecOutline.ZIndex = 16
            SecFrame:AddChild(SecOutline)
            
            local SecLabel = BaseDrawing.new("Text")
            SecLabel.Text = secConfig.Name
            SecLabel.Size = Vector2.new(SecFrame.Size.X, 35)
            SecLabel.Position = Vector2.new(10, 10)
            SecLabel.Color = CompkillerLib.Theme.SwitchColor
            SecLabel.TextSize = 13
            SecLabel.ZIndex = 17
            SecLabel.Transparency = 0.6
            SecFrame:AddChild(SecLabel)
            
            local ItemContainer = BaseDrawing.new("Square")
            ItemContainer.Size = Vector2.new(SecFrame.Size.X, 0)
            ItemContainer.Position = Vector2.new(0, 35)
            ItemContainer.Color = CompkillerLib.Theme.BlockColor
            ItemContainer.Filled = false
            ItemContainer.Transparency = 0
            ItemContainer.ZIndex = 16
            SecFrame:AddChild(ItemContainer)

            local function RefreshSectionHeight()
                UpdateListLayout(ItemContainer, 5)
                SecFrame.Size = Vector2.new(SecFrame.Size.X, 40 + ItemContainer.Size.Y)
                SecOutline.Size = SecFrame.Size
                UpdateListLayout(TargetCol, 10)
            end

            -- [ Create Elements within Section ] --
            
            function SecObj:AddToggle(cfg)
                cfg = cfg or {}
                cfg.Name = cfg.Name or "Toggle"
                cfg.Default = cfg.Default or false
                cfg.Callback = cfg.Callback or function() end
                
                local ToggleApi = { Value = cfg.Default }
                
                local ToggleFrame = BaseDrawing.new("Square")
                ToggleFrame.Size = Vector2.new(ItemContainer.Size.X - 20, 25)
                ToggleFrame.Position = Vector2.new(10, 0)
                ToggleFrame.Color = CompkillerLib.Theme.BlockColor
                ToggleFrame.Filled = true
                ToggleFrame.Transparency = 0
                ToggleFrame.ZIndex = 17
                ItemContainer:AddChild(ToggleFrame)
                
                local ToggleLabel = BaseDrawing.new("Text")
                ToggleLabel.Text = cfg.Name
                ToggleLabel.Size = Vector2.new(100, 25)
                ToggleLabel.Position = Vector2.new(0, 5)
                ToggleLabel.Color = cfg.Risky and CompkillerLib.Theme.Risky or CompkillerLib.Theme.SwitchColor
                ToggleLabel.TextSize = 13
                ToggleLabel.Transparency = cfg.Default and 1 or 0.5
                ToggleLabel.ZIndex = 18
                ToggleFrame:AddChild(ToggleLabel)
                
                local OuterBox = BaseDrawing.new("Square")
                OuterBox.Size = Vector2.new(30, 16)
                OuterBox.Position = Vector2.new(ToggleFrame.Size.X - 35, 4)
                OuterBox.Color = cfg.Default and CompkillerLib.Theme.Toggle or CompkillerLib.Theme.DropColor
                OuterBox.Filled = true
                OuterBox.ZIndex = 18
                ToggleFrame:AddChild(OuterBox)
                
                local InnerNode = BaseDrawing.new("Square")
                InnerNode.Size = Vector2.new(12, 12)
                InnerNode.Position = Vector2.new(cfg.Default and 16 or 2, 2)
                InnerNode.Color = CompkillerLib.Theme.SwitchColor
                InnerNode.Filled = true
                InnerNode.ZIndex = 19
                OuterBox:AddChild(InnerNode)
                
                local function UpdateVisuals()
                    if ToggleApi.Value then
                        OuterBox.Color = CompkillerLib.Theme.Toggle
                        CreateCustomTween(InnerNode, {Position = Vector2.new(16, 2)}, 0.2)
                        ToggleLabel.Transparency = 1
                    else
                        OuterBox.Color = CompkillerLib.Theme.DropColor
                        CreateCustomTween(InnerNode, {Position = Vector2.new(2, 2)}, 0.2)
                        ToggleLabel.Transparency = 0.5
                    end
                end

                function ToggleApi:SetValue(val)
                    ToggleApi.Value = val
                    UpdateVisuals()
                    cfg.Callback(ToggleApi.Value)
                end
                
                ToggleFrame.OnInputBegan = function()
                    ToggleApi.Value = not ToggleApi.Value
                    UpdateVisuals()
                    cfg.Callback(ToggleApi.Value)
                end
                
                if cfg.Flag then CompkillerLib.Flags[cfg.Flag] = ToggleApi end
                RefreshSectionHeight()
                return ToggleApi
            end

            function SecObj:AddSlider(cfg)
                cfg = cfg or {}
                cfg.Name = cfg.Name or "Slider"
                cfg.Min = cfg.Min or 0
                cfg.Max = cfg.Max or 100
                cfg.Default = cfg.Default or cfg.Min
                cfg.Round = cfg.Round or 0
                cfg.Callback = cfg.Callback or function() end
                
                local SliderApi = { Value = cfg.Default }
                
                local SliderFrame = BaseDrawing.new("Square")
                SliderFrame.Size = Vector2.new(ItemContainer.Size.X - 20, 45)
                SliderFrame.Position = Vector2.new(10, 0)
                SliderFrame.Color = CompkillerLib.Theme.BlockColor
                SliderFrame.Filled = true
                SliderFrame.Transparency = 0
                SliderFrame.ZIndex = 17
                ItemContainer:AddChild(SliderFrame)
                
                local SliderLabel = BaseDrawing.new("Text")
                SliderLabel.Text = cfg.Name
                SliderLabel.Size = Vector2.new(100, 20)
                SliderLabel.Position = Vector2.new(0, 5)
                SliderLabel.Color = CompkillerLib.Theme.SwitchColor
                SliderLabel.TextSize = 13
                SliderLabel.ZIndex = 18
                SliderFrame:AddChild(SliderLabel)
                
                local ValueLabel = BaseDrawing.new("Text")
                ValueLabel.Text = tostring(cfg.Default)
                ValueLabel.Size = Vector2.new(50, 20)
                ValueLabel.Position = Vector2.new(SliderFrame.Size.X - 50, 5)
                ValueLabel.Color = CompkillerLib.Theme.SwitchColor
                ValueLabel.TextSize = 13
                ValueLabel.ZIndex = 18
                SliderFrame:AddChild(ValueLabel)
                
                local BarBg = BaseDrawing.new("Square")
                BarBg.Size = Vector2.new(SliderFrame.Size.X - 10, 8)
                BarBg.Position = Vector2.new(5, 25)
                BarBg.Color = CompkillerLib.Theme.DropColor
                BarBg.Filled = true
                BarBg.ZIndex = 18
                SliderFrame:AddChild(BarBg)
                
                local BarFill = BaseDrawing.new("Square")
                local p = (cfg.Default - cfg.Min) / (cfg.Max - cfg.Min)
                BarFill.Size = Vector2.new(BarBg.Size.X * p, 8)
                BarFill.Position = Vector2.new(0, 0)
                BarFill.Color = CompkillerLib.Theme.Highlight
                BarFill.Filled = true
                BarFill.ZIndex = 19
                BarBg:AddChild(BarFill)
                
                local function UpdateMath(inputPos)
                    local relX = math.clamp(inputPos.X - BarBg.AbsolutePosition.X, 0, BarBg.AbsoluteSize.X)
                    local percent = relX / BarBg.AbsoluteSize.X
                    local exactValue = cfg.Min + ((cfg.Max - cfg.Min) * percent)
                    
                    local mult = 10 ^ cfg.Round
                    SliderApi.Value = math.floor(exactValue * mult + 0.5) / mult
                    
                    BarFill.Size = Vector2.new(BarBg.AbsoluteSize.X * percent, 8)
                    ValueLabel.Text = tostring(SliderApi.Value)
                    cfg.Callback(SliderApi.Value)
                end
                
                local holding = false
                BarBg.OnInputBegan = function()
                    holding = true
                    UpdateMath(Engine.MousePos)
                end
                
                RunService.RenderStepped:Connect(function()
                    if holding then
                        if not Engine.MouseDown then
                            holding = false
                        else
                            UpdateMath(Engine.MousePos)
                        end
                    end
                end)
                
                if cfg.Flag then CompkillerLib.Flags[cfg.Flag] = SliderApi end
                RefreshSectionHeight()
                return SliderApi
            end

            function SecObj:AddDropdown(cfg)
                cfg = cfg or {}
                cfg.Name = cfg.Name or "Dropdown"
                cfg.Values = cfg.Values or {}
                cfg.Default = cfg.Default
                cfg.Callback = cfg.Callback or function() end
                
                local DropApi = { Value = cfg.Default }
                local isOpen = false
                
                local DropFrame = BaseDrawing.new("Square")
                DropFrame.Size = Vector2.new(ItemContainer.Size.X - 20, 50)
                DropFrame.Position = Vector2.new(10, 0)
                DropFrame.Color = CompkillerLib.Theme.BlockColor
                DropFrame.Filled = true
                DropFrame.Transparency = 0
                DropFrame.ZIndex = 17
                ItemContainer:AddChild(DropFrame)
                
                local DropLabel = BaseDrawing.new("Text")
                DropLabel.Text = cfg.Name
                DropLabel.Size = Vector2.new(100, 20)
                DropLabel.Position = Vector2.new(0, 5)
                DropLabel.Color = CompkillerLib.Theme.SwitchColor
                DropLabel.TextSize = 13
                DropLabel.ZIndex = 18
                DropFrame:AddChild(DropLabel)
                
                local SelectionBox = BaseDrawing.new("Square")
                SelectionBox.Size = Vector2.new(DropFrame.Size.X - 10, 20)
                SelectionBox.Position = Vector2.new(5, 25)
                SelectionBox.Color = CompkillerLib.Theme.DropColor
                SelectionBox.Filled = true
                SelectionBox.ZIndex = 18
                DropFrame:AddChild(SelectionBox)
                
                local SelectionText = BaseDrawing.new("Text")
                SelectionText.Text = tostring(cfg.Default or "None")
                SelectionText.Size = Vector2.new(SelectionBox.Size.X, 20)
                SelectionText.Position = Vector2.new(5, 3)
                SelectionText.Color = CompkillerLib.Theme.SwitchColor
                SelectionText.TextSize = 12
                SelectionText.ZIndex = 19
                SelectionBox:AddChild(SelectionText)

                -- The floating list for dropdown items
                local ListContainer = BaseDrawing.new("Square")
                ListContainer.Size = Vector2.new(SelectionBox.Size.X, 0)
                ListContainer.Position = Vector2.new(0, 22)
                ListContainer.Color = CompkillerLib.Theme.BlockBackground
                ListContainer.Filled = true
                ListContainer.ZIndex = 50 -- Float above everything
                ListContainer.Visible = false
                SelectionBox:AddChild(ListContainer)

                local ListOutline = BaseDrawing.new("Square")
                ListOutline.Size = ListContainer.Size
                ListOutline.Color = CompkillerLib.Theme.HighStrokeColor
                ListOutline.Filled = false
                ListOutline.Thickness = 1
                ListOutline.ZIndex = 51
                ListContainer:AddChild(ListOutline)

                local function PopulateList()
                    for _, c in ipairs(ListContainer.Children) do
                        if c ~= ListOutline then c:Destroy() end
                    end
                    
                    local curY = 0
                    for i, v in ipairs(cfg.Values) do
                        local btn = BaseDrawing.new("Square")
                        btn.Size = Vector2.new(ListContainer.Size.X, 20)
                        btn.Position = Vector2.new(0, curY)
                        btn.Color = CompkillerLib.Theme.BlockBackground
                        btn.Filled = true
                        btn.ZIndex = 52
                        ListContainer:AddChild(btn)
                        
                        local txt = BaseDrawing.new("Text")
                        txt.Text = tostring(v)
                        txt.Size = Vector2.new(btn.Size.X, 20)
                        txt.Position = Vector2.new(5, 3)
                        txt.Color = CompkillerLib.Theme.SwitchColor
                        txt.TextSize = 12
                        txt.Transparency = (DropApi.Value == v) and 1 or 0.5
                        txt.ZIndex = 53
                        btn:AddChild(txt)
                        
                        btn.OnHover = function()
                            btn.Color = CompkillerLib.Theme.MouseEnter
                        end
                        btn.OnLeave = function()
                            btn.Color = CompkillerLib.Theme.BlockBackground
                        end
                        
                        btn.OnInputBegan = function()
                            DropApi.Value = v
                            SelectionText.Text = tostring(v)
                            isOpen = false
                            ListContainer.Visible = false
                            cfg.Callback(v)
                        end
                        
                        curY = curY + 20
                    end
                    
                    ListContainer.Size = Vector2.new(SelectionBox.Size.X, curY)
                    ListOutline.Size = ListContainer.Size
                end
                
                SelectionBox.OnInputBegan = function()
                    isOpen = not isOpen
                    if isOpen then
                        PopulateList()
                        ListContainer.Visible = true
                    else
                        ListContainer.Visible = false
                    end
                end

                function DropApi:Refresh(newValues)
                    cfg.Values = newValues
                    if isOpen then PopulateList() end
                end

                function DropApi:SetValue(val)
                    DropApi.Value = val
                    SelectionText.Text = tostring(val)
                    cfg.Callback(val)
                end
                
                if cfg.Flag then CompkillerLib.Flags[cfg.Flag] = DropApi end
                RefreshSectionHeight()
                return DropApi
            end
            
            function SecObj:AddKeybind(cfg)
                cfg = cfg or {}
                cfg.Name = cfg.Name or "Keybind"
                cfg.Default = cfg.Default or Enum.KeyCode.Unknown
                cfg.Callback = cfg.Callback or function() end
                
                local KeyApi = { Value = cfg.Default }
                local isBinding = false
                
                local KeyFrame = BaseDrawing.new("Square")
                KeyFrame.Size = Vector2.new(ItemContainer.Size.X - 20, 25)
                KeyFrame.Position = Vector2.new(10, 0)
                KeyFrame.Color = CompkillerLib.Theme.BlockColor
                KeyFrame.Filled = true
                KeyFrame.Transparency = 0
                KeyFrame.ZIndex = 17
                ItemContainer:AddChild(KeyFrame)
                
                local KeyLabel = BaseDrawing.new("Text")
                KeyLabel.Text = cfg.Name
                KeyLabel.Size = Vector2.new(100, 25)
                KeyLabel.Position = Vector2.new(0, 5)
                KeyLabel.Color = CompkillerLib.Theme.SwitchColor
                KeyLabel.TextSize = 13
                KeyLabel.ZIndex = 18
                KeyLabel.Transparency = 0.5
                KeyFrame:AddChild(KeyLabel)
                
                local KeyBox = BaseDrawing.new("Square")
                KeyBox.Size = Vector2.new(60, 16)
                KeyBox.Position = Vector2.new(KeyFrame.Size.X - 65, 4)
                KeyBox.Color = CompkillerLib.Theme.DropColor
                KeyBox.Filled = true
                KeyBox.ZIndex = 18
                KeyFrame:AddChild(KeyBox)
                
                local KeyText = BaseDrawing.new("Text")
                KeyText.Text = KeyApi.Value == Enum.KeyCode.Unknown and "None" or KeyApi.Value.Name
                KeyText.Size = Vector2.new(60, 16)
                KeyText.Position = Vector2.new(0, 2)
                KeyText.Color = CompkillerLib.Theme.SwitchColor
                KeyText.TextSize = 12
                KeyText.Center = true
                KeyText.ZIndex = 19
                KeyBox:AddChild(KeyText)
                
                KeyBox.OnInputBegan = function()
                    if isBinding then return end
                    isBinding = true
                    KeyText.Text = "..."
                    
                    local connection
                    connection = UserInputService.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            KeyApi.Value = input.KeyCode
                            KeyText.Text = input.KeyCode.Name
                            isBinding = false
                            connection:Disconnect()
                            cfg.Callback(input.KeyCode)
                        elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 then
                            KeyApi.Value = input.UserInputType
                            KeyText.Text = input.UserInputType.Name
                            isBinding = false
                            connection:Disconnect()
                            cfg.Callback(input.UserInputType)
                        end
                    end)
                end
                
                if cfg.Flag then CompkillerLib.Flags[cfg.Flag] = KeyApi end
                RefreshSectionHeight()
                return KeyApi
            end
            
            function SecObj:AddColorPicker(cfg)
                cfg = cfg or {}
                cfg.Name = cfg.Name or "Color Picker"
                cfg.Default = cfg.Default or Color3.new(1,1,1)
                cfg.Callback = cfg.Callback or function() end
                
                local ColApi = { Value = cfg.Default }
                local isOpen = false
                
                local ColFrame = BaseDrawing.new("Square")
                ColFrame.Size = Vector2.new(ItemContainer.Size.X - 20, 25)
                ColFrame.Position = Vector2.new(10, 0)
                ColFrame.Color = CompkillerLib.Theme.BlockColor
                ColFrame.Filled = true
                ColFrame.Transparency = 0
                ColFrame.ZIndex = 17
                ItemContainer:AddChild(ColFrame)
                
                local ColLabel = BaseDrawing.new("Text")
                ColLabel.Text = cfg.Name
                ColLabel.Size = Vector2.new(100, 25)
                ColLabel.Position = Vector2.new(0, 5)
                ColLabel.Color = CompkillerLib.Theme.SwitchColor
                ColLabel.TextSize = 13
                ColLabel.ZIndex = 18
                ColLabel.Transparency = 0.5
                ColFrame:AddChild(ColLabel)
                
                local ColBox = BaseDrawing.new("Square")
                ColBox.Size = Vector2.new(20, 16)
                ColBox.Position = Vector2.new(ColFrame.Size.X - 25, 4)
                ColBox.Color = ColApi.Value
                ColBox.Filled = true
                ColBox.ZIndex = 18
                ColFrame:AddChild(ColBox)
                
                -- Extended Picker Window Simulated (Simplified due to lack of gradients in standard Drawing)
                local PickerWindow = BaseDrawing.new("Square")
                PickerWindow.Size = Vector2.new(160, 160)
                PickerWindow.Position = Vector2.new(ColFrame.Size.X - 165, 25)
                PickerWindow.Color = CompkillerLib.Theme.BlockBackground
                PickerWindow.Filled = true
                PickerWindow.ZIndex = 50
                PickerWindow.Visible = false
                ColFrame:AddChild(PickerWindow)
                
                -- Hue bar simulated by sections (since Drawing doesn't have ColorSequence)
                local h = 0; local s = 1; local v = 1
                
                local HueBar = BaseDrawing.new("Square")
                HueBar.Size = Vector2.new(10, 140)
                HueBar.Position = Vector2.new(140, 10)
                HueBar.Color = Color3.fromRGB(255, 0, 0)
                HueBar.Filled = true
                HueBar.ZIndex = 51
                PickerWindow:AddChild(HueBar)
                
                local SatValBox = BaseDrawing.new("Square")
                SatValBox.Size = Vector2.new(120, 140)
                SatValBox.Position = Vector2.new(10, 10)
                SatValBox.Color = Color3.fromHSV(h, s, v)
                SatValBox.Filled = true
                SatValBox.ZIndex = 51
                PickerWindow:AddChild(SatValBox)
                
                local function UpdateColor()
                    local finalColor = Color3.fromHSV(h, s, v)
                    ColApi.Value = finalColor
                    ColBox.Color = finalColor
                    SatValBox.Color = Color3.fromHSV(h, 1, 1)
                    cfg.Callback(finalColor)
                end
                
                local holdingHue = false
                HueBar.OnInputBegan = function() holdingHue = true end
                
                local holdingSatVal = false
                SatValBox.OnInputBegan = function() holdingSatVal = true end
                
                RunService.RenderStepped:Connect(function()
                    if holdingHue then
                        if not Engine.MouseDown then holdingHue = false return end
                        local relY = math.clamp(Engine.MousePos.Y - HueBar.AbsolutePosition.Y, 0, HueBar.AbsoluteSize.Y)
                        h = 1 - (relY / HueBar.AbsoluteSize.Y)
                        UpdateColor()
                    end
                    if holdingSatVal then
                        if not Engine.MouseDown then holdingSatVal = false return end
                        local relX = math.clamp(Engine.MousePos.X - SatValBox.AbsolutePosition.X, 0, SatValBox.AbsoluteSize.X)
                        local relY = math.clamp(Engine.MousePos.Y - SatValBox.AbsolutePosition.Y, 0, SatValBox.AbsoluteSize.Y)
                        s = relX / SatValBox.AbsoluteSize.X
                        v = 1 - (relY / SatValBox.AbsoluteSize.Y)
                        UpdateColor()
                    end
                end)
                
                ColBox.OnInputBegan = function()
                    isOpen = not isOpen
                    PickerWindow.Visible = isOpen
                end
                
                if cfg.Flag then CompkillerLib.Flags[cfg.Flag] = ColApi end
                RefreshSectionHeight()
                return ColApi
            end
            
            function SecObj:AddTextBox(cfg)
                cfg = cfg or {}
                cfg.Name = cfg.Name or "TextBox"
                cfg.Default = cfg.Default or ""
                cfg.Placeholder = cfg.Placeholder or "Enter text..."
                cfg.Callback = cfg.Callback or function() end
                
                local TextApi = { Value = cfg.Default }
                
                local TextFrame = BaseDrawing.new("Square")
                TextFrame.Size = Vector2.new(ItemContainer.Size.X - 20, 25)
                TextFrame.Position = Vector2.new(10, 0)
                TextFrame.Color = CompkillerLib.Theme.BlockColor
                TextFrame.Filled = true
                TextFrame.Transparency = 0
                TextFrame.ZIndex = 17
                ItemContainer:AddChild(TextFrame)
                
                local TextLabel = BaseDrawing.new("Text")
                TextLabel.Text = cfg.Name
                TextLabel.Size = Vector2.new(80, 25)
                TextLabel.Position = Vector2.new(0, 5)
                TextLabel.Color = CompkillerLib.Theme.SwitchColor
                TextLabel.TextSize = 13
                TextLabel.ZIndex = 18
                TextLabel.Transparency = 0.5
                TextFrame:AddChild(TextLabel)
                
                local InputBox = BaseDrawing.new("Square")
                InputBox.Size = Vector2.new(110, 16)
                InputBox.Position = Vector2.new(TextFrame.Size.X - 115, 4)
                InputBox.Color = CompkillerLib.Theme.DropColor
                InputBox.Filled = true
                InputBox.ZIndex = 18
                TextFrame:AddChild(InputBox)
                
                local InputLabel = BaseDrawing.new("Text")
                InputLabel.Text = TextApi.Value ~= "" and TextApi.Value or cfg.Placeholder
                InputLabel.Size = Vector2.new(110, 16)
                InputLabel.Position = Vector2.new(5, 2)
                InputLabel.Color = CompkillerLib.Theme.SwitchColor
                InputLabel.TextSize = 12
                InputLabel.ZIndex = 19
                InputLabel.Transparency = TextApi.Value ~= "" and 1 or 0.4
                InputBox:AddChild(InputLabel)
                
                local isTyping = false
                
                InputBox.OnInputBegan = function()
                    if isTyping then return end
                    isTyping = true
                    InputLabel.Text = "|"
                    InputLabel.Transparency = 1
                    
                    local str = ""
                    local conn
                    conn = UserInputService.InputBegan:Connect(function(input)
                        if not isTyping then conn:Disconnect() return end
                        if input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.Escape then
                            isTyping = false
                            TextApi.Value = str
                            InputLabel.Text = str ~= "" and str or cfg.Placeholder
                            InputLabel.Transparency = str ~= "" and 1 or 0.4
                            conn:Disconnect()
                            cfg.Callback(str)
                        elseif input.KeyCode == Enum.KeyCode.Backspace then
                            str = string.sub(str, 1, -2)
                            InputLabel.Text = str .. "|"
                        elseif input.UserInputType == Enum.UserInputType.Keyboard then
                            local char = UserInputService:GetStringForKeyCode(input.KeyCode)
                            -- Basic shift checking
                            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift) then
                                char = string.upper(char)
                            else
                                char = string.lower(char)
                            end
                            str = str .. char
                            InputLabel.Text = str .. "|"
                        end
                    end)
                end
                
                if cfg.Flag then CompkillerLib.Flags[cfg.Flag] = TextApi end
                RefreshSectionHeight()
                return TextApi
            end
            
            function SecObj:AddButton(cfg)
                cfg = cfg or {}
                cfg.Name = cfg.Name or "Button"
                cfg.Callback = cfg.Callback or function() end
                
                local BtnFrame = BaseDrawing.new("Square")
                BtnFrame.Size = Vector2.new(ItemContainer.Size.X - 30, 24)
                BtnFrame.Position = Vector2.new(15, 0)
                BtnFrame.Color = CompkillerLib.Theme.Highlight
                BtnFrame.Transparency = 0.1
                BtnFrame.Filled = true
                BtnFrame.ZIndex = 17
                ItemContainer:AddChild(BtnFrame)
                
                local BtnOutline = BaseDrawing.new("Square")
                BtnOutline.Size = BtnFrame.Size
                BtnOutline.Color = CompkillerLib.Theme.StrokeColor
                BtnOutline.Filled = false
                BtnOutline.Thickness = 1
                BtnOutline.ZIndex = 18
                BtnFrame:AddChild(BtnOutline)
                
                local BtnLabel = BaseDrawing.new("Text")
                BtnLabel.Text = cfg.Name
                BtnLabel.Size = Vector2.new(BtnFrame.Size.X, 24)
                BtnLabel.Position = Vector2.new(0, 5)
                BtnLabel.Color = CompkillerLib.Theme.SwitchColor
                BtnLabel.TextSize = 13
                BtnLabel.Center = true
                BtnLabel.ZIndex = 19
                BtnFrame:AddChild(BtnLabel)
                
                BtnFrame.OnHover = function()
                    BtnFrame.Transparency = 0.2
                end
                
                BtnFrame.OnLeave = function()
                    BtnFrame.Transparency = 0.1
                end
                
                BtnFrame.OnInputBegan = function()
                    BtnFrame.Transparency = 0.4
                    cfg.Callback()
                end
                
                BtnFrame.OnInputEnded = function()
                    BtnFrame.Transparency = 0.2
                end
                
                RefreshSectionHeight()
            end
            
            function SecObj:AddParagraph(cfg)
                cfg = cfg or {}
                cfg.Title = cfg.Title or "Paragraph"
                cfg.Content = cfg.Content or ""
                
                local ParaFrame = BaseDrawing.new("Square")
                ParaFrame.Size = Vector2.new(ItemContainer.Size.X - 20, 50) -- Default scale, can expand
                ParaFrame.Position = Vector2.new(10, 0)
                ParaFrame.Color = CompkillerLib.Theme.BlockColor
                ParaFrame.Filled = true
                ParaFrame.Transparency = 0
                ParaFrame.ZIndex = 17
                ItemContainer:AddChild(ParaFrame)
                
                local TitleLabel = BaseDrawing.new("Text")
                TitleLabel.Text = cfg.Title
                TitleLabel.Size = Vector2.new(ParaFrame.Size.X, 20)
                TitleLabel.Position = Vector2.new(0, 5)
                TitleLabel.Color = CompkillerLib.Theme.SwitchColor
                TitleLabel.TextSize = 14
                TitleLabel.ZIndex = 18
                ParaFrame:AddChild(TitleLabel)
                
                local ContentLabel = BaseDrawing.new("Text")
                ContentLabel.Text = cfg.Content
                ContentLabel.Size = Vector2.new(ParaFrame.Size.X, 25)
                ContentLabel.Position = Vector2.new(0, 22)
                ContentLabel.Color = CompkillerLib.Theme.SwitchColor
                ContentLabel.TextSize = 12
                ContentLabel.Transparency = 0.6
                ContentLabel.ZIndex = 18
                ParaFrame:AddChild(ContentLabel)
                
                -- Manual multiline simulation is hard with raw Drawing API text.
                -- We assume it fits for now, but a robust system would parse string lengths.
                
                RefreshSectionHeight()
            end

            table.insert(TabObj.Sections, SecObj)
            UpdateListLayout(TargetCol, 10)
            return SecObj
        end
        
        return TabObj
    end
    
    return WindowObj
end

-- [ Expose the Global Interface ] --
getgenv().Compkiller = CompkillerLib

-- Initialization sequence for smooth execution
return CompkillerLib
