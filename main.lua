local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local MyId = Player.UserId

local Dimension = workspace:WaitForChild("HalloweenDimension")
local Monsters = Dimension:WaitForChild("Monsters")
local EggFolder = Dimension:WaitForChild("WorldEggs")

local Settings = {
    TPDistance = 20,
    TPInterval = 0.4,
    WalkSpeed = 16,
    FlySpeed = 60,
    FollowTime = 2,
    ArrivalDistance = 5,
    MinTravelTime = 2,
    MaxTravelTime = 6,
    SecondsPerStud = 0.05,
    EggHoldTime = 0.7,
    TravelTimeout = 4
}

local NtfyBase = "https://ntfy.sh"
local ChatTopic = "halloween-dim-chat-x7Qp2"
local AdminCode = "BarkForMarin"
local RequestFunction = request or http_request or (syn and syn.request)

local Strings = {
    RU = {
        title = "ХЭЛЛОУИН ИЗМЕРЕНИЕ",
        tab_targets = "Цели",
        tab_settings = "Настройки",
        tab_eggs = "Яйца",
        tab_message = "Сообщения",
        tab_admin = "Админ",
        select_targets = "ВЫБРАТЬ ЦЕЛИ ▼",
        mode_tp = "ТЕЛЕПОРТ",
        mode_walk = "ХОДЬБА",
        mode_fly = "ПОЛЁТ",
        auto_egg = "АВТО ЯЙЦА",
        save_here = "СЕЙВ ЗДЕСЬ",
        save_zone = "SAVE ZONE",
        on = "ВКЛ",
        off = "ВЫКЛ",
        status_idle = "Статус: Ожидание",
        status_no_targets = "Нет выбранных целей",
        status_wait_spawn = "Ожидание спавна",
        status_target = "Цель: ",
        status_follow = "Следование: ",
        status_no_eggs = "Нет выбранных яиц",
        status_egg = "Яйцо: ",
        status_return = "Возврат к точке",
        status_no_zone = "Save zone не найдена",
        status_point_set = "Точка возврата установлена",
        status_no_tp_auto = "TP отключен в AUTO EGGS",
        set_tp_distance = "Дистанция телепорта:",
        set_tp_interval = "Интервал телепорта:",
        set_walk_speed = "Скорость ходьбы:",
        set_fly_speed = "Скорость полёта:",
        set_follow_time = "Время следования:",
        chat_send = "ОТПР.",
        chat_placeholder = "Сообщение...",
        chat_online = "Онлайн",
        chat_no_users = "Никого нет онлайн",
        admin_code = "Введите код",
        admin_enter = "ВОЙТИ",
        admin_wrong = "Неверный код",
        admin_placeholder = "Админ панель (скоро)"
    },
    EN = {
        title = "HALLOWEEN DIMENSION",
        tab_targets = "Targets",
        tab_settings = "Settings",
        tab_eggs = "Eggs",
        tab_message = "Messages",
        tab_admin = "Admin",
        select_targets = "SELECT TARGETS ▼",
        mode_tp = "TELEPORT",
        mode_walk = "WALK",
        mode_fly = "FLY",
        auto_egg = "AUTO EGGS",
        save_here = "SAVE HERE",
        save_zone = "SAVE ZONE",
        on = "ON",
        off = "OFF",
        status_idle = "Status: Idle",
        status_no_targets = "No targets selected",
        status_wait_spawn = "Waiting for spawn",
        status_target = "Target: ",
        status_follow = "Following: ",
        status_no_eggs = "No eggs selected",
        status_egg = "Egg: ",
        status_return = "Returning to point",
        status_no_zone = "Save zone not found",
        status_point_set = "Return point set",
        status_no_tp_auto = "TP disabled in AUTO EGGS",
        set_tp_distance = "Teleport distance:",
        set_tp_interval = "Teleport interval:",
        set_walk_speed = "Walk speed:",
        set_fly_speed = "Fly speed:",
        set_follow_time = "Follow time:",
        chat_send = "SEND",
        chat_placeholder = "Message...",
        chat_online = "Online",
        chat_no_users = "No one online",
        admin_code = "Enter code",
        admin_enter = "ENTER",
        admin_wrong = "Wrong code",
        admin_placeholder = "Admin panel (coming soon)"
    }
}

local Language = "RU"
local Localized = {}
local StatusKey = "status_idle"
local StatusExtra = ""

local function T(key)
    return Strings[Language][key] or key
end

local SelectedNames = {}
local SelectedEggs = {}
local ActiveMode = nil
local EggMode = nil
local AutoEgg = false
local UseCustomPoint = false
local CustomPoint = nil
local Minimized = false
local EggWindows = {}
local HoverWindows = {}
local HoverConnections = {}
local EggCards = {}
local ModeButtons = {}
local EggModeButtons = {}
local LangButtons = {}
local Peers = {}
local Histories = {}
local ThumbCache = {}
local Seen = {}
local Since = os.time() - 30
local ChatWin = nil
local ChatPeer = nil
local ChatLog = nil
local ChatInput = nil
local AdminUnlocked = false

local ModeKeys = {
    TP = "mode_tp",
    Walk = "mode_walk",
    Fly = "mode_fly"
}

local EffectClasses = {
    ParticleEmitter = true,
    Beam = true,
    Trail = true,
    Fire = true,
    Smoke = true,
    Sparkles = true,
    Highlight = true,
    PointLight = true,
    SpotLight = true,
    SurfaceLight = true
}

local ColorOn = Color3.fromRGB(45, 135, 70)
local ColorOff = Color3.fromRGB(48, 48, 62)
local ColorDisabled = Color3.fromRGB(32, 32, 40)
local ColorEggCard = Color3.fromRGB(40, 40, 53)
local ColorTab = Color3.fromRGB(180, 90, 40)
local ColorPanel = Color3.fromRGB(28, 28, 37)
local ColorHeader = Color3.fromRGB(43, 43, 57)

local Gui = Instance.new("ScreenGui")
Gui.Name = "HalloweenMenu"
Gui.ResetOnSpawn = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent = PlayerGui

local function Create(class, properties, parent)
    local object = Instance.new(class)

    for key, value in pairs(properties) do
        object[key] = value
    end

    object.Parent = parent
    return object
end

local function Tween(object, duration, properties)
    local tween = TweenService:Create(
        object,
        TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        properties
    )

    tween:Play()
    return tween
end

local function SetColor(object, color)
    Tween(object, 0.2, {BackgroundColor3 = color})
end

local function Corner(object, radius)
    Create("UICorner", {
        CornerRadius = UDim.new(0, radius or 7)
    }, object)
end

local function Localize(object, key)
    table.insert(Localized, {Object = object, Key = key})
    object.Text = T(key)
    return object
end

local function CreateLabel(parent, text, position)
    return Create("TextLabel", {
        Size = UDim2.new(1, -5, 0, 27),
        Position = UDim2.fromOffset(5, position),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Color3.fromRGB(220, 220, 230),
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left
    }, parent)
end

local Main = Create("Frame", {
    Size = UDim2.fromOffset(550, 390),
    Position = UDim2.new(0.5, -275, 0.5, -195),
    BackgroundColor3 = Color3.fromRGB(23, 23, 31),
    BorderSizePixel = 0
}, Gui)

