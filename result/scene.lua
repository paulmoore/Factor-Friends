--- scene.lua
--
-- This is the ending scene for a game.  Displays the winner/loser and final scores.
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

local storyboard = require "storyboard"
local net        = require "net"

local scene = storyboard.newScene()

local bg
local myText, friendText

local resultSound

local function onTapEvent ()
	storyboard.gotoScene("menu.scene", "slideRight", 500)
end

-- Called when the scene's view does not exist:
local function onCreateScene (event)
	resultSound = audio.loadSound("res/audio/result_sfx.wav")
end

-- Called BEFORE scene has moved onscreen:
local function onWillEnterScene (event)
	local params = event.params
	bg = display.newImage(scene.view, "res/img/result_splash_"..params.winner..".png", 0, 0, true)
	display.center(bg)
	
	myText = display.newText(scene.view, net.user().name.."\nScore: "..params.myScore, 0, 0, 500, 150, "Bauhaus93", 45)
	myText:setTextColor(0xf5, 0x91, 0x33)
	
	friendText = display.newText(scene.view, params.friend.name.."\nScore: "..params.friendScore, 0, 0, 500, 150, "Bauhaus93", 45)
	friendText:setTextColor(0xf5, 0x91, 0x33)
	
	-- Text is positioned differently according to if we are the victor or loser.
	if params.isWinner then
		myText:setReferencePoint(display.TopLeftReferencePoint)
		myText.x = 30
		myText.y = 150
		friendText:setReferencePoint(display.BottomLeftReferencePoint)
		friendText.x = display.contentCenterX
		friendText.y = display.contentHeight - 150
	else
		friendText:setReferencePoint(display.TopLeftReferencePoint)
		friendText.x = 30
		friendText.y = 150
		myText:setReferencePoint(display.BottomLeftReferencePoint)
		myText.x = display.contentCenterX
		myText.y = display.contentHeight - 150
	end
end

-- Called immediately after scene has moved onscreen:
local function onEnterScene (event)
	Runtime:addEventListener("tap", onTapEvent)
	audio.play(resultSound)
end

-- Called when scene is about to move offscreen:
local function onExitScene (event)
	Runtime:removeEventListener("tap", onTapEvent)
end

-- Called AFTER scene has finished moving offscreen:
local function onDidExitScene (event)
	bg:removeSelf()
	bg          = nil
	myText:removeSelf()
	myText      = nil
	friendText:removeSelf()
	friendText  = nil
	audio.dispose(resultSound)
	resultSound = nil
end
-- Called if/when overlay scene is displayed via storyboard.showOverlay()
local function onOverlayBegan (event)
end

-- Called if/when overlay scene is hidden/removed via storyboard.hideOverlay()
local function onOverlayEnded (event)
end

-- Called prior to the removal of scene's "view" (display group)
local function onDestroyScene (event)
end

-- "createScene" event is dispatched if scene's view does not exist
scene:addEventListener("createScene", onCreateScene)

-- "willEnterScene" event is dispatched before scene transition begins
scene:addEventListener("willEnterScene", onWillEnterScene)

-- "enterScene" event is dispatched whenever scene transition has finished
scene:addEventListener("enterScene", onEnterScene)

-- "exitScene" event is dispatched before next scene's transition begins
scene:addEventListener("exitScene", onExitScene)

-- "didExitScene" event is dispatched after scene has finished transitioning out
scene:addEventListener("didExitScene", onDidExitScene)

-- "overlayBegan" event is dispatched when an overlay scene is shown
scene:addEventListener("overlayBegan", onOverlayBegan)
 
-- "overlayEnded" event is dispatched when an overlay scene is hidden/removed
scene:addEventListener("overlayEnded", onOverlayEnded)

-- "destroyScene" event is dispatched before view is unloaded, which can be
-- automatically unloaded in low memory situations, or explicitly via a call to
-- storyboard.purgeScene() or storyboard.removeScene().
scene:addEventListener("destroyScene", onDestroyScene)

return scene
