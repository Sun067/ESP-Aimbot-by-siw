local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "ESP - Aimbot by siw",
    SubTitle = "Aimbot & ESP Edition",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = false, 
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.End
})

local Tabs = {
    Combat = Window:AddTab({ Title = "Combat", Icon = "crosshair" }),
    Visuals = Window:AddTab({ Title = "Visuals", Icon = "eye" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- [[ SETTINGS ]]
local ESP_ENABLED = false
local AIMBOT_ENABLED = false
local FOV_ENABLED = false
local FOV_RADIUS = 150
local SMOOTHING = 2
local TARGET_PART = "Head"

-- [[ FOV CIRCLE SETUP ]]
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Filled = false
FOVCircle.Visible = false

-- [[ ESP SYSTEM (NEW CLEAN VERSION) ]]
local ESP_Table = {}

local function RemoveESP(player)
    if ESP_Table[player] then
        for _, obj in pairs(ESP_Table[player].Drawing) do
            obj.Visible = false
            obj:Remove()
        end
        ESP_Table[player] = nil
    end
end

local function CreateESP(player)
    if player == LocalPlayer then return end
    
    local Box = Drawing.new("Square")
    Box.Thickness = 1
    Box.Filled = false
    Box.Color = Color3.fromRGB(255, 255, 255)

    local HealthBar = Drawing.new("Line")
    HealthBar.Thickness = 2

    ESP_Table[player] = {
        Drawing = {Box, HealthBar}
    }

    local function Update()
        local Connection
        Connection = RunService.RenderStepped:Connect(function()
            if ESP_ENABLED and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local Root = player.Character.HumanoidRootPart
                local Hum = player.Character:FindFirstChildOfClass("Humanoid")
                local Pos, OnScreen = Camera:WorldToViewportPoint(Root.Position)

                if OnScreen and Hum and Hum.Health > 0 then
                    local Size = (Camera:WorldToViewportPoint(Root.Position - Vector3.new(0, 3, 0)).Y - Camera:WorldToViewportPoint(Root.Position + Vector3.new(0, 2.6, 0)).Y)
                    Box.Size = Vector2.new(Size * 1.5, Size)
                    Box.Position = Vector2.new(Pos.X - Box.Size.X / 2, Pos.Y - Box.Size.Y / 2)
                    Box.Visible = true

                    local HP = Hum.Health / Hum.MaxHealth
                    HealthBar.From = Vector2.new(Box.Position.X - 5, Box.Position.Y + Box.Size.Y)
                    HealthBar.To = Vector2.new(Box.Position.X - 5, Box.Position.Y + Box.Size.Y - (Box.Size.Y * HP))
                    HealthBar.Color = Color3.fromHSV(HP * 0.3, 1, 1)
                    HealthBar.Visible = true
                else
                    Box.Visible = false
                    HealthBar.Visible = false
                end
            else
                Box.Visible = false
                HealthBar.Visible = false
                if not ESP_ENABLED or not player.Parent then
                    Connection:Disconnect()
                    RemoveESP(player)
                end
            end
        end)
    end
    coroutine.wrap(Update)()
end

-- [[ AIMBOT LOGIC (KEEP ORIGINAL) ]]
local function GetClosestPlayer()
    local Target = nil
    local ShortestDistance = FOV_RADIUS
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild(TARGET_PART) then
            local Hum = v.Character:FindFirstChildOfClass("Humanoid")
            if Hum and Hum.Health > 0 then
                local Pos, OnScreen = Camera:WorldToViewportPoint(v.Character[TARGET_PART].Position)
                if OnScreen then
                    local Distance = (Vector2.new(Pos.X, Pos.Y) - Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)).Magnitude
                    if Distance < ShortestDistance then
                        ShortestDistance = Distance
                        Target = v
                    end
                end
            end
        end
    end
    return Target
end

-- [[ UI - COMBAT ]]
local AimToggle = Tabs.Combat:AddToggle("AimToggle", {Title = "Enable Aimbot", Default = false })
AimToggle:OnChanged(function() AIMBOT_ENABLED = AimToggle.Value end)

Tabs.Combat:AddKeybind("AimKeybind", {Title = "Aimbot Keybind", Default = "LeftControl", Callback = function(Value) AimToggle:SetValue(Value) end})

local FOVToggle = Tabs.Combat:AddToggle("FOVToggle", {Title = "Show FOV Circle", Default = false })
FOVToggle:OnChanged(function() FOV_ENABLED = FOVToggle.Value end)

Tabs.Combat:AddSlider("FOVSlider", {Title = "FOV Size", Min = 30, Max = 500, Default = 150, Rounding = 0, Callback = function(Value) FOV_RADIUS = Value end})
Tabs.Combat:AddSlider("SmoothSlider", {Title = "Aimbot Smoothing", Min = 1, Max = 10, Default = 2, Rounding = 1, Callback = function(Value) SMOOTHING = Value end})
Tabs.Combat:AddDropdown("PartDropdown", {Title = "Target Part", Values = {"Head", "UpperTorso", "HumanoidRootPart"}, Default = "Head", Callback = function(Value) TARGET_PART = Value end})

-- [[ UI - VISUALS ]]
local ESPToggle = Tabs.Visuals:AddToggle("ESPToggle", {Title = "Enable ESP", Default = false })
ESPToggle:OnChanged(function() 
    ESP_ENABLED = ESPToggle.Value 
    if ESP_ENABLED then
        for _, p in pairs(Players:GetPlayers()) do CreateESP(p) end
    else
        for _, p in pairs(Players:GetPlayers()) do RemoveESP(p) end
    end
end)

Tabs.Visuals:AddKeybind("ESPKeybind", {Title = "ESP Keybind", Default = "P", Callback = function(Value) ESPToggle:SetValue(Value) end})

-- [[ MAIN LOOP - FIXED VERSION ]]
RunService.RenderStepped:Connect(function()
    if FOV_ENABLED then
        FOVCircle.Visible = true
        FOVCircle.Radius = FOV_RADIUS
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    else
        FOVCircle.Visible = false
    end
    
    if AIMBOT_ENABLED then
        local Target = GetClosestPlayer()
        -- แก้ไขจุดที่เช็ค UserInputType เพื่อป้องกัน Error ใน Fluent UI
        if Target and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            local TargetCharacter = Target.Character
            if TargetCharacter and TargetCharacter:FindFirstChild(TARGET_PART) then
                local TargetPos = Camera:WorldToViewportPoint(TargetCharacter[TARGET_PART].Position)
                local MousePos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                
                if mousemoverel then
                    mousemoverel((TargetPos.X - MousePos.X) / SMOOTHING, (TargetPos.Y - MousePos.Y) / SMOOTHING)
                end
            end
        end
    end
end)

-- [[ CONFIG ]]
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)
Window:SelectTab(1)
SaveManager:LoadAutoloadConfig()
Players.PlayerAdded:Connect(function(p) if ESP_ENABLED then CreateESP(p) end end)
Players.PlayerRemoving:Connect(RemoveESP)
