--!optimize 2
--!strict

local Element = {}

function Element.new()
	local object = setmetatable({
		_children = {}
	}, Element)

	return object
end

return Element