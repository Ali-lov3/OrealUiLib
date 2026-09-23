local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Oreal = {
    Flags = {},
    Items = {},
    Tabs = {},
    Sections = {},
    ConfigFolder = "Oreal",
    Window = nil
}

local function New(class, properties, parent)
    local object = Instance.new(class)
    for property, value in pairs(properties or {}) do
        object[property] = value
    end
    object.Parent = parent
    return object
end

local function Corner(object, radius)
    New("UICorner", {
        CornerRadius = UDim.new(0, radius or 4)
    }, object)
end

local function Stroke(object, color, thickness, transparency)
    return New("UIStroke", {
        Color = color or Color3.fromRGB(48, 48, 48),
        Thickness = thickness or 1,
        Transparency = transparency or 0
    }, object)
end

local function Tween(object, time, properties)
    TweenService:Create(object, TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), properties):Play()
end

local function ProtectGui(gui)
    if gethui then
        gui.Parent = gethui()
    elseif syn and syn.protect_gui then
        syn.protect_gui(gui)
        gui.Parent = game:GetService("CoreGui")
    else
        gui.Parent = PlayerGui
    end
end

local function MakeDraggable(frame, handle)
    local dragging = false
    local dragStart
    local startPosition

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPosition = frame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then
            return
        end

        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
        end
    end)
end

local function ResolveIcon(icon)
    if not icon then
        return nil
    end

    if type(icon) == "number" then
        return "rbxassetid://" .. tostring(icon)
    end

    if type(icon) == "string" then
        if icon:match("^rbxassetid://") then
            return icon
        end

        if icon:match("^%d+$") then
            return "rbxassetid://" .. icon
        end

        local icons = rawget(getfenv and getfenv() or _G, "Lucide")

        if type(icons) == "table" then
            local name = string.lower(icon)

            for _, set in ipairs({
                icons["48px"],
                icons["256px"],
                icons
            }) do
                if type(set) == "table" then
                    local data = set[name]

                    if type(data) == "table" and data[1] then
                        return "rbxassetid://" .. tostring(data[1])
                    end
                end
            end
        end
    end

    return nil
end

local function ApplyIcon(object, icon)
    local image = ResolveIcon(icon)

    if image then
        object.Image = image
        object.ImageColor3 = Color3.fromRGB(220, 220, 220)
    end
end

local function GetPath(folder, name)
    return Oreal.ConfigFolder .. "/" .. name .. ".json"
end

local function EnsureConfigFolder()
    if not isfolder or not makefolder then
        return
    end

    if not isfolder(Oreal.ConfigFolder) then
        makefolder(Oreal.ConfigFolder)
    end
end

local function GetConfigs()
    EnsureConfigFolder()

    if not listfiles then
        return {}
    end

    local configs = {}

    for _, file in ipairs(listfiles(Oreal.ConfigFolder)) do
        local name = file:match("([^/\\]+)%.json$")

        if name then
            table.insert(configs, name)
        end
    end

    table.sort(configs)

    return configs
end

local function Serialize()
    local data = {}

    for flag, item in pairs(Oreal.Items) do
        if item.GetValue then
            data[flag] = item:GetValue()
        end
    end

    return data
end

local function ApplyData(data)
    if type(data) ~= "table" then
        return
    end

    for flag, value in pairs(data) do
        local item = Oreal.Items[flag]

        if item and item.SetValue then
            pcall(function()
                item:SetValue(value)
            end)
        end
    end
end

local function GetAutoloadPath()
    return Oreal.ConfigFolder .. "/autoload.txt"
end

local function GetAutoload()
    if not isfile or not isfile(GetAutoloadPath()) then
        return nil
    end

    local success, result = pcall(readfile, GetAutoloadPath())

    if success and result ~= "" then
        return result
    end

    return nil
end

local function SetAutoload(name)
    EnsureConfigFolder()

    if writefile then
        writefile(GetAutoloadPath(), name or "")
    end
end

local function SaveConfig(name, overwrite)
    if not name or name == "" then
        return false
    end

    EnsureConfigFolder()

    if not writefile or not HttpService then
        return false
    end

    local path = GetPath(Oreal.ConfigFolder, name)

    if isfile and isfile(path) and not overwrite then
        return false
    end

    local success = pcall(function()
        writefile(path, HttpService:JSONEncode(Serialize()))
    end)

    return success
end

