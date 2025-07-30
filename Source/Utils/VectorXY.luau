--!optimize 2
--!strict

local VectorXY = {} :: VectorXY
export type VectorXY = typeof(setmetatable({} :: {
	__tostring: (self: VectorXY) -> (string),
	__len: (self: VectorXY) -> (number),
	__unm: (self: VectorXY) -> (VectorXY),

	__eq: (a: VectorXY | any, b: VectorXY | any) -> (boolean),
	__idiv: (a: VectorXY | number, b: VectorXY | number) -> (VectorXY),
	__div: (a: VectorXY | number, b: VectorXY | number) -> (VectorXY),
	__mul: (a: VectorXY | number, b: VectorXY | number) -> (VectorXY),
	__sub: (a: VectorXY, b: VectorXY) -> (VectorXY),
	__add: (a: VectorXY, b: VectorXY) -> (VectorXY),

	__index: (self: VectorXY, key: any, value: any) -> (any),
	__newindex: (self: VectorXY, key: any, value: any) -> (),

	x: number, y: number,

	unit: VectorXY,
	magnitude: number,

	ToTable: (self: VectorXY) -> ({x: number, y: number}),
	ToVector2: (self: VectorXY) -> (Vector2),
	ToUDim2: (self: VectorXY) -> (UDim2),
	Dot: (self: VectorXY, other: VectorXY) -> (number),
	Lerp: (self: VectorXY, other: VectorXY, alpha: number) -> (VectorXY),
	Clone: (self: VectorXY) -> (VectorXY),
	Rotate: (self: VectorXY, radians: number) -> (VectorXY),
	Angle: (self: VectorXY) -> (number),

	fromVector2: (vector2: Vector2) -> (VectorXY),
	new: (x: number, y: number) -> (VectorXY),
}, VectorXY))

local function isVector(value: any): (boolean)
	return type(value) == "table" and getmetatable(value) == VectorXY
end

local function unpackOperands(a: VectorXY | number, b: VectorXY | number, errorMessage: string): (number, number, number, number)
	local x1, y1, x2, y2

	if isVector(a) then x1 = (a :: VectorXY).x; y1 = (a :: VectorXY).y
	elseif type(a) == "number" then x1 = a; y1 = a
	else error(`{errorMessage} {type(a)}`) end

	if isVector(b) then x2 = (b :: VectorXY).x; y2 = (b :: VectorXY).y
	elseif type(b) == "number" then x2 = b; y2 = b
	else error(`{errorMessage} {type(b)}`) end

	return x1, y1, x2, y2
end

VectorXY.__add = function(a: VectorXY, b: VectorXY): (VectorXY)
	assert(isVector(a), `cannot add VectorXY with {type(a)}`)
	assert(isVector(b), `cannot add VectorXY with {type(b)}`)
	return VectorXY.new(a.x + b.x, a.y + b.y)
end

VectorXY.__sub = function(a: VectorXY, b: VectorXY): (VectorXY)
	assert(isVector(a), `cannot subtract VectorXY with {type(a)}`)
	assert(isVector(b), `cannot subtract VectorXY with {type(b)}`)
	return VectorXY.new(a.x - b.x, a.y - b.y)
end

VectorXY.__mul = function(a: VectorXY | number, b: VectorXY | number): (VectorXY)
	local x1, y1, x2, y2 = unpackOperands(a, b, "cannot multiply VectorXY with")
	return VectorXY.new(x1 * x2, y1 * y2)
end

VectorXY.__div = function(a: VectorXY | number, b: VectorXY | number): (VectorXY)
	local x1, y1, x2, y2 = unpackOperands(a, b, "cannot divide VectorXY with")
	return VectorXY.new(x1 / x2, y1 / y2)
end