Corner(Main, 9)

local Header = Create("Frame", {
    Size = UDim2.new(1, 0, 0, 40),
    BackgroundColor3 = Color3.fromRGB(37, 37, 49),
    BorderSizePixel = 0
}, Main)

Corner(Header, 9)

Localize(Create("TextLabel", {
    Size = UDim2.new(1, -165, 1, 0),
    Position = UDim2.fromOffset(12, 0),
    BackgroundTransparency = 1,
    TextColor3 = Color3.fromRGB(255, 160, 65),
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left
}, Header), "title")

local Minimize = Create("TextButton", {
    Size = UDim2.fromOffset(32, 30),
    Position = UDim2.new(1, -72, 0, 5),
    Text = "-",
    BackgroundColor3 = Color3.fromRGB(55, 55, 70),
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 20
}, Header)

local Close = Create("TextButton", {
    Size = UDim2.fromOffset(32, 30),
    Position = UDim2.new(1, -36, 0, 5),
    Text = "X",
    BackgroundColor3 = Color3.fromRGB(150, 45, 45),
    TextColor3 = Color3.new(1, 1, 1)
}, Header)

local function CreateLangButton(lang, xOffset)
    local button = Create("TextButton", {
        Size = UDim2.fromOffset(34, 30),
        Position = UDim2.new(1, xOffset, 0, 5),
        Text = lang,
        BackgroundColor3 = ColorOff,
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = 12
    }, Header)

    Corner(button, 5)
    LangButtons[lang] = button
end

CreateLangButton("EN", -110)
CreateLangButton("RU", -148)

local dragging = false
local dragStart
local startPos

Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart

        Main.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

local Tabs = Create("Frame", {
    Size = UDim2.new(0, 115, 1, -50),
    Position = UDim2.fromOffset(8, 46),
    BackgroundColor3 = Color3.fromRGB(30, 30, 40),
    BorderSizePixel = 0
}, Main)

local Content = Create("Frame", {
    Size = UDim2.new(1, -140, 1, -55),
    Position = UDim2.fromOffset(130, 47),
    BackgroundTransparency = 1,
    ClipsDescendants = true
}, Main)

local function CreateTab(key, position)
    local button = Localize(Create("TextButton", {
        Size = UDim2.new(1, -10, 0, 36),
        Position = UDim2.fromOffset(5, position),
        BackgroundColor3 = ColorOff,
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = 11
    }, Tabs), key)

    Corner(button, 5)
    return button
end

local TargetTab = CreateTab("tab_targets", 8)
local SettingsTab = CreateTab("tab_settings", 50)
local EggTab = CreateTab("tab_eggs", 92)
local MessageTab = CreateTab("tab_message", 134)
local AdminTab = CreateTab("tab_admin", 176)

local TargetPage = Create("Frame", {
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1
}, Content)

local SettingsPage = Create("ScrollingFrame", {
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    CanvasSize = UDim2.fromOffset(0, 300),
    Visible = false
}, Content)

local EggPage = Create("Frame", {
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Visible = false
}, Content)

local MessagePage = Create("Frame", {
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Visible = false
}, Content)

local AdminPage = Create("Frame", {
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Visible = false
}, Content)

local function CreateInput(parent, key, value, position, callback)
    Localize(CreateLabel(parent, "", position), key)

    local box = Create("TextBox", {
        Size = UDim2.fromOffset(105, 27),
        Position = UDim2.new(1, -112, 0, position),
        BackgroundColor3 = Color3.fromRGB(43, 43, 56),
        TextColor3 = Color3.new(1, 1, 1),
        Text = tostring(value),
        Font = Enum.Font.Gotham,
        TextSize = 12,
        ClearTextOnFocus = false
    }, parent)

    Corner(box, 5)

    box.FocusLost:Connect(function()
        local number = tonumber(box.Text)

        if number and number > 0 then
            callback(number)
            box.Text = tostring(number)
        else
            box.Text = tostring(value)
        end
    end)

    return box
end

local TargetButton = Localize(Create("TextButton", {
    Size = UDim2.new(1, 0, 0, 35),
    BackgroundColor3 = ColorOff,
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamBold,
    TextSize = 12
}, TargetPage), "select_targets")

Corner(TargetButton, 5)

local List = Create("ScrollingFrame", {
    Size = UDim2.new(1, 0, 0, 155),
    Position = UDim2.fromOffset(0, 40),
    BackgroundColor3 = ColorPanel,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    CanvasSize = UDim2.fromOffset(0, 0),
    ClipsDescendants = true,
    Visible = false
}, TargetPage)

Create("UIListLayout", {
    Padding = UDim.new(0, 4),
    SortOrder = Enum.SortOrder.LayoutOrder
}, List)

local function CreateModeButton(name, position)
    local button = Create("TextButton", {
        Size = UDim2.new(1, 0, 0, 36),
        Position = UDim2.fromOffset(0, position),
        BackgroundColor3 = ColorOff,
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = 12
    }, TargetPage)

    Corner(button, 5)
    ModeButtons[name] = button
end

CreateModeButton("TP", 205)
CreateModeButton("Walk", 248)
CreateModeButton("Fly", 291)

local Status = CreateLabel(TargetPage, "", 335)

local EggControls = Create("Frame", {
    Size = UDim2.new(1, 0, 0, 30),
    BackgroundTransparency = 1
}, EggPage)

Create("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 6),
    SortOrder = Enum.SortOrder.LayoutOrder
}, EggControls)

local AutoEggButton = Localize(Create("TextButton", {
    Size = UDim2.new(0.25, -5, 1, 0),
    LayoutOrder = 0,
    BackgroundColor3 = ColorOff,
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamBold,
    TextSize = 11
}, EggControls), "auto_egg")

Corner(AutoEggButton, 5)

for index, name in ipairs({"TP", "Walk", "Fly"}) do
    local button = Localize(Create("TextButton", {
        Size = UDim2.new(0.25, -5, 1, 0),
        LayoutOrder = index,
        BackgroundColor3 = ColorOff,
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = 11
    }, EggControls), ModeKeys[name])

    Corner(button, 5)
    EggModeButtons[name] = button
end

local EggStatus = CreateLabel(EggPage, "", 34)

local EggControls2 = Create("Frame", {
    Size = UDim2.new(1, 0, 0, 26),
    Position = UDim2.fromOffset(0, 62),
    BackgroundTransparency = 1
}, EggPage)

Create("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 6),
    SortOrder = Enum.SortOrder.LayoutOrder
}, EggControls2)

local SaveHereButton = Localize(Create("TextButton", {
    Size = UDim2.new(0.5, -3, 1, 0),
    LayoutOrder = 0,
    BackgroundColor3 = ColorOff,
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamBold,
    TextSize = 11
}, EggControls2), "save_here")

Corner(SaveHereButton, 5)

local SaveZoneButton = Localize(Create("TextButton", {
    Size = UDim2.new(0.5, -3, 1, 0),
    LayoutOrder = 1,
    BackgroundColor3 = ColorOff,
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamBold,
    TextSize = 11
}, EggControls2), "save_zone")

Corner(SaveZoneButton, 5)