local function LoadConfig(name)
    if not name or name == "" or not isfile or not readfile then
        return false
    end

    local path = GetPath(Oreal.ConfigFolder, name)

    if not isfile(path) then
        return false
    end

    local success, data = pcall(function()
        return HttpService:JSONDecode(readfile(path))
    end)

    if not success then
        return false
    end

    ApplyData(data)

    return true
end

local function DeleteConfig(name)
    if not name or name == "" or not isfile or not delfile then
        return false
    end

    local path = GetPath(Oreal.ConfigFolder, name)

    if not isfile(path) then
        return false
    end

    local success = pcall(delfile, path)
    return success
end

function Oreal:Notify(title, description)
    if not self.NotifyHolder then
        return
    end

    local card = New("Frame", {
        Size = UDim2.new(0, 250, 0, 55),
        BackgroundColor3 = Color3.fromRGB(20, 20, 20),
        BorderSizePixel = 0
    }, self.NotifyHolder)

    Corner(card, 5)
    Stroke(card, Color3.fromRGB(45, 45, 45), 1)

    New("Frame", {
        Size = UDim2.new(0, 2, 1, 0),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0
    }, card)

    New("TextLabel", {
        Size = UDim2.new(1, -20, 0, 18),
        Position = UDim2.new(0, 12, 0, 7),
        BackgroundTransparency = 1,
        Text = title or "Oreal",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left
    }, card)

    New("TextLabel", {
        Size = UDim2.new(1, -20, 0, 20),
        Position = UDim2.new(0, 12, 0, 26),
        BackgroundTransparency = 1,
        Text = description or "",
        TextColor3 = Color3.fromRGB(145, 145, 145),
        TextSize = 9,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left
    }, card)

    card.Position = UDim2.new(1, 20, 0, 0)

    Tween(card, 0.25, {
        Position = UDim2.new(0, 0, 0, 0)
    })

    task.delay(3, function()
        if card.Parent then
            Tween(card, 0.25, {
                Position = UDim2.new(1, 20, 0, 0)
            })

            task.delay(0.3, function()
                card:Destroy()
            end)
        end
    end)
end

