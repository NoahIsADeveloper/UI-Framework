local Slate = {}
Slate.__index
export type Slate = typeof(setmetatable({} :: {}, Slate))

function Slate.new()
	local object = setmetatable(Slate, {})

	return object
end

return Slate