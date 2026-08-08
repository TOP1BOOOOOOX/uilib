--[[
    ===========================================================================
    COMPKILLER // ADVANCED DRAWING API RENDERING ENGINE
    VERSION: 4.0.0 (RAW VIRTUAL DOM IMPLEMENTATION)
    ARCHITECTURE: LUAU
    
    DESCRIPTION:
    This is the hyper-detailed, fully unrolled implementation of the Compkiller
    interface utilizing strictly the Roblox Drawing API. It bypasses all native 
    UI objects (Instance.new("Frame"), etc.) to remain entirely undetected.
    
    FEATURES INCLUDED IN THIS KERNEL:
    - Custom Robert Penner Easing Library
    - Kinetic Friction & Inertia Physics Engine
    - Multi-Layered Drop Shadow Generation
    - Virtual Document Object Model (VDOM)
    - Sub-Pixel Interpolation
    - Exhaustive Theme State Machine
    - Z-Index Sorting & Layer Compositing
    ===========================================================================
--]]

-- [ SERVICE DECLARATIONS ] --
local CoreGui               = game:GetService("CoreGui")
local HttpService           = game:GetService("HttpService")
local UserInputService      = game:GetService("UserInputService")
local RunService            = game:GetService("RunService")
local TweenService          = game:GetService("TweenService")
local Workspace             = game:GetService("Workspace")
local Players               = game:GetService("Players")

-- [ LOCAL DEFINITIONS ] --
local LocalPlayer           = Players.LocalPlayer
local CurrentCamera         = Workspace.CurrentCamera
local Mouse                 = LocalPlayer:GetMouse()

-- [ ENGINE CONFIGURATION ] --
local EngineState = {
    Initialized             = false,
    RenderQueue             = {},
    TweenQueue              = {},
    PhysicsQueue            = {},
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
    GarbageCollection       = {}
}

-- [ MASSIVE THEME ARCHITECTURE ] --
local ThemeManager = {
    CurrentTheme = "Dark",
    Presets = {
        Dark = {
            -- Backgrounds
            WindowBackground          = Color3.fromRGB(15, 15, 20),
            SidebarBackground         = Color3.fromRGB(12, 12, 17),
            SectionBackground         = Color3.fromRGB(20, 21, 26),
            ElementBackground         = Color3.fromRGB(25, 26, 31),
            ElementHover              = Color3.fromRGB(32, 33, 38),
            ElementActive             = Color3.fromRGB(40, 41, 48),
            
            -- Borders & Outlines
            OutlineOuter              = Color3.fromRGB(35, 36, 42),
            OutlineInner              = Color3.fromRGB(28, 29, 34),
            SectionOutline            = Color3.fromRGB(35, 36, 42),
            SeparatorLine             = Color3.fromRGB(45, 45, 55),
            
            -- Accents
            AccentPrimary             = Color3.fromRGB(13, 185, 195),
            AccentSecondary           = Color3.fromRGB(17, 238, 253),
            AccentHover               = Color3.fromRGB(20, 255, 255),
            AccentDark                = Color3.fromRGB(9, 130, 140),
            
            -- Typography
            TextPrimary               = Color3.fromRGB(255, 255, 255),
            TextSecondary             = Color3.fromRGB(180, 180, 190),
            TextMuted                 = Color3.fromRGB(120, 120, 130),
            TextDisabled              = Color3.fromRGB(80, 80, 90),
            
            -- Status Colors
            Success                   = Color3.fromRGB(46, 204, 113),
            Warning                   = Color3.fromRGB(241, 196, 15),
            Danger                    = Color3.fromRGB(231, 76, 60),
            Info                      = Color3.fromRGB(52, 152, 219),
            
            -- Shadows
            ShadowColor               = Color3.fromRGB(0, 0, 0),
            ShadowOpacity             = 0.6
        }
    }
}

-- [ MATH & GEOMETRY KERNEL ] --
local MathLib = {}

function MathLib.Lerp(Start, End, Alpha)
    return Start + (End - Start) * Alpha
end

function MathLib.Clamp(Value, Min, Max)
    if Value < Min then
        return Min
    elseif Value > Max then
        return Max
    end
    return Value
end

