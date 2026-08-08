--[[
    =======================================================================================================================
    COMPKILLER // ADVANCED DRAWING API RENDERING ENGINE (EXTENDED VIRTUAL DOM)
    ARCHITECTURE: LUAU
    =======================================================================================================================
--]]

local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local CurrentCamera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

local EngineState = {
    Initialized = false,
    RenderQueue = {},
    TweenQueue = {},
    HoveredElements = {},
    ActiveInputTarget = nil,
    MousePosition = Vector2.new(0, 0),
    PreviousMousePosition = Vector2.new(0, 0),
    MouseDelta = Vector2.new(0, 0),
    IsMouseDown = false,
    IsRightMouseDown = false,
    TimeElapsed = 0,
    DeltaTime = 0,
    Resolution = CurrentCamera.ViewportSize,
    InputBeganConnection = nil,
    InputEndedConnection = nil,
    RenderConnection = nil,
    TypingActive = false,
    TypingElement = nil
}

local ThemeManager = {
    CurrentTheme = "Dark",
    Presets = {}
}

ThemeManager.Presets["Dark"] = {
    WindowBackground = Color3.fromRGB(15, 15, 20),
    SidebarBackground = Color3.fromRGB(12, 12, 17),
    SectionBackground = Color3.fromRGB(20, 21, 26),
    ElementBackground = Color3.fromRGB(25, 26, 31),
    ElementHover = Color3.fromRGB(32, 33, 38),
    ElementActive = Color3.fromRGB(40, 41, 48),
    OutlineOuter = Color3.fromRGB(35, 36, 42),
    OutlineInner = Color3.fromRGB(28, 29, 34),
    SectionOutline = Color3.fromRGB(35, 36, 42),
    SeparatorLine = Color3.fromRGB(45, 45, 55),
    AccentPrimary = Color3.fromRGB(13, 185, 195),
    AccentSecondary = Color3.fromRGB(17, 238, 253),
    AccentHover = Color3.fromRGB(20, 255, 255),
    AccentDark = Color3.fromRGB(9, 130, 140),
    TextPrimary = Color3.fromRGB(255, 255, 255),
    TextSecondary = Color3.fromRGB(180, 180, 190),
    TextMuted = Color3.fromRGB(120, 120, 130),
    TextDisabled = Color3.fromRGB(80, 80, 90),
    Success = Color3.fromRGB(46, 204, 113),
    Warning = Color3.fromRGB(241, 196, 15),
    Danger = Color3.fromRGB(231, 76, 60),
    Info = Color3.fromRGB(52, 152, 219),
    ShadowColor = Color3.fromRGB(0, 0, 0),
    ShadowOpacity = 0.6
}

ThemeManager.Presets["Light"] = {
    WindowBackground = Color3.fromRGB(240, 240, 245),
    SidebarBackground = Color3.fromRGB(230, 230, 235),
    SectionBackground = Color3.fromRGB(245, 245, 250),
    ElementBackground = Color3.fromRGB(250, 250, 255),
    ElementHover = Color3.fromRGB(235, 235, 240),
    ElementActive = Color3.fromRGB(220, 220, 225),
    OutlineOuter = Color3.fromRGB(200, 200, 205),
    OutlineInner = Color3.fromRGB(210, 210, 215),
    SectionOutline = Color3.fromRGB(200, 200, 205),
    SeparatorLine = Color3.fromRGB(190, 190, 195),
    AccentPrimary = Color3.fromRGB(13, 185, 195),
    AccentSecondary = Color3.fromRGB(17, 238, 253),
    AccentHover = Color3.fromRGB(20, 255, 255),
    AccentDark = Color3.fromRGB(9, 130, 140),
    TextPrimary = Color3.fromRGB(20, 20, 25),
    TextSecondary = Color3.fromRGB(60, 60, 65),
    TextMuted = Color3.fromRGB(100, 100, 105),
    TextDisabled = Color3.fromRGB(140, 140, 145),
    Success = Color3.fromRGB(46, 204, 113),
    Warning = Color3.fromRGB(241, 196, 15),
    Danger = Color3.fromRGB(231, 76, 60),
    Info = Color3.fromRGB(52, 152, 219),
    ShadowColor = Color3.fromRGB(0, 0, 0),
    ShadowOpacity = 0.3
}

ThemeManager.Presets["Midnight"] = {
    WindowBackground = Color3.fromRGB(5, 5, 8),
    SidebarBackground = Color3.fromRGB(8, 8, 12),
    SectionBackground = Color3.fromRGB(10, 10, 15),
    ElementBackground = Color3.fromRGB(15, 15, 20),
    ElementHover = Color3.fromRGB(20, 20, 25),
    ElementActive = Color3.fromRGB(25, 25, 30),
    OutlineOuter = Color3.fromRGB(20, 20, 25),
    OutlineInner = Color3.fromRGB(15, 15, 20),
    SectionOutline = Color3.fromRGB(25, 25, 30),
    SeparatorLine = Color3.fromRGB(30, 30, 35),
    AccentPrimary = Color3.fromRGB(147, 112, 219),
    AccentSecondary = Color3.fromRGB(138, 43, 226),
    AccentHover = Color3.fromRGB(186, 85, 211),
    AccentDark = Color3.fromRGB(75, 0, 130),
    TextPrimary = Color3.fromRGB(255, 255, 255),
    TextSecondary = Color3.fromRGB(200, 200, 200),
    TextMuted = Color3.fromRGB(150, 150, 150),
    TextDisabled = Color3.fromRGB(100, 100, 100),
    Success = Color3.fromRGB(0, 255, 127),
    Warning = Color3.fromRGB(255, 215, 0),
    Danger = Color3.fromRGB(220, 20, 60),
    Info = Color3.fromRGB(30, 144, 255),
    ShadowColor = Color3.fromRGB(0, 0, 0),
    ShadowOpacity = 0.8
}

local MathLib = {}

function MathLib.Lerp(Start, End, Alpha)
    local Difference = End - Start
    local Progress = Difference * Alpha
    local Result = Start + Progress
    return Result
end

function MathLib.Clamp(Value, Min, Max)
    if Value < Min then
        return Min
    end
    if Value > Max then
        return Max
    end
    return Value
end

function MathLib.Round(Value, DecimalPlaces)
    local Power = DecimalPlaces or 0
    local Multiplier = math.pow(10, Power)
    local ShiftedValue = Value * Multiplier
    local RoundedValue = math.floor(ShiftedValue + 0.5)
    local FinalValue = RoundedValue / Multiplier
    return FinalValue
end

function MathLib.LerpVector2(StartVec, EndVec, Alpha)
    local XStart = StartVec.X
    local YStart = StartVec.Y
    local XEnd = EndVec.X
    local YEnd = EndVec.Y
    local XLerp = MathLib.Lerp(XStart, XEnd, Alpha)
    local YLerp = MathLib.Lerp(YStart, YEnd, Alpha)
    local Result = Vector2.new(XLerp, YLerp)
    return Result
end

function MathLib.LerpColor3(StartCol, EndCol, Alpha)
    local RStart = StartCol.R
    local GStart = StartCol.G
    local BStart = StartCol.B
    local REnd = EndCol.R
    local GEnd = EndCol.G
    local BEnd = EndCol.B
    local RLerp = MathLib.Lerp(RStart, REnd, Alpha)
    local GLerp = MathLib.Lerp(GStart, GEnd, Alpha)
    local BLerp = MathLib.Lerp(BStart, BEnd, Alpha)
    local Result = Color3.new(RLerp, GLerp, BLerp)
    return Result
end

