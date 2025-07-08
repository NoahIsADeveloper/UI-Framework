--!optimize 2
--!strict

local Element = {}
Element.__index = Element
export type Element = typeof(setmetatable({} :: {
	new: (parent: Element) -> (Element),
}, Element))

function Element.new(parent: Element)
	local object = setmetatable({
		_parent = parent,
		_children = {}
	}, Element)

	return object
end

return Element