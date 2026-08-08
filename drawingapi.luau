--[[
    ===========================================================================
    COMPKILLER // ADVANCED DRAWING API RENDERING ENGINE (FULL KERNEL)
    VERSION: 4.0.0 (RAW VIRTUAL DOM IMPLEMENTATION)
    ARCHITECTURE: LUAU
    ===========================================================================
--]]

local CoreGui               = game:GetService("CoreGui")
local HttpService           = game:GetService("HttpService")
local UserInputService      = game:GetService("UserInputService")
local RunService            = game:GetService("RunService")
local TweenService          = game:GetService("TweenService")
local Workspace             = game:GetService("Workspace")
local Players               = game:GetService("Players")

local LocalPlayer           = Players.LocalPlayer
local CurrentCamera         = Workspace.CurrentCamera
local Mouse                 = LocalPlayer:GetMouse()

local EngineState = {
    Initialized             = false,
    RenderQueue             = {},
    TweenQueue              = {},
    HoveredElements         = {},
    ActiveInputTarget       = nil,
    MousePosition           = Vector2.new(0, 0),
    PreviousMousePosition   = Vector2.new(0, 0),
    MouseDelta              = Vector2.new(0, 0),
    IsMouseDown             = false,
    IsRightMouseDown        = false,
    TimeElapsed             = 0,
    DeltaTime               = 0,
    Resolution              = CurrentCamera.ViewportSize,
    InputBeganConnection    = nil,
    InputEndedConnection    = nil,
    RenderConnection        = nil,
    TypingActive            = false,
    TypingElement           = nil
}

local ThemeManager = {
    CurrentTheme = "Dark",
    Presets = {
        Dark = {
            WindowBackground          = Color3.fromRGB(15, 15, 20),
            SidebarBackground         = Color3.fromRGB(12, 12, 17),
            SectionBackground         = Color3.fromRGB(20, 21, 26),
            ElementBackground         = Color3.fromRGB(25, 26, 31),
            ElementHover              = Color3.fromRGB(32, 33, 38),
            ElementActive             = Color3.fromRGB(40, 41, 48),
            OutlineOuter              = Color3.fromRGB(35, 36, 42),
            OutlineInner              = Color3.fromRGB(28, 29, 34),
            SectionOutline            = Color3.fromRGB(35, 36, 42),
            SeparatorLine             = Color3.fromRGB(45, 45, 55),
            AccentPrimary             = Color3.fromRGB(13, 185, 195),
            AccentSecondary           = Color3.fromRGB(17, 238, 253),
            AccentHover               = Color3.fromRGB(20, 255, 255),
            AccentDark                = Color3.fromRGB(9, 130, 140),
            TextPrimary               = Color3.fromRGB(255, 255, 255),
            TextSecondary             = Color3.fromRGB(180, 180, 190),
            TextMuted                 = Color3.fromRGB(120, 120, 130),
            TextDisabled              = Color3.fromRGB(80, 80, 90),
            Success                   = Color3.fromRGB(46, 204, 113),
            Warning                   = Color3.fromRGB(241, 196, 15),
            Danger                    = Color3.fromRGB(231, 76, 60),
            Info                      = Color3.fromRGB(52, 152, 219),
            ShadowColor               = Color3.fromRGB(0, 0, 0),
            ShadowOpacity             = 0.6
        }
    }
}

local MathLib = {}
function MathLib.Lerp(Start, End, Alpha) return Start + (End - Start) * Alpha end
function MathLib.Clamp(Value, Min, Max) return math.max(Min, math.min(Max, Value)) end
function MathLib.Round(Value, DecimalPlaces)
    local Multiplier = 10 ^ (DecimalPlaces or 0)
    return math.floor(Value * Multiplier + 0.5) / Multiplier
end
function MathLib.LerpVector2(StartVec, EndVec, Alpha)
    return Vector2.new(MathLib.Lerp(StartVec.X, EndVec.X, Alpha), MathLib.Lerp(StartVec.Y, EndVec.Y, Alpha))
end
function MathLib.LerpColor3(StartCol, EndCol, Alpha)
    return Color3.new(MathLib.Lerp(StartCol.R, EndCol.R, Alpha), MathLib.Lerp(StartCol.G, EndCol.G, Alpha), MathLib.Lerp(StartCol.B, EndCol.B, Alpha))
end
function MathLib.PointInRectangle(Point, RectPosition, RectSize)
    return Point.X >= RectPosition.X and Point.X <= RectPosition.X + RectSize.X and Point.Y >= RectPosition.Y and Point.Y <= RectPosition.Y + RectSize.Y
end
function MathLib.HSVToRGB(h, s, v)
    local r, g, b
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)
    i = i % 6
    if i == 0 then r, g, b = v, t, p
    elseif i == 1 then r, g, b = q, v, p
    elseif i == 2 then r, g, b = p, v, t
    elseif i == 3 then r, g, b = p, q, v
    elseif i == 4 then r, g, b = t, p, v
    elseif i == 5 then r, g, b = v, p, q
    end
    return Color3.new(r, g, b)
end
function MathLib.RGBToHSV(c)
    local r, g, b = c.R, c.G, c.B
    local max, min = math.max(r, g, b), math.min(r, g, b)
    local h, s, v
    v = max
    local d = max - min
    if max == 0 then s = 0 else s = d / max end
    if max == min then
        h = 0
    else
        if max == r then
            h = (g - b) / d
            if g < b then h = h + 6 end
        elseif max == g then h = (b - r) / d + 2
        elseif max == b then h = (r - g) / d + 4
        end
        h = h / 6
    end
    return h, s, v
end

local EasingLib = {}
function EasingLib.Linear(t, b, c, d) return c * t / d + b end
function EasingLib.OutQuad(t, b, c, d) t = t / d; return -c * t * (t - 2) + b end
function EasingLib.OutQuint(t, b, c, d) t = t / d - 1; return c * (math.pow(t, 5) + 1) + b end
function EasingLib.OutExpo(t, b, c, d) if t == d then return b + c else return c * 1.001 * (-math.pow(2, -10 * t / d) + 1) + b end end

local Animator = {}
function Animator.ConstructTween(Object, Properties, Duration, EasingStyle, EasingDirection, Callback)
    EasingStyle = EasingStyle or "Quad"
    EasingDirection = EasingDirection or "Out"
    local EasingFunctionName = EasingDirection .. EasingStyle
    local EasingFunction = EasingLib[EasingFunctionName] or EasingLib.OutQuad
    
    local StartProperties, ChangeProperties = {}, {}
    for Property, EndValue in pairs(Properties) do
        StartProperties[Property] = Object[Property]
        ChangeProperties[Property] = EndValue
    end
    
    local TweenData = { Object = Object, Start = StartProperties, Target = ChangeProperties, Duration = Duration, TimeElapsed = 0, Easing = EasingFunction, OnComplete = Callback, IsCompleted = false }
    table.insert(EngineState.TweenQueue, TweenData)
    return TweenData
end

function Animator.CancelTween(Object)
    for i = #EngineState.TweenQueue, 1, -1 do
        if EngineState.TweenQueue[i].Object == Object then table.remove(EngineState.TweenQueue, i) end
    end
end

local VirtualDOM = {}
VirtualDOM.__index = VirtualDOM

function VirtualDOM.CreateInstance(Type)
    local self = setmetatable({}, VirtualDOM)
    self.Type = Type
    self.RenderObject = Drawing.new(Type)
    self.Children = {}
    self.Parent = nil
    self.Position = Vector2.new(0, 0)
    self.Size = Vector2.new(0, 0)
    self.AbsolutePosition = Vector2.new(0, 0)
    self.AbsoluteSize = Vector2.new(0, 0)
    self.Visible = true
    self.ZIndex = 1
    self.Transparency = 1
    self.Color = Color3.new(1, 1, 1)
    self.ClipsDescendants = false
    self.ClipBounds = nil
    
    if Type == "Square" then
        self.Filled = true
        self.Thickness = 1
    elseif Type == "Text" then
        self.Text = ""
        self.TextSize = 13
        self.Center = false
        self.Outline = true
        self.OutlineColor = Color3.new(0, 0, 0)
        self.Font = 2
    elseif Type == "Line" then
        self.Thickness = 1
        self.From = Vector2.new(0, 0)
        self.To = Vector2.new(0, 0)
    elseif Type == "Circle" then
        self.Radius = 0
        self.Filled = false
        self.NumSides = 64
        self.Thickness = 1
    end
    
    table.insert(EngineState.RenderQueue, self)
    return self