function MathLib.PointInRectangle(Point, RectPosition, RectSize)
    local PointX = Point.X
    local PointY = Point.Y
    local RectX = RectPosition.X
    local RectY = RectPosition.Y
    local RectWidth = RectSize.X
    local RectHeight = RectSize.Y
    local MaxX = RectX + RectWidth
    local MaxY = RectY + RectHeight
    
    local XValid = false
    local YValid = false
    
    if PointX >= RectX then
        if PointX <= MaxX then
            XValid = true
        end
    end
    
    if PointY >= RectY then
        if PointY <= MaxY then
            YValid = true
        end
    end
    
    if XValid == true then
        if YValid == true then
            return true
        end
    end
    
    return false
end

function MathLib.HSVToRGB(Hue, Saturation, Value)
    local R = 0
    local G = 0
    local B = 0
    local I = math.floor(Hue * 6)
    local F = Hue * 6 - I
    local P = Value * (1 - Saturation)
    local Q = Value * (1 - F * Saturation)
    local T = Value * (1 - (1 - F) * Saturation)
    I = I % 6
    if I == 0 then
        R = Value
        G = T
        B = P
    elseif I == 1 then
        R = Q
        G = Value
        B = P
    elseif I == 2 then
        R = P
        G = Value
        B = T
    elseif I == 3 then
        R = P
        G = Q
        B = Value
    elseif I == 4 then
        R = T
        G = P
        B = Value
    elseif I == 5 then
        R = Value
        G = P
        B = Q
    end
    local Result = Color3.new(R, G, B)
    return Result
end

function MathLib.RGBToHSV(Color)
    local R = Color.R
    local G = Color.G
    local B = Color.B
    local MaxValue = math.max(R, G, B)
    local MinValue = math.min(R, G, B)
    local Hue = 0
    local Saturation = 0
    local Value = MaxValue
    local Difference = MaxValue - MinValue
    
    if MaxValue == 0 then
        Saturation = 0
    else
        Saturation = Difference / MaxValue
    end
    
    if MaxValue == MinValue then
        Hue = 0
    else
        if MaxValue == R then
            Hue = (G - B) / Difference
            if G < B then
                Hue = Hue + 6
            end
        elseif MaxValue == G then
            Hue = (B - R) / Difference + 2
        elseif MaxValue == B then
            Hue = (R - G) / Difference + 4
        end
        Hue = Hue / 6
    end
    
    return Hue, Saturation, Value
end

local EasingLib = {}

function EasingLib.Linear(Time, Begin, Change, Duration)
    local Progress = Time / Duration
    local Value = Change * Progress
    local Result = Value + Begin
    return Result
end

function EasingLib.InQuad(Time, Begin, Change, Duration)
    local Progress = Time / Duration
    local Value = Progress * Progress
    local Result = Change * Value + Begin
    return Result
end

function EasingLib.OutQuad(Time, Begin, Change, Duration)
    local Progress = Time / Duration
    local Value = Progress * (Progress - 2)
    local Result = -Change * Value + Begin
    return Result
end

function EasingLib.InOutQuad(Time, Begin, Change, Duration)
    local Progress = Time / (Duration / 2)
    if Progress < 1 then
        local Value = Change / 2 * Progress * Progress
        local Result = Value + Begin
        return Result
    end
    Progress = Progress - 1
    local Value = -Change / 2 * (Progress * (Progress - 2) - 1)
    local Result = Value + Begin
    return Result
end

function EasingLib.InCubic(Time, Begin, Change, Duration)
    local Progress = Time / Duration
    local Value = Progress * Progress * Progress
    local Result = Change * Value + Begin
    return Result
end

function EasingLib.OutCubic(Time, Begin, Change, Duration)
    local Progress = Time / Duration - 1
    local Value = Progress * Progress * Progress + 1
    local Result = Change * Value + Begin
    return Result
end

function EasingLib.InOutCubic(Time, Begin, Change, Duration)
    local Progress = Time / (Duration / 2)
    if Progress < 1 then
        local Value = Change / 2 * Progress * Progress * Progress
        local Result = Value + Begin
        return Result
    end
    Progress = Progress - 2
    local Value = Change / 2 * (Progress * Progress * Progress + 2)
    local Result = Value + Begin
    return Result
end

function EasingLib.InQuart(Time, Begin, Change, Duration)
    local Progress = Time / Duration
    local Value = Progress * Progress * Progress * Progress
    local Result = Change * Value + Begin
    return Result
end

function EasingLib.OutQuart(Time, Begin, Change, Duration)
    local Progress = Time / Duration - 1
    local Value = Progress * Progress * Progress * Progress - 1
    local Result = -Change * Value + Begin
    return Result
end

function EasingLib.InOutQuart(Time, Begin, Change, Duration)
    local Progress = Time / (Duration / 2)
    if Progress < 1 then
        local Value = Change / 2 * Progress * Progress * Progress * Progress
        local Result = Value + Begin
        return Result
    end
    Progress = Progress - 2
    local Value = -Change / 2 * (Progress * Progress * Progress * Progress - 2)
    local Result = Value + Begin
    return Result
end

function EasingLib.InQuint(Time, Begin, Change, Duration)
    local Progress = Time / Duration
    local Value = math.pow(Progress, 5)
    local Result = Change * Value + Begin
    return Result
end

function EasingLib.OutQuint(Time, Begin, Change, Duration)
    local Progress = Time / Duration - 1
    local Value = math.pow(Progress, 5) + 1
    local Result = Change * Value + Begin
    return Result
end

function EasingLib.InOutQuint(Time, Begin, Change, Duration)
    local Progress = Time / (Duration / 2)
    if Progress < 1 then
        local Value = Change / 2 * math.pow(Progress, 5)
        local Result = Value + Begin
        return Result
    end
    Progress = Progress - 2
    local Value = Change / 2 * (math.pow(Progress, 5) + 2)
    local Result = Value + Begin
    return Result
end

function EasingLib.InSine(Time, Begin, Change, Duration)
    local Progress = Time / Duration
    local Value = math.cos(Progress * (math.pi / 2))
    local Result = -Change * Value + Change + Begin
    return Result
end

function EasingLib.OutSine(Time, Begin, Change, Duration)
    local Progress = Time / Duration
    local Value = math.sin(Progress * (math.pi / 2))
    local Result = Change * Value + Begin
    return Result
end

function EasingLib.InOutSine(Time, Begin, Change, Duration)
    local Progress = Time / Duration
    local Value = math.cos(math.pi * Progress) - 1
    local Result = -Change / 2 * Value + Begin
    return Result
end

function EasingLib.InExpo(Time, Begin, Change, Duration)
    if Time == 0 then
        return Begin
    end
    local Progress = Time / Duration - 1
    local Value = math.pow(2, 10 * Progress)
    local Result = Change * Value + Begin
    return Result
end

function EasingLib.OutExpo(Time, Begin, Change, Duration)
    if Time == Duration then
        local Result = Begin + Change
        return Result
    end
    local Progress = Time / Duration
    local Value = -math.pow(2, -10 * Progress) + 1
    local Result = Change * 1.001 * Value + Begin
    return Result
end

function EasingLib.InOutExpo(Time, Begin, Change, Duration)
    if Time == 0 then
        return Begin
    end
    if Time == Duration then
        local Result = Begin + Change
        return Result
    end
    local Progress = Time / (Duration / 2)
    if Progress < 1 then
        local Value = math.pow(2, 10 * (Progress - 1))
        local Result = Change / 2 * Value + Begin
        return Result
    end
    Progress = Progress - 1
    local Value = -math.pow(2, -10 * Progress) + 2
    local Result = Change / 2 * 1.0005 * Value + Begin
    return Result
end

local Animator = {}

