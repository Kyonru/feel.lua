local feelLove = require("feel.love")

local W = 960
local H = 640

return {
	W = W,
	H = H,
	fx = feelLove.new({ width = W, height = H, shakeAmount = 7, flashAmount = 0.35 }),
}