function MathLib.Round(Value, DecimalPlaces)
    local Multiplier = 10 ^ (DecimalPlaces or 0)
    return math.floor(Value * Multiplier + 0.5) / Multiplier
end

function MathLib.LerpVector2(StartVec, EndVec, Alpha)
    local X = MathLib.Lerp(StartVec.X, EndVec.X, Alpha)
    local Y = MathLib.Lerp(StartVec.Y, EndVec.Y, Alpha)
    return Vector2.new(X, Y)
end

function MathLib.LerpColor3(StartCol, EndCol, Alpha)
    local R = MathLib.Lerp(StartCol.R, EndCol.R, Alpha)
    local G = MathLib.Lerp(StartCol.G, EndCol.G, Alpha)
    local B = MathLib.Lerp(StartCol.B, EndCol.B, Alpha)
    return Color3.new(R, G, B)
end

function MathLib.CalculateDistance(VecA, VecB)
    local DX = VecA.X - VecB.X
    local DY = VecA.Y - VecB.Y
    return math.sqrt((DX * DX) + (DY * DY))
end

function MathLib.PointInRectangle(Point, RectPosition, RectSize)
    local MinX = RectPosition.X
    local MinY = RectPosition.Y
    local MaxX = RectPosition.X + RectSize.X
    local MaxY = RectPosition.Y + RectSize.Y
    
    if Point.X >= MinX and Point.X <= MaxX then
        if Point.Y >= MinY and Point.Y <= MaxY then
            return true
        end
    end
    
    return false
end

-- [ CUSTOM EASING ENGINE (ROBERT PENNER EQUATIONS) ] --
-- Since native UI uses TweenService, and Drawing API objects cannot be passed
-- to TweenService, we must build an exhaustive mathematical tweening engine.
local EasingLib = {}

-- Linear
function EasingLib.Linear(t, b, c, d)
    return c * t / d + b
end

-- Sine
function EasingLib.InSine(t, b, c, d)
    return -c * math.cos(t / d * (math.pi / 2)) + c + b
end

function EasingLib.OutSine(t, b, c, d)
    return c * math.sin(t / d * (math.pi / 2)) + b
end

function EasingLib.InOutSine(t, b, c, d)
    return -c / 2 * (math.cos(math.pi * t / d) - 1) + b
end

-- Quad
function EasingLib.InQuad(t, b, c, d)
    t = t / d
    return c * math.pow(t, 2) + b
end

function EasingLib.OutQuad(t, b, c, d)
    t = t / d
    return -c * t * (t - 2) + b
end

function EasingLib.InOutQuad(t, b, c, d)
    t = t / d * 2
    if t < 1 then
        return c / 2 * math.pow(t, 2) + b
    else
        return -c / 2 * ((t - 1) * (t - 3) - 1) + b
    end
end

-- Cubic
function EasingLib.InCubic(t, b, c, d)
    t = t / d
    return c * math.pow(t, 3) + b
end

function EasingLib.OutCubic(t, b, c, d)
    t = t / d - 1
    return c * (math.pow(t, 3) + 1) + b
end

function EasingLib.InOutCubic(t, b, c, d)
    t = t / d * 2
    if t < 1 then
        return c / 2 * t * t * t + b
    else
        t = t - 2
        return c / 2 * (t * t * t + 2) + b
    end
end

-- Quart
function EasingLib.InQuart(t, b, c, d)
    t = t / d
    return c * math.pow(t, 4) + b
end

function EasingLib.OutQuart(t, b, c, d)
    t = t / d - 1
    return -c * (math.pow(t, 4) - 1) + b
end

function EasingLib.InOutQuart(t, b, c, d)
    t = t / d * 2
    if t < 1 then
        return c / 2 * math.pow(t, 4) + b
    else
        t = t - 2
        return -c / 2 * (math.pow(t, 4) - 2) + b
    end
end

-- Quint
function EasingLib.InQuint(t, b, c, d)
    t = t / d
    return c * math.pow(t, 5) + b
end

function EasingLib.OutQuint(t, b, c, d)
    t = t / d - 1
    return c * (math.pow(t, 5) + 1) + b
end

