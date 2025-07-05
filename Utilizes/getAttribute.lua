--!strict

--[[
  Returns the value of the inputed attribute, erros if the attribute
  doesn't exist.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Attribute = require(ReplicatedStorage.Source.SharedConstants.Attribute)

local function getAttribute<T>(instance: Instance, attributeName: Attribute.EnumType): T
	local value = instance:GetAttribute(attributeName)
	assert(value ~= nil, ("%s is not a valid attribute of %s"):format(attributeName, instance:GetFullName()))

	return value
end

return getAttribute
