--!optimize 2
--!strict

-- Written by @NoahIsADeveloper
-- Disconnecting listeners in callbacks will still run the listener if said listener is the next one in the chain. Unsure as to a fix. Why would you be doing this anyways?
-- Listeners are called in the order they are connected in (FIFO)
-- Arguments are not cloned

-- // Constants
local CONNECTION_POOL_MAX_SIZE = 64

-- // Connection
export type Callback = (self: Connection, ...any) -> ()

local ConnectionPool = table.create(CONNECTION_POOL_MAX_SIZE) :: {Connection}
local Connection = {} :: Connection
Connection.__index = Connection
export type Connection = typeof(setmetatable({} :: {
	__index: Connection,

	_callback: Callback?,
	_connected: boolean,
	_next: Connection?,
	_last: Connection?,

	IsConnected: (self: Connection) -> (boolean),
	Disconnect: (self: Connection) -> (),
}, Connection))

function Connection:IsConnected(): (boolean)
	return self._connected
end

function Connection:Disconnect(): ()
	if not self._connected then error("cannot disconnect Connection that is not connected") end

	local last = self._last
	if last then
		last._next = self._next
		self._last = nil
	end

	self._connected = false
	self._callback = nil
	self._next = nil

	if #ConnectionPool < CONNECTION_POOL_MAX_SIZE then
		table.insert(ConnectionPool, self)
	end
end

local function CreateConnection(callback: Callback): (Connection)
	local object = (table.remove(ConnectionPool) or setmetatable({
		_next = nil,
		_last = nil,
	}, Connection)) :: any

	object._callback = callback
	object._connected = true

	return object
end

-- // Signal
local Signal = {} :: Signal
Signal.__index = Signal
export type Signal = typeof(setmetatable({} :: {
	__index: Signal,

	_head: Connection?,
	_tail: Connection?,

	HasConnections: (self: Signal) -> (boolean, number),
	GetConnections: (self: Signal) -> ({Connection}),
	GetConnectionCount: (self: Signal) -> (number),

	Connect: (self: Signal, callback: Callback) -> (Connection),
	Once: (self: Signal, callback: Callback) -> (Connection),
	Wait: (self: Signal, timeout: number) -> (...any),

	Disconnect: (self: Signal, callback: Callback, disconnectAll: boolean?) -> (),
	DisconnectAll: (self: Signal) -> (),

	Listen: (self: Signal, signal: RBXScriptSignal) -> (RBXScriptConnection),
	Fire: (self: Signal, ...any) -> (),

	Destroy: (self: Signal) -> (),
}, Signal))

function Signal:HasConnections(): (boolean, number)
	if self._head == nil then return false, 0 end

	local connections = 0
	local connection = self._head

	while connection do
		connections += 1
		connection = connection._next :: any
	end

	return true, connections
end

function Signal:GetConnectionCount(): (number)
	local _, count = self:HasConnections()
	return count
end

function Signal:GetConnections(): ({Connection})
	local connections = {}
	local connection = self._head

	while connection do
		table.insert(connections, connection)
		connection = connection._next
	end

	return connections
end

function Signal:DisconnectAll(): ()
	local connection = self._head

	while connection do
		local next = connection._next
		connection:Disconnect()
		connection = next
	end

	self._head = nil
	self._tail = nil
end

function Signal:Connect(callback: Callback): (Connection)
	if type(callback) ~= "function" then error(`argument 1 of :Connect(callback: Callback) expected function got {typeof(callback)}`) end

	local connection = CreateConnection(callback)
	local tail = self._tail

	if tail then
		connection._last = tail
		tail._next = connection
	else
		self._head = connection
	end

	self._tail = connection
	return connection
end

function Signal:Disconnect(callback: Callback, disconnectAll: boolean?): ()
	if type(callback) ~= "function" then error(`argument 1 of :Disconnect(callback: Callback) expected function got {typeof(callback)}`) end
	local connection = self._head

	while connection do
		local next = connection._next

		if connection._callback == callback then
			connection:Disconnect()
			if not disconnectAll then break end
		end

		connection = next
	end
end

function Signal:Wait(timeout: number): (...any)
	local thread = coroutine.running()

	local connection
	connection = self:Connect(function(_, ...: any)
		connection:Disconnect()
		task.spawn(thread, ...)
	end)

	if timeout then
		task.delay(timeout, function()
			if connection:IsConnected() then
				connection:Disconnect()
				task.spawn(thread)
			end
		end)
	end

	return coroutine.yield()
end

function Signal:Once(callback: Callback): (Connection)
	return self:Connect(function(connection: Connection, ...: any)
		connection:Disconnect()
		callback(connection, ...)
	end)
end

function Signal:Fire(...: any): ()
	local connection = self._head
	while connection do
		local callback = connection._callback
		local next = connection._next

		if connection._connected and callback then
			local success, errorMessage = pcall(task.spawn, callback, connection, ...)
			if not success then
				warn(`{debug.traceback(errorMessage)}`)
			end
		end

		connection = next
	end
end

function Signal:Listen(signal: RBXScriptSignal): (RBXScriptConnection)
	if typeof(signal) ~= "RBXScriptSignal" then error(`argument 1 of :Listen(signal: RBXScriptSignal) expected RBXScriptSignal got {typeof(signal)}`) end

	return signal:Connect(function(...)
		self:Fire(...)
	end)
end

function Signal:Destroy()
	self:DisconnectAll()
	setmetatable(self :: any, nil)
	table.clear(self :: any)
end

local function CreateSignal(): (Signal)
	local object = setmetatable({
		_head = nil,
		_tail = nil,
	}, Signal) :: any

	return object
end

return {
	new = CreateSignal,
	from = function(signal: RBXScriptSignal)
		if typeof(signal) ~= "RBXScriptSignal" then error(`argument 1 of .from(signal: RBXScriptSignal) expected RBXScriptSignal got {typeof(signal)}`) end

		local object = CreateSignal()

		local connection = signal:Connect(function(...)
			object:Fire(...)
		end) :: RBXScriptConnection

		return object, connection
	end
}