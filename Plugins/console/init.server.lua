local createSharedToolbar = require(script.createSharedToolbar)
local StudioService = game:GetService("StudioService")
local ActiveScript

local DefaultSource = [=[
--[[
    Custom Console Plugin by: JKbings0099
    Run​Service usage isn't allowed because it can be uncontrolled.
]]

]=]

local toolbarSettings = {} :: createSharedToolbar.SharedToolbarSettings
toolbarSettings.CombinerName = "JKbings0099PluginsToolbar"
toolbarSettings.ToolbarName = "JKbings0099 Plugins"
toolbarSettings.ButtonName = "Console"
toolbarSettings.ButtonIcon = "rbxassetid://83303130309635"
toolbarSettings.ButtonTooltip = ""
toolbarSettings.ClickedFn = function()
    toolbarSettings.Button.ClickableWhenViewportHidden = true
    if ActiveScript and ActiveScript:IsA("LuaSourceContainer") then
        local success, source = pcall(function()
            return ActiveScript.Source
        end)
        
        if success and source:find("Run Service") then
            warn("RunService usage isn't allowed")
            return
        elseif success and source:find("RunService") then
            warn("RunService usage isn't allowed")
            return
        end
        
        loadstring(ActiveScript.Source)()
    else
        ActiveScript = Instance.new("Script", game:GetService("TestService"))
        if game.Players:GetPlayers()[1] then
            ActiveScript.Name = game.Players:GetPlayers()[1].Name .. "_Console"
        else
            ActiveScript.Name = "LocalEnv_Console"
        end
        ActiveScript.Source = DefaultSource
        plugin:OpenScript(ActiveScript, 6)
    end
end

StudioService:GetPropertyChangedSignal("ActiveScript"):Connect(function()
    local Active = StudioService.ActiveScript
    if Active ~= ActiveScript and ActiveScript then
        ActiveScript:Destroy()
        ActiveScript = nil
    end
end)

createSharedToolbar(plugin, toolbarSettings)
toolbarSettings.Button.ClickableWhenViewportHidden = true
