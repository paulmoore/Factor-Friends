--- main.lua
--
-- Factor Friends application entry point.
--
-- @author Paul Moore
--
-- Copyright (c) 2012 Strange Ideas Software
--
-- This file is part of Factor Friends.
--
-- Factor Friends is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
-- 
-- Factor Friends is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU General Public License
-- along with Factor Friends.  If not, see <http://www.gnu.org/licenses/>.

io.output():setvbuf("no")
display.setStatusBar(display.HiddenStatusBar)

local storyboard = require "storyboard"
local net        = require "net"

-- Set up some useful utility display variables and functions
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

--- Login status won't persist after an application exit, to make things simpler for now.
local function onSystemEvent (event)
	if event.type == "applicationSuspend" then
		collectgarbage("collect")
	elseif event.type == "applicationExit" then
		net.logout()
	end
end
Runtime:addEventListener("system", onSystemEvent)

--- Reduce the likelyhood of an app load timeout by placing the scene loading/transition on the first frame.
local function onEnterFrame (event)
	Runtime:removeEventListener("enterFrame", onEnterFrame)
	storyboard.gotoScene("menu.scene")
end
Runtime:addEventListener("enterFrame", onEnterFrame)

net.init()

-- Memory debugging.
--[[local statusText = native.newTextBox(0, display.contentHeight - 75, 275, 75)
statusText:setTextColor(0x00, 0x00, 0x00)
statusText.hasBackground = true
local function dround (num, idp)
  local mult = 10 ^ (idp or 0)
  return math.floor(num * mult + 0.5) / mult
end
local function onStatusUpdate ()
	local info = "Memory: "..dround(collectgarbage("count") / 1000, 4).."mB\nTexture: "..dround(system.getInfo("textureMemoryUsed") / 1000000, 4).."mB"
	statusText.text = info
end
timer.performWithDelay(1000, onStatusUpdate, 0)]]

-- Facebook test-account generation through the GraphAPI.
--local function onNetworkEvent (event)
--	print(event.response)
--end
--network.request("https://graph.facebook.com/oauth/access_token?client_id=223466991100849&client_secret=a494682afdc51b4ae48782999b94fb21&grant_type=client_credentials", "GET", onNetworkEvent)
--network.request("https://graph.facebook.com/223466991100849/accounts/test-users?name=TestOne&method=post&access_token=223466991100849%7CBcsnPCLA5gZmftlnnYd44wEqHyY", "POST", onNetworkEvent)
--network.request("https://graph.facebook.com/223466991100849/accounts/test-users?name=TestTwo&method=post&access_token=223466991100849%7CBcsnPCLA5gZmftlnnYd44wEqHyY", "POST", onNetworkEvent)
--network.request("https://graph.facebook.com/100003811250248/friends/100003819770108?method=post&access_token=AAADLPfafo7EBAD62qKSmZCD6ZCfQOxkJUcLjPYMNnEqCrH2KZByUN2J815FqZC9k8ZClWtWtoqACE22878JmbuhGuwuSpbbiZCFbc25oT2onTHAKgSH9xr", "POST", onNetworkEvent)
--network.request("https://graph.facebook.com/100003819770108/friends/100003811250248?method=post&access_token=AAADLPfafo7EBAKQA6QvbBvmB4CLt5yZCXeBR2oocxeLDpZARG8if2OlfGzgscxCDBPhZC3Ov4Qrt9xmjPcPHrxq0l2SOowiykVZAxfRo0G03w4FOlAO3", "POST", onNetworkEvent)
