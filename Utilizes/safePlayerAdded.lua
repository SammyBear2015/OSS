--!strict

--[[
  Calls the callback for all already existing players which may be in the game, and any that join aftermath.
	Can be useful if you want to run code for every player, even the players that joined before the script initiated.
--]]

local Players = game:GetService("Players")

local function safePlayerAdded(onPlayerAddedCallback: (Player) -> nil)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(onPlayerAddedCallback, player)
	end
	return Players.PlayerAdded:Connect(onPlayerAddedCallback)
end

return safePlayerAdded