function Animator.ConstructTween(Object, Properties, Duration, EasingStyle, EasingDirection, Callback)
    local SelectedStyle = EasingStyle or "Quad"
    local SelectedDirection = EasingDirection or "Out"
    local FunctionName = SelectedDirection .. SelectedStyle
    
    if SelectedStyle == "Linear" then
        FunctionName = "Linear"
    end
    
    local AssignedFunction = EasingLib[FunctionName]
    if not AssignedFunction then
        AssignedFunction = EasingLib.OutQuad
    end
    
    local StartStates = {}
    local EndStates = {}
    
    for PropertyName, PropertyValue in pairs(Properties) do
        local CurrentValue = Object[PropertyName]
        StartStates[PropertyName] = CurrentValue
        EndStates[PropertyName] = PropertyValue
    end
    
    local TweenConstructor = {
        Object = Object,
        Start = StartStates,
        Target = EndStates,
        Duration = Duration,
        TimeElapsed = 0,
        Easing = AssignedFunction,
        OnComplete = Callback,
        IsCompleted = false
    }
    
    table.insert(EngineState.TweenQueue, TweenConstructor)
    return TweenConstructor
end

function Animator.CancelTween(TargetObject)
    local QueueSize = #EngineState.TweenQueue
    for Index = QueueSize, 1, -1 do
        local CurrentTween = EngineState.TweenQueue[Index]
        local TweenTarget = CurrentTween.Object
        if TweenTarget == TargetObject then
            table.remove(EngineState.TweenQueue, Index)
        end
    end
end

local VirtualDOM = {}
VirtualDOM.__index = VirtualDOM

function VirtualDOM.CreateInstance(InstanceType)
    local DOMObject = {}
    setmetatable(DOMObject, VirtualDOM)
    
    local NativeDrawing = Drawing.new(InstanceType)
    
    DOMObject.Type = InstanceType
    DOMObject.RenderObject = NativeDrawing
    DOMObject.Children = {}
    DOMObject.Parent = nil
    
    DOMObject.Position = Vector2.new(0, 0)
    DOMObject.Size = Vector2.new(0, 0)
    DOMObject.AbsolutePosition = Vector2.new(0, 0)
    DOMObject.AbsoluteSize = Vector2.new(0, 0)
    
    DOMObject.Visible = true
    DOMObject.ZIndex = 1
    DOMObject.Transparency = 1
    DOMObject.Color = Color3.new(1, 1, 1)
    
    DOMObject.ClipsDescendants = false
    DOMObject.ClipBounds = nil
    
    DOMObject.FloatingLayer = false
    
    if InstanceType == "Square" then
        DOMObject.Filled = true
        DOMObject.Thickness = 1
    end
    
    if InstanceType == "Text" then
        DOMObject.Text = ""
        DOMObject.TextSize = 13
        DOMObject.Center = false
        DOMObject.Outline = true
        DOMObject.OutlineColor = Color3.new(0, 0, 0)
        DOMObject.Font = 2
    end
    
    if InstanceType == "Line" then
        DOMObject.Thickness = 1
        DOMObject.From = Vector2.new(0, 0)
        DOMObject.To = Vector2.new(0, 0)
    end
    
    if InstanceType == "Circle" then
        DOMObject.Radius = 0
        DOMObject.Filled = false
        DOMObject.NumSides = 64
        DOMObject.Thickness = 1
    end
    
    if InstanceType == "Image" then
        DOMObject.Data = nil
        DOMObject.Rounding = 0
    end
    
    DOMObject.InputBegan = nil
    DOMObject.InputEnded = nil
    DOMObject.RightInputBegan = nil
    DOMObject.MouseEnter = nil
    DOMObject.MouseLeave = nil
    DOMObject.MouseScroll = nil
    
    table.insert(EngineState.RenderQueue, DOMObject)
    
    return DOMObject
end

function VirtualDOM:AddChild(ChildNode)
    ChildNode.Parent = self
    table.insert(self.Children, ChildNode)
end

function VirtualDOM:Destroy()
    local ChildList = self.Children
    for Index, ChildNode in ipairs(ChildList) do
        ChildNode:Destroy()
    end
    
    local ParentNode = self.Parent
    if ParentNode ~= nil then
        local SiblingList = ParentNode.Children
        for Index, SiblingNode in ipairs(SiblingList) do
            if SiblingNode == self then
                table.remove(ParentNode.Children, Index)
                break
            end
        end
    end
    
    local RenderList = EngineState.RenderQueue
    for Index, RenderNode in ipairs(RenderList) do
        if RenderNode == self then
            table.remove(EngineState.RenderQueue, Index)
            break
        end
    end
    
    Animator.CancelTween(self)
    
    local NativeDrawing = self.RenderObject
    if NativeDrawing ~= nil then
        NativeDrawing:Remove()
        self.RenderObject = nil
    end
    
    setmetatable(self, nil)
end

function VirtualDOM:UpdateTransformations()
    local ParentNode = self.Parent
    if ParentNode ~= nil then
        local ParentAbsolute = ParentNode.AbsolutePosition
        local LocalPosition = self.Position
        self.AbsolutePosition = ParentAbsolute + LocalPosition
    else
        local LocalPosition = self.Position
        self.AbsolutePosition = LocalPosition
    end
    
    local LocalSize = self.Size
    self.AbsoluteSize = LocalSize
    
    if ParentNode ~= nil then
        local ParentClips = ParentNode.ClipsDescendants
        if ParentClips == true then
            local ParentBounds = ParentNode.ClipBounds
            if ParentBounds ~= nil then
                self.ClipBounds = ParentBounds
            else
                local MinBound = ParentNode.AbsolutePosition
                local MaxBound = ParentNode.AbsolutePosition + ParentNode.AbsoluteSize
                self.ClipBounds = {
                    Min = MinBound,
                    Max = MaxBound
                }
            end
        else
            local ParentBounds = ParentNode.ClipBounds
            if ParentBounds ~= nil then
                self.ClipBounds = ParentBounds
            else
                self.ClipBounds = nil
            end
        end
    else
        self.ClipBounds = nil
    end
end

