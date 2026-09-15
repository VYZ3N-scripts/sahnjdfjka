local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/jensonhirst/Orion/main/source')))()
loadstring(game:HttpGet(('https://raw.githubusercontent.com/2015xavier123-star/My-mod-lowk/refs/heads/main/anti_grab_ghost_script.txt')))()

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local AntiExplosionEnabled = false
local antiExplosionConnection = nil
local antiExplosionCharConn = nil

local function setupAntiExplosion(character)
    local humanoid = character:WaitForChild("Humanoid", 5)
    local hrp = character:WaitForChild("HumanoidRootPart", 5)
    if not humanoid or not hrp then return end

    if antiExplosionConnection then
        antiExplosionConnection:Disconnect()
        antiExplosionConnection = nil
    end

    antiExplosionConnection = Workspace.ChildAdded:Connect(function(model)
        if not AntiExplosionEnabled then return end

        local char = LocalPlayer.Character
        local h = char and char:FindFirstChild("Humanoid")
        local r = char and char:FindFirstChild("HumanoidRootPart")
        if not h or not r then return end

        if model:IsA("BasePart") and (model.Position - r.Position).Magnitude <= 20 then
            if h.SeatPart ~= nil then
                r.Anchored = true
                task.wait(0.03)
                r.AssemblyLinearVelocity = Vector3.zero
                r.AssemblyAngularVelocity = Vector3.zero
                r.Anchored = false
            else
                r.Anchored = true
                task.wait()
                h:ChangeState(Enum.HumanoidStateType.Running)
                r.Anchored = false
                h.AutoRotate = true

                for _, limb in ipairs(char:GetDescendants()) do
                    if limb:IsA("BasePart") and limb.Name == "RagdollLimbPart" then
                        limb.CanCollide = false
                    end
                end
            end
        end
    end)
end

local function enableAntiExplosion()
    AntiExplosionEnabled = true

    if LocalPlayer.Character then
        setupAntiExplosion(LocalPlayer.Character)
    end

    if antiExplosionCharConn then
        antiExplosionCharConn:Disconnect()
    end

    antiExplosionCharConn = LocalPlayer.CharacterAdded:Connect(function(char)
        if antiExplosionConnection then
            antiExplosionConnection:Disconnect()
            antiExplosionConnection = nil
        end
        setupAntiExplosion(char)
    end)
end

local function disableAntiExplosion()
    AntiExplosionEnabled = false

    if antiExplosionConnection then
        antiExplosionConnection:Disconnect()
        antiExplosionConnection = nil
    end

    if antiExplosionCharConn then
        antiExplosionCharConn:Disconnect()
        antiExplosionCharConn = nil
    end
end

local Window = OrionLib:MakeWindow({
    Name = "Main script | AI SIMP",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "OrionTest"
})

local AntisTab = Window:MakeTab({
    Name = "Antis",
    Icon = "rbxassetid://111176085924966",
    PremiumOnly = false
})

local Rndm = Window:MakeTab({
    Name = "Essentials",
    Icon = "rbxassetid://5009915812",
    PremiumOnly = false
})

AntisTab:AddToggle({
    Name = "Antigrab",
    Default = false,
    Callback = function(Value)
        SETTINGS_ANTI_GRAB = Value
    end
})

AntisTab:AddToggle({
    Name = "Anti Explosion",
    Default = false,
    Callback = function(Value)
        if Value then
            enableAntiExplosion()
        else
            disableAntiExplosion()
        end
    end
})

Rndm:AddToggle({
    Name = "Enable void",
    Default = true,
    Callback = function(Value)
        game.Workspace.FallHeightEnabled = Value
    end
})

Rndm:AddButton({
    Name = "Tsunami",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/2015xavier123-star/Bjsjsjs/refs/heads/main/tsunami.lua"))()
    end
})

Rndm:AddButton({
    Name = "Grab all",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/2015xavier123-star/Bjsjsjs/refs/heads/main/Test.lua"))()
    end
})

OrionLib:Init()
