local Slate = {}
Slate.__index = Slate
export type Slate = typeof(setmetatable({} :: {
	__index: Slate,
}, Slate))

function Slate.new()
	local object = setmetatable(Slate, {})

	return object
end

return Slate