function Oreal:CreateWindow(settings)
    settings = settings or {}

    self.ConfigFolder = settings.ConfigFolder or "Oreal"

    local gui = New("ScreenGui", {
        Name = "Oreal",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    })

    ProtectGui(gui)

    local holder = New("Frame", {
        Name = "Holder",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1
    }, gui)

    local notifyHolder = New("Frame", {
        Name = "Notifications",
        Size = UDim2.new(0, 250, 0, 300),
        Position = UDim2.new(1, -265, 0, 15),
        BackgroundTransparency = 1
    }, holder)

    local notifyLayout = New("UIListLayout", {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, notifyHolder)

    self.NotifyHolder = notifyHolder

    local window = New("Frame", {
        Name = "Window",
        Size = UDim2.new(0, 700, 0, 470),
        Position = UDim2.new(0.5, -350, 0.5, -235),
        BackgroundColor3 = Color3.fromRGB(15, 15, 15),
        BorderSizePixel = 0,
        ClipsDescendants = true
    }, holder)

    Corner(window, 7)
    Stroke(window, Color3.fromRGB(45, 45, 45), 1)

    local top = New("Frame", {
        Name = "Top",
        Size = UDim2.new(1, 0, 0, 48),
        BackgroundColor3 = Color3.fromRGB(20, 20, 20),
        BorderSizePixel = 0
    }, window)

    local logo

    if settings.Logo then
        logo = New("ImageLabel", {
            Size = UDim2.new(0, 25, 0, 25),
            Position = UDim2.new(0, 15, 0.5, -12),
            BackgroundTransparency = 1
        }, top)

        logo.Image = "rbxassetid://" .. tostring(settings.Logo)
    end

    local titleX = settings.Logo and 50 or 15

    New("TextLabel", {
        Size = UDim2.new(0, 250, 0, 20),
        Position = UDim2.new(0, titleX, 0, 7),
        BackgroundTransparency = 1,
        Text = settings.Title or "Oreal",
        TextColor3 = Color3.fromRGB(245, 245, 245),
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left
    }, top)

    New("TextLabel", {
        Size = UDim2.new(0, 250, 0, 14),
        Position = UDim2.new(0, titleX, 0, 27),
        BackgroundTransparency = 1,
        Text = settings.Anonymous and "Anonymous" or LocalPlayer.DisplayName,
        TextColor3 = Color3.fromRGB(110, 110, 110),
        TextSize = 9,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left
    }, top)

    local avatar

    if settings.Anonymous then
        avatar = New("TextLabel", {
            Size = UDim2.new(0, 30, 0, 30),
            Position = UDim2.new(1, -45, 0.5, -15),
            BackgroundColor3 = Color3.fromRGB(30, 30, 30),
            Text = "?",
            TextColor3 = Color3.fromRGB(180, 180, 180),
            TextSize = 13,
            Font = Enum.Font.GothamBold
        }, top)
        Corner(avatar, 5)
    else
        avatar = New("ImageLabel", {
            Size = UDim2.new(0, 30, 0, 30),
            Position = UDim2.new(1, -45, 0.5, -15),
            BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        }, top)

        Corner(avatar, 5)

        pcall(function()
            avatar.Image = Players:GetUserThumbnailAsync(
                LocalPlayer.UserId,
                Enum.ThumbnailType.HeadShot,
                Enum.ThumbnailSize.Size100x100
            )
        end)
    end

    local tabBar = New("Frame", {
        Name = "Tabs",
        Size = UDim2.new(0, 145, 1, -48),
        Position = UDim2.new(0, 0, 0, 48),
        BackgroundColor3 = Color3.fromRGB(18, 18, 18),
        BorderSizePixel = 0
    }, window)

    local tabLayout = New("UIListLayout", {
        Padding = UDim.new(0, 3),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, tabBar)

    New("UIPadding", {
        PaddingTop = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8)
    }, tabBar)

    local content = New("Frame", {
        Name = "Content",
        Size = UDim2.new(1, -145, 1, -48),
        Position = UDim2.new(0, 145, 0, 48),
        BackgroundColor3 = Color3.fromRGB(13, 13, 13),
        BorderSizePixel = 0
    }, window)

    MakeDraggable(window, top)

    self.Window = window
    self.TabBar = tabBar
    self.Content = content
    self.Tabs = {}

    local mobileScale = New("UIScale", {
        Scale = 1
    }, window)

    local function updateScale()
        local camera = workspace.CurrentCamera

        if not camera then
            return
        end

        local width = camera.ViewportSize.X

        if width < 650 then
            mobileScale.Scale = math.clamp(width / 700, 0.72, 0.95)
        else
            mobileScale.Scale = 1
        end
    end

    updateScale()

    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)

    return self
end

