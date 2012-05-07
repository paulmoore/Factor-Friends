io.output():setvbuf("no")
display.setStatusBar(display.HiddenStatusBar)

local storyboard = require "storyboard"
local net        = require "net"

display.contentBgWidth  = 760
display.contentBgHeight = 1140

display.contentBleedWidth  = (display.contentBgWidth - display.contentWidth) / 2
display.contentBleedHeight = (display.contentBgHeight - display.contentHeight) / 2

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
		net.logout()
	end
end
Runtime:addEventListener("system", onSystemEvent)

local function onEnterFrame (event)
	Runtime:removeEventListener("enterFrame", onEnterFrame)
	storyboard.gotoScene("menu.scene")
	--[[net.login()
	storyboard.gotoScene("game.scene", {
		params = {friend = net.friends()[1], isFirst = true}, effect = "slideRight", time = 500
	})]]
end
Runtime:addEventListener("enterFrame", onEnterFrame)

net.init()

--local function onNetworkEvent (event)
--	print(event.response)
--end
--network.request("https://graph.facebook.com/oauth/access_token?client_id=223466991100849&client_secret=a494682afdc51b4ae48782999b94fb21&grant_type=client_credentials", "GET", onNetworkEvent)
--network.request("https://graph.facebook.com/223466991100849/accounts/test-users?name=TestOne&method=post&access_token=223466991100849%7CBcsnPCLA5gZmftlnnYd44wEqHyY", "POST", onNetworkEvent)
--network.request("https://graph.facebook.com/223466991100849/accounts/test-users?name=TestTwo&method=post&access_token=223466991100849%7CBcsnPCLA5gZmftlnnYd44wEqHyY", "POST", onNetworkEvent)
--network.request("https://graph.facebook.com/100003811250248/friends/100003819770108?method=post&access_token=AAADLPfafo7EBAD62qKSmZCD6ZCfQOxkJUcLjPYMNnEqCrH2KZByUN2J815FqZC9k8ZClWtWtoqACE22878JmbuhGuwuSpbbiZCFbc25oT2onTHAKgSH9xr", "POST", onNetworkEvent)
--network.request("https://graph.facebook.com/100003819770108/friends/100003811250248?method=post&access_token=AAADLPfafo7EBAKQA6QvbBvmB4CLt5yZCXeBR2oocxeLDpZARG8if2OlfGzgscxCDBPhZC3Ov4Qrt9xmjPcPHrxq0l2SOowiykVZAxfRo0G03w4FOlAO3", "POST", onNetworkEvent)