function VirtualDOM:RenderToScreen()
    local NativeDrawing = self.RenderObject
    if NativeDrawing == nil then
        return
    end
    
    local IsVisible = self.Visible
    if IsVisible == false then
        NativeDrawing.Visible = false
        return
    end
    
    local CurrentNode = self.Parent
    local IsHierarchyVisible = true
    
    while CurrentNode ~= nil do
        local NodeVisible = CurrentNode.Visible
        if NodeVisible == false then
            IsHierarchyVisible = false
            break
        end
        CurrentNode = CurrentNode.Parent
    end
    
    if IsHierarchyVisible == false then
        NativeDrawing.Visible = false
        return
    end
    
    self:UpdateTransformations()
    
    local RenderPosition = self.AbsolutePosition
    local RenderSize = self.AbsoluteSize
    local IsClippedOut = false
    local Bounds = self.ClipBounds
    
    if Bounds ~= nil then
        local InstanceType = self.Type
        if InstanceType == "Square" then
            local MinX = Bounds.Min.X
            local MinY = Bounds.Min.Y
            local MaxX = Bounds.Max.X
            local MaxY = Bounds.Max.Y
            
            local RenderMinX = RenderPosition.X
            local RenderMinY = RenderPosition.Y
            local RenderMaxX = RenderPosition.X + RenderSize.X
            local RenderMaxY = RenderPosition.Y + RenderSize.Y
            
            local ClampedMinX = math.max(RenderMinX, MinX)
            local ClampedMinY = math.max(RenderMinY, MinY)
            local ClampedMaxX = math.min(RenderMaxX, MaxX)
            local ClampedMaxY = math.min(RenderMaxY, MaxY)
            
            if ClampedMinX >= ClampedMaxX then
                IsClippedOut = true
            end
            
            if ClampedMinY >= ClampedMaxY then
                IsClippedOut = true
            end
            
            if IsClippedOut == false then
                RenderPosition = Vector2.new(ClampedMinX, ClampedMinY)
                RenderSize = Vector2.new(ClampedMaxX - ClampedMinX, ClampedMaxY - ClampedMinY)
            end
            
        elseif InstanceType == "Text" then
            local MinX = Bounds.Min.X
            local MinY = Bounds.Min.Y
            local MaxX = Bounds.Max.X
            local MaxY = Bounds.Max.Y
            
            local RenderX = RenderPosition.X
            local RenderY = RenderPosition.Y
            
            if RenderX < MinX then
                IsClippedOut = true
            end
            if RenderX > MaxX then
                IsClippedOut = true
            end
            if RenderY < MinY then
                IsClippedOut = true
            end
            if RenderY > MaxY then
                IsClippedOut = true
            end
            
        elseif InstanceType == "Line" then
            IsClippedOut = false 
        end
    end
    
    if IsClippedOut == true then
        NativeDrawing.Visible = false
        return
    end
    
    NativeDrawing.Visible = true
    NativeDrawing.ZIndex = self.ZIndex
    NativeDrawing.Transparency = self.Transparency
    NativeDrawing.Color = self.Color
    
    local InstanceType = self.Type
    if InstanceType == "Square" then
        NativeDrawing.Position = RenderPosition
        NativeDrawing.Size = RenderSize
        NativeDrawing.Filled = self.Filled
        NativeDrawing.Thickness = self.Thickness
    elseif InstanceType == "Text" then
        NativeDrawing.Position = RenderPosition
        NativeDrawing.Text = self.Text
        NativeDrawing.Size = self.TextSize
        NativeDrawing.Center = self.Center
        NativeDrawing.Outline = self.Outline
        NativeDrawing.OutlineColor = self.OutlineColor
        NativeDrawing.Font = self.Font
    elseif InstanceType == "Line" then
        NativeDrawing.From = RenderPosition
        NativeDrawing.To = RenderPosition + RenderSize
        NativeDrawing.Thickness = self.Thickness
    elseif InstanceType == "Circle" then
        NativeDrawing.Position = RenderPosition
        NativeDrawing.Radius = self.Radius
        NativeDrawing.Filled = self.Filled
        NativeDrawing.NumSides = self.NumSides
        NativeDrawing.Thickness = self.Thickness
    elseif InstanceType == "Image" then
        NativeDrawing.Position = RenderPosition
        NativeDrawing.Size = RenderSize
        if self.Data ~= nil then
            NativeDrawing.Data = self.Data
        end
    end
end

local VisualEffects = {}

function VisualEffects.GenerateDropShadow(ParentNode, Size, PositionOffset, Spread, Opacity, Quality)
    local ShadowGroup = {}
    local QualitySteps = Quality
    local TotalSpread = Spread
    local StepSize = TotalSpread / QualitySteps
    local BaseOpacity = Opacity
    
    for Index = 1, QualitySteps do
        local Expansion = Index * StepSize
        local OpacityReduction = Index * (BaseOpacity / QualitySteps)
        local CurrentOpacity = BaseOpacity - OpacityReduction
        
        local ShadowLayer = VirtualDOM.CreateInstance("Square")
        local BaseSize = Size
        local AddedSize = Vector2.new(Expansion * 2, Expansion * 2)
        local FinalSize = BaseSize + AddedSize
        
        local BasePosition = PositionOffset
        local SubtractedPosition = Vector2.new(Expansion, Expansion)
        local FinalPosition = BasePosition - SubtractedPosition
        
        local ActiveTheme = ThemeManager.CurrentTheme
        local ThemeColors = ThemeManager.Presets[ActiveTheme]
        local ShadowColor = ThemeColors.ShadowColor
        
        local ParentZIndex = ParentNode.ZIndex
        local TargetZIndex = ParentZIndex - Index
        
        ShadowLayer.Size = FinalSize
        ShadowLayer.Position = FinalPosition
        ShadowLayer.Color = ShadowColor
        ShadowLayer.Filled = false
        ShadowLayer.Thickness = 1
        ShadowLayer.Transparency = CurrentOpacity
        ShadowLayer.ZIndex = TargetZIndex
        
        ParentNode:AddChild(ShadowLayer)
        table.insert(ShadowGroup, ShadowLayer)
    end
    
    return ShadowGroup
end

function VisualEffects.GenerateGradient(ParentNode, Size, StartColor, EndColor, Resolution, IsVertical)
    local GradientGroup = {}
    local TotalSteps = Resolution
    
    if IsVertical == true then
        local TotalHeight = Size.Y
        local StepHeight = TotalHeight / TotalSteps
        
        for Index = 0, TotalSteps - 1 do
            local Alpha = Index / (TotalSteps - 1)
            local CurrentColor = MathLib.LerpColor3(StartColor, EndColor, Alpha)
            
            local GradientLine = VirtualDOM.CreateInstance("Square")
            local LineWidth = Size.X
            local LineHeight = StepHeight + 1
            local LineSize = Vector2.new(LineWidth, LineHeight)
            
            local LineX = 0
            local LineY = Index * StepHeight
            local LinePosition = Vector2.new(LineX, LineY)
            
            local ParentZIndex = ParentNode.ZIndex
            local TargetZIndex = ParentZIndex + 1
            
            GradientLine.Size = LineSize
            GradientLine.Position = LinePosition
            GradientLine.Color = CurrentColor
            GradientLine.Filled = true
            GradientLine.ZIndex = TargetZIndex
            GradientLine.Transparency = 1
            
            ParentNode:AddChild(GradientLine)
            table.insert(GradientGroup, GradientLine)
        end
    else
        local TotalWidth = Size.X
        local StepWidth = TotalWidth / TotalSteps
        
        for Index = 0, TotalSteps - 1 do
            local Alpha = Index / (TotalSteps - 1)
            local CurrentColor = MathLib.LerpColor3(StartColor, EndColor, Alpha)
            
            local GradientLine = VirtualDOM.CreateInstance("Square")
            local LineWidth = StepWidth + 1
            local LineHeight = Size.Y
            local LineSize = Vector2.new(LineWidth, LineHeight)
            
            local LineX = Index * StepWidth
            local LineY = 0
            local LinePosition = Vector2.new(LineX, LineY)
            
            local ParentZIndex = ParentNode.ZIndex
            local TargetZIndex = ParentZIndex + 1
            
            GradientLine.Size = LineSize
            GradientLine.Position = LinePosition
            GradientLine.Color = CurrentColor
            GradientLine.Filled = true
            GradientLine.ZIndex = TargetZIndex
            GradientLine.Transparency = 1
            
            ParentNode:AddChild(GradientLine)
            table.insert(GradientGroup, GradientLine)
        end
    end
    
    return GradientGroup
end

