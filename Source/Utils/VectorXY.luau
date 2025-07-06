--!optimize 2
--!strict

local VectorXY = {} :: Definition

export type Definition = typeof(setmetatable({} :: {
	x: number, y: number,

	unit: Definition,
	magnitude: number,

	ToTable: (self: Definition) -> {x: number, y: number},
	Dot: (self: Definition, other: Definition) -> number,
	Lerp: (self: Definition, other: Definition, alpha: number) -> Definition,
	Clone: (self: Definition) -> Definition,
	Rotate: (self: Definition, radians: number) -> Definition,
	Angle: (self: Definition) -> number,

	new: (x: number, y: number) -> Definition,

	__tostring: (self: Definition) -> string,
	__len: (self: Definition) -> number,
	__unm: (self: Definition) -> Definition,

	__eq: (a: Definition | any, b: Definition | any) -> boolean,
	__idiv: (a: Definition | number, b: Definition | number) -> Definition,
	__div: (a: Definition | number, b: Definition | number) -> Definition,
	__mul: (a: Definition | number, b: Definition | number) -> Definition,
	__sub: (a: Definition, b: Definition) -> Definition,
	__add: (a: Definition, b: Definition) -> Definition,

	__index: (self: Definition, key: any, value: any) -> any,
	__newindex: (self: Definition, key: any, value: any) -> (),
}, VectorXY))

local function isVector(value: any): boolean
	return type(value) == "table" and getmetatable(value) == VectorXY
end

local function unpackOperands(a: Definition | number, b: Definition | number, errorMessage: string): (number, number, number, number)
	local x1, y1, x2, y2

	if isVector(a) then x1 = (a :: Definition).x; y1 = (a :: Definition).y
	elseif type(a) == "number" then x1 = a; y1 = a
	else error(`{errorMessage} {type(a)}`) end

	if isVector(b) then x2 = (b :: Definition).x; y2 = (b :: Definition).y
	elseif type(b) == "number" then x2 = b; y2 = b
	else error(`{errorMessage} {type(b)}`) end

	return x1, y1, x2, y2
end

VectorXY.__add = function(a: Definition, b: Definition): Definition
	assert(isVector(a), `cannot add VectorXY with {type(a)}`)
	assert(isVector(b), `cannot add VectorXY with {type(b)}`)
	return VectorXY.new(a.x + b.x, a.y + b.y)
end

VectorXY.__sub = function(a: Definition, b: Definition): Definition
	assert(isVector(a), `cannot subtract VectorXY with {type(a)}`)
	assert(isVector(b), `cannot subtract VectorXY with {type(b)}`)
	return VectorXY.new(a.x - b.x, a.y - b.y)
end

VectorXY.__mul = function(a: Definition | number, b: Definition | number): Definition
	local x1, y1, x2, y2 = unpackOperands(a, b, "cannot multiply VectorXY with")
	return VectorXY.new(x1 * x2, y1 * y2)
end

VectorXY.__div = function(a: Definition | number, b: Definition | number): Definition
	local x1, y1, x2, y2 = unpackOperands(a, b, "cannot divide VectorXY with")
	return VectorXY.new(x1 / x2, y1 / y2)
end

VectorXY.__idiv = function(a: Definition | number, b: Definition | number): Definition
	local x1, y1, x2, y2 = unpackOperands(a, b, "cannot integer divide VectorXY with")
	return VectorXY.new(x1 // x2, y1 // y2)
end

VectorXY.__unm = function(self: Definition): Definition
	return VectorXY.new(-self.x, -self.y)
end

VectorXY.__eq = function(a: Definition, b: Definition): boolean
	return isVector(a) and isVector(b) and a.x == b.x and a.y == b.y
end

VectorXY.__len = function(self: Definition): number
	return math.sqrt(self.x * self.x + self.y * self.y)
end

VectorXY.__index = function(self: Definition, key: any): any
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

	return self[key:lower()] or VectorXY[key]
end

VectorXY.__newindex = function(self: Definition, key: any, value: any)
	assert(type(key) == "string" and (key:lower() == "x" or key:lower() == "y"), `cannot set property '{key}' of VectorXY`)
	assert(type(value) == "number", `cannot set property '{key}' of VectorXY to {type(value)}`)

	self[key:lower()] = value
end

VectorXY.__tostring = function(self: Definition): string
	return `VectorXY({self.x}, {self.y})`
end

function VectorXY:InBoundingBox(position: Definition, size: Definition): (boolean)
	return false
end

function VectorXY:ToTable(): {x: number, y: number}
	return {x = self.x, y = self.y}
end

function VectorXY:Angle(): number
	return math.atan2(self.y, self.x)
end

function VectorXY:Clone(): Definition
	return VectorXY.new(self.x, self.y)
end

function VectorXY:Dot(other: Definition): number
	assert(isVector(other), `cannot get the dot product of VectorXY and {type(other)}`)

	return self.x * other.x + self.y * other.y
end

function VectorXY:Lerp(other: Definition, alpha: number): Definition
	assert(isVector(other), `cannot interpolate VectorXY into {type(other)}`)
	assert(type(alpha) == "number", `argument 2 of VectorXY:Lerp() expected number got {type(alpha)}`)

	return VectorXY.new(
		self.x + (other.x - self.x) * alpha,
		self.y + (other.y - self.y) * alpha
	)
end

function VectorXY:Rotate(radians: number): Definition
	assert(type(radians) == "number", `argument 1 of VectorXY:Rotate() expected number got {type(radians)}`)

	local cos = math.cos(radians)
	local sin = math.sin(radians)

	return VectorXY.new(
		self.x * cos - self.y * sin,
		self.x * sin + self.y * cos
	)
end

function VectorXY.new(x: number?, y: number?): Definition
	assert(type(x) == "nil" or type(x) == "number", `argument 1 of VectorXY.new() expected number got {type(x)}`)
	assert(type(y) == "nil" or type(y) == "number", `argument 2 of VectorXY.new() expected number got {type(y)}`)

	local object = setmetatable({
		x = x or 0,
		y = y or 0,
	}, VectorXY) :: Definition

	return object
end

return VectorXY