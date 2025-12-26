local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local IS_SERVER = RunService:IsServer()
local IS_CLIENT = RunService:IsClient()

export type Connection = {
	Disconnect: (self: Connection) -> ()
}

export type Signal<T...> = {
	Connect: (self: Signal<T...>, callback: (T...) -> ()) -> Connection,
	FireServer: (self: Signal<T...>, T...) -> (),
	FireClient: (self: Signal<T...>, player: Player, T...) -> (),
	FireAllClients: (self: Signal<T...>, T...) -> (),
	OnInvoke: (self: Signal<T...>, callback: (T...) -> any) -> (),
	InvokeServer: (self: Signal<T...>, T...) -> any,
	InvokeClient: (self: Signal<T...>, player: Player, T...) -> any,
	Destroy: (self: Signal<T...>) -> (),
}

local SignalCS = {}
SignalCS.__index = SignalCS
SignalCS.__registry = {}

local RemoteFolder = if IS_SERVER 
	then Instance.new("Folder") 
	else ReplicatedStorage:WaitForChild("SignalRemotes", 10)

if IS_SERVER and RemoteFolder then
	RemoteFolder.Name = "SignalRemotes"
	RemoteFolder.Parent = ReplicatedStorage
end

--[[
	SignalCS can only be used
	Client -> Server
	Server -> Client
]]
function SignalCS.new<T...>(signalName: string?): Signal<T...>
	assert(type(signalName) == "string", "Signal name must be a string.")

	if SignalCS.__registry[signalName] then
		return SignalCS.__registry[signalName]
	end

	local self = setmetatable({} :: {any}, SignalCS)

	self._name = signalName
	self._connections = {}
	self._isDestroyed = false
	self._invokeCallback = nil

	if RemoteFolder then
		if IS_SERVER then
			local remote = Instance.new("RemoteEvent")
			remote.Name = signalName
			remote.Parent = RemoteFolder
			self._remoteEvent = remote

			local remoteFunc = Instance.new("RemoteFunction")
			remoteFunc.Name = signalName .. "_Function"
			remoteFunc.Parent = RemoteFolder
			self._remoteFunction = remoteFunc

			remote.OnServerEvent:Connect(function(player, ...)
				for _, callback in ipairs(self._connections) do
					task.spawn(callback, player, ...)
				end
			end)

			remoteFunc.OnServerInvoke = function(player, ...)
				if self._invokeCallback then
					return self._invokeCallback(player, ...)
				else
					warn(`No invoke callback set for Signal: {signalName}`)
					return nil
				end
			end

		elseif IS_CLIENT then
			local remote = RemoteFolder:WaitForChild(signalName, 10)
			if remote and remote:IsA("RemoteEvent") then
				self._remoteEvent = remote

				remote.OnClientEvent:Connect(function(...)
					for _, callback in ipairs(self._connections) do
						task.spawn(callback, ...)
					end
				end)
			else
				warn(`Failed to find RemoteEvent for Signal: {signalName}`)
			end

			local remoteFunc = RemoteFolder:WaitForChild(signalName .. "_Function", 10)
			if remoteFunc and remoteFunc:IsA("RemoteFunction") then
				self._remoteFunction = remoteFunc

				remoteFunc.OnClientInvoke = function(...)
					if self._invokeCallback then
						return self._invokeCallback(...)
					else
						warn(`No invoke callback set for Signal: {signalName}`)
						return nil
					end
				end
			else
				warn(`Failed to find RemoteFunction for Signal: {signalName}`)
			end
		end
	end

	SignalCS.__registry[signalName] = self

	return self :: Signal<T...>
end

function SignalCS:Connect<T...>(callback: (T...) -> ()): Connection
	assert(typeof(callback) == "function", "Connect expects a function")
	assert(not self._isDestroyed, "Cannot connect to a destroyed Signal")

	table.insert(self._connections, callback)

	local disconnected = false
	local connection = {}

	function connection.Disconnect()
		if disconnected or self._isDestroyed then return end
		disconnected = true

		for i, storedCallback in ipairs(self._connections) do
			if storedCallback == callback then
				table.remove(self._connections, i)
				break
			end
		end
	end

	return connection :: Connection
end

function SignalCS:FireServer<T...>(...: T...)
	if self._isDestroyed then
		warn("Attempted to FireServer on a destroyed Signal")
		return
	end

	if not IS_CLIENT then
		warn("FireServer can only be called from the client")
		return
	end

	if self._remoteEvent then
		self._remoteEvent:FireServer(...)
	end
end

function SignalCS:FireClient<T...>(player: Player, ...: T...)
	if self._isDestroyed then
		warn("Attempted to FireClient on a destroyed Signal")
		return
	end

	if not IS_SERVER then
		warn("FireClient can only be called from the server")
		return
	end

	if self._remoteEvent then
		self._remoteEvent:FireClient(player, ...)
	end
end

function SignalCS:FireAllClients<T...>(...: T...)
	if self._isDestroyed then
		warn("Attempted to FireAllClients on a destroyed Signal")
		return
	end

	if not IS_SERVER then
		warn("FireAllClients can only be called from the server")
		return
	end

	if self._remoteEvent then
		self._remoteEvent:FireAllClients(...)
	end
end

function SignalCS:OnInvoke<T...>(callback: (T...) -> any)
	assert(typeof(callback) == "function", "OnInvoke expects a function")
	assert(not self._isDestroyed, "Cannot set OnInvoke on a destroyed Signal")

	self._invokeCallback = callback
end

function SignalCS:InvokeServer<T...>(...: T...): any
	if self._isDestroyed then
		warn("Attempted to InvokeServer on a destroyed Signal")
		return nil
	end

	if not IS_CLIENT then
		warn("InvokeServer can only be called from the client")
		return nil
	end

	if self._remoteFunction then
		return self._remoteFunction:InvokeServer(...)
	end

	return nil
end

function SignalCS:InvokeClient<T...>(player: Player, ...: T...): any
	if self._isDestroyed then
		warn("Attempted to InvokeClient on a destroyed Signal")
		return nil
	end

	if not IS_SERVER then
		warn("InvokeClient can only be called from the server")
		return nil
	end

	if self._remoteFunction then
		return self._remoteFunction:InvokeClient(player, ...)
	end

	return nil
end

function SignalCS:Destroy()
	self._connections = {}
	self._isDestroyed = true
	self._invokeCallback = nil

	if IS_SERVER then
		if self._remoteEvent then
			self._remoteEvent:Destroy()
		end
		if self._remoteFunction then
			self._remoteFunction:Destroy()
		end
	end

	SignalCS.__registry[self._name] = nil
end

return SignalCS
