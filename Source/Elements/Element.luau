--!optimize 2
--!strict

--haha

local Element = {}

function Element.new()
	local object = setmetatable({
		_children = {}
	}, Element)

	return object
end

return Element