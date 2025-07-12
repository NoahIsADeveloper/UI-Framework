local Element = require("./Element")

local Frame = table.clone(Element) :: Frame
export type Frame = {
	color: Color3,
} & Element.Element

function Frame:DefineProperties(): ()
	Element.DefineProperties(self)
	self.color = Color3.new(1, 1, 1)
end

function Frame:Render(): ()
	
end

return Frame