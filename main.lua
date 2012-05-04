io.output():setvbuf("no")

local storyboard = require "storyboard"
local net        = require "net"

function display.center (obj)
	obj.x, obj.y = display.contentCenterX, display.contentCenterY
end

function display.zero (obj)
	obj.x, obj.y = 0, 0
end

display.setStatusBar(display.HiddenStatusBar)

net.init()

local net = require "net"
net.join(1)

storyboard.gotoScene("game.scene", {
	params = {
		myId = 1
	}
})
