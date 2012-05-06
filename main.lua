io.output():setvbuf("no")

local storyboard = require "storyboard"
local facebook   = require "facebook"
local net        = require "net"

function display.center (obj)
	obj.x, obj.y = display.contentCenterX, display.contentCenterY
end

function display.zero (obj)
	obj.x, obj.y = 0, 0
end

local function onSystemEvent (event)
	if event.type == "applicationSuspend" then
		collectgarbage("collect")
	elseif event.type == "applicationExit" then
		facebook.logout()
	end
end
Runtime:addEventListener("system", onSystemEvent)

display.setStatusBar(display.HiddenStatusBar)

--net.init()
--net.join(1, 2)

storyboard.gotoScene("menu.scene", {
	params = {
		myId = 1
	}
})