local EngineTick = function(DeltaTime)
    local CurrentElapsed = EngineState.TimeElapsed
    local NewElapsed = CurrentElapsed + DeltaTime
    EngineState.TimeElapsed = NewElapsed
    EngineState.DeltaTime = DeltaTime
    
    local MouseLocation = UserInputService:GetMouseLocation()
    local PrevLocation = EngineState.PreviousMousePosition
    local Difference = MouseLocation - PrevLocation
    EngineState.MouseDelta = Difference
    EngineState.PreviousMousePosition = MouseLocation
    EngineState.MousePosition = MouseLocation
    
    local TweenList = EngineState.TweenQueue
    local TweenCount = #TweenList
    
    for Index = TweenCount, 1, -1 do
        local CurrentTween = TweenList[Index]
        local TweenElapsed = CurrentTween.TimeElapsed
        local TweenDuration = CurrentTween.Duration
        local NewTweenElapsed = TweenElapsed + DeltaTime
        CurrentTween.TimeElapsed = NewTweenElapsed
        
        if NewTweenElapsed >= TweenDuration then
            CurrentTween.TimeElapsed = TweenDuration
            CurrentTween.IsCompleted = true
        end
        
        local CurrentElapsedForMath = CurrentTween.TimeElapsed
        local TargetProperties = CurrentTween.Target
        local StartProperties = CurrentTween.Start
        local EasingFunction = CurrentTween.Easing
        local TargetObject = CurrentTween.Object
        
        for PropertyName, TargetValue in pairs(TargetProperties) do
            local StartValue = StartProperties[PropertyName]
            local InterpolatedValue = nil
            
            local ValueType = typeof(StartValue)
            if ValueType == "number" then
                local ChangeValue = TargetValue - StartValue
                local Result = EasingFunction(CurrentElapsedForMath, StartValue, ChangeValue, TweenDuration)
                InterpolatedValue = Result
            elseif ValueType == "Vector2" then
                local XStart = StartValue.X
                local YStart = StartValue.Y
                local XTarget = TargetValue.X
                local YTarget = TargetValue.Y
                local XChange = XTarget - XStart
                local YChange = YTarget - YStart
                local XResult = EasingFunction(CurrentElapsedForMath, XStart, XChange, TweenDuration)
                local YResult = EasingFunction(CurrentElapsedForMath, YStart, YChange, TweenDuration)
                InterpolatedValue = Vector2.new(XResult, YResult)
            elseif ValueType == "Color3" then
                local RStart = StartValue.R
                local GStart = StartValue.G
                local BStart = StartValue.B
                local RTarget = TargetValue.R
                local GTarget = TargetValue.G
                local BTarget = TargetValue.B
                local RChange = RTarget - RStart
                local GChange = GTarget - GStart
                local BChange = BTarget - BStart
                local RResult = EasingFunction(CurrentElapsedForMath, RStart, RChange, TweenDuration)
                local GResult = EasingFunction(CurrentElapsedForMath, GStart, GChange, TweenDuration)
                local BResult = EasingFunction(CurrentElapsedForMath, BStart, BChange, TweenDuration)
                InterpolatedValue = Color3.new(RResult, GResult, BResult)
            end
            
            TargetObject[PropertyName] = InterpolatedValue
        end
        
        local IsDone = CurrentTween.IsCompleted
        if IsDone == true then
            local CompleteCallback = CurrentTween.OnComplete
            if CompleteCallback ~= nil then
                task.spawn(CompleteCallback)
            end
            table.remove(EngineState.TweenQueue, Index)
        end
    end
    
    local RenderList = EngineState.RenderQueue
    table.sort(RenderList, function(ElementA, ElementB)
        local ZA = ElementA.ZIndex
        local ZB = ElementB.ZIndex
        return ZA < ZB
    end)
    
    local TopElement = nil
    local EngineMouseX = EngineState.MousePosition.X
    local EngineMouseY = EngineState.MousePosition.Y
    local EngineMouseVector = Vector2.new(EngineMouseX, EngineMouseY)
    
    for Index, RenderElement in ipairs(RenderList) do
        RenderElement:RenderToScreen()
        
        local IsElementVisible = RenderElement.Visible
        local NativeObject = RenderElement.RenderObject
        
        if IsElementVisible == true then
            if NativeObject ~= nil then
                local NativeVisible = NativeObject.Visible
                if NativeVisible == true then
                    local HasEnterEvent = RenderElement.MouseEnter
                    local HasLeaveEvent = RenderElement.MouseLeave
                    local HasInputEvent = RenderElement.InputBegan
                    local HasEndEvent = RenderElement.InputEnded
                    local HasScrollEvent = RenderElement.MouseScroll
                    
                    if HasEnterEvent ~= nil or HasLeaveEvent ~= nil or HasInputEvent ~= nil or HasEndEvent ~= nil or HasScrollEvent ~= nil then
                        local ElementPos = RenderElement.AbsolutePosition
                        local ElementSize = RenderElement.AbsoluteSize
                        local IsInside = MathLib.PointInRectangle(EngineMouseVector, ElementPos, ElementSize)
                        if IsInside == true then
                            TopElement = RenderElement
                        end
                    end
                end
            end
        end
    end
    
    local CurrentHovered = EngineState.HoveredElements.Current
    if TopElement ~= CurrentHovered then
        if CurrentHovered ~= nil then
            local LeaveCallback = CurrentHovered.MouseLeave
            if LeaveCallback ~= nil then
                task.spawn(LeaveCallback)
            end
        end
        
        EngineState.HoveredElements.Current = TopElement
        
        if TopElement ~= nil then
            local EnterCallback = TopElement.MouseEnter
            if EnterCallback ~= nil then
                task.spawn(EnterCallback)
            end
        end
    end
end

EngineState.RenderConnection = RunService.RenderStepped:Connect(EngineTick)

local InputBeganTick = function(InputData, ProcessedFlag)
    local InputType = InputData.UserInputType
    local MouseBtn1 = Enum.UserInputType.MouseButton1
    local MouseBtn2 = Enum.UserInputType.MouseButton2
    
    if InputType == MouseBtn1 then
        EngineState.IsMouseDown = true
        local HoveredElement = EngineState.HoveredElements.Current
        if HoveredElement ~= nil then
            local InputCallback = HoveredElement.InputBegan
            if InputCallback ~= nil then
                EngineState.ActiveInputTarget = HoveredElement
                task.spawn(InputCallback, InputData)
            end
        end
    elseif InputType == MouseBtn2 then
        EngineState.IsRightMouseDown = true
        local HoveredElement = EngineState.HoveredElements.Current
        if HoveredElement ~= nil then
            local RightCallback = HoveredElement.RightInputBegan
            if RightCallback ~= nil then
                task.spawn(RightCallback, InputData)
            end
        end
    end
end

EngineState.InputBeganConnection = UserInputService.InputBegan:Connect(InputBeganTick)

local InputEndedTick = function(InputData, ProcessedFlag)
    local InputType = InputData.UserInputType
    local MouseBtn1 = Enum.UserInputType.MouseButton1
    local MouseBtn2 = Enum.UserInputType.MouseButton2
    
    if InputType == MouseBtn1 then
        EngineState.IsMouseDown = false
        local ActiveTarget = EngineState.ActiveInputTarget
        if ActiveTarget ~= nil then
            local EndCallback = ActiveTarget.InputEnded
            if EndCallback ~= nil then
                task.spawn(EndCallback, InputData)
            end
        end
        EngineState.ActiveInputTarget = nil
    elseif InputType == MouseBtn2 then
        EngineState.IsRightMouseDown = false
    end
end

EngineState.InputEndedConnection = UserInputService.InputEnded:Connect(InputEndedTick)

local InputChangedTick = function(InputData, ProcessedFlag)
    local InputType = InputData.UserInputType
    local MouseWheel = Enum.UserInputType.MouseWheel
    
    if InputType == MouseWheel then
        local HoveredElement = EngineState.HoveredElements.Current
        if HoveredElement ~= nil then
            local ScrollCallback = HoveredElement.MouseScroll
            if ScrollCallback ~= nil then
                local ZDelta = InputData.Position.Z
                task.spawn(ScrollCallback, ZDelta)
            end
        end
    end
end

UserInputService.InputChanged:Connect(InputChangedTick)

local CompkillerLib = {
    Windows = {},
    ToggledFlags = {},
    ConfigName = "CK_Configuration_File",
    DragPhysics = {
        TargetObject = nil,
        DragOffset = Vector2.new(0, 0),
        Velocity = Vector2.new(0, 0),
        Friction = 0.82,
        IsDragging = false
    },
    Notifications = {}
}

