--!optimize 2
--!strict

local Element = require("./Element")

local Container = table.clone(Element) :: Container
export type Container = {
	color: Color3,
} & Element.Element

function Container:DefineProperties(): ()
	(self :: Container).color = Color3.new(1, 1, 1)

	Element.DefineProperties(self)
end

function Container:Render(): ()
	
end

return Container