CreateInput(SettingsPage, "set_tp_distance", Settings.TPDistance, 5, function(v)
    Settings.TPDistance = math.clamp(v, 1, 500)
end)

CreateInput(SettingsPage, "set_tp_interval", Settings.TPInterval, 48, function(v)
    Settings.TPInterval = math.clamp(v, 0.05, 5)
end)

CreateInput(SettingsPage, "set_walk_speed", Settings.WalkSpeed, 91, function(v)
    Settings.WalkSpeed = math.clamp(v, 1, 200)
end)

CreateInput(SettingsPage, "set_fly_speed", Settings.FlySpeed, 134, function(v)
    Settings.FlySpeed = math.clamp(v, 1, 300)
end)

CreateInput(SettingsPage, "set_follow_time", Settings.FollowTime, 177, function(v)
    Settings.FollowTime = math.clamp(v, 0.1, 10)
end)

local MyCard = Create("Frame", {
    Size = UDim2.new(1, 0, 0, 44),
    BackgroundColor3 = ColorEggCard,
    BorderSizePixel = 0
}, MessagePage)

Corner(MyCard, 7)

local MyAvatar = Create("ImageLabel", {
    Size = UDim2.fromOffset(36, 36),
    Position = UDim2.fromOffset(4, 4),
    BackgroundTransparency = 1
}, MyCard)

Corner(MyAvatar, 18)

Create("TextLabel", {
    Size = UDim2.new(1, -50, 1, -8),
    Position = UDim2.fromOffset(46, 4),
    BackgroundTransparency = 1,
    Text = Player.DisplayName .. "  (@" .. Player.Name .. ")",
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd
}, MyCard)

local OnlineLabel = CreateLabel(MessagePage, "", 50)

local UserList = Create("ScrollingFrame", {
    Size = UDim2.new(1, 0, 1, -76),
    Position = UDim2.fromOffset(0, 72),
    BackgroundColor3 = ColorPanel,
    BorderSizePixel = 0,
    ScrollBarThickness = 5,
    CanvasSize = UDim2.fromOffset(0, 0)
}, MessagePage)

Create("UIListLayout", {
    Padding = UDim.new(0, 4),
    SortOrder = Enum.SortOrder.LayoutOrder
}, UserList)

local LockFrame = Create("Frame", {
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1
}, AdminPage)

Localize(CreateLabel(LockFrame, "", 10), "admin_code")

local AdminBox = Create("TextBox", {
    Size = UDim2.new(1, -20, 0, 32),
    Position = UDim2.fromOffset(10, 44),
    BackgroundColor3 = Color3.fromRGB(43, 43, 56),
    TextColor3 = Color3.new(1, 1, 1),
    Text = "",
    Font = Enum.Font.Gotham,
    TextSize = 12,
    ClearTextOnFocus = false
}, LockFrame)

Corner(AdminBox, 5)

local AdminEnter = Localize(Create("TextButton", {
    Size = UDim2.new(1, -20, 0, 34),
    Position = UDim2.fromOffset(10, 86),
    BackgroundColor3 = ColorTab,
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamBold,
    TextSize = 12
}, LockFrame), "admin_enter")

Corner(AdminEnter, 5)

local AdminMsg = CreateLabel(LockFrame, "", 126)

local PanelFrame = Create("Frame", {
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Visible = false
}, AdminPage)

Localize(CreateLabel(PanelFrame, "", 10), "admin_placeholder")

local function SetStatus(key, extra)
    StatusKey = key
    StatusExtra = extra or ""

    local text = T(key) .. StatusExtra
    Status.Text = text
    EggStatus.Text = text
end

local function GetCharacter()
    local character = Player.Character

    if not character then
        return
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")

    if humanoid and root then
        return character, humanoid, root
    end
end

local function GetTargetPosition(target)
    if not target or not target.Parent then
        return nil
    end

    if target:IsA("Model") then
        return target:GetPivot().Position
    elseif target:IsA("BasePart") then
        return target.Position
    end
end

local function GetFollowPosition(target)
    if not target or not target.Parent then
        return nil
    end

    local cf

    if target:IsA("Model") then
        cf = target:GetPivot()
    else
        cf = target.CFrame
    end

    return (cf * CFrame.new(0, 0, 4)).Position
end

local function DistanceTo(target, origin)
    local position = GetTargetPosition(target)

    if not position then
        return math.huge
    end

    return (position - origin).Magnitude
end

local function GetTargets()
    local _, _, root = GetCharacter()
    local result = {}

    for _, target in ipairs(Monsters:GetChildren()) do
        if (target:IsA("Model") or target:IsA("BasePart")) and SelectedNames[target.Name] then
            table.insert(result, target)
        end
    end

    if root then
        local origin = root.Position

        table.sort(result, function(a, b)
            return DistanceTo(a, origin) < DistanceTo(b, origin)
        end)
    end

    return result
end

local function GetSelectedEggs()
    local _, _, root = GetCharacter()
    local result = {}

    for model in pairs(SelectedEggs) do
        if model.Parent == EggFolder then
            table.insert(result, model)
        else
            SelectedEggs[model] = nil
        end
    end

    if root then
        local origin = root.Position

        table.sort(result, function(a, b)
            return DistanceTo(a, origin) < DistanceTo(b, origin)
        end)
    end

    return result
end

local function FollowTarget(target, mode)
    local start = os.clock()

    while ActiveMode == mode
        and target.Parent == Monsters
        and os.clock() - start < Settings.FollowTime do

        local _, humanoid, root = GetCharacter()
        local position = GetFollowPosition(target)

        if not humanoid or not root or not position then
            break
        end

        if mode == "TP" then
            local direction = position - root.Position

            if direction.Magnitude > 0.1 then
                root.CFrame = CFrame.lookAt(
                    position,
                    GetTargetPosition(target)
                )
            end

        elseif mode == "Walk" then
            humanoid.WalkSpeed = Settings.WalkSpeed
            humanoid:MoveTo(position)

        elseif mode == "Fly" then
            local flat = Vector3.new(position.X, root.Position.Y, position.Z)
            local direction = flat - root.Position

            if direction.Magnitude > 1 then
                root.AssemblyLinearVelocity =
                    Vector3.new(direction.Unit.X, 0, direction.Unit.Z) * Settings.FlySpeed
            else
                root.AssemblyLinearVelocity = Vector3.zero
            end
        end

        task.wait(0.1)
    end

    local _, humanoid, root = GetCharacter()

    if humanoid then
        humanoid:Move(Vector3.zero)
    end

    if root then
        root.AssemblyLinearVelocity = Vector3.zero
    end
end

local function MoveTP(target)
    while ActiveMode == "TP" and target.Parent == Monsters do
        local _, _, root = GetCharacter()
        local position = GetTargetPosition(target)

        if not root or not position then
            return false
        end

        local direction = position - root.Position
        local distance = direction.Magnitude

        if distance <= Settings.ArrivalDistance then
            return true
        end

        local step = math.min(
            Settings.TPDistance,
            distance - Settings.ArrivalDistance
        )

        root.CFrame = CFrame.lookAt(
            root.Position + direction.Unit * step,
            position
        )

        task.wait(Settings.TPInterval)
    end

    return false
end

