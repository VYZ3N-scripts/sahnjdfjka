local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local SoundService = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer

local variants = {
	"BlackHoleKick",
	"BlackHoleDetected",
	"BlackHole",
	"Black_Hole",
	"Blackhole",
	"Black-Hole",
	"BHole",
	"BH",
	"VoidHole",
	"Void",
	"VoidSphere",
	"DarkHole",
	"DarkSphere",
	"DarkOrb",
	"GravityHole",
	"GravityOrb",
	"SpaceHole",
	"SpaceOrb",
	"Singularity",
	"SingularityOrb",
	"EventHorizon",
	"BlackSphere",
	"Anomaly",
	"AnomalyHole",
	"SupermassiveHole",
	"QuantumHole",
}

local variantSet = {}
for _, n in ipairs(variants) do
	variantSet[n] = true
end

local function playKickSound()
	local s = Instance.new("Sound")
	s.SoundId = "rbxassetid://79150789336480"
	s.Volume = 5
	s.PlayOnRemove = true
	s.Parent = SoundService
	s:Destroy()
end

local function notifyKick(displayName, username)
	print("[KickDetect]", displayName .. " (" .. username .. ") has been kicked")
end

local function getClosestPlayer(pos)
	local closestPlr = nil
	local closestDist = math.huge
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and plr.Character then
			local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				local dist = (hrp.Position - pos).Magnitude
				if dist < closestDist then
					closestDist = dist
					closestPlr = plr
				end
			end
		end
	end
	return closestPlr
end

local function onKickObject(obj)
	task.wait(0.05)
	local pos
	if obj:IsA("BasePart") then
		pos = obj.Position
	elseif obj:IsA("Model") and obj.PrimaryPart then
		pos = obj.PrimaryPart.Position
	else
		local p = obj:FindFirstChildWhichIsA("BasePart", true)
		if p then pos = p.Position end
	end
	if not pos then return end
	local plr = getClosestPlayer(pos)
	if not plr then return end
	playKickSound()
	notifyKick(plr.DisplayName, plr.Name)
end

Workspace.ChildAdded:Connect(function(obj)
	if obj.Name == "BlackHoleKick" or obj.Name == "BlackHoleDetected" or variantSet[obj.Name] then
		onKickObject(obj)
	end
end)

Workspace.DescendantAdded:Connect(function(obj)
	if obj.Name == "BlackHoleKick" or obj.Name == "BlackHoleDetected" then
		onKickObject(obj)
	end
end)

print("kicking loaded")
