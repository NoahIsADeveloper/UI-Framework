--!optimize 2
--!strict

export type Callback = (self: Connection, ...any) -> ()

local ConnectionPool = table.create(64) :: {Connection}
local Connection = {} :: Connection
Connection.__index = Connection
export type Connection = typeof(setmetatable({} :: {
	__index: Connection,

	_callback: Callback?,
	_connected: boolean,
	_next: Connection?,
	_last: Connection?,

	Disconnect: (self: Connection) -> (),

	new: (callback: Callback) -> (Connection),
}, Connection))

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

	if #ConnectionPool < 64 then
		table.insert(ConnectionPool, self)
	end
end

function Connection.new(callback: Callback): (Connection)
	if type(callback) ~= "function" then error(`argument 1 of :Connect(callback: Callback) expected function got {type(callback)}`) end

	local object = (table.remove(ConnectionPool) or setmetatable({
		_next = nil,
		_last = nil,
	}, Connection)) :: any

	object._callback = callback
	object._connected = true

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
	FireAsync: (self: Signal, ...any) -> (),
	FireSync: (self: Signal, ...any) -> (),
	Fire: (self: Signal, ...any) -> (),

	wrap: (RBXScriptSignal) -> (Signal),
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

function Signal:Connect(callback: Callback): (Connection)
	if type(callback) ~= "function" then error(`argument 1 of :Connect(callback: Callback) expected function got {type(callback)}`) end

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

function Signal:Wait(): (...any)
	local thread = coroutine.running()

	self:Connect(function(connection: Connection, ...: any)
		connection:Disconnect()
		task.spawn(thread, ...)
	end)

	return coroutine.yield()
end

function Signal:Once(callback: Callback): (Connection)
	return self:Connect(function(connection: Connection, ...: any)
		connection:Disconnect()
		callback(connection, ...)
	end)
end

function Signal:FireSync(...: any): ()
	local connection = self._head
	while connection do
		local callback = connection._callback
		if connection._connected and callback then
			callback(connection, ...)
		end
		connection = connection._next
	end
end

function Signal:FireAsync(...: any): ()
	local connection = self._head
	while connection do
		local callback = connection._callback
		if connection._connected and callback then
			task.spawn(callback, connection, ...)
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

Signal.Fire = Signal.FireAsync
return Signal