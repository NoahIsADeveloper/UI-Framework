--!optimize 2
--!strict

-- Written by @NoahIsADeveloper
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

	new: (callback: Callback) -> (Connection),
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

function Connection.new(callback: Callback): (Connection)
	if type(callback) ~= "function" then error(`argument 1 of :Connect(callback: Callback) expected function got {typeof(callback)}`) end

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

	Connect: (self: Signal, callback: Callback) -> (Connection),
	Once: (self: Signal, callback: Callback) -> (Connection),
	Disconnect: (self: Signal, callback: Callback) -> (),
	DisconnectAll: (self: Signal) -> (),
	Wait: (self: Signal, timeout: number) -> (...any),
	Fire: (self: Signal, ...any) -> (),
	Listen: (self: Signal, signal: RBXScriptSignal) -> (RBXScriptConnection),
	GetConnections: (self: Signal) -> ({Connection}),

	from: (signal: RBXScriptSignal) -> (Signal),
	new: () -> (Signal),
}, Signal))

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

function Signal:Disconnect(callback: Callback): ()
	if type(callback) ~= "function" then error(`argument 1 of :Connect(callback: Callback) expected function got {typeof(callback)}`) end
	local connection = self._head

	while connection do
		local next = connection._next

		if connection._callback == callback then
			connection:Disconnect()
		end

		connection = next
	end
end

function Signal:GetConnections(): ({Connection})
	local connections = {}
	local connection = self._head

	while connection do
		table.insert(connections, connection)
		connection = connection._next
	end

	return connections;
end

function Signal:Connect(callback: Callback): (Connection)
	if type(callback) ~= "function" then error(`argument 1 of :Connect(callback: Callback) expected function got {typeof(callback)}`) end

	local connection = Connection.new(callback)
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

function Signal.from(signal: RBXScriptSignal): (Signal, RBXScriptConnection)
	if typeof(signal) ~= "RBXScriptSignal" then error(`argument 1 of .from(signal: RBXScriptSignal) expected RBXScriptSignal got {typeof(signal)}`) end

	local object = Signal.new()

	local connection = signal:Connect(function(...)
		object:Fire(...)
	end) :: RBXScriptConnection

	return object, connection
end

function Signal.new(): (Signal)
	local object = setmetatable({
		_head = nil,
		_tail = nil,
	}, Signal) :: any

	return object
end

return Signal