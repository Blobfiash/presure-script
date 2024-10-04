local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("Pressure", "Synapse")

local MainTab = Window:NewTab("Main")
local BasicSection = MainTab:NewSection("Basics")
local ExtraSection = MainTab:NewSection("Extras")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local rooms = workspace:WaitForChild("Rooms")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local KeyChams = {}
local MedkitChams = {}
local MonsterTracers = {}
local FakeDoorEsps = {}
local originalDistances = {}

_G.KeyChams = false
_G.MedkitChams = false
_G.MonsterLockerChams = false
_G.MonsterTracers = false
_G.GodMode = false
_G.InstantInteract = false
_G.FakeDoorEsp = false

BasicSection:NewButton("Noclip", "CANT TURN OFF!!!", function()
    local noclip = true
    local character = Player.Character or Player.CharacterAdded:Wait()
    while true do
        character = Player.Character
        if noclip and character then
            for _, part in pairs(character:GetDescendants()) do
                pcall(function()
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end)
            end
        end
        game:GetService("RunService").Stepped:Wait()
    end
end)

local currentSpeed = 16

ExtraSection:NewSlider("Speed Boost", "Changes your player speed", 100, 16, function(value)
    currentSpeed = value
end)

game:GetService("RunService").RenderStepped:Connect(function()
    if Player.Character and Player.Character:FindFirstChild("Humanoid") then
        Player.Character.Humanoid.WalkSpeed = currentSpeed
    end
end)

ExtraSection:NewSlider("Field of View", "Changes FOV", 125, 90, function(value)
    workspace.CurrentCamera.FieldOfView = value
end)

ExtraSection:NewToggle("Full Bright", "Makes you see in the dark", function(state)
    if state then
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
    else
        Lighting.Ambient = Color3.fromRGB(40, 53, 65)
    end
end)

ExtraSection:NewToggle("Keycard Chams (Color Red)", "Keycard chams", function(state)
    _G.KeyChams = state
    if not state then
        for _, cham in pairs(KeyChams) do
            cham:Destroy()
        end
        KeyChams = {}
    else
        coroutine.wrap(updateKeyChams)()
    end
end)

ExtraSection:NewToggle("Medkit/Other Items Chams (Color Blue)", "Chams for medkits and other things", function(state)
    _G.MedkitChams = state
    updateMedkitChams()
end)

ExtraSection:NewToggle("Instant Interact", "Test", function(state)
    _G.InstantInteract = state
    while _G.InstantInteract do
        for _, item in pairs(workspace:GetDescendants()) do
            if item:IsA("ProximityPrompt") then
                item.HoldDuration = 0
            end
        end
        wait(0)
    end
end)

ExtraSection:NewSlider("Grab Distance", "Test", 60, 7, function(value)
    for _, item in pairs(workspace:GetDescendants()) do
        if item:IsA("ProximityPrompt") then
            if not originalDistances[item] then
                originalDistances[item] = item.MaxActivationDistance
            end
            item.MaxActivationDistance = value == 7 and 7 or value
        end
    end
end)

ExtraSection:NewToggle("Monster Label", "Labels the monster of how far they are", function(state)
    _G.MonsterTracers = state
    if state then
        workspace.ChildAdded:Connect(function(inst)
            local monsters = {
                ["Angler"] = true,
                ["Froger"] = true,
                ["A60"] = true,
                ["Pandemonium"] = true,
                ["Blitz"] = true,
                ["Chainsmoker"] = true,
                ["Pinkie"] = true
            }
            if monsters[inst.Name] then
                local part = Instance.new("Part")
                part.Position = inst.Position
                part.Anchored = true
                part.Transparency = 0.5
                part.CanCollide = false
                part.BrickColor = BrickColor.new("Red")
                part.Parent = workspace

                local billboard = Instance.new("BillboardGui")
                billboard.Adornee = inst
                billboard.Size = UDim2.new(0, 100, 0, 50)
                billboard.StudsOffset = Vector3.new(0, 2, 0)
                billboard.AlwaysOnTop = true
                billboard.Parent = game:GetService("CoreGui")

                local label = Instance.new("TextLabel")
                label.Size = UDim2.new(1, 0, 1, 0)
                label.TextColor3 = Color3.new(1, 1, 1)
                label.BackgroundTransparency = 1
                label.TextScaled = true
                label.Parent = billboard

                MonsterTracers[inst] = {part, billboard, label}
                game:GetService("RunService").RenderStepped:Connect(function()
                    if _G.MonsterTracers then
                        local playerPosition = Player.Character.HumanoidRootPart.Position
                        local monsterPosition = inst.Position
                        local distance = math.floor((playerPosition - monsterPosition).Magnitude)
                        label.Text = "Distance: " .. distance .. " feet"
                        part.Position = monsterPosition
                    else
                        part:Destroy()
                        billboard:Destroy()
                        MonsterTracers[inst] = nil
                    end
                end)
            end
        end)
    else
        for monster, tracer in pairs(MonsterTracers) do
            tracer[1]:Destroy()
            tracer[2]:Destroy()
            tracer[3]:Destroy()
            MonsterTracers[monster] = nil
        end
    end
end)