local function MoveWalk(target)
    while ActiveMode == "Walk" and target.Parent == Monsters do
        local _, humanoid, root = GetCharacter()
        local position = GetTargetPosition(target)

        if not humanoid or not root or not position then
            return false
        end

        local distance = (position - root.Position).Magnitude

        if distance <= Settings.ArrivalDistance then
            return true
        end

        humanoid.WalkSpeed = Settings.WalkSpeed
        humanoid:MoveTo(position)

        task.wait(0.2)
    end

    return false
end

local function MoveFly(target)
    local _, humanoid, root = GetCharacter()

    if not humanoid or not root then
        return false
    end

    local lockedY = root.Position.Y

    local attachment = Instance.new("Attachment")
    attachment.Parent = root

    local velocity = Instance.new("LinearVelocity")
    velocity.Attachment0 = attachment
    velocity.MaxForce = math.huge
    velocity.RelativeTo = Enum.ActuatorRelativeTo.World
    velocity.VectorVelocity = Vector3.zero
    velocity.Parent = root

    humanoid.AutoRotate = false

    local reached = false

    while ActiveMode == "Fly" and target.Parent == Monsters do
        local position = GetTargetPosition(target)

        if not position then
            break
        end

        local flat = Vector3.new(position.X, lockedY, position.Z)
        local direction = flat - root.Position
        local distance = direction.Magnitude

        if distance <= Settings.ArrivalDistance then
            reached = true
            break
        end

        velocity.VectorVelocity = direction.Unit * Settings.FlySpeed

        root.CFrame = CFrame.lookAt(
            root.Position,
            flat
        )

        task.wait(0.05)
    end

    velocity:Destroy()
    attachment:Destroy()

    if humanoid.Parent then
        humanoid.AutoRotate = true
    end

    root.AssemblyLinearVelocity = Vector3.zero

    return reached
end

local function NormalizeName(name)
    return (string.lower(name):gsub("[%s_%-]", ""))
end

local function FindSaveZone()
    local folder = workspace:FindFirstChild("HalloweenDimension-ZonesAssets-Spawn", true)

    if not folder then
        return nil
    end

    for _, object in ipairs(folder:GetDescendants()) do
        if object:IsA("BasePart") or object:IsA("Model") then
            if NormalizeName(object.Name) == "savezone" then
                return object
            end
        end
    end

    return nil
end

local function GetZoneGoal(zone)
    if not zone or not zone.Parent then
        return nil
    end

    return GetTargetPosition(zone) + Vector3.new(0, 3, 0)
end

local function Travel(getGoal, mode, duration, isValid, holdTime)
    local _, humanoid, root = GetCharacter()

    if not humanoid or not root then
        return false
    end

    local lockedY = root.Position.Y
    local attachment
    local velocity

    if mode == "Fly" then
        attachment = Instance.new("Attachment")
        attachment.Parent = root

        velocity = Instance.new("LinearVelocity")
        velocity.Attachment0 = attachment
        velocity.MaxForce = math.huge
        velocity.RelativeTo = Enum.ActuatorRelativeTo.World
        velocity.VectorVelocity = Vector3.zero
        velocity.Parent = root

        humanoid.AutoRotate = false
    end

    local startTime = os.clock()
    local limit = duration + Settings.TravelTimeout
    local reached = false

    while isValid() and os.clock() - startTime < limit do
        local _, currentHumanoid, currentRoot = GetCharacter()
        local goal = getGoal()

        if not currentHumanoid or not currentRoot or not goal then
            break
        end

        if mode == "Fly" then
            goal = Vector3.new(goal.X, lockedY, goal.Z)
        end

        local delta = goal - currentRoot.Position
        local distance = delta.Magnitude

        if distance <= Settings.ArrivalDistance then
            reached = true
            break
        end

        local timeLeft = math.max(duration - (os.clock() - startTime), 0.05)
        local speed = distance / timeLeft

        if mode == "TP" then
            local step = math.min(distance, speed * Settings.TPInterval)

            currentRoot.CFrame = CFrame.lookAt(
                currentRoot.Position + delta.Unit * step,
                goal
            )

            task.wait(Settings.TPInterval)

        elseif mode == "Walk" then
            currentHumanoid.WalkSpeed = math.clamp(speed, 1, 200)
            currentHumanoid:MoveTo(goal)

            task.wait(0.1)

        else
            velocity.VectorVelocity = delta.Unit * speed

            currentRoot.CFrame = CFrame.lookAt(
                currentRoot.Position,
                goal
            )

            task.wait(0.05)
        end
    end

    if reached and holdTime > 0 and isValid() then
        local _, currentHumanoid, currentRoot = GetCharacter()

        if velocity then
            velocity.VectorVelocity = Vector3.zero
        end

        if mode == "Walk" and currentHumanoid and currentRoot then
            currentHumanoid:MoveTo(currentRoot.Position)
        end

        local holdStart = os.clock()

        while isValid() and os.clock() - holdStart < holdTime do
            task.wait(0.05)
        end
    end

    if velocity then
        velocity:Destroy()
    end

    if attachment then
        attachment:Destroy()
    end

    local _, finalHumanoid, finalRoot = GetCharacter()

    if finalHumanoid then
        finalHumanoid:Move(Vector3.zero)
        finalHumanoid.AutoRotate = true

        if mode == "Walk" then
            finalHumanoid.WalkSpeed = Settings.WalkSpeed
        end
    end

    if finalRoot then
        finalRoot.AssemblyLinearVelocity = Vector3.zero
    end

    return reached
end

local function EggLeg(getGoal, mode, isValid, holdTime)
    local goal = getGoal()
    local _, _, root = GetCharacter()

    if not goal or not root then
        return false
    end

    local distance = (goal - root.Position).Magnitude
    local duration = math.clamp(
        distance * Settings.SecondsPerStud,
        Settings.MinTravelTime,
        Settings.MaxTravelTime
    )

    return Travel(getGoal, mode, duration, isValid, holdTime)
end

local function UpdateModeButtons()
    for name, button in pairs(ModeButtons) do
        local on = ActiveMode == name

        button.Text = T(ModeKeys[name]) .. ": " .. T(on and "on" or "off")
        SetColor(button, on and ColorOn or ColorOff)
    end
end

local function UpdateEggControls()
    for name, button in pairs(EggModeButtons) do
        if name == "TP" and AutoEgg then
            SetColor(button, ColorDisabled)
        else
            SetColor(button, EggMode == name and ColorOn or ColorOff)
        end
    end

    SetColor(AutoEggButton, AutoEgg and ColorOn or ColorOff)
    SetColor(SaveHereButton, UseCustomPoint and ColorOn or ColorOff)
    SetColor(SaveZoneButton, UseCustomPoint and ColorOff or ColorOn)
end

local function UpdateLanguageButtons()
    for lang, button in pairs(LangButtons) do
        SetColor(button, Language == lang and ColorTab or ColorOff)
    end
end

local function StopMode()
    ActiveMode = nil

    local _, humanoid, root = GetCharacter()

    if humanoid then
        humanoid:Move(Vector3.zero)
        humanoid.AutoRotate = true
    end

    if root then
        root.AssemblyLinearVelocity = Vector3.zero
    end

    UpdateModeButtons()
    SetStatus("status_idle")
