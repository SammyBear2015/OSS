--[[
  I mean it formats a number

  for example:
  formatNumber(9000) returns 9,000
]]

--!strict

local function formatNumber(Money: number)
	local formatted = tostring(Money)

	while true do
		local newFormatted, substitutions = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
		formatted = newFormatted
		if substitutions == 0 then
			break
		end
	end

	return formatted
end

return formatNumber
