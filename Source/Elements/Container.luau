--!optimize 2
--!strict

local Element = require("./Element")

local Container = table.clone(Element) :: Container
Container.__index = Container
export type Container = {
	color: Color3,
} & Element.Element

function Container:DefineProperties(): ()
	(self :: Container).color = Color3.new(1, 1, 1)

	Element.DefineProperties(self)
end

function Container:Render(): (Instance)
	local frame = Element.Render(self) :: Frame
	frame.BackgroundColor3 = (self :: Container).color

	return frame
end

return Container