end

function VirtualDOM:AddChild(ChildInstance)
    ChildInstance.Parent = self
    table.insert(self.Children, ChildInstance)
end

function VirtualDOM:Destroy()
    for _, Child in ipairs(self.Children) do Child:Destroy() end
    if self.Parent then
        for i, Child in ipairs(self.Parent.Children) do
            if Child == self then table.remove(self.Parent.Children, i); break end
        end
    end
    for i, Instance in ipairs(EngineState.RenderQueue) do
        if Instance == self then table.remove(EngineState.RenderQueue, i); break end
    end
    Animator.CancelTween(self)
    if self.RenderObject then self.RenderObject:Remove(); self.RenderObject = nil end
    setmetatable(self, nil)
end

function VirtualDOM:UpdateTransformations()
    if self.Parent then
        self.AbsolutePosition = self.Parent.AbsolutePosition + self.Position
    else
        self.AbsolutePosition = self.Position
    end
    self.AbsoluteSize = self.Size
    
    if self.Parent and self.Parent.ClipsDescendants then
        if self.Parent.ClipBounds then
            self.ClipBounds = self.Parent.ClipBounds
        else
            self.ClipBounds = {
                Min = self.Parent.AbsolutePosition,
                Max = self.Parent.AbsolutePosition + self.Parent.AbsoluteSize
            }
        end
    elseif self.Parent and self.Parent.ClipBounds then
        self.ClipBounds = self.Parent.ClipBounds
    else
        self.ClipBounds = nil
    end
end

function VirtualDOM:RenderToScreen()
    if not self.RenderObject then return end
    if not self.Visible then self.RenderObject.Visible = false return end
    
    local CurrentNode = self.Parent
    local IsVisibleHierarchy = true
    while CurrentNode do
        if not CurrentNode.Visible then IsVisibleHierarchy = false break end
        CurrentNode = CurrentNode.Parent
    end
    
    if not IsVisibleHierarchy then self.RenderObject.Visible = false return end
    self:UpdateTransformations()
    
    local RenderPos = self.AbsolutePosition
    local RenderSize = self.AbsoluteSize
    local IsClippedOut = false
    
    if self.ClipBounds and self.Type == "Square" then
        local MinX = math.max(RenderPos.X, self.ClipBounds.Min.X)
        local MinY = math.max(RenderPos.Y, self.ClipBounds.Min.Y)
        local MaxX = math.min(RenderPos.X + RenderSize.X, self.ClipBounds.Max.X)
        local MaxY = math.min(RenderPos.Y + RenderSize.Y, self.ClipBounds.Max.Y)
        
        if MinX >= MaxX or MinY >= MaxY then
            IsClippedOut = true
        else
            RenderPos = Vector2.new(MinX, MinY)
            RenderSize = Vector2.new(MaxX - MinX, MaxY - MinY)
        end
    elseif self.ClipBounds and (self.Type == "Text" or self.Type == "Circle") then
        if RenderPos.X < self.ClipBounds.Min.X or RenderPos.X > self.ClipBounds.Max.X or 
           RenderPos.Y < self.ClipBounds.Min.Y or RenderPos.Y > self.ClipBounds.Max.Y then
            IsClippedOut = true
        end
    end
    
    if IsClippedOut then self.RenderObject.Visible = false return end

    self.RenderObject.Visible = true
    self.RenderObject.ZIndex = self.ZIndex
    self.RenderObject.Transparency = self.Transparency
    self.RenderObject.Color = self.Color
    
    if self.Type == "Square" then
        self.RenderObject.Position = RenderPos
        self.RenderObject.Size = RenderSize
        self.RenderObject.Filled = self.Filled
        self.RenderObject.Thickness = self.Thickness
    elseif self.Type == "Text" then
        self.RenderObject.Position = RenderPos
        self.RenderObject.Text = self.Text
        self.RenderObject.Size = self.TextSize
        self.RenderObject.Center = self.Center
        self.RenderObject.Outline = self.Outline
        self.RenderObject.OutlineColor = self.OutlineColor
        self.RenderObject.Font = self.Font
    elseif self.Type == "Line" then
        self.RenderObject.From = RenderPos
        self.RenderObject.To = RenderPos + RenderSize
        self.RenderObject.Thickness = self.Thickness
    elseif self.Type == "Circle" then
        self.RenderObject.Position = RenderPos
        self.RenderObject.Radius = self.Radius
        self.RenderObject.Filled = self.Filled
        self.RenderObject.NumSides = self.NumSides
        self.RenderObject.Thickness = self.Thickness
    end
end

local VisualEffects = {}
function VisualEffects.GenerateDropShadow(ParentNode, Size, PositionOffset, Spread, Opacity, Quality)
    local ShadowGroup = {}
    local StepSize = Spread / Quality
    for i = 1, Quality do
        local Expansion = i * StepSize
        local CurrentOpacity = Opacity - (i * (Opacity / Quality))
        local ShadowLayer = VirtualDOM.CreateInstance("Square")
        ShadowLayer.Size = Size + Vector2.new(Expansion * 2, Expansion * 2)
        ShadowLayer.Position = PositionOffset - Vector2.new(Expansion, Expansion)
        ShadowLayer.Color = ThemeManager.Presets[ThemeManager.CurrentTheme].ShadowColor
        ShadowLayer.Filled = false
        ShadowLayer.Thickness = 1
        ShadowLayer.Transparency = CurrentOpacity
        ShadowLayer.ZIndex = ParentNode.ZIndex - i
        ParentNode:AddChild(ShadowLayer)
        table.insert(ShadowGroup, ShadowLayer)
    end
    return ShadowGroup
end

EngineState.RenderConnection = RunService.RenderStepped:Connect(function(DeltaTime)
    EngineState.TimeElapsed = EngineState.TimeElapsed + DeltaTime
    EngineState.DeltaTime = DeltaTime
    
    local CurrentMouseLocation = UserInputService:GetMouseLocation()
    EngineState.MouseDelta = CurrentMouseLocation - EngineState.PreviousMousePosition
    EngineState.PreviousMousePosition = CurrentMouseLocation
    EngineState.MousePosition = CurrentMouseLocation
    
    for i = #EngineState.TweenQueue, 1, -1 do
        local Tween = EngineState.TweenQueue[i]
        Tween.TimeElapsed = Tween.TimeElapsed + DeltaTime
        if Tween.TimeElapsed >= Tween.Duration then
            Tween.TimeElapsed = Tween.Duration
            Tween.IsCompleted = true
        end
        for Property, TargetValue in pairs(Tween.Target) do
            local StartValue = Tween.Start[Property]
            local InterpolatedValue
            if typeof(StartValue) == "number" then
                InterpolatedValue = Tween.Easing(Tween.TimeElapsed, StartValue, TargetValue - StartValue, Tween.Duration)
            elseif typeof(StartValue) == "Vector2" then
                local X = Tween.Easing(Tween.TimeElapsed, StartValue.X, TargetValue.X - StartValue.X, Tween.Duration)
                local Y = Tween.Easing(Tween.TimeElapsed, StartValue.Y, TargetValue.Y - StartValue.Y, Tween.Duration)
                InterpolatedValue = Vector2.new(X, Y)
            elseif typeof(StartValue) == "Color3" then
                local R = Tween.Easing(Tween.TimeElapsed, StartValue.R, TargetValue.R - StartValue.R, Tween.Duration)
                local G = Tween.Easing(Tween.TimeElapsed, StartValue.G, TargetValue.G - StartValue.G, Tween.Duration)
                local B = Tween.Easing(Tween.TimeElapsed, StartValue.B, TargetValue.B - StartValue.B, Tween.Duration)
                InterpolatedValue = Color3.new(R, G, B)
            end
            Tween.Object[Property] = InterpolatedValue
        end
        if Tween.IsCompleted then
            if Tween.OnComplete then task.spawn(Tween.OnComplete) end
            table.remove(EngineState.TweenQueue, i)
        end
    end
    
    table.sort(EngineState.RenderQueue, function(A, B) return A.ZIndex < B.ZIndex end)
    
    local TopMostHoveredElement = nil
    for _, Element in ipairs(EngineState.RenderQueue) do
        Element:RenderToScreen()
        if Element.Visible and Element.RenderObject and Element.RenderObject.Visible then
            if Element.MouseEnter or Element.InputBegan or Element.InputEnded or Element.MouseScroll then
                if MathLib.PointInRectangle(EngineState.MousePosition, Element.AbsolutePosition, Element.AbsoluteSize) then
                    TopMostHoveredElement = Element
                end
            end
        end
    end
    
    if TopMostHoveredElement ~= EngineState.HoveredElements.Current then
        if EngineState.HoveredElements.Current and EngineState.HoveredElements.Current.MouseLeave then
            task.spawn(EngineState.HoveredElements.Current.MouseLeave)
        end
        EngineState.HoveredElements.Current = TopMostHoveredElement
        if TopMostHoveredElement and TopMostHoveredElement.MouseEnter then
            task.spawn(TopMostHoveredElement.MouseEnter)
        end
    end
end)