VectorXY.__idiv = function(a: VectorXY | number, b: VectorXY | number): (VectorXY)
	local x1, y1, x2, y2 = unpackOperands(a, b, "cannot integer divide VectorXY with")
	return VectorXY.new(x1 // x2, y1 // y2)
end

VectorXY.__unm = function(self: VectorXY): (VectorXY)
	return VectorXY.new(-self.x, -self.y)
end

VectorXY.__eq = function(a: VectorXY, b: VectorXY): (boolean)
	return isVector(a) and isVector(b) and a.x == b.x and a.y == b.y
end

VectorXY.__len = function(self: VectorXY): (number)
	return math.sqrt(self.x * self.x + self.y * self.y)
end

VectorXY.__index = function(self: VectorXY, key: any): (any)
	if type(key) == "string" then
		local k = key:lower()

		if k == "x" or k == "y" then
			return self[k]
		elseif k == "magnitude" then
			return #self
		elseif k == "unit" then
			local magnitude = #self
			if magnitude == 0 then return VectorXY.new(0, 0) end
			return VectorXY.new(self.x / magnitude, self.y / magnitude)
		end
	end

	return rawget(self :: any, key:lower()) or VectorXY[key]
end

VectorXY.__newindex = function(self: VectorXY, key: any, value: any): ()
	assert(type(key) == "string" and (key:lower() == "x" or key:lower() == "y"), `cannot set property '{key}' of VectorXY`)
	assert(type(value) == "number", `cannot set property '{key}' of VectorXY to {type(value)}`)

	rawset(self :: any, key:lower(), value)
end

VectorXY.__tostring = function(self: VectorXY): (string)
	return `VectorXY({self.x}, {self.y})`
end

function VectorXY:InBoundingBox(position: VectorXY, size: VectorXY): (boolean)
	assert(isVector(position), `argument 1 of VectorXY:InBoundingBox() expected VectorXY got {type(position)}`)
	assert(isVector(size), `argument 2 of VectorXY:InBoundingBox() expected VectorXY got {type(size)}`)

	return
		self.x >= position.x and
		self.x <= position.y + size.y and
		self.y >= position.y and
		self.y <= position.x + size.x
end

function VectorXY:ToVector2(): (Vector2)
	return Vector2.new(self.x, self.y)
end

function VectorXY:ToUDim2(): (UDim2)
	return UDim2.new(0, self.x, 0, self.y)
end

function VectorXY:ToTable(): ({x: number, y: number})
	return {x = self.x, y = self.y}
end

function VectorXY:Angle(): (number)
	return math.atan2(self.y, self.x)
end

function VectorXY:Clone(): (VectorXY)
	return VectorXY.new(self.x, self.y)
end

function VectorXY:Dot(other: VectorXY): (number)
	assert(isVector(other), `cannot get the dot product of VectorXY and {type(other)}`)

	return self.x * other.x + self.y * other.y
end

function VectorXY:Lerp(other: VectorXY, alpha: number): (VectorXY)
	assert(isVector(other), `cannot interpolate VectorXY into {type(other)}`)
	assert(type(alpha) == "number", `argument 2 of VectorXY:Lerp() expected number got {type(alpha)}`)

	return VectorXY.new(
		self.x + (other.x - self.x) * alpha,
		self.y + (other.y - self.y) * alpha
	)
end

function VectorXY:Rotate(radians: number, pivot: VectorXY?): VectorXY
	assert(type(radians) == "number", `argument 1 of VectorXY:Rotate() expected number got {type(radians)}`)
	assert(isVector(pivot) or pivot == nil, `argument 2 of VectorXY:Rotate() expected VectorXY? got {type(pivot)}`)

	local translated = if pivot then self - pivot else self
	local cos = math.cos(radians)
	local sin = math.sin(radians)

	local rotated = VectorXY.new(
		translated.x * cos - translated.y * sin,
		translated.x * sin + translated.y * cos
	)

	return if pivot then rotated + pivot else rotated
end

function VectorXY.fromVector2(vector2: Vector2): (VectorXY)
	assert(typeof(vector2) == "Vector2", `argument 1 of VectorXY.fromVector2() expected number got {type(vector2)}`)

	local object = setmetatable({
		x = vector2.X or 0,
		y = vector2.Y or 0,
	}, VectorXY) :: VectorXY

	return object
end

function VectorXY.new(x: number?, y: number?): (VectorXY)
	assert(type(x) == "nil" or type(x) == "number", `argument 1 of VectorXY.new() expected number got {type(x)}`)
	assert(type(y) == "nil" or type(y) == "number", `argument 2 of VectorXY.new() expected number got {type(y)}`)

	local object = setmetatable({
		x = x or 0,
		y = y or 0,
	}, VectorXY) :: VectorXY

	return object
end

return VectorXY