function Oreal:CreateTab(name, icon)
    local tabButton = New("TextButton", {
        Name = name,
        Size = UDim2.new(1, 0, 0, 35),
        BackgroundColor3 = Color3.fromRGB(18, 18, 18),
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false
    }, self.TabBar)

    Corner(tabButton, 4)

    local iconImage

    if icon then
        iconImage = New("ImageLabel", {
            Size = UDim2.new(0, 15, 0, 15),
            Position = UDim2.new(0, 10, 0.5, -7),
            BackgroundTransparency = 1
        }, tabButton)

        ApplyIcon(iconImage, icon)
    end

    local label = New("TextLabel", {
        Size = UDim2.new(1, -35, 1, 0),
        Position = UDim2.new(0, icon and 32 or 10, 0, 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = Color3.fromRGB(145, 145, 145),
        TextSize = 10,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left
    }, tabButton)

    local page = New("Frame", {
        Name = name .. "Page",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Visible = false
    }, self.Content)

    local left = New("Frame", {
        Name = "Left",
        Size = UDim2.new(0.5, -10, 1, -20),
        Position = UDim2.new(0, 10, 0, 10),
        BackgroundTransparency = 1
    }, page)

    local right = New("Frame", {
        Name = "Right",
        Size = UDim2.new(0.5, -10, 1, -20),
        Position = UDim2.new(0.5, 0, 0, 10),
        BackgroundTransparency = 1
    }, page)

    local tab = {
        Name = name,
        Button = tabButton,
        Page = page,
        Left = left,
        Right = right
    }

    function tab:CreateSection(sectionName, side)
        side = string.lower(side or "Left")

        local parent = side == "right" and self.Right or self.Left

        local section = New("Frame", {
            Name = sectionName,
            Size = UDim2.new(1, 0, 0, 40),
            BackgroundColor3 = Color3.fromRGB(19, 19, 19),
            BorderSizePixel = 0
        }, parent)

        Corner(section, 5)
        Stroke(section, Color3.fromRGB(38, 38, 38), 1)

        local header = New("Frame", {
            Size = UDim2.new(1, 0, 0, 35),
            BackgroundColor3 = Color3.fromRGB(24, 24, 24),
            BorderSizePixel = 0
        }, section)

        Corner(header, 5)

        New("TextLabel", {
            Size = UDim2.new(1, -15, 1, 0),
            Position = UDim2.new(0, 10, 0, 0),
            BackgroundTransparency = 1,
            Text = sectionName,
            TextColor3 = Color3.fromRGB(225, 225, 225),
            TextSize = 10,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left
        }, header)

        local container = New("Frame", {
            Size = UDim2.new(1, -10, 0, 0),
            Position = UDim2.new(0, 5, 0, 40),
            BackgroundTransparency = 1
        }, section)

        local layout = New("UIListLayout", {
            Padding = UDim.new(0, 2),
            SortOrder = Enum.SortOrder.LayoutOrder
        }, container)

        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            container.Size = UDim2.new(1, -10, 0, layout.AbsoluteContentSize.Y)
            section.Size = UDim2.new(1, 0, 0, layout.AbsoluteContentSize.Y + 45)
        end)

        local sectionObject = {}

        function sectionObject:AddLabel(text)
            local item = New("TextLabel", {
                Size = UDim2.new(1, 0, 0, 25),
                BackgroundColor3 = Color3.fromRGB(24, 24, 24),
                BorderSizePixel = 0,
                Text = text,
                TextColor3 = Color3.fromRGB(130, 130, 130),
                TextSize = 9,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left
            }, container)

            Corner(item, 3)
            table.insert(Oreal.Items, item)

            return item
        end

        function sectionObject:AddButton(options)
            options = type(options) == "string" and {Name = options} or options

            local button = New("TextButton", {
                Size = UDim2.new(1, 0, 0, 30),
                BackgroundColor3 = Color3.fromRGB(27, 27, 27),
                BorderSizePixel = 0,
                Text = options.Name or "Button",
                TextColor3 = Color3.fromRGB(220, 220, 220),
                TextSize = 9,
                Font = Enum.Font.GothamMedium,
                AutoButtonColor = false
            }, container)

            Corner(button, 3)

            button.MouseEnter:Connect(function()
                Tween(button, 0.15, {
                    BackgroundColor3 = Color3.fromRGB(34, 34, 34)
                })
            end)

            button.MouseLeave:Connect(function()
                Tween(button, 0.15, {
                    BackgroundColor3 = Color3.fromRGB(27, 27, 27)
                })
            end)

            button.MouseButton1Click:Connect(function()
                if options.Callback then
                    options.Callback()
                end
            end)

            return button
        end

        function sectionObject:AddToggle(options)
            local flag = options.Flag or options.Name
            local value = options.Default or false

            local button = New("TextButton", {
                Size = UDim2.new(1, 0, 0, 32),
                BackgroundColor3 = Color3.fromRGB(25, 25, 25),
                BorderSizePixel = 0,
                Text = "",
                AutoButtonColor = false
            }, container)

            Corner(button, 3)

            local label = New("TextLabel", {
                Size = UDim2.new(1, -60, 1, 0),
                Position = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1,
                Text = options.Name or flag,
                TextColor3 = Color3.fromRGB(205, 205, 205),
                TextSize = 9,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left
            }, button)

            local switch = New("Frame", {
                Size = UDim2.new(0, 34, 0, 18),
                Position = UDim2.new(1, -44, 0.5, -9),
                BackgroundColor3 = Color3.fromRGB(45, 45, 45),
                BorderSizePixel = 0
            }, button)

            Corner(switch, 9)

            local knob = New("Frame", {
                Size = UDim2.new(0, 14, 0, 14),
                Position = UDim2.new(0, 2, 0.5, -7),
                BackgroundColor3 = Color3.fromRGB(150, 150, 150),
                BorderSizePixel = 0
            }, switch)

            Corner(knob, 7)

            local function update()
                Tween(switch, 0.15, {
                    BackgroundColor3 = value and Color3.fromRGB(230, 230, 230) or Color3.fromRGB(45, 45, 45)
                })

                Tween(knob, 0.15, {
                    Position = value and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7),
                    BackgroundColor3 = value and Color3.fromRGB(20, 20, 20) or Color3.fromRGB(150, 150, 150)
                })

                if options.Callback then
                    options.Callback(value)
                end
            end

            button.MouseButton1Click:Connect(function()
                value = not value
                update()
            end)

            local item = {
                GetValue = function()
                    return value
                end,
                SetValue = function(_, newValue)
                    value = newValue == true
                    update()
                end
            }

            Oreal.Items[flag] = item
            update()

            return item
        end

        function sectionObject:AddSlider(options)
            local flag = options.Flag or options.Name
            local minimum = options.Min or 0
            local maximum = options.Max or 100
            local value = math.clamp(options.Default or minimum, minimum, maximum)

            local frame = New("Frame", {
                Size = UDim2.new(1, 0, 0, 48),
                BackgroundColor3 = Color3.fromRGB(25, 25, 25),
                BorderSizePixel = 0
            }, container)

            Corner(frame, 3)

            local label = New("TextLabel", {
                Size = UDim2.new(0.7, 0, 0, 20),
                Position = UDim2.new(0, 10, 0, 4),
                BackgroundTransparency = 1,
                Text = options.Name or flag,
                TextColor3 = Color3.fromRGB(205, 205, 205),
                TextSize = 9,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left
            }, frame)

            local valueLabel = New("TextLabel", {
                Size = UDim2.new(0.3, -10, 0, 20),
                Position = UDim2.new(0.7, 0, 0, 4),
                BackgroundTransparency = 1,
                Text = tostring(value),
                TextColor3 = Color3.fromRGB(140, 140, 140),
                TextSize = 9,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Right
            }, frame)

            local bar = New("Frame", {
                Size = UDim2.new(1, -20, 0, 5),
                Position = UDim2.new(0, 10, 0, 32),
                BackgroundColor3 = Color3.fromRGB(40, 40, 40),
                BorderSizePixel = 0
            }, frame)

            Corner(bar, 3)

            local fill = New("Frame", {
                Size = UDim2.new((value - minimum) / (maximum - minimum), 0, 1, 0),
                BackgroundColor3 = Color3.fromRGB(220, 220, 220),
                BorderSizePixel = 0
            }, bar)

            Corner(fill, 3)

            local dragging = false

            local function setValue(newValue)
                value = math.clamp(newValue, minimum, maximum)
                valueLabel.Text = tostring(math.floor(value))
                fill.Size = UDim2.new((value - minimum) / (maximum - minimum), 0, 1, 0)

                if options.Callback then
                    options.Callback(value)
                end
            end

            local function update(input)
                local position = math.clamp(
                    (input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X,
                    0,
                    1
                )

                setValue(math.floor(minimum + (maximum - minimum) * position))
            end

            bar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    update(input)
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    update(input)
                end
            end)

            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)

            local item = {
                GetValue = function()
                    return value
                end,
                SetValue = function(_, newValue)
                    setValue(tonumber(newValue) or minimum)
                end
            }

            Oreal.Items[flag] = item
            setValue(value)

            return item
        end

        function sectionObject:AddDropdown(options)
            local flag = options.Flag or options.Name
            local values = options.Values or {}
            local value = options.Default or values[1] or ""
            local opened = false

            local frame = New("Frame", {
                Size = UDim2.new(1, 0, 0, 32),
                BackgroundColor3 = Color3.fromRGB(25, 25, 25),
                BorderSizePixel = 0,
                ClipsDescendants = true
            }, container)

            Corner(frame, 3)

            local button = New("TextButton", {
                Size = UDim2.new(1, -10, 0, 32),
                Position = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1,
                Text = (options.Name or flag) .. ": " .. tostring(value),
                TextColor3 = Color3.fromRGB(205, 205, 205),
                TextSize = 9,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left
            }, frame)

            local list = New("Frame", {
                Size = UDim2.new(1, 0, 0, 0),
                Position = UDim2.new(0, 0, 0, 32),
                BackgroundColor3 = Color3.fromRGB(20, 20, 20),
                BorderSizePixel = 0
            }, frame)

            local layout = New("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder
            }, list)

            local function update()
                button.Text = (options.Name or flag) .. ": " .. tostring(value)

                if options.Callback then
                    options.Callback(value)
                end
            end

            for _, option in ipairs(values) do
                local optionButton = New("TextButton", {
                    Size = UDim2.new(1, 0, 0, 25),
                    BackgroundColor3 = Color3.fromRGB(23, 23, 23),
                    BorderSizePixel = 0,
                    Text = tostring(option),
                    TextColor3 = option == value and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(130, 130, 130),
                    TextSize = 8,
                    Font = Enum.Font.Gotham
                }, list)

                optionButton.MouseButton1Click:Connect(function()
                    value = option
                    opened = false
                    frame.Size = UDim2.new(1, 0, 0, 32)

                    for _, child in ipairs(list:GetChildren()) do
                        if child:IsA("TextButton") then
                            child.TextColor3 = child.Text == tostring(value) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(130, 130, 130)
                        end
                    end

                    update()
                end)
            end

            button.MouseButton1Click:Connect(function()
                opened = not opened
                frame.Size = opened and UDim2.new(1, 0, 0, 32 + #values * 25) or UDim2.new(1, 0, 0, 32)
            end)

            local item = {
                GetValue = function()
                    return value
                end,
                SetValue = function(_, newValue)
                    for _, option in ipairs(values) do
                        if option == newValue then
                            value = newValue
                            update()
                            break
                        end
                    end
                end
            }

            Oreal.Items[flag] = item
            return item
        end

        function sectionObject:AddSearchDropdown(options)
            local flag = options.Flag or options.Name
            local values = options.Values or {}
            local value = options.Default or values[1] or ""
            local opened = false

            local frame = New("Frame", {
                Size = UDim2.new(1, 0, 0, 32),
                BackgroundColor3 = Color3.fromRGB(25, 25, 25),
                BorderSizePixel = 0,
                ClipsDescendants = true
            }, container)

            Corner(frame, 3)

            local button = New("TextButton", {
                Size = UDim2.new(1, -10, 0, 32),
                Position = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1,
                Text = (options.Name or flag) .. ": " .. tostring(value),
                TextColor3 = Color3.fromRGB(205, 205, 205),
                TextSize = 9,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left
            }, frame)

            local search = New("TextBox", {
                Size = UDim2.new(1, -10, 0, 24),
                Position = UDim2.new(0, 5, 0, 32),
                BackgroundColor3 = Color3.fromRGB(17, 17, 17),
                BorderSizePixel = 0,
                PlaceholderText = "Search...",
                PlaceholderColor3 = Color3.fromRGB(100, 100, 100),
                Text = "",
                TextColor3 = Color3.fromRGB(220, 220, 220),
                TextSize = 8,
                Font = Enum.Font.Gotham
            }, frame)

            Corner(search, 3)

            local list = New("Frame", {
                Size = UDim2.new(1, 0, 0, 0),
                Position = UDim2.new(0, 0, 0, 60),
                BackgroundColor3 = Color3.fromRGB(20, 20, 20),
                BorderSizePixel = 0
            }, frame)

            local layout = New("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder
            }, list)

            local buttons = {}

            for _, option in ipairs(values) do
                local optionButton = New("TextButton", {
                    Size = UDim2.new(1, 0, 0, 25),
                    BackgroundColor3 = Color3.fromRGB(23, 23, 23),
                    BorderSizePixel = 0,
                    Text = tostring(option),
                    TextColor3 = option == value and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(130, 130, 130),
                    TextSize = 8,
                    Font = Enum.Font.Gotham
                }, list)

                table.insert(buttons, optionButton)

                optionButton.MouseButton1Click:Connect(function()
                    value = option
                    opened = false
                    frame.Size = UDim2.new(1, 0, 0, 32)

                    if options.Callback then
                        options.Callback(value)
                    end
                end)
            end

            local function filter()
                local query = string.lower(search.Text)
                local count = 0

                for _, optionButton in ipairs(buttons) do
                    local visible = query == "" or string.find(string.lower(optionButton.Text), query, 1, true) ~= nil
                    optionButton.Visible = visible

                    if visible then
                        count += 1
                    end
                end

                if opened then
                    frame.Size = UDim2.new(1, 0, 0, 60 + count * 25)
                end
            end

            search:GetPropertyChangedSignal("Text"):Connect(filter)

            button.MouseButton1Click:Connect(function()
                opened = not opened

                if opened then
                    filter()
                else
                    frame.Size = UDim2.new(1, 0, 0, 32)
                end
            end)

            local item = {
                GetValue = function()
                    return value
                end,
                SetValue = function(_, newValue)
                    for _, option in ipairs(values) do
                        if option == newValue then
                            value = newValue
                            button.Text = (options.Name or flag) .. ": " .. tostring(value)
                            break
                        end
                    end
                end
            }

            Oreal.Items[flag] = item
            return item
        end

        function sectionObject:AddMultiDropdown(options)
            local flag = options.Flag or options.Name
            local values = options.Values or {}
            local selected = {}

            for _, value in ipairs(options.Default or {}) do
                selected[value] = true
            end

            local opened = false

            local frame = New("Frame", {
                Size = UDim2.new(1, 0, 0, 32),
                BackgroundColor3 = Color3.fromRGB(25, 25, 25),
                BorderSizePixel = 0,
                ClipsDescendants = true
            }, container)

            Corner(frame, 3)

            local function count()
                local total = 0

                for _, enabled in pairs(selected) do
                    if enabled then
                        total += 1
                    end
                end

                return total
            end

            local button = New("TextButton", {
                Size = UDim2.new(1, -10, 0, 32),
                Position = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1,
                Text = (options.Name or flag) .. ": " .. count() .. " selected",
                TextColor3 = Color3.fromRGB(205, 205, 205),
                TextSize = 9,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left
            }, frame)

            local list = New("Frame", {
                Size = UDim2.new(1, 0, 0, 0),
                Position = UDim2.new(0, 0, 0, 32),
                BackgroundColor3 = Color3.fromRGB(20, 20, 20),
                BorderSizePixel = 0
            }, frame)

            New("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder
            }, list)

            local function getValues()
                local result = {}

                for _, option in ipairs(values) do
                    if selected[option] then
                        table.insert(result, option)
                    end
                end

                return result
            end

            for _, option in ipairs(values) do
                local optionButton = New("TextButton", {
                    Size = UDim2.new(1, 0, 0, 25),
                    BackgroundColor3 = Color3.fromRGB(23, 23, 23),
                    BorderSizePixel = 0,
                    Text = tostring(option),
                    TextColor3 = selected[option] and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(125, 125, 125),
                    TextSize = 8,
                    Font = Enum.Font.Gotham
                }, list)

                optionButton.MouseButton1Click:Connect(function()
                    selected[option] = not selected[option]

                    optionButton.TextColor3 = selected[option] and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(125, 125, 125)
                    button.Text = (options.Name or flag) .. ": " .. count() .. " selected"

                    if options.Callback then
                        options.Callback(getValues())
                    end
                end)
            end

            button.MouseButton1Click:Connect(function()
                opened = not opened
                frame.Size = opened and UDim2.new(1, 0, 0, 32 + #values * 25) or UDim2.new(1, 0, 0, 32)
            end)

            local item = {
                GetValue = function()
                    return getValues()
                end,
                SetValue = function(_, newValues)
                    selected = {}

                    if type(newValues) == "table" then
                        for _, value in ipairs(newValues) do
                            selected[value] = true
                        end
                    end

                    button.Text = (options.Name or flag) .. ": " .. count() .. " selected"
                end
            }

            Oreal.Items[flag] = item
            return item
        end

        function sectionObject:AddTextBox(options)
            local flag = options.Flag or options.Name
            local value = options.Default or ""

            local frame = New("Frame", {
                Size = UDim2.new(1, 0, 0, 42),
                BackgroundColor3 = Color3.fromRGB(25, 25, 25),
                BorderSizePixel = 0
            }, container)

            Corner(frame, 3)

            New("TextLabel", {
                Size = UDim2.new(0.4, 0, 1, 0),
                Position = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1,
                Text = options.Name or flag,
                TextColor3 = Color3.fromRGB(205, 205, 205),
                TextSize = 9,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left
            }, frame)

            local input = New("TextBox", {
                Size = UDim2.new(0.55, -5, 0, 25),
                Position = UDim2.new(0.45, 0, 0.5, -12),
                BackgroundColor3 = Color3.fromRGB(17, 17, 17),
                BorderSizePixel = 0,
                Text = value,
                PlaceholderText = options.Placeholder or "Enter text...",
                PlaceholderColor3 = Color3.fromRGB(90, 90, 90),
                TextColor3 = Color3.fromRGB(220, 220, 220),
                TextSize = 8,
                Font = Enum.Font.Gotham
            }, frame)

            Corner(input, 3)

            input.FocusLost:Connect(function(enterPressed)
                value = input.Text

                if options.Callback then
                    options.Callback(value, enterPressed)
                end
            end)

            local item = {
                GetValue = function()
                    return value
                end,
                SetValue = function(_, newValue)
                    value = tostring(newValue or "")
                    input.Text = value
                end
            }

            Oreal.Items[flag] = item
            return item
        end

        local section = sectionObject
        return section
    end

    function tab:Select()
        for _, other in pairs(Oreal.Tabs) do
            other.Page.Visible = false
            other.Button.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
            other.Button:FindFirstChildWhichIsA("TextLabel").TextColor3 = Color3.fromRGB(145, 145, 145)
        end

        self.Page.Visible = true
        self.Button.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        self.Button:FindFirstChildWhichIsA("TextLabel").TextColor3 = Color3.fromRGB(255, 255, 255)
    end

    tabButton.MouseButton1Click:Connect(function()
        tab:Select()
    end)

    table.insert(self.Tabs, tab)
    self.Tabs[name] = tab

    if #self.Tabs == 1 then
        tab:Select()
    end

    return tab
end

function Oreal:ApplyConfigManager(tab)
    local section = tab:CreateSection("Config Manager", "Left")
    local info = tab:CreateSection("Config Status", "Right")

    section:AddTextBox({
        Name = "Config Name",
        Flag = "ConfigName",
        Placeholder = "Enter config name..."
    })

    local configDropdown

    local function refreshConfigs()
        if configDropdown and configDropdown.SetValues then
            configDropdown:SetValues(GetConfigs())
        end
    end

    configDropdown = section:AddDropdown({
        Name = "Configs",
        Flag = "SelectedConfig",
        Values = GetConfigs(),
        Default = GetConfigs()[1] or ""
    })

    section:AddButton({
        Name = "Save Config",
        Callback = function()
            local name = Oreal.Items.ConfigName:GetValue()

            if name == "" then
                self:Notify("Config", "Enter a config name first.")
                return
            end

            if SaveConfig(name, false) then
                self:Notify("Config", "Config saved.")
                refreshConfigs()
            else
                self:Notify("Config", "Config already exists.")
            end
        end
    })

    section:AddButton({
        Name = "Load Config",
        Callback = function()
            local name = Oreal.Items.SelectedConfig:GetValue()

            if LoadConfig(name) then
                self:Notify("Config", "Config loaded.")
            else
                self:Notify("Config", "Config could not be loaded.")
            end
        end
    })

    section:AddButton({
        Name = "Overwrite Config",
        Callback = function()
            local name = Oreal.Items.ConfigName:GetValue()

            if name == "" then
                name = Oreal.Items.SelectedConfig:GetValue()
            end

            if SaveConfig(name, true) then
                self:Notify("Config", "Config overwritten.")
                refreshConfigs()
            else
                self:Notify("Config", "Could not overwrite config.")
            end
        end
    })

    section:AddButton({
        Name = "Set As Autoload",
        Callback = function()
            local name = Oreal.Items.SelectedConfig:GetValue()

            if not name or name == "" then
                name = Oreal.Items.ConfigName:GetValue()
            end

            if name and name ~= "" then
                SetAutoload(name)
                self:Notify("Autoload", "Autoload set to " .. name .. ".")
                updateAutoload()
            end
        end
    })

    section:AddButton({
        Name = "Remove Autoload",
        Callback = function()
            SetAutoload("")
            self:Notify("Autoload", "Autoload removed.")
            updateAutoload()
        end
    })

    section:AddButton({
        Name = "Delete Config",
        Callback = function()
            local name = Oreal.Items.SelectedConfig:GetValue()

            if DeleteConfig(name) then
                self:Notify("Config", "Config deleted.")
                refreshConfigs()
            else
                self:Notify("Config", "Config could not be deleted.")
            end
        end
    })

    info:AddLabel("Autoload")

    local autoloadLabel = info:AddLabel("None")

    function updateAutoload()
        local autoload = GetAutoload()
        autoloadLabel.Text = autoload and ("Autoload: " .. autoload) or "Autoload: None"
    end

    updateAutoload()

    local autoload = GetAutoload()

    if autoload and isfile and isfile(GetPath(self.ConfigFolder, autoload)) then
        task.defer(function()
            LoadConfig(autoload)
        end)
    end

    return {
        Refresh = refreshConfigs
    }
end

return Oreal
