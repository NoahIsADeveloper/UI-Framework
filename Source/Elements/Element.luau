--!optimize 2
--!strict

local Signal = require("../Utils/Signal")

local VectorXY = require("../Utils/VectorXY")
local FlexXY = require("../Utils/FlexXY")

local Element = {} :: Element
Element.__index = Element
export type Element = typeof(setmetatable({} :: {
	__index: Element,

	-- // Properties
	anchorPoint: VectorXY.VectorXY,

	actualSize: FlexXY.FlexXY,
	size: FlexXY.FlexXY,

	actualPosition: FlexXY.FlexXY,
	position: FlexXY.FlexXY,

	parent: Element?,
	children: {Element},

	-- // Signals
	PositionChanged: Signal.Signal,
	SizeChanged: Signal.Signal,
	ParentChanged: Signal.Signal,

	ChildAdded: Signal.Signal,

	-- // Methods
	DefineProperties: (self: Element) -> (),
	DefineSignals: (self: Element) -> (),

	Reparent: (self: Element, parent: Element?) -> (boolean),
	Resize: (self: Element, size: FlexXY.FlexXY) -> (boolean),

	new: (parent: Element) -> (Element),
}, Element))

local function isElement(value: any): (boolean)
	return type(value) == "table" and getmetatable(value) == Element
end

function Element:DefineSignals(): ()
	self.ParentChanged = Signal.new()
	self.SizeChanged = Signal.new()
	self.PositionChanged = Signal.new()
	self.ChildAdded = Signal.new()
end

function Element:DefineProperties(): ()
	self.size = FlexXY.new(0, 100, 0, 100)
	self.position = FlexXY.new(0, 0, 0, 0)
	self.anchorPoint = VectorXY.new(0.5, 0.5)
end

function Element:Resize(size: FlexXY.FlexXY): (boolean)
	--note! would also need to resize children
	--note! also change the actualSize

	local oldSize = self.size

	self.size = size
	self.SizeChanged:Fire(size, oldSize)

	return true
end

function Element:Reparent(parent: Element?): (boolean)
	local oldParent = self.parent
	if oldParent == parent then return false end
	if parent ~= nil and not isElement(parent) then return false end
	--note! would also need to resize children
	--note! also change the actualSize

	if oldParent then
		local index = table.find(oldParent.children, self)
		if index then
			table.remove(oldParent.children, index)
		end
	end

	self.parent = parent

	if parent then
		table.insert(parent.children, self)
		parent.ChildAdded:Fire(self)
	end

	self.ParentChanged:Fire(parent, oldParent)

	return true
end

function Element.new(parent: Element): (Element)
	local object = setmetatable({
		parent = nil,
		children = {},
	}, Element) :: any

	object:DefineSignals()
	object:DefineProperties()

	object:Reparent(parent)

	return object
end

return Element