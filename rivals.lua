-- Rivals Enhanced Script (Silent Aim + FOV Circle + ESP + Username/Health + Skin Changer + Noclip + Keybinds)
-- March 2026 style - use at own risk

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- Settings
local SilentAimEnabled = false          -- toggle with keybind
local AimKey = Enum.KeyCode.E           -- press E to toggle silent aim
local AimHoldKey = Enum.UserInputType.MouseButton2  -- hold RMB for silent aim (alternative)
local FOV = 180
local ShowFOVCircle = true
local TeamCheck = true
local VisibleCheck = true

local ESPEnabled = true
local BoxColor = Color3.fromRGB(255, 100, 100)
local TracerColor = Color3.fromRGB(255, 200, 200)
local NameColor = Color3.fromRGB(255, 255, 255)
local HealthColor = Color3.fromRGB(0, 255, 0)

local NoclipEnabled = false
local NoclipKey = Enum.KeyCode.N

-- FOV Circle
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 2
fovCircle.NumSides = 100
fovCircle.Radius = FOV
fovCircle.Filled = false
fovCircle.Color = Color3.fromRGB(255, 255, 0)
fovCircle.Transparency = 0.8
fovCircle.Visible = ShowFOVCircle

RunService.RenderStepped:Connect(function()
    if ShowFOVCircle and fovCircle then
        fovCircle.Position = Vector2.new(Mouse.X, Mouse.Y + game:GetService("GuiService"):GetGuiInset().Y)
    end
end)

-- Closest target function
local function GetClosestPlayerToMouse()
    local closest, dist = nil, FOV
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then continue end
        
        local root = player.Character.HumanoidRootPart
        local head = player.Character:FindFirstChild("Head") or root
        if not head then continue end
        
        if TeamCheck and player.Team == LocalPlayer.Team then continue end
        
        local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
        if not onScreen then continue end
        
        local magnitude = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
        if magnitude < dist then
            if VisibleCheck then
                local rayParams = RaycastParams.new()
                rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
                rayParams.FilterType = Enum.RaycastFilterType.Exclude
                local rayResult = workspace:Raycast(Camera.CFrame.Position, (head.Position - Camera.CFrame.Position).Unit * 999, rayParams)
                if rayResult and rayResult.Instance and rayResult.Instance:IsDescendantOf(player.Character) then
                    closest = head
                    dist = magnitude
                end
            else
                closest = head
                dist = magnitude
            end
        end
    end
    
    return closest
end

-- Silent Aim hook (namecall)
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    local args = {...}
    local method = getnamecallmethod()
    
    if SilentAimEnabled and self == workspace and method == "Raycast" then
        local target = GetClosestPlayerToMouse()
        if target then
            local origin = args[1]
            local newDir = (target.Position - origin).Unit * 999
            return oldNamecall(self, origin, newDir, unpack(args, 3))
        end
    end
    
    return oldNamecall(self, ...)
end)

setreadonly(mt, true)

-- Keybinds
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    
    if input.KeyCode == AimKey then
        SilentAimEnabled = not SilentAimEnabled
        print("Silent Aim " .. (SilentAimEnabled and "ENABLED" or "DISABLED"))
    elseif input.KeyCode == NoclipKey then
        NoclipEnabled = not NoclipEnabled
        print("Noclip " .. (NoclipEnabled and "ENABLED" or "DISABLED"))
    end
end)

-- Hold RMB alternative toggle
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == AimHoldKey then
        SilentAimEnabled = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == AimHoldKey then
        SilentAimEnabled = false
    end
end)

