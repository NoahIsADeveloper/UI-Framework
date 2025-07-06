--!optimize 2
--!strict

export type Callback = (self: Connection, ...any) -> ()

local Connection = {} :: Connection
Connection.__index = Connection
export type Connection = typeof(setmetatable({} :: {
	__index: Connection,

	_callback: Callback?,
	_connected: boolean,
	_signal: Signal,
	_next: Connection?,
	_last: Connection?,

	Disconnect: (self: Connection) -> (),

	new: (signal: Signal, callback: Callback) -> (Connection),
}, Connection))

function Connection:Disconnect(): ()
	assert(self._connected, "cannot disconnect Connection that is not connected")

	self._connected = false
	self._callback = nil

	if not self._last then return end
	self._last._next = self._next
end

function Connection.new(signal: Signal, callback: Callback): (Connection)
	if type(callback) ~= "function" then error(`argument 1 of :Connect(callback: Callback) expected function got {type(callback)}`) end

	local object = setmetatable({
		_callback = callback,
		_connected = true,
		_signal = signal,
		_next = nil,
		_last = nil,
	}, Connection) :: any

	return object
end

local Signal = {} :: Signal
Signal.__index = Signal
export type Signal = typeof(setmetatable({} :: {
	__index: Signal,

	_head: Connection?,
	_tail: Connection?,

	Connect: (self: Signal, callback: Callback) -> (Connection),
	Once: (self: Signal, callback: Callback) -> (Connection),
	DisconnectAll: (self: Signal) -> (),
	Wait: (self: Signal) -> (...any),
	Fire: (self: Signal, ...any) -> (),

	new: () -> (Signal),
}, Signal))

function Signal:DisconnectAll(): ()
	self._head = nil
	self._tail = nil
end

function Signal:Connect(callback: Callback): (Connection)
	if type(callback) ~= "function" then error(`argument 1 of :Connect(callback: Callback) expected function got {type(callback)}`) end

	local connection = Connection.new(self, callback)

	if self._tail then
		connection._last = self._tail
		self._tail._next = connection
	else
		self._head = connection
	end

	self._tail = connection
	return connection
end

function Signal:Wait(): (...any)
	local thread = coroutine.running()

	self:Connect(function(connection: Connection, ...: any)
		connection:Disconnect()
		task.spawn(thread, ...)
	end)

	return coroutine.yield()
end

function Signal:Once(callback: Callback): (Connection)
	local connection = self:Connect(function(connection: Connection, ...: any)
		connection:Disconnect()
		callback(connection, ...)
	end)

	return connection
end

function Signal:Fire(...: any): ()
	local connection = self._head
	while connection do
		if connection._connected then
			task.spawn(function(...: any)
				local callback = connection._callback
				if not callback then return end

				callback(connection, ...)
			end, ...)
		end
		connection = connection._next
	end
end

function Signal.new(): (Signal)
	local object = setmetatable({
		_head = nil,
		_tail = nil,
	}, Signal) :: any

	return object
end

return Signal