end

local function StopEggMode()
    EggMode = nil

    local _, humanoid, root = GetCharacter()

    if humanoid then
        humanoid:Move(Vector3.zero)
        humanoid.AutoRotate = true
    end

    if root then
        root.AssemblyLinearVelocity = Vector3.zero
    end

    UpdateEggControls()
    SetStatus("status_idle")
end

local function StartMode(mode)
    if ActiveMode == mode then
        StopMode()
        return
    end

    StopEggMode()
    StopMode()

    ActiveMode = mode
    UpdateModeButtons()

    task.spawn(function()
        while ActiveMode == mode do
            local targets = GetTargets()

            if next(SelectedNames) == nil then
                SetStatus("status_no_targets")
                task.wait(0.5)

            elseif #targets == 0 then
                SetStatus("status_wait_spawn")
                task.wait(0.3)

            else
                local target = targets[1]
                SetStatus("status_target", target.Name)

                local reached = false

                if mode == "TP" then
                    reached = MoveTP(target)
                elseif mode == "Walk" then
                    reached = MoveWalk(target)
                elseif mode == "Fly" then
                    reached = MoveFly(target)
                end

                if reached and ActiveMode == mode then
                    SetStatus("status_follow", target.Name)
                    FollowTarget(target, mode)
                end
            end

            task.wait(0.05)
        end
    end)
end

local function StartEggMode(mode)
    if EggMode == mode then
        StopEggMode()
        return
    end

    if mode == "TP" and AutoEgg then
        SetStatus("status_no_tp_auto")
        return
    end

    StopMode()
    StopEggMode()

    EggMode = mode
    UpdateEggControls()

    task.spawn(function()
        while EggMode == mode do
            local eggs = GetSelectedEggs()

            if #eggs == 0 then
                SetStatus("status_no_eggs")
                task.wait(0.5)

            else
                local egg = eggs[1]

                SetStatus("status_egg", egg.Name)

                local reached = EggLeg(
                    function()
                        if egg.Parent == EggFolder then
                            return GetTargetPosition(egg)
                        end
                        return nil
                    end,
                    mode,
                    function()
                        return EggMode == mode and egg.Parent == EggFolder
                    end,
                    Settings.EggHoldTime
                )

                if reached and EggMode == mode then
                    local returnGoal

                    if UseCustomPoint and CustomPoint then
                        local point = CustomPoint

                        returnGoal = function()
                            return point
                        end
                    else
                        local zone = FindSaveZone()

                        if zone then
                            returnGoal = function()
                                return GetZoneGoal(zone)
                            end
                        end
                    end

                    if returnGoal then
                        SetStatus("status_return")

                        EggLeg(
                            returnGoal,
                            mode,
                            function()
                                return EggMode == mode
                            end,
                            0
                        )
                    else
                        SetStatus("status_no_zone")
                        task.wait(1)
                    end
                end
            end

            task.wait(0.05)
        end
    end)
end

local function Publish(data)
    if not RequestFunction then
        return false
    end

    data.f = MyId
    data.n = Player.Name
    data.d = Player.DisplayName

    local ok, response = pcall(RequestFunction, {
        Url = NtfyBase .. "/" .. ChatTopic,
        Method = "POST",
        Headers = {["Content-Type"] = "text/plain"},
        Body = HttpService:JSONEncode(data)
    })

    return ok and response and response.Success
end

local function GetThumb(userId)
    if ThumbCache[userId] == nil then
        ThumbCache[userId] = ""

        task.spawn(function()
            local ok, url = pcall(Players.GetUserThumbnailAsync, Players, userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)

            if ok and url then
                ThumbCache[userId] = url
            end
        end)
    end

    return ThumbCache[userId]
end

local function AddChat(peer, text, mine)
    Histories[peer] = Histories[peer] or {}
    table.insert(Histories[peer], {text = text, mine = mine})

    while #Histories[peer] > 100 do
        table.remove(Histories[peer], 1)
    end
end

local function RenderChat()
    if not ChatLog or not ChatPeer then
        return
    end

    for _, child in ipairs(ChatLog:GetChildren()) do
        if child:IsA("TextLabel") then
            child:Destroy()
        end
    end

    for _, msg in ipairs(Histories[ChatPeer] or {}) do
        local label = Create("TextLabel", {
            Size = UDim2.new(1, -10, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = msg.mine and ColorOn or ColorEggCard,
            TextColor3 = Color3.new(1, 1, 1),
            Text = msg.text,
            TextWrapped = true,
            TextXAlignment = msg.mine and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            ZIndex = 22
        }, ChatLog)

        Corner(label, 6)
    end
end

local function SendCurrent()
    if not ChatInput or not ChatPeer then
        return
    end

    local text = (ChatInput.Text:gsub("^%s+", ""):gsub("%s+$", ""))

    if text == "" then
        return
    end

    text = string.sub(text, 1, 200)
    ChatInput.Text = ""

    Publish({k = "chat", to = ChatPeer, x = text})
    AddChat(ChatPeer, text, true)
    RenderChat()
end

local function CloseChat()
    if ChatWin then
        ChatWin:Destroy()
    end

    ChatWin = nil
    ChatPeer = nil
    ChatLog = nil
    ChatInput = nil
end

local function MakeDraggable(window, header)
    local moving = false
    local startMouse
    local startPosition

    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            moving = true
            startMouse = input.Position
            startPosition = window.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if moving and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - startMouse

            window.Position = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            moving = false
        end
    end)
end