-- Noclip loop
RunService.Stepped:Connect(function()
    if NoclipEnabled and LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

-- ESP with Username + Health
local function AddESP(player)
    if player == LocalPlayer then return end
    
    local box = Drawing.new("Square")
    box.Thickness = 2
    box.Filled = false
    box.Color = BoxColor
    box.Transparency = 1
    
    local tracer = Drawing.new("Line")
    tracer.Thickness = 1
    tracer.Color = TracerColor
    tracer.Transparency = 1
    
    local nameText = Drawing.new("Text")
    nameText.Size = 14
    nameText.Center = true
    nameText.Outline = true
    nameText.Color = NameColor
    nameText.Text = player.Name
    
    local healthBar = Drawing.new("Line")
    healthBar.Thickness = 3
    healthBar.Color = HealthColor
    healthBar.Transparency = 1
    
    local healthText = Drawing.new("Text")
    healthText.Size = 12
    healthText.Center = true
    healthText.Outline = true
    healthText.Color = HealthColor
    
    local conn
    conn = RunService.RenderStepped:Connect(function()
        if not ESPEnabled or not player.Character or not player.Character:FindFirstChild("Humanoid") or player.Character.Humanoid.Health <= 0 or not player.Character:FindFirstChild("HumanoidRootPart") then
            box.Visible = false
            tracer.Visible = false
            nameText.Visible = false
            healthBar.Visible = false
            healthText.Visible = false
            return
        end
        
        local root = player.Character.HumanoidRootPart
        local head = player.Character:FindFirstChild("Head")
        local humanoid = player.Character.Humanoid
        
        local headPos, onScreen = Camera:WorldToViewportPoint((head or root).Position + Vector3.new(0, 1, 0))
        local legPos = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
        
        if onScreen then
            local sizeY = (headPos - legPos).Magnitude
            local sizeX = sizeY * 0.6
            
            box.Size = Vector2.new(sizeX, sizeY)
            box.Position = Vector2.new(headPos.X - sizeX/2, headPos.Y - sizeY/2)
            box.Visible = true
            
            tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            tracer.To = Vector2.new(headPos.X, headPos.Y)
            tracer.Visible = true
            
            nameText.Position = Vector2.new(headPos.X, headPos.Y - sizeY/2 - 16)
            nameText.Visible = true
            
            local healthPct = humanoid.Health / humanoid.MaxHealth
            healthBar.From = Vector2.new(headPos.X - sizeX/2 - 6, headPos.Y + sizeY/2)
            healthBar.To = Vector2.new(headPos.X - sizeX/2 - 6, headPos.Y + sizeY/2 - sizeY * healthPct)
            healthBar.Color = Color3.fromHSV(healthPct * 0.3, 1, 1)  -- green to red
            healthBar.Visible = true
            
            healthText.Text = tostring(math.floor(humanoid.Health)) .. "/" .. tostring(humanoid.MaxHealth)
            healthText.Position = Vector2.new(headPos.X - sizeX/2 - 20, headPos.Y + sizeY/2 - 10)
            healthText.Visible = true
        else
            box.Visible = false
            tracer.Visible = false
            nameText.Visible = false
            healthBar.Visible = false
            healthText.Visible = false
        end
    end)
    
    player.CharacterRemoving:Connect(function()
        conn:Disconnect()
        box:Remove()
        tracer:Remove()
        nameText:Remove()
        healthBar:Remove()
        healthText:Remove()
    end)
end

-- Load ESP for existing players
for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= LocalPlayer then
        task.spawn(AddESP, plr)
    end
end

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Wait()
    task.spawn(AddESP, plr)
end)

-- Basic Skin Changer (example - may not work if game uses server-side skins)
-- Change this table to actual asset IDs you want (guns/skins)
local skinTable = {
    ["SomeGunName"] = 1234567890,  -- replace with real skin asset ID
    -- add more
}

local function ChangeSkins()
    if not LocalPlayer.Character then return end
    for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if tool:IsA("Tool") and skinTable[tool.Name] then
            -- Attempt local skin spoof (often blocked)
            for _, handle in ipairs(tool:GetDescendants()) do
                if handle:IsA("MeshPart") or handle:IsA("Part") then
                    handle.TextureID = "rbxassetid://" .. tostring(skinTable[tool.Name])
                end
            end
        end
    end
end

-- Run skin changer every few seconds (or on tool equip)
spawn(function()
    while true do
        ChangeSkins()
        wait(3)
    end
end)

print("Rivals Enhanced Script Loaded!")
print("Keybinds:")
print("E = Toggle Silent Aim")
print("Hold RMB = Silent Aim while holding")
print("N = Toggle Noclip")
print("FOV Circle visible (yellow)")
print("ESP: Box + Tracer + Name + Health Bar")
