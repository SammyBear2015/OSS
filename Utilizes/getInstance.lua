--!strict

--[[
  This model just returns the instance corresponding with the given path of object names. Will error if instance doesn't exist.
  Can be useful for accessing Instance trees generated at runtime in strict mode

  For Example:
  local helmet: Model = getInstance(rootInstance, "Racer", "Helmet")
--]]

local function getInstance<T>(instance: Instance, ...: string): T
	for _, childName in ipairs({ ... }) do
		local child = instance:FindFirstChild(childName)
		assert(child, string.format("%s is not a child of %s", childName, instance:GetFullName()))
		instance = child
	end
  
	return (instance :: any) :: T
end

return getInstance
