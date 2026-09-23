local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Ali-lov3/OrealUiLib/refs/heads/main/Source.lua"))()
local CheatName = "MyProject"

Library.Folders = {
    Directory = CheatName,
    Configs = CheatName .. "/Configs",
    Assets = CheatName .. "/Assets",
}

local Accent = Color3.fromRGB(255, 80, 80)
local Gradient = Color3.fromRGB(120, 20, 20)

Library.Theme.Accent = Accent
Library.Theme.AccentGradient = Gradient
Library:ChangeTheme("Accent", Accent)
Library:ChangeTheme("AccentGradient", Gradient)
local Window = Library:Window({
    Name = "Like Neverlose UI",
    SubName = "Example btw",
    Logo = "120959262762131"
})

local KeybindList = Library:KeybindList("Keybinds")
Library:Watermark({
    "Like Neverlose UI",
    "by ImInsane",
    120959262762131
})

task.spawn(function()
    while true do
        local FPS = math.floor(1 / game:GetService("RunService").RenderStepped:Wait())
        
        Library:Watermark({
            "Like Neverlose UI",
            "by ImInsane",
            120959262762131,
            "FPS: " .. FPS
        })
        task.wait(0.5)
    end
end)

Window:Category("Main")

local LegitPage = Window:Page({Name = "Legit", Icon = "138827881557940"})
local MainSection = LegitPage:Section({Name = "Main Features", Side = 1})

MainSection:Toggle({
    Name = "Enabled",
    Flag = "LegitEnabled",
    Default = true,
    Callback = function(Value)
        print("Legit Enabled:", Value)
    end
})

MainSection:Slider({
    Name = "Speed Hack",
    Flag = "SpeedSlider",
    Min = 1,
    Max = 100,
    Default = 16,
    Suffix = " studs",
    Callback = function(Value)
        print("Speed set to:", Value)
    end
})

MainSection:Dropdown({
    Name = "Hitbox Type",
    Flag = "HitboxType",
    Default = {"Head"},
    Items = {"Head", "Torso", "Arms", "Legs"},
    Multi = true,
    Callback = function(Value)
        print("Selected Hitboxes:", table.concat(Value, ", "))
    end
})

MainSection:Label("ESP Color"):Colorpicker({
    Name = "Color",
    Flag = "EspColor",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(Value)
        print("Color changed")
    end
})

local MiscSection = LegitPage:Section({Name = "Misc", Side = 2})
MiscSection:Button({
    Name = "Test Notification",
    Callback = function()
        Library:Notification({
            Title = "System",
            Description = "This is a test notification!",
            Duration = 5,
            Icon = "73789337996373"
        })
    end
})

MiscSection:Keybind({
    Name = "Test keybind",
    Flag = "testkeybind",
    Default = Enum.KeyCode.Delete,
    Callback = function(Value)
        print("Keybind pressed")
    end
})

Window:Category("Settings")
local SettingsPage = Library:CreateSettingsPage(Window, KeybindList)
Window:Init()
