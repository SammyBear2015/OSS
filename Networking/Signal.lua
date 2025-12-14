--[[
  This is a custom signal module that I made in my free time.
]]--

export type Connection = {
	Disconnect: (self: Connection) -> ()
}
export type Signal<T...> = {
	Connect: (self: Signal<T...>, callback: (T...) -> ()) -> Connection,
	Fire: (self: Signal<T...>, T...) -> (),
	Destroy: (self: Signal<T...>) -> (),
	_connections: { (T...) -> () },
	_isDestroyed: boolean,
}

local Signal = {}
Signal.__index = Signal

function Signal.new<T...>() : Signal<T...>
	local self = setmetatable({} :: {any}, Signal)
	
	self._connections = {}
	self._isDestroyed = false
	
	return self :: Signal<T...>
end

function Signal:Connect<T...>(callback: (T...) -> ()): Connection
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

function Signal:Fire<T...>(...: T...)
	if self._isDestroyed then
		warn("Attemped to Fire a destroyed Signal: ", ...)
		return
	end
	
	for _, callback in ipairs(self._connections) do
		task.spawn(callback, ...)
	end
end

function Signal:Destroy()
	self._connections = {}
	self.isDestroyed = true
end

return Signal
