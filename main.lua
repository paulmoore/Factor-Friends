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

display.contentBgWidth  = 760
display.contentBgHeight = 1140

display.contentBleedWidth  = (display.contentBgWidth - display.contentWidth) / 2
display.contentBleedHeight = (display.contentBgHeight - display.contentHeight) / 2

local function onSystemEvent (event)
	if event.type == "applicationSuspend" then
		collectgarbage("collect")
	elseif event.type == "applicationExit" then
		facebook.logout()
	end
end
Runtime:addEventListener("system", onSystemEvent)

display.setStatusBar(display.HiddenStatusBar)

net.init()

storyboard.gotoScene("menu.scene")