local PhysicsTick = function()
    local PhysicsData = CompkillerLib.DragPhysics
    local IsDraggingState = PhysicsData.IsDragging
    local TargetObj = PhysicsData.TargetObject
    
    if IsDraggingState == true then
        if TargetObj ~= nil then
            local MousePos = EngineState.MousePosition
            local Offset = PhysicsData.DragOffset
            local TargetPosition = MousePos + Offset
            local CurrentPosition = TargetObj.Position
            local Difference = TargetPosition - CurrentPosition
            local NewVelocity = Difference * 0.4
            PhysicsData.Velocity = NewVelocity
            local AppliedPosition = CurrentPosition + NewVelocity
            TargetObj.Position = AppliedPosition
        end
    else
        if TargetObj ~= nil then
            local CurrentVelocity = PhysicsData.Velocity
            local VelX = CurrentVelocity.X
            local VelY = CurrentVelocity.Y
            local AbsX = math.abs(VelX)
            local AbsY = math.abs(VelY)
            
            if AbsX > 0.1 or AbsY > 0.1 then
                local FrictionValue = PhysicsData.Friction
                local DampenedVelocity = CurrentVelocity * FrictionValue
                PhysicsData.Velocity = DampenedVelocity
                local CurrentPosition = TargetObj.Position
                local AppliedPosition = CurrentPosition + DampenedVelocity
                TargetObj.Position = AppliedPosition
            else
                PhysicsData.TargetObject = nil
            end
        end
    end
end

RunService.RenderStepped:Connect(PhysicsTick)