local function OpenChat(peer)
    CloseChat()

    ChatPeer = peer

    local info = Peers[peer] or {name = "?", d = "?"}
    local displayName = info.display or info.d or "?"
    local userName = info.name or info.n or "?"

    local window = Create("Frame", {
        Size = UDim2.fromOffset(260, 330),
        Position = UDim2.fromOffset(
            Main.AbsolutePosition.X + Main.AbsoluteSize.X + 10,
            Main.AbsolutePosition.Y
        ),
        BackgroundColor3 = Color3.fromRGB(25, 25, 34),
        BorderSizePixel = 0,
        ZIndex = 20
    }, Gui)

    Corner(window, 9)

    local chatHeader = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = ColorHeader,
        BorderSizePixel = 0,
        ZIndex = 21
    }, window)

    Corner(chatHeader, 9)

    local avatar = Create("ImageLabel", {
        Size = UDim2.fromOffset(28, 28),
        Position = UDim2.fromOffset(6, 4),
        BackgroundTransparency = 1,
        Image = GetThumb(peer),
        ZIndex = 22
    }, chatHeader)

    Corner(avatar, 14)

    Create("TextLabel", {
        Size = UDim2.new(1, -80, 1, 0),
        Position = UDim2.fromOffset(40, 0),
        BackgroundTransparency = 1,
        Text = displayName .. " (@" .. userName .. ")",
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 22
    }, chatHeader)

    local deleteButton = Create("TextButton", {
        Size = UDim2.fromOffset(30, 27),
        Position = UDim2.new(1, -34, 0, 4),
        Text = "X",
        TextColor3 = Color3.new(1, 1, 1),
        BackgroundColor3 = Color3.fromRGB(160, 45, 45),
        ZIndex = 22
    }, chatHeader)

    Corner(deleteButton, 5)

    ChatLog = Create("ScrollingFrame", {
        Size = UDim2.new(1, -12, 1, -94),
        Position = UDim2.fromOffset(6, 44),
        BackgroundColor3 = ColorPanel,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        CanvasSize = UDim2.fromOffset(0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ZIndex = 21
    }, window)

    Corner(ChatLog, 6)

    Create("UIListLayout", {
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, ChatLog)

    ChatInput = Create("TextBox", {
        Size = UDim2.new(1, -56, 0, 34),
        Position = UDim2.new(0, 6, 1, -42),
        BackgroundColor3 = Color3.fromRGB(43, 43, 56),
        TextColor3 = Color3.new(1, 1, 1),
        PlaceholderText = T("chat_placeholder"),
        PlaceholderColor3 = Color3.fromRGB(120, 120, 130),
        Text = "",
        Font = Enum.Font.Gotham,
        TextSize = 12,
        ClearTextOnFocus = false,
        ZIndex = 21
    }, window)

    Corner(ChatInput, 5)

    local sendButton = Create("TextButton", {
        Size = UDim2.fromOffset(40, 34),
        Position = UDim2.new(1, -46, 1, -42),
        Text = T("chat_send"),
        BackgroundColor3 = ColorTab,
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        ZIndex = 21
    }, window)

    Corner(sendButton, 5)

    sendButton.MouseButton1Click:Connect(SendCurrent)

    ChatInput.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            SendCurrent()
        end
    end)

    deleteButton.MouseButton1Click:Connect(CloseChat)

    MakeDraggable(window, chatHeader)

    ChatWin = window
    RenderChat()
end

local function HandleData(data)
    if type(data) ~= "table" or data.f == nil or data.f == MyId then
        return
    end

    local peer = data.f

    if data.k == "hello" then
        Peers[peer] = {name = data.n, display = data.d, seen = os.clock()}

    elseif data.k == "chat" and data.to == MyId then
        Peers[peer] = Peers[peer] or {name = data.n, display = data.d, seen = os.clock()}
        Peers[peer].seen = os.clock()

        AddChat(peer, tostring(data.x), false)

        if ChatPeer == peer then
            RenderChat()
        end
    end
end

local function PollChat()
    if not RequestFunction then
        return
    end

    local ok, response = pcall(RequestFunction, {
        Url = NtfyBase .. "/" .. ChatTopic .. "/json?poll=1&since=" .. tostring(Since),
        Method = "GET"
    })

    if not ok or not response or not response.Success or not response.Body then
        return
    end

    for line in string.gmatch(response.Body, "[^\n]+") do
        local okEvent, event = pcall(HttpService.JSONDecode, HttpService, line)

        if okEvent and type(event) == "table" and event.event == "message" and event.id and not Seen[event.id] then
            Seen[event.id] = true

            local okData, data = pcall(HttpService.JSONDecode, HttpService, event.message or "")

            if okData then
                HandleData(data)
            end
        end
    end

    Since = os.time() - 5
end

local function RefreshUsers()
    for _, child in ipairs(UserList:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    local now = os.clock()
    local online = {}

    for id, info in pairs(Peers) do
        if now - info.seen < 25 then
            table.insert(online, {id = id, info = info})
        else
            Peers[id] = nil
        end
    end

    table.sort(online, function(a, b)
        return (a.info.name or "") < (b.info.name or "")
    end)

    OnlineLabel.Text = T("chat_online") .. ": " .. #online

    if #online == 0 then
        Create("TextLabel", {
            Size = UDim2.new(1, -8, 0, 36),
            BackgroundTransparency = 1,
            Text = T("chat_no_users"),
            TextColor3 = Color3.fromRGB(160, 160, 170),
            Font = Enum.Font.Gotham,
            TextSize = 12
        }, UserList)
    end

    for _, entry in ipairs(online) do
        local row = Create("Frame", {
            Size = UDim2.new(1, -8, 0, 40),
            BackgroundColor3 = ColorEggCard,
            BorderSizePixel = 0
        }, UserList)

        Corner(row, 6)

        local avatar = Create("ImageLabel", {
            Size = UDim2.fromOffset(32, 32),
            Position = UDim2.fromOffset(4, 4),
            BackgroundTransparency = 1,
            Image = GetThumb(entry.id)
        }, row)

        Corner(avatar, 16)

        local nameButton = Create("TextButton", {
            Size = UDim2.new(1, -46, 1, 0),
            Position = UDim2.fromOffset(42, 0),
            BackgroundTransparency = 1,
            Text = (entry.info.display or "?") .. "  (@" .. (entry.info.name or "?") .. ")",
            TextColor3 = Color3.new(1, 1, 1),
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd
        }, row)

        local id = entry.id

        nameButton.MouseButton1Click:Connect(function()
            OpenChat(id)
        end)
    end

    UserList.CanvasSize = UDim2.fromOffset(0, #online * 44)
end

local function UpdateAdminView()
    LockFrame.Visible = not AdminUnlocked
    PanelFrame.Visible = AdminUnlocked
end

local function RefreshTargets()
    for _, child in ipairs(List:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    local counts = {}
    local names = {}

    for _, target in ipairs(Monsters:GetChildren()) do
        if target:IsA("Model") or target:IsA("BasePart") then
            counts[target.Name] = (counts[target.Name] or 0) + 1
            names[target.Name] = true
        end
    end

    for name in pairs(SelectedNames) do
        names[name] = true
    end

    local sorted = {}

    for name in pairs(names) do
        table.insert(sorted, name)
    end

    table.sort(sorted)

    for _, name in ipairs(sorted) do
        local count = counts[name] or 0
        local selected = SelectedNames[name] == true

        local button = Create("TextButton", {
            Size = UDim2.new(1, -8, 0, 29),
            BackgroundColor3 = selected and ColorOn or Color3.fromRGB(48, 48, 60),
            TextColor3 = Color3.new(1, 1, 1),
            Text = name .. "  " .. count,
            Font = Enum.Font.Gotham,
            TextSize = 12
        }, List)

        Corner(button, 4)

        button.MouseButton1Click:Connect(function()
            if SelectedNames[name] then
                SelectedNames[name] = nil
            else
                SelectedNames[name] = true
            end

            RefreshTargets()
        end)
    end

    List.CanvasSize = UDim2.fromOffset(0, #sorted * 33)
end

local function ToggleList()
    if List.Visible then
        local tween = Tween(List, 0.2, {Size = UDim2.new(1, 0, 0, 0)})

        tween.Completed:Connect(function()
            if List.Size.Y.Offset == 0 then
                List.Visible = false
            end
        end)
    else
        RefreshTargets()

        List.Size = UDim2.new(1, 0, 0, 0)
        List.Visible = true
        Tween(List, 0.2, {Size = UDim2.new(1, 0, 0, 155)})
    end
end

local function ShowPage(page)
    if page.Visible then
        return
    end

    page.Position = UDim2.fromOffset(18, 0)
    page.Visible = true
    Tween(page, 0.25, {Position = UDim2.fromOffset(0, 0)})
end

local function SwitchTab(tab)
    local pages = {
        Targets = TargetPage,
        Settings = SettingsPage,
        Eggs = EggPage,
        Messages = MessagePage,
        Admin = AdminPage
    }

    for name, page in pairs(pages) do
        if name ~= tab then
            page.Visible = false
        end
    end

    ShowPage(pages[tab])

    SetColor(TargetTab, tab == "Targets" and ColorTab or ColorOff)
    SetColor(SettingsTab, tab == "Settings" and ColorTab or ColorOff)
    SetColor(EggTab, tab == "Eggs" and ColorTab or ColorOff)
    SetColor(MessageTab, tab == "Messages" and ColorTab or ColorOff)
    SetColor(AdminTab, tab == "Admin" and ColorTab or ColorOff)

    if tab == "Admin" then
        UpdateAdminView()
    end

    if tab == "Messages" then
        RefreshUsers()
    end
end

local function CreateViewport(parent, model, size)
    local viewport = Create("ViewportFrame", {
        Size = size,
        BackgroundColor3 = Color3.fromRGB(27, 27, 37),
        BorderSizePixel = 0,
        Ambient = Color3.fromRGB(180, 180, 180),
        LightColor = Color3.new(1, 1, 1)
    }, parent)

    local world = Instance.new("WorldModel")
    world.Parent = viewport

    local clone = model:Clone()
    clone.Parent = world

    for _, object in ipairs(clone:GetDescendants()) do
        if object:IsA("Script") or object:IsA("LocalScript") then
            object:Destroy()
        elseif object:IsA("BasePart") then
            object.Anchored = true
            object.CanCollide = false
        elseif EffectClasses[object.ClassName] then
            object.Enabled = true
        end
    end

    local camera = Instance.new("Camera")
    camera.Parent = viewport
    viewport.CurrentCamera = camera

    local cf, objectSize = clone:GetBoundingBox()
    clone:PivotTo(clone:GetPivot() - cf.Position)

    local maxSize = math.max(
        objectSize.X,
        objectSize.Y,
        objectSize.Z,
        1
    )

    local distance = maxSize * 2.2
    local angleX = 0
    local angleY = 0
    local draggingPreview = false
    local previousMouse

    local function UpdateCamera()
        local rotation = CFrame.Angles(angleX, angleY, 0)

        camera.CFrame = CFrame.new(
            rotation * Vector3.new(0, 0, distance)
        ) * rotation
    end

    UpdateCamera()

    viewport.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingPreview = true
            previousMouse = input.Position
        end
    end)

    viewport.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingPreview = false
        end
    end)

    viewport.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
            and draggingPreview then

            local delta = input.Position - previousMouse
            previousMouse = input.Position

            angleY += delta.X * 0.01
            angleX = math.clamp(
                angleX + delta.Y * 0.01,
                -1.5,
                1.5
            )

            UpdateCamera()
        end

        if input.UserInputType == Enum.UserInputType.MouseWheel then
            distance = math.clamp(
                distance - input.Position.Z * maxSize * 0.15,
                maxSize * 0.7,
                maxSize * 8
            )

            UpdateCamera()
        end
    end)

    return viewport
end

local function CreateEggWindow(model)
    if EggWindows[model] then
        EggWindows[model]:Destroy()
        EggWindows[model] = nil
        return
    end

    local window = Create("Frame", {
        Size = UDim2.fromOffset(340, 310),
        Position = UDim2.new(0.5, -170, 0.5, -155),
        BackgroundColor3 = Color3.fromRGB(25, 25, 34),
        BorderSizePixel = 0,
        ZIndex = 20
    }, Gui)

    Corner(window, 9)

    local header = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 35),
        BackgroundColor3 = ColorHeader,
        BorderSizePixel = 0,
        ZIndex = 21
    }, window)

    Create("TextLabel", {
        Size = UDim2.new(1, -45, 1, 0),
        Position = UDim2.fromOffset(10, 0),
        BackgroundTransparency = 1,
        Text = model.Name,
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 22
    }, header)

    local close = Create("TextButton", {
        Size = UDim2.fromOffset(30, 27),
        Position = UDim2.new(1, -34, 0, 4),
        Text = "X",
        TextColor3 = Color3.new(1, 1, 1),
        BackgroundColor3 = Color3.fromRGB(160, 45, 45),
        ZIndex = 22
    }, header)

    local viewport = CreateViewport(
        window,
        model,
        UDim2.new(1, -16, 1, -50)
    )

    viewport.Position = UDim2.fromOffset(8, 42)
    viewport.ZIndex = 21

    MakeDraggable(window, header)

    close.MouseButton1Click:Connect(function()
        EggWindows[model] = nil
        window:Destroy()
    end)

    EggWindows[model] = window
