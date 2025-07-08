--!optimize 2
--!strict

local VectorXY = require("./VectorXY")

local FlexXY = {} :: FlexXY
FlexXY.__index = FlexXY
export type FlexXY = typeof(setmetatable({} :: {
	__index: FlexXY,

	scale: VectorXY.VectorXY,
	offset: VectorXY.VectorXY,

	ToOffset: (self: FlexXY, frameSize: VectorXY.VectorXY?) -> (VectorXY.VectorXY),
	ToScale: (self: FlexXY, frameSize: VectorXY.VectorXY?) -> (VectorXY.VectorXY),
	ToUDim2: (self: FlexXY) -> (UDim2),

	fromUDim2: (udim: UDim2) -> (FlexXY),
	new: (scaleX: number?, offsetX: number?, scaleY: number?, offsetY: number?) -> (FlexXY)
}, FlexXY))

function FlexXY:ToUDim2(): (UDim2)
	return UDim2.new(self.scale.X, self.offset.X, self.scale.Y, self.offset.Y)
end

function FlexXY:ToScale(frameSize: VectorXY.VectorXY?): (VectorXY.VectorXY)
	return self.scale + self.offset / (frameSize or VectorXY.fromVector2(workspace.CurrentCamera.ViewportSize))
end

function FlexXY:ToOffset(frameSize: VectorXY.VectorXY?): (VectorXY.VectorXY)
	return self.offset + self.scale * (frameSize or VectorXY.fromVector2(workspace.CurrentCamera.ViewportSize))
end

function FlexXY.fromUDim2(udim: UDim2): (FlexXY)
	local object = setmetatable({
		scale = VectorXY.new(udim.X.Scale, udim.Y.Scale),
		offset = VectorXY.new(udim.X.Offset, udim.Y.Offset)
	}, FlexXY) :: any

	return object
end

function FlexXY.new(scaleX: number?, offsetX: number?, scaleY: number?, offsetY: number?): (FlexXY)
	local object = setmetatable({
		scale = VectorXY.new(scaleX or 0, scaleY or 0),
		offset = VectorXY.new(offsetX or 0, offsetY or 0),
	}, FlexXY) :: any

	return object
end

return FlexXY