function EasingLib.InOutQuint(t, b, c, d)
    t = t / d * 2
    if t < 1 then
        return c / 2 * math.pow(t, 5) + b
    else
        t = t - 2
        return c / 2 * (math.pow(t, 5) + 2) + b
    end
end

-- Expo
function EasingLib.InExpo(t, b, c, d)
    if t == 0 then
        return b
    else
        return c * math.pow(2, 10 * (t / d - 1)) + b - c * 0.001
    end
end

function EasingLib.OutExpo(t, b, c, d)
    if t == d then
        return b + c
    else
        return c * 1.001 * (-math.pow(2, -10 * t / d) + 1) + b
    end
end

function EasingLib.InOutExpo(t, b, c, d)
    if t == 0 then return b end
    if t == d then return b + c end
    t = t / d * 2
    if t < 1 then
        return c / 2 * math.pow(2, 10 * (t - 1)) + b - c * 0.0005
    else
        t = t - 1
        return c / 2 * 1.0005 * (-math.pow(2, -10 * t) + 2) + b
    end
end

-- Circ
function EasingLib.InCirc(t, b, c, d)
    t = t / d
    return -c * (math.sqrt(1 - math.pow(t, 2)) - 1) + b
end

function EasingLib.OutCirc(t, b, c, d)
    t = t / d - 1
    return c * math.sqrt(1 - math.pow(t, 2)) + b
end

function EasingLib.InOutCirc(t, b, c, d)
    t = t / d * 2
    if t < 1 then
        return -c / 2 * (math.sqrt(1 - t * t) - 1) + b
    else
        t = t - 2
        return c / 2 * (math.sqrt(1 - t * t) + 1) + b
    end
end

-- [ TWEEN ANIMATION MANAGER ] --
local Animator = {}

function Animator.ConstructTween(Object, Properties, Duration, EasingStyle, EasingDirection, Callback)
    EasingStyle = EasingStyle or "Quad"
    EasingDirection = EasingDirection or "Out"
    
    local EasingFunctionName = EasingDirection .. EasingStyle
    if EasingStyle == "Linear" then
        EasingFunctionName = "Linear"
    end
    
    local EasingFunction = EasingLib[EasingFunctionName] or EasingLib.OutQuad
    
    local StartProperties = {}
    local ChangeProperties = {}
    
    for Property, EndValue in pairs(Properties) do
        StartProperties[Property] = Object[Property]
        ChangeProperties[Property] = EndValue
    end
    
    local TweenData = {
        Object = Object,
        Start = StartProperties,
        Target = ChangeProperties,
        Duration = Duration,
        TimeElapsed = 0,
        Easing = EasingFunction,
        OnComplete = Callback,
        IsCompleted = false
    }
    
    table.insert(EngineState.TweenQueue, TweenData)
    return TweenData
end

function Animator.CancelTween(Object)
    for i = #EngineState.TweenQueue, 1, -1 do
        local TweenObj = EngineState.TweenQueue[i]
        if TweenObj.Object == Object then
            table.remove(EngineState.TweenQueue, i)
        end
    end
end

-- [ VIRTUAL DOCUMENT OBJECT MODEL (VDOM) ] --
-- Creating a custom hierarchy and rendering loop wrapper around the 
-- primitive Drawing API objects to simulate full UI instances.
local VirtualDOM = {}
VirtualDOM.__index = VirtualDOM

function VirtualDOM.CreateInstance(Type)
    local self = setmetatable({}, VirtualDOM)
    self.Type = Type
    self.RenderObject = Drawing.new(Type)
    self.Children = {}
    self.Parent = nil
    
    -- Absolute/Relative Positioning System
    self.Position = Vector2.new(0, 0)
    self.Size = Vector2.new(0, 0)
    self.AbsolutePosition = Vector2.new(0, 0)
    self.AbsoluteSize = Vector2.new(0, 0)
    
    -- Display Properties
    self.Visible = true
    self.ZIndex = 1
    self.Transparency = 1
    self.Color = Color3.new(1, 1, 1)
    
    -- Specific Properties based on Type
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
    elseif Type == "Image" then
        self.Data = nil
        self.Rounding = 0
    elseif Type == "Circle" then
        self.Radius = 0
        self.Filled = false
        self.NumSides = 64
        self.Thickness = 1
    end
    
    -- Event Hooks
    self.InputBegan = nil
    self.InputEnded = nil
    self.MouseEnter = nil
    self.MouseLeave = nil
    
    -- Registration
    table.insert(EngineState.RenderQueue, self)
    
    return self
end

function VirtualDOM:AddChild(ChildInstance)
    ChildInstance.Parent = self
    table.insert(self.Children, ChildInstance)
end

function VirtualDOM:RemoveChild(ChildInstance)
    for i, Child in ipairs(self.Children) do
        if Child == ChildInstance then
            ChildInstance.Parent = nil
            table.remove(self.Children, i)
            break
        end
    end
end

function VirtualDOM:Destroy()
    -- Deep clean recursive destruction
    for _, Child in ipairs(self.Children) do
        Child:Destroy()
    end
    
    if self.Parent then
        self.Parent:RemoveChild(self)
    end
    
    for i, Instance in ipairs(EngineState.RenderQueue) do
        if Instance == self then
            table.remove(EngineState.RenderQueue, i)
            break
        end
    end
    
    Animator.CancelTween(self)
    
    if self.RenderObject then
        self.RenderObject:Remove()
        self.RenderObject = nil
    end
    
    setmetatable(self, nil)
end

function VirtualDOM:UpdateTransformations()
    if self.Parent then
        self.AbsolutePosition = self.Parent.AbsolutePosition + self.Position
    else
        self.AbsolutePosition = self.Position
    end
    
    self.AbsoluteSize = self.Size
end

function VirtualDOM:RenderToScreen()
    if not self.RenderObject then return end
    
    -- Visibility Inheritence Check
    if not self.Visible then
        self.RenderObject.Visible = false
        return
    end
    
    local CurrentNode = self.Parent
    local IsVisibleHierarchy = true
    
    while CurrentNode do
        if not CurrentNode.Visible then
            IsVisibleHierarchy = false
            break
        end
        CurrentNode = CurrentNode.Parent
    end
    
    if not IsVisibleHierarchy then
        self.RenderObject.Visible = false
        return
    end
    
    -- Math Update
    self:UpdateTransformations()
    
    -- Apply Base Properties
    self.RenderObject.Visible = true
    self.RenderObject.ZIndex = self.ZIndex
    self.RenderObject.Transparency = self.Transparency
    self.RenderObject.Color = self.Color
    
    -- Apply Type Specifics
    if self.Type == "Square" then
        self.RenderObject.Position = self.AbsolutePosition
        self.RenderObject.Size = self.AbsoluteSize
        self.RenderObject.Filled = self.Filled
        self.RenderObject.Thickness = self.Thickness
        
    elseif self.Type == "Text" then
        self.RenderObject.Position = self.AbsolutePosition
        self.RenderObject.Text = self.Text
        self.RenderObject.Size = self.TextSize
        self.RenderObject.Center = self.Center
        self.RenderObject.Outline = self.Outline
        self.RenderObject.OutlineColor = self.OutlineColor
        self.RenderObject.Font = self.Font
        
    elseif self.Type == "Line" then
        self.RenderObject.From = self.AbsolutePosition
        self.RenderObject.To = self.AbsolutePosition + self.AbsoluteSize
        self.RenderObject.Thickness = self.Thickness
        
    elseif self.Type == "Image" then
        self.RenderObject.Position = self.AbsolutePosition
        self.RenderObject.Size = self.AbsoluteSize
        if self.Data then
            self.RenderObject.Data = self.Data
        end
        
    elseif self.Type == "Circle" then
        self.RenderObject.Position = self.AbsolutePosition
        self.RenderObject.Radius = self.Radius
        self.RenderObject.Filled = self.Filled
        self.RenderObject.NumSides = self.NumSides
        self.RenderObject.Thickness = self.Thickness
    end
end

-- [ HIGH-FIDELITY SHADING & GRADIENT ENGINE ] --
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