end

local function CreateHoverPreview(model, card)
    if HoverWindows[model] then
        return
    end

    local popup = Create("Frame", {
        Size = UDim2.fromOffset(220, 220),
        BackgroundColor3 = Color3.fromRGB(25, 25, 35),
        BorderSizePixel = 0,
        ZIndex = 30
    }, Gui)

    Corner(popup, 8)

    local viewport = CreateViewport(
        popup,
        model,
        UDim2.new(1, -10, 1, -10)
    )

    viewport.Position = UDim2.fromOffset(5, 5)
    viewport.ZIndex = 31

    HoverWindows[model] = popup

    HoverConnections[model] = RunService.RenderStepped:Connect(function()
        if not popup.Parent or not card.Parent then
            return
        end

        local mouse = UserInputService:GetMouseLocation()

        popup.Position = UDim2.fromOffset(
            mouse.X + 18,
            mouse.Y + 18
        )
    end)
end

local function RemoveHoverPreview(model)
    if HoverConnections[model] then
        HoverConnections[model]:Disconnect()
        HoverConnections[model] = nil
    end

    if HoverWindows[model] then
        HoverWindows[model]:Destroy()
        HoverWindows[model] = nil
    end
end

local function UpdateEggCard(model)
    local card = EggCards[model]

    if card and card.Parent then
        SetColor(card, SelectedEggs[model] and ColorOn or ColorEggCard)
    end
end

local EggScroll
local EggLayout

