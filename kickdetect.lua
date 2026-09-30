local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local enabled = true
local lastNotify = {}
local NOTIFY_COOLDOWN = 4

local function notify(msg)
	print("[KickDetect]", msg)
end

local function canNotify(key)
	local now = tick()
	if (lastNotify[key] or 0) + NOTIFY_COOLDOWN > now then
		return false
	end
	lastNotify[key] = now
	return true
end

local function ownerOfToyFolder(folder)
	if not folder then return nil end
	local name = folder.Name
	if name:find("SpawnedInToys") then
		return name:gsub("SpawnedInToys", "")
	end
	return nil
end

local function watchBlobman(blobman, ownerName)
	if not blobman or blobman:GetAttribute("KickDetectWatched") then return end
	blobman:SetAttribute("KickDetectWatched", true)

	local function onGrabSignal()
		if not enabled then return end
		local key = "blob:" .. tostring(ownerName)
		if canNotify(key) then
			notify((ownerName or "Someone") .. " is using Blobman kick")
		end
	end

	for _, d in ipairs(blobman:GetDescendants()) do
		if d:IsA("RemoteEvent") or d:IsA("RemoteFunction") then
			local n = string.lower(d.Name)
			if n:find("grab") or n:find("creature") or n:find("drop") then
				pcall(function()
					if d:IsA("RemoteEvent") then
						d.OnClientEvent:Connect(onGrabSignal)
					end
				end)
			end
		end
	end

	local seat = blobman:FindFirstChild("VehicleSeat", true) or blobman:FindFirstChildWhichIsA("VehicleSeat", true)
	if seat then
		seat:GetPropertyChangedSignal("Occupant"):Connect(function()
			if not enabled then return end
			if seat.Occupant and ownerName and ownerName ~= LocalPlayer.Name then
				local key = "seat:" .. ownerName
				if canNotify(key) then
					notify(ownerName .. " sat in Blobman (kick ready)")
				end
			end
		end)
	end

	task.spawn(function()
		while enabled and blobman.Parent do
			local left = blobman:FindFirstChild("LeftDetector", true)
			local right = blobman:FindFirstChild("RightDetector", true)
			for _, det in ipairs({ left, right }) do
				if det and det:IsA("BasePart") then
					for _, p in ipairs(Players:GetPlayers()) do
						if p ~= LocalPlayer and p.Name ~= ownerName and p.Character then
							local hrp = p.Character:FindFirstChild("HumanoidRootPart")
							if hrp and (hrp.Position - det.Position).Magnitude < 8 then
								local key = "near:" .. tostring(ownerName) .. ":" .. p.Name
								if canNotify(key) then
									notify((ownerName or "?") .. " Blobman near " .. p.Name .. " (possible kick)")
								end
							end
						end
					end
				end
			end
			task.wait(0.4)
		end
	end)
end

local function scanToysFolder(folder)
	if not folder then return end
	local ownerName = ownerOfToyFolder(folder)
	for _, child in ipairs(folder:GetChildren()) do
		if child.Name == "CreatureBlobman" or child.Name:find("Blobman") then
			watchBlobman(child, ownerName)
		end
	end
	folder.ChildAdded:Connect(function(child)
		if not enabled then return end
		if child.Name == "CreatureBlobman" or child.Name:find("Blobman") then
			task.wait(0.1)
			watchBlobman(child, ownerName)
			if ownerName and ownerName ~= LocalPlayer.Name and canNotify("spawn:" .. ownerName) then
				notify(ownerName .. " spawned Blobman")
			end
		end
	end)
end

for _, child in ipairs(Workspace:GetChildren()) do
	if child.Name:find("SpawnedInToys") then
		scanToysFolder(child)
	end
end

Workspace.ChildAdded:Connect(function(child)
	if child.Name:find("SpawnedInToys") then
		task.wait(0.1)
		scanToysFolder(child)
	end
end)

Workspace.DescendantAdded:Connect(function(obj)
	if not enabled then return end
	if obj.Name ~= "GrabParts" then return end
	task.spawn(function()
		task.wait(0.05)
		local grabPart = obj:FindFirstChild("GrabPart")
		if not grabPart then return end
		local weld = grabPart:FindFirstChildOfClass("WeldConstraint")
		if not weld or not weld.Part1 then return end
		local victimPart = weld.Part1
		local victimChar = victimPart.Parent
		local victimPlayer = victimChar and Players:GetPlayerFromCharacter(victimChar)
		if not victimPlayer then return end

		local attackerName = nil
		local po = victimPart:FindFirstChild("PartOwner")
		if po and po:IsA("StringValue") and po.Value ~= "" then
			attackerName = po.Value
		end
		if not attackerName then
			local best, bestDist = nil, math.huge
			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= victimPlayer and p.Character then
					local hrp = p.Character:FindFirstChild("HumanoidRootPart")
					if hrp then
						local d = (hrp.Position - victimPart.Position).Magnitude
						if d < bestDist then
							bestDist = d
							best = p.Name
						end
					end
				end
			end
			if best and bestDist < 30 then
				attackerName = best
			end
		end

		local key = "grab:" .. tostring(attackerName) .. ":" .. victimPlayer.Name
		if canNotify(key) then
			notify((attackerName or "Someone") .. " grabbed " .. victimPlayer.Name .. " (possible kick)")
		end

		local startY = victimPart.Position.Y
		task.wait(0.35)
		if victimPart and victimPart.Parent then
			local dy = victimPart.Position.Y - startY
			if dy > 80 or victimPart.Position.Y > 200 or victimPart.Position.Y < -50 then
				local key2 = "fling:" .. tostring(attackerName) .. ":" .. victimPlayer.Name
				if canNotify(key2) then
					notify((attackerName or "Someone") .. " flung/kicked " .. victimPlayer.Name)
				end
			end
		end
	end)
end)

local g = (getgenv and getgenv()) or _G
function g.StopKickDetect()
	enabled = false
	notify("stopped")
end
function g.StartKickDetect()
	enabled = true
	notify("watching for kicks")
end

notify("stalking your game for Blobman kicks")
print("kickdetect loaded sonnnn")