function VisualEffects.GenerateVerticalGradient(ParentNode, Size, ColorTop, ColorBottom, Resolution)
    local GradientGroup = {}
    local StepHeight = Size.Y / Resolution
    
    for i = 0, Resolution - 1 do
        local Alpha = i / (Resolution - 1)
        local CurrentColor = MathLib.LerpColor3(ColorTop, ColorBottom, Alpha)
        
        local GradientLine = VirtualDOM.CreateInstance("Square")
        GradientLine.Size = Vector2.new(Size.X, StepHeight + 1)
        GradientLine.Position = Vector2.new(0, i * StepHeight)
        GradientLine.Color = CurrentColor
        GradientLine.Filled = true
        GradientLine.ZIndex = ParentNode.ZIndex + 1
        GradientLine.Transparency = 1
        
        ParentNode:AddChild(GradientLine)
        table.insert(GradientGroup, GradientLine)
    end
    
    return GradientGroup
end

-- [ MASTER RENDER PIPELINE ] --
local function ProcessRenderPipeline(DeltaTime)
    EngineState.TimeElapsed = EngineState.TimeElapsed + DeltaTime
    EngineState.DeltaTime = DeltaTime
    
    -- Capture input metrics
    local CurrentMouseLocation = UserInputService:GetMouseLocation()
    EngineState.MouseDelta = CurrentMouseLocation - EngineState.PreviousMousePosition
    EngineState.PreviousMousePosition = CurrentMouseLocation
    EngineState.MousePosition = CurrentMouseLocation
    
    -- Process Tween Queue
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
            if Tween.OnComplete then
                task.spawn(Tween.OnComplete)
            end
            table.remove(EngineState.TweenQueue, i)
        end
    end
    
    -- Z-Index Sorting
    table.sort(EngineState.RenderQueue, function(A, B)
        return A.ZIndex < B.ZIndex
    end)
    
    -- Render & Collision Detection Pipeline
    local TopMostHoveredElement = nil
    
    for i, Element in ipairs(EngineState.RenderQueue) do
        Element:RenderToScreen()
        
        -- Intersection Logic
        if Element.Visible and Element.RenderObject and Element.RenderObject.Visible then
            if Element.MouseEnter or Element.InputBegan then
                if MathLib.PointInRectangle(EngineState.MousePosition, Element.AbsolutePosition, Element.AbsoluteSize) then
                    TopMostHoveredElement = Element
                end
            end
        end
    end
    
    -- Fire Interaction Events
    if TopMostHoveredElement ~= EngineState.HoveredElements.Current then
        if EngineState.HoveredElements.Current and EngineState.HoveredElements.Current.MouseLeave then
            task.spawn(EngineState.HoveredElements.Current.MouseLeave)
        end
        
        EngineState.HoveredElements.Current = TopMostHoveredElement
        
        if TopMostHoveredElement and TopMostHoveredElement.MouseEnter then
            task.spawn(TopMostHoveredElement.MouseEnter)
        end
    end
end

RunService.RenderStepped:Connect(ProcessRenderPipeline)

-- [ INPUT MANAGEMENT ENGINE ] --
UserInputService.InputBegan:Connect(function(Input, GameProcessedEvent)
    if Input.UserInputType == Enum.UserInputType.MouseButton1 then
        EngineState.IsMouseDown = true
        
        if EngineState.HoveredElements.Current and EngineState.HoveredElements.Current.InputBegan then
            EngineState.ActiveInputTarget = EngineState.HoveredElements.Current
            task.spawn(EngineState.HoveredElements.Current.InputBegan, Input)
        end
    elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
        EngineState.IsRightMouseDown = true
    end
end)