local function RefreshEggs()
    for _, child in ipairs(EggScroll:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    local eggs = {}

    for _, model in ipairs(EggFolder:GetChildren()) do
        if model:IsA("Model") then
            table.insert(eggs, model)
        end
    end

    table.sort(eggs, function(a, b)
        return a.Name < b.Name
    end)

    for _, model in ipairs(eggs) do
        local card = Create("Frame", {
            BackgroundColor3 = SelectedEggs[model] and ColorOn or ColorEggCard,
            BorderSizePixel = 0
        }, EggScroll)

        Corner(card, 7)
        EggCards[model] = card

        local viewport = CreateViewport(
            card,
            model,
            UDim2.new(1, -8, 0, 105)
        )

        viewport.Position = UDim2.fromOffset(4, 4)

        local nameButton = Create("TextButton", {
            Size = UDim2.new(1, -36, 0, 30),
            Position = UDim2.fromOffset(5, 110),
            BackgroundTransparency = 1,
            Text = model.Name,
            TextColor3 = Color3.new(1, 1, 1),
            Font = Enum.Font.Gotham,
            TextSize = 10,
            TextTruncate = Enum.TextTruncate.AtEnd
        }, card)

        nameButton.MouseButton1Click:Connect(function()
            if SelectedEggs[model] then
                SelectedEggs[model] = nil
            else
                SelectedEggs[model] = true
            end

            UpdateEggCard(model)
        end)

        local open = Create("TextButton", {
            Size = UDim2.fromOffset(25, 25),
            Position = UDim2.new(1, -29, 1, -29),
            Text = "+",
            BackgroundColor3 = ColorTab,
            TextColor3 = Color3.new(1, 1, 1),
            Font = Enum.Font.GothamBold,
            TextSize = 16
        }, card)

        Corner(open, 5)

        open.MouseButton1Click:Connect(function()
            if model.Parent then
                CreateEggWindow(model)
            end
        end)

        card.MouseEnter:Connect(function()
            if model.Parent then
                CreateHoverPreview(model, card)
            end
        end)

        card.MouseLeave:Connect(function()
            RemoveHoverPreview(model)
        end)
    end

    EggScroll.CanvasSize = UDim2.fromOffset(
        0,
        EggLayout.AbsoluteContentSize.Y + 10
    )
end

EggScroll = Create("ScrollingFrame", {
    Size = UDim2.new(1, 0, 1, -92),
    Position = UDim2.fromOffset(0, 92),
    BackgroundColor3 = ColorPanel,
    BorderSizePixel = 0,
    ScrollBarThickness = 5,
    CanvasSize = UDim2.fromOffset(0, 0)
}, EggPage)

EggLayout = Create("UIGridLayout", {
    CellSize = UDim2.fromOffset(125, 145),
    CellPadding = UDim2.fromOffset(8, 8),
    SortOrder = Enum.SortOrder.Name
}, EggScroll)

EggLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    EggScroll.CanvasSize = UDim2.fromOffset(
        0,
        EggLayout.AbsoluteContentSize.Y + 10
    )
end)

local function SetAutoEgg(value)
    AutoEgg = value

    if AutoEgg then
        for _, model in ipairs(EggFolder:GetChildren()) do
            if model:IsA("Model") then
                SelectedEggs[model] = true
            end
        end

        if EggMode == "TP" then
            StopEggMode()
            StartEggMode("Walk")
        end
    end

    UpdateEggControls()

    if EggPage.Visible then
        RefreshEggs()
    end
end

local function SetLanguage(lang)
    Language = lang

    for _, item in ipairs(Localized) do
        item.Object.Text = T(item.Key)
    end

    UpdateModeButtons()
    UpdateEggControls()
    UpdateLanguageButtons()
    SetStatus(StatusKey, StatusExtra)

    if List.Visible then
        RefreshTargets()
    end

    if ChatInput then
        ChatInput.PlaceholderText = T("chat_placeholder")
    end
end

local NoclipApplied = false

local NoclipConnection = RunService.Stepped:Connect(function()
    local character = Player.Character

    if not character then
        return
    end

    local active = ActiveMode ~= nil or EggMode ~= nil

    if active then
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end

        NoclipApplied = true

    elseif NoclipApplied then
        NoclipApplied = false

        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = part.Name ~= "HumanoidRootPart"
            end
        end
    end
end)

for name, button in pairs(ModeButtons) do
    button.MouseButton1Click:Connect(function()
        StartMode(name)
    end)
end

for name, button in pairs(EggModeButtons) do
    button.MouseButton1Click:Connect(function()
        StartEggMode(name)
    end)
end

AutoEggButton.MouseButton1Click:Connect(function()
    SetAutoEgg(not AutoEgg)
end)

SaveHereButton.MouseButton1Click:Connect(function()
    local _, _, root = GetCharacter()

    if root then
        CustomPoint = root.Position
        UseCustomPoint = true
        UpdateEggControls()
        SetStatus("status_point_set")
    end
end)

SaveZoneButton.MouseButton1Click:Connect(function()
    UseCustomPoint = false
    UpdateEggControls()
end)

AdminEnter.MouseButton1Click:Connect(function()
    if AdminBox.Text == AdminCode then
        AdminUnlocked = true
        AdminMsg.Text = ""
        AdminBox.Text = ""
    else
        AdminMsg.Text = T("admin_wrong")
    end

    UpdateAdminView()
end)

LangButtons.EN.MouseButton1Click:Connect(function()
    SetLanguage("EN")
end)

LangButtons.RU.MouseButton1Click:Connect(function()
    SetLanguage("RU")
end)

TargetTab.MouseButton1Click:Connect(function()
    SwitchTab("Targets")
end)

SettingsTab.MouseButton1Click:Connect(function()
    SwitchTab("Settings")
end)

EggTab.MouseButton1Click:Connect(function()
    SwitchTab("Eggs")
    RefreshEggs()
end)

MessageTab.MouseButton1Click:Connect(function()
    SwitchTab("Messages")
end)

AdminTab.MouseButton1Click:Connect(function()
    SwitchTab("Admin")
end)

TargetButton.MouseButton1Click:Connect(function()
    ToggleList()
end)

Monsters.ChildAdded:Connect(function()
    if List.Visible then
        RefreshTargets()
    end
end)

Monsters.ChildRemoved:Connect(function()
    if List.Visible then
        RefreshTargets()
    end
end)

EggFolder.ChildAdded:Connect(function(model)
    if AutoEgg and model:IsA("Model") then
        SelectedEggs[model] = true
    end

    if EggPage.Visible then
        RefreshEggs()
    end
end)

EggFolder.ChildRemoved:Connect(function(model)
    SelectedEggs[model] = nil
    RemoveHoverPreview(model)

    if EggWindows[model] then
        EggWindows[model]:Destroy()
        EggWindows[model] = nil
    end

    if EggPage.Visible then
        RefreshEggs()
    end
end)

Minimize.MouseButton1Click:Connect(function()
    Minimized = not Minimized

    Tabs.Visible = not Minimized
    Content.Visible = not Minimized

    Main:TweenSize(
        Minimized and UDim2.fromOffset(550, 40)
            or UDim2.fromOffset(550, 390),
        Enum.EasingDirection.Out,
        Enum.EasingStyle.Quad,
        0.2,
        true
    )
end)

Close.MouseButton1Click:Connect(function()
    StopMode()
    StopEggMode()
    CloseChat()

    for _, connection in pairs(HoverConnections) do
        connection:Disconnect()
    end

    NoclipConnection:Disconnect()
    Gui:Destroy()
end)

task.spawn(function()
    while Gui.Parent do
        Publish({k = "hello"})
        task.wait(8)
    end
end)

task.spawn(function()
    while Gui.Parent do
        PollChat()
        task.wait(2)
    end
end)

task.spawn(function()
    while Gui.Parent do
        if MessagePage.Visible then
            RefreshUsers()
        end

        task.wait(2)
    end
end)

local MainScale = Instance.new("UIScale")
MainScale.Scale = 0.85
MainScale.Parent = Main
Tween(MainScale, 0.35, {Scale = 1})

UpdateModeButtons()
UpdateEggControls()
UpdateLanguageButtons()
SetStatus("status_idle")
UpdateAdminView()
SwitchTab("Targets")
RefreshTargets()