function CompkillerLib:CreateWindow(ConfigurationTable)
    local Config = ConfigurationTable or {}
    local TitleName = Config.Title or "COMPKILLER V4 INTERNAL"
    local SizeVector = Config.Size or Vector2.new(710, 520)
    
    local ViewportX = CurrentCamera.ViewportSize.X
    local ViewportY = CurrentCamera.ViewportSize.Y
    local HalfViewX = ViewportX / 2
    local HalfViewY = ViewportY / 2
    local HalfSizeX = SizeVector.X / 2
    local HalfSizeY = SizeVector.Y / 2
    local CenterX = HalfViewX - HalfSizeX
    local CenterY = HalfViewY - HalfSizeY
    local DefaultPosition = Vector2.new(CenterX, CenterY)
    local PositionVector = Config.Position or DefaultPosition
    
    local ActiveThemeString = ThemeManager.CurrentTheme
    local ThemeConfig = ThemeManager.Presets[ActiveThemeString]
    
    local WindowAPI = {
        Tabs = {},
        SelectedTab = nil,
        State = {
            IsOpen = true
        }
    }
    
    local MainCanvas = VirtualDOM.CreateInstance("Square")
    MainCanvas.Size = SizeVector
    MainCanvas.Position = PositionVector
    MainCanvas.Color = ThemeConfig.WindowBackground
    MainCanvas.ZIndex = 100
    
    local ShadowSpread = 25
    local ShadowOpacity = 0.4
    local ShadowQuality = 20
    local ShadowOffset = Vector2.new(0, 0)
    VisualEffects.GenerateDropShadow(MainCanvas, SizeVector, ShadowOffset, ShadowSpread, ShadowOpacity, ShadowQuality)
    
    local StrokeOuter = VirtualDOM.CreateInstance("Square")
    StrokeOuter.Size = SizeVector
    StrokeOuter.Color = ThemeConfig.OutlineOuter
    StrokeOuter.Filled = false
    StrokeOuter.ZIndex = 101
    MainCanvas:AddChild(StrokeOuter)
    
    local StrokeInner = VirtualDOM.CreateInstance("Square")
    local InnerSizeOffset = Vector2.new(2, 2)
    local InnerPosOffset = Vector2.new(1, 1)
    StrokeInner.Size = SizeVector - InnerSizeOffset
    StrokeInner.Position = InnerPosOffset
    StrokeInner.Color = ThemeConfig.OutlineInner
    StrokeInner.Filled = false
    StrokeInner.ZIndex = 101
    MainCanvas:AddChild(StrokeInner)
    
    local TopAccent = VirtualDOM.CreateInstance("Square")
    local AccentSizeVector = Vector2.new(SizeVector.X - 2, 2)
    local AccentPosVector = Vector2.new(1, 1)
    TopAccent.Size = AccentSizeVector
    TopAccent.Position = AccentPosVector
    TopAccent.Color = ThemeConfig.AccentPrimary
    TopAccent.ZIndex = 102
    MainCanvas:AddChild(TopAccent)
    
    local SidebarWidth = 180
    local SidebarHeight = SizeVector.Y - 2
    local Sidebar = VirtualDOM.CreateInstance("Square")
    Sidebar.Size = Vector2.new(SidebarWidth, SidebarHeight)
    Sidebar.Position = Vector2.new(1, 1)
    Sidebar.Color = ThemeConfig.SidebarBackground
    Sidebar.ZIndex = 101
    MainCanvas:AddChild(Sidebar)
    
    local SidebarSeparator = VirtualDOM.CreateInstance("Square")
    local SeparatorWidth = 1
    local SeparatorHeight = Sidebar.Size.Y
    SidebarSeparator.Size = Vector2.new(SeparatorWidth, SeparatorHeight)
    SidebarSeparator.Position = Vector2.new(SidebarWidth - 1, 0)
    SidebarSeparator.Color = ThemeConfig.SectionOutline
    SidebarSeparator.ZIndex = 102
    Sidebar:AddChild(SidebarSeparator)
    
    local TitleLabel = VirtualDOM.CreateInstance("Text")
    TitleLabel.Text = TitleName
    TitleLabel.Size = 14
    TitleLabel.Position = Vector2.new(SidebarWidth / 2, 25)
    TitleLabel.Color = ThemeConfig.AccentSecondary
    TitleLabel.Center = true
    TitleLabel.ZIndex = 105
    Sidebar:AddChild(TitleLabel)
    
    local TitleUnderline = VirtualDOM.CreateInstance("Square")
    local UnderlineWidth = 140
    local UnderlineHeight = 1
    TitleUnderline.Size = Vector2.new(UnderlineWidth, UnderlineHeight)
    TitleUnderline.Position = Vector2.new(20, 45)
    TitleUnderline.Color = ThemeConfig.SeparatorLine
    TitleUnderline.ZIndex = 105
    Sidebar:AddChild(TitleUnderline)
    
    local TabContainer = VirtualDOM.CreateInstance("Square")
    local TabContainerWidth = SidebarWidth
    local TabContainerHeight = SizeVector.Y - 60
    TabContainer.Size = Vector2.new(TabContainerWidth, TabContainerHeight)
    TabContainer.Position = Vector2.new(0, 55)
    TabContainer.Transparency = 0
    TabContainer.ZIndex = 102
    Sidebar:AddChild(TabContainer)
    
    local ContentWidth = SizeVector.X - SidebarWidth
    local ContentHeight = SizeVector.Y - 2
    local ContentCanvas = VirtualDOM.CreateInstance("Square")
    ContentCanvas.Size = Vector2.new(ContentWidth, ContentHeight)
    ContentCanvas.Position = Vector2.new(SidebarWidth, 1)
    ContentCanvas.Color = ThemeConfig.WindowBackground
    ContentCanvas.ZIndex = 101
    MainCanvas:AddChild(ContentCanvas)
    
    local SidebarInputBegan = function(InputInfo)
        local PhysicsData = CompkillerLib.DragPhysics
        PhysicsData.TargetObject = MainCanvas
        local CanvasPos = MainCanvas.Position
        local MousePos = EngineState.MousePosition
        local CalculatedOffset = CanvasPos - MousePos
        PhysicsData.DragOffset = CalculatedOffset
        PhysicsData.IsDragging = true
    end
    Sidebar.InputBegan = SidebarInputBegan
    
    local SidebarInputEnded = function(InputInfo)
        local PhysicsData = CompkillerLib.DragPhysics
        PhysicsData.IsDragging = false
    end
    Sidebar.InputEnded = SidebarInputEnded
    
    local KeybindToggleHook = function(InputData, ProcessedState)
        local TypingStatus = EngineState.TypingActive
        if ProcessedState == true then
            if TypingStatus == false then
                return
            end
        end
        local Key = InputData.KeyCode
        local RShift = Enum.KeyCode.RightShift
        local Insert = Enum.KeyCode.Insert
        
        if Key == RShift or Key == Insert then
            if TypingStatus == false then
                local CurrentWindowState = WindowAPI.State.IsOpen
                local InvertedState = not CurrentWindowState
                WindowAPI.State.IsOpen = InvertedState
                MainCanvas.Visible = InvertedState
            end
        end
    end
    UserInputService.InputBegan:Connect(KeybindToggleHook)
    
    function WindowAPI:CreateTab(TabConfigTable)
        local TabConfig = TabConfigTable or {}
        local TabName = TabConfig.Name or "New Tab"
        
        local TabAPI = {
            Sections = {},
            IsActive = false
        }
        
        local TabButtonHeight = 38
        local TabButton = VirtualDOM.CreateInstance("Square")
        TabButton.Size = Vector2.new(SidebarWidth, TabButtonHeight)
        TabButton.Color = ThemeConfig.SidebarBackground
        TabButton.ZIndex = 103
        TabContainer:AddChild(TabButton)
        
        local HighlightWidth = 3
        local TabHighlight = VirtualDOM.CreateInstance("Square")
        TabHighlight.Size = Vector2.new(HighlightWidth, TabButtonHeight)
        TabHighlight.Color = ThemeConfig.AccentPrimary
        TabHighlight.Transparency = 0
        TabHighlight.ZIndex = 104
        TabButton:AddChild(TabHighlight)
        
        local TabText = VirtualDOM.CreateInstance("Text")
        TabText.Text = TabName
        TabText.Size = 13
        TabText.Position = Vector2.new(30, 12)
        TabText.Color = ThemeConfig.TextMuted
        TabText.ZIndex = 104
        TabButton:AddChild(TabText)
        
        local TabPage = VirtualDOM.CreateInstance("Square")
        TabPage.Size = ContentCanvas.Size
        TabPage.Transparency = 0
        TabPage.Visible = false
        TabPage.ZIndex = 102
        ContentCanvas:AddChild(TabPage)
        
        local Padding = 12
        local InnerPadding = 6
        local ColumnWidth = (TabPage.Size.X / 2) - (Padding + InnerPadding)
        local ColumnHeight = TabPage.Size.Y - (Padding * 2)
        
        local LeftColumn = VirtualDOM.CreateInstance("Square")
        LeftColumn.Size = Vector2.new(ColumnWidth, ColumnHeight)
        LeftColumn.Position = Vector2.new(Padding, Padding)
        LeftColumn.Transparency = 0
        LeftColumn.ZIndex = 103
        TabPage:AddChild(LeftColumn)
        
        local RightColumn = VirtualDOM.CreateInstance("Square")
        RightColumn.Size = Vector2.new(ColumnWidth, ColumnHeight)
        local RightColumnX = (TabPage.Size.X / 2) + InnerPadding
        RightColumn.Position = Vector2.new(RightColumnX, Padding)
        RightColumn.Transparency = 0
        RightColumn.ZIndex = 103
        TabPage:AddChild(RightColumn)
        
        local TabEnterHook = function()
            local ActiveState = TabAPI.IsActive
            if ActiveState == false then
                local TweenColor = ThemeConfig.TextSecondary
                local TweenProps = {Color = TweenColor}
                Animator.ConstructTween(TabText, TweenProps, 0.2, "Quad", "Out")
            end
        end
        TabButton.MouseEnter = TabEnterHook
        
        local TabLeaveHook = function()
            local ActiveState = TabAPI.IsActive
            if ActiveState == false then
                local TweenColor = ThemeConfig.TextMuted
                local TweenProps = {Color = TweenColor}
                Animator.ConstructTween(TabText, TweenProps, 0.2, "Quad", "Out")
            end
        end
        TabButton.MouseLeave = TabLeaveHook
        
        local TabInputHook = function()
            local WindowTabs = WindowAPI.Tabs
            for Index, ExistingTab in ipairs(WindowTabs) do
                local PageNode = ExistingTab.TabPage
                PageNode.Visible = false
                ExistingTab.IsActive = false
                
                local HighlightNode = ExistingTab.TabHighlight
                local TransProps = {Transparency = 0}
                Animator.ConstructTween(HighlightNode, TransProps, 0.3, "Quad", "Out")
                
                local TextNode = ExistingTab.TabText
                local ColorProps = {Color = ThemeConfig.TextMuted}
                Animator.ConstructTween(TextNode, ColorProps, 0.3, "Quad", "Out")
            end
            
            TabPage.Visible = true
            TabAPI.IsActive = true
            WindowAPI.SelectedTab = TabAPI
            
            local ActiveTransProps = {Transparency = 1}
            Animator.ConstructTween(TabHighlight, ActiveTransProps, 0.3, "Quint", "Out")
            
            local ActiveColorProps = {Color = ThemeConfig.TextPrimary}
            Animator.ConstructTween(TabText, ActiveColorProps, 0.3, "Quint", "Out")
        end
        TabButton.InputBegan = TabInputHook
        
        table.insert(WindowAPI.Tabs, TabAPI)
        TabAPI.TabPage = TabPage
        TabAPI.TabHighlight = TabHighlight
        TabAPI.TabText = TabText
        
        local CurrentTabYPosition = 0
        local ContainerChildren = TabContainer.Children
        for Index, ChildNode in ipairs(ContainerChildren) do
            local NodeType = ChildNode.Type
            local NodeWidth = ChildNode.Size.X
            if NodeType == "Square" then
                if NodeWidth == SidebarWidth then
                    local NewPosition = Vector2.new(0, CurrentTabYPosition)
                    ChildNode.Position = NewPosition
                    local NodeHeight = ChildNode.Size.Y
                    CurrentTabYPosition = CurrentTabYPosition + NodeHeight
                end
            end
        end
        
        local TabCount = #WindowAPI.Tabs
        if TabCount == 1 then
            TabInputHook()
        end
        
        function TabAPI:CreateSection(SectionConfigTable)
            local SectionConfig = SectionConfigTable or {}
            local SectionName = SectionConfig.Name or "Data Section"
            local SectionSide = SectionConfig.Side or "Left"
            
            local TargetColumn = LeftColumn
            local SideLower = string.lower(SectionSide)
            if SideLower == "right" then
                TargetColumn = RightColumn
            end
            
            local SectionAPI = {
                Elements = {}
            }
            
            local BaseSectionHeight = 40
            local SectionCanvas = VirtualDOM.CreateInstance("Square")
            SectionCanvas.Size = Vector2.new(TargetColumn.Size.X, BaseSectionHeight)
            SectionCanvas.Color = ThemeConfig.SectionBackground
            SectionCanvas.ZIndex = 104
            TargetColumn:AddChild(SectionCanvas)
            
            local SectionOutline = VirtualDOM.CreateInstance("Square")
            SectionOutline.Size = SectionCanvas.Size
            SectionOutline.Color = ThemeConfig.SectionOutline
            SectionOutline.Filled = false
            SectionOutline.ZIndex = 105
            SectionCanvas:AddChild(SectionOutline)
            
            local SectionInline = VirtualDOM.CreateInstance("Square")
            local SectionInlineOffset = Vector2.new(2, 2)
            local SectionInlinePos = Vector2.new(1, 1)
            SectionInline.Size = SectionCanvas.Size - SectionInlineOffset
            SectionInline.Position = SectionInlinePos
            SectionInline.Color = ThemeConfig.OutlineInner
            SectionInline.Filled = false
            SectionInline.ZIndex = 105
            SectionCanvas:AddChild(SectionInline)
            
            local HeaderHeight = 25
            local SectionHeader = VirtualDOM.CreateInstance("Square")
            SectionHeader.Size = Vector2.new(SectionCanvas.Size.X - 2, HeaderHeight)
            SectionHeader.Position = Vector2.new(1, 1)
            SectionHeader.Color = ThemeConfig.ElementBackground
            SectionHeader.ZIndex = 105
            SectionCanvas:AddChild(SectionHeader)
            
            local SectionAccent = VirtualDOM.CreateInstance("Square")
            local AccentHeight = 1
            SectionAccent.Size = Vector2.new(SectionCanvas.Size.X - 2, AccentHeight)
            SectionAccent.Position = Vector2.new(1, 1)
            SectionAccent.Color = ThemeConfig.AccentPrimary
            SectionAccent.ZIndex = 106
            SectionCanvas:AddChild(SectionAccent)
            
            local SectionTitle = VirtualDOM.CreateInstance("Text")
            SectionTitle.Text = SectionName
            SectionTitle.Size = 13
            SectionTitle.Position = Vector2.new(10, 6)
            SectionTitle.Color = ThemeConfig.TextPrimary
            SectionTitle.ZIndex = 106
            SectionHeader:AddChild(SectionTitle)
            
            local ItemContainer = VirtualDOM.CreateInstance("Square")
            local ContainerY = 32
            ItemContainer.Size = Vector2.new(SectionCanvas.Size.X, 0)
            ItemContainer.Position = Vector2.new(0, ContainerY)
            ItemContainer.Transparency = 0
            ItemContainer.ZIndex = 105
            SectionCanvas:AddChild(ItemContainer)
            
            local RefreshLayoutsFunction = function()
                local ContentYPosition = 0
                local ElementPadding = 6
                local ElementsList = ItemContainer.Children
                
                for Index, ElementNode in ipairs(ElementsList) do
                    local ElementVisible = ElementNode.Visible
                    local ElementType = ElementNode.Type
                    local ElementFloating = ElementNode.FloatingLayer
                    
                    if ElementVisible == true then
                        if ElementType == "Square" then
                            if ElementFloating == false then
                                local NewPosition = Vector2.new(0, ContentYPosition)
                                ElementNode.Position = NewPosition
                                local ElementHeight = ElementNode.Size.Y
                                ContentYPosition = ContentYPosition + ElementHeight + ElementPadding
                            end
                        end
                    end
                end
                
                local NewContainerSize = Vector2.new(SectionCanvas.Size.X, ContentYPosition)
                ItemContainer.Size = NewContainerSize
                
                local NewCanvasHeight = ContentYPosition + 40
                local NewCanvasSize = Vector2.new(SectionCanvas.Size.X, NewCanvasHeight)
                SectionCanvas.Size = NewCanvasSize
                SectionOutline.Size = NewCanvasSize
                
                local NewInlineSize = NewCanvasSize - Vector2.new(2, 2)
                SectionInline.Size = NewInlineSize
                
                local ColumnYPosition = 0
                local SectionPadding = 12
                local SectionsList = TargetColumn.Children
                
                for Index, SectionNode in ipairs(SectionsList) do
                    local SectionVisible = SectionNode.Visible
                    if SectionVisible == true then
                        local NewPosition = Vector2.new(0, ColumnYPosition)
                        SectionNode.Position = NewPosition
                        local SectionHeight = SectionNode.Size.Y
                        ColumnYPosition = ColumnYPosition + SectionHeight + SectionPadding
                    end
                end
            end
            
            function SectionAPI:AddToggle(ToggleConfigTable)
                local ToggleConfig = ToggleConfigTable or {}
                local ToggleName = ToggleConfig.Name or "Toggle"
                local ToggleDefault = ToggleConfig.Default or false
                local RandomId = tostring(math.random(100000, 999999))
                local ToggleFlag = ToggleConfig.Flag or RandomId
                
                local ToggleAPI = {
                    Value = ToggleDefault
                }
                
                local ElementHeight = 18
                local ElementCanvas = VirtualDOM.CreateInstance("Square")
                ElementCanvas.Size = Vector2.new(ItemContainer.Size.X, ElementHeight)
                ElementCanvas.Transparency = 0
                ItemContainer:AddChild(ElementCanvas)
                
                local CheckboxSize = 12
                local CheckboxBg = VirtualDOM.CreateInstance("Square")
                CheckboxBg.Size = Vector2.new(CheckboxSize, CheckboxSize)
                CheckboxBg.Position = Vector2.new(12, 3)
                CheckboxBg.Color = ThemeConfig.ElementBackground
                CheckboxBg.ZIndex = 106
                ElementCanvas:AddChild(CheckboxBg)
                
                local CheckboxOut = VirtualDOM.CreateInstance("Square")
                CheckboxOut.Size = Vector2.new(CheckboxSize, CheckboxSize)
                CheckboxOut.Position = Vector2.new(12, 3)
                local OutlineColor = ThemeConfig.SectionOutline
                if ToggleAPI.Value == true then
                    OutlineColor = ThemeConfig.AccentPrimary
                end
                CheckboxOut.Color = OutlineColor
                CheckboxOut.Filled = false
                CheckboxOut.ZIndex = 107
                ElementCanvas:AddChild(CheckboxOut)
                
                local FillSize = 10
                local CheckboxFill = VirtualDOM.CreateInstance("Square")
                CheckboxFill.Size = Vector2.new(FillSize, FillSize)
                CheckboxFill.Position = Vector2.new(13, 4)
                CheckboxFill.Color = ThemeConfig.AccentPrimary
                local FillTransparency = 0
                if ToggleAPI.Value == true then
                    FillTransparency = 1
                end
                CheckboxFill.Transparency = FillTransparency
                CheckboxFill.ZIndex = 107
                ElementCanvas:AddChild(CheckboxFill)
                
                local ToggleLabel = VirtualDOM.CreateInstance("Text")
                ToggleLabel.Text = ToggleName
                ToggleLabel.Size = 13
                ToggleLabel.Position = Vector2.new(32, 2)
                local LabelColor = ThemeConfig.TextMuted
                if ToggleAPI.Value == true then
                    LabelColor = ThemeConfig.TextPrimary
                end
                ToggleLabel.Color = LabelColor
                ToggleLabel.ZIndex = 106
                ElementCanvas:AddChild(ToggleLabel)
                
                local InputBeganHook = function()
                    local CurrentValue = ToggleAPI.Value
                    local NewValue = not CurrentValue
                    ToggleAPI.Value = NewValue
                    
                    local TargetTrans = 0
                    if NewValue == true then
                        TargetTrans = 1
                    end
                    local FillProps = {Transparency = TargetTrans}
                    Animator.ConstructTween(CheckboxFill, FillProps, 0.2, "Quint", "Out")
                    
                    local TargetOutCol = ThemeConfig.SectionOutline
                    if NewValue == true then
                        TargetOutCol = ThemeConfig.AccentPrimary
                    end
                    local OutProps = {Color = TargetOutCol}
                    Animator.ConstructTween(CheckboxOut, OutProps, 0.2, "Quint", "Out")
                    
                    local TargetLabelCol = ThemeConfig.TextMuted
                    if NewValue == true then
                        TargetLabelCol = ThemeConfig.TextPrimary
                    end
                    local LabelProps = {Color = TargetLabelCol}
                    Animator.ConstructTween(ToggleLabel, LabelProps, 0.2, "Quint", "Out")
                    
                    local CallbackFunc = ToggleConfig.Callback
                    if CallbackFunc ~= nil then
                        task.spawn(CallbackFunc, NewValue)
                    end
                end
                ElementCanvas.InputBegan = InputBeganHook
                
                CompkillerLib.ToggledFlags[ToggleFlag] = ToggleAPI
                RefreshLayoutsFunction()
                
                return ToggleAPI
            end
            
            return SectionAPI
        end
        return TabAPI
    end
    return WindowAPI
end

return CompkillerLib