UserInputService.InputEnded:Connect(function(Input, GameProcessedEvent)
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

-- [ COMPKILLER LIBRARY CORE ] --
local CompkillerLib = {
    Instances               = {},
    KeybindData             = {},
    ToggledFlags            = {},
    DragPhysics             = {
        TargetObject        = nil,
        DragOffset          = Vector2.new(0, 0),
        Velocity            = Vector2.new(0, 0),
        Friction            = 0.85,
        IsDragging          = false
    }
}

-- Kinetic Drag Integration
RunService.RenderStepped:Connect(function()
    local Physics = CompkillerLib.DragPhysics
    if Physics.IsDragging and Physics.TargetObject then
        local TargetPosition = EngineState.MousePosition + Physics.DragOffset
        Physics.Velocity = (TargetPosition - Physics.TargetObject.Position) * 0.4
        Physics.TargetObject.Position = Physics.TargetObject.Position + Physics.Velocity
    elseif Physics.TargetObject and not Physics.IsDragging then
        -- Inertia dampening
        if math.abs(Physics.Velocity.X) > 0.1 or math.abs(Physics.Velocity.Y) > 0.1 then
            Physics.Velocity = Physics.Velocity * Physics.Friction
            Physics.TargetObject.Position = Physics.TargetObject.Position + Physics.Velocity
        else
            Physics.TargetObject = nil
        end
    end
end)

--=============================================================================
-- COMPONENT CONSTRUCTORS
--=============================================================================

function CompkillerLib:CreateWindow(Configuration)
    Configuration = Configuration or {}
    Configuration.Title = Configuration.Title or "COMPKILLER V4"
    Configuration.Size = Configuration.Size or Vector2.new(710, 520)
    Configuration.Position = Configuration.Position or Vector2.new(
        CurrentCamera.ViewportSize.X / 2 - Configuration.Size.X / 2,
        CurrentCamera.ViewportSize.Y / 2 - Configuration.Size.Y / 2
    )
    
    local Theme = ThemeManager.Presets[ThemeManager.CurrentTheme]
    
    local WindowAPI = {
        Tabs = {},
        SelectedTab = nil,
        State = {
            IsOpen = true,
            IsMinimized = false
        }
    }
    
    -- Primary Background Canvas
    local MainCanvas = VirtualDOM.CreateInstance("Square")
    MainCanvas.Size = Configuration.Size
    MainCanvas.Position = Configuration.Position
    MainCanvas.Color = Theme.WindowBackground
    MainCanvas.ZIndex = 100
    
    -- Sophisticated Layered Drop Shadow
    VisualEffects.GenerateDropShadow(MainCanvas, Configuration.Size, Vector2.new(0, 0), 25, 0.4, 20)
    
    -- Outer Inline Stroke
    local StrokeOuter = VirtualDOM.CreateInstance("Square")
    StrokeOuter.Size = Configuration.Size
    StrokeOuter.Color = Theme.OutlineOuter
    StrokeOuter.Filled = false
    StrokeOuter.ZIndex = 101
    MainCanvas:AddChild(StrokeOuter)
    
    -- Inner Inline Stroke
    local StrokeInner = VirtualDOM.CreateInstance("Square")
    StrokeInner.Size = Configuration.Size - Vector2.new(2, 2)
    StrokeInner.Position = Vector2.new(1, 1)
    StrokeInner.Color = Theme.OutlineInner
    StrokeInner.Filled = false
    StrokeInner.ZIndex = 101
    MainCanvas:AddChild(StrokeInner)
    
    -- Top Accent Bar (Gradient Emulated)
    local TopAccent = VirtualDOM.CreateInstance("Square")
    TopAccent.Size = Vector2.new(Configuration.Size.X - 2, 2)
    TopAccent.Position = Vector2.new(1, 1)
    TopAccent.Color = Theme.AccentPrimary
    TopAccent.ZIndex = 102
    MainCanvas:AddChild(TopAccent)
    
    -- Layout: Sidebar Navigation
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
    
    -- Branding
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
    
    -- Tab Navigation Container
    local TabContainer = VirtualDOM.CreateInstance("Square")
    TabContainer.Size = Vector2.new(180, Configuration.Size.Y - 60)
    TabContainer.Position = Vector2.new(0, 55)
    TabContainer.Transparency = 0
    TabContainer.ZIndex = 102
    Sidebar:AddChild(TabContainer)
    
    -- Dynamic Content Canvas
    local ContentCanvas = VirtualDOM.CreateInstance("Square")
    ContentCanvas.Size = Vector2.new(Configuration.Size.X - 180, Configuration.Size.Y - 2)
    ContentCanvas.Position = Vector2.new(180, 1)
    ContentCanvas.Color = Theme.WindowBackground
    ContentCanvas.ZIndex = 101
    MainCanvas:AddChild(ContentCanvas)
    
    -- Drag Hook logic
    Sidebar.InputBegan = function(Input)
        CompkillerLib.DragPhysics.TargetObject = MainCanvas
        CompkillerLib.DragPhysics.DragOffset = MainCanvas.Position - EngineState.MousePosition
        CompkillerLib.DragPhysics.IsDragging = true
    end
    
    Sidebar.InputEnded = function(Input)
        CompkillerLib.DragPhysics.IsDragging = false
    end
    
    -- Toggle Keybind
    UserInputService.InputBegan:Connect(function(Input, Processed)
        if Processed then return end
        if Input.KeyCode == Enum.KeyCode.RightShift or Input.KeyCode == Enum.KeyCode.Insert then
            WindowAPI.State.IsOpen = not WindowAPI.State.IsOpen
            MainCanvas.Visible = WindowAPI.State.IsOpen
        end
    end)
    
    -- ==========================================
    -- COMPONENT: TAB GENERATOR
    -- ==========================================
    function WindowAPI:CreateTab(TabConfiguration)
        TabConfiguration = TabConfiguration or {}
        TabConfiguration.Name = TabConfiguration.Name or "New Tab"
        
        local TabAPI = {
            Sections = {},
            IsActive = false
        }
        
        local TabButton = VirtualDOM.CreateInstance("Square")
        TabButton.Size = Vector2.new(180, 38)
        TabButton.Color = Theme.SidebarBackground
        TabButton.ZIndex = 103
        TabContainer:AddChild(TabButton)
        
        local TabHighlight = VirtualDOM.CreateInstance("Square")
        TabHighlight.Size = Vector2.new(3, 38)
        TabHighlight.Position = Vector2.new(0, 0)
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
        TabPage.Position = Vector2.new(0, 0)
        TabPage.Transparency = 0
        TabPage.Visible = false
        TabPage.ZIndex = 102
        ContentCanvas:AddChild(TabPage)
        
        -- Dual Column Layout Architecture
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
        
        -- Tab Interaction Logic
        TabButton.MouseEnter = function()
            if not TabAPI.IsActive then
                Animator.ConstructTween(TabText, {Color = Theme.TextSecondary}, 0.2, "Quad", "Out")
            end
        end
        
        TabButton.MouseLeave = function()
            if not TabAPI.IsActive then
                Animator.ConstructTween(TabText, {Color = Theme.TextMuted}, 0.2, "Quad", "Out")
            end
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
        TabAPI.TabPage = TabPage
        TabAPI.TabHighlight = TabHighlight
        TabAPI.TabText = TabText
        
        -- Layout Organizer for Tabs
        local CurrentTabY = 0
        for _, Child in ipairs(TabContainer.Children) do
            if Child.Type == "Square" and Child.Size.X == 180 then
                Child.Position = Vector2.new(0, CurrentTabY)
                CurrentTabY = CurrentTabY + Child.Size.Y
            end
        end
        
        -- Initialize First Tab
        if #WindowAPI.Tabs == 1 then
            TabButton.InputBegan()
        end
        
        -- ==========================================
        -- COMPONENT: SECTION GENERATOR
        -- ==========================================
        function TabAPI:CreateSection(SectionConfiguration)
            SectionConfiguration = SectionConfiguration or {}
            SectionConfiguration.Name = SectionConfiguration.Name or "Data Section"
            SectionConfiguration.Side = SectionConfiguration.Side or "Left"
            
            local TargetColumn = string.lower(SectionConfiguration.Side) == "left" and LeftColumn or RightColumn
            
            local SectionAPI = {
                Elements = {}
            }
            
            local SectionCanvas = VirtualDOM.CreateInstance("Square")
            SectionCanvas.Size = Vector2.new(TargetColumn.Size.X, 40) -- Dynamic height
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
                -- Calculate internal section height
                local ContentY = 0
                for _, Element in ipairs(ItemContainer.Children) do
                    if Element.Visible then
                        Element.Position = Vector2.new(0, ContentY)
                        ContentY = ContentY + Element.Size.Y + 6
                    end
                end
                
                ItemContainer.Size = Vector2.new(SectionCanvas.Size.X, ContentY)
                SectionCanvas.Size = Vector2.new(SectionCanvas.Size.X, ContentY + 40)
                SectionOutline.Size = SectionCanvas.Size
                SectionInline.Size = SectionCanvas.Size - Vector2.new(2, 2)
                
                -- Calculate column height mapping
                local ColumnY = 0
                for _, Section in ipairs(TargetColumn.Children) do
                    if Section.Visible then
                        Section.Position = Vector2.new(0, ColumnY)
                        ColumnY = ColumnY + Section.Size.Y + 12
                    end
                end
            end
            
            -- ==========================================
            -- SUB-COMPONENT: TOGGLE
            -- ==========================================
            function SectionAPI:AddToggle(ToggleConfig)
                ToggleConfig.Name = ToggleConfig.Name or "Feature Toggle"
                ToggleConfig.Default = ToggleConfig.Default or false
                ToggleConfig.Flag = ToggleConfig.Flag or tostring(math.random(100000, 999999))
                
                local ToggleAPI = {
                    Value = ToggleConfig.Default
                }
                
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
                
                local function FireToggle()
                    Animator.ConstructTween(CheckboxFill, {Transparency = ToggleAPI.Value and 1 or 0}, 0.2, "Quint", "Out")
                    Animator.ConstructTween(CheckboxOut, {Color = ToggleAPI.Value and Theme.AccentPrimary or Theme.SectionOutline}, 0.2, "Quint", "Out")
                    Animator.ConstructTween(ToggleLabel, {Color = ToggleAPI.Value and Theme.TextPrimary or Theme.TextMuted}, 0.2, "Quint", "Out")
                    
                    if ToggleConfig.Callback then
                        task.spawn(ToggleConfig.Callback, ToggleAPI.Value)
                    end
                end
                
                ElementCanvas.MouseEnter = function()
                    if not ToggleAPI.Value then
                        Animator.ConstructTween(ToggleLabel, {Color = Theme.TextSecondary}, 0.15, "Quad", "Out")
                    end
                end
                
                ElementCanvas.MouseLeave = function()
                    if not ToggleAPI.Value then
                        Animator.ConstructTween(ToggleLabel, {Color = Theme.TextMuted}, 0.15, "Quad", "Out")
                    end
                end
                
                ElementCanvas.InputBegan = function()
                    ToggleAPI.Value = not ToggleAPI.Value
                    FireToggle()
                end
                
                CompkillerLib.ToggledFlags[ToggleConfig.Flag] = ToggleAPI
                RefreshLayouts()
                return ToggleAPI
            end
            
            -- ==========================================
            -- SUB-COMPONENT: SLIDER
            -- ==========================================
            function SectionAPI:AddSlider(SliderConfig)
                SliderConfig.Name = SliderConfig.Name or "Value Slider"
                SliderConfig.Min = SliderConfig.Min or 0
                SliderConfig.Max = SliderConfig.Max or 100
                SliderConfig.Default = math.clamp(SliderConfig.Default or SliderConfig.Min, SliderConfig.Min, SliderConfig.Max)
                SliderConfig.Decimals = SliderConfig.Decimals or 0
                SliderConfig.Flag = SliderConfig.Flag or tostring(math.random(100000, 999999))
                
                local SliderAPI = {
                    Value = SliderConfig.Default
                }
                
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
                    
                    if SliderConfig.Callback then
                        task.spawn(SliderConfig.Callback, SliderAPI.Value)
                    end
                end
                
                RailBackground.InputBegan = function()
                    IsSliding = true
                    Animator.ConstructTween(SliderLabel, {Color = Theme.TextPrimary}, 0.2, "Quad", "Out")
                    ExecuteMath()
                end
                
                RunService.RenderStepped:Connect(function()
                    if IsSliding then
                        if not EngineState.IsMouseDown then
                            IsSliding = false
                            Animator.ConstructTween(SliderLabel, {Color = Theme.TextMuted}, 0.2, "Quad", "Out")
                        else
                            ExecuteMath()
                        end
                    end
                end)
                
                CompkillerLib.ToggledFlags[SliderConfig.Flag] = SliderAPI
                RefreshLayouts()
                return SliderAPI
            end
            
            return SectionAPI
        end
        return TabAPI
    end
    return WindowAPI
end

return CompkillerLib