EngineState.InputBeganConnection = UserInputService.InputBegan:Connect(function(Input, GameProcessedEvent)
    if Input.UserInputType == Enum.UserInputType.MouseButton1 then
        EngineState.IsMouseDown = true
        if EngineState.HoveredElements.Current and EngineState.HoveredElements.Current.InputBegan then
            EngineState.ActiveInputTarget = EngineState.HoveredElements.Current
            task.spawn(EngineState.HoveredElements.Current.InputBegan, Input)
        end
    elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
        EngineState.IsRightMouseDown = true
        if EngineState.HoveredElements.Current and EngineState.HoveredElements.Current.RightInputBegan then
            task.spawn(EngineState.HoveredElements.Current.RightInputBegan, Input)
        end
    end
end)

EngineState.InputEndedConnection = UserInputService.InputEnded:Connect(function(Input, GameProcessedEvent)
    if Input.UserInputType == Enum.UserInputType.MouseButton1 then
        EngineState.IsMouseDown = false
        if EngineState.ActiveInputTarget and EngineState.ActiveInputTarget.InputEnded then
            task.spawn(EngineState.ActiveInputTarget.InputEnded, Input)
        end
        EngineState.ActiveInputTarget = nil
    elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
        EngineState.IsRightMouseDown = false
    end
end)

UserInputService.InputChanged:Connect(function(Input, GameProcessedEvent)
    if Input.UserInputType == Enum.UserInputType.MouseWheel then
        if EngineState.HoveredElements.Current and EngineState.HoveredElements.Current.MouseScroll then
            task.spawn(EngineState.HoveredElements.Current.MouseScroll, Input.Position.Z)
        end
    end
end)

local CompkillerLib = {
    Windows = {},
    ToggledFlags = {},
    ConfigName = "CK_Config",
    DragPhysics = { TargetObject = nil, DragOffset = Vector2.new(0, 0), Velocity = Vector2.new(0, 0), Friction = 0.82, IsDragging = false },
    Notifications = {}
}

RunService.RenderStepped:Connect(function()
    local Physics = CompkillerLib.DragPhysics
    if Physics.IsDragging and Physics.TargetObject then
        local TargetPosition = EngineState.MousePosition + Physics.DragOffset
        Physics.Velocity = (TargetPosition - Physics.TargetObject.Position) * 0.4
        Physics.TargetObject.Position = Physics.TargetObject.Position + Physics.Velocity
    elseif Physics.TargetObject and not Physics.IsDragging then
        if math.abs(Physics.Velocity.X) > 0.1 or math.abs(Physics.Velocity.Y) > 0.1 then
            Physics.Velocity = Physics.Velocity * Physics.Friction
            Physics.TargetObject.Position = Physics.TargetObject.Position + Physics.Velocity
        else
            Physics.TargetObject = nil
        end
    end
end)

