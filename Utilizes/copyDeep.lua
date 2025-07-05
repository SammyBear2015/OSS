--!strict

--[[
  This module creates and returns a copy of the given table and or nested tables.
  If the type is not a vaild table it just return the value passed into the function
  This uses table.clone, which can preserve metatables, but doesn't clone the metatable.
--]]

local function copyDeep<T>(source: T): T
	if typeof(source) == "table" then
		local copied = table.clone(source)
		for key, value in pairs(copied) do
			if typeof(value) == "table" then
				copied[key] = copyDeep(value)
			end
		end
		return (copied :: any) :: T
	else
		return source
	end
end

return copyDeep
