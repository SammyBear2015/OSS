--!strict
--[[
	Makes a nice typerwriter effect for guis
  thats all lol.
]]

return function(TextLabel:TextLabel, Sound:any)
	local currenttext = ""
	local skip = false
	local stop = false
	local arrow = 0

	TextLabel.Destroying:Once(function()
		stop = true
	end)

	for i, letter in string.split(TextLabel.Text,"") do
		if stop then break end
		currenttext = currenttext .. letter
		if letter == "<" then skip = true end
		if letter == ">" then skip = false arrow += 1 continue end
		if arrow == 2 then arrow = 0 end
		if skip then continue end
		TextLabel.Text = currenttext .. if arrow == 1 then "</font>" else ""
		if Sound then
			Sound:Play()
		end
		task.wait(0.02)
	end
end