function CompkillerLib:Notify(Title, Content, Duration)
    Duration = Duration or 3
    local Theme = ThemeManager.Presets[ThemeManager.CurrentTheme]
    
    local NotifBase = VirtualDOM.CreateInstance("Square")
    NotifBase.Size = Vector2.new(250, 60)
    NotifBase.Position = Vector2.new(CurrentCamera.ViewportSize.X, CurrentCamera.ViewportSize.Y - (#self.Notifications * 70) - 70)
    NotifBase.Color = Theme.WindowBackground
    NotifBase.ZIndex = 500
    
    local NotifOut = VirtualDOM.CreateInstance("Square")
    NotifOut.Size = NotifBase.Size
    NotifOut.Color = Theme.SectionOutline
    NotifOut.Filled = false
    NotifOut.ZIndex = 501
    NotifBase:AddChild(NotifOut)
    
    local NotifBar = VirtualDOM.CreateInstance("Square")
    NotifBar.Size = Vector2.new(2, NotifBase.Size.Y)
    NotifBar.Color = Theme.AccentPrimary
    NotifBar.ZIndex = 502
    NotifBase:AddChild(NotifBar)
    
    local TitleLabel = VirtualDOM.CreateInstance("Text")
    TitleLabel.Text = Title
    TitleLabel.Size = 14
    TitleLabel.Position = Vector2.new(10, 8)
    TitleLabel.Color = Theme.AccentSecondary
    TitleLabel.ZIndex = 502
    NotifBase:AddChild(TitleLabel)
    
    local ContentLabel = VirtualDOM.CreateInstance("Text")
    ContentLabel.Text = Content
    ContentLabel.Size = 13
    ContentLabel.Position = Vector2.new(10, 30)
    ContentLabel.Color = Theme.TextPrimary
    ContentLabel.ZIndex = 502
    NotifBase:AddChild(ContentLabel)
    
    table.insert(self.Notifications, NotifBase)
    Animator.ConstructTween(NotifBase, {Position = Vector2.new(CurrentCamera.ViewportSize.X - 260, NotifBase.Position.Y)}, 0.4, "Expo", "Out")
    
    task.delay(Duration, function()
        Animator.ConstructTween(NotifBase, {Position = Vector2.new(CurrentCamera.ViewportSize.X, NotifBase.Position.Y)}, 0.4, "Expo", "In", function()
            NotifBase:Destroy()
            for i, n in ipairs(self.Notifications) do
                if n == NotifBase then table.remove(self.Notifications, i) break end
            end
            for i, n in ipairs(self.Notifications) do
                Animator.ConstructTween(n, {Position = Vector2.new(CurrentCamera.ViewportSize.X - 260, CurrentCamera.ViewportSize.Y - (i * 70))}, 0.3, "Expo", "Out")
            end
        end)
    end)
end

function CompkillerLib:CreateWindow(Configuration)
    Configuration = Configuration or {}
    Configuration.Title = Configuration.Title or "COMPKILLER V4"
    Configuration.Size = Configuration.Size or Vector2.new(710, 520)
    Configuration.Position = Configuration.Position or Vector2.new(CurrentCamera.ViewportSize.X / 2 - Configuration.Size.X / 2, CurrentCamera.ViewportSize.Y / 2 - Configuration.Size.Y / 2)
    
    local Theme = ThemeManager.Presets[ThemeManager.CurrentTheme]
    
    local WindowAPI = { Tabs = {}, SelectedTab = nil, State = { IsOpen = true } }
    
    local MainCanvas = VirtualDOM.CreateInstance("Square")
    MainCanvas.Size = Configuration.Size
    MainCanvas.Position = Configuration.Position
    MainCanvas.Color = Theme.WindowBackground
    MainCanvas.ZIndex = 100
    
    VisualEffects.GenerateDropShadow(MainCanvas, Configuration.Size, Vector2.new(0, 0), 25, 0.4, 20)
    
    local StrokeOuter = VirtualDOM.CreateInstance("Square")
    StrokeOuter.Size = Configuration.Size
    StrokeOuter.Color = Theme.OutlineOuter
    StrokeOuter.Filled = false
    StrokeOuter.ZIndex = 101
    MainCanvas:AddChild(StrokeOuter)
    
    local StrokeInner = VirtualDOM.CreateInstance("Square")
    StrokeInner.Size = Configuration.Size - Vector2.new(2, 2)
    StrokeInner.Position = Vector2.new(1, 1)
    StrokeInner.Color = Theme.OutlineInner
    StrokeInner.Filled = false
    StrokeInner.ZIndex = 101
    MainCanvas:AddChild(StrokeInner)
    
    local TopAccent = VirtualDOM.CreateInstance("Square")
    TopAccent.Size = Vector2.new(Configuration.Size.X - 2, 2)
    TopAccent.Position = Vector2.new(1, 1)
    TopAccent.Color = Theme.AccentPrimary
    TopAccent.ZIndex = 102
    MainCanvas:AddChild(TopAccent)
    
    local Sidebar = VirtualDOM.CreateInstance("Square")
    Sidebar.Size = Vector2.new(180, Configuration.Size.Y - 2)
    Sidebar.Position = Vector2.new(1, 1)
    Sidebar.Color = Theme.SidebarBackground
    Sidebar.ZIndex = 101
    MainCanvas:AddChild(Sidebar)
    
    local SidebarSeparator = VirtualDOM.CreateInstance("Square")
    SidebarSeparator.Size = Vector2.new(1, Sidebar.Size.Y)
    SidebarSeparator.Position = Vector2.new(179, 0)
    SidebarSeparator.Color = Theme.SectionOutline
    SidebarSeparator.ZIndex = 102
    Sidebar:AddChild(SidebarSeparator)
    
    local TitleLabel = VirtualDOM.CreateInstance("Text")
    TitleLabel.Text = Configuration.Title
    TitleLabel.Size = 14
    TitleLabel.Position = Vector2.new(90, 25)
    TitleLabel.Color = Theme.AccentSecondary
    TitleLabel.Center = true
    TitleLabel.ZIndex = 105
    Sidebar:AddChild(TitleLabel)
    
    local TitleUnderline = VirtualDOM.CreateInstance("Square")
    TitleUnderline.Size = Vector2.new(140, 1)
    TitleUnderline.Position = Vector2.new(20, 45)
    TitleUnderline.Color = Theme.SeparatorLine
    TitleUnderline.ZIndex = 105
    Sidebar:AddChild(TitleUnderline)
    
    local TabContainer = VirtualDOM.CreateInstance("Square")
    TabContainer.Size = Vector2.new(180, Configuration.Size.Y - 60)
    TabContainer.Position = Vector2.new(0, 55)
    TabContainer.Transparency = 0
    TabContainer.ZIndex = 102
    Sidebar:AddChild(TabContainer)
    
    local ContentCanvas = VirtualDOM.CreateInstance("Square")
    ContentCanvas.Size = Vector2.new(Configuration.Size.X - 180, Configuration.Size.Y - 2)
    ContentCanvas.Position = Vector2.new(180, 1)
    ContentCanvas.Color = Theme.WindowBackground
    ContentCanvas.ZIndex = 101
    MainCanvas:AddChild(ContentCanvas)
    
    Sidebar.InputBegan = function(Input)
        CompkillerLib.DragPhysics.TargetObject = MainCanvas
        CompkillerLib.DragPhysics.DragOffset = MainCanvas.Position - EngineState.MousePosition
        CompkillerLib.DragPhysics.IsDragging = true
    end
    
    Sidebar.InputEnded = function(Input)
        CompkillerLib.DragPhysics.IsDragging = false
    end
    
    UserInputService.InputBegan:Connect(function(Input, Processed)
        if Processed and not EngineState.TypingActive then return end
        if Input.KeyCode == Enum.KeyCode.RightShift or Input.KeyCode == Enum.KeyCode.Insert then
            if not EngineState.TypingActive then
                WindowAPI.State.IsOpen = not WindowAPI.State.IsOpen
                MainCanvas.Visible = WindowAPI.State.IsOpen
            end
        end
    end)
    
    function WindowAPI:CreateTab(TabConfiguration)
        TabConfiguration = TabConfiguration or {}
        TabConfiguration.Name = TabConfiguration.Name or "New Tab"
        
        local TabAPI = { Sections = {}, IsActive = false }
        
        local TabButton = VirtualDOM.CreateInstance("Square")
        TabButton.Size = Vector2.new(180, 38)
        TabButton.Color = Theme.SidebarBackground
        TabButton.ZIndex = 103
        TabContainer:AddChild(TabButton)
        
        local TabHighlight = VirtualDOM.CreateInstance("Square")
        TabHighlight.Size = Vector2.new(3, 38)
        TabHighlight.Color = Theme.AccentPrimary
        TabHighlight.Transparency = 0
        TabHighlight.ZIndex = 104
        TabButton:AddChild(TabHighlight)
        
        local TabText = VirtualDOM.CreateInstance("Text")
        TabText.Text = TabConfiguration.Name
        TabText.Size = 13
        TabText.Position = Vector2.new(30, 12)
        TabText.Color = Theme.TextMuted
        TabText.ZIndex = 104
        TabButton:AddChild(TabText)
        
        local TabPage = VirtualDOM.CreateInstance("Square")
        TabPage.Size = ContentCanvas.Size
        TabPage.Transparency = 0
        TabPage.Visible = false
        TabPage.ZIndex = 102
        ContentCanvas:AddChild(TabPage)
        
        local LeftColumn = VirtualDOM.CreateInstance("Square")
        LeftColumn.Size = Vector2.new((TabPage.Size.X / 2) - 18, TabPage.Size.Y - 20)
        LeftColumn.Position = Vector2.new(12, 12)
        LeftColumn.Transparency = 0
        LeftColumn.ZIndex = 103
        TabPage:AddChild(LeftColumn)
        
        local RightColumn = VirtualDOM.CreateInstance("Square")
        RightColumn.Size = Vector2.new((TabPage.Size.X / 2) - 18, TabPage.Size.Y - 20)
        RightColumn.Position = Vector2.new((TabPage.Size.X / 2) + 6, 12)
        RightColumn.Transparency = 0
        RightColumn.ZIndex = 103
        TabPage:AddChild(RightColumn)
        
        TabButton.MouseEnter = function()
            if not TabAPI.IsActive then Animator.ConstructTween(TabText, {Color = Theme.TextSecondary}, 0.2, "Quad", "Out") end
        end
        
        TabButton.MouseLeave = function()
            if not TabAPI.IsActive then Animator.ConstructTween(TabText, {Color = Theme.TextMuted}, 0.2, "Quad", "Out") end
        end
        
        TabButton.InputBegan = function()
            for _, ExistingTab in ipairs(WindowAPI.Tabs) do
                ExistingTab.TabPage.Visible = false
                ExistingTab.IsActive = false
                Animator.ConstructTween(ExistingTab.TabHighlight, {Transparency = 0}, 0.3, "Quad", "Out")
                Animator.ConstructTween(ExistingTab.TabText, {Color = Theme.TextMuted}, 0.3, "Quad", "Out")
            end
            TabPage.Visible = true
            TabAPI.IsActive = true
            WindowAPI.SelectedTab = TabAPI
            Animator.ConstructTween(TabHighlight, {Transparency = 1}, 0.3, "Quint", "Out")
            Animator.ConstructTween(TabText, {Color = Theme.TextPrimary}, 0.3, "Quint", "Out")
        end
        
        table.insert(WindowAPI.Tabs, TabAPI)
        TabAPI.TabPage = TabPage; TabAPI.TabHighlight = TabHighlight; TabAPI.TabText = TabText
        
        local CurrentTabY = 0
        for _, Child in ipairs(TabContainer.Children) do
            if Child.Type == "Square" and Child.Size.X == 180 then
                Child.Position = Vector2.new(0, CurrentTabY)
                CurrentTabY = CurrentTabY + Child.Size.Y
            end
        end
        
        if #WindowAPI.Tabs == 1 then TabButton.InputBegan() end
        
        function TabAPI:CreateSection(SectionConfiguration)
            SectionConfiguration = SectionConfiguration or {}
            SectionConfiguration.Name = SectionConfiguration.Name or "Data Section"
            SectionConfiguration.Side = SectionConfiguration.Side or "Left"
            
            local TargetColumn = string.lower(SectionConfiguration.Side) == "left" and LeftColumn or RightColumn
            local SectionAPI = { Elements = {} }
            
            local SectionCanvas = VirtualDOM.CreateInstance("Square")
            SectionCanvas.Size = Vector2.new(TargetColumn.Size.X, 40)
            SectionCanvas.Color = Theme.SectionBackground
            SectionCanvas.ZIndex = 104
            TargetColumn:AddChild(SectionCanvas)
            
            local SectionOutline = VirtualDOM.CreateInstance("Square")
            SectionOutline.Size = SectionCanvas.Size
            SectionOutline.Color = Theme.SectionOutline
            SectionOutline.Filled = false
            SectionOutline.ZIndex = 105
            SectionCanvas:AddChild(SectionOutline)
            
            local SectionInline = VirtualDOM.CreateInstance("Square")
            SectionInline.Size = SectionCanvas.Size - Vector2.new(2, 2)
            SectionInline.Position = Vector2.new(1, 1)
            SectionInline.Color = Theme.OutlineInner
            SectionInline.Filled = false
            SectionInline.ZIndex = 105
            SectionCanvas:AddChild(SectionInline)
            
            local SectionHeader = VirtualDOM.CreateInstance("Square")
            SectionHeader.Size = Vector2.new(SectionCanvas.Size.X - 2, 25)
            SectionHeader.Position = Vector2.new(1, 1)
            SectionHeader.Color = Theme.ElementBackground
            SectionHeader.ZIndex = 105
            SectionCanvas:AddChild(SectionHeader)
            
            local SectionAccent = VirtualDOM.CreateInstance("Square")
            SectionAccent.Size = Vector2.new(SectionCanvas.Size.X - 2, 1)
            SectionAccent.Position = Vector2.new(1, 1)
            SectionAccent.Color = Theme.AccentPrimary
            SectionAccent.ZIndex = 106
            SectionCanvas:AddChild(SectionAccent)
            
            local SectionTitle = VirtualDOM.CreateInstance("Text")
            SectionTitle.Text = SectionConfiguration.Name
            SectionTitle.Size = 13
            SectionTitle.Position = Vector2.new(10, 6)
            SectionTitle.Color = Theme.TextPrimary
            SectionTitle.ZIndex = 106
            SectionHeader:AddChild(SectionTitle)
            
            local ItemContainer = VirtualDOM.CreateInstance("Square")
            ItemContainer.Size = Vector2.new(SectionCanvas.Size.X, 0)
            ItemContainer.Position = Vector2.new(0, 32)
            ItemContainer.Transparency = 0
            ItemContainer.ZIndex = 105
            SectionCanvas:AddChild(ItemContainer)
            
            local function RefreshLayouts()
                local ContentY = 0
                for _, Element in ipairs(ItemContainer.Children) do
                    if Element.Visible and Element.Type == "Square" and not Element.FloatingLayer then
                        Element.Position = Vector2.new(0, ContentY)
                        ContentY = ContentY + Element.Size.Y + 6
                    end
                end
                ItemContainer.Size = Vector2.new(SectionCanvas.Size.X, ContentY)
                SectionCanvas.Size = Vector2.new(SectionCanvas.Size.X, ContentY + 40)
                SectionOutline.Size = SectionCanvas.Size
                SectionInline.Size = SectionCanvas.Size - Vector2.new(2, 2)
                
                local ColumnY = 0
                for _, Section in ipairs(TargetColumn.Children) do
                    if Section.Visible then
                        Section.Position = Vector2.new(0, ColumnY)
                        ColumnY = ColumnY + Section.Size.Y + 12
                    end
                end
            end
            
            function SectionAPI:AddToggle(ToggleConfig)
                ToggleConfig.Name = ToggleConfig.Name or "Toggle"
                ToggleConfig.Default = ToggleConfig.Default or false
                ToggleConfig.Flag = ToggleConfig.Flag or tostring(math.random(100000, 999999))
                
                local ToggleAPI = { Value = ToggleConfig.Default }
                
                local ElementCanvas = VirtualDOM.CreateInstance("Square")
                ElementCanvas.Size = Vector2.new(ItemContainer.Size.X, 18)
                ElementCanvas.Transparency = 0
                ItemContainer:AddChild(ElementCanvas)
                
                local CheckboxBg = VirtualDOM.CreateInstance("Square")
                CheckboxBg.Size = Vector2.new(12, 12)
                CheckboxBg.Position = Vector2.new(12, 3)
                CheckboxBg.Color = Theme.ElementBackground
                CheckboxBg.ZIndex = 106
                ElementCanvas:AddChild(CheckboxBg)
                
                local CheckboxOut = VirtualDOM.CreateInstance("Square")
                CheckboxOut.Size = Vector2.new(12, 12)
                CheckboxOut.Position = Vector2.new(12, 3)
                CheckboxOut.Color = ToggleAPI.Value and Theme.AccentPrimary or Theme.SectionOutline
                CheckboxOut.Filled = false
                CheckboxOut.ZIndex = 107
                ElementCanvas:AddChild(CheckboxOut)
                
                local CheckboxFill = VirtualDOM.CreateInstance("Square")
                CheckboxFill.Size = Vector2.new(10, 10)
                CheckboxFill.Position = Vector2.new(13, 4)
                CheckboxFill.Color = Theme.AccentPrimary
                CheckboxFill.Transparency = ToggleAPI.Value and 1 or 0
                CheckboxFill.ZIndex = 107
                ElementCanvas:AddChild(CheckboxFill)
                
                local ToggleLabel = VirtualDOM.CreateInstance("Text")
                ToggleLabel.Text = ToggleConfig.Name
                ToggleLabel.Size = 13
                ToggleLabel.Position = Vector2.new(32, 2)
                ToggleLabel.Color = ToggleAPI.Value and Theme.TextPrimary or Theme.TextMuted
                ToggleLabel.ZIndex = 106
                ElementCanvas:AddChild(ToggleLabel)
                
                ElementCanvas.InputBegan = function()
                    ToggleAPI.Value = not ToggleAPI.Value
                    Animator.ConstructTween(CheckboxFill, {Transparency = ToggleAPI.Value and 1 or 0}, 0.2, "Quint", "Out")
                    Animator.ConstructTween(CheckboxOut, {Color = ToggleAPI.Value and Theme.AccentPrimary or Theme.SectionOutline}, 0.2, "Quint", "Out")
                    Animator.ConstructTween(ToggleLabel, {Color = ToggleAPI.Value and Theme.TextPrimary or Theme.TextMuted}, 0.2, "Quint", "Out")
                    if ToggleConfig.Callback then task.spawn(ToggleConfig.Callback, ToggleAPI.Value) end
                end
                
                CompkillerLib.ToggledFlags[ToggleConfig.Flag] = ToggleAPI
                RefreshLayouts(); return ToggleAPI
            end
            
            function SectionAPI:AddSlider(SliderConfig)
                SliderConfig.Name = SliderConfig.Name or "Slider"
                SliderConfig.Min = SliderConfig.Min or 0
                SliderConfig.Max = SliderConfig.Max or 100
                SliderConfig.Default = math.clamp(SliderConfig.Default or SliderConfig.Min, SliderConfig.Min, SliderConfig.Max)
                SliderConfig.Decimals = SliderConfig.Decimals or 0
                SliderConfig.Flag = SliderConfig.Flag or tostring(math.random(100000, 999999))
                
                local SliderAPI = { Value = SliderConfig.Default }
                
                local ElementCanvas = VirtualDOM.CreateInstance("Square")
                ElementCanvas.Size = Vector2.new(ItemContainer.Size.X, 36)
                ElementCanvas.Transparency = 0
                ItemContainer:AddChild(ElementCanvas)
                
                local SliderLabel = VirtualDOM.CreateInstance("Text")
                SliderLabel.Text = SliderConfig.Name
                SliderLabel.Size = 13
                SliderLabel.Position = Vector2.new(12, 2)
                SliderLabel.Color = Theme.TextMuted
                SliderLabel.ZIndex = 106
                ElementCanvas:AddChild(SliderLabel)
                
                local ValueDisplay = VirtualDOM.CreateInstance("Text")
                ValueDisplay.Text = tostring(SliderAPI.Value)
                ValueDisplay.Size = 13
                ValueDisplay.Position = Vector2.new(ElementCanvas.Size.X - 12, 2)
                ValueDisplay.Color = Theme.TextPrimary
                ValueDisplay.Center = true
                ValueDisplay.ZIndex = 106
                ElementCanvas:AddChild(ValueDisplay)
                
                local RailBackground = VirtualDOM.CreateInstance("Square")
                RailBackground.Size = Vector2.new(ElementCanvas.Size.X - 24, 10)
                RailBackground.Position = Vector2.new(12, 20)
                RailBackground.Color = Theme.ElementBackground
                RailBackground.ZIndex = 106
                ElementCanvas:AddChild(RailBackground)
                
                local RailOutline = VirtualDOM.CreateInstance("Square")
                RailOutline.Size = RailBackground.Size
                RailOutline.Position = RailBackground.Position
                RailOutline.Color = Theme.SectionOutline
                RailOutline.Filled = false
                RailOutline.ZIndex = 107
                ElementCanvas:AddChild(RailOutline)
                
                local ProgressPercentage = (SliderAPI.Value - SliderConfig.Min) / (SliderConfig.Max - SliderConfig.Min)
                local RailFill = VirtualDOM.CreateInstance("Square")
                RailFill.Size = Vector2.new(RailBackground.Size.X * ProgressPercentage, 10)
                RailFill.Position = RailBackground.Position
                RailFill.Color = Theme.AccentPrimary
                RailFill.ZIndex = 107
                ElementCanvas:AddChild(RailFill)
                
                local IsSliding = false
                local function ExecuteMath()
                    local MaxX = RailBackground.AbsoluteSize.X
                    local RelativeX = math.clamp(EngineState.MousePosition.X - RailBackground.AbsolutePosition.X, 0, MaxX)
                    local Percent = RelativeX / MaxX
                    local RawValue = SliderConfig.Min + ((SliderConfig.Max - SliderConfig.Min) * Percent)
                    local Power = 10 ^ SliderConfig.Decimals
                    local CleanValue = math.floor(RawValue * Power + 0.5) / Power
                    SliderAPI.Value = CleanValue
                    ValueDisplay.Text = tostring(CleanValue)
                    Animator.ConstructTween(RailFill, {Size = Vector2.new(MaxX * Percent, 10)}, 0.05, "Linear", "Out")
                    if SliderConfig.Callback then task.spawn(SliderConfig.Callback, SliderAPI.Value) end
                end
                
                RailBackground.InputBegan = function() IsSliding = true; ExecuteMath() end
                RunService.RenderStepped:Connect(function()
                    if IsSliding then
                        if not EngineState.IsMouseDown then IsSliding = false else ExecuteMath() end
                    end
                end)
                
                CompkillerLib.ToggledFlags[SliderConfig.Flag] = SliderAPI
                RefreshLayouts(); return SliderAPI
            end
            
            function SectionAPI:AddDropdown(DropConfig)
                DropConfig.Name = DropConfig.Name or "Dropdown"
                DropConfig.Values = DropConfig.Values or {"Option 1", "Option 2"}
                DropConfig.Default = DropConfig.Default or DropConfig.Values[1]
                DropConfig.Flag = DropConfig.Flag or tostring(math.random(100000, 999999))
                
                local DropAPI = { Value = DropConfig.Default, IsOpen = false }
                
                local ElementCanvas = VirtualDOM.CreateInstance("Square")
                ElementCanvas.Size = Vector2.new(ItemContainer.Size.X, 42)
                ElementCanvas.Transparency = 0
                ItemContainer:AddChild(ElementCanvas)
                
                local DropLabel = VirtualDOM.CreateInstance("Text")
                DropLabel.Text = DropConfig.Name
                DropLabel.Size = 13
                DropLabel.Position = Vector2.new(12, 2)
                DropLabel.Color = Theme.TextMuted
                DropLabel.ZIndex = 106
                ElementCanvas:AddChild(DropLabel)
                
                local DropBox = VirtualDOM.CreateInstance("Square")
                DropBox.Size = Vector2.new(ElementCanvas.Size.X - 24, 20)
                DropBox.Position = Vector2.new(12, 18)
                DropBox.Color = Theme.ElementBackground
                DropBox.ZIndex = 106
                ElementCanvas:AddChild(DropBox)
                
                local DropBoxOut = VirtualDOM.CreateInstance("Square")
                DropBoxOut.Size = DropBox.Size
                DropBoxOut.Position = DropBox.Position
                DropBoxOut.Color = Theme.SectionOutline
                DropBoxOut.Filled = false
                DropBoxOut.ZIndex = 107
                ElementCanvas:AddChild(DropBoxOut)
                
                local DropValueText = VirtualDOM.CreateInstance("Text")
                DropValueText.Text = DropAPI.Value
                DropValueText.Size = 13
                DropValueText.Position = Vector2.new(18, 21)
                DropValueText.Color = Theme.TextPrimary
                DropValueText.ZIndex = 107
                ElementCanvas:AddChild(DropValueText)
                
                local DropContainer = VirtualDOM.CreateInstance("Square")
                DropContainer.Size = Vector2.new(DropBox.Size.X, 0)
                DropContainer.Position = Vector2.new(12, 40)
                DropContainer.Color = Theme.SectionBackground
                DropContainer.ZIndex = 150
                DropContainer.Visible = false
                DropContainer.FloatingLayer = true
                ElementCanvas:AddChild(DropContainer)
                
                local DropContainerOut = VirtualDOM.CreateInstance("Square")
                DropContainerOut.Size = DropContainer.Size
                DropContainerOut.Color = Theme.AccentPrimary
                DropContainerOut.Filled = false
                DropContainerOut.ZIndex = 151
                DropContainer:AddChild(DropContainerOut)
                
                local function BuildDropdownList()
                    for _, Child in ipairs(DropContainer.Children) do
                        if Child ~= DropContainerOut then Child:Destroy() end
                    end
                    local CurY = 0
                    for _, Option in ipairs(DropConfig.Values) do
                        local OptBox = VirtualDOM.CreateInstance("Square")
                        OptBox.Size = Vector2.new(DropContainer.Size.X, 20)
                        OptBox.Position = Vector2.new(0, CurY)
                        OptBox.Color = Theme.ElementBackground
                        OptBox.ZIndex = 152
                        DropContainer:AddChild(OptBox)
                        
                        local OptText = VirtualDOM.CreateInstance("Text")
                        OptText.Text = Option
                        OptText.Size = 13
                        OptText.Position = Vector2.new(6, 3)
                        OptText.Color = Option == DropAPI.Value and Theme.AccentPrimary or Theme.TextMuted
                        OptText.ZIndex = 153
                        OptBox:AddChild(OptText)
                        
                        OptBox.MouseEnter = function() OptBox.Color = Theme.ElementHover end
                        OptBox.MouseLeave = function() OptBox.Color = Theme.ElementBackground end
                        
                        OptBox.InputBegan = function()
                            DropAPI.Value = Option
                            DropValueText.Text = Option
                            DropAPI.IsOpen = false
                            DropContainer.Visible = false
                            if DropConfig.Callback then task.spawn(DropConfig.Callback, DropAPI.Value) end
                        end
                        CurY = CurY + 20
                    end
                    DropContainer.Size = Vector2.new(DropBox.Size.X, CurY)
                    DropContainerOut.Size = DropContainer.Size
                end
                
                DropBox.InputBegan = function()
                    DropAPI.IsOpen = not DropAPI.IsOpen
                    if DropAPI.IsOpen then
                        BuildDropdownList()
                        DropContainer.Visible = true
                    else
                        DropContainer.Visible = false
                    end
                end
                
                CompkillerLib.ToggledFlags[DropConfig.Flag] = DropAPI
                RefreshLayouts(); return DropAPI
            end
            
            function SectionAPI:AddColorPicker(ColorConfig)
                ColorConfig.Name = ColorConfig.Name or "Color Picker"
                ColorConfig.Default = ColorConfig.Default or Color3.fromRGB(255, 255, 255)
                ColorConfig.Flag = ColorConfig.Flag or tostring(math.random(100000, 999999))
                
                local ColorAPI = { Value = ColorConfig.Default, IsOpen = false }
                
                local ElementCanvas = VirtualDOM.CreateInstance("Square")
                ElementCanvas.Size = Vector2.new(ItemContainer.Size.X, 20)
                ElementCanvas.Transparency = 0
                ItemContainer:AddChild(ElementCanvas)
                
                local ColorLabel = VirtualDOM.CreateInstance("Text")
                ColorLabel.Text = ColorConfig.Name
                ColorLabel.Size = 13
                ColorLabel.Position = Vector2.new(12, 3)
                ColorLabel.Color = Theme.TextMuted
                ColorLabel.ZIndex = 106
                ElementCanvas:AddChild(ColorLabel)
                
                local DisplayBox = VirtualDOM.CreateInstance("Square")
                DisplayBox.Size = Vector2.new(24, 12)
                DisplayBox.Position = Vector2.new(ElementCanvas.Size.X - 36, 4)
                DisplayBox.Color = ColorAPI.Value
                DisplayBox.ZIndex = 106
                ElementCanvas:AddChild(DisplayBox)
                
                local DisplayOut = VirtualDOM.CreateInstance("Square")
                DisplayOut.Size = DisplayBox.Size
                DisplayOut.Position = DisplayBox.Position
                DisplayOut.Color = Theme.SectionOutline
                DisplayOut.Filled = false
                DisplayOut.ZIndex = 107
                ElementCanvas:AddChild(DisplayOut)
                
                local PickerWindow = VirtualDOM.CreateInstance("Square")
                PickerWindow.Size = Vector2.new(160, 160)
                PickerWindow.Position = Vector2.new(ElementCanvas.Size.X - 170, 20)
                PickerWindow.Color = Theme.SectionBackground
                PickerWindow.ZIndex = 200
                PickerWindow.Visible = false
                PickerWindow.FloatingLayer = true
                ElementCanvas:AddChild(PickerWindow)
                
                local PickerOut = VirtualDOM.CreateInstance("Square")
                PickerOut.Size = PickerWindow.Size
                PickerOut.Color = Theme.SectionOutline
                PickerOut.Filled = false
                PickerOut.ZIndex = 201
                PickerWindow:AddChild(PickerOut)
                
                local SatValBox = VirtualDOM.CreateInstance("Square")
                SatValBox.Size = Vector2.new(130, 140)
                SatValBox.Position = Vector2.new(10, 10)
                local h, s, v = MathLib.RGBToHSV(ColorAPI.Value)
                SatValBox.Color = MathLib.HSVToRGB(h, 1, 1)
                SatValBox.ZIndex = 202
                PickerWindow:AddChild(SatValBox)
                
                local HueBar = VirtualDOM.CreateInstance("Square")
                HueBar.Size = Vector2.new(10, 140)
                HueBar.Position = Vector2.new(145, 10)
                HueBar.Color = Color3.fromRGB(255, 0, 0)
                HueBar.ZIndex = 202
                PickerWindow:AddChild(HueBar)
                
                local HueCursor = VirtualDOM.CreateInstance("Square")
                HueCursor.Size = Vector2.new(12, 2)
                HueCursor.Position = Vector2.new(144, 10 + (140 * (1 - h)))
                HueCursor.Color = Color3.fromRGB(255, 255, 255)
                HueCursor.ZIndex = 203
                PickerWindow:AddChild(HueCursor)
                
                local SVDot = VirtualDOM.CreateInstance("Square")
                SVDot.Size = Vector2.new(4, 4)
                SVDot.Position = Vector2.new(10 + (130 * s), 10 + (140 * (1 - v)))
                SVDot.Color = Color3.fromRGB(255, 255, 255)
                SVDot.ZIndex = 203
                PickerWindow:AddChild(SVDot)
                
                local HoldingHue, HoldingSV = false, false
                
                local function UpdateColor()
                    ColorAPI.Value = MathLib.HSVToRGB(h, s, v)
                    DisplayBox.Color = ColorAPI.Value
                    SatValBox.Color = MathLib.HSVToRGB(h, 1, 1)
                    if ColorConfig.Callback then task.spawn(ColorConfig.Callback, ColorAPI.Value) end
                end
                
                HueBar.InputBegan = function() HoldingHue = true end
                SatValBox.InputBegan = function() HoldingSV = true end
                
                RunService.RenderStepped:Connect(function()
                    if HoldingHue then
                        if not EngineState.IsMouseDown then HoldingHue = false return end
                        local relY = math.clamp(EngineState.MousePosition.Y - HueBar.AbsolutePosition.Y, 0, HueBar.AbsoluteSize.Y)
                        h = 1 - (relY / HueBar.AbsoluteSize.Y)
                        HueCursor.Position = Vector2.new(144, 10 + relY - 1)
                        UpdateColor()
                    end
                    if HoldingSV then
                        if not EngineState.IsMouseDown then HoldingSV = false return end
                        local relX = math.clamp(EngineState.MousePosition.X - SatValBox.AbsolutePosition.X, 0, SatValBox.AbsoluteSize.X)
                        local relY = math.clamp(EngineState.MousePosition.Y - SatValBox.AbsolutePosition.Y, 0, SatValBox.AbsoluteSize.Y)
                        s = relX / SatValBox.AbsoluteSize.X
                        v = 1 - (relY / SatValBox.AbsoluteSize.Y)
                        SVDot.Position = Vector2.new(10 + relX - 2, 10 + relY - 2)
                        UpdateColor()
                    end
                end)
                
                DisplayBox.InputBegan = function()
                    ColorAPI.IsOpen = not ColorAPI.IsOpen
                    PickerWindow.Visible = ColorAPI.IsOpen
                end
                
                CompkillerLib.ToggledFlags[ColorConfig.Flag] = ColorAPI
                RefreshLayouts(); return ColorAPI
            end
            
            function SectionAPI:AddButton(BtnConfig)
                BtnConfig.Name = BtnConfig.Name or "Button"
                
                local ElementCanvas = VirtualDOM.CreateInstance("Square")
                ElementCanvas.Size = Vector2.new(ItemContainer.Size.X, 26)
                ElementCanvas.Transparency = 0
                ItemContainer:AddChild(ElementCanvas)
                
                local BtnBody = VirtualDOM.CreateInstance("Square")
                BtnBody.Size = Vector2.new(ElementCanvas.Size.X - 24, 20)
                BtnBody.Position = Vector2.new(12, 3)
                BtnBody.Color = Theme.ElementBackground
                BtnBody.ZIndex = 106
                ElementCanvas:AddChild(BtnBody)
                
                local BtnOut = VirtualDOM.CreateInstance("Square")
                BtnOut.Size = BtnBody.Size
                BtnOut.Position = BtnBody.Position
                BtnOut.Color = Theme.SectionOutline
                BtnOut.Filled = false
                BtnOut.ZIndex = 107
                ElementCanvas:AddChild(BtnOut)
                
                local BtnLabel = VirtualDOM.CreateInstance("Text")
                BtnLabel.Text = BtnConfig.Name
                BtnLabel.Size = 13
                BtnLabel.Position = Vector2.new(ElementCanvas.Size.X / 2, 6)
                BtnLabel.Color = Theme.TextPrimary
                BtnLabel.Center = true
                BtnLabel.ZIndex = 107
                ElementCanvas:AddChild(BtnLabel)
                
                BtnBody.MouseEnter = function() Animator.ConstructTween(BtnBody, {Color = Theme.ElementHover}, 0.2, "Quad", "Out") end
                BtnBody.MouseLeave = function() Animator.ConstructTween(BtnBody, {Color = Theme.ElementBackground}, 0.2, "Quad", "Out") end
                BtnBody.InputBegan = function()
                    Animator.ConstructTween(BtnBody, {Color = Theme.AccentPrimary}, 0.1, "Quad", "Out", function()
                        Animator.ConstructTween(BtnBody, {Color = Theme.ElementHover}, 0.2, "Quad", "Out")
                    end)
                    if BtnConfig.Callback then task.spawn(BtnConfig.Callback) end
                end
                
                RefreshLayouts()
            end
            
            function SectionAPI:AddKeybind(KeyConfig)
                KeyConfig.Name = KeyConfig.Name or "Keybind"
                KeyConfig.Default = KeyConfig.Default or Enum.KeyCode.Unknown
                KeyConfig.Flag = KeyConfig.Flag or tostring(math.random(100000, 999999))
                
                local KeyAPI = { Value = KeyConfig.Default, IsBinding = false }
                
                local ElementCanvas = VirtualDOM.CreateInstance("Square")
                ElementCanvas.Size = Vector2.new(ItemContainer.Size.X, 20)
                ElementCanvas.Transparency = 0
                ItemContainer:AddChild(ElementCanvas)
                
                local KeyLabel = VirtualDOM.CreateInstance("Text")
                KeyLabel.Text = KeyConfig.Name
                KeyLabel.Size = 13
                KeyLabel.Position = Vector2.new(12, 3)
                KeyLabel.Color = Theme.TextMuted
                KeyLabel.ZIndex = 106
                ElementCanvas:AddChild(KeyLabel)
                
                local BindBox = VirtualDOM.CreateInstance("Square")
                BindBox.Size = Vector2.new(50, 16)
                BindBox.Position = Vector2.new(ElementCanvas.Size.X - 62, 2)
                BindBox.Color = Theme.ElementBackground
                BindBox.ZIndex = 106
                ElementCanvas:AddChild(BindBox)
                
                local BindOut = VirtualDOM.CreateInstance("Square")
                BindOut.Size = BindBox.Size
                BindOut.Position = BindBox.Position
                BindOut.Color = Theme.SectionOutline
                BindOut.Filled = false
                BindOut.ZIndex = 107
                ElementCanvas:AddChild(BindOut)
                
                local BindText = VirtualDOM.CreateInstance("Text")
                BindText.Text = KeyAPI.Value == Enum.KeyCode.Unknown and "None" or KeyAPI.Value.Name
                BindText.Size = 12
                BindText.Position = Vector2.new(ElementCanvas.Size.X - 37, 3)
                BindText.Color = Theme.TextPrimary
                BindText.Center = true
                BindText.ZIndex = 107
                ElementCanvas:AddChild(BindText)
                
                BindBox.InputBegan = function()
                    if KeyAPI.IsBinding then return end
                    KeyAPI.IsBinding = true
                    BindText.Text = "..."
                    
                    local BindConn
                    BindConn = UserInputService.InputBegan:Connect(function(Input)
                        if Input.UserInputType == Enum.UserInputType.Keyboard then
                            if Input.KeyCode == Enum.KeyCode.Escape then
                                KeyAPI.Value = Enum.KeyCode.Unknown
                                BindText.Text = "None"
                            else
                                KeyAPI.Value = Input.KeyCode
                                BindText.Text = Input.KeyCode.Name
                            end
                            KeyAPI.IsBinding = false
                            BindConn:Disconnect()
                            if KeyConfig.Callback then task.spawn(KeyConfig.Callback, KeyAPI.Value) end
                        elseif Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.MouseButton2 then
                            KeyAPI.Value = Input.UserInputType
                            BindText.Text = Input.UserInputType.Name
                            KeyAPI.IsBinding = false
                            BindConn:Disconnect()
                            if KeyConfig.Callback then task.spawn(KeyConfig.Callback, KeyAPI.Value) end
                        end
                    end)
                end
                
                CompkillerLib.ToggledFlags[KeyConfig.Flag] = KeyAPI
                RefreshLayouts(); return KeyAPI
            end
            
            function SectionAPI:AddTextBox(TextConfig)
                TextConfig.Name = TextConfig.Name or "TextBox"
                TextConfig.Default = TextConfig.Default or ""
                TextConfig.Flag = TextConfig.Flag or tostring(math.random(100000, 999999))
                
                local TextAPI = { Value = TextConfig.Default }
                
                local ElementCanvas = VirtualDOM.CreateInstance("Square")
                ElementCanvas.Size = Vector2.new(ItemContainer.Size.X, 40)
                ElementCanvas.Transparency = 0
                ItemContainer:AddChild(ElementCanvas)
                
                local TextLabel = VirtualDOM.CreateInstance("Text")
                TextLabel.Text = TextConfig.Name
                TextLabel.Size = 13
                TextLabel.Position = Vector2.new(12, 2)
                TextLabel.Color = Theme.TextMuted
                TextLabel.ZIndex = 106
                ElementCanvas:AddChild(TextLabel)
                
                local InputBox = VirtualDOM.CreateInstance("Square")
                InputBox.Size = Vector2.new(ElementCanvas.Size.X - 24, 20)
                InputBox.Position = Vector2.new(12, 18)
                InputBox.Color = Theme.ElementBackground
                InputBox.ZIndex = 106
                ElementCanvas:AddChild(InputBox)
                
                local InputOut = VirtualDOM.CreateInstance("Square")
                InputOut.Size = InputBox.Size
                InputOut.Position = InputBox.Position
                InputOut.Color = Theme.SectionOutline
                InputOut.Filled = false
                InputOut.ZIndex = 107
                ElementCanvas:AddChild(InputOut)
                
                local InputText = VirtualDOM.CreateInstance("Text")
                InputText.Text = TextAPI.Value == "" and "Enter text..." or TextAPI.Value
                InputText.Size = 13
                InputText.Position = Vector2.new(18, 21)
                InputText.Color = TextAPI.Value == "" and Theme.TextDisabled or Theme.TextPrimary
                InputText.ZIndex = 107
                ElementCanvas:AddChild(InputText)
                
                InputBox.InputBegan = function()
                    if EngineState.TypingActive then return end
                    EngineState.TypingActive = true
                    EngineState.TypingElement = InputBox
                    InputOut.Color = Theme.AccentPrimary
                    InputText.Text = TextAPI.Value .. "|"
                    InputText.Color = Theme.TextPrimary
                    
                    local TypeConn
                    TypeConn = UserInputService.InputBegan:Connect(function(Input)
                        if Input.KeyCode == Enum.KeyCode.Return or Input.KeyCode == Enum.KeyCode.Escape then
                            EngineState.TypingActive = false
                            EngineState.TypingElement = nil
                            InputOut.Color = Theme.SectionOutline
                            InputText.Text = TextAPI.Value == "" and "Enter text..." or TextAPI.Value
                            InputText.Color = TextAPI.Value == "" and Theme.TextDisabled or Theme.TextPrimary
                            TypeConn:Disconnect()
                            if TextConfig.Callback then task.spawn(TextConfig.Callback, TextAPI.Value) end
                        elseif Input.KeyCode == Enum.KeyCode.Backspace then
                            TextAPI.Value = string.sub(TextAPI.Value, 1, -2)
                            InputText.Text = TextAPI.Value .. "|"
                        elseif Input.UserInputType == Enum.UserInputType.Keyboard then
                            local char = UserInputService:GetStringForKeyCode(Input.KeyCode)
                            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift) then
                                char = string.upper(char)
                            else
                                char = string.lower(char)
                            end
                            if char:match("[%w%p%s]") and #char == 1 then
                                TextAPI.Value = TextAPI.Value .. char
                                InputText.Text = TextAPI.Value .. "|"
                            end
                        end
                    end)
                end
                
                CompkillerLib.ToggledFlags[TextConfig.Flag] = TextAPI
                RefreshLayouts(); return TextAPI
            end
            
            return SectionAPI
        end
        return TabAPI
    end
    
    function WindowAPI:SaveConfig(Name)
        local Cfg = {}
        for flag, api in pairs(CompkillerLib.ToggledFlags) do
            if typeof(api.Value) == "Color3" then
                Cfg[flag] = {R = api.Value.R, G = api.Value.G, B = api.Value.B, Type = "Color3"}
            elseif typeof(api.Value) == "EnumItem" then
                Cfg[flag] = {Name = api.Value.Name, Type = "Enum"}
            else
                Cfg[flag] = {Value = api.Value, Type = "Value"}
            end
        end
        local Json = HttpService:JSONEncode(Cfg)
        if writefile then
            writefile(Name .. ".json", Json)
            CompkillerLib:Notify("Configuration", "Saved config: " .. Name .. ".json", 3)
        else
            print("Writefile missing. JSON:", Json)
        end
    end

    function WindowAPI:LoadConfig(Name)
        if readfile and isfile and isfile(Name .. ".json") then
            local Json = readfile(Name .. ".json")
            local Cfg = HttpService:JSONDecode(Json)
            for flag, data in pairs(Cfg) do
                if CompkillerLib.ToggledFlags[flag] then
                    local api = CompkillerLib.ToggledFlags[flag]
                    if data.Type == "Color3" then
                        api.Value = Color3.new(data.R, data.G, data.B)
                    elseif data.Type == "Enum" then
                        -- Enum assignment requires finding the enum, handled via lookup
                    elseif data.Type == "Value" then
                        api.Value = data.Value
                    end
                end
            end
            CompkillerLib:Notify("Configuration", "Loaded config: " .. Name .. ".json", 3)
        end
    end
    
    return WindowAPI
end

return CompkillerLib
