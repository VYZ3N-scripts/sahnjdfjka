local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local CharacterEvents = ReplicatedStorage:FindFirstChild("CharacterEvents")
local StruggleEvent = CharacterEvents and CharacterEvents:FindFirstChild("Struggle")
local RagdollRemote = CharacterEvents and CharacterEvents:FindFirstChild("RagdollRemote")

local Phantom = {
    Enabled = true,
    Connections = {},
    Processing = false,
    Walking = false
}

local function DisconnectAll()
    for _, conn in pairs(Phantom.Connections) do
        if conn then pcall(function() conn:Disconnect() end) end
    end
    table.clear(Phantom.Connections)
end

local function ApplyPhantom(char)
    if not char or not Phantom.Enabled then return end

    local hrp = char:WaitForChild("HumanoidRootPart", 5)
    local hum = char:WaitForChild("Humanoid", 5)
    local head = char:WaitForChild("Head", 5)
    local torso = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
    if not (hrp and hum and head and torso) then return end

    local beingHeld = char:FindFirstChild("BeingHeld")
    local wasRagdolled = false

    Phantom.Connections["Limb"] = RunService.Heartbeat:Connect(function()
        local ragdolled = hum:FindFirstChild("Ragdolled")
        if ragdolled and ragdolled.Value then
            wasRagdolled = true
            for _, name in ipairs({"Left Arm", "Right Arm", "Left Leg", "Right Leg"}) do
                local limb = char:FindFirstChild(name)
                if limb then
                    if name:find("Arm") then
                        limb.CFrame = torso.CFrame * CFrame.new(name == "Left Arm" and -1.5 or 1.5, 0, 0)
                    else
                        limb.CFrame = torso.CFrame * CFrame.new(name == "Left Leg" and -0.5 or 0.5, -2, 0)
                    end
                    limb.CanCollide = false
                end
            end
        elseif wasRagdolled then
            wasRagdolled = false
            for _, name in ipairs({"Left Arm", "Right Arm", "Left Leg", "Right Leg"}) do
                local limb = char:FindFirstChild(name)
                if limb then limb.CanCollide = true end
            end
        end
    end)

    Phantom.Connections["Head"] = head.ChildAdded:Connect(function(child)
        if child.Name ~= "PartOwner" then return end
        if Phantom.Processing then return end

        Phantom.Processing = true
        hum.Sit = false

        pcall(function() StruggleEvent:FireServer(LocalPlayer) end)

        task.spawn(function()
            while (head and head:FindFirstChild("PartOwner")) or (beingHeld and beingHeld.Value) do
                pcall(function() StruggleEvent:FireServer(LocalPlayer) end)
                pcall(function() RagdollRemote:FireServer(hrp, 0) end)
                task.wait()
            end
        end)

        task.spawn(function()
            hrp.Anchored = true
            if not Phantom.Walking then
                Phantom.Walking = true
                while (head and head:FindFirstChild("PartOwner")) or (beingHeld and beingHeld.Value) do
                    hrp.CFrame = hrp.CFrame + hum.MoveDirection * 0.43
                    task.wait()
                end
            end
            hrp.Anchored = false
            Phantom.Processing = false
            Phantom.Walking = false
        end)
    end)

    local weldHRP = hrp:FindFirstChild("WeldHRP")
    if weldHRP then
        Phantom.Connections["Weld"] = weldHRP:GetPropertyChangedSignal("Enabled"):Connect(function()
            if weldHRP.Enabled then
                task.spawn(function()
                    while weldHRP.Enabled and task.wait() do
                        hum.Sit = false
                        hum.AutoRotate = true
                        hum.HipHeight = 0
                        pcall(function() head.CFrame = hrp.CFrame + Vector3.new(0, 1.35, 0) end)
                    end
                    hum.HipHeight = 0
                end)
            end
        end)
    end
end

DisconnectAll()
ApplyPhantom(LocalPlayer.Character)
Phantom.Connections["Char"] = LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.6)
    DisconnectAll()
    ApplyPhantom(char)
end)
