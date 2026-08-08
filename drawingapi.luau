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
            
            -- ==============================================================================
            -- SUB-COMPONENT: TOGGLE
            -- ==============================================================================
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
                if ToggleAPI.Value == true then OutlineColor = ThemeConfig.AccentPrimary end
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
                if ToggleAPI.Value == true then FillTransparency = 1 end
                CheckboxFill.Transparency = FillTransparency
                CheckboxFill.ZIndex = 107
                ElementCanvas:AddChild(CheckboxFill)
                
                local ToggleLabel = VirtualDOM.CreateInstance("Text")
                ToggleLabel.Text = ToggleName
                ToggleLabel.Size = 13
                ToggleLabel.Position = Vector2.new(32, 2)
                local LabelColor = ThemeConfig.TextMuted
                if ToggleAPI.Value == true then LabelColor = ThemeConfig.TextPrimary end
                ToggleLabel.Color = LabelColor
                ToggleLabel.ZIndex = 106
                ElementCanvas:AddChild(ToggleLabel)
                
                local InputBeganHook = function()
                    local CurrentValue = ToggleAPI.Value
                    local NewValue = not CurrentValue
                    ToggleAPI.Value = NewValue
                    
                    local TargetTrans = 0
                    if NewValue == true then TargetTrans = 1 end
                    local FillProps = {Transparency = TargetTrans}
                    Animator.ConstructTween(CheckboxFill, FillProps, 0.2, "Quint", "Out")
                    
                    local TargetOutCol = ThemeConfig.SectionOutline
                    if NewValue == true then TargetOutCol = ThemeConfig.AccentPrimary end
                    local OutProps = {Color = TargetOutCol}
                    Animator.ConstructTween(CheckboxOut, OutProps, 0.2, "Quint", "Out")
                    
                    local TargetLabelCol = ThemeConfig.TextMuted
                    if NewValue == true then TargetLabelCol = ThemeConfig.TextPrimary end
                    local LabelProps = {Color = TargetLabelCol}
                    Animator.ConstructTween(ToggleLabel, LabelProps, 0.2, "Quint", "Out")
                    
                    local CallbackFunc = ToggleConfig.Callback
                    if CallbackFunc ~= nil then task.spawn(CallbackFunc, NewValue) end
                end
                ElementCanvas.InputBegan = InputBeganHook
                
                CompkillerLib.ToggledFlags[ToggleFlag] = ToggleAPI
                RefreshLayoutsFunction()
                return ToggleAPI
            end
            
            -- ==============================================================================
            -- SUB-COMPONENT: SLIDER
            -- ==============================================================================
            function SectionAPI:AddSlider(SliderConfigTable)
                local SliderConfig = SliderConfigTable or {}
                local SliderName = SliderConfig.Name or "Value Slider"
                local SliderMin = SliderConfig.Min or 0
                local SliderMax = SliderConfig.Max or 100
                local DefaultRaw = SliderConfig.Default or SliderMin
                local SliderDefault = MathLib.Clamp(DefaultRaw, SliderMin, SliderMax)
                local SliderDecimals = SliderConfig.Decimals or 0
                local RandomId = tostring(math.random(100000, 999999))
                local SliderFlag = SliderConfig.Flag or RandomId
                
                local SliderAPI = { Value = SliderDefault }
                
                local ElementHeight = 36
                local ElementCanvas = VirtualDOM.CreateInstance("Square")
                ElementCanvas.Size = Vector2.new(ItemContainer.Size.X, ElementHeight)
                ElementCanvas.Transparency = 0
                ItemContainer:AddChild(ElementCanvas)
                
                local SliderLabel = VirtualDOM.CreateInstance("Text")
                SliderLabel.Text = SliderName
                SliderLabel.Size = 13
                SliderLabel.Position = Vector2.new(12, 2)
                SliderLabel.Color = ThemeConfig.TextMuted
                SliderLabel.ZIndex = 106
                ElementCanvas:AddChild(SliderLabel)
                
                local ValueDisplay = VirtualDOM.CreateInstance("Text")
                ValueDisplay.Text = tostring(SliderAPI.Value)
                ValueDisplay.Size = 13
                ValueDisplay.Position = Vector2.new(ElementCanvas.Size.X - 22, 2)
                ValueDisplay.Color = ThemeConfig.TextPrimary
                ValueDisplay.Center = true
                ValueDisplay.ZIndex = 107
                ElementCanvas:AddChild(ValueDisplay)
                
                local RailBackground = VirtualDOM.CreateInstance("Square")
                local RailWidth = ElementCanvas.Size.X - 24
                local RailHeight = 10
                RailBackground.Size = Vector2.new(RailWidth, RailHeight)
                RailBackground.Position = Vector2.new(12, 20)
                RailBackground.Color = ThemeConfig.ElementBackground
                RailBackground.ZIndex = 106
                ElementCanvas:AddChild(RailBackground)
                
                local RailOutline = VirtualDOM.CreateInstance("Square")
                RailOutline.Size = RailBackground.Size
                RailOutline.Position = RailBackground.Position
                RailOutline.Color = ThemeConfig.SectionOutline
                RailOutline.Filled = false
                RailOutline.ZIndex = 107
                ElementCanvas:AddChild(RailOutline)
                
                local Difference = SliderMax - SliderMin
                local CurrentOffset = SliderAPI.Value - SliderMin
                local ProgressPercentage = CurrentOffset / Difference
                local FillWidth = RailBackground.Size.X * ProgressPercentage
                
                local RailFill = VirtualDOM.CreateInstance("Square")
                RailFill.Size = Vector2.new(FillWidth, RailHeight)
                RailFill.Position = RailBackground.Position
                RailFill.Color = ThemeConfig.AccentPrimary
                RailFill.ZIndex = 107
                ElementCanvas:AddChild(RailFill)
                
                local IsSliding = false
                local ExecuteMathFunction = function()
                    local MaxX = RailBackground.AbsoluteSize.X
                    local MouseX = EngineState.MousePosition.X
                    local RailAbsoluteX = RailBackground.AbsolutePosition.X
                    local RelativeX = MouseX - RailAbsoluteX
                    local ClampedRelativeX = MathLib.Clamp(RelativeX, 0, MaxX)
                    
                    local Percent = ClampedRelativeX / MaxX
                    local ValueDifference = SliderMax - SliderMin
                    local ScaledValue = ValueDifference * Percent
                    local RawValue = SliderMin + ScaledValue
                    
                    local Power = math.pow(10, SliderDecimals)
                    local Shifted = RawValue * Power
                    local Rounded = math.floor(Shifted + 0.5)
                    local CleanValue = Rounded / Power
                    
                    SliderAPI.Value = CleanValue
                    ValueDisplay.Text = tostring(CleanValue)
                    
                    local NewFillWidth = MaxX * Percent
                    local TweenProps = {Size = Vector2.new(NewFillWidth, RailHeight)}
                    Animator.ConstructTween(RailFill, TweenProps, 0.05, "Linear", "Out")
                    
                    local CallbackFunc = SliderConfig.Callback
                    if CallbackFunc ~= nil then task.spawn(CallbackFunc, SliderAPI.Value) end
                end
                
                RailBackground.InputBegan = function(InputData)
                    IsSliding = true
                    local LabelProps = {Color = ThemeConfig.TextPrimary}
                    Animator.ConstructTween(SliderLabel, LabelProps, 0.2, "Quad", "Out")
                    ExecuteMathFunction()
                end
                
                RunService.RenderStepped:Connect(function()
                    if IsSliding == true then
                        local MouseDown = EngineState.IsMouseDown
                        if MouseDown == false then
                            IsSliding = false
                            local LabelProps = {Color = ThemeConfig.TextMuted}
                            Animator.ConstructTween(SliderLabel, LabelProps, 0.2, "Quad", "Out")
                        else
                            ExecuteMathFunction()
                        end
                    end
                end)
                
                CompkillerLib.ToggledFlags[SliderFlag] = SliderAPI
                RefreshLayoutsFunction()
                return SliderAPI
            end

            -- ==============================================================================
            -- SUB-COMPONENT: DROPDOWN
            -- ==============================================================================
            function SectionAPI:AddDropdown(DropdownConfigTable)
                local DropConfig = DropdownConfigTable or {}
                local DropName = DropConfig.Name or "Dropdown Selection"
                local DropValues = DropConfig.Values or {"Option 1", "Option 2", "Option 3"}
                local DropDefault = DropConfig.Default or DropValues[1]
                local RandomId = tostring(math.random(100000, 999999))
                local DropFlag = DropConfig.Flag or RandomId
                local MaxVisibleItems = DropConfig.MaxItems or 5
                
                local DropAPI = { Value = DropDefault, IsOpen = false, ScrollIndex = 0 }
                
                local ElementHeight = 42
                local ElementCanvas = VirtualDOM.CreateInstance("Square")
                ElementCanvas.Size = Vector2.new(ItemContainer.Size.X, ElementHeight)
                ElementCanvas.Transparency = 0
                ItemContainer:AddChild(ElementCanvas)
                
                local DropLabel = VirtualDOM.CreateInstance("Text")
                DropLabel.Text = DropName
                DropLabel.Size = 13
                DropLabel.Position = Vector2.new(12, 2)
                DropLabel.Color = ThemeConfig.TextMuted
                DropLabel.ZIndex = 106
                ElementCanvas:AddChild(DropLabel)
                
                local BoxWidth = ElementCanvas.Size.X - 24
                local BoxHeight = 20
                local DropBox = VirtualDOM.CreateInstance("Square")
                DropBox.Size = Vector2.new(BoxWidth, BoxHeight)
                DropBox.Position = Vector2.new(12, 18)
                DropBox.Color = ThemeConfig.ElementBackground
                DropBox.ZIndex = 106
                ElementCanvas:AddChild(DropBox)
                
                local DropBoxOut = VirtualDOM.CreateInstance("Square")
                DropBoxOut.Size = DropBox.Size
                DropBoxOut.Position = DropBox.Position
                DropBoxOut.Color = ThemeConfig.SectionOutline
                DropBoxOut.Filled = false
                DropBoxOut.ZIndex = 107
                ElementCanvas:AddChild(DropBoxOut)
                
                local DropValueText = VirtualDOM.CreateInstance("Text")
                DropValueText.Text = DropAPI.Value
                DropValueText.Size = 13
                DropValueText.Position = Vector2.new(18, 21)
                DropValueText.Color = ThemeConfig.TextPrimary
                DropValueText.ZIndex = 107
                ElementCanvas:AddChild(DropValueText)
                
                local Indicator = VirtualDOM.CreateInstance("Text")
                Indicator.Text = "+"
                Indicator.Size = 13
                Indicator.Position = Vector2.new(ElementCanvas.Size.X - 22, 21)
                Indicator.Color = ThemeConfig.TextMuted
                Indicator.ZIndex = 107
                ElementCanvas:AddChild(Indicator)
                
                local DropContainer = VirtualDOM.CreateInstance("Square")
                DropContainer.Size = Vector2.new(DropBox.Size.X, 0)
                DropContainer.Position = Vector2.new(12, 40)
                DropContainer.Color = ThemeConfig.SectionBackground
                DropContainer.ZIndex = 250
                DropContainer.Visible = false
                DropContainer.FloatingLayer = true
                DropContainer.ClipsDescendants = true
                ElementCanvas:AddChild(DropContainer)
                
                local DropContainerOut = VirtualDOM.CreateInstance("Square")
                DropContainerOut.Size = DropContainer.Size
                DropContainerOut.Color = ThemeConfig.AccentPrimary
                DropContainerOut.Filled = false
                DropContainerOut.ZIndex = 251
                DropContainer:AddChild(DropContainerOut)
                
                local ItemHeight = 20
                local TotalItems = #DropValues
                local VisibleItems = math.min(TotalItems, MaxVisibleItems)
                local ContainerMaxHeight = VisibleItems * ItemHeight
                
                local ScrollContainer = VirtualDOM.CreateInstance("Square")
                ScrollContainer.Size = Vector2.new(DropContainer.Size.X, TotalItems * ItemHeight)
                ScrollContainer.Position = Vector2.new(0, 0)
                ScrollContainer.Transparency = 0
                ScrollContainer.ZIndex = 250
                DropContainer:AddChild(ScrollContainer)
                
                local ScrollbarBg = VirtualDOM.CreateInstance("Square")
                ScrollbarBg.Size = Vector2.new(4, ContainerMaxHeight)
                ScrollbarBg.Position = Vector2.new(DropContainer.Size.X - 4, 0)
                ScrollbarBg.Color = ThemeConfig.ElementBackground
                ScrollbarBg.ZIndex = 252
                DropContainer:AddChild(ScrollbarBg)
                
                local ScrollThumb = VirtualDOM.CreateInstance("Square")
                local ThumbHeightRatio = VisibleItems / TotalItems
                local ThumbHeight = ContainerMaxHeight * ThumbHeightRatio
                ScrollThumb.Size = Vector2.new(4, ThumbHeight)
                ScrollThumb.Position = Vector2.new(DropContainer.Size.X - 4, 0)
                ScrollThumb.Color = ThemeConfig.AccentPrimary
                ScrollThumb.ZIndex = 253
                DropContainer:AddChild(ScrollThumb)
                
                if TotalItems <= MaxVisibleItems then
                    ScrollbarBg.Visible = false
                    ScrollThumb.Visible = false
                end
                
                local GeneratedOptions = {}
                local BuildDropdownListFunction = function()
                    local CurrentY = 0
                    for Index, OptionString in ipairs(DropValues) do
                        local OptBox = VirtualDOM.CreateInstance("Square")
                        OptBox.Size = Vector2.new(DropContainer.Size.X - 4, ItemHeight)
                        OptBox.Position = Vector2.new(0, CurrentY)
                        OptBox.Color = ThemeConfig.ElementBackground
                        OptBox.ZIndex = 251
                        ScrollContainer:AddChild(OptBox)
                        
                        local OptText = VirtualDOM.CreateInstance("Text")
                        OptText.Text = OptionString
                        OptText.Size = 13
                        OptText.Position = Vector2.new(8, 3)
                        local TextColor = ThemeConfig.TextMuted
                        if OptionString == DropAPI.Value then TextColor = ThemeConfig.AccentPrimary end
                        OptText.Color = TextColor
                        OptText.ZIndex = 252
                        OptBox:AddChild(OptText)
                        
                        OptBox.MouseEnter = function()
                            local HoverProps = {Color = ThemeConfig.ElementHover}
                            Animator.ConstructTween(OptBox, HoverProps, 0.1, "Quad", "Out")
                        end
                        
                        OptBox.MouseLeave = function()
                            local LeaveProps = {Color = ThemeConfig.ElementBackground}
                            Animator.ConstructTween(OptBox, LeaveProps, 0.1, "Quad", "Out")
                        end
                        
                        OptBox.InputBegan = function(InputData)
                            DropAPI.Value = OptionString
                            DropValueText.Text = OptionString
                            DropAPI.IsOpen = false
                            DropContainer.Visible = false
                            Indicator.Text = "+"
                            local OutProps = {Color = ThemeConfig.SectionOutline}
                            Animator.ConstructTween(DropBoxOut, OutProps, 0.2, "Quint", "Out")
                            
                            local CallbackFunc = DropConfig.Callback
                            if CallbackFunc ~= nil then task.spawn(CallbackFunc, DropAPI.Value) end
                        end
                        
                        table.insert(GeneratedOptions, OptBox)
                        CurrentY = CurrentY + ItemHeight
                    end
                end
                
                local UpdateScrollPhysics = function()
                    local MaxScrollIndex = TotalItems - VisibleItems
                    DropAPI.ScrollIndex = MathLib.Clamp(DropAPI.ScrollIndex, 0, MaxScrollIndex)
                    
                    local TargetY = -(DropAPI.ScrollIndex * ItemHeight)
                    local ScrollProps = {Position = Vector2.new(0, TargetY)}
                    Animator.ConstructTween(ScrollContainer, ScrollProps, 0.15, "Quad", "Out")
                    
                    local ScrollProgress = 0
                    if MaxScrollIndex > 0 then ScrollProgress = DropAPI.ScrollIndex / MaxScrollIndex end
                    local ThumbMaxY = ContainerMaxHeight - ThumbHeight
                    local ThumbTargetY = ThumbMaxY * ScrollProgress
                    local ThumbProps = {Position = Vector2.new(DropContainer.Size.X - 4, ThumbTargetY)}
                    Animator.ConstructTween(ScrollThumb, ThumbProps, 0.15, "Quad", "Out")
                end
                
                DropContainer.MouseScroll = function(ZDelta)
                    if TotalItems <= MaxVisibleItems then return end
                    if ZDelta > 0 then DropAPI.ScrollIndex = DropAPI.ScrollIndex - 1
                    elseif ZDelta < 0 then DropAPI.ScrollIndex = DropAPI.ScrollIndex + 1 end
                    UpdateScrollPhysics()
                end
                
                DropBox.InputBegan = function(InputData)
                    local CurrentState = DropAPI.IsOpen
                    local NewState = not CurrentState
                    DropAPI.IsOpen = NewState
                    
                    if NewState == true then
                        if #GeneratedOptions == 0 then BuildDropdownListFunction() end
                        DropContainer.Size = Vector2.new(DropBox.Size.X, ContainerMaxHeight)
                        DropContainerOut.Size = DropContainer.Size
                        DropContainer.Visible = true
                        Indicator.Text = "-"
                        local OutProps = {Color = ThemeConfig.AccentPrimary}
                        Animator.ConstructTween(DropBoxOut, OutProps, 0.2, "Quint", "Out")
                    else
                        DropContainer.Visible = false
                        Indicator.Text = "+"
                        local OutProps = {Color = ThemeConfig.SectionOutline}
                        Animator.ConstructTween(DropBoxOut, OutProps, 0.2, "Quint", "Out")
                    end
                end
                
                CompkillerLib.ToggledFlags[DropFlag] = DropAPI
                RefreshLayoutsFunction()
                return DropAPI
            end

            -- ==============================================================================
            -- SUB-COMPONENT: MULTI-DROPDOWN
            -- ==============================================================================
            function SectionAPI:AddMultiDropdown(MultiDropConfigTable)
                local DropConfig = MultiDropConfigTable or {}
                local DropName = DropConfig.Name or "Multi Selection"
                local DropValues = DropConfig.Values or {"Option 1", "Option 2"}
                local DropDefault = DropConfig.Default or {}
                local RandomId = tostring(math.random(100000, 999999))
                local DropFlag = DropConfig.Flag or RandomId
                local MaxVisibleItems = DropConfig.MaxItems or 5
                
                local DropAPI = { Value = {}, IsOpen = false, ScrollIndex = 0 }
                for Index, DefaultVal in ipairs(DropDefault) do DropAPI.Value[DefaultVal] = true end
                
                local ElementHeight = 42
                local ElementCanvas = VirtualDOM.CreateInstance("Square")
                ElementCanvas.Size = Vector2.new(ItemContainer.Size.X, ElementHeight)
                ElementCanvas.Transparency = 0
                ItemContainer:AddChild(ElementCanvas)
                
                local DropLabel = VirtualDOM.CreateInstance("Text")
                DropLabel.Text = DropName
                DropLabel.Size = 13
                DropLabel.Position = Vector2.new(12, 2)
                DropLabel.Color = ThemeConfig.TextMuted
                DropLabel.ZIndex = 106
                ElementCanvas:AddChild(DropLabel)
                
                local BoxWidth = ElementCanvas.Size.X - 24
                local BoxHeight = 20
                local DropBox = VirtualDOM.CreateInstance("Square")
                DropBox.Size = Vector2.new(BoxWidth, BoxHeight)
                DropBox.Position = Vector2.new(12, 18)
                DropBox.Color = ThemeConfig.ElementBackground
                DropBox.ZIndex = 106
                ElementCanvas:AddChild(DropBox)
                
                local DropBoxOut = VirtualDOM.CreateInstance("Square")
                DropBoxOut.Size = DropBox.Size
                DropBoxOut.Position = DropBox.Position
                DropBoxOut.Color = ThemeConfig.SectionOutline
                DropBoxOut.Filled = false
                DropBoxOut.ZIndex = 107
                ElementCanvas:AddChild(DropBoxOut)
                
                local function FormatDisplayString()
                    local ActiveItems = {}
                    for ItemName, IsActive in pairs(DropAPI.Value) do
                        if IsActive == true then table.insert(ActiveItems, tostring(ItemName)) end
                    end
                    if #ActiveItems == 0 then return "None"
                    elseif #ActiveItems == 1 then return ActiveItems[1]
                    else return tostring(#ActiveItems) .. " Selected" end
                end
                
                local DropValueText = VirtualDOM.CreateInstance("Text")
                DropValueText.Text = FormatDisplayString()
                DropValueText.Size = 13
                DropValueText.Position = Vector2.new(18, 21)
                local InitialTextColor = ThemeConfig.TextDisabled
                if FormatDisplayString() ~= "None" then InitialTextColor = ThemeConfig.TextPrimary end
                DropValueText.Color = InitialTextColor
                DropValueText.ZIndex = 107
                ElementCanvas:AddChild(DropValueText)
                
                local Indicator = VirtualDOM.CreateInstance("Text")
                Indicator.Text = "+"
                Indicator.Size = 13
                Indicator.Position = Vector2.new(ElementCanvas.Size.X - 22, 21)
                Indicator.Color = ThemeConfig.TextMuted
                Indicator.ZIndex = 107
                ElementCanvas:AddChild(Indicator)
                
                local DropContainer = VirtualDOM.CreateInstance("Square")
                DropContainer.Size = Vector2.new(DropBox.Size.X, 0)
                DropContainer.Position = Vector2.new(12, 40)
                DropContainer.Color = ThemeConfig.SectionBackground
                DropContainer.ZIndex = 250
                DropContainer.Visible = false
                DropContainer.FloatingLayer = true
                DropContainer.ClipsDescendants = true
                ElementCanvas:AddChild(DropContainer)
                
                local DropContainerOut = VirtualDOM.CreateInstance("Square")
                DropContainerOut.Size = DropContainer.Size
                DropContainerOut.Color = ThemeConfig.AccentPrimary
                DropContainerOut.Filled = false
                DropContainerOut.ZIndex = 251
                DropContainer:AddChild(DropContainerOut)
                
                local ItemHeight = 20
                local TotalItems = #DropValues
                local VisibleItems = math.min(TotalItems, MaxVisibleItems)
                local ContainerMaxHeight = VisibleItems * ItemHeight
                
                local ScrollContainer = VirtualDOM.CreateInstance("Square")
                ScrollContainer.Size = Vector2.new(DropContainer.Size.X, TotalItems * ItemHeight)
                ScrollContainer.Position = Vector2.new(0, 0)
                ScrollContainer.Transparency = 0
                ScrollContainer.ZIndex = 250
                DropContainer:AddChild(ScrollContainer)
                
                local ScrollbarBg = VirtualDOM.CreateInstance("Square")
                ScrollbarBg.Size = Vector2.new(4, ContainerMaxHeight)
                ScrollbarBg.Position = Vector2.new(DropContainer.Size.X - 4, 0)
                ScrollbarBg.Color = ThemeConfig.ElementBackground
                ScrollbarBg.ZIndex = 252
                DropContainer:AddChild(ScrollbarBg)
                
                local ScrollThumb = VirtualDOM.CreateInstance("Square")
                local ThumbHeightRatio = VisibleItems / TotalItems
                local ThumbHeight = ContainerMaxHeight * ThumbHeightRatio
                ScrollThumb.Size = Vector2.new(4, ThumbHeight)
                ScrollThumb.Position = Vector2.new(DropContainer.Size.X - 4, 0)
                ScrollThumb.Color = ThemeConfig.AccentPrimary
                ScrollThumb.ZIndex = 253
                DropContainer:AddChild(ScrollThumb)
                
                if TotalItems <= MaxVisibleItems then
                    ScrollbarBg.Visible = false
                    ScrollThumb.Visible = false
                end
                
                local GeneratedOptions = {}
                local BuildMultiListFunction = function()
                    local CurrentY = 0
                    for Index, OptionString in ipairs(DropValues) do
                        local OptBox = VirtualDOM.CreateInstance("Square")
                        OptBox.Size = Vector2.new(DropContainer.Size.X - 4, ItemHeight)
                        OptBox.Position = Vector2.new(0, CurrentY)
                        OptBox.Color = ThemeConfig.ElementBackground
                        OptBox.ZIndex = 251
                        ScrollContainer:AddChild(OptBox)
                        
                        local OptText = VirtualDOM.CreateInstance("Text")
                        OptText.Text = OptionString
                        OptText.Size = 13
                        OptText.Position = Vector2.new(8, 3)
                        local IsSelected = DropAPI.Value[OptionString] or false
                        local TextColor = ThemeConfig.TextMuted
                        if IsSelected == true then TextColor = ThemeConfig.AccentPrimary end
                        OptText.Color = TextColor
                        OptText.ZIndex = 252
                        OptBox:AddChild(OptText)
                        
                        OptBox.MouseEnter = function()
                            local HoverProps = {Color = ThemeConfig.ElementHover}
                            Animator.ConstructTween(OptBox, HoverProps, 0.1, "Quad", "Out")
                        end
                        
                        OptBox.MouseLeave = function()
                            local LeaveProps = {Color = ThemeConfig.ElementBackground}
                            Animator.ConstructTween(OptBox, LeaveProps, 0.1, "Quad", "Out")
                        end
                        
                        OptBox.InputBegan = function(InputData)
                            local CurrentSelectionState = DropAPI.Value[OptionString] or false
                            local NewSelectionState = not CurrentSelectionState
                            
                            if NewSelectionState == true then
                                DropAPI.Value[OptionString] = true
                                local SelectProps = {Color = ThemeConfig.AccentPrimary}
                                Animator.ConstructTween(OptText, SelectProps, 0.2, "Quint", "Out")
                            else
                                DropAPI.Value[OptionString] = nil
                                local DeselectProps = {Color = ThemeConfig.TextMuted}
                                Animator.ConstructTween(OptText, DeselectProps, 0.2, "Quint", "Out")
                            end
                            
                            local NewDisplayStr = FormatDisplayString()
                            DropValueText.Text = NewDisplayStr
                            if NewDisplayStr == "None" then DropValueText.Color = ThemeConfig.TextDisabled
                            else DropValueText.Color = ThemeConfig.TextPrimary end
                            
                            local CallbackFunc = MultiDropConfigTable.Callback
                            if CallbackFunc ~= nil then task.spawn(CallbackFunc, DropAPI.Value) end
                        end
                        
                        table.insert(GeneratedOptions, OptBox)
                        CurrentY = CurrentY + ItemHeight
                    end
                end
                
                local UpdateMultiScrollPhysics = function()
                    local MaxScrollIndex = TotalItems - VisibleItems
                    DropAPI.ScrollIndex = MathLib.Clamp(DropAPI.ScrollIndex, 0, MaxScrollIndex)
                    
                    local TargetY = -(DropAPI.ScrollIndex * ItemHeight)
                    local ScrollProps = {Position = Vector2.new(0, TargetY)}
                    Animator.ConstructTween(ScrollContainer, ScrollProps, 0.15, "Quad", "Out")
                    
                    local ScrollProgress = 0
                    if MaxScrollIndex > 0 then ScrollProgress = DropAPI.ScrollIndex / MaxScrollIndex end
                    local ThumbMaxY = ContainerMaxHeight - ThumbHeight
                    local ThumbTargetY = ThumbMaxY * ScrollProgress
                    local ThumbProps = {Position = Vector2.new(DropContainer.Size.X - 4, ThumbTargetY)}
                    Animator.ConstructTween(ScrollThumb, ThumbProps, 0.15, "Quad", "Out")
                end
                
                DropContainer.MouseScroll = function(ZDelta)
                    if TotalItems <= MaxVisibleItems then return end
                    if ZDelta > 0 then DropAPI.ScrollIndex = DropAPI.ScrollIndex - 1
                    elseif ZDelta < 0 then DropAPI.ScrollIndex = DropAPI.ScrollIndex + 1 end
                    UpdateMultiScrollPhysics()
                end
                
                DropBox.InputBegan = function(InputData)
                    local CurrentState = DropAPI.IsOpen
                    local NewState = not CurrentState
                    DropAPI.IsOpen = NewState
                    
                    if NewState == true then
                        if #GeneratedOptions == 0 then BuildMultiListFunction() end
                        DropContainer.Size = Vector2.new(DropBox.Size.X, ContainerMaxHeight)
                        DropContainerOut.Size = DropContainer.Size
                        DropContainer.Visible = true
                        Indicator.Text = "-"
                        local OutProps = {Color = ThemeConfig.AccentPrimary}
                        Animator.ConstructTween(DropBoxOut, OutProps, 0.2, "Quint", "Out")
                    else
                        DropContainer.Visible = false
                        Indicator.Text = "+"
                        local OutProps = {Color = ThemeConfig.SectionOutline}
                        Animator.ConstructTween(DropBoxOut, OutProps, 0.2, "Quint", "Out")
                    end
                end
                
                CompkillerLib.ToggledFlags[DropFlag] = DropAPI
                RefreshLayoutsFunction()
                return DropAPI
            end
            
            -- ==============================================================================
            -- SUB-COMPONENT: COLOR PICKER
            -- ==============================================================================
            function SectionAPI:AddColorPicker(ColorConfigTable)
                local ColorConfig = ColorConfigTable or {}
                local ColorName = ColorConfig.Name or "Color Picker"
                local DefaultColor = ColorConfig.Default or Color3.fromRGB(255, 255, 255)
                local RandomId = tostring(math.random(100000, 999999))
                local ColorFlag = ColorConfig.Flag or RandomId
                
                local ColorAPI = { Value = DefaultColor, IsOpen = false }
                
                local ElementHeight = 20
                local ElementCanvas = VirtualDOM.CreateInstance("Square")
                ElementCanvas.Size = Vector2.new(ItemContainer.Size.X, ElementHeight)
                ElementCanvas.Transparency = 0
                ItemContainer:AddChild(ElementCanvas)
                
                local ColorLabel = VirtualDOM.CreateInstance("Text")
                ColorLabel.Text = ColorName
                ColorLabel.Size = 13
                ColorLabel.Position = Vector2.new(12, 3)
                ColorLabel.Color = ThemeConfig.TextMuted
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
                DisplayOut.Color = ThemeConfig.SectionOutline
                DisplayOut.Filled = false
                DisplayOut.ZIndex = 107
                ElementCanvas:AddChild(DisplayOut)
                
                local PickerWindow = VirtualDOM.CreateInstance("Square")
                PickerWindow.Size = Vector2.new(160, 160)
                PickerWindow.Position = Vector2.new(ElementCanvas.Size.X - 170, 20)
                PickerWindow.Color = ThemeConfig.SectionBackground
                PickerWindow.ZIndex = 300
                PickerWindow.Visible = false
                PickerWindow.FloatingLayer = true
                ElementCanvas:AddChild(PickerWindow)
                
                local PickerOut = VirtualDOM.CreateInstance("Square")
                PickerOut.Size = PickerWindow.Size
                PickerOut.Color = ThemeConfig.AccentPrimary
                PickerOut.Filled = false
                PickerOut.ZIndex = 301
                PickerWindow:AddChild(PickerOut)
                
                local SatValBox = VirtualDOM.CreateInstance("Square")
                SatValBox.Size = Vector2.new(130, 140)
                SatValBox.Position = Vector2.new(10, 10)
                local CurrentHue, CurrentSat, CurrentVal = MathLib.RGBToHSV(ColorAPI.Value)
                SatValBox.Color = MathLib.HSVToRGB(CurrentHue, 1, 1)
                SatValBox.ZIndex = 302
                PickerWindow:AddChild(SatValBox)
                
                local WhiteOverlay = VirtualDOM.CreateInstance("Square")
                WhiteOverlay.Size = SatValBox.Size
                WhiteOverlay.Position = SatValBox.Position
                WhiteOverlay.Color = Color3.fromRGB(255, 255, 255)
                WhiteOverlay.Transparency = 0.5 
                WhiteOverlay.ZIndex = 303
                PickerWindow:AddChild(WhiteOverlay)
                
                local BlackOverlay = VirtualDOM.CreateInstance("Square")
                BlackOverlay.Size = SatValBox.Size
                BlackOverlay.Position = SatValBox.Position
                BlackOverlay.Color = Color3.fromRGB(0, 0, 0)
                BlackOverlay.Transparency = 0.5
                BlackOverlay.ZIndex = 304
                PickerWindow:AddChild(BlackOverlay)
                
                local HueBar = VirtualDOM.CreateInstance("Square")
                HueBar.Size = Vector2.new(10, 140)
                HueBar.Position = Vector2.new(145, 10)
                HueBar.Color = Color3.fromRGB(255, 0, 0)
                HueBar.ZIndex = 302
                PickerWindow:AddChild(HueBar)
                VisualEffects.GenerateGradient(HueBar, HueBar.Size, Color3.fromRGB(255, 0, 0), Color3.fromRGB(255, 0, 255), 6, true)
                
                local HueCursor = VirtualDOM.CreateInstance("Square")
                HueCursor.Size = Vector2.new(14, 4)
                HueCursor.Position = Vector2.new(143, 10 + (140 * (1 - CurrentHue)) - 2)
                HueCursor.Color = Color3.fromRGB(255, 255, 255)
                HueCursor.ZIndex = 310
                PickerWindow:AddChild(HueCursor)
                
                local HueCursorOut = VirtualDOM.CreateInstance("Square")
                HueCursorOut.Size = HueCursor.Size
                HueCursorOut.Position = HueCursor.Position
                HueCursorOut.Color = Color3.fromRGB(0, 0, 0)
                HueCursorOut.Filled = false
                HueCursorOut.ZIndex = 311
                PickerWindow:AddChild(HueCursorOut)
                
                local SVDot = VirtualDOM.CreateInstance("Square")
                SVDot.Size = Vector2.new(6, 6)
                SVDot.Position = Vector2.new(10 + (130 * CurrentSat) - 3, 10 + (140 * (1 - CurrentVal)) - 3)
                SVDot.Color = Color3.fromRGB(255, 255, 255)
                SVDot.ZIndex = 310
                PickerWindow:AddChild(SVDot)
                
                local SVDotOut = VirtualDOM.CreateInstance("Square")
                SVDotOut.Size = SVDot.Size
                SVDotOut.Position = SVDot.Position
                SVDotOut.Color = Color3.fromRGB(0, 0, 0)
                SVDotOut.Filled = false
                SVDotOut.ZIndex = 311
                PickerWindow:AddChild(SVDotOut)
                
                local IsHoldingHue = false
                local IsHoldingSV = false
                
                local ForceColorUpdate = function()
                    local NewColor = MathLib.HSVToRGB(CurrentHue, CurrentSat, CurrentVal)
                    ColorAPI.Value = NewColor
                    DisplayBox.Color = NewColor
                    SatValBox.Color = MathLib.HSVToRGB(CurrentHue, 1, 1)
                    if ColorConfig.Callback ~= nil then task.spawn(ColorConfig.Callback, ColorAPI.Value) end
                end
                
                HueBar.InputBegan = function() IsHoldingHue = true end
                SatValBox.InputBegan = function() IsHoldingSV = true end
                
                RunService.RenderStepped:Connect(function()
                    if IsHoldingHue == true then
                        if EngineState.IsMouseDown == false then IsHoldingHue = false return end
                        local RelY = EngineState.MousePosition.Y - HueBar.AbsolutePosition.Y
                        local ClampedY = MathLib.Clamp(RelY, 0, HueBar.AbsoluteSize.Y)
                        CurrentHue = 1 - (ClampedY / HueBar.AbsoluteSize.Y)
                        HueCursor.Position = Vector2.new(143, 10 + ClampedY - 2)
                        HueCursorOut.Position = HueCursor.Position
                        ForceColorUpdate()
                    end
                    if IsHoldingSV == true then
                        if EngineState.IsMouseDown == false then IsHoldingSV = false return end
                        local RelX = EngineState.MousePosition.X - SatValBox.AbsolutePosition.X
                        local RelY = EngineState.MousePosition.Y - SatValBox.AbsolutePosition.Y
                        local ClampedX = MathLib.Clamp(RelX, 0, SatValBox.AbsoluteSize.X)
                        local ClampedY = MathLib.Clamp(RelY, 0, SatValBox.AbsoluteSize.Y)
                        CurrentSat = ClampedX / SatValBox.AbsoluteSize.X
                        CurrentVal = 1 - (ClampedY / SatValBox.AbsoluteSize.Y)
                        SVDot.Position = Vector2.new(10 + ClampedX - 3, 10 + ClampedY - 3)
                        SVDotOut.Position = SVDot.Position
                        ForceColorUpdate()
                    end
                end)
                
                DisplayBox.InputBegan = function(InputData)
                    ColorAPI.IsOpen = not ColorAPI.IsOpen
                    PickerWindow.Visible = ColorAPI.IsOpen
                    if ColorAPI.IsOpen == true then
                        Animator.ConstructTween(ColorLabel, {Color = ThemeConfig.TextPrimary}, 0.2, "Quad", "Out")
                        Animator.ConstructTween(DisplayOut, {Color = ThemeConfig.AccentPrimary}, 0.2, "Quad", "Out")
                    else
                        Animator.ConstructTween(ColorLabel, {Color = ThemeConfig.TextMuted}, 0.2, "Quad", "Out")
                        Animator.ConstructTween(DisplayOut, {Color = ThemeConfig.SectionOutline}, 0.2, "Quad", "Out")
                    end
                end
                
                CompkillerLib.ToggledFlags[ColorFlag] = ColorAPI
                RefreshLayoutsFunction()
                return ColorAPI
            end

            -- ==============================================================================
            -- SUB-COMPONENT: KEYBIND
            -- ==============================================================================
            function SectionAPI:AddKeybind(KeybindConfigTable)
                local KeyConfig = KeybindConfigTable or {}
                local KeyName = KeyConfig.Name or "Keybind Macro"
                local DefaultKey = KeyConfig.Default or Enum.KeyCode.Unknown
                local RandomId = tostring(math.random(100000, 999999))
                local KeyFlag = KeyConfig.Flag or RandomId
                
                local KeyAPI = { Value = DefaultKey, IsBinding = false }
                
                local ElementHeight = 22
                local ElementCanvas = VirtualDOM.CreateInstance("Square")
                ElementCanvas.Size = Vector2.new(ItemContainer.Size.X, ElementHeight)
                ElementCanvas.Transparency = 0
                ItemContainer:AddChild(ElementCanvas)
                
                local KeyLabel = VirtualDOM.CreateInstance("Text")
                KeyLabel.Text = KeyName
                KeyLabel.Size = 13
                KeyLabel.Position = Vector2.new(12, 4)
                KeyLabel.Color = ThemeConfig.TextMuted
                KeyLabel.ZIndex = 106
                ElementCanvas:AddChild(KeyLabel)
                
                local BindBox = VirtualDOM.CreateInstance("Square")
                BindBox.Size = Vector2.new(60, 16)
                BindBox.Position = Vector2.new(ElementCanvas.Size.X - 72, 3)
                BindBox.Color = ThemeConfig.ElementBackground
                BindBox.ZIndex = 106
                ElementCanvas:AddChild(BindBox)
                
                local BindOut = VirtualDOM.CreateInstance("Square")
                BindOut.Size = BindBox.Size
                BindOut.Position = BindBox.Position
                BindOut.Color = ThemeConfig.SectionOutline
                BindOut.Filled = false
                BindOut.ZIndex = 107
                ElementCanvas:AddChild(BindOut)
                
                local BindText = VirtualDOM.CreateInstance("Text")
                BindText.Text = KeyAPI.Value == Enum.KeyCode.Unknown and "None" or KeyAPI.Value.Name
                BindText.Size = 12
                BindText.Position = Vector2.new(BindBox.Position.X + 30, 4)
                BindText.Color = ThemeConfig.TextPrimary
                BindText.Center = true
                BindText.ZIndex = 107
                ElementCanvas:AddChild(BindText)
                
                BindBox.MouseEnter = function()
                    if KeyAPI.IsBinding == false then Animator.ConstructTween(BindBox, {Color = ThemeConfig.ElementHover}, 0.15, "Quad", "Out") end
                end
                
                BindBox.MouseLeave = function()
                    if KeyAPI.IsBinding == false then Animator.ConstructTween(BindBox, {Color = ThemeConfig.ElementBackground}, 0.15, "Quad", "Out") end
                end
                
                BindBox.InputBegan = function(InputData)
                    if KeyAPI.IsBinding == true then return end
                    KeyAPI.IsBinding = true
                    BindText.Text = "..."
                    BindText.Color = ThemeConfig.AccentPrimary
                    Animator.ConstructTween(BindOut, {Color = ThemeConfig.AccentPrimary}, 0.2, "Quint", "Out")
                    
                    local BindConnection
                    BindConnection = UserInputService.InputBegan:Connect(function(KeyInput)
                        local InputType = KeyInput.UserInputType
                        if InputType == Enum.UserInputType.Keyboard then
                            local PressedKey = KeyInput.KeyCode
                            if PressedKey == Enum.KeyCode.Escape or PressedKey == Enum.KeyCode.Backspace then
                                KeyAPI.Value = Enum.KeyCode.Unknown
                                BindText.Text = "None"
                            else
                                KeyAPI.Value = PressedKey
                                BindText.Text = PressedKey.Name
                            end
                            KeyAPI.IsBinding = false
                            BindText.Color = ThemeConfig.TextPrimary
                            Animator.ConstructTween(BindOut, {Color = ThemeConfig.SectionOutline}, 0.2, "Quint", "Out")
                            BindConnection:Disconnect()
                            if KeyConfig.Callback ~= nil then task.spawn(KeyConfig.Callback, KeyAPI.Value) end
                        elseif InputType == Enum.UserInputType.MouseButton1 or InputType == Enum.UserInputType.MouseButton2 or InputType == Enum.UserInputType.MouseButton3 then
                            KeyAPI.Value = InputType
                            if InputType == Enum.UserInputType.MouseButton1 then BindText.Text = "MB1" end
                            if InputType == Enum.UserInputType.MouseButton2 then BindText.Text = "MB2" end
                            if InputType == Enum.UserInputType.MouseButton3 then BindText.Text = "MB3" end
                            KeyAPI.IsBinding = false
                            BindText.Color = ThemeConfig.TextPrimary
                            Animator.ConstructTween(BindOut, {Color = ThemeConfig.SectionOutline}, 0.2, "Quint", "Out")
                            BindConnection:Disconnect()
                            if KeyConfig.Callback ~= nil then task.spawn(KeyConfig.Callback, KeyAPI.Value) end
                        end
                    end)
                end
                
                CompkillerLib.ToggledFlags[KeyFlag] = KeyAPI
                RefreshLayoutsFunction()
                return KeyAPI
            end

            -- ==============================================================================
            -- SUB-COMPONENT: TEXTBOX
            -- ==============================================================================
            function SectionAPI:AddTextBox(TextBoxConfigTable)
                local TextConfig = TextBoxConfigTable or {}
                local TextName = TextConfig.Name or "Text Input"
                local TextDefault = TextConfig.Default or ""
                local RandomId = tostring(math.random(100000, 999999))
                local TextFlag = TextConfig.Flag or RandomId
                local ClearOnFocus = TextConfig.ClearOnFocus or false
                
                local TextAPI = { Value = TextDefault, IsTyping = false }
                
                local ElementHeight = 44
                local ElementCanvas = VirtualDOM.CreateInstance("Square")
                ElementCanvas.Size = Vector2.new(ItemContainer.Size.X, ElementHeight)
                ElementCanvas.Transparency = 0
                ItemContainer:AddChild(ElementCanvas)
                
                local TextLabel = VirtualDOM.CreateInstance("Text")
                TextLabel.Text = TextName
                TextLabel.Size = 13
                TextLabel.Position = Vector2.new(12, 2)
                TextLabel.Color = ThemeConfig.TextMuted
                TextLabel.ZIndex = 106
                ElementCanvas:AddChild(TextLabel)
                
                local InputBox = VirtualDOM.CreateInstance("Square")
                InputBox.Size = Vector2.new(ElementCanvas.Size.X - 24, 22)
                InputBox.Position = Vector2.new(12, 18)
                InputBox.Color = ThemeConfig.ElementBackground
                InputBox.ZIndex = 106
                ElementCanvas:AddChild(InputBox)
                
                local InputOut = VirtualDOM.CreateInstance("Square")
                InputOut.Size = InputBox.Size
                InputOut.Position = InputBox.Position
                InputOut.Color = ThemeConfig.SectionOutline
                InputOut.Filled = false
                InputOut.ZIndex = 107
                ElementCanvas:AddChild(InputOut)
                
                local InputText = VirtualDOM.CreateInstance("Text")
                InputText.Text = TextAPI.Value == "" and "Enter text..." or TextAPI.Value
                InputText.Size = 13
                InputText.Position = Vector2.new(18, 22)
                InputText.Color = TextAPI.Value == "" and ThemeConfig.TextDisabled or ThemeConfig.TextPrimary
                InputText.ZIndex = 107
                ElementCanvas:AddChild(InputText)
                
                local CursorBlink = VirtualDOM.CreateInstance("Square")
                CursorBlink.Size = Vector2.new(1, 12)
                CursorBlink.Position = Vector2.new(18, 23)
                CursorBlink.Color = ThemeConfig.AccentPrimary
                CursorBlink.ZIndex = 108
                CursorBlink.Visible = false
                ElementCanvas:AddChild(CursorBlink)
                
                local BlinkTimer = 0
                RunService.RenderStepped:Connect(function(Delta)
                    if TextAPI.IsTyping == true then
                        BlinkTimer = BlinkTimer + Delta
                        if BlinkTimer >= 0.5 then
                            BlinkTimer = 0
                            CursorBlink.Visible = not CursorBlink.Visible
                        end
                    else
                        CursorBlink.Visible = false
                    end
                end)
                
                InputBox.InputBegan = function(InputData)
                    if EngineState.TypingActive == true then return end
                    EngineState.TypingActive = true
                    EngineState.TypingElement = InputBox
                    TextAPI.IsTyping = true
                    if ClearOnFocus == true then TextAPI.Value = "" end
                    
                    Animator.ConstructTween(InputOut, {Color = ThemeConfig.AccentPrimary}, 0.2, "Quint", "Out")
                    Animator.ConstructTween(TextLabel, {Color = ThemeConfig.TextPrimary}, 0.2, "Quint", "Out")
                    
                    InputText.Text = TextAPI.Value
                    InputText.Color = ThemeConfig.TextPrimary
                    local TextLength = InputText.RenderObject.TextBounds.X
                    CursorBlink.Position = Vector2.new(18 + TextLength + 2, 23)
                    CursorBlink.Visible = true
                    
                    local TypingConnection
                    TypingConnection = UserInputService.InputBegan:Connect(function(KeyInput)
                        local KeyCode = KeyInput.KeyCode
                        if KeyCode == Enum.KeyCode.Return or KeyCode == Enum.KeyCode.Escape then
                            EngineState.TypingActive = false
                            EngineState.TypingElement = nil
                            TextAPI.IsTyping = false
                            
                            Animator.ConstructTween(InputOut, {Color = ThemeConfig.SectionOutline}, 0.2, "Quint", "Out")
                            Animator.ConstructTween(TextLabel, {Color = ThemeConfig.TextMuted}, 0.2, "Quint", "Out")
                            
                            if TextAPI.Value == "" then
                                InputText.Text = "Enter text..."
                                InputText.Color = ThemeConfig.TextDisabled
                            else
                                InputText.Text = TextAPI.Value
                                InputText.Color = ThemeConfig.TextPrimary
                            end
                            TypingConnection:Disconnect()
                            if TextConfig.Callback ~= nil then task.spawn(TextConfig.Callback, TextAPI.Value) end
                        elseif KeyCode == Enum.KeyCode.Backspace then
                            local CurrentLength = string.len(TextAPI.Value)
                            if CurrentLength > 0 then
                                TextAPI.Value = string.sub(TextAPI.Value, 1, CurrentLength - 1)
                                InputText.Text = TextAPI.Value
                                CursorBlink.Position = Vector2.new(18 + InputText.RenderObject.TextBounds.X + 2, 23)
                            end
                        else
                            if KeyInput.UserInputType == Enum.UserInputType.Keyboard then
                                local CharString = UserInputService:GetStringForKeyCode(KeyCode)
                                local ShiftDown = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
                                if ShiftDown == true then
                                    CharString = string.upper(CharString)
                                    if KeyCode == Enum.KeyCode.One then CharString = "!" end
                                    if KeyCode == Enum.KeyCode.Two then CharString = "@" end
                                    if KeyCode == Enum.KeyCode.Three then CharString = "#" end
                                    if KeyCode == Enum.KeyCode.Four then CharString = "$" end
                                    if KeyCode == Enum.KeyCode.Five then CharString = "%" end
                                    if KeyCode == Enum.KeyCode.Six then CharString = "^" end
                                    if KeyCode == Enum.KeyCode.Seven then CharString = "&" end
                                    if KeyCode == Enum.KeyCode.Eight then CharString = "*" end
                                    if KeyCode == Enum.KeyCode.Nine then CharString = "(" end
                                    if KeyCode == Enum.KeyCode.Zero then CharString = ")" end
                                else
                                    CharString = string.lower(CharString)
                                    if KeyCode == Enum.KeyCode.Space then CharString = " " end
                                end
                                
                                if string.match(CharString, "[%w%p%s]") and string.len(CharString) == 1 then
                                    local ProjectedString = TextAPI.Value .. CharString
                                    local ProjectedBounds = InputText.RenderObject.TextBounds.X
                                    if ProjectedBounds < (InputBox.Size.X - 10) then
                                        TextAPI.Value = ProjectedString
                                        InputText.Text = TextAPI.Value
                                        CursorBlink.Position = Vector2.new(18 + InputText.RenderObject.TextBounds.X + 2, 23)
                                    end
                                end
                            end
                        end
                    end)
                end
                
                CompkillerLib.ToggledFlags[TextFlag] = TextAPI
                RefreshLayoutsFunction()
                return TextAPI
            end
            
            -- ==============================================================================
            -- SUB-COMPONENT: BUTTON
            -- ==============================================================================
            function SectionAPI:AddButton(ButtonConfigTable)
                local BtnConfig = ButtonConfigTable or {}
                local BtnName = BtnConfig.Name or "Execute Action"
                
                local ElementHeight = 28
                local ElementCanvas = VirtualDOM.CreateInstance("Square")
                ElementCanvas.Size = Vector2.new(ItemContainer.Size.X, ElementHeight)
                ElementCanvas.Transparency = 0
                ItemContainer:AddChild(ElementCanvas)
                
                local BtnWidth = ElementCanvas.Size.X - 24
                local BtnBody = VirtualDOM.CreateInstance("Square")
                BtnBody.Size = Vector2.new(BtnWidth, 22)
                BtnBody.Position = Vector2.new(12, 3)
                BtnBody.Color = ThemeConfig.ElementBackground
                BtnBody.ZIndex = 106
                BtnBody.ClipsDescendants = true
                ElementCanvas:AddChild(BtnBody)
                
                local BtnOut = VirtualDOM.CreateInstance("Square")
                BtnOut.Size = BtnBody.Size
                BtnOut.Position = BtnBody.Position
                BtnOut.Color = ThemeConfig.SectionOutline
                BtnOut.Filled = false
                BtnOut.ZIndex = 108
                ElementCanvas:AddChild(BtnOut)
                
                local BtnLabel = VirtualDOM.CreateInstance("Text")
                BtnLabel.Text = BtnName
                BtnLabel.Size = 13
                BtnLabel.Position = Vector2.new(ElementCanvas.Size.X / 2, 7)
                BtnLabel.Color = ThemeConfig.TextPrimary
                BtnLabel.Center = true
                BtnLabel.ZIndex = 109
                ElementCanvas:AddChild(BtnLabel)
                
                BtnBody.MouseEnter = function()
                    Animator.ConstructTween(BtnBody, {Color = ThemeConfig.ElementHover}, 0.2, "Quad", "Out")
                    Animator.ConstructTween(BtnOut, {Color = ThemeConfig.AccentPrimary}, 0.2, "Quad", "Out")
                end
                
                BtnBody.MouseLeave = function()
                    Animator.ConstructTween(BtnBody, {Color = ThemeConfig.ElementBackground}, 0.2, "Quad", "Out")
                    Animator.ConstructTween(BtnOut, {Color = ThemeConfig.SectionOutline}, 0.2, "Quad", "Out")
                end
                
                BtnBody.InputBegan = function(InputData)
                    local RippleNode = VirtualDOM.CreateInstance("Circle")
                    RippleNode.Radius = 0
                    RippleNode.Position = Vector2.new(EngineState.MousePosition.X - BtnBody.AbsolutePosition.X, EngineState.MousePosition.Y - BtnBody.AbsolutePosition.Y)
                    RippleNode.Color = ThemeConfig.AccentPrimary
                    RippleNode.Filled = true
                    RippleNode.Transparency = 0.4
                    RippleNode.ZIndex = 107
                    BtnBody:AddChild(RippleNode)
                    
                    Animator.ConstructTween(RippleNode, {Radius = BtnWidth, Transparency = 1}, 0.4, "Quint", "Out", function() RippleNode:Destroy() end)
                    
                    Animator.ConstructTween(BtnLabel, {Color = ThemeConfig.AccentSecondary}, 0.1, "Quad", "Out", function()
                        Animator.ConstructTween(BtnLabel, {Color = ThemeConfig.TextPrimary}, 0.2, "Quad", "Out")
                    end)
                    
                    if BtnConfig.Callback ~= nil then task.spawn(BtnConfig.Callback) end
                end
                
                RefreshLayoutsFunction()
            end
            
            -- ==============================================================================
            -- SUB-COMPONENT: PARAGRAPH / LABEL
            -- ==============================================================================
            function SectionAPI:AddParagraph(LabelConfigTable)
                local LabelConfig = LabelConfigTable or {}
                local TitleString = LabelConfig.Title or "Information"
                local ContentString = LabelConfig.Content or "Description text goes here."
                
                local _, NewlineCount = string.gsub(ContentString, "\n", "")
                local ContentHeight = 15 + (NewlineCount * 14)
                
                local ElementCanvas = VirtualDOM.CreateInstance("Square")
                ElementCanvas.Size = Vector2.new(ItemContainer.Size.X, 22 + ContentHeight)
                ElementCanvas.Transparency = 0
                ItemContainer:AddChild(ElementCanvas)
                
                local TitleLabel = VirtualDOM.CreateInstance("Text")
                TitleLabel.Text = TitleString
                TitleLabel.Size = 13
                TitleLabel.Position = Vector2.new(12, 4)
                TitleLabel.Color = ThemeConfig.TextPrimary
                TitleLabel.ZIndex = 106
                ElementCanvas:AddChild(TitleLabel)
                
                local CurrentYOffset = 20
                for LineData in string.gmatch(ContentString .. "\n", "(.-)\n") do
                    local LineLabel = VirtualDOM.CreateInstance("Text")
                    LineLabel.Text = LineData
                    LineLabel.Size = 13
                    LineLabel.Position = Vector2.new(12, CurrentYOffset)
                    LineLabel.Color = ThemeConfig.TextMuted
                    LineLabel.ZIndex = 106
                    ElementCanvas:AddChild(LineLabel)
                    CurrentYOffset = CurrentYOffset + 14
                end
                
                RefreshLayoutsFunction()
            end
            
            return SectionAPI
        end
        return TabAPI
    end
    
    -- ==============================================================================
    -- EXTERNAL WINDOWS & CONFIGURATION LOGIC
    -- ==============================================================================
    function WindowAPI:SaveConfiguration(ConfigFileName)
        local ExportTable = {}
        for FlagId, FlagAPI in pairs(CompkillerLib.ToggledFlags) do
            local ValueType = typeof(FlagAPI.Value)
            if ValueType == "Color3" then
                ExportTable[FlagId] = {R = FlagAPI.Value.R, G = FlagAPI.Value.G, B = FlagAPI.Value.B, Type = "Color3"}
            elseif ValueType == "EnumItem" then
                ExportTable[FlagId] = {Name = FlagAPI.Value.Name, EnumType = tostring(FlagAPI.Value.EnumType), Type = "Enum"}
            elseif type(FlagAPI.Value) == "table" then
                ExportTable[FlagId] = {Value = FlagAPI.Value, Type = "Table"}
            else
                ExportTable[FlagId] = {Value = FlagAPI.Value, Type = "Primitive"}
            end
        end
        
        local EncodedJSON = HttpService:JSONEncode(ExportTable)
        if writefile ~= nil then
            writefile(ConfigFileName .. ".json", EncodedJSON)
            print("[Compkiller] Exported configuration payload to workspace: " .. ConfigFileName .. ".json")
        else
            warn("[Compkiller] Executor does not support writefile. JSON output:")
            print(EncodedJSON)
        end
    end

    function WindowAPI:LoadConfiguration(ConfigFileName)
        if readfile ~= nil and isfile ~= nil then
            local FullPath = ConfigFileName .. ".json"
            if isfile(FullPath) == true then
                local DecodedTable = HttpService:JSONDecode(readfile(FullPath))
                for FlagId, StoredData in pairs(DecodedTable) do
                    local TargetAPI = CompkillerLib.ToggledFlags[FlagId]
                    if TargetAPI ~= nil then
                        if StoredData.Type == "Color3" then
                            TargetAPI.Value = Color3.new(StoredData.R, StoredData.G, StoredData.B)
                        elseif StoredData.Type == "Enum" then
                            local EnumTypeName = string.match(StoredData.EnumType, "Enum%.(.*)")
                            if EnumTypeName and Enum[EnumTypeName] and Enum[EnumTypeName][StoredData.Name] then
                                TargetAPI.Value = Enum[EnumTypeName][StoredData.Name]
                            end
                        elseif StoredData.Type == "Table" then
                            TargetAPI.Value = StoredData.Value
                        elseif StoredData.Type == "Primitive" then
                            TargetAPI.Value = StoredData.Value
                        end
                    end
                end
                print("[Compkiller] Loaded configuration state from " .. FullPath)
            else
                warn("[Compkiller] Configuration file does not exist: " .. FullPath)
            end
        else
            warn("[Compkiller] Executor missing readfile/isfile capabilities.")
        end
    end
    
    function WindowAPI:CreateWatermark(WatermarkConfigTable)
        local WatermarkConfig = WatermarkConfigTable or {}
        local RefreshRate = WatermarkConfig.RefreshRate or 0.5
        
        local WatermarkCanvas = VirtualDOM.CreateInstance("Square")
        WatermarkCanvas.Size = Vector2.new(280, 24)
        WatermarkCanvas.Position = Vector2.new(40, 40)
        WatermarkCanvas.Color = ThemeConfig.WindowBackground
        WatermarkCanvas.ZIndex = 400
        VisualEffects.GenerateDropShadow(WatermarkCanvas, WatermarkCanvas.Size, Vector2.new(0, 0), 15, 0.4, 10)
        
        local OutLine = VirtualDOM.CreateInstance("Square")
        OutLine.Size = WatermarkCanvas.Size
        OutLine.Color = ThemeConfig.OutlineOuter
        OutLine.Filled = false
        OutLine.ZIndex = 401
        WatermarkCanvas:AddChild(OutLine)
        
        local InLine = VirtualDOM.CreateInstance("Square")
        InLine.Size = WatermarkCanvas.Size - Vector2.new(2, 2)
        InLine.Position = Vector2.new(1, 1)
        InLine.Color = ThemeConfig.OutlineInner
        InLine.Filled = false
        InLine.ZIndex = 401
        WatermarkCanvas:AddChild(InLine)
        
        local TopBar = VirtualDOM.CreateInstance("Square")
        TopBar.Size = Vector2.new(WatermarkCanvas.Size.X - 2, 2)
        TopBar.Position = Vector2.new(1, 1)
        TopBar.Color = ThemeConfig.AccentPrimary
        TopBar.ZIndex = 402
        WatermarkCanvas:AddChild(TopBar)
        
        local InfoText = VirtualDOM.CreateInstance("Text")
        InfoText.Text = "COMPKILLER | FPS: 0 | PING: 0ms | TIME: 00:00"
        InfoText.Size = 13
        InfoText.Position = Vector2.new(10, 5)
        InfoText.Color = ThemeConfig.TextPrimary
        InfoText.ZIndex = 403
        WatermarkCanvas:AddChild(InfoText)
        
        local LastUpdate, Frames, FpsCounter = 0, 0, 0
        RunService.RenderStepped:Connect(function(Delta)
            Frames = Frames + 1
            LastUpdate = LastUpdate + Delta
            if LastUpdate >= RefreshRate then
                FpsCounter = math.floor(Frames / LastUpdate)
                Frames, LastUpdate = 0, 0
                InfoText.Text = string.format("COMPKILLER | FPS: %d | PING: 0ms | TIME: %s", FpsCounter, os.date("%H:%M:%S"))
                local NewCanvasWidth = InfoText.RenderObject.TextBounds.X + 20
                WatermarkCanvas.Size = Vector2.new(NewCanvasWidth, 24)
                OutLine.Size = WatermarkCanvas.Size
                InLine.Size = WatermarkCanvas.Size - Vector2.new(2, 2)
                TopBar.Size = Vector2.new(WatermarkCanvas.Size.X - 2, 2)
            end
        end)
    end
    
    function WindowAPI:CreateKeybindList()
        local KeybindCanvas = VirtualDOM.CreateInstance("Square")
        KeybindCanvas.Size = Vector2.new(180, 24)
        KeybindCanvas.Position = Vector2.new(40, 80)
        KeybindCanvas.Color = ThemeConfig.WindowBackground
        KeybindCanvas.ZIndex = 400
        VisualEffects.GenerateDropShadow(KeybindCanvas, KeybindCanvas.Size, Vector2.new(0, 0), 15, 0.4, 10)
        
        local OutLine = VirtualDOM.CreateInstance("Square")
        OutLine.Size = KeybindCanvas.Size
        OutLine.Color = ThemeConfig.OutlineOuter
        OutLine.Filled = false
        OutLine.ZIndex = 401
        KeybindCanvas:AddChild(OutLine)
        
        local InLine = VirtualDOM.CreateInstance("Square")
        InLine.Size = KeybindCanvas.Size - Vector2.new(2, 2)
        InLine.Position = Vector2.new(1, 1)
        InLine.Color = ThemeConfig.OutlineInner
        InLine.Filled = false
        InLine.ZIndex = 401
        KeybindCanvas:AddChild(InLine)
        
        local TopBar = VirtualDOM.CreateInstance("Square")
        TopBar.Size = Vector2.new(KeybindCanvas.Size.X - 2, 2)
        TopBar.Position = Vector2.new(1, 1)
        TopBar.Color = ThemeConfig.AccentPrimary
        TopBar.ZIndex = 402
        KeybindCanvas:AddChild(TopBar)
        
        local TitleText = VirtualDOM.CreateInstance("Text")
        TitleText.Text = "Keybinds"
        TitleText.Size = 13
        TitleText.Position = Vector2.new(KeybindCanvas.Size.X / 2, 5)
        TitleText.Color = ThemeConfig.AccentSecondary
        TitleText.Center = true
        TitleText.ZIndex = 403
        KeybindCanvas:AddChild(TitleText)
        
        local ItemContainer = VirtualDOM.CreateInstance("Square")
        ItemContainer.Size = Vector2.new(KeybindCanvas.Size.X, 0)
        ItemContainer.Position = Vector2.new(0, 24)
        ItemContainer.Transparency = 0
        ItemContainer.ZIndex = 401
        KeybindCanvas:AddChild(ItemContainer)
        
        local ActiveBinds = {}
        local function RefreshKeybindLayout()
            local CurrentY = 0
            for _, Element in ipairs(ItemContainer.Children) do Element:Destroy() end
            
            for BindName, BindState in pairs(ActiveBinds) do
                if BindState == true then
                    local BindLabel = VirtualDOM.CreateInstance("Text")
                    BindLabel.Text = BindName
                    BindLabel.Size = 13
                    BindLabel.Position = Vector2.new(10, CurrentY + 4)
                    BindLabel.Color = ThemeConfig.TextPrimary
                    BindLabel.ZIndex = 402
                    ItemContainer:AddChild(BindLabel)
                    
                    local StateLabel = VirtualDOM.CreateInstance("Text")
                    StateLabel.Text = "[ON]"
                    StateLabel.Size = 13
                    StateLabel.Position = Vector2.new(KeybindCanvas.Size.X - 35, CurrentY + 4)
                    StateLabel.Color = ThemeConfig.AccentPrimary
                    StateLabel.ZIndex = 402
                    ItemContainer:AddChild(StateLabel)
                    CurrentY = CurrentY + 20
                end
            end
            
            local TargetCanvasHeight = CurrentY == 0 and 24 or 24 + CurrentY
            KeybindCanvas.Size = Vector2.new(KeybindCanvas.Size.X, TargetCanvasHeight)
            OutLine.Size = KeybindCanvas.Size
            InLine.Size = KeybindCanvas.Size - Vector2.new(2, 2)
            ItemContainer.Size = Vector2.new(KeybindCanvas.Size.X, CurrentY)
        end
        
        RunService.RenderStepped:Connect(function()
            local HasChanges = false
            for FlagId, API in pairs(CompkillerLib.ToggledFlags) do
                if API.Value ~= nil and typeof(API.Value) == "EnumItem" then
                    local IsKeyDown = false
                    if API.Value.EnumType == Enum.KeyCode then IsKeyDown = UserInputService:IsKeyDown(API.Value)
                    elseif API.Value.EnumType == Enum.UserInputType then
                        local MouseStates = { [Enum.UserInputType.MouseButton1] = EngineState.IsMouseDown, [Enum.UserInputType.MouseButton2] = EngineState.IsRightMouseDown }
                        IsKeyDown = MouseStates[API.Value] or false
                    end
                    if ActiveBinds[FlagId] ~= IsKeyDown then
                        ActiveBinds[FlagId] = IsKeyDown
                        HasChanges = true
                    end
                end
            end
            if HasChanges == true then RefreshKeybindLayout() end
        end)
    end
    
    return WindowAPI
end

return CompkillerLib