ExtraSection:NewToggle("Locker Esp", "Tells you if there is a monster in a locker", function(state)
    _G.MonsterLockerChams = state
    updateMonsterlockerChams()
end)

ExtraSection:NewToggle("Fake Door Esp", "If a door is red don't enter", function(state)
    _G.FakeDoorEsp = state
    updateFakeDoorChams()
end)

-- Funcs

local function updateKeyChams()
    while true do
        if _G.KeyChams then
            for _, item in ipairs(workspace.Rooms:GetDescendants()) do
                if item.Name == "NormalKeyCard" or item.Name == "InnerKeyCard" or item.Name == "RidgeKeyCard" then
                    local exists = false
                    for _, cham in ipairs(KeyChams) do
                        if cham.Adornee == item then
                            exists = true
                            break
                        end
                    end
                    if not exists then
                        local cham = Instance.new("Highlight")
                        cham.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        cham.FillColor = Color3.new(1, 0, 0)
                        cham.FillTransparency = 0
                        cham.OutlineColor = Color3.new(1, 0, 0)
                        cham.Parent = game:GetService("CoreGui")
                        cham.Adornee = item
                        cham.Enabled = true
                        cham.RobloxLocked = true
                        table.insert(KeyChams, cham)
                    end
                end
            end
        end
        wait(0.1)
    end
end

local function updateMedkitChams()
    for _, cham in pairs(MedkitChams) do
        cham:Destroy()
    end
    MedkitChams = {}
    if _G.MedkitChams then
        for _, item in ipairs(workspace.Rooms:GetDescendants()) do
            if item.Name == "Medkit" or item.Name == "Flashlight" or item.Name == "CodeBreacher" then
                local cham = Instance.new("Highlight")
                cham.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                cham.FillColor = Color3.new(0, 0, 1)
                cham.FillTransparency = 0.5
                cham.OutlineColor = Color3.new(0, 0, 1)
                cham.Adornee = item
                cham.Parent = game:GetService("CoreGui")
                cham.Enabled = true
                table.insert(MedkitChams, cham)
            end
        end
    end
end

local function updateMonsterlockerChams()
    for _, cham in pairs(MedkitChams) do
        cham:Destroy()
    end
    MedkitChams = {}
    if _G.MonsterLockerChams then
        for _, item in ipairs(workspace.Rooms:GetDescendants()) do
            if item.Name == "MonsterLocker" then
                local cham = Instance.new("Highlight")
                cham.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                cham.FillColor = Color3.new(1, 0, 0)
                cham.FillTransparency = 0.5
                cham.OutlineColor = Color3.new(1, 0, 0)
                cham.Adornee = item
                cham.Parent = game:GetService("CoreGui")
                cham.Enabled = true
                table.insert(MedkitChams, cham)
            end
        end
    end
end

local function updateFakeDoorChams()
    for _, cham in pairs(FakeDoorEsps) do
        cham:Destroy()
    end
    FakeDoorEsps = {}
    if _G.FakeDoorEsp then
        for _, item in ipairs(workspace.Rooms:GetDescendants()) do
            if item.Name == "TricksterDoor" then
                local cham = Instance.new("Highlight")
                cham.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                cham.FillColor = Color3.new(1, 0, 0)
                cham.FillTransparency = 0.5
                cham.OutlineColor = Color3.new(1, 0, 0)
                cham.Adornee = item
                cham.Parent = game:GetService("CoreGui")
                cham.Enabled = true
                table.insert(FakeDoorEsps, cham)
            end
        end
    end
end

workspace.Rooms.DescendantAdded:Connect(function(inst)
    if inst.Name == "MonsterLocker" then
        updateMonsterlockerChams()
    elseif inst.Name == "Medkit" or inst.Name == "Flashlight" or inst.Name == "CodeBreacher" then
        updateMedkitChams()
    elseif inst.Name == "TricksterDoor" then
        updateFakeDoorChams()
    elseif inst.Name == "NormalKeyCard" or inst.Name == "InnerKeyCard" or inst.Name == "RidgeKeyCard" then 
        updateKeyChams()
    end
end)
