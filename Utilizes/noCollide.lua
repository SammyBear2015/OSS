--[[
  As the name of this file, all this module does is disable collision for players characters
]]

local PhysicsService = game:GetService("PhysicsService")
PhysicsService:RegisterCollisionGroup("Player")
PhysicsService:CollisionGroupSetCollidable("Player", "Player", false)

return function(Character)
	if Character then
		for _, Part in Character:GetChildren() do
			if Part:IsA("BasePart") then
				Part.CollisionGroup = "Player"
			end
		end
	end
end
