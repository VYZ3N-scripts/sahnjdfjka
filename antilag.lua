local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local playerScripts = LocalPlayer:FindFirstChild("PlayerScripts")
	or LocalPlayer:WaitForChild("PlayerScripts", 5)
local anticreatelinelocalscript = playerScripts
	and playerScripts:FindFirstChild("CharacterAndBeamMove")

local AntiLagEnabled = true

local function setAntiLag(on)
	AntiLagEnabled = on and true or false
	if anticreatelinelocalscript then
		anticreatelinelocalscript.Disabled = AntiLagEnabled
	end
end

setAntiLag(true)

LocalPlayer.CharacterAdded:Connect(function()
	task.defer(function()
		playerScripts = LocalPlayer:FindFirstChild("PlayerScripts")
			or LocalPlayer:WaitForChild("PlayerScripts", 5)
		anticreatelinelocalscript = playerScripts
			and playerScripts:FindFirstChild("CharacterAndBeamMove")
		if AntiLagEnabled and anticreatelinelocalscript then
			anticreatelinelocalscript.Disabled = true
		end
	end)
